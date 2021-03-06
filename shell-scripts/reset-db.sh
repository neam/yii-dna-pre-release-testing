#!/bin/bash

#
# Resets the database to the current DATA profile's migration base, then runs migrations
#
# Parameters:
#    --force-s3-sync    will fetch user generated data from S3 despite there being existing files
#

# Uncomment to see all variables used in this sciprt
#set -x;

script_path=`dirname $0`

# fail on any error
set -o errexit
set -o pipefail

export LOG=/tmp/reset-db.sh.log

echo "* Reset db (DATA=$DATA) started. Logging to $LOG" | tee -a $LOG

# Show script name and line number when errors occur to make errors easier to debug
trap 'echo "
! Script error in $0 on or near line ${LINENO}. Check $LOG for details

    To view log:
    cat $LOG | less
"' ERR

cd $script_path/..
dna_path=$(pwd)/../../../dna

# make app config available as shell variables
cd $dna_path/../
source vendor/neam/php-app-config/shell-export.sh
cd - >> $LOG

if [ "$DATA" == "" ]; then

    echo "The environment variable DATA needs to be set"
    exit 1

fi

# set media path
media_path=/files/$DATA/media

# to see which commands are executed
# set -x;

if [ "$DATA" != "clean-db" ]; then

    echo "* Fetching the user-generated data associated with this commit" | tee -a $LOG

    shell-scripts/fetch-user-generated-data.sh $1 >> $LOG

fi

echo "* Dropping all tables and views" | tee -a $LOG
cat shell-scripts/drop-all-tables-and-views.sql | mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME >> $LOG

echo "* Setting schema character set and collation defaults" | tee -a $LOG
if [ -f $dna_path/db/migration-base/$DATA/alter-schema-defaults.sql ]; then
    mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD < $dna_path/db/migration-base/$DATA/alter-schema-defaults.sql
else
    echo "ALTER SCHEMA $DATABASE_NAME DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;" | mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD
fi

echo "* Copying schema dump to a temporary location before modifying it for successful import"
cp $dna_path/db/migration-base/$DATA/schema.sql /tmp/$DATA.schema.sql

echo "* Removing DEFINER metadata from schema dump since it prevents import of schema with other users than the one used for export"
sed -i -e 's/\/\*!50013 DEFINER=`[^`]*`@`[^`]*` SQL SECURITY DEFINER \*\///' /tmp/$DATA.schema.sql

echo "* Appending 'quit' to schema dump to prevent mysql from hanging during import"
echo "quit" >> /tmp/$DATA.schema.sql
echo "" >> /tmp/$DATA.schema.sql

if [ "$DATA" != "clean-db" ]; then

    echo "* Loading the user-generated data associated with this commit" | tee -a $LOG

    # load mysql dumps
    mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < /tmp/$DATA.schema.sql
    mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/$DATA/data.sql

    # load user generated files (not sending --force-s3-sync to script since it is already performed above)
    shell-scripts/reset-user-generated-files.sh >> $LOG

fi

if [ "$DATA" == "clean-db" ]; then

    echo "* Loading the clean-db data associated with this commit" | tee -a $LOG

    # load mysql dumps
    mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < /tmp/$DATA.schema.sql
    mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/clean-db/data.sql

fi

echo "* Running legacy Yii migrations" | tee -a $LOG
console/yii-dna-pre-release-testing-console migrate --interactive=0 >> $LOG

if [ -f "$dna_path/../bin/migrate-propel.sh" ]; then
echo "* Running Propel migrations" | tee -a $LOG
$dna_path/../bin/migrate-propel.sh
fi

echo "* Loading fixtures" | tee -a $LOG
console/yii-dna-pre-release-testing-console fixture load >> $LOG

echo "* Generating database views" | tee -a $LOG
console/yii-dna-pre-release-testing-console databaseviewgenerator postResetDb >> $LOG

echo "* Generating database routines" | tee -a $LOG
console/yii-dna-pre-release-testing-console databaseroutinegenerator postResetDb >> $LOG

if [ "$connectionID" != "dbTest" ]; then

    echo "* Updating current schema dumps" | tee -a $LOG
    shell-scripts/update-current-schema-dumps.sh >> $LOG

fi

echo "* Reset db finished. Log is found at $LOG"
echo
echo "    To view log:"
echo "    cat $LOG | less -R";
echo
#echo "To view errors in log:"
#echo "cat $LOG | grep rror | less";
