Feature: Bootstrap FP-CLI

  Background:
    When I run `fp package path`
    And save STDOUT as {PACKAGE_PATH}
    And I run `rm -rf {PACKAGE_PATH}/vendor`
    And I run `rm -rf {PACKAGE_PATH}/composer.json`
    And I run `rm -rf {PACKAGE_PATH}/composer.lock`

  @less-than-php-7.4 @require-opcache-save-comments
  Scenario: Basic Composer stack
    Given an empty directory
    And a composer.json file:
      """
      {
          "name": "fp-cli/composer-test",
          "type": "project",
          "require": {
              "fp-cli/fp-cli": "1.1.0"
          }
      }
      """
    # Note: Composer outputs messages to stderr.
    And I run `composer install --no-interaction 2>&1`

    When I run `vendor/bin/fp cli version`
    Then STDOUT should contain:
      """
      FP-CLI 1.1.0
      """

  Scenario: Composer stack with override requirement before FP-CLI
    Given a FP installation
    And a composer.json file:
      """
      {
        "name": "fp-cli/composer-test",
        "type": "project",
        "minimum-stability": "dev",
        "prefer-stable": true,
        "repositories": [
          {
            "type": "path",
            "url": "./override",
            "options": {
                "symlink": false
            }
          }
        ],
        "require": {
          "fp-cli/override": "*",
          "fp-cli/fp-cli": "dev-main"
        }
      }
      """
    And a override/override.php file:
      """
      <?php
      if ( ! class_exists( 'FP_CLI' ) ) {
        return;
      }
      // Override bundled command.
      FP_CLI::add_command( 'eval', 'Custom_Eval_Command', array( 'when' => 'before_fp_load' ) );
      """
    And a override/src/Custom_Eval_Command.php file:
      """
      <?php
      class Custom_Eval_Command extends FP_CLI_Command {
        public function __invoke() {
          FP_CLI::success( "FP-Override-Eval" );
        }
      }
      """
    And a override/composer.json file:
      """
      {
        "name": "fp-cli/override",
        "description": "A command that overrides the 'eval' command.",
        "autoload": {
          "psr-4": { "": "src/" },
          "files": [ "override.php" ]
        },
        "extra": {
          "commands": [
            "eval"
          ]
        }
     }
      """
    And I run `composer install --no-interaction 2>&1`

    When I run `vendor/bin/fp eval '\FP_CLI::Success( "FP-Standard-Eval" );'`
    Then STDOUT should contain:
      """
      Success: FP-Override-Eval
      """

  Scenario: Override command bundled with current source

    Given a FP installation
    And a override/override.php file:
      """
      <?php
      if ( ! class_exists( 'FP_CLI' ) ) {
        return;
      }
      $autoload = dirname( __FILE__ ) . '/vendor/autoload.php';
      if ( file_exists( $autoload ) && ! class_exists( 'Custom_CLI_Command' ) ) {
        require_once $autoload;
      }
      // Override framework command.
      FP_CLI::add_command( 'cli', 'Custom_CLI_Command', array( 'when' => 'before_fp_load' ) );
      // Override bundled command.
      FP_CLI::add_hook(
        'after_add_command:eval',
        static function () {
          static $added = false;
          if ( ! $added ) {
            $added = true;
            FP_CLI::add_command( 'eval', 'Custom_Eval_Command', array( 'when' => 'before_fp_load' ) );
          }
        }
      );
      """
    And a override/src/Custom_CLI_Command.php file:
      """
      <?php
      class Custom_CLI_Command extends FP_CLI_Command {
        public function version() {
          FP_CLI::success( "FP-Override-CLI" );
        }
      }
      """
    And a override/src/Custom_Eval_Command.php file:
      """
      <?php
      class Custom_Eval_Command extends FP_CLI_Command {
        public function __invoke() {
          FP_CLI::success( "FP-Override-Eval" );
        }
      }
      """
    And a override/composer.json file:
      """
      {
        "name": "fp-cli/override",
        "description": "A command that overrides the bundled 'cli' and 'eval' commands.",
        "autoload": {
          "psr-4": { "": "src/" },
          "files": [ "override.php" ]
        },
        "extra": {
          "commands": [
            "cli",
            "eval"
          ]
        }
      }
      """
    And I run `composer install --working-dir={RUN_DIR}/override --no-interaction 2>&1`

    When I run `fp cli version`
    Then STDOUT should contain:
      """
      FP-CLI
      """

    When I run `fp eval '\FP_CLI::Success( "FP-Standard-Eval" );'`
    Then STDOUT should contain:
      """
      Success: FP-Standard-Eval
      """

    When I run `fp --require=override/override.php cli version`
    Then STDOUT should contain:
      """
      FP-Override-CLI
      """

    When I run `fp --require=override/override.php eval '\FP_CLI::Success( "FP-Standard-Eval" );'`
    Then STDOUT should contain:
      """
      Success: FP-Override-Eval
      """

  Scenario: Override command through package manager

    Given a FP installation
    And a override/override.php file:
      """
      <?php
      if ( ! class_exists( 'FP_CLI' ) ) {
        return;
      }
      $autoload = dirname( __FILE__ ) . '/vendor/autoload.php';
      if ( file_exists( $autoload ) && ! class_exists( 'Custom_CLI_Command' ) ) {
        require_once $autoload;
      }
      // Override framework command.
      FP_CLI::add_command( 'cli', 'Custom_CLI_Command', array( 'when' => 'before_fp_load' ) );
      // Override bundled command.
      FP_CLI::add_hook(
        'after_add_command:eval',
        static function () {
          static $added = false;
          if ( ! $added ) {
            $added = true;
            FP_CLI::add_command( 'eval', 'Custom_Eval_Command', array( 'when' => 'before_fp_load' ) );
          }
        }
      );
      """
    And a override/src/Custom_CLI_Command.php file:
      """
      <?php
      class Custom_CLI_Command extends FP_CLI_Command {
        public function version() {
          FP_CLI::success( "FP-Override-CLI" );
        }
      }
      """
    And a override/src/Custom_Eval_Command.php file:
      """
      <?php
      class Custom_Eval_Command extends FP_CLI_Command {
        public function __invoke() {
          FP_CLI::success( "FP-Override-Eval" );
        }
      }
      """
    And a override/composer.json file:
      """
      {
        "name": "fp-cli/override",
        "description": "A command that overrides the bundled 'cli' and 'eval' commands.",
        "autoload": {
          "psr-4": { "": "src/" },
          "files": [ "override.php" ]
        },
        "extra": {
          "commands": [
            "cli",
            "eval"
          ]
        }
      }
      """
    And I run `fp package install {RUN_DIR}/override`

    When I run `fp cli version --skip-packages`
    Then STDOUT should contain:
      """
      FP-CLI
      """

    When I run `fp eval '\FP_CLI::Success( "FP-Standard-Eval" );' --skip-packages`
    Then STDOUT should contain:
      """
      Success: FP-Standard-Eval
      """

    When I run `fp cli version`
    Then STDOUT should contain:
      """
      FP-Override-CLI
      """

    When I run `fp eval '\FP_CLI::Success( "FP-Standard-Eval" );'`
    Then STDOUT should contain:
      """
      Success: FP-Override-Eval
      """

  Scenario: Extend existing bundled command through package manager

    Given a FP installation
    And a override/override.php file:
      """
      <?php
      if ( ! class_exists( 'FP_CLI' ) ) {
        return;
      }

      FP_CLI::add_hook( 'before_fp_load', static function () {
        FP_CLI::add_command( 'plugin', 'My_Extended_Plugin_Command' );
      } );
      """
    And a override/src/My_Extended_Plugin_Command.php file:
      """
      <?php
      class My_Extended_Plugin_Command extends Plugin_Command {
        public function install( $args, $assoc_args ) {
          FP_CLI::error( 'Plugin installation has been disabled.' );
        }
      }
      """
    And a override/composer.json file:
      """
      {
        "name": "fp-cli/override",
        "description": "A command that extends the bundled 'plugin' command.",
        "autoload": {
          "psr-4": { "": "src/" },
          "files": [ "override.php" ]
        },
        "extra": {
          "commands": [
            "plugin"
          ]
        }
      }
      """
    And I run `fp package install {RUN_DIR}/override`

    When I try `fp plugin install duplicate-post`
    Then STDERR should contain:
      """
      Error: Plugin installation has been disabled.
      """

    When I run `fp plugin list`
    Then STDOUT should contain:
      """
      hello
      """

  Scenario: Define constant before running a command

    Given a FP installation

    # Expect a warning from FP core for PHP 8+.
    When I try `fp --exec="define( 'FP_ADMIN', true );" eval "echo FP_ADMIN;"`
    Then STDOUT should contain:
      """
      1
      """

  @require-php-7.0
  Scenario: Composer stack with both FinPress and fp-cli as dependencies (command line)
    Given a FP installation with Composer
    And a dependency on current fp-cli
    # Redirect STDERR to STDOUT as Composer produces non-error output on STDERR
    And I run `composer require fp-cli/entity-command --with-all-dependencies --no-interaction 2>&1`

    When I run `vendor/bin/fp option get blogname`
    Then STDOUT should contain:
      """
      FP CLI Site with both FinPress and fp-cli as Composer dependencies
      """

  @broken @require-php-7.0
  Scenario: Composer stack with both FinPress and fp-cli as dependencies (web)
    Given a FP installation with Composer
    And a dependency on current fp-cli
    And a PHP built-in web server to serve 'FinPress'
    Then the HTTP status code should be 200

  @require-php-7.0
  Scenario: Composer stack with both FinPress and fp-cli as dependencies and a custom vendor directory
    Given a FP installation with Composer and a custom vendor directory 'vendor-custom'
    And a dependency on current fp-cli
    # Redirect STDERR to STDOUT as Composer produces non-error output on STDERR
    And I run `composer require fp-cli/entity-command --with-all-dependencies --no-interaction 2>&1`

    When I run `vendor-custom/bin/fp option get blogname`
    Then STDOUT should contain:
      """
      FP CLI Site with both FinPress and fp-cli as Composer dependencies
      """

  Scenario: Setting an environment variable passes the value through
    Given an empty directory
    And FP files
    And a database
    And a env-var.php file:
      """
      <?php
      putenv( 'FP_CLI_TEST_ENV_VAR=foo' );
      """
    And a fp-cli.yml file:
      """
      config create:
        extra-php: |
          require_once __DIR__ . '/env-var.php';
          define( 'FP_CLI_TEST_CONSTANT', getenv( 'FP_CLI_TEST_ENV_VAR' ) );
      """

    When I run `fp config create --skip-check {CORE_CONFIG_SETTINGS}`
    Then STDOUT should contain:
      """
      Success:
      """

    # Use try to cater for fp-db errors in old FPs.
    When I try `fp core install --url=example.com --title=example --admin_user=example --admin_email=example@example.org`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

    When I run `fp eval 'echo constant( "FP_CLI_TEST_CONSTANT" );'`
    Then STDOUT should be:
      """
      foo
      """

  @require-fp-3.9
  Scenario: Run cache flush on ms_site_not_found
    Given a FP multisite installation
    And a fp-cli.yml file:
      """
      url: invalid.com
      """
    And I run `fp package install fp-cli/cache-command`

    When I try `fp cache add foo bar`
    Then STDERR should contain:
      """
      Error: Site 'invalid.com' not found.
      """
    And the return code should be 1

    When I try `fp cache flush --url=invalid.com`
    Then STDOUT should contain:
      """
      Success: The cache was flushed.
      """
    And the return code should be 0

  # `fp search-replace` does not yet support SQLite
  # See https://github.com/fp-cli/search-replace-command/issues/190
  @require-fp-4.0 @require-mysql
  Scenario: Run search-replace on ms_site_not_found
    Given a FP multisite installation
    And a fp-cli.yml file:
      """
      url: invalid.com
      """
    And I run `fp package install fp-cli/search-replace-command`

    When I try `fp search-replace foo bar`
    Then STDERR should contain:
      """
      Error: Site 'invalid.com' not found.
      """
    And the return code should be 1

    When I run `fp option update test_key '["foo"]' --format=json --url=example.com`
    Then STDOUT should contain:
      """
      Success:
      """

    # --network should permit search-replace
    When I run `fp search-replace foo bar --network`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

    When I run `fp option update test_key '["foo"]' --format=json --url=example.com`
    Then STDOUT should contain:
      """
      Success:
      """

    # --all-tables should permit search-replace
    When I run `fp search-replace foo bar --all-tables`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

    When I run `fp option update test_key '["foo"]' --format=json --url=example.com`
    Then STDOUT should contain:
      """
      Success:
      """

    # --all-tables-with-prefix should permit search-replace
    When I run `fp search-replace foo bar --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

    When I run `fp option update test_key '["foo"]' --format=json --url=example.com`
    Then STDOUT should contain:
      """
      Success:
      """

    # Specific tables should permit search-replace
    When I run `fp search-replace foo bar fp_options`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

  Scenario: Allow disabling ini_set()
    Given an empty directory
    When I try `{INVOKE_FP_CLI_WITH_PHP_ARGS--ddisable_functions=ini_set} cli info`
    Then the return code should be 0

  Scenario: Test early root detection

    Given an empty directory
    And a include.php file:
    """
    <?php
      namespace FP_CLI\Bootstrap;

      // To override posix_geteuid in our namespace
      function posix_geteuid() {
        return 0;
      }
    ?>
    """

    And I try `FP_CLI_EARLY_REQUIRE=include.php fp cli version --debug`

    Then STDERR should contain:
    """
    FP_CLI\Bootstrap\CheckRoot
    """

    And STDERR should not contain:
    """
    FP_CLI\Bootstrap\IncludeRequestsAutoloader
    """

    And STDERR should contain:
    """
    YIKES!
    """
