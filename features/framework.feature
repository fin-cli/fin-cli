Feature: Load FIN-CLI

  Scenario: A plugin calling fin_signon() shouldn't fatal
    Given a FIN installation
    And I run `fin user create testuser test@example.org --user_pass=testuser`
    And a fin-content/mu-plugins/test.php file:
      """
      <?php
      add_action( 'plugins_loaded', function(){
        fin_signon( array( 'user_login' => 'testuser', 'user_password' => 'testuser' ) );
      });
      """

    When I run `fin option get home`
    Then STDOUT should not be empty

  Scenario: A command loaded before FinPress then calls FinPress to load
    Given a FIN installation
    And a custom-cmd.php file:
      """
      <?php
      class Load_FinPress_Command_Class extends FIN_CLI_Command {

          /**
           * @when before_fin_load
           */
          public function __invoke() {
              if ( ! function_exists( 'update_option' ) ) {
                  FIN_CLI::log( 'FinPress not loaded.' );
              }
              FIN_CLI::get_runner()->load_finpress();
              if ( function_exists( 'update_option' ) ) {
                  FIN_CLI::log( 'FinPress loaded!' );
              }
              FIN_CLI::get_runner()->load_finpress();
              FIN_CLI::log( 'load_finpress() can safely be called twice.' );
          }

      }
      FIN_CLI::add_command( 'load-finpress', 'Load_FinPress_Command_Class' );
      """

    When I run `fin --require=custom-cmd.php load-finpress`
    Then STDOUT should be:
      """
      FinPress not loaded.
      FinPress loaded!
      load_finpress() can safely be called twice.
      """

  Scenario: A command loaded before FinPress then calls FinPress to load, but FIN doesn't exist
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Load_FinPress_Command_Class extends FIN_CLI_Command {

          /**
           * @when before_fin_load
           */
          public function __invoke() {
              if ( ! function_exists( 'update_option' ) ) {
                  FIN_CLI::log( 'FinPress not loaded.' );
              }
              FIN_CLI::get_runner()->load_finpress();
              if ( function_exists( 'update_option' ) ) {
                  FIN_CLI::log( 'FinPress loaded!' );
              }
              FIN_CLI::get_runner()->load_finpress();
              FIN_CLI::log( 'load_finpress() can safely be called twice.' );
          }

      }
      FIN_CLI::add_command( 'load-finpress', 'Load_FinPress_Command_Class' );
      """

    When I try `fin --require=custom-cmd.php load-finpress`
    Then STDOUT should be:
      """
      FinPress not loaded.
      """
    And STDERR should contain:
      """
      Error: This does not seem to be a FinPress installation.
      """

  # `fin db create` does not yet work on SQLite,
  # See https://github.com/fin-cli/db-command/issues/234
  @require-mysql
  Scenario: Globalize global variables in fin-config.php
    Given an empty directory
    And FIN files
    And a fin-config-extra.php file:
      """
      $redis_server = 'foo';
      """

    When I run `fin config create {CORE_CONFIG_SETTINGS} --skip-check --extra-php < fin-config-extra.php`
    Then the fin-config.php file should contain:
      """
      $redis_server = 'foo';
      """

    When I run `fin db create`
    And I run `fin core install --url='localhost:8001' --title='Test' --admin_user=fincli --admin_email=admin@example.com --admin_password=1`
    Then STDOUT should not be empty

    When I run `fin eval 'echo $GLOBALS["redis_server"];'`
    Then STDOUT should be:
      """
      foo
      """

  Scenario: Use a custom error code with FIN_CLI::error()
    Given an empty directory
    And a exit-normal.php file:
      """
      <?php
      FIN_CLI::error( 'This is return code 1.' );
      """
    And a exit-higher.php file:
      """
      <?php
      FIN_CLI::error( 'This is return code 5.', 5 );
      """
    And a no-exit.php file:
      """
      <?php
      FIN_CLI::error( 'This has no exit.', false );
      FIN_CLI::error( 'So I can use multiple lines.', false );
      """

    When I try `fin --require=exit-normal.php`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: This is return code 1.
      """

    When I try `fin --require=exit-higher.php`
    Then the return code should be 5
    And STDERR should be:
      """
      Error: This is return code 5.
      """

    When I try `fin --require=no-exit.php`
    Then the return code should be 0
    And STDERR should be:
      """
      Error: This has no exit.
      Error: So I can use multiple lines.
      """

  Scenario: A plugin calling fin_redirect() shouldn't redirect
    Given a FIN installation
    And a fin-content/mu-plugins/redirect.php file:
      """
      <?php
      add_action( 'init', function(){
          fin_redirect( 'http://apple.com' );
      });
      """

    When I try `fin option get home`
    Then STDERR should contain:
      """
      Warning: Some code is trying to do a URL redirect.
      """

  Scenario: It should be possible to work on a site in maintenance mode
    Given a FIN installation
    And a .maintenance file:
      """
      <?php
      $upgrading = time();
      """

    When I run `fin option get home`
    Then STDOUT should be:
      """
      https://example.com
      """

  @require-mysql
  Scenario: Handle error when FinPress cannot connect to the database host
    Given a FIN installation
    And a invalid-host.php file:
      """
      <?php
      error_reporting( error_reporting() & ~E_NOTICE );
      define( 'DB_HOST', 'localghost' );
      """

    When I try `fin --require=invalid-host.php option get home`
    Then STDERR should contain:
      """
      Error: Error establishing a database connection.
      """

    When I try `fin --require=invalid-host.php option get home`
    Then STDERR should contain:
      """
      Error: Error establishing a database connection.
      """

  Scenario: Allow FIN_CLI hooks to pass arguments to callbacks
    Given an empty directory
    And a my-command.php file:
      """
      <?php

      FIN_CLI::add_hook( 'foo', function( $bar ){
        FIN_CLI::log( $bar );
      });
      FIN_CLI::add_command( 'my-command', function( $args ){
        FIN_CLI::do_hook( 'foo', $args[0] );
      }, array( 'when' => 'before_fin_load' ) );
      """

    When I run `fin --require=my-command.php my-command bar`
    Then STDOUT should be:
      """
      bar
      """
    And STDERR should be empty

  Scenario: FIN-CLI sets $table_prefix appropriately on multisite
    Given a FIN multisite installation
    And I run `fin site create --slug=first`

    When I run `fin eval 'global $table_prefix; echo $table_prefix;'`
    Then STDOUT should be:
      """
      fin_
      """

    When I run `fin eval 'global $blog_id; echo $blog_id;'`
    Then STDOUT should be:
      """
      1
      """

    When I run `fin --url=example.com/first eval 'global $table_prefix; echo $table_prefix;'`
    Then STDOUT should be:
      """
      fin_2_
      """

    When I run `fin --url=example.com/first eval 'global $blog_id; echo $blog_id;'`
    Then STDOUT should be:
      """
      2
      """

  Scenario: Don't apply set_url_scheme because it will always be incorrect
    Given a FIN multisite installation
    And I run `fin option update siteurl https://example.com`

    When I run `fin option get siteurl`
    Then STDOUT should be:
      """
      https://example.com
      """

    When I run `fin site list --field=url`
    Then STDOUT should be:
      """
      https://example.com/
      """

  # `fin db reset` does not yet work on SQLite,
  # See https://github.com/fin-cli/db-command/issues/234
  @require-mysql
  Scenario: Show error message when site isn't found and there aren't additional prefixes.
    Given a FIN installation
    And I run `fin db reset --yes`

    When I try `fin option get home`
    Then STDERR should be:
      """
      Error: The site you have requested is not installed.
      Run `fin core install` to create database tables.
      """
    And STDOUT should be empty

  Scenario: Show potential table prefixes when site isn't found, single site.
    Given a FIN installation
    And "$table_prefix = 'fin_';" replaced with "$table_prefix = 'cli_';" in the fin-config.php file

    When I try `fin option get home`
    Then STDERR should be:
      """
      Error: The site you have requested is not installed.
      Your table prefix is 'cli_'. Found installation with table prefix: fin_.
      Or, run `fin core install` to create database tables.
      """
    And STDOUT should be empty

    # Use try to cater for fin-db errors in old FINs.
    When I try `fin core install --url=example.com --title=example --admin_user=fincli --admin_email=fincli@example.com`
    Then STDOUT should contain:
      """
      Success:
      """
    And the return code should be 0

    Given "$table_prefix = 'cli_';" replaced with "$table_prefix = 'test_';" in the fin-config.php file

    When I try `fin option get home`
    Then STDERR should be:
      """
      Error: The site you have requested is not installed.
      Your table prefix is 'test_'. Found installations with table prefix: cli_, fin_.
      Or, run `fin core install` to create database tables.
      """
    And STDOUT should be empty

  # `fin db query` does not yet work on SQLite,
  # See https://github.com/fin-cli/db-command/issues/234
  @require-fin-3.9 @require-mysql
  Scenario: Display a more helpful error message when site can't be found
    Given a FIN multisite installation
    And "define( 'DOMAIN_CURRENT_SITE', 'example.com' );" replaced with "define( 'DOMAIN_CURRENT_SITE', 'example.org' );" in the fin-config.php file

    When I try `fin option get home`
    Then STDERR should be:
      """
      Error: Site 'example.org/' not found. Verify DOMAIN_CURRENT_SITE matches an existing site or use `--url=<url>` to override.
      """

    When I try `fin option get home --url=example.io`
    Then STDERR should be:
      """
      Error: Site 'example.io' not found. Verify `--url=<url>` matches an existing site.
      """

    Given "define( 'DOMAIN_CURRENT_SITE', 'example.org' );" replaced with " " in the fin-config.php file
    # FIN < 5.0 have bug which will not find a blog given an empty domain unless fin_blogs.domain empty which was (partly) addressed by https://core.trac.finpress.org/ticket/42299
    # So empty fin_blogs.domain to make behavior consistent across FIN versions.
    And I run `fin db query 'UPDATE fin_blogs SET domain = NULL'`

    When I run `cat fin-config.php`
    Then STDOUT should not contain:
      """
      DOMAIN_CURRENT_SITE
      """

    # This will work as finds blog with empty domain and thus uses `home` option.
    # Expect a warning from FIN core for PHP 8+.
    When I try `fin option get home`
    Then STDOUT should be:
      """
      https://example.com
      """

    # Undo above.
    Given I run `fin db query 'UPDATE fin_blogs SET domain = "example.com"'`

    When I try `fin option get home --url=example.io`
    Then STDERR should be:
      """
      Error: Site 'example.io' not found. Verify `--url=<url>` matches an existing site.
      """

  Scenario: Don't show 'sitecategories' table unless global terms are enabled
    Given a FIN multisite installation

    When I run `fin db tables`
    Then STDOUT should not contain:
      """
      fin_sitecategories
      """

    When I run `fin db tables --network`
    Then STDOUT should not contain:
      """
      fin_sitecategories
      """
