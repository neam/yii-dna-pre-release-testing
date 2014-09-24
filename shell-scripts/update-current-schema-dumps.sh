#!/bin/bash

script_path=`dirname $0`
cd $script_path/../../

# document the current database table defaults
app/yiic config exportDbConfig --connectionID=db | tee /tmp/db-config.sh
source /tmp/db-config.sh
mysqldump -h$DB_HOST -P$DB_PORT -u$DB_USER --password=$DB_PASSWORD --no-create-info --skip-triggers --no-data --databases $DB_NAME > db/migration-results/$DATA/create-db.sql

# dump the current schema
app/yiic mysqldump --dumpPath=db --dumpFile=migration-results/$DATA/schema.sql --data=false --schema=true
app/yiic mysqldump --dumpPath=db --dumpFile=migration-results/$DATA/data.sql --data=true --schema=false --compact=false

# perform some clean-up on the dump files so that it needs to be committed less often
function cleanupdump {

    sed -i '/-- Dump completed on/d' $1
    sed -i 's/AUTO_INCREMENT=[0-9]*\b/\/\*AUTO_INCREMENT omitted\*\//' $1

}

cleanupdump db/migration-results/$DATA/create-db.sql
cleanupdump db/migration-results/$DATA/schema.sql
cleanupdump db/migration-results/$DATA/data.sql

exit 0