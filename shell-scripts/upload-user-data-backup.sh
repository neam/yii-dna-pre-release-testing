#!/bin/bash

set -x

# fail on any error
set -o errexit

script_path=`dirname $0`

# defaults
if [ "$connectionID" == "" ]; then
    connectionID=db
fi

# cd to app root
cd $script_path/..
dna_path=$(pwd)/../../../dna
media_path=$dna_path/db/data/p3media

# dump

# configure s3cmd
echo "[default]
access_key = $USER_DATA_BACKUP_UPLOADERS_ACCESS_KEY
secret_key = $USER_DATA_BACKUP_UPLOADERS_SECRET" > /tmp/.user-generated-data.s3cfg

# make php binaries available
export PATH="/app/vendor/php/bin/:$PATH"

DATETIME=$(date +"%Y-%m-%d_%H%M%S")
FOLDER=DATA-$DATA/ENV-$ENV

# sending --non-compact will negate the default behavior of dumping the data in a compact format. useful to be able to inspect the dumped data files
if [ "$1" == "--non-compact" ]; then
    COMPACT="false"
else
    COMPACT="true"
fi

# dump schema sql

SCHEMA_FILEPATH=$FOLDER/$DATETIME/schema.sql

if [ -f $dna_path/db/schema.sql ] ; then
    rm $dna_path/db/schema.sql
fi
console/yii-dna-pre-release-testing-console mysqldump --connectionID=$connectionID --dumpPath=dna/db --dumpFile=schema.sql --data=false --skip-triggers
if [ ! -f $dna_path/db/schema.sql ] ; then
    echo "The mysql dump is not found at the expected location: db/schema.sql"
    exit 1
fi

# dump data sql

DATA_FILEPATH=$FOLDER/$DATETIME/data.sql

if [ -f $dna_path/db/data.sql ] ; then
    rm $dna_path/db/data.sql
fi
console/yii-dna-pre-release-testing-console mysqldump --connectionID=$connectionID --dumpPath=dna/db --dumpFile=data.sql --schema=false --compact=$COMPACT
if [ ! -f $dna_path/db/data.sql ] ; then
    echo "The mysql dump is not found at the expected location: db/data.sql"
    exit 1
fi

if [ "$1" == "--dump-only" ]; then
    exit 0;
fi

# upload schema sql

gzip -f $dna_path/db/schema.sql
SCHEMA_FILEPATH=$SCHEMA_FILEPATH.gz
s3cmd -v --config=/tmp/.user-generated-data.s3cfg put $dna_path/db/schema.sql.gz "$USER_GENERATED_DATA_S3_BUCKET/$SCHEMA_FILEPATH"

echo $SCHEMA_FILEPATH > $dna_path/db/schema.filepath

# upload data sql

gzip -f $dna_path/db/data.sql
DATA_FILEPATH=$DATA_FILEPATH.gz
s3cmd -v --config=/tmp/.user-generated-data.s3cfg put $dna_path/db/data.sql.gz "$USER_GENERATED_DATA_S3_BUCKET/$DATA_FILEPATH"

echo $DATA_FILEPATH > $dna_path/db/data.filepath

# dump and upload user media

FOLDERPATH=$FOLDER/$DATETIME/media/

s3cmd -v --config=/tmp/.user-generated-data.s3cfg --recursive put $media_path/ "$USER_GENERATED_DATA_S3_BUCKET/$FOLDERPATH"
echo $FOLDERPATH > $dna_path/db/media.folderpath

set +x

echo
echo "=== Upload finished ==="

DATA_FILEPATH=$(cat $dna_path/db/data.filepath)
echo "User generated db schema sql dump uploaded to $USER_GENERATED_DATA_S3_BUCKET/$DATA_FILEPATH"
echo "Set the contents of 'db/migration-base/$DATA/schema.filepath' to '$DATA_FILEPATH' in order to use this upload"

SCHEMA_FILEPATH=$(cat $dna_path/db/schema.filepath)
echo "User generated db data sql dump uploaded to $USER_GENERATED_DATA_S3_BUCKET/$SCHEMA_FILEPATH"
echo "Set the contents of 'db/migration-base/$DATA/data.filepath' to '$SCHEMA_FILEPATH' in order to use this upload"

FOLDERPATH=$(cat $dna_path/db/media.folderpath)
echo "User media uploaded to $USER_GENERATED_DATA_S3_BUCKET/$FOLDERPATH"
echo "Set the contents of 'db/migration-base/$DATA/media.folderpath' to '$FOLDERPATH' in order to use this upload"
echo
echo "# Commands to run locally in order to set the refs to point to this user data (optional - do this if your data set is meant to be the base of future production deployments)"
echo "echo '$SCHEMA_FILEPATH' > dna/db/migration-base/$DATA/schema.filepath"
echo "echo '$DATA_FILEPATH' > dna/db/migration-base/$DATA/data.filepath"
echo "echo '$FOLDERPATH' > dna/db/migration-base/$DATA/media.folderpath"

exit 0