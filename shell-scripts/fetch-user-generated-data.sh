#!/bin/bash

#
# Fetch the current DATA profile's user generated data from S3
#
# Parameters:
#    --force-s3-sync    will fetch user generated data from S3 despite there being existing files
#

# uncomment to debug
# set -x;

# fail on any error
set -o errexit

script_path=`dirname $0`
cd $script_path/..
dna_path=$(pwd)/../../../dna

if [ "$DATA" == "" ]; then

    echo "The environment variable DATA needs to be set"
    exit 1

fi

if [ "$USER_GENERATED_DATA_S3_BUCKET" == "" ]; then

    echo "The environment variable USER_GENERATED_DATA_S3_BUCKET needs to be set"
    exit 1

fi

# sending --force-s3-sync will fetch user generated data from S3 despite there being existing files
if [ "$1" == "--force-s3-sync" ]; then
    FORCE="--force"
else
    FORCE=""
fi

if [ ! -f $dna_path/db/migration-base/$DATA/schema.sql ] || [ "$FORCE" ]; then

    echo "== Fetching the user-generated schema associated with this commit =="

    if [ -f $dna_path/db/migration-base/$DATA/schema.filepath ]; then

        export USER_GENERATED_DATA_FILEPATH=`cat $dna_path/db/migration-base/$DATA/schema.filepath`
        export USER_GENERATED_DATA_S3_URL=$USER_GENERATED_DATA_S3_BUCKET/$USER_GENERATED_DATA_FILEPATH
        s3cmd -v --config=/tmp/.user-generated-data.s3cfg $FORCE get "$USER_GENERATED_DATA_S3_URL" $dna_path/db/migration-base/$DATA/schema.sql

        echo "User data dump downloaded from $USER_GENERATED_DATA_S3_URL to $dna_path/db/migration-base/$DATA/schema.sql"

    else
        echo "Error: the file $dna_path/db/migration-base/$DATA/schema.filepath needs to be available and contain the relative path in the S3 bucket that contains the sql dump with the user-generated db schema"
    fi

else
    echo "Not fetching user-generated data since $dna_path/db/migration-base/$DATA/schema.sql already exists"
fi

if [ ! -f $dna_path/db/migration-base/$DATA/data.sql ] || [ "$FORCE" ]; then

    echo "== Fetching the user-generated data associated with this commit =="

    if [ -f $dna_path/db/migration-base/$DATA/data.filepath ]; then

        export USER_GENERATED_DATA_FILEPATH=`cat $dna_path/db/migration-base/$DATA/data.filepath`
        export USER_GENERATED_DATA_S3_URL=$USER_GENERATED_DATA_S3_BUCKET/$USER_GENERATED_DATA_FILEPATH
        s3cmd -v --config=/tmp/.user-generated-data.s3cfg $FORCE get "$USER_GENERATED_DATA_S3_URL" $dna_path/db/migration-base/$DATA/data.sql

        echo "User data dump downloaded from $USER_GENERATED_DATA_S3_URL to $dna_path/db/migration-base/$DATA/data.sql"

    else
        echo "Error: the file $dna_path/db/migration-base/$DATA/data.filepath needs to be available and contain the relative path in the S3 bucket that contains the sql dump with the user-generated db data"
    fi

else
    echo "Not fetching user-generated data since $dna_path/db/migration-base/$DATA/data.sql already exists"
fi

if [ ! -d $dna_path/db/migration-base/$DATA/media/ ] || [ "$FORCE" ]; then

    echo "== Fetching the user-generated media associated with this commit =="

    if [ -f $dna_path/db/migration-base/$DATA/media.folderpath ]; then

        export USER_GENERATED_MEDIA_S3_BUCKET=$USER_GENERATED_DATA_S3_BUCKET
        export USER_GENERATED_MEDIA_FOLDERPATH=`cat $dna_path/db/migration-base/$DATA/media.folderpath`
        export USER_GENERATED_MEDIA_S3_URL=$USER_GENERATED_MEDIA_S3_BUCKET/$USER_GENERATED_MEDIA_FOLDERPATH
        mkdir $dna_path/db/migration-base/$DATA/media/ || true
        s3cmd -v --config=/tmp/.user-generated-data.s3cfg --recursive sync "$USER_GENERATED_MEDIA_S3_URL" $dna_path/db/migration-base/$DATA/

        echo "User media downloaded from $USER_GENERATED_DATA_S3_URL to $dna_path/db/migration-base/$DATA/media/"

    else
        echo "Error: the file $dna_path/db/migration-base/$DATA/media.folderpath needs to be available and contain the relative path in the S3 bucket that contains the user-generated media files"
    fi

else
    echo "Not fetching user-generated media since $dna_path/db/migration-base/$DATA/media/ already exists"
fi

exit 0
