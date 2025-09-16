Feature: FIN-CLI Commands

  Scenario: Registered FIN-CLI commands
    Given an empty directory

    When I run `fin help --help`
    Then STDOUT should contain:
      """
      fin help [<command>...]
      """

  Scenario: Invalid class is specified for a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php

      FIN_CLI::add_command( 'command example', 'Non_Existent_Class' );
      """

    When I try `fin --require=custom-cmd.php help`
    Then the return code should be 1
    And STDERR should contain:
      """
      Callable "Non_Existent_Class" does not exist, and cannot be registered as `fin command example`.
      """

  Scenario: Invalid subcommand of valid command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fin_load
       */
      class Custom_Command_Class extends FIN_CLI_Command {

          public function valid() {
             FIN_CLI::success( 'Hello world' );
          }

      }
      FIN_CLI::add_command( 'command', 'Custom_Command_Class' );
      """

    When I try `fin --require=custom-cmd.php command invalid`
    Then STDERR should contain:
      """
      Error: 'invalid' is not a registered subcommand of 'command'. See 'fin help command' for available subcommands.
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
       * @when before_fin_load
       */
      $foo = function( $args ) {
        FIN_CLI::success( $args[0] );
      };
      FIN_CLI::add_command( 'foo', $foo );
      """

    When I run `fin --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fin --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome closure command
      """

    When I try `fin --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fin --require=custom-cmd.php foo bar`
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
       * @when before_fin_load
       */
      function foo( $args ) {
        FIN_CLI::success( $args[0] );
      }
      FIN_CLI::add_command( 'foo', 'foo' );
      """

    When I run `fin --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fin --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome function command
      """

    When I try `fin --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fin --require=custom-cmd.php foo bar`
    Then STDOUT should contain:
      """
      Success: bar
      """

  Scenario: Use a class method as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class extends FIN_CLI_Command {
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
         * @when before_fin_load
         */
        function foo( $args ) {
          FIN_CLI::success( $this->prefix . ':' . $args[0] );
        }
      }
      $foo = new Foo_Class( 'boo' );
      FIN_CLI::add_command( 'foo', array( $foo, 'foo' ) );
      """

    When I run `fin --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fin --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome class method command
      """

    When I try `fin --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fin --require=custom-cmd.php foo bar`
    Then STDOUT should contain:
      """
      Success: boo:bar
      """

  Scenario: Use a class method as a command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      class Foo_Class extends FIN_CLI_Command {
        /**
         * My awesome class method command
         *
         * <message>
         * : An awesome message to display
         *
         * @when before_fin_load
         */
        function foo( $args ) {
          FIN_CLI::success( $args[0] );
        }
      }
      FIN_CLI::add_command( 'foo', array( 'Foo_Class', 'foo' ) );
      """

    When I run `fin --require=custom-cmd.php help`
    Then STDOUT should contain:
      """
      foo
      """

    When I run `fin --require=custom-cmd.php help foo`
    Then STDOUT should contain:
      """
      My awesome class method command
      """

    When I try `fin --require=custom-cmd.php foo bar --burrito`
    Then STDERR should contain:
      """
      unknown --burrito parameter
      """

    When I run `fin --require=custom-cmd.php foo bar`
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
         * @when before_fin_load
         */
        function __invoke( $args ) {
          FIN_CLI::success( $this->message );
        }
      }
      $foo = new Foo_Class( 'bar' );
      FIN_CLI::add_command( 'instantiated-command', $foo );
      """

    When I run `fin --require=custom-cmd.php instantiated-command`
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
      class Foo_Class extends FIN_CLI_Command {
        /**
         * My awesome class method command
         *
         * <message>
         * : An awesome message to display
         *
         * @when before_fin_load
         */
        function foo( $args ) {
          FIN_CLI::success( $args[0] );
        }
      }
      $foo = new Foo_Class;
      FIN_CLI::add_command( 'bar', array( $foo, 'bar' ) );
      """

    When I try `fin --require=custom-cmd.php bar`
    Then STDERR should contain:
      """
      Error: Callable ["Foo_Class","bar"] does not exist, and cannot be registered as `fin bar`.
      """

  Scenario: Register a synopsis for a given command
    Given an empty directory
    And a custom-cmd.php file:
      """
      <?php
      function foo( $args, $assoc_args ) {
        $message = array_shift( $args );
        FIN_CLI::log( 'Message is: ' . $message );
        FIN_CLI::success( $assoc_args['meal'] );
      }
      FIN_CLI::add_command( 'foo', 'foo', array(
        'shortdesc'   => 'My awesome function command',
        'when'        => 'before_fin_load',
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
    And a fin-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I try `fin foo`
    Then STDOUT should contain:
      """
      usage: fin foo <message> --apple=<apple> [--meal=<meal>]
      """
    And STDERR should be empty
    And the return code should be 1

    When I run `fin help foo`
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
      fin foo <message> --apple=<apple> [--meal=<meal>]
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

    When I try `fin foo nana --apple=fuji`
    Then STDERR should contain:
      """
      Error: Invalid value specified for positional arg.
      """

    When I try `fin foo hello --apple=fuji --meal=snack`
    Then STDERR should contain:
      """
      Invalid value specified for 'meal' (A type of meal.)
      """

    When I try `fin foo hello --apple=fuji --meal=breakfast,lunch,dinner`
    Then STDERR should be empty

    When I try `fin foo hello --apple=fuji --meal=breakfast,snack,dinner`
    Then STDERR should contain:
      """
      Invalid value specified for 'meal' (A type of meal.)
      """

    When I run `fin foo hello --apple=fuji`
    Then STDOUT should be:
      """
      Message is: hello
      Success: breakfast
      """

    When I run `fin foo hello --apple=fuji --meal=dinner`
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
      FIN_CLI::add_command( 'foo', function( $args ){
        FIN_CLI::log( count( $args ) );
      }, array(
        'when' => 'before_fin_load',
        'synopsis' => array(
          array(
            'type'      => 'positional',
            'name'      => 'arg',
            'repeating' => true,
          ),
        ),
      ));
      """
    And a fin-cli.yml file:
      """
      require:
        - test-cmd.php
      """

    When I run `fin foo bar`
    Then STDOUT should be:
      """
      1
      """

    When I run `fin foo bar burrito`
    Then STDOUT should be:
      """
      2
      """

  Scenario: Register a synopsis that requires a flag
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      FIN_CLI::add_command( 'foo', function( $_, $assoc_args ){
        FIN_CLI::log( \FIN_CLI\Utils\get_flag_value( $assoc_args, 'honk' ) ? 'honked' : 'nohonk' );
      }, array(
        'when' => 'before_fin_load',
        'synopsis' => array(
          array(
            'type'     => 'flag',
            'name'     => 'honk',
            'optional' => true,
          ),
        ),
      ));
      """
    And a fin-cli.yml file:
      """
      require:
        - test-cmd.php
      """

    When I run `fin foo`
    Then STDOUT should be:
      """
      nohonk
      """

    When I run `fin foo --honk`
    Then STDOUT should be:
      """
      honked
      """

    When I run `fin foo --honk=1`
    Then STDOUT should be:
      """
      honked
      """

    When I run `fin foo --no-honk`
    Then STDOUT should be:
      """
      nohonk
      """

    When I run `fin foo --honk=0`
    Then STDOUT should be:
      """
      nohonk
      """

    # Note treats "false" as true.
    When I run `fin foo --honk=false`
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
        FIN_CLI::success( 'Command run.' );
      }
      FIN_CLI::add_command( 'foo', 'foo', array(
        'shortdesc'   => 'My awesome function command',
        'when'        => 'before_fin_load',
        'longdesc'    => '## EXAMPLES' . PHP_EOL . PHP_EOL . '  # Run the custom foo command',
      ) );
      """
    And a fin-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fin help foo`
    Then STDOUT should contain:
      """
      NAME

        fin foo

      DESCRIPTION

        My awesome function command

      SYNOPSIS

        fin foo 

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
            FIN_CLI::$type( "Hello, $name!" );
            if ( isset( $assoc_args['honk'] ) ) {
                FIN_CLI::log( 'Honk!' );
            }
        };
        FIN_CLI::add_command( 'example hello', $hello_command, array(
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
            'when' => 'after_fin_load',
            'longdesc'    => "\r\n## EXAMPLES\n\n# Say hello to Newman\nfin example hello Newman\nSuccess: Hello, Newman!",
      ) );
      """

    When I run `fin --require=hello-command.php help example hello`
    Then STDOUT should contain:
      """
      NAME

        fin example hello

      DESCRIPTION

        Prints a greeting.

      SYNOPSIS

        fin example hello <name> [--type=<type>] [--honk]

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
        fin example hello Newman
        Success: Hello, Newman!

      GLOBAL PARAMETERS

      """

    Given a test-reordering.php file:
      """
      <?php
      FIN_CLI::add_command( 'test-reordering', function () { }, [
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
        'when'      => 'before_fin_load',
      ] );
      """

    When I run `fin --require=test-reordering.php help test-reordering`
    Then STDOUT should contain:
      """
      NAME

        fin test-reordering

      DESCRIPTION

        Test reordering of arguments.

      SYNOPSIS

        fin test-reordering <my-positional> --my-assoc=<my-assoc> --my-flag

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
       * @when before_fin_load
       */
      $foo = function( $args, $assoc_args ) {
        $out = array(
          'bar'     => isset( $args[0] ) ? $args[0] : '',
          'shop'    => isset( $args[1] ) ? $args[1] : '',
          'burrito' => isset( $assoc_args['burrito'] ) ? $assoc_args['burrito'] : '',
        );
        FIN_CLI::print_value( $out, array( 'format' => 'yaml' ) );
      };
      FIN_CLI::add_command( 'foo', $foo );
      """

    When I run `fin --require=test-cmd.php foo --help`
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

    When I run `fin --require=test-cmd.php foo`
    Then STDOUT should be YAML containing:
      """
      bar: burrito
      shop:
      burrito:
      """
    And STDERR should be empty

    When I run `fin --require=test-cmd.php foo ''`
    Then STDOUT should be YAML containing:
      """
      bar:
      shop:
      burrito:
      """
    And STDERR should be empty

    When I run `fin --require=test-cmd.php foo apple --burrito=veggies`
    Then STDOUT should be YAML containing:
      """
      bar: apple
      shop:
      burrito: veggies
      """
    And STDERR should be empty

    When I try `fin --require=test-cmd.php foo apple --burrito=meat`
    Then STDERR should contain:
      """
      Error: Parameter errors:
       Invalid value specified for 'burrito' (This is the burrito argument.)
      """

    When I try `fin --require=test-cmd.php foo apple --burrito=''`
    Then STDERR should contain:
      """
      Error: Parameter errors:
       Invalid value specified for 'burrito' (This is the burrito argument.)
      """

    When I try `fin --require=test-cmd.php foo apple taco_del_mar`
    Then STDERR should contain:
      """
      Error: Invalid value specified for positional arg.
      """

    When I try `fin --require=test-cmd.php foo apple 'cha cha cha' taco_del_mar`
    Then STDERR should contain:
      """
      Error: Invalid value specified for positional arg.
      """

    When I run `fin --require=test-cmd.php foo apple 'cha cha cha'`
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
       * @when before_fin_load
       */
      $foo = function( $args, $assoc_args ) {
        $out = array(
          'burrito' => isset( $args[0] ) ? $args[0] : '',
        );
        FIN_CLI::print_value( $out, array( 'format' => 'yaml' ) );
      };
      FIN_CLI::add_command( 'foo', $foo );
      """

    When I run `fin --require=test-cmd.php foo`
    Then STDOUT should be YAML containing:
      """
      burrito:
      """
    And STDERR should be empty

    When I run `fin --require=test-cmd.php foo beans`
    Then STDOUT should be YAML containing:
      """
      burrito: beans
      """
    And STDERR should be empty

    When I try `fin --require=test-cmd.php foo apple`
    Then STDERR should be:
      """
      Error: Invalid value specified for positional arg.
      """

  Scenario: Removing a subcommand should remove it from the index
    Given an empty directory
    And a remove-comment.php file:
      """
      <?php
      FIN_CLI::add_hook( 'after_add_command:comment', function () {
        $command = FIN_CLI::get_root_command();
        $command->remove_subcommand( 'comment' );
      } );
      """

    When I run `fin`
    Then STDOUT should contain:
      """
      Creates, updates, deletes, and moderates comments.
      """

    When I run `fin --require=remove-comment.php`
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
       * @when before_fin_load
       */
      $before_invoke = function() {
        FIN_CLI::success( 'Invoked' );
      };
      $before_invoke_args = array( 'before_invoke' => function() {
        FIN_CLI::success( 'before invoke' );
      }, 'after_invoke' => function() {
        FIN_CLI::success( 'after invoke' );
      });
      FIN_CLI::add_command( 'before invoke', $before_invoke, $before_invoke_args );
      FIN_CLI::add_command( 'before-invoke', $before_invoke, $before_invoke_args );
      """

    When I run `fin --require=call-invoke.php before invoke`
    Then STDOUT should contain:
      """
      Success: before invoke
      Success: Invoked
      Success: after invoke
      """

    When I run `fin --require=call-invoke.php before-invoke`
    Then STDOUT should contain:
      """
      Success: before invoke
      Success: Invoked
      Success: after invoke
      """

  Scenario: Default arguments should respect fin-cli.yml
    Given a FIN installation
    And a fin-cli.yml file:
      """
      post list:
        format: count
      """

    When I run `fin post list`
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
         * @when before_fin_load
         */
        function message( $args ) {
          FIN_CLI::success( $this->message );
        }
      }
      $foo = new Foo_Class( 'bar' );
      FIN_CLI::add_command( 'instantiated-command', $foo );
      """

    When I run `fin --require=custom-cmd.php instantiated-command message`
    Then STDOUT should contain:
      """
      bar
      """
    And STDERR should be empty

  Scenario: FIN-CLI suggests matching commands when user entry contains typos
    Given a FIN installation

    When I try `fin clu`
    Then STDERR should contain:
      """
      Did you mean 'cli'?
      """

    When I try `fin cli nfo`
    Then STDERR should contain:
      """
      Did you mean 'info'?
      """

    When I try `fin cli beyondlevenshteinthreshold`
    Then STDERR should not contain:
      """
      Did you mean
      """

  Scenario: FIN-CLI suggests matching parameters when user entry contains typos
    Given an empty directory

    When I try `fin cli info --quie`
    Then STDERR should contain:
      """
      Did you mean '--quiet'?
      """

    When I try `fin cli info --forma=json`
    Then STDERR should contain:
      """
      Did you mean '--format'?
      """

  Scenario: Adding a command can be aborted through the hooks system
    Given an empty directory
    And a abort-add-command.php file:
      """
      <?php
      FIN_CLI::add_hook( 'before_add_command:test-command-2', function ( $addition ) {
        $addition->abort( 'Testing hooks.' );
      } );

      FIN_CLI::add_command( 'test-command-1', function () {} );
      FIN_CLI::add_command( 'test-command-2', function () {} );
      """

    When I try `fin --require=abort-add-command.php`
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

      FIN_CLI::add_hook( 'after_add_command:test-command', function () {
        FIN_CLI::add_command( 'test-command sub-command', function () {} );
      } );

      FIN_CLI::add_command( 'test-command', 'TestCommand' );
      """

    When I run `fin --require=add-dependent-command.php`
    Then STDOUT should contain:
      """
      test-command
      """

    When I run `fin --require=add-dependent-command.php help test-command`
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

      FIN_CLI::add_command( 'test-command sub-command', function () {} );

      FIN_CLI::add_command( 'test-command', 'TestCommand' );
      """

    When I run `fin --require=add-deferred-command.php`
    Then STDOUT should contain:
      """
      test-command
      """

    When I run `fin --require=add-deferred-command.php help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

  Scenario: Command additions should work as plugins
    Given a FIN installation
    And a fin-content/plugins/test-cli/command.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      function test_function() {
        \FIN_CLI::success( 'unknown-parent child-command' );
      }

      FIN_CLI::add_command( 'unknown-parent child-command', 'test_function' );

      FIN_CLI::add_command( 'test-command sub-command', function () { \FIN_CLI::success( 'test-command sub-command' ); } );

      FIN_CLI::add_command( 'test-command', 'TestCommand' );
      """
    And I run `fin plugin activate test-cli`

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin`
    Then STDOUT should contain:
      """
      test-command
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

    When I run `fin test-command sub-command`
    Then STDOUT should contain:
      """
      Success: test-command sub-command
      """

    When I run `fin unknown-parent child-command`
    Then STDOUT should contain:
      """
      Success: unknown-parent child-command
      """

  Scenario: Command additions should work as must-use plugins
    Given a FIN installation
    And a fin-content/mu-plugins/test-cli.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      function test_function() {
        \FIN_CLI::success( 'unknown-parent child-command' );
      }

      FIN_CLI::add_command( 'unknown-parent child-command', 'test_function' );

      FIN_CLI::add_command( 'test-command sub-command', function () { \FIN_CLI::success( 'test-command sub-command' ); } );

      FIN_CLI::add_command( 'test-command', 'TestCommand' );
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin`
    Then STDOUT should contain:
      """
      test-command
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

    When I run `fin test-command sub-command`
    Then STDOUT should contain:
      """
      Success: test-command sub-command
      """

    When I run `fin unknown-parent child-command`
    Then STDOUT should contain:
      """
      Success: unknown-parent child-command
      """

  Scenario: Command additions should work when registered on after_fin_load
    Given a FIN installation
    And a fin-content/mu-plugins/test-cli.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      function test_function() {
        \FIN_CLI::success( 'unknown-parent child-command' );
      }

      FIN_CLI::add_hook( 'after_fin_load', function(){
        FIN_CLI::add_command( 'unknown-parent child-command', 'test_function' );

        FIN_CLI::add_command( 'test-command sub-command', function () { \FIN_CLI::success( 'test-command sub-command' ); } );

        FIN_CLI::add_command( 'test-command', 'TestCommand' );
      });
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin`
    Then STDOUT should contain:
      """
      test-command
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin help test-command`
    Then STDOUT should contain:
      """
      sub-command
      """

    When I run `fin test-command sub-command`
    Then STDOUT should contain:
      """
      Success: test-command sub-command
      """

    When I run `fin unknown-parent child-command`
    Then STDOUT should contain:
      """
      Success: unknown-parent child-command
      """

  Scenario: The command should fire on `after_fin_load`
    Given a FIN installation
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fin_load
       */
      class Custom_Command_Class extends FIN_CLI_Command {
          /**
           * @when after_fin_load
           */
          public function after_fin_load() {
             var_dump( function_exists( 'home_url' ) );
          }
          public function before_fin_load() {
             var_dump( function_exists( 'home_url' ) );
          }
      }
      FIN_CLI::add_command( 'command', 'Custom_Command_Class' );
      """
    And a fin-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fin command after_fin_load`
    Then STDOUT should contain:
      """
      bool(true)
      """
    And the return code should be 0

    When I run `fin command before_fin_load`
    Then STDOUT should contain:
      """
      bool(false)
      """
    And the return code should be 0

    When I try `fin command after_fin_load --path=/tmp`
    Then STDERR should contain:
      """
      Error: This does not seem to be a FinPress installation.
      """
    And the return code should be 1

  Scenario: The command should fire on `before_fin_load`
    Given a FIN installation
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when after_fin_load
       */
      class Custom_Command_Class extends FIN_CLI_Command {
          /**
           * @when before_fin_load
           */
          public function before_fin_load() {
             var_dump( function_exists( 'home_url' ) );
          }

          public function after_fin_load() {
             var_dump( function_exists( 'home_url' ) );
          }
      }
      FIN_CLI::add_command( 'command', 'Custom_Command_Class' );
      """
    And a fin-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fin command before_fin_load`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      bool(false)
      """
    And the return code should be 0

    When I run `fin command after_fin_load`
    Then STDERR should be empty
    And STDOUT should contain:
      """
      bool(true)
      """
    And the return code should be 0

  Scenario: Command hook should fires as expected on __invoke()
    Given a FIN installation
    And a custom-cmd.php file:
      """
      <?php
      /**
       * @when before_fin_load
       */
      class Custom_Command_Class extends FIN_CLI_Command {
          /**
           * @when after_fin_load
           */
          public function __invoke() {
             var_dump( function_exists( 'home_url' ) );
          }
      }
      FIN_CLI::add_command( 'command', 'Custom_Command_Class' );
      """
    And a fin-cli.yml file:
      """
      require:
        - custom-cmd.php
      """

    When I run `fin command`
    Then STDOUT should contain:
      """
      bool(true)
      """
    And the return code should be 0

    When I try `fin command --path=/tmp`
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
      class My_Command_Namespace extends \FIN_CLI\Dispatcher\CommandNamespace {}
      FIN_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );
      """

    When I run `fin help --require=command-namespace.php`
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
      class My_Namespaced_Command extends FIN_CLI_Command {}
      FIN_CLI::add_command( 'my-namespaced-command', 'My_Namespaced_Command' );

      /**
       * My Command Namespace Description.
       */
      class My_Command_Namespace extends \FIN_CLI\Dispatcher\CommandNamespace {}
      FIN_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );
      """

    When I run `fin help --require=command-namespace.php`
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
      class My_Command_Namespace extends \FIN_CLI\Dispatcher\CommandNamespace {}
      FIN_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );

      /**
       * My Actual Namespaced Command.
       */
      class My_Namespaced_Command extends FIN_CLI_Command {}
      FIN_CLI::add_command( 'my-namespaced-command', 'My_Namespaced_Command' );
      """

    When I run `fin help --require=command-namespace.php`
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
      class My_Command_Namespace extends \FIN_CLI\Dispatcher\CommandNamespace {}
      FIN_CLI::add_command( 'my-namespaced-command', 'My_Command_Namespace' );
      """

    When I run `fin --require=command-namespace.php my-namespaced-command`
    Then STDOUT should contain:
      """
      The namespace my-namespaced-command does not contain any usable commands in the current context.
      """
    And STDERR should be empty

  Scenario: Late-registered command should appear in command usage
    Given a FIN installation
    And a test-cmd.php file:
      """
      <?php
      FIN_CLI::add_fin_hook( 'plugins_loaded', function(){
        FIN_CLI::add_command( 'core custom-subcommand', function() {});
      });
      """
    And a fin-cli.yml file:
      """
      require:
        - test-cmd.php
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin help core`
    Then STDOUT should contain:
      """
      custom-subcommand
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin core`
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
    Given a FIN installation
    And a fin-content/plugins/custom-command/custom-cmd.php file:
      """
      <?php
      // Plugin Name: Custom Command

      add_action( 'cli_init', function() {
        FIN_CLI::add_command( 'custom', function () {} );
      } );
      """
    And I run `fin plugin activate custom-command`
    # TODO: Throwing deprecations with PHP 8.1+ and FIN < 5.9
    When I try `fin custom --help`
    Then STDOUT should contain:
      """
      fin custom
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
         * @when before_fin_load
         *
         */
        public function foo( $args, $assoc_args ) {
          echo 'Hello' . PHP_EOL;
        }
      }

      FIN_CLI::add_command( 'test', Test_Command::class );
      """

    When I run `fin --require=custom-cmd.php test foo`
    Then STDOUT should contain:
      """
      Hello
      """

    When I run `fin --require=custom-cmd.php test bar`
    Then STDOUT should contain:
      """
      Hello
      """
