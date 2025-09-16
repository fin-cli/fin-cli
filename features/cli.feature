Feature: `fin cli` tasks

  @less-than-php-8
  Scenario: Ability to detect a FIN-CLI registered command
    Given a FIN installation

    # Allow for composer/ca-bundle using `openssl_x509_parse()` which throws PHP warnings on old versions of PHP.
    When I try `fin package install fin-cli/scaffold-package-command`
    And I run `fin cli has-command scaffold package`
    Then the return code should be 0

    # Allow for composer/ca-bundle using `openssl_x509_parse()` which throws PHP warnings on old versions of PHP.
    When I try `fin package uninstall fin-cli/scaffold-package-command`
    And I try `fin cli has-command scaffold package`
    Then the return code should be 1

  Scenario: Ability to detect a command which is registered by plugin
    Given a FIN installation
    And a fin-content/mu-plugins/test-cli.php file:
      """
      <?php
      // Plugin Name: Test CLI Help

      class TestCommand {
      }

      FIN_CLI::add_command( 'test-command', 'TestCommand' );
      """

    When I run `fin cli has-command test-command`
    Then the return code should be 0

  Scenario: Dump the list of global parameters with values
    Given a FIN installation

    When I run `fin cli param-dump --with-values | grep -o '"current":' | uniq -c | tr -d ' '`
    Then STDOUT should be:
      """
      19"current":
      """
    And STDERR should be empty
    And the return code should be 0

  Scenario: Checking whether a global configuration parameter exists or not
    Given a FIN installation
    And a custom-cmd.php file:
      """
      <?php
      class Custom_Command extends FIN_CLI_Command {

          /**
           * Custom command to validate a global configuration does exist or not.
           *
           * <config>
           * : Configuration parameter name to check for.
           *
           * @when after_fin_load
           */
          public function __invoke( $args ) {
              if ( FIN_CLI::has_config( $args[0] ) ) {
                  FIN_CLI::log( "Global configuration '{$args[0]}' does exist." );
              } else {
                  FIN_CLI::log( "Global configuration '{$args[0]}' does not exist." );
              }
          }
      }
      FIN_CLI::add_command( 'custom-command', 'Custom_Command' );
      """

    When I run `fin --require=custom-cmd.php custom-command url`
    Then STDOUT should be:
      """
      Global configuration 'url' does exist.
      """

    When I run `fin --require=custom-cmd.php custom-command dummy`
    Then STDOUT should be:
      """
      Global configuration 'dummy' does not exist.
      """
