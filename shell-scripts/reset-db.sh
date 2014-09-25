#!/bin/bash

set -x;

script_path=`dirname $0`

if [ "$connectionID" == "" ]; then

    echo "The environment variable connectionID needs to be set"
    exit 1

fi

# fail on any error
set -o errexit

cd $script_path/..
dna_path=../../../dna

console/yiic databaseschema --connectionID=$connectionID dropAllTablesAndViews --verbose=0

if [ "$DATA" == "user-generated" ]; then

    echo "===== Load the user-generated data associated with this commit ===="

    $dna_path/db/shell-scripts/fetch-user-generated-data.sh

    # load mysql dump
    # TODO fix what is causing the following command to crash (it is most likely the file size of > 1 MB)
    #console/yiic databaseschema --connectionID=$connectionID loadSql --path=$dna_path/db/migration-base/user-generated/schema.sql
    #console/yiic databaseschema --connectionID=$connectionID loadSql --path=$dna_path/db/migration-base/user-generated/data.sql

    # TODO Remove this once the todo above has been fixed
    mysql -A --host=$DB_HOST --port=$DB_PORT --user=$DB_USER --password=$DB_PASSWORD $DB_NAME < $dna_path/db/migration-base/user-generated/schema.sql
    mysql -A --host=$DB_HOST --port=$DB_PORT --user=$DB_USER --password=$DB_PASSWORD $DB_NAME < $dna_path/db/migration-base/user-generated/data.sql

    # copy the downloaded data to the p3media folder
    rm -rf $dna_path/db/data/p3media/*
    # todo: find a way to ensure that previously uploaded media can be restored from, possible similar to below but that works more than once
    #mkdir .trashed-p3media-data
    #mv $dna_path/db/data/p3media/* .trashed-p3media-data/
    cp -r $dna_path/db/migration-base/user-generated/media/* $dna_path/db/data/p3media/

    # make downloaded media directories owned and writable by the web server
    chown -R nobody: $dna_path/db/data/p3media/

fi

if [ "$DATA" == "clean-db" ]; then

    console/yiic databaseschema --connectionID=$connectionID loadSql --path=$dna_path/db/migration-base/clean-db/schema.sql --verbose=0
    console/yiic databaseschema --connectionID=$connectionID loadSql --path=$dna_path/db/migration-base/clean-db/data.sql --verbose=0

fi

if [ "$DATA" == "" ]; then

    echo "The environment variable DATA needs to be set"
    exit 1

fi

console/yiic fixture --connectionID=$connectionID load
console/yiic migrate --connectionID=$connectionID --interactive=0 # > /dev/null
console/yiic databaseviewgenerator --connectionID=$connectionID item
console/yiic databaseviewgenerator --connectionID=$connectionID itemTable

if [ "$connectionID" != "dbTest" ]; then

    shell-scripts/update-current-schema-dumps.sh

fi

