Feature: FP-CLI Commands

  Scenario: Registered FP-CLI commands
    Given an empty directory

    When I run `fp help --help`
    Then STDOUT should contain:
      """
      fp help [<command>...]
      """

  Scenario: Invalid class is specified for a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php

      FP_CLI::add_command( 'command example', 'Non_Existent_Class' );
      """

    When I try `fp --require=custom-cmd.php help`
    Then the return code should be 1
    And STDERR should contain:
      """
      Callable "Non_Existent_Class" does not exist, and cannot be registered as `fp command example`.
      """

  Scenario: Invalid subcommand of valid command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fp_load
       */
      class Custom_Command_Class extends FP_CLI_Command {

          public function valid() {
             FP_CLI::success( 'Hello world' );
          }

      }
      FP_CLI::add_command( 'command', 'Custom_Command_Class' );
      """

    When I try `fp --require=custom-cmd.php command invalid`
    Then STDERR should contain:
      """
      Error: 'invalid' is not a registered subcommand of 'command'. See 'fp help command' for available subcommands.
      """

  Scenario: Use a closure as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      /**
       * My awesome closure command
       *
       * <message>
       * : An awesome message to display
       *
       * @when before_fp_load
       */
      $foo = function( $args ) {
        FP_CLI::success( $args[0] );
      };
      FP_CLI::add_command( 'foo', $foo );
      """

    When I run `fp --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fp --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome closure command
      """

    When I try `fp --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fp --require=custom-cmd.php foo bar`
    Then STDOUT should contain:
      """
      Success: bar
      """

  Scenario: Use a function as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      /**
       * My awesome function command
       *
       * <message>
       * : An awesome message to display
       *
       * @when before_fp_load
       */
      function foo( $args ) {
        FP_CLI::success( $args[0] );
      }
      FP_CLI::add_command( 'foo', 'foo' );
      """

    When I run `fp --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fp --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome function command
      """

    When I try `fp --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fp --require=custom-cmd.php foo bar`
    Then STDOUT should contain:
      """
      Success: bar
      """

  Scenario: Use a class method as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class extends FP_CLI_Command {
        private $prefix;
        public function __construct( $prefix ) {
          $this->prefix = $prefix;
        }
        /**
         * My awesome class method command
         *
         * <message>
         * : An awesome message to display
         *
         * @when before_fp_load
         */
        function foo( $args ) {
          FP_CLI::success( $this->prefix . ':' . $args[0] );
        }
      }
      $foo = new Foo_Class( 'boo' );
      FP_CLI::add_command( 'foo', array( $foo, 'foo' ) );
      """

    When I run `fp --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fp --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome class method command
      """

    When I try `fp --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fp --require=custom-cmd.php foo bar`
    Then STDOUT should contain:
      """
      Success: boo:bar
      """

  Scenario: Use a class method as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class extends FP_CLI_Command {
        /**
         * My awesome class method command
         *
         * <message>
         * : An awesome message to display
         *
         * @when before_fp_load
         */
        function foo( $args ) {
          FP_CLI::success( $args[0] );
        }
      }
      FP_CLI::add_command( 'foo', array( 'Foo_Class', 'foo' ) );
      """

    When I run `fp --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fp --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome class method command
      """

    When I try `fp --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fp --require=custom-cmd.php foo bar`
    Then STDOUT should contain:
      """
      Success: bar
      """

  Scenario: Use class with __invoke() passed as object
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class {
        private $message;
        public function __construct( $message ) {
          $this->message = $message;
        }

        /**
         * My awesome class method command
         *
         * @when before_fp_load
         */
        function __invoke( $args ) {
          FP_CLI::success( $this->message );
        }
      }
      $foo = new Foo_Class( 'bar' );
      FP_CLI::add_command( 'instantiated-command', $foo );
      """

    When I run `fp --require=custom-cmd.php instantiated-command`
    Then STDOUT should contain:
      """
      bar
      """
    And STDERR should be empty

  Scenario: Use an invalid class method as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class extends FP_CLI_Command {
        /**
         * My awesome class method command
         *
         * <message>
         * : An awesome message to display
         *
         * @when before_fp_load
         */
        function foo( $args ) {
          FP_CLI::success( $args[0] );
        }
      }
      $foo = new Foo_Class;
      FP_CLI::add_command( 'bar', array( $foo, 'bar' ) );
      """

    When I try `fp --require=custom-cmd.php bar`
    Then STDERR should contain:
      """
      Error: Callable ["Foo_Class","bar"] does not exist, and cannot be registered as `fp bar`.
      """

  Scenario: Register a synopsis for a given command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      function foo( $args, $assoc_args ) {
        $message = array_shift( $args );
        FP_CLI::log( 'Message is: ' . $message );
        FP_CLI::success( $assoc_args['meal'] );
      }
      FP_CLI::add_command( 'foo', 'foo', array(
        'shortdesc'   => 'My awesome function command',
        'when'        => 'before_fp_load',
        'synopsis'    => array(
          array(
            'type'          => 'positional',
            'name'          => 'message',
            'description'   => 'An awesome message to display',
            'optional'      => false,
            'options'       => array( 'hello', 'goodbye' ),
          ),
          array(
            'type'          => 'assoc',
            'name'          => 'apple',
            'description'   => 'A type of fruit.',
            'optional'      => false,
          ),
          array(
            'type'          => 'assoc',
            'name'          => 'meal',
            'description'   => 'A type of meal.',
            'optional'      => true,
            'default'       => 'breakfast',
            'options'       => array( 'breakfast', 'lunch', 'dinner' ),
          ),
        ),
      ) );
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I try `fp foo`
    Then STDOUT should contain:
      """
      usage: fp foo <message> --apple=<apple> [--meal=<meal>]
      """
    And STDERR should be empty
    And the return code should be 1

    When I run `fp help foo`
    Then STDOUT should contain:
      """
      My awesome function command
      """
    And STDOUT should contain:
      """
      SYNOPSIS
      """
    And STDOUT should contain:
      """
      fp foo <message> --apple=<apple> [--meal=<meal>]
      """
    And STDOUT should contain:
      """
      OPTIONS
      """
    And STDOUT should contain:
      """
      <message>
          An awesome message to display
          ---
          options:
            - hello
            - goodbye
          ---
      """
    And STDOUT should contain:
      """
      [--meal=<meal>]
          A type of meal.
          ---
          default: breakfast
          options:
            - breakfast
            - lunch
            - dinner
          ---
      """

    When I try `fp foo nana --apple=fuji`
    Then STDERR should contain:
      """
      Error: Invalid value specified for positional arg.
      """

    When I try `fp foo hello --apple=fuji --meal=snack`
    Then STDERR should contain:
      """
      Invalid value specified for 'meal' (A type of meal.)
      """

    When I try `fp foo hello --apple=fuji --meal=breakfast,lunch,dinner`
    Then STDERR should be empty

    When I try `fp foo hello --apple=fuji --meal=breakfast,snack,dinner`
    Then STDERR should contain:
      """
      Invalid value specified for 'meal' (A type of meal.)
      """

    When I run `fp foo hello --apple=fuji`
    Then STDOUT should be:
      """
      Message is: hello
      Success: breakfast
      """

    When I run `fp foo hello --apple=fuji --meal=dinner`
    Then STDOUT should be:
      """
      Message is: hello
      Success: dinner
      """

  Scenario: Register a synopsis that supports multiple positional arguments
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      FP_CLI::add_command( 'foo', function( $args ){
        FP_CLI::log( count( $args ) );
      }, array(
        'when' => 'before_fp_load',
        'synopsis' => array(
          array(
            'type'      => 'positional',
            'name'      => 'arg',
            'repeating' => true,
          ),
        ),
      ));
      """
    And a fp-cli.yml file:
      """
      require:
        - test-cmd.php
      """

    When I run `fp foo bar`
    Then STDOUT should be:
      """
      1
      """

    When I run `fp foo bar burrito`
    Then STDOUT should be:
      """
      2
      """

  Scenario: Register a synopsis that requires a flag
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      FP_CLI::add_command( 'foo', function( $_, $assoc_args ){
        FP_CLI::log( \FP_CLI\Utils\get_flag_value( $assoc_args, 'honk' ) ? 'honked' : 'nohonk' );
      }, array(
        'when' => 'before_fp_load',
        'synopsis' => array(
          array(
            'type'     => 'flag',
            'name'     => 'honk',
            'optional' => true,
          ),
        ),
      ));
      """
    And a fp-cli.yml file:
      """
      require:
        - test-cmd.php
      """

    When I run `fp foo`
    Then STDOUT should be:
      """
      nohonk
      """

    When I run `fp foo --honk`
    Then STDOUT should be:
      """
      honked
      """

    When I run `fp foo --honk=1`
    Then STDOUT should be:
      """
      honked
      """

    When I run `fp foo --no-honk`
    Then STDOUT should be:
      """
      nohonk
      """

    When I run `fp foo --honk=0`
    Then STDOUT should be:
      """
      nohonk
      """

    # Note treats "false" as true.
    When I run `fp foo --honk=false`
    Then STDOUT should be:
      """
      honked
      """

  Scenario: Register a longdesc for a given command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      function foo() {
        FP_CLI::success( 'Command run.' );
      }
      FP_CLI::add_command( 'foo', 'foo', array(
        'shortdesc'   => 'My awesome function command',
        'when'        => 'before_fp_load',
        'longdesc'    => '## EXAMPLES' . PHP_EOL . PHP_EOL . '  # Run the custom foo command',
      ) );
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fp help foo`
    Then STDOUT should contain:
      """
      NAME

        fp foo

      DESCRIPTION

        My awesome function command

      SYNOPSIS

        fp foo 

      EXAMPLES

        # Run the custom foo command

      GLOBAL PARAMETERS

      """

    # With synopsis, appended.
    Given a hello-command.php file:
      """
      <?php
        $hello_command = function( $args, $assoc_args ) {
            list( $name ) = $args;
            $type = $assoc_args['type'];
            FP_CLI::$type( "Hello, $name!" );
            if ( isset( $assoc_args['honk'] ) ) {
                FP_CLI::log( 'Honk!' );
            }
        };
        FP_CLI::add_command( 'example hello', $hello_command, array(
            'shortdesc' => 'Prints a greeting.',
            'synopsis' => array(
                array(
                    'type'      => 'positional',
                    'name'      => 'name',
                    'description' => 'Name of person to greet.',
                    'optional'  => false,
                    'repeating' => false,
                ),
                array(
                    'type'     => 'assoc',
                    'name'     => 'type',
                    'optional' => true,
                    'default'  => 'success',
                    'options'  => array( 'success', 'error' ),
                ),
                array(
                    'type'     => 'flag',
                    'name'     => 'honk',
                    'optional' => true,
                ),
            ),
            'when' => 'after_fp_load',
            'longdesc'    => "\r\n## EXAMPLES\n\n# Say hello to Newman\nfp example hello Newman\nSuccess: Hello, Newman!",
      ) );
      """

    When I run `fp --require=hello-command.php help example hello`
    Then STDOUT should contain:
      """
      NAME

        fp example hello

      DESCRIPTION

        Prints a greeting.

      SYNOPSIS

        fp example hello <name> [--type=<type>] [--honk]

      OPTIONS

        <name>
          Name of person to greet.

        [--type=<type>]
        ---
        default: success
        options:
        - success
        - error
        ---

        [--honk]

      EXAMPLES

        # Say hello to Newman
        fp example hello Newman
        Success: Hello, Newman!

      GLOBAL PARAMETERS

      """

    Given a test-reordering.php file:
      """
      <?php
      FP_CLI::add_command( 'test-reordering', function () { }, [
        'shortdesc' => 'Test reordering of arguments.',
        'synopsis'  => [
          [
            'type'        => 'flag',
            'name'        => 'my-flag',
            'description' => 'Flag something',
          ],
          [
            'type'        => 'assoc',
            'name'        => 'my-assoc',
            'description' => 'Assoc something',
            'options'     => [ 'a', 'b', 'c' ],
            'default'     => 'a',
          ],
          [
            'type'        => 'positional',
            'name'        => 'my-positional',
            'description' => 'Positional something',
            'optional'    => false,
            'repeating'   => false,
          ],
        ],
        'when'      => 'before_fp_load',
      ] );
      """

    When I run `fp --require=test-reordering.php help test-reordering`
    Then STDOUT should contain:
      """
      NAME

        fp test-reordering

      DESCRIPTION

        Test reordering of arguments.

      SYNOPSIS

        fp test-reordering <my-positional> --my-assoc=<my-assoc> --my-flag

      OPTIONS

        <my-positional>
          Positional something

        --my-assoc=<my-assoc>
          Assoc something
          ---
          default: a
          options:
            - a
            - b
            - c
          ---

        --my-flag
          Flag something
      """

  Scenario: Register a command with default and accepted arguments.
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      /**
       * An amazing command for managing burritos.
       *
       * [<bar>]
       * : This is the bar argument.
       * ---
       * default: burrito
       * ---
       *
       * [<shop>...]
       * : This is where you buy burritos.
       * ---
       * options:
       *   - left_coast_siesta
       *   - cha cha cha
       * ---
       *
       * [--burrito=<burrito>]
       * : This is the burrito argument.
       * ---
       * options:
       *   - beans
       *   - veggies
       * ---
       *
       * @when before_fp_load
       */
      $foo = function( $args, $assoc_args ) {
        $out = array(
          'bar'     => isset( $args[0] ) ? $args[0] : '',
          'shop'    => isset( $args[1] ) ? $args[1] : '',
          'burrito' => isset( $assoc_args['burrito'] ) ? $assoc_args['burrito'] : '',
        );
        FP_CLI::print_value( $out, array( 'format' => 'yaml' ) );
      };
      FP_CLI::add_command( 'foo', $foo );
      """

    When I run `fp --require=test-cmd.php foo --help`
    Then STDOUT should contain:
      """
      [<bar>]
          This is the bar argument.
          ---
          default: burrito
          ---
      """
    And STDOUT should contain:
      """
      [--burrito=<burrito>]
          This is the burrito argument.
          ---
          options:
            - beans
            - veggies
          ---
      """

    When I run `fp --require=test-cmd.php foo`
    Then STDOUT should be YAML containing:
      """
      bar: burrito
      shop:
      burrito:
      """
    And STDERR should be empty

    When I run `fp --require=test-cmd.php foo ''`
    Then STDOUT should be YAML containing:
      """
      bar:
      shop:
      burrito:
      """
    And STDERR should be empty

    When I run `fp --require=test-cmd.php foo apple --burrito=veggies`
    Then STDOUT should be YAML containing:
      """
      bar: apple
      shop:
      burrito: veggies
      """
    And STDERR should be empty

    When I try `fp --require=test-cmd.php foo apple --burrito=meat`
    Then STDERR should contain:
      """
      Error: Parameter errors:
       Invalid value specified for 'burrito' (This is the burrito argument.)
      """

    When I try `fp --require=test-cmd.php foo apple --burrito=''`
    Then STDERR should contain:
      """
      Error: Parameter errors:
       Invalid value specified for 'burrito' (This is the burrito argument.)
      """

    When I try `fp --require=test-cmd.php foo apple taco_del_mar`
    Then STDERR should contain:
      """
      Error: Invalid value specified for positional arg.
      """

    When I try `fp --require=test-cmd.php foo apple 'cha cha cha' taco_del_mar`
    Then STDERR should contain:
      """
      Error: Invalid value specified for positional arg.
      """

    When I run `fp --require=test-cmd.php foo apple 'cha cha cha'`
    Then STDOUT should be YAML containing:
      """
      bar: apple
      shop: cha cha cha
      burrito:
      """
    And STDERR should be empty

  Scenario: Register a command with default and accepted arguments, part two
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      /**
       * An amazing command for managing burritos.
       *
       * [<burrito>]
       * : This is the bar argument.
       * ---
       * options:
       *   - beans
       *   - veggies
       * ---
       *
       * @when before_fp_load
       */
      $foo = function( $args, $assoc_args ) {
        $out = array(
          'burrito' => isset( $args[0] ) ? $args[0] : '',
        );
        FP_CLI::print_value( $out, array( 'format' => 'yaml' ) );
      };
      FP_CLI::add_command( 'foo', $foo );
      """

    When I run `fp --require=test-cmd.php foo`
    Then STDOUT should be YAML containing:
      """
      burrito:
      """
    And STDERR should be empty

    When I run `fp --require=test-cmd.php foo beans`
    Then STDOUT should be YAML containing:
      """
      burrito: beans
      """
    And STDERR should be empty

    When I try `fp --require=test-cmd.php foo apple`
    Then STDERR should be:
      """
      Error: Invalid value specified for positional arg.
      """

  Scenario: Removing a subcommand should remove it from the index
    Given an empty directory
    And a remove-comment.php file:
      """
      <?php
      FP_CLI::add_hook( 'after_add_command:comment', function () {
        $command = FP_CLI::get_root_command();
        $command->remove_subcommand( 'comment' );
      } );
      """

    When I run `fp`
    Then STDOUT should contain:
      """
      Creates, updates, deletes, and moderates comments.
      """

    When I run `fp --require=remove-comment.php`
    Then STDOUT should not contain:
      """
      Creates, updates, deletes, and moderates comments.
      """

  Scenario: before_invoke should call subcommands
    Given an empty directory
    And a call-invoke.php file:
      """
      <?php
      /**
       * @when before_fp_load
       */
      $before_invoke = function() {
        FP_CLI::success( 'Invoked' );
      };
      $before_invoke_args = array( 'before_invoke' => function() {
        FP_CLI::success( 'before invoke' );
      }, 'after_invoke' => function() {
        FP_CLI::success( 'after invoke' );
      });
      FP_CLI::add_command( 'before invoke', $before_invoke, $before_invoke_args );
      FP_CLI::add_command( 'before-invoke', $before_invoke, $before_invoke_args );
      """

    When I run `fp --require=call-invoke.php before invoke`
    Then STDOUT should contain:
      """
      Success: before invoke
      Success: Invoked
      Success: after invoke
      """

    When I run `fp --require=call-invoke.php before-invoke`
    Then STDOUT should contain:
      """
      Success: before invoke
      Success: Invoked
      Success: after invoke
      """

  Scenario: Default arguments should respect fp-cli.yml
    Given a FP installation
    And a fp-cli.yml file:
      """
      post list:
        format: count
      """

    When I run `fp post list`
    Then STDOUT should be a number

  Scenario: Use class passed as object
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class {
        private $message;
        public function __construct( $message ) {
          $this->message = $message;
        }

        /**
         * My awesome class method command
         *
         * @when before_fp_load
         */
        function message( $args ) {
          FP_CLI::success( $this->message );
        }
      }
      $foo = new Foo_Class( 'bar' );
      FP_CLI::add_command( 'instantiated-command', $foo );
      """

    When I run `fp --require=custom-cmd.php instantiated-command message`
    Then STDOUT should contain:
      """
      bar
      """
    And STDERR should be empty

  Scenario: FP-CLI suggests matching commands when user entry contains typos
    Given a FP installation

    When I try `fp clu`
    Then STDERR should contain:
      """
      Did you mean 'cli'?
      """

    When I try `fp cli nfo`
    Then STDERR should contain:
      """
      Did you mean 'info'?
      """

    When I try `fp cli beyondlevenshteinthreshold`
    Then STDERR should not contain:
      """
      Did you mean
      """

  Scenario: FP-CLI suggests matching parameters when user entry contains typos
    Given an empty directory

    When I try `fp cli info --quie`
    Then STDERR should contain:
      """
      Did you mean '--quiet'?
      """

    When I try `fp cli info --forma=json`
    Then STDERR should contain:
      """
      Did you mean '--format'?
      """

  Scenario: Adding a command can be aborted through the hooks system
    Given an empty directory
    And a abort-add-command.php file:
      """
      <?php
      FP_CLI::add_hook( 'before_add_command:test-command-2', function ( $addition ) {
        $addition->abort( 'Testing hooks.' );
      } );

      FP_CLI::add_command( 'test-command-1', function () {} );
      FP_CLI::add_command( 'test-command-2', function () {} );
      """

    When I try `fp --require=abort-add-command.php`
    Then STDOUT should contain:
      """
      test-command-1
      """
    And STDOUT should not contain:
      """
      test-command-2
      """
    And STDERR should be:
      """
      Warning: Aborting the addition of the command 'test-command-2' with reason: Testing hooks..
      """
    And the return code should be 0

  Scenario: Adding a command can depend on a previous command having been added before
    Given an empty directory
    And a add-dependent-command.php file:
      """
      <?php
      class TestCommand {
      }

      FP_CLI::add_hook( 'after_add_command:test-command', function () {
        FP_CLI::add_command( 'test-command sub-command', function () {} );
      } );

      FP_CLI::add_command( 'test-command', 'TestCommand' );
      """

    When I run `fp --require=add-dependent-command.php`
    Then STDOUT should contain:
      """
      test-command
      """

    When I run `fp --require=add-dependent-command.php help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

  Scenario: Command additions can be deferred until their parent is added
    Given an empty directory
    And a add-deferred-command.php file:
      """
      <?php
      class TestCommand {
      }

      FP_CLI::add_command( 'test-command sub-command', function () {} );

      FP_CLI::add_command( 'test-command', 'TestCommand' );
      """

    When I run `fp --require=add-deferred-command.php`
    Then STDOUT should contain:
      """
      test-command
      """

    When I run `fp --require=add-deferred-command.php help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

  Scenario: Command additions should work as plugins
    Given a FP installation
    And a fp-content/plugins/test-cli/command.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      function test_function() {
        \FP_CLI::success( 'unknown-parent child-command' );
      }

      FP_CLI::add_command( 'unknown-parent child-command', 'test_function' );

      FP_CLI::add_command( 'test-command sub-command', function () { \FP_CLI::success( 'test-command sub-command' ); } );

      FP_CLI::add_command( 'test-command', 'TestCommand' );
      """
    And I run `fp plugin activate test-cli`

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp`
    Then STDOUT should contain:
      """
      test-command
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

    When I run `fp test-command sub-command`
    Then STDOUT should contain:
      """
      Success: test-command sub-command
      """

    When I run `fp unknown-parent child-command`
    Then STDOUT should contain:
      """
      Success: unknown-parent child-command
      """

  Scenario: Command additions should work as must-use plugins
    Given a FP installation
    And a fp-content/mu-plugins/test-cli.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      function test_function() {
        \FP_CLI::success( 'unknown-parent child-command' );
      }

      FP_CLI::add_command( 'unknown-parent child-command', 'test_function' );

      FP_CLI::add_command( 'test-command sub-command', function () { \FP_CLI::success( 'test-command sub-command' ); } );

      FP_CLI::add_command( 'test-command', 'TestCommand' );
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp`
    Then STDOUT should contain:
      """
      test-command
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

    When I run `fp test-command sub-command`
    Then STDOUT should contain:
      """
      Success: test-command sub-command
      """

    When I run `fp unknown-parent child-command`
    Then STDOUT should contain:
      """
      Success: unknown-parent child-command
      """

  Scenario: Command additions should work when registered on after_fp_load
    Given a FP installation
    And a fp-content/mu-plugins/test-cli.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      function test_function() {
        \FP_CLI::success( 'unknown-parent child-command' );
      }

      FP_CLI::add_hook( 'after_fp_load', function(){
        FP_CLI::add_command( 'unknown-parent child-command', 'test_function' );

        FP_CLI::add_command( 'test-command sub-command', function () { \FP_CLI::success( 'test-command sub-command' ); } );

        FP_CLI::add_command( 'test-command', 'TestCommand' );
      });
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp`
    Then STDOUT should contain:
      """
      test-command
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

    When I run `fp test-command sub-command`
    Then STDOUT should contain:
      """
      Success: test-command sub-command
      """

    When I run `fp unknown-parent child-command`
    Then STDOUT should contain:
      """
      Success: unknown-parent child-command
      """

  Scenario: The command should fire on `after_fp_load`
    Given a FP installation
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fp_load
       */
      class Custom_Command_Class extends FP_CLI_Command {
          /**
           * @when after_fp_load
           */
          public function after_fp_load() {
             var_dump( function_exists( 'home_url' ) );
          }
          public function before_fp_load() {
             var_dump( function_exists( 'home_url' ) );
          }
      }
      FP_CLI::add_command( 'command', 'Custom_Command_Class' );
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fp command after_fp_load`
    Then STDOUT should contain:
      """
      bool(true)
      """
    And the return code should be 0

    When I run `fp command before_fp_load`
    Then STDOUT should contain:
      """
      bool(false)
      """
    And the return code should be 0

    When I try `fp command after_fp_load --path=/tmp`
    Then STDERR should contain:
      """
      Error: This does not seem to be a FinPress installation.
      """
    And the return code should be 1

  Scenario: The command should fire on `before_fp_load`
    Given a FP installation
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when after_fp_load
       */
      class Custom_Command_Class extends FP_CLI_Command {
          /**
           * @when before_fp_load
           */
          public function before_fp_load() {
             var_dump( function_exists( 'home_url' ) );
          }

          public function after_fp_load() {
             var_dump( function_exists( 'home_url' ) );
          }
      }
      FP_CLI::add_command( 'command', 'Custom_Command_Class' );
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fp command before_fp_load`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      bool(false)
      """
    And the return code should be 0

    When I run `fp command after_fp_load`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      bool(true)
      """
    And the return code should be 0

  Scenario: Command hook should fires as expected on __invoke()
    Given a FP installation
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fp_load
       */
      class Custom_Command_Class extends FP_CLI_Command {
          /**
           * @when after_fp_load
           */
          public function __invoke() {
             var_dump( function_exists( 'home_url' ) );
          }
      }
      FP_CLI::add_command( 'command', 'Custom_Command_Class' );
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fp command`
    Then STDOUT should contain:
      """
      bool(true)
      """
    And the return code should be 0

    When I try `fp command --path=/tmp`
    Then STDERR should contain:
      """
      Error: This does not seem to be a FinPress installation.
      """
    And the return code should be 1

  Scenario: Command namespaces can be added and are shown in help
    Given an empty directory
    And a command-namespace.php file:
      """
      <?php
      /**
       * My Command Namespace Description.
       */
      class My_Command_Namespace extends \FP_CLI\Dispatcher\CommandNamespace {}
      FP_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );
      """

    When I run `fp help --require=command-namespace.php`
    Then STDOUT should contain:
      """
      my-namespaced-command
      """
    And STDOUT should contain:
      """
      My Command Namespace Description.
      """
    And STDERR should be empty

  Scenario: Command namespaces are only added when the command does not exist
    Given an empty directory
    And a command-namespace.php file:
      """
      <?php
      /**
       * My Actual Namespaced Command.
       */
      class My_Namespaced_Command extends FP_CLI_Command {}
      FP_CLI::add_command( 'my-namespaced-command', 'My_Namespaced_Command' );

      /**
       * My Command Namespace Description.
       */
      class My_Command_Namespace extends \FP_CLI\Dispatcher\CommandNamespace {}
      FP_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );
      """

    When I run `fp help --require=command-namespace.php`
    Then STDOUT should contain:
      """
      my-namespaced-command
      """
    And STDOUT should contain:
      """
      My Actual Namespaced Command.
      """
    And STDERR should be empty

  Scenario: Command namespaces are replaced by commands of the same name
    Given an empty directory
    And a command-namespace.php file:
      """
      <?php
      /**
       * My Command Namespace Description.
       */
      class My_Command_Namespace extends \FP_CLI\Dispatcher\CommandNamespace {}
      FP_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );

      /**
       * My Actual Namespaced Command.
       */
      class My_Namespaced_Command extends FP_CLI_Command {}
      FP_CLI::add_command( 'my-namespaced-command', 'My_Namespaced_Command' );
      """

    When I run `fp help --require=command-namespace.php`
    Then STDOUT should contain:
      """
      my-namespaced-command
      """
    And STDOUT should contain:
      """
      My Actual Namespaced Command.
      """
    And STDERR should be empty

  Scenario: Empty command namespaces show a notice when invoked
    Given an empty directory
    And a command-namespace.php file:
      """
      <?php
      /**
       * My Command Namespace Description.
       */
      class My_Command_Namespace extends \FP_CLI\Dispatcher\CommandNamespace {}
      FP_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );
      """

    When I run `fp --require=command-namespace.php my-namespaced-command`
    Then STDOUT should contain:
      """
      The namespace my-namespaced-command does not contain any usable commands in the current context.
      """
    And STDERR should be empty

  Scenario: Late-registered command should appear in command usage
    Given a FP installation
    And a test-cmd.php file:
      """
      <?php
      FP_CLI::add_fp_hook( 'plugins_loaded', function(){
        FP_CLI::add_command( 'core custom-subcommand', function() {});
      });
      """
    And a fp-cli.yml file:
      """
      require:
        - test-cmd.php
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp help core`
    Then STDOUT should contain:
      """
      custom-subcommand
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp core`
    Then STDOUT should contain:
      """
      usage:
      """
    And STDOUT should contain:
      """
      core update
      """
    And STDOUT should contain:
      """
      core custom-subcommand
      """

  Scenario: An activated plugin should successfully add custom commands when hooked on the cli_init action
    Given a FP installation
    And a fp-content/plugins/custom-command/custom-cmd.php file:
      """
      <?php
      // Plugin Name: Custom Command

      add_action( 'cli_init', function() {
        FP_CLI::add_command( 'custom', function () {} );
      } );
      """
    And I run `fp plugin activate custom-command`
    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp custom --help`
    Then STDOUT should contain:
      """
      fp custom
      """

  Scenario: subcommand alias should respect @when definition
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Test_Command {
        /**
         * test
         *
         * @alias bar
         *
         * @when before_fp_load
         *
         */
        public function foo( $args, $assoc_args ) {
          echo 'Hello' . PHP_EOL;
        }
      }

      FP_CLI::add_command( 'test', Test_Command::class );
      """

    When I run `fp --require=custom-cmd.php test foo`
    Then STDOUT should contain:
      """
      Hello
      """

    When I run `fp --require=custom-cmd.php test bar`
    Then STDOUT should contain:
      """
      Hello
      """
