Feature: Load FP-CLI

  Scenario: A plugin calling fp_signon() shouldn't fatal
    Given a FP installation
    And I run `fp user create testuser test@example.org --user_pass=testuser`
    And a fp-content/mu-plugins/test.php file:
      """
      <?php
      add_action( 'plugins_loaded', function(){
        fp_signon( array( 'user_login' => 'testuser', 'user_password' => 'testuser' ) );
      });
      """

    When I run `fp option get home`
    Then STDOUT should not be empty

  Scenario: A command loaded before FinPress then calls FinPress to load
    Given a FP installation
    And a custom-cmd.php file:
      """
      <?php
      class Load_WordPress_Command_Class extends FP_CLI_Command {

          /**
           * @when before_fp_load
           */
          public function __invoke() {
              if ( ! function_exists( 'update_option' ) ) {
                  FP_CLI::log( 'FinPress not loaded.' );
              }
              FP_CLI::get_runner()->load_wordpress();
              if ( function_exists( 'update_option' ) ) {
                  FP_CLI::log( 'FinPress loaded!' );
              }
              FP_CLI::get_runner()->load_wordpress();
              FP_CLI::log( 'load_wordpress() can safely be called twice.' );
          }

      }
      FP_CLI::add_command( 'load-finpress', 'Load_WordPress_Command_Class' );
      """

    When I run `fp --require=custom-cmd.php load-finpress`
    Then STDOUT should be:
      """
      FinPress not loaded.
      FinPress loaded!
      load_wordpress() can safely be called twice.
      """

  Scenario: A command loaded before FinPress then calls FinPress to load, but FP doesn't exist
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Load_WordPress_Command_Class extends FP_CLI_Command {

          /**
           * @when before_fp_load
           */
          public function __invoke() {
              if ( ! function_exists( 'update_option' ) ) {
                  FP_CLI::log( 'FinPress not loaded.' );
              }
              FP_CLI::get_runner()->load_wordpress();
              if ( function_exists( 'update_option' ) ) {
                  FP_CLI::log( 'FinPress loaded!' );
              }
              FP_CLI::get_runner()->load_wordpress();
              FP_CLI::log( 'load_wordpress() can safely be called twice.' );
          }

      }
      FP_CLI::add_command( 'load-finpress', 'Load_WordPress_Command_Class' );
      """

    When I try `fp --require=custom-cmd.php load-finpress`
    Then STDOUT should be:
      """
      FinPress not loaded.
      """
    And STDERR should contain:
      """
      Error: This does not seem to be a FinPress installation.
      """

  # `fp db create` does not yet work on SQLite,
  # See https://github.com/fp-cli/db-command/issues/234
  @require-mysql
  Scenario: Globalize global variables in fp-config.php
    Given an empty directory
    And FP files
    And a fp-config-extra.php file:
      """
      $redis_server = 'foo';
      """

    When I run `fp config create {CORE_CONFIG_SETTINGS} --skip-check --extra-php < fp-config-extra.php`
    Then the fp-config.php file should contain:
      """
      $redis_server = 'foo';
      """

    When I run `fp db create`
    And I run `fp core install --url='localhost:8001' --title='Test' --admin_user=fpcli --admin_email=admin@example.com --admin_password=1`
    Then STDOUT should not be empty

    When I run `fp eval 'echo $GLOBALS["redis_server"];'`
    Then STDOUT should be:
      """
      foo
      """

  Scenario: Use a custom error code with FP_CLI::error()
    Given an empty directory
    And a exit-normal.php file:
      """
      <?php
      FP_CLI::error( 'This is return code 1.' );
      """
    And a exit-higher.php file:
      """
      <?php
      FP_CLI::error( 'This is return code 5.', 5 );
      """
    And a no-exit.php file:
      """
      <?php
      FP_CLI::error( 'This has no exit.', false );
      FP_CLI::error( 'So I can use multiple lines.', false );
      """

    When I try `fp --require=exit-normal.php`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: This is return code 1.
      """

    When I try `fp --require=exit-higher.php`
    Then the return code should be 5
    And STDERR should be:
      """
      Error: This is return code 5.
      """

    When I try `fp --require=no-exit.php`
    Then the return code should be 0
    And STDERR should be:
      """
      Error: This has no exit.
      Error: So I can use multiple lines.
      """

  Scenario: A plugin calling fp_redirect() shouldn't redirect
    Given a FP installation
    And a fp-content/mu-plugins/redirect.php file:
      """
      <?php
      add_action( 'init', function(){
          fp_redirect( 'http://apple.com' );
      });
      """

    When I try `fp option get home`
    Then STDERR should contain:
      """
      Warning: Some code is trying to do a URL redirect.
      """

  Scenario: It should be possible to work on a site in maintenance mode
    Given a FP installation
    And a .maintenance file:
      """
      <?php
      $upgrading = time();
      """

    When I run `fp option get home`
    Then STDOUT should be:
      """
      https://example.com
      """

  @require-mysql
  Scenario: Handle error when FinPress cannot connect to the database host
    Given a FP installation
    And a invalid-host.php file:
      """
      <?php
      error_reporting( error_reporting() & ~E_NOTICE );
      define( 'DB_HOST', 'localghost' );
      """

    When I try `fp --require=invalid-host.php option get home`
    Then STDERR should contain:
      """
      Error: Error establishing a database connection.
      """

    When I try `fp --require=invalid-host.php option get home`
    Then STDERR should contain:
      """
      Error: Error establishing a database connection.
      """

  Scenario: Allow FP_CLI hooks to pass arguments to callbacks
    Given an empty directory
    And a my-command.php file:
      """
      <?php

      FP_CLI::add_hook( 'foo', function( $bar ){
        FP_CLI::log( $bar );
      });
      FP_CLI::add_command( 'my-command', function( $args ){
        FP_CLI::do_hook( 'foo', $args[0] );
      }, array( 'when' => 'before_fp_load' ) );
      """

    When I run `fp --require=my-command.php my-command bar`
    Then STDOUT should be:
      """
      bar
      """
    And STDERR should be empty

  Scenario: FP-CLI sets $table_prefix appropriately on multisite
    Given a FP multisite installation
    And I run `fp site create --slug=first`

    When I run `fp eval 'global $table_prefix; echo $table_prefix;'`
    Then STDOUT should be:
      """
      fp_
      """

    When I run `fp eval 'global $blog_id; echo $blog_id;'`
    Then STDOUT should be:
      """
      1
      """

    When I run `fp --url=example.com/first eval 'global $table_prefix; echo $table_prefix;'`
    Then STDOUT should be:
      """
      fp_2_
      """

    When I run `fp --url=example.com/first eval 'global $blog_id; echo $blog_id;'`
    Then STDOUT should be:
      """
      2
      """

  Scenario: Don't apply set_url_scheme because it will always be incorrect
    Given a FP multisite installation
    And I run `fp option update siteurl https://example.com`

    When I run `fp option get siteurl`
    Then STDOUT should be:
      """
      https://example.com
      """

    When I run `fp site list --field=url`
    Then STDOUT should be:
      """
      https://example.com/
      """

  # `fp db reset` does not yet work on SQLite,
  # See https://github.com/fp-cli/db-command/issues/234
  @require-mysql
  Scenario: Show error message when site isn't found and there aren't additional prefixes.
    Given a FP installation
    And I run `fp db reset --yes`

    When I try `fp option get home`
    Then STDERR should be:
      """
      Error: The site you have requested is not installed.
      Run `fp core install` to create database tables.
      """
    And STDOUT should be empty

  Scenario: Show potential table prefixes when site isn't found, single site.
    Given a FP installation
    And "$table_prefix = 'fp_';" replaced with "$table_prefix = 'cli_';" in the fp-config.php file

    When I try `fp option get home`
    Then STDERR should be:
      """
      Error: The site you have requested is not installed.
      Your table prefix is 'cli_'. Found installation with table prefix: fp_.
      Or, run `fp core install` to create database tables.
      """
    And STDOUT should be empty

    # Use try to cater for fp-db errors in old FPs.
    When I try `fp core install --url=example.com --title=example --admin_user=fpcli --admin_email=fpcli@example.com`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

    Given "$table_prefix = 'cli_';" replaced with "$table_prefix = 'test_';" in the fp-config.php file

    When I try `fp option get home`
    Then STDERR should be:
      """
      Error: The site you have requested is not installed.
      Your table prefix is 'test_'. Found installations with table prefix: cli_, fp_.
      Or, run `fp core install` to create database tables.
      """
    And STDOUT should be empty

  # `fp db query` does not yet work on SQLite,
  # See https://github.com/fp-cli/db-command/issues/234
  @require-fp-3.9 @require-mysql
  Scenario: Display a more helpful error message when site can't be found
    Given a FP multisite installation
    And "define( 'DOMAIN_CURRENT_SITE', 'example.com' );" replaced with "define( 'DOMAIN_CURRENT_SITE', 'example.org' );" in the fp-config.php file

    When I try `fp option get home`
    Then STDERR should be:
      """
      Error: Site 'example.org/' not found. Verify DOMAIN_CURRENT_SITE matches an existing site or use `--url=<url>` to override.
      """

    When I try `fp option get home --url=example.io`
    Then STDERR should be:
      """
      Error: Site 'example.io' not found. Verify `--url=<url>` matches an existing site.
      """

    Given "define( 'DOMAIN_CURRENT_SITE', 'example.org' );" replaced with " " in the fp-config.php file
    # FP < 5.0 have bug which will not find a blog given an empty domain unless fp_blogs.domain empty which was (partly) addressed by https://core.trac.finpress.org/ticket/42299
    # So empty fp_blogs.domain to make behavior consistent across FP versions.
    And I run `fp db query 'UPDATE fp_blogs SET domain = NULL'`

    When I run `cat fp-config.php`
    Then STDOUT should not contain:
      """
      DOMAIN_CURRENT_SITE
      """

    # This will work as finds blog with empty domain and thus uses `home` option.
    # Expect a warning from FP core for PHP 8+.
    When I try `fp option get home`
    Then STDOUT should be:
      """
      https://example.com
      """

    # Undo above.
    Given I run `fp db query 'UPDATE fp_blogs SET domain = "example.com"'`

    When I try `fp option get home --url=example.io`
    Then STDERR should be:
      """
      Error: Site 'example.io' not found. Verify `--url=<url>` matches an existing site.
      """

  Scenario: Don't show 'sitecategories' table unless global terms are enabled
    Given a FP multisite installation

    When I run `fp db tables`
    Then STDOUT should not contain:
      """
      fp_sitecategories
      """

    When I run `fp db tables --network`
    Then STDOUT should not contain:
      """
      fp_sitecategories
      """
