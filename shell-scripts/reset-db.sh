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

if [ "$connectionID" == "" ]; then

    echo "The environment variable connectionID needs to be set"
    exit 1

fi

# fail on any error
set -o errexit

LOG=/tmp/reset-db.sh.log

echo "* Reset db started. Logging to $LOG" | tee -a $LOG

# Show script name and line number when errors occur to make errors easier to debug
trap 'echo "
! Script error in $0 on or near line ${LINENO}. Check $LOG for details

    To view log:
    cat $LOG | less
"' ERR

cd $script_path/..
dna_path=$(pwd)/../../../dna

# make app config available as shell variables
php $dna_path/../vendor/neam/php-app-config/export.php | tee /tmp/php-app-config.sh >> $LOG
source /tmp/php-app-config.sh

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

# Clear current data
console/yii-dna-pre-release-testing-console databaseschema --connectionID=$connectionID dropAllTablesAndViews --verbose=0 >> $LOG

if [ "$connectionID" == "dbTest" ]; then
    export DATABASE_HOST=$TEST_DB_HOST
    export DATABASE_PORT=$TEST_DB_PORT
    export DATABASE_USER=$TEST_DB_USER
    export DATABASE_PASSWORD=$TEST_DB_PASSWORD
    export DATABASE_NAME=$TEST_DB_NAME
fi

echo "* Setting schema character set and collation defaults" | tee -a $LOG
if [ -f $dna_path/db/migration-base/$DATA/alter-schema-defaults.sql ]; then
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD < $dna_path/db/migration-base/$DATA/alter-schema-defaults.sql
else
    echo "ALTER SCHEMA $DATABASE_NAME DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;" | mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD
fi

echo "* Removing DEFINER metadata from schema dump"
sed -i -e 's/\/\*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER \*\///' -e 's/\/\*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER \*\///' $dna_path/db/migration-base/$DATA/schema.sql

if [ "$DATA" != "clean-db" ]; then

    echo "* Loading the user-generated data associated with this commit" | tee -a $LOG

    # load mysql dumps
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/$DATA/schema.sql
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/$DATA/data.sql

    # load user generated files (not sending --force-s3-sync to script since it is already performed above)
    shell-scripts/reset-user-generated-files.sh >> $LOG

fi

if [ "$DATA" == "clean-db" ]; then

    echo "* Loading the clean-db data associated with this commit" | tee -a $LOG

    # load mysql dumps
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/clean-db/schema.sql
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/clean-db/data.sql

fi

echo "* Running migrations" | tee -a $LOG
console/yii-dna-pre-release-testing-console migrate --connectionID=$connectionID --interactive=0 >> $LOG

echo "* Loading fixtures" | tee -a $LOG
console/yii-dna-pre-release-testing-console fixture --connectionID=$connectionID load >> $LOG

echo "* Generating database views" | tee -a $LOG
console/yii-dna-pre-release-testing-console databaseviewgenerator --connectionID=$connectionID postResetDb >> $LOG

echo "* Generating database routines" | tee -a $LOG
console/yii-dna-pre-release-testing-console databaseroutinegenerator --connectionID=$connectionID postResetDb >> $LOG

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