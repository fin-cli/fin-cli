Feature: Global flags

  @require-fin-5.5
  Scenario: Setting the URL
    Given a FIN installation

    When I run `fin --url=localhost:8001 eval 'echo json_encode( $_SERVER );'`
    Then STDOUT should be JSON containing:
      """
      {
        "HTTP_HOST": "localhost:8001",
        "SERVER_NAME": "localhost",
        "SERVER_PORT": 8001
      }
      """

  @less-than-fin-5.5
  Scenario: Setting the URL
    Given a FIN installation

    When I run `fin --url=localhost:8001 eval 'echo json_encode( $_SERVER );'`
    Then STDOUT should be JSON containing:
      """
      {
        "HTTP_HOST": "localhost:8001",
        "SERVER_NAME": "localhost",
        "SERVER_PORT": "8001"
      }
      """

  Scenario: Setting the URL on multisite
    Given a FIN multisite installation
    And I run `fin site create --slug=foo`

    When I run `fin --url=example.com/foo option get home`
    Then STDOUT should contain:
      """
      example.com/foo
      """

  @require-fin-3.9
  Scenario: Invalid URL
    Given a FIN multisite installation

    When I try `fin post list --url=invalid.example.com`
    Then STDERR should be:
      """
      Error: Site 'invalid.example.com' not found. Verify `--url=<url>` matches an existing site.
      """

  Scenario: Quiet run
    Given a FIN installation

    When I try `fin non-existing-command --quiet`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: 'non-existing-command' is not a registered fin command. See 'fin help' for available commands.
      """

  @less-than-php-8
  Scenario: Debug run
    Given a FIN installation

    When I try `fin eval 'echo CONST_WITHOUT_QUOTES;'`
    Then STDOUT should be:
      """
      CONST_WITHOUT_QUOTES
      """
    And STDERR should contain:
      """
      Use of undefined constant CONST_WITHOUT_QUOTES
      """
    And the return code should be 0

    When I try `fin eval 'echo CONST_WITHOUT_QUOTES;' --debug`
    Then the return code should be 0
    And STDOUT should be:
      """
      CONST_WITHOUT_QUOTES
      """
    And STDERR should contain:
      """
      Use of undefined constant CONST_WITHOUT_QUOTES
      """

  Scenario: Setting the FIN user
    Given a FIN installation

    When I run `fin eval 'var_export( is_user_logged_in() );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `fin --user=admin eval 'echo fin_get_current_user()->user_login;'`
    Then STDOUT should be:
      """
      admin
      """
    And STDERR should be empty

    When I run `fin --user=admin@example.com eval 'echo fin_get_current_user()->user_login;'`
    Then STDOUT should be:
      """
      admin
      """
    And STDERR should be empty

    When I try `fin --user=non-existing-user eval 'echo fin_get_current_user()->user_login;'`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: Invalid user ID, email or login: 'non-existing-user'
      """

  Scenario: Warn when provided user is ambiguous
    Given a FIN installation

    When I run `fin --user=1 eval 'echo fin_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      admin@example.com
      """
    And STDERR should be empty

    When I run `fin user create 1 user1@example.com`
    Then STDOUT should contain:
      """
      Success:
      """

    When I try `fin --user=1 eval 'echo fin_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      admin@example.com
      """
    And STDERR should be:
      """
      Warning: Ambiguous user match detected (both ID and user_login exist for identifier '1'). FIN-CLI will default to the ID, but you can force user_login instead with FIN_CLI_FORCE_USER_LOGIN=1.
      """

    When I run `FIN_CLI_FORCE_USER_LOGIN=1 fin --user=1 eval 'echo fin_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      user1@example.com
      """
    And STDERR should be empty

    When I run `fin --user=user1@example.com eval 'echo fin_get_current_user()->user_email;'`
    Then STDOUT should be:
      """
      user1@example.com
      """
    And STDERR should be empty

    When I try `FIN_CLI_FORCE_USER_LOGIN=1 fin --user=user1@example.com eval 'echo fin_get_current_user()->user_email;'`
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

      FIN_CLI::set_logger( new Dummy_Logger );
      """

    When I try `fin --require=custom-logger.php is-installed`
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
       * @when before_fin_load
       */
      class Test_Command extends FIN_CLI_Command {

        function req( $args, $assoc_args ) {
          FIN_CLI::line( $args[0] );
        }
      }

      FIN_CLI::add_command( 'test', 'Test_Command' );
      """

    And a foo.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """

    And a bar.php file:
      """
      <?php echo basename(__FILE__) . "\n";
      """

    And a fin-cli.yml file:
      """
      require:
        - foo.php
        - bar.php
      """

    And a fin-cli2.yml file:
      """
      require: custom-cmd.php
      """

    When I run `fin --require=custom-cmd.php test req 'This is a custom command.'`
    Then STDOUT should be:
      """
      foo.php
      bar.php
      This is a custom command.
      """

    When I run `FIN_CLI_CONFIG_PATH=fin-cli2.yml fin test req 'This is a custom command.'`
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

    And a fin-cli.yml file:
      """
      require: foober/*.php
      """

    When I run `fin`
    Then STDOUT should contain:
      """
      bar.php
      foo.php
      """
    When I run `fin --require=doobie/*.php`
    Then STDOUT should contain:
      """
      doo.php
      """

  Scenario: Enabling/disabling color
    Given a FIN installation

    When I try `fin --no-color non-existent-command`
    Then STDERR should be:
      """
      Error: 'non-existent-command' is not a registered fin command. See 'fin help' for available commands.
      """

    When I try `fin --color non-existent-command`
    Then STDERR should strictly contain:
      """
      [31;1mError:
      """

  Scenario: Use `FIN_CLI_STRICT_ARGS_MODE` to distinguish between global and local args
    Given an empty directory
    And a cmd.php file:
      """
      <?php
      /**
       * @when before_fin_load
       *
       * [--url=<url>]
       * : URL passed to the callback.
       */
      $cmd_test = function( $args, $assoc_args ) {
          $url = FIN_CLI::get_runner()->config['url'] ? ' ' . FIN_CLI::get_runner()->config['url'] : '';
          FIN_CLI::log( 'global:' . $url );
          $url = isset( $assoc_args['url'] ) ? ' ' . $assoc_args['url'] : '';
          FIN_CLI::log( 'local:' . $url );
      };
      FIN_CLI::add_command( 'cmd-test', $cmd_test );
      """
    And a fin-cli.yml file:
      """
      require:
        - cmd.php
      """

    When I run `fin cmd-test --url=foo.dev`
    Then STDOUT should be:
      """
      global: foo.dev
      local:
      """

    When I run `FIN_CLI_STRICT_ARGS_MODE=1 fin cmd-test --url=foo.dev`
    Then STDOUT should be:
      """
      global:
      local: foo.dev
      """

    When I run `FIN_CLI_STRICT_ARGS_MODE=1 fin --url=bar.dev cmd-test --url=foo.dev`
    Then STDOUT should be:
      """
      global: bar.dev
      local: foo.dev
      """

  Scenario: Using --http=<url> requires fin-cli/restful
    Given an empty directory

    When I try `fin --http=foo.dev`
    Then STDERR should be:
      """
      Error: RESTful FIN-CLI needs to be installed. Try 'fin package install fin-cli/restful'.
      """

  Scenario: Strict args mode should be passed on to ssh
    When I try `FIN_CLI_STRICT_ARGS_MODE=1 fin --debug --ssh=/ --version`
    Then STDERR should contain:
      """
      Running SSH command: ssh -T -vvv '' 'FIN_CLI_STRICT_ARGS_MODE=1 fin
      """

  Scenario: SSH flag should support changing directories
    When I try `fin --debug --ssh=finpress:/my/path --version`
    Then STDERR should contain:
      """
      Running SSH command: ssh -T -vvv 'finpress' 'cd '\''/my/path'\''; fin
      """

  Scenario: SSH flag should support Docker
    When I try `FIN_CLI_DOCKER_NO_INTERACTIVE=1 fin --debug --ssh=docker:user@finpress --version`
    Then STDERR should contain:
      """
      Running SSH command: docker exec --user 'user' 'finpress' sh -c
      """

  Scenario: Customize config-spec with FIN_CLI_CONFIG_SPEC_FILTER_CALLBACK
    Given a FIN installation
    And a fin-cli-early-require.php file:
      """
      <?php
      function fin_cli_remove_user_arg( $spec ) {
        unset( $spec['user'] );
        return $spec;
      }
      define( 'FIN_CLI_CONFIG_SPEC_FILTER_CALLBACK', 'fin_cli_remove_user_arg' );
      """

    When I run `FIN_CLI_EARLY_REQUIRE=fin-cli-early-require.php fin help`
    Then STDOUT should not contain:
      """
      --user=<id|login|email>
      """

    When I run `fin help`
    Then STDOUT should contain:
      """
      --user=<id|login|email>
      """
