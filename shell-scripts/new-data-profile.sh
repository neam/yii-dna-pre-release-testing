#!/bin/bash

#
# Creates a new data profile
#
#        Usage: new-data-profile.sh <profile-name>

# uncomment to debug
# set -x;

# fail on any error
set -o errexit

script_path=`dirname $0`
cd $script_path/..
dna_path=$(pwd)/../../../dna

FROM=clean-db
TO=$1

if [ "$TO" == "" ]; then
    echo "Usage: new-data-profile.sh <profile-name>"
    exit 1
fi

if [ ! -d "$dna_path/db/migration-base/$TO" ]; then
    cp -r $dna_path/db/migration-base/$FROM $dna_path/db/migration-base/$TO
    mkdir $dna_path/db/migration-base/$TO/media
    touch $dna_path/db/migration-base/$TO/media/.gitkeep
fi
if [ ! -d "$dna_path/db/migration-results/$TO" ]; then
    cp -r $dna_path/db/migration-results/$FROM $dna_path/db/migration-results/$TO
fi
if [ ! -d "$dna_path/db/migrations/$TO-only" ]; then
    cp -r $dna_path/db/migrations/$FROM-only $dna_path/db/migrations/$TO-only
    rm $dna_path/db/migrations/$TO-only/m999999_999999_fixed_apply_time_for_clean_db_migration_table*
fi

echo "Data profile '$TO' is now available. Run reset-db.sh to make sure it works, then run upload-user-data-backup.sh and commit the relevant files to make it available for others"
echo
echo " Example:"
echo "     export DATA=$TO"
echo "     bin/ensure-db.sh"
echo "     bin/reset-db.sh"
echo "     bin/upload-current-user-data.sh"
