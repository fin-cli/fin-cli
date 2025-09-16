Feature: Argument validation
  In order to catch errors fast
  As a user
  I need to see warnings and errors when I pass incorrect arguments

  Scenario: Passing zero arguments to a variadic command
    Given a FIN installation

    When I try `fin plugin install`
    Then the return code should be 1
    And STDOUT should contain:
      """
      usage: fin plugin install
      """

  Scenario: Validation for early commands
    Given an empty directory
    And FIN files

    When I try `fin core config`
    Then the return code should be 1
    And STDERR should contain:
      """
      Parameter errors:
      """
    And STDERR should contain:
      """
      missing --dbname parameter
      """

    When I try `fin core config --invalid --other-invalid`
    Then the return code should be 1
    And STDERR should contain:
      """
      unknown --invalid parameter
      """
    And STDERR should contain:
      """
      unknown --other-invalid parameter
      """

    When I try `fin core version invalid`
    Then the return code should be 1
    And STDERR should contain:
      """
      Error: Too many positional arguments: invalid
      """
    And STDOUT should be empty
