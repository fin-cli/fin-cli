Feature: Context handling via --context global flag

  Scenario: CLI context can be selected, but is same as default
    Given a FP install

    When I run `fp eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      false
      """

    When I run `fp --context=cli eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      false
      """

    When I run `fp eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fp --context=cli eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fp eval 'add_action( "admin_init", static function () { FP_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

    When I run `fp --context=cli eval 'add_action( "admin_init", static function () { FP_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

  Scenario: Admin context can be selected
    Given a FP install

    When I run `fp --context=admin eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fp --context=admin eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fp eval --context=admin 'add_action( "admin_init", static function () { FP_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

  Scenario: Frontend context can be selected (and does nothing yet...)
    Given a FP install

    When I run `fp --context=frontend eval 'var_export( is_admin() );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      false
      """

    When I run `fp --context=frontend eval 'var_export( function_exists( "media_handle_upload" ) );'`
    Then the return code should be 0
    And STDOUT should be:
      """
      true
      """

    When I run `fp --context=frontend eval 'add_action( "admin_init", static function () { FP_CLI::warning( "admin_init was triggered." ); } );'`
    Then the return code should be 0
    And STDERR should not contain:
      """
      admin_init was triggered.
      """

  Scenario: Auto context can be selected and changes environment based on command
    Given a FP install
    And a context-logger.php file:
      """
      <?php
      FP_CLI::add_hook( 'before_run_command', static function () {
        $context = FP_CLI::get_runner()->context_manager->get_context();
        FP_CLI::log( "Current context: {$context}" );
      } );
      """

    When I run `fp --require=context-logger.php --context=auto post list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      Current context: cli
      """

    When I run `fp --require=context-logger.php --context=auto plugin list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      Current context: admin
      """

  Scenario: Unknown contexts throw an exception
    Given a FP install

    When I try `fp --context=nonsense post list`
    Then the return code should be 1
    And STDOUT should be empty
    And STDERR should contain:
      """
      Error: Unknown context 'nonsense'
      """

  Scenario: Bundled contexts can be filtered
    Given a FP install
    And a custom-contexts.php file:
      """
      <?php

      final class OverriddenAdminContext implements \FP_CLI\Context {
        public function process( $config ) {
          \FP_CLI::log( 'admin context was overridden' );
        }
      }

      final class CustomContext implements \FP_CLI\Context {
        public function process( $config ) {
          \FP_CLI::log( 'custom context was added' );
        }
      }

      FP_CLI::add_hook( 'before_registering_contexts', static function ( $contexts ) {
        unset( $contexts['frontend'] );
        $contexts['admin']          = new OverriddenAdminContext();
        $contexts['custom_context'] = new CustomContext();
        return $contexts;
      } );
      """

    When I try `fp --require=custom-contexts.php --context=frontend post list`
    Then the return code should be 1
    And STDOUT should be empty
    And STDERR should contain:
      """
      Error: Unknown context 'frontend'
      """

    When I run `fp --require=custom-contexts.php --context=admin post list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      admin context was overridden
      """

    When I run `fp --require=custom-contexts.php --context=custom_context post list`
    Then the return code should be 0
    And STDOUT should contain:
      """
      custom context was added
      """

  Scenario: Core fp-admin/admin.php with CRLF lines does not fail.
    Given a FP install
    And a modify-fp-admin.php file:
      """
      <?php
      $admin_php_file = file( __DIR__ . '/fp-admin/admin.php' );
      $admin_php_file = implode( "\r\n", array_map( 'trim', $admin_php_file ) );
      file_put_contents( __DIR__ . '/fp-admin/admin.php', $admin_php_file );
      unset( $admin_php_file );
      """

    When I run `fp --require=modify-fp-admin.php --context=admin eval 'var_export( is_admin() );'`
    And STDOUT should be:
      """
      true
      """
