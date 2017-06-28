Local Development: Working with data
====================================

## To reset to a clean database

First, choose the DATA profile to reset to by editing `.env`. Then, reset the database:

    bin/reset-db.sh

Note: to reset to anything other than DATA=clean-db, the below instructions needs to be followed first, since you need access to S3 where the data is stored.

## To reset to a database with user generated data:

Make sure to set the `USER_DATA_BACKUP_UPLOADERS_*` config vars in your `secrets.php` file.

Uncomment/set the DATA variable in your `.env` to the data environment you want to reset to.

Then, run a normal database reset:

    bin/reset-db.sh

If you have already run this once in the current DATA profile, no data will be re-fetched from S3. To force sync from S3, run:

    bin/reset-db.sh --force-s3-sync

## To upload your current data

Enter a shell and run:

    vendor/bin/upload-current-user-data.sh

Then, run the echo scripts at the bottom (it says its optional) to copy your new files into dna/db/migration-base/

Commit your files in dna/db/migration-base/ - the three files to commit are:

		dna/db/migration-base/{project-name}/schema.filepath
		dna/db/migration-base/{project-name}/data.filepath
		dna/db/migration-base/{project-name}/media.folderpath

Push.

## Migrations

### How are new migrations created?

    vendor/bin/yii-dna-pre-release-testing-console migrate create migration_foo

This puts the empty migration files in the common migrations dir. If you need a migration only for clean-db or only for user-generated you'll need to move it.

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
