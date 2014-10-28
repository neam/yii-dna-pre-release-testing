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

## FAQ

### How are new migrations created?

    vendor/bin/yii-dna-pre-release-testing-console migrate create migration_foo

This puts the empty migration files in the common migrations dir. If you need a migration only for clean-db or only for user-generated you'll need to move it.

