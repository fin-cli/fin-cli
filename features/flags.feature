Feature: Global flags

  @require-fp-5.5
  Scenario: Setting the URL
    Given a FP installation

    When I run `fp --url=localhost:8001 eval 'echo json_encode( $_SERVER );'`
    Then STDOUT should be JSON containing:
      """
      {
        "HTTP_HOST": "localhost:8001",
        "SERVER_NAME": "localhost",
        "SERVER_PORT": 8001
      }
      """

  @less-than-fp-5.5
  Scenario: Setting the URL
    Given a FP installation

    When I run `fp --url=localhost:8001 eval 'echo json_encode( $_SERVER );'`
    Then STDOUT should be JSON containing:
      """
      {
        "HTTP_HOST": "localhost:8001",
        "SERVER_NAME": "localhost",
        "SERVER_PORT": "8001"
      }
      """

  Scenario: Setting the URL on multisite
    Given a FP multisite installation
    And I run `fp site create --slug=foo`

    When I run `fp --url=example.com/foo option get home`
    Then STDOUT should contain:
      """
      example.com/foo
      """

  @require-fp-3.9
  Scenario: Invalid URL
    Given a FP multisite installation

    When I try `fp post list --url=invalid.example.com`
    Then STDERR should be:
      """
      Error: Site 'invalid.example.com' not found. Verify `--url=<url>` matches an existing site.
      """

  Scenario: Quiet run
    Given a FP installation

    When I try `fp non-existing-command --quiet`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: 'non-existing-command' is not a registered fp command. See 'fp help' for available commands.
      """

  @less-than-php-8
  Scenario: Debug run
    Given a FP installation

    When I try `fp eval 'echo CONST_WITHOUT_QUOTES;'`
    Then STDOUT should be:
      """
      CONST_WITHOUT_QUOTES
      """
    And STDERR should contain:
      """
      Use of undefined constant CONST_WITHOUT_QUOTES
      """
    And the return code should be 0

    When I try `fp eval 'echo CONST_WITHOUT_QUOTES;' --debug`
    Then the return code should be 0
    And STDOUT should be:
      """
      CONST_WITHOUT_QUOTES
      """
    And STDERR should contain:
      """
      Use of undefined constant CONST_WITHOUT_QUOTES
      """

  Scenario: Setting the FP user
    Given a FP installation

    When I run `fp eval 'var_export( is_user_logged_in() );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `fp --user=admin eval 'echo fp_get_current_user()->user_login;'`
    Then STDOUT should be:
      """
      admin
      """
    And STDERR should be empty

    When I run `fp --user=admin@example.com eval 'echo fp_get_current_user()->user_login;'`
    Then STDOUT should be:
      """
      admin
      """
    And STDERR should be empty

    When I try `fp --user=non-existing-user eval 'echo fp_get_current_user()->user_login;'`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: Invalid user ID, email or login: 'non-existing-user'
      """

  Scenario: Warn when provided user is ambiguous
    Given a FP installation

    When I run `fp --user=1 eval 'echo fp_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      admin@example.com
      """
    And STDERR should be empty

    When I run `fp user create 1 user1@example.com`
    Then STDOUT should contain:
      """
      Success:
      """

    When I try `fp --user=1 eval 'echo fp_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      admin@example.com
      """
    And STDERR should be:
      """
      Warning: Ambiguous user match detected (both ID and user_login exist for identifier '1'). FP-CLI will default to the ID, but you can force user_login instead with FP_CLI_FORCE_USER_LOGIN=1.
      """

    When I run `FP_CLI_FORCE_USER_LOGIN=1 fp --user=1 eval 'echo fp_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      user1@example.com
      """
    And STDERR should be empty

    When I run `fp --user=user1@example.com eval 'echo fp_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      user1@example.com
      """
    And STDERR should be empty

    When I try `FP_CLI_FORCE_USER_LOGIN=1 fp --user=user1@example.com eval 'echo fp_get_current_user()->user_email;'`
    Then STDERR should be:
      """
      Error: Invalid user login: 'user1@example.com'
      """

  Scenario: Using a custom logger
    Given an empty directory
    And a custom-logger.php file:
      """
      <?php
      class Dummy_Logger {

        function __call( $method, $args ) {
          echo "log: called '$method' method";
        }
      }

      FP_CLI::set_logger( new Dummy_Logger );
      """

    When I try `fp --require=custom-logger.php is-installed`
    Then STDOUT should contain:
      """
      log: called 'error' method
      """
    And STDERR should be empty
    And the return code should be 1

  Scenario: Using --require
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fp_load
       */
      class Test_Command extends FP_CLI_Command {

        function req( $args, $assoc_args ) {
          FP_CLI::line( $args[0] );
        }
      }

      FP_CLI::add_command( 'test', 'Test_Command' );
      """

    And a foo.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """

    And a bar.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """

    And a fp-cli.yml file:
      """
      require:
        - foo.php
        - bar.php
      """

    And a fp-cli2.yml file:
      """
      require: custom-cmd.php
      """

    When I run `fp --require=custom-cmd.php test req 'This is a custom command.'`
    Then STDOUT should be:
      """
      foo.php
      bar.php
      This is a custom command.
      """

    When I run `FP_CLI_CONFIG_PATH=fp-cli2.yml fp test req 'This is a custom command.'`
    Then STDOUT should contain:
      """
      This is a custom command.
      """

  Scenario: Using --require with globs
    Given an empty directory
    And a foober/foo.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """
    And a foober/bar.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """
    And a doobie/doo.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """

    And a fp-cli.yml file:
      """
      require: foober/*.php
      """

    When I run `fp`
    Then STDOUT should contain:
      """
      bar.php
      foo.php
      """
    When I run `fp --require=doobie/*.php`
    Then STDOUT should contain:
      """
      doo.php
      """

  Scenario: Enabling/disabling color
    Given a FP installation

    When I try `fp --no-color non-existent-command`
    Then STDERR should be:
      """
      Error: 'non-existent-command' is not a registered fp command. See 'fp help' for available commands.
      """

    When I try `fp --color non-existent-command`
    Then STDERR should strictly contain:
      """
      [31;1mError:
      """

  Scenario: Use `FP_CLI_STRICT_ARGS_MODE` to distinguish between global and local args
    Given an empty directory
    And a cmd.php file:
      """
      <?php
      /**
       * @when before_fp_load
       *
       * [--url=<url>]
       * : URL passed to the callback.
       */
      $cmd_test = function( $args, $assoc_args ) {
          $url = FP_CLI::get_runner()->config['url'] ? ' ' . FP_CLI::get_runner()->config['url'] : '';
          FP_CLI::log( 'global:' . $url );
          $url = isset( $assoc_args['url'] ) ? ' ' . $assoc_args['url'] : '';
          FP_CLI::log( 'local:' . $url );
      };
      FP_CLI::add_command( 'cmd-test', $cmd_test );
      """
    And a fp-cli.yml file:
      """
      require:
        - cmd.php
      """

    When I run `fp cmd-test --url=foo.dev`
    Then STDOUT should be:
      """
      global: foo.dev
      local:
      """

    When I run `FP_CLI_STRICT_ARGS_MODE=1 fp cmd-test --url=foo.dev`
    Then STDOUT should be:
      """
      global:
      local: foo.dev
      """

    When I run `FP_CLI_STRICT_ARGS_MODE=1 fp --url=bar.dev cmd-test --url=foo.dev`
    Then STDOUT should be:
      """
      global: bar.dev
      local: foo.dev
      """

  Scenario: Using --http=<url> requires fp-cli/restful
    Given an empty directory

    When I try `fp --http=foo.dev`
    Then STDERR should be:
      """
      Error: RESTful FP-CLI needs to be installed. Try 'fp package install fp-cli/restful'.
      """

  Scenario: Strict args mode should be passed on to ssh
    When I try `FP_CLI_STRICT_ARGS_MODE=1 fp --debug --ssh=/ --version`
    Then STDERR should contain:
      """
      Running SSH command: ssh -T -vvv '' 'FP_CLI_STRICT_ARGS_MODE=1 fp
      """

  Scenario: SSH flag should support changing directories
    When I try `fp --debug --ssh=finpress:/my/path --version`
    Then STDERR should contain:
      """
      Running SSH command: ssh -T -vvv 'finpress' 'cd '\''/my/path'\''; fp
      """

  Scenario: SSH flag should support Docker
    When I try `FP_CLI_DOCKER_NO_INTERACTIVE=1 fp --debug --ssh=docker:user@finpress --version`
    Then STDERR should contain:
      """
      Running SSH command: docker exec --user 'user' 'finpress' sh -c
      """

  Scenario: Customize config-spec with FP_CLI_CONFIG_SPEC_FILTER_CALLBACK
    Given a FP installation
    And a fp-cli-early-require.php file:
      """
      <?php
      function fp_cli_remove_user_arg( $spec ) {
        unset( $spec['user'] );
        return $spec;
      }
      define( 'FP_CLI_CONFIG_SPEC_FILTER_CALLBACK', 'fp_cli_remove_user_arg' );
      """

    When I run `FP_CLI_EARLY_REQUIRE=fp-cli-early-require.php fp help`
    Then STDOUT should not contain:
      """
      --user=<id|login|email>
      """

    When I run `fp help`
    Then STDOUT should contain:
      """
      --user=<id|login|email>
      """
