#!/bin/bash

set -x;

# fail on any error
set -o errexit

script_path=`dirname $0`
cd $script_path/../../

if [ ! -f db/migration-base/user-generated/schema.sql ]; then

    echo "== Fetching the user-generated schema associated with this commit =="

    if [ -f db/migration-base/user-generated/schema.filepath ]; then

        export USER_GENERATED_DATA_S3_BUCKET="s3://user-data-backups"
        export USER_GENERATED_DATA_FILEPATH=`cat db/migration-base/user-generated/schema.filepath`
        export USER_GENERATED_DATA_S3_URL=$USER_GENERATED_DATA_S3_BUCKET/$USER_GENERATED_DATA_FILEPATH
        s3cmd -v --config=/tmp/.user-generated-data.s3cfg get "$USER_GENERATED_DATA_S3_URL" db/migration-base/user-generated/schema.sql

        echo "User data dump downloaded from $USER_GENERATED_DATA_S3_URL to db/migration-base/user-generated/schema.sql"

    else
        echo "Error: the file db/migration-base/user-generated/schema.filepath needs to be available and contain the relative path in the S3 bucket that contains the sql dump with the user-generated db schema"
    fi

else
    echo "Not fetching user-generated data since db/migration-base/user-generated/schema.sql already exists"
fi

if [ ! -f db/migration-base/user-generated/data.sql ]; then

    echo "== Fetching the user-generated data associated with this commit =="

    if [ -f db/migration-base/user-generated/data.filepath ]; then

        export USER_GENERATED_DATA_S3_BUCKET="s3://user-data-backups"
        export USER_GENERATED_DATA_FILEPATH=`cat db/migration-base/user-generated/data.filepath`
        export USER_GENERATED_DATA_S3_URL=$USER_GENERATED_DATA_S3_BUCKET/$USER_GENERATED_DATA_FILEPATH
        s3cmd -v --config=/tmp/.user-generated-data.s3cfg get "$USER_GENERATED_DATA_S3_URL" db/migration-base/user-generated/data.sql

        echo "User data dump downloaded from $USER_GENERATED_DATA_S3_URL to db/migration-base/user-generated/data.sql"

    else
        echo "Error: the file db/migration-base/user-generated/data.filepath needs to be available and contain the relative path in the S3 bucket that contains the sql dump with the user-generated db data"
    fi

else
    echo "Not fetching user-generated data since db/migration-base/user-generated/data.sql already exists"
fi

if [ ! -d db/migration-base/user-generated/media/ ]; then

    echo "== Fetching the user-generated media associated with this commit =="

    if [ -f db/migration-base/user-generated/media.folderpath ]; then

        export USER_GENERATED_MEDIA_S3_BUCKET="s3://user-data-backups"
        export USER_GENERATED_MEDIA_FOLDERPATH=`cat db/migration-base/user-generated/media.folderpath`
        export USER_GENERATED_MEDIA_S3_URL=$USER_GENERATED_MEDIA_S3_BUCKET/$USER_GENERATED_MEDIA_FOLDERPATH
        mkdir db/migration-base/user-generated/media/
        s3cmd -v --config=/tmp/.user-generated-data.s3cfg --recursive get "$USER_GENERATED_MEDIA_S3_URL" db/migration-base/user-generated/media/

        echo "User media downloaded from $USER_GENERATED_DATA_S3_URL to db/migration-base/user-generated/media/"

    else
        echo "Error: the file db/migration-base/user-generated/media.folderpath needs to be available and contain the relative path in the S3 bucket that contains the user-generated media files"
    fi

else
    echo "Not fetching user-generated media since db/migration-base/user-generated/media/ already exists"
fi

exit 0
