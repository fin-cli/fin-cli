Feature: Tests `FP_CLI::add_hook()`

  Scenario: Add callback to the `before_invoke:plugin list`
    Given a FP installation
    And a before-invoke.php file:
      """
      <?php
      $callback = function() {
        FP_CLI::log( '`add_hook()` to the `before_invoke` is working.');
      };

      FP_CLI::add_hook( 'before_invoke:plugin list', $callback );
      """
    And a fp-cli.yml file:
      """
      require:
        - before-invoke.php
      """

    When I run `fp plugin list`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_invoke` is working.
      """
    And the return code should be 0

  # `fp db check` does not yet work on SQLite,
  # See https://github.com/fp-cli/db-command/issues/234
  @require-mysql
  Scenario: Add callback to the `before_invoke:db check`
    Given a FP installation
    And a before-invoke.php file:
      """
      <?php
      $callback = function() {
        FP_CLI::log( '`add_hook()` to the `before_invoke` is working.');
      };

      FP_CLI::add_hook( 'before_invoke:db check', $callback );
      """
    And a fp-cli.yml file:
      """
      require:
        - before-invoke.php
      """

    When I run `fp db check`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_invoke` is working.
      """
    And the return code should be 0

  Scenario: Add callback to the `before_invoke:core version`
    Given a FP installation
    And a before-invoke.php file:
      """
      <?php
      $callback = function() {
        FP_CLI::log( '`add_hook()` to the `before_invoke` is working.');
      };

      FP_CLI::add_hook( 'before_invoke:core version', $callback );
      """
    And a fp-cli.yml file:
      """
      require:
        - before-invoke.php
      """

    When I run `fp core version`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_invoke` is working.
      """
    And the return code should be 0

  Scenario: Add callback to the `before_run_command` with args
    Given a FP installation
    And a before-run-command.php file:
      """
      <?php
      $callback = function ( $args, $assoc_args, $options ) {
        FP_CLI::log( '`add_hook()` to the `before_run_command` is working.' );
        if ( 'version' !== $args[1] ) {
          FP_CLI::error( 'Arg context not being passed in to callback properly' );
        }

        if ( ! array_key_exists( 'extra', $assoc_args ) ) {
          FP_CLI::error( 'Assoc arg context not being passed in to callback properly' );
        }
      };

      FP_CLI::add_hook( 'before_run_command', $callback );
      """
    And a fp-cli.yml file:
      """
      require:
        - before-run-command.php
      """

    When I run `fp core version --extra`
    Then STDOUT should contain:
      """
      `add_hook()` to the `before_run_command` is working.
      """
    And the return code should be 0

  Scenario: Use return value of a callback hook
    Given a FP installation
    And a custom-hook.php file:
      """
      <?php
      $callback = function ( $first, $second ) {
        FP_CLI::log( '`add_hook()` to the `custom_hook` is working.' );
        if ( 'value1' !== $first ) {
          FP_CLI::error( 'First argument is not being passed in to callback properly' );
        }

        if ( 'value2' !== $second ) {
          FP_CLI::error( 'Second argument is not being passed in to callback properly' );
        }

        return 'value3';
      };

      FP_CLI::add_hook( 'custom_hook', $callback );

      $result = FP_CLI::do_hook( 'custom_hook', 'value1', 'value2' );

      if ( empty( $result ) ) {
        FP_CLI::error( 'First argument is not returned via do_hook()' );
      }

      if ( 'value3' !== $result ) {
        FP_CLI::error( 'First argument is not mutable via do_hook()' );
      }
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-hook.php
      """

    When I run `fp cli version`
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
    Given a FP installation
    And a custom-hook.php file:
      """
      <?php
      $callback = function ( $first, $second ) {
        FP_CLI::log( '`add_hook()` to the `custom_hook` is working.' );
        if ( 'value1' !== $first ) {
          FP_CLI::error( 'First argument is not being passed in to callback properly' );
        }

        if ( 'value2' !== $second ) {
          FP_CLI::error( 'Second argument is not being passed in to callback properly' );
        }
      };

      FP_CLI::add_hook( 'custom_hook', $callback );

      $result = FP_CLI::do_hook( 'custom_hook', 'value1', 'value2' );

      if ( empty( $result ) ) {
        FP_CLI::error( 'First argument is not returned via do_hook()' );
      }

      if ( 'value1' !== $result ) {
        FP_CLI::error( 'First argument is not correctly returned on bad callback missing return' );
      }
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-hook.php
      """

    When I run `fp cli version`
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
