#!/bin/bash

# this script essentially takes the current user-generated schema and copies it to the
# migration base of the clean-db schema. this makes the default schema to be identical
# with the user-generated version, and this routine should be done after a release
# (ie when migrations have been run in production) so that already production-applied
# migrations can be removed from the current codebase in order to minimize clutter

script_path=`dirname $0`
cd $script_path/../

cp db/migration-base/user-generated/schema.sql db/migration-base/clean-db/schema.sql

function cleanupdump {

    sed -i '/-- Dump completed on/d' $1
    sed -i 's/AUTO_INCREMENT=[0-9]*\b//' $1

}

cleanupdump db/migration-base/clean-db/schema.sql

echo "Schema updated. Now remove migrations that are already applied"

exit 0