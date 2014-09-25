<?php

/**
 * Command for automating tasks of database schema modification
 *
 * Class DatabaseSchemaCommand
 */
class DatabaseSchemaCommand extends CConsoleCommand
{
    /**
     * @var string database connection component
     */
    public $connectionID = "db";

    /**
     * If we should be verbose
     *
     * @var bool
     */
    private $_verbose = false;

    /**
     * Write a string to standard output if we're verbose
     *
     * @param $string
     */
    protected function d($string)
    {
        if ($this->_verbose) {
            print "\033[37m" . $string . "\033[30m";
        }
    }

    protected function execute($db, $sql)
    {
        $this->d("Executing '" . $sql . "'\n");
        $db->createCommand($sql)->execute();
    }

    /**
     * Drops all tables from the database.
     * @param bool $verbose
     */
    public function actionDropAllTablesAndViews($verbose = false)
    {

        if (!empty($verbose)) {
            $this->_verbose = true;
        }

        $db =& Yii::app()->{$this->connectionID};

        $this->d("Connecting to '" . $db->connectionString . "'\n");

        $schema = $db->schema;
        $tables = $db->schema->tables;

        $this->execute($db, "SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;");
        $this->execute($db, "SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;");
        $this->execute($db, "SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';");

        foreach ($tables as $table) {
            $this->execute($db, "DROP TABLE IF EXISTS `{$table->name}`;");
            $this->execute($db, "DROP VIEW IF EXISTS `{$table->name}`;");
        }

        $this->execute($db, "SET SQL_MODE=@OLD_SQL_MODE;");
        $this->execute($db, "SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;");
        $this->execute($db, "SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;");

    }

    public function actionLoadSql($path, $verbose = false)
    {
        if (!empty($verbose)) {
            $this->_verbose = true;
        }

        $db = Yii::app()->{$this->connectionID};
        $sql = file_get_contents($path);
        $this->execute($db, $sql);
    }
}
