Feature: Run a FP-CLI command

  Background:
    Given an empty directory
    And a command.php file:
      """
      <?php
      /**
       * Run a FP-CLI command with FP_CLI::runcommand();
       *
       * ## OPTIONS
       *
       * <command>
       * : Command to run, quoted.
       *
       * [--launch]
       * : Launch a new process for the command.
       *
       * [--exit_error]
       * : Exit on error.
       *
       * [--return[=<return>]]
       * : Capture and return output.
       *
       * [--parse=<format>]
       * : Parse returned output as a particular format.
       */
      FP_CLI::add_command( 'run', function( $args, $assoc_args ){
        $ret = FP_CLI::runcommand( $args[0], $assoc_args );
        $ret = is_object( $ret ) ? (array) $ret : $ret;
        FP_CLI::log( 'returned: ' . var_export( $ret, true ) );
      });
      """
    And a fp-cli.yml file:
      """
      user: admin
      require:
        - command.php
      """
    And a config.yml file:
      """
      user get:
        0: admin
        field: user_email
      """

  Scenario Outline: Run a FP-CLI command and render output
    Given a FP installation

    When I run `fp <flag> run 'option get home'`
    Then STDOUT should be:
      """
      https://example.com
      returned: NULL
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp <flag> run 'eval "echo fp_get_current_user()->user_login . PHP_EOL;"'`
    Then STDOUT should be:
      """
      admin
      returned: NULL
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `FP_CLI_CONFIG_PATH=config.yml fp <flag> run 'user get'`
    Then STDOUT should be:
      """
      admin@example.com
      returned: NULL
      """
    And STDERR should be empty
    And the return code should be 0

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Run a FP-CLI command and capture output
    Given a FP installation

    When I run `fp run <flag> --return 'option get home'`
    Then STDOUT should be:
      """
      returned: 'https://example.com'
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp <flag> --return run 'eval "echo fp_get_current_user()->user_login . PHP_EOL;"'`
    Then STDOUT should be:
      """
      returned: 'admin'
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp <flag> --return=stderr run 'eval "echo fp_get_current_user()->user_login . PHP_EOL;"'`
    Then STDOUT should be:
      """
      returned: ''
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp <flag> --return=return_code run 'eval "echo fp_get_current_user()->user_login . PHP_EOL;"'`
    Then STDOUT should be:
      """
      returned: 0
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp <flag> --return=all run 'eval "echo fp_get_current_user()->user_login . PHP_EOL;"'`
    Then STDOUT should be:
      """
      returned: array (
        'stdout' => 'admin',
        'stderr' => '',
        'return_code' => 0,
      )
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `FP_CLI_CONFIG_PATH=config.yml fp --return <flag> run 'user get'`
    Then STDOUT should be:
      """
      returned: 'admin@example.com'
      """
    And STDERR should be empty
    And the return code should be 0

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Use 'parse=json' to parse JSON output
    Given a FP installation

    When I run `fp run --return --parse=json <flag> 'user get admin --fields=user_login,user_email --format=json'`
    Then STDOUT should be:
      """
      returned: array (
        'user_login' => 'admin',
        'user_email' => 'admin@example.com',
      )
      """

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Exit on error by default
    Given a FP installation

    When I try `fp run <flag> 'eval "FP_CLI::error( var_export( get_current_user_id(), true ) );"'`
    Then STDOUT should be empty
    And STDERR should be:
      """
      Error: 1
      """
    And the return code should be 1

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Override erroring on exit
    Given a FP installation

    When I try `fp run <flag> --no-exit_error --return=all 'eval "FP_CLI::error( var_export( get_current_user_id(), true ) );"'`
    Then STDOUT should be:
      """
      returned: array (
        'stdout' => '',
        'stderr' => 'Error: 1',
        'return_code' => 1,
      )
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp <flag> --no-exit_error run 'option pluck foo$bar barfoo'`
    Then STDOUT should be:
      """
      returned: NULL
      """
    And STDERR should be empty
    And the return code should be 0

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Output using echo and log, success, warning and error
    Given a FP installation

    # Note FP_CLI::error() terminates eval processing so needs to be last.
    When I run `fp run <flag> --no-exit_error --return=all 'eval "FP_CLI::log( '\'log\'' ); echo '\'echo\''; FP_CLI::success( '\'success\'' ); FP_CLI::error( '\'error\'' );"'`
    Then STDOUT should be:
      """
      returned: array (
        'stdout' => 'log
      echoSuccess: success',
        'stderr' => 'Error: error',
        'return_code' => 1,
      )
      """
    And STDERR should be empty
    And the return code should be 0

    When I run `fp run <flag> --no-exit_error --return=all 'eval "echo '\'echo\''; FP_CLI::log( '\'log\'' ); FP_CLI::warning( '\'warning\''); FP_CLI::success( '\'success\'' );"'`
    Then STDOUT should be:
      """
      returned: array (
        'stdout' => 'echolog
      Success: success',
        'stderr' => 'Warning: warning',
        'return_code' => 0,
      )
      """
    And STDERR should be empty
    And the return code should be 0

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  @less-than-php-8
  Scenario Outline: Installed packages work as expected
    Given a FP installation

    # Allow for composer/ca-bundle using `openssl_x509_parse()` which throws PHP warnings on old versions of PHP.
    When I try `fp package install fp-cli/scaffold-package-command`
    And I run `fp <flag> run 'help scaffold package'`
    Then STDOUT should contain:
      """
      fp scaffold package <name>
      """
    And STDERR should be empty

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Persists global parameters when supplied interactively
    Given a FP installation in 'foo'

    When I run `fp <flag> --path=foo run 'config set test 42 --type=constant'`
    Then STDOUT should be:
      """
      Success: Added the constant 'test' to the 'fp-config.php' file with the value '42'.
      returned: NULL
      """
    And STDERR should be empty
    And the return code should be 0

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Apply backwards compat conversions
    Given a FP installation

    When I run `fp <flag> run 'term url category 1'`
    Then STDOUT should be:
      """
      https://example.com/?cat=1
      returned: NULL
      """
    And STDERR should be empty
    And the return code should be 0

    Examples:
      | flag        |
      | --no-launch |
      | --launch    |

  Scenario Outline: Check that proc_open() and proc_close() aren't disabled for launch
    Given a FP installation

    When I try `{INVOKE_FP_CLI_WITH_PHP_ARGS--ddisable_functions=<func>} --launch run 'option get home'`
    Then STDERR should contain:
      """
      Error: Cannot do 'launch option': The PHP functions `proc_open()` and/or `proc_close()` are disabled
      """
    And the return code should be 1

    Examples:
      | func       |
      | proc_open  |
      | proc_close |

  Scenario: Check that command_args provided to runcommand are used in command
    Given a FP installation
    And a custom-cmd.php file:
      """
      <?php
      class Custom_Command extends FP_CLI_Command {

        /**
         * Custom command to test passing command_args via runcommand options
         *
         * @when after_fp_load
         */
        public function echo_test( $args ) {
          $cli_opts = array( 'command_args' => array( '--exec="echo \'test\' . PHP_EOL;"' ) );
          FP_CLI::runcommand( 'option get home', $cli_opts);
        }
        public function bad_path( $args ) {
          $cli_opts = array( 'command_args' => array('--path=/bad/path' ) );
          FP_CLI::runcommand( 'option get home', $cli_opts);
        }
      }
      FP_CLI::add_command( 'custom-command', 'Custom_Command' );
      """

    When I run `fp --require=custom-cmd.php custom-command echo_test`
    Then STDOUT should be:
      """
      test
      https://example.com
      """

    When I try `fp --require=custom-cmd.php custom-command bad_path`
    Then STDERR should contain:
      """
      The used path is: /bad/path/
      """

  Scenario: Check that required files are used from command arguments and ENV VAR
    Given a FP installation
    And a custom-cmd.php file:
      """
      <?php
      class Custom_Command extends FP_CLI_Command {
        /**
         * Custom command to test passing command_args via runcommand options
         *
         * @when after_fp_load
         */
         public function echo_test( $args ) {
         echo "test" . PHP_EOL;
        }
      }
      FP_CLI::add_command( 'custom-command', 'Custom_Command' );
      """
    And a env.php file:
      """
      <?php
      echo 'ENVIRONMENT REQUIRE' . PHP_EOL;
      """
    And a env-2.php file:
      """
      <?php
      echo 'ENVIRONMENT REQUIRE 2' . PHP_EOL;
      """

    When I run `FP_CLI_REQUIRE=env.php fp eval 'return null;' --skip-finpress`
    Then STDOUT should be:
      """
      ENVIRONMENT REQUIRE
      """

    When I run `FP_CLI_REQUIRE=env.php fp --require=custom-cmd.php custom-command echo_test`
    Then STDOUT should be:
      """
      ENVIRONMENT REQUIRE
      test
      """

    When I run `FP_CLI_REQUIRE='env.php,env-2.php' fp --require=custom-cmd.php custom-command echo_test`
    Then STDOUT should be:
      """
      ENVIRONMENT REQUIRE
      ENVIRONMENT REQUIRE 2
      test
      """
