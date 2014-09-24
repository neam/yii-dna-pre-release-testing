#!/bin/bash

set -x

# fail on any error
set -o errexit

script_path=`dirname $0`

# Note: this script is tailored to be run on dokku deployments through sshcommand

# cd to app root
cd $script_path/../

# configure s3cmd
deploy/configure-s3cmd.sh

# make php binaries available
export PATH="/app/vendor/php/bin/:$PATH"

DATETIME=$(date +"%Y-%m-%d_%H%M%S")
FOLDER=ENV-$ENV

# dump and upload schema sql

FILEPATH=cms/$FOLDER/$DATETIME/schema.sql

if [ -f db/migration-base/user-generated/schema.sql ] ; then
    rm db/migration-base/user-generated/schema.sql
fi
$script_path/../app/yiic mysqldump --dumpPath=db/migration-base/user-generated --dumpFile=schema.sql --data=false
if [ ! -f db/migration-base/user-generated/schema.sql ] ; then
    echo "The mysql dump is not found at the expected location: db/migration-base/user-generated/schema.sql"
    exit 1
fi
s3cmd -v --config=/tmp/.user-generated-data.s3cfg put db/migration-base/user-generated/schema.sql "$USER_GENERATED_DATA_S3_BUCKET/$FILEPATH"

echo $FILEPATH > /app/db/migration-base/user-generated/schema.filepath
echo "User generated db schema sql dump uploaded to $USER_GENERATED_DATA_S3_BUCKET/$FILEPATH"
echo "Set the contents of 'db/migration-base/user-generated/schema.filepath' to '$FILEPATH' in order to use this upload"

# dump and upload data sql

FILEPATH=cms/$FOLDER/$DATETIME/data.sql

if [ -f db/migration-base/user-generated/data.sql ] ; then
    rm db/migration-base/user-generated/data.sql
fi
$script_path/../app/yiic mysqldump --dumpPath=db/migration-base/user-generated --dumpFile=data.sql --schema=false
if [ ! -f db/migration-base/user-generated/data.sql ] ; then
    echo "The mysql dump is not found at the expected location: db/migration-base/user-generated/data.sql"
    exit 1
fi
s3cmd -v --config=/tmp/.user-generated-data.s3cfg put db/migration-base/user-generated/data.sql "$USER_GENERATED_DATA_S3_BUCKET/$FILEPATH"

echo $FILEPATH > /app/db/migration-base/user-generated/data.filepath
echo "User generated db data sql dump uploaded to $USER_GENERATED_DATA_S3_BUCKET/$FILEPATH"
echo "Set the contents of 'db/migration-base/user-generated/data.filepath' to '$FILEPATH' in order to use this upload"

# dump and upload user media

FOLDERPATH=cms/$FOLDER/$DATETIME/media/

s3cmd -v --config=/tmp/.user-generated-data.s3cfg --recursive put $script_path/../app/data/p3media/ "$USER_GENERATED_DATA_S3_BUCKET/$FOLDERPATH"
echo $FOLDERPATH > /app/db/migration-base/user-generated/media.folderpath

echo "User media uploaded to $USER_GENERATED_DATA_S3_BUCKET/$FOLDERPATH"
echo "Set the contents of 'db/migration-base/user-generated/media.folderpath' to '$FOLDERPATH' in order to use this upload"

exit 0