<?php

$applicationDirectory = realpath(dirname(__FILE__) . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR);
$projectRoot = $applicationDirectory . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..';

// Selection of migrations to apply in clean-db vs user-generated DATA scenario
$modulePaths = array();
if (DATA == "clean-db") {
    $modulePaths['clean-db-only'] = 'dna.db.migrations.clean-db-only';
}
if (DATA == "user-generated") {
    $modulePaths['user-generated-only'] = 'dna.db.migrations.user-generated-only';
}

$consoleConfig = array(
    'aliases' => array(
        'root' => $projectRoot,
        'app' => $applicationDirectory,
        'vendor' => $projectRoot . DIRECTORY_SEPARATOR . 'vendor',
        'dna' => $projectRoot . DIRECTORY_SEPARATOR . 'dna',
    ),
    'basePath' => $applicationDirectory,
    'name' => 'Yii DNA Pre-Release Testing Console Application',
    'import' => array(),
    'commandMap' => array(
        'migrate' => array(
            // alias of the path where you extracted the zip file
            'class' => 'vendor.yiiext.migrate-command.EMigrateCommand',
            // this is the path where you want your core application migrations to be created
            'migrationPath' => 'dna.db.migrations.common',
            // the name of the table created in your database to save versioning information
            'migrationTable' => 'migration',
            // the application migrations are in a pseudo-module called "core" by default
            'applicationModuleName' => 'common',
            // define all available modules (if you do not set this, modules will be set from yii app config)
            'modulePaths' => $modulePaths,
            // you can customize the modules migrations subdirectory which is used when you are using yii module config
            'migrationSubPath' => 'migrations',
            // here you can configure which modules should be active, you can disable a module by adding its name to this array
            'disabledModules' => array(),
            // the name of the application component that should be used to connect to the database
            'connectionID' => 'db',
            // alias of the template file used to create new migrations
            #'templateFile' => 'system.cli.migration_template',
        ),
        // fixtureHelper
        'fixture' => array(
            'class' => 'vendor.sumwai.yii-fixture-helper.FixtureHelperCommand',
            'defaultFixturePathAlias' => 'dna.fixtures',
        ),
        // db commands
        'databaseschema' => array(
            'class' => 'app.commands.DatabaseSchemaCommand',
        ),
        'mysqldump' => array(
            'class' => 'vendor.crisu83.yii-consoletools.commands.MysqldumpCommand',
            'basePath' => dirname(__DIR__) . '/..',
            'dumpPath' => '/db',
        ),
        // dna-specific commands
        'databaseviewgenerator' => array(
            'class' => 'dna.commands.DatabaseViewGeneratorCommand',
        ),
    ),
    'components' => array(
        'fixture-helper' => array(
            'class' => 'vendor.sumwai.yii-fixture-helper.FixtureHelperDbFixtureManager',
        ),
    ),
);

$config = $consoleConfig;

// Database config
require $projectRoot . DIRECTORY_SEPARATOR . 'dna' . DIRECTORY_SEPARATOR . 'db' . DIRECTORY_SEPARATOR . 'config.inc.php';

return $config;
