Feature: Tests `FIN_CLI::add_hook()`

  Scenario: Add callback to the `before_invoke:plugin list`
    Given a FIN installation
    And a before-invoke.php file:
      """
      <?php
      $callback = function() {
        FIN_CLI::log( '`add_hook()` to the `before_invoke` is working.');
      };

      FIN_CLI::add_hook( 'before_invoke:plugin list', $callback );
      """
    And a fin-cli.yml file:
      """
      require:
        - before-invoke.php
      """

    When I run `fin plugin list`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_invoke` is working.
      """
    And the return code should be 0

  # `fin db check` does not yet work on SQLite,
  # See https://github.com/fin-cli/db-command/issues/234
  @require-mysql
  Scenario: Add callback to the `before_invoke:db check`
    Given a FIN installation
    And a before-invoke.php file:
      """
      <?php
      $callback = function() {
        FIN_CLI::log( '`add_hook()` to the `before_invoke` is working.');
      };

      FIN_CLI::add_hook( 'before_invoke:db check', $callback );
      """
    And a fin-cli.yml file:
      """
      require:
        - before-invoke.php
      """

    When I run `fin db check`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_invoke` is working.
      """
    And the return code should be 0

  Scenario: Add callback to the `before_invoke:core version`
    Given a FIN installation
    And a before-invoke.php file:
      """
      <?php
      $callback = function() {
        FIN_CLI::log( '`add_hook()` to the `before_invoke` is working.');
      };

      FIN_CLI::add_hook( 'before_invoke:core version', $callback );
      """
    And a fin-cli.yml file:
      """
      require:
        - before-invoke.php
      """

    When I run `fin core version`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_invoke` is working.
      """
    And the return code should be 0

  Scenario: Add callback to the `before_run_command` with args
    Given a FIN installation
    And a before-run-command.php file:
      """
      <?php
      $callback = function ( $args, $assoc_args, $options ) {
        FIN_CLI::log( '`add_hook()` to the `before_run_command` is working.' );
        if ( 'version' !== $args[1] ) {
          FIN_CLI::error( 'Arg context not being passed in to callback properly' );
        }

        if ( ! array_key_exists( 'extra', $assoc_args ) ) {
          FIN_CLI::error( 'Assoc arg context not being passed in to callback properly' );
        }
      };

      FIN_CLI::add_hook( 'before_run_command', $callback );
      """
    And a fin-cli.yml file:
      """
      require:
        - before-run-command.php
      """

    When I run `fin core version --extra`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_run_command` is working.
      """
    And the return code should be 0

  Scenario: Use return value of a callback hook
    Given a FIN installation
    And a custom-hook.php file:
      """
      <?php
      $callback = function ( $first, $second ) {
        FIN_CLI::log( '`add_hook()` to the `custom_hook` is working.' );
        if ( 'value1' !== $first ) {
          FIN_CLI::error( 'First argument is not being passed in to callback properly' );
        }

        if ( 'value2' !== $second ) {
          FIN_CLI::error( 'Second argument is not being passed in to callback properly' );
        }

        return 'value3';
      };

      FIN_CLI::add_hook( 'custom_hook', $callback );

      $result = FIN_CLI::do_hook( 'custom_hook', 'value1', 'value2' );

      if ( empty( $result ) ) {
        FIN_CLI::error( 'First argument is not returned via do_hook()' );
      }

      if ( 'value3' !== $result ) {
        FIN_CLI::error( 'First argument is not mutable via do_hook()' );
      }
      """
    And a fin-cli.yml file:
      """
      require:
        - custom-hook.php
      """

    When I run `fin cli version`
    Then STDOUT should contain:
      """
      `add_hook()` to the `custom_hook` is working.
      """
    And STDOUT should not contain:
      """
      First argument is not being passed in to callback properly
      """
    And STDOUT should not contain:
      """
      Second argument is not being passed in to callback properly
      """
    And STDOUT should not contain:
      """
      First argument is not returned via do_hook()
      """
    And STDOUT should not contain:
      """
      First argument is not mutable via do_hook()
      """
    And the return code should be 0

  Scenario: Callback hook with arguments does not break on bad callback
    Given a FIN installation
    And a custom-hook.php file:
      """
      <?php
      $callback = function ( $first, $second ) {
        FIN_CLI::log( '`add_hook()` to the `custom_hook` is working.' );
        if ( 'value1' !== $first ) {
          FIN_CLI::error( 'First argument is not being passed in to callback properly' );
        }

        if ( 'value2' !== $second ) {
          FIN_CLI::error( 'Second argument is not being passed in to callback properly' );
        }
      };

      FIN_CLI::add_hook( 'custom_hook', $callback );

      $result = FIN_CLI::do_hook( 'custom_hook', 'value1', 'value2' );

      if ( empty( $result ) ) {
        FIN_CLI::error( 'First argument is not returned via do_hook()' );
      }

      if ( 'value1' !== $result ) {
        FIN_CLI::error( 'First argument is not correctly returned on bad callback missing return' );
      }
      """
    And a fin-cli.yml file:
      """
      require:
        - custom-hook.php
      """

    When I run `fin cli version`
    Then STDOUT should contain:
      """
      `add_hook()` to the `custom_hook` is working.
      """
    And STDOUT should not contain:
      """
      First argument is not being passed in to callback properly
      """
    And STDOUT should not contain:
      """
      Second argument is not being passed in to callback properly
      """
    And STDOUT should not contain:
      """
      First argument is not returned via do_hook()
      """
    And STDOUT should not contain:
      """
      First argument is not correctly returned on bad callback missing return
      """
    And the return code should be 0
