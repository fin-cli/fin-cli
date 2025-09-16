Feature: Context handling via --context global flag

  Scenario: CLI context can be selected, but is same as default
    Given a FIN install

    When I run `fin eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      false
      """

    When I run `fin --context=cli eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      false
      """

    When I run `fin eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fin --context=cli eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fin eval 'add_action( "admin_init", static function () { FIN_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

    When I run `fin --context=cli eval 'add_action( "admin_init", static function () { FIN_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

  Scenario: Admin context can be selected
    Given a FIN install

    When I run `fin --context=admin eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fin --context=admin eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fin eval --context=admin 'add_action( "admin_init", static function () { FIN_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

  Scenario: Frontend context can be selected (and does nothing yet...)
    Given a FIN install

    When I run `fin --context=frontend eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      false
      """

    When I run `fin --context=frontend eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fin --context=frontend eval 'add_action( "admin_init", static function () { FIN_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

  Scenario: Auto context can be selected and changes environment based on command
    Given a FIN install
    And a context-logger.php file:
      """
      <?php
      FIN_CLI::add_hook( 'before_run_command', static function () {
        $context = FIN_CLI::get_runner()->context_manager->get_context();
        FIN_CLI::log( "Current context: {$context}" );
      } );
      """

    When I run `fin --require=context-logger.php --context=auto post list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      Current context: cli
      """

    When I run `fin --require=context-logger.php --context=auto plugin list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      Current context: admin
      """

  Scenario: Unknown contexts throw an exception
    Given a FIN install

    When I try `fin --context=nonsense post list`
    Then the return code should be 1
    And STDOUT should be empty
    And STDERR should contain:
      """
      Error: Unknown context 'nonsense'
      """

  Scenario: Bundled contexts can be filtered
    Given a FIN install
    And a custom-contexts.php file:
      """
      <?php

      final class OverriddenAdminContext implements \FIN_CLI\Context {
        public function process( $config ) {
          \FIN_CLI::log( 'admin context was overridden' );
        }
      }

      final class CustomContext implements \FIN_CLI\Context {
        public function process( $config ) {
          \FIN_CLI::log( 'custom context was added' );
        }
      }

      FIN_CLI::add_hook( 'before_registering_contexts', static function ( $contexts ) {
        unset( $contexts['frontend'] );
        $contexts['admin']          = new OverriddenAdminContext();
        $contexts['custom_context'] = new CustomContext();
        return $contexts;
      } );
      """

    When I try `fin --require=custom-contexts.php --context=frontend post list`
    Then the return code should be 1
    And STDOUT should be empty
    And STDERR should contain:
      """
      Error: Unknown context 'frontend'
      """

    When I run `fin --require=custom-contexts.php --context=admin post list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      admin context was overridden
      """

    When I run `fin --require=custom-contexts.php --context=custom_context post list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      custom context was added
      """

  Scenario: Core fin-admin/admin.php with CRLF lines does not fail.
    Given a FIN install
    And a modify-fin-admin.php file:
      """
      <?php
      $admin_php_file = file( __DIR__ . '/fin-admin/admin.php' );
      $admin_php_file = implode( "\r\n", array_map( 'trim', $admin_php_file ) );
      file_put_contents( __DIR__ . '/fin-admin/admin.php', $admin_php_file );
      unset( $admin_php_file );
      """

    When I run `fin --require=modify-fin-admin.php --context=admin eval 'var_export( is_admin() );'`
    And STDOUT should be:
      """
      true
      """
