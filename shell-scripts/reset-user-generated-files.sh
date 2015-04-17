#!/bin/bash

#
# Resets the media files to the current DATA profile's migration base, then runs migrations
#

# Uncomment to see all variables used in this sciprt
#set -x;

script_path=`dirname $0`

if [ "$WEB_SERVER_POSIX_USER" == "" ]; then
  WEB_SERVER_POSIX_USER="www-data"
fi

if [ "$WEB_SERVER_POSIX_GROUP" == "" ]; then
  WEB_SERVER_POSIX_GROUP=""
fi

# fail on any error
set -o errexit

LOG=/tmp/reset-db.sh.log

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

# set media path
media_path=/files/$DATA/media

# to see which commands are executed
# set -x;

# Clear current data
rm -rf $media_path/*

if [ "$DATA" != "clean-db" ]; then

    if [ "$1" == "--force-s3-sync" ]; then

        echo "* Fetching the user-generated data associated with this commit" | tee -a $LOG

        shell-scripts/fetch-user-generated-data.sh $1 >> $LOG

    fi

    echo "* Loading the user-generated files associated with this commit" | tee -a $LOG

    # copy the downloaded data to the p3media folder
    SOURCE_PATH=$dna_path/db/migration-base/$DATA/media
    if [ "$(ls $SOURCE_PATH/)" ]; then
        mkdir -p $media_path/
        cp -r $SOURCE_PATH/* $media_path/
    else
        echo "Warning: No media files found" | tee -a $LOG
    fi

    # make downloaded media directories owned and writable by the web server
    chown -R $WEB_SERVER_POSIX_USER:$WEB_SERVER_POSIX_GROUP $media_path/

fi
