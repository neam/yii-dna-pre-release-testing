#!/bin/bash

# fail on any error
set -o errexit

# This wrapper runs yiic migrate and then updates the current db/schema-after-applied-migrations.sql file with the current schema
script_path=`dirname $0`

$script_path/../console/yiic migrate $@
$script_path/update-current-schema-dumps.sh