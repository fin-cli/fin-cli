Feature: Runner FP-CLI

  Scenario: Path argument should be slashed correctly
    When I try `fp no-such-command --path=/foo --debug`
    Then STDERR should contain:
      """
      ABSPATH defined: /foo/
      """

    When I try `fp no-such-command --path=/foo/ --debug`
    Then STDERR should contain:
      """
      ABSPATH defined: /foo/
      """

    When I try `fp no-such-command --path=/foo\\ --debug`
    Then STDERR should contain:
      """
      ABSPATH defined: /foo/
      """

  Scenario: ABSPATH can be defined outside of FP-CLI
    Given an empty directory
    And a fp-cli.yml file:
      """
      require:
        - abspath.php
      """
    And a abspath.php file:
      """
      <?php
      if ( ! defined( 'ABSPATH' ) ) {
          define( 'ABSPATH', '/some_path/' );
      }
      """

    When I try `fp no-such-command --debug`
    Then STDERR should not contain:
      """
      Constant ABSPATH already defined in
      """
    And STDERR should contain:
      """
      ABSPATH defined: /some_path/
      """

    When I try `fp no-such-command --path=/foo --debug`
    Then STDERR should contain:
      """
      The --path parameter cannot be used when ABSPATH is already defined elsewhere
      """

  Scenario: Empty path argument should be handled correctly
    When I try `fp no-such-command --path`
    Then STDERR should contain:
      """
      The --path parameter cannot be empty when provided
      """

    When I try `fp no-such-command --path=`
    Then STDERR should contain:
      """
      The --path parameter cannot be empty when provided
      """

    When I try `fp no-such-command --path= some_path`
    Then STDERR should contain:
      """
      The --path parameter cannot be empty when provided
      """

  Scenario: Suggest 'meta' when 'option' subcommand is run
    Given a FP install

    When I try `fp network option`
    Then STDERR should contain:
      """
      Error: 'option' is not a registered subcommand of 'network'. See 'fp help network' for available subcommands.
      Did you mean 'meta'?
      """
    And the return code should be 1

  Scenario: Suggest 'fp term <command>' when an invalid taxonomy command is run
    Given a FP install

    When I try `fp category list`
    Then STDERR should contain:
      """
      Did you mean 'fp term <command>'?
      """
    And the return code should be 1

  Scenario: Suggest 'fp post <command>' when an invalid post type command is run
    Given a FP install

    When I try `fp page create`
    Then STDERR should contain:
      """
      Did you mean 'fp post --post_type=page <command>'?
      """
    And the return code should be 1
