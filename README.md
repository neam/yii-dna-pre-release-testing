Yii DNA Pre-Release Testing
===========================

Scripts and database migrations folder structure suited for release-upgrade testing with fake data and cloned real user data.

## Rationale and definitions

We want to be able to develop/test the code both starting from an empty database, and with data imported from a production deployment. These two testing-data-scenarios are referred to as "clean-db" vs "user-generated", and all acceptance tests should be grouped into one or both of these.
The "clean-db" data is saved in db/migration-base/clean-db/, the user-generated schema is saved in s3://user-data-backups at the path specified within files located in db/migration-base/user-generated/

## User-generated data
User generated data is backed up to S3 by running a command specified in the readme. This includes the schema, table data and uploaded user media.

## Database migrations
The migrations-folder should at any time contain the migrations necessary to migrate (separately) the clean-db schema and the user-generated schema to the schema necessary for the current revision.

This ensures that release-upgrades can be tested before actual releases.

# DATA profiles
Since there may be multiple independent databases deployed, one may keep track of them separately by creating data profiles. That is, instead of simply having "clean-db" and "user-generated" variants, we can create any new dataset and call it for instance "customer1" to be able to track the data set of that particular customer-deployment. 

## FAQ

### How are new migrations created?

    vendor/bin/yii-dna-pre-release-testing-console migrate create migration_foo

This puts the empty migration files in the common migrations dir. If you need a migration only for clean-db or only for user-generated you'll need to move it.

### How are new DATA profiles added?

Create a new data profile using the helper script, then upload the current current user-generated data to S3, commit the references and profile-related files in dna (anything with <profileref> in it's path) and push.

    vendor/neam/yii-dna-pre-release-testing/shell-scripts/new-data-profile.sh <profileref>
    vendor/neam/yii-dna-pre-release-testing/shell-scripts/upload-user-data-backup.sh
    # then run the three commands to update the data refs
    # commit and push
