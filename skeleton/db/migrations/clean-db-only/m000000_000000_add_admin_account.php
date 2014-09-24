<?php

/**
 * The first migration to be applied to the clean-db database is one that adds an admin-account
 * This example adds a user "admin" with the password "admin" for use with nordsoftware/yii-account
 */
class m000000_000000_add_admin_account extends EDbMigration
{
	public function safeUp()
	{
        $password = '$2a$12$dyixOdTUCj3lcHhP0w.owu2esQMRb2vkedMx4tb3inn6OMYHZLium';
        $salt = '$2a$12$dyixOdTUCj3lcHhP0w.oww';

        $this->execute("INSERT INTO `account` VALUES (1, 'admin', '{$password}', 'webmaster@example.com', 'd6aef338ea9d2ea49a0f62705ef51ecc', 1, 1, '2014-01-01 00:00:00', NULL, '{$salt}', 'bcrypt', 0, NULL, NULL);");
        $this->execute("INSERT INTO `profile` VALUES (1, 'Administrator', 'Admin', NULL, NULL, NULL, 0, NULL, NULL, 'sv', NULL, NULL, NULL, NULL);");
	}

	public function safeDown()
	{
        $this->delete('account', 'id = 1');
        $this->delete('profile', 'user_id = 1');
	}
}
