Feature: fin-config

  Scenario: Default FinPress install with FIN_CONFIG_PATH specified in environment variable
    Given a FIN installation
    And a fin-config-override.php file:
      """
      <?php
      define('DB_NAME', 'fin_cli_test');
      define('DB_USER', '{DB_USER}');
      define('DB_PASSWORD', '{DB_PASSWORD}');
      define('DB_HOST', '{DB_HOST}');
      define('DB_CHARSET', 'utf8');
      define('DB_COLLATE', '');
      $table_prefix = 'fin_';

      // Provide custom define in override only that we can test against
      define('TEST_CONFIG_OVERRIDE', 'success');

      if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');
      require_once(ABSPATH . 'fin-settings.php');
      """

    When I try `fin eval "echo 'TEST_CONFIG_OVERRIDE => ' . TEST_CONFIG_OVERRIDE;"`
    Then STDERR should contain:
      """
      TEST_CONFIG_OVERRIDE
      """

    When I run `FIN_CONFIG_PATH=fin-config-override.php fin eval "echo 'TEST_CONFIG_OVERRIDE => ' . TEST_CONFIG_OVERRIDE;"`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      TEST_CONFIG_OVERRIDE => success
      """
