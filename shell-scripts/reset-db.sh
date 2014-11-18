#!/bin/bash

#
# Resets the database to the current DATA profile's migration base, then runs migrations
#
# Parameters:
#    --force-s3-sync    will fetch user generated data from S3 despite there being existing files
#

set -x;

script_path=`dirname $0`

if [ "$connectionID" == "" ]; then

    echo "The environment variable connectionID needs to be set"
    exit 1

fi

# fail on any error
set -o errexit

cd $script_path/..
dna_path=$(pwd)/../../../dna

console/yii-dna-pre-release-testing-console databaseschema --connectionID=$connectionID dropAllTablesAndViews --verbose=0

# make app config available as shell variables
php $dna_path/../vendor/neam/php-app-config/export.php | tee /tmp/php-app-config.sh
source /tmp/php-app-config.sh

if [ "$connectionID" == "dbTest" ]; then
    export DATABASE_HOST=$TEST_DB_HOST
    export DATABASE_PORT=$TEST_DB_PORT
    export DATABASE_USER=$TEST_DB_USER
    export DATABASE_PASSWORD=$TEST_DB_PASSWORD
    export DATABASE_NAME=$TEST_DB_NAME
fi

if [ "$DATA" != "clean-db" ]; then

    echo "===== Load the user-generated data associated with this commit ===="

    shell-scripts/fetch-user-generated-data.sh $1

    # load mysql dumps
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/$DATA/schema.sql
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/$DATA/data.sql

    # copy the downloaded data to the p3media folder
    rm -rf $dna_path/db/data/p3media/*
    SOURCE_PATH=$dna_path/db/migration-base/$DATA/media
    if [ "$(ls -A $SOURCE_PATH/)" ]; then
        cp -r $SOURCE_PATH/* $dna_path/db/data/p3media/
    else
        echo "Warning: No media files found"
    fi

    # make downloaded media directories owned and writable by the web server
    chown -R nobody: $dna_path/db/data/p3media/

fi

if [ "$DATA" == "clean-db" ]; then

    # load mysql dumps
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/clean-db/schema.sql
    mysql -A --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < $dna_path/db/migration-base/clean-db/data.sql

fi

if [ "$DATA" == "" ]; then

    echo "The environment variable DATA needs to be set"
    exit 1

fi

console/yii-dna-pre-release-testing-console fixture --connectionID=$connectionID load
console/yii-dna-pre-release-testing-console migrate --connectionID=$connectionID --interactive=0 # > /dev/null
console/yii-dna-pre-release-testing-console databaseviewgenerator --connectionID=$connectionID item
console/yii-dna-pre-release-testing-console databaseviewgenerator --connectionID=$connectionID itemTable

if [ "$connectionID" != "dbTest" ]; then

    shell-scripts/update-current-schema-dumps.sh

fi

