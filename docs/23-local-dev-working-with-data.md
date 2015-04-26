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

    bin/upload-current-user-data.sh

Commit and push.

NOTE: 

	Also commit your files in dna/db/migration-base/ - but remember to remove the 5 files directly subordinate from dna/db:

		data.filepath
		data.sql.gz
		media.folderpath
		schema.filepath
		schema.sql.gz

	Files to commit are for example:

		dna/db/migration-base/{project-name}/schema.filepath
		dna/db/migration-base/{project-name}/data.filepath
		dna/db/migration-base/{project-name}/media.folderpath

NOTE #2:

	After you have ran the "bin/upload-current-user-data.sh" and before you commit you need to run the echo scripts at the bottom (it says its optional) to copy your new files into dna/db/migration-base/

