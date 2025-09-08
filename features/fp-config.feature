Feature: fp-config

  Scenario: Default FinPress install with FP_CONFIG_PATH specified in environment variable
    Given a FP installation
    And a fp-config-override.php file:
      """
      <?php
      define('DB_NAME', 'fp_cli_test');
      define('DB_USER', '{DB_USER}');
      define('DB_PASSWORD', '{DB_PASSWORD}');
      define('DB_HOST', '{DB_HOST}');
      define('DB_CHARSET', 'utf8');
      define('DB_COLLATE', '');
      $table_prefix = 'fp_';

      // Provide custom define in override only that we can test against
      define('TEST_CONFIG_OVERRIDE', 'success');

      if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');
      require_once(ABSPATH . 'fp-settings.php');
      """

    When I try `fp eval "echo 'TEST_CONFIG_OVERRIDE => ' . TEST_CONFIG_OVERRIDE;"`
    Then STDERR should contain:
      """
      TEST_CONFIG_OVERRIDE
      """

    When I run `FP_CONFIG_PATH=fp-config-override.php fp eval "echo 'TEST_CONFIG_OVERRIDE => ' . TEST_CONFIG_OVERRIDE;"`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      TEST_CONFIG_OVERRIDE => success
      """
