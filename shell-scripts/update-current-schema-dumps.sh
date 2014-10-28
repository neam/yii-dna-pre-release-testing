#!/bin/bash

script_path=`dirname $0`
cd $script_path/..
dna_path=$(pwd)/../../../dna

# fail on any error
set -o errexit

# document the current database table defaults
php $dna_path/../vendor/neam/php-app-config/export.php | tee /tmp/php-app-config.sh
source /tmp/php-app-config.sh
mysqldump -h$DATABASE_HOST -P$DATABASE_PORT -u$DATABASE_USER --password=$DATABASE_PASSWORD --no-create-info --skip-triggers --no-data --databases $DATABASE_NAME > $dna_path/db/migration-results/$DATA/create-db.sql

# dump the current schema
console/yii-dna-pre-release-testing-console mysqldump --dumpPath=dna/db --dumpFile=migration-results/$DATA/schema.sql --data=false --schema=true
console/yii-dna-pre-release-testing-console mysqldump --dumpPath=dna/db --dumpFile=migration-results/$DATA/data.sql --data=true --schema=false --compact=false

# perform some clean-up on the dump files so that it needs to be committed less often
function cleanupdump {

    sed -i '/-- Dump completed on/d' $1
    sed -i 's/AUTO_INCREMENT=[0-9]*\b/\/\*AUTO_INCREMENT omitted\*\//' $1

}

cleanupdump $dna_path/db/migration-results/$DATA/create-db.sql
cleanupdump $dna_path/db/migration-results/$DATA/schema.sql
cleanupdump $dna_path/db/migration-results/$DATA/data.sql

exit 0