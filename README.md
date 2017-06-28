DNA Project Base Data Set Management
===========================

**MIGRATION NOTICE: Repository migrated to [https://github.com/neam/dna-project-base-data-set-management]()**

Scripts and database migrations folder structure suited for release-upgrade testing with fake data and cloned real user data.

## Rationale and definitions

We want to be able to develop/test the code both starting from an empty database, and with data imported from a production deployment. These two testing-data-scenarios are referred to as "clean-db" vs "user-generated", and all acceptance tests should be grouped into one or both of these.
The "clean-db" data is saved in db/migration-base/clean-db/, the user-generated schema is saved in s3://user-data-backups at the path specified within files located in db/migration-base/user-generated/

## User-generated data
User generated data is backed up to S3 by running a command specified in the readme. This includes the schema, table data and uploaded user media.

## Database migrations
Handled by Propel. 

# DATA profiles
Since there may be multiple independent databases deployed, one may keep track of them separately by creating data profiles. That is, instead of simply having "clean-db" and "user-generated" variants, we can create any new dataset and call it for instance "customer1" to be able to track the data set of that particular customer-deployment. 

## FAQ

### How are new DATA profiles added?

Create a new data profile using the helper script, then upload the current current user-generated data to S3, commit the references and profile-related files in dna (anything with <profileref> in it's path) and push.

    vendor/neam/yii-dna-pre-release-testing/shell-scripts/new-data-profile.sh <profileref>
    vendor/neam/yii-dna-pre-release-testing/shell-scripts/upload-user-data-backup.sh
    # then run the three commands to update the data refs
    # commit and push

### Removing applied migrations in order to remove clutter

Run the following to take the current user-generated schema and copies it to the migration base of the clean-db schema. This makes the default schema to be identical with the user-generated version, and this routine should be done after a release (ie when migrations have been run in production) so that already production-applied migrations can be removed from the current codebase in order to minimize clutter.

    export DATA=example
    vendor/neam/yii-dna-pre-release-testing/shell-scripts/post-release-user-generated-schema-to-clean-db-schema-routine.sh
    # then, manually remove already applied migrations

A comment: Migrations are crucial when it comes to upgrading older deployments to the latest schema. If, however, there are no need of upgrading older deployments to the latest schema and code, migrations may instead add to the maintenance and development routines burden without adding value to the project. This is for instance the case during early development where there are no live deployments, or when all live deployments have run all migrations to date and there is no need to restore from old backups.
