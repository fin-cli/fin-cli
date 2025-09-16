Feature: Review CLI information

  Background:
    When I run `fin package path`
    Then save STDOUT as {PACKAGE_PATH}

  Scenario: Get the path to the packages directory
    Given an empty directory
    And a non-existent {PACKAGE_PATH} directory

    When I run `fin cli info --format=json`
    Then STDOUT should be JSON containing:
      """
      {"fin_cli_packages_dir_path":null}
      """

    # Allow for composer/ca-bundle using `openssl_x509_parse()` which throws PHP warnings on old versions of PHP.
    When I try `fin package install danielbachhuber/fin-cli-reset-post-date-command`
    And I run `fin cli info --format=json`
    Then STDOUT should be JSON containing:
      """
      {"fin_cli_packages_dir_path":"{PACKAGE_PATH}"}
      """

    When I run `fin cli info`
    Then STDOUT should contain:
      """
      FIN-CLI packages dir:
      """

  Scenario: Packages directory path should be slashed correctly
    When I run `FIN_CLI_PACKAGES_DIR=/foo fin package path`
    Then STDOUT should be:
      """
      /foo/
      """

    When I run `FIN_CLI_PACKAGES_DIR=/foo/ fin package path`
    Then STDOUT should be:
      """
      /foo/
      """

    When I run `FIN_CLI_PACKAGES_DIR=/foo\\ fin package path`
    Then STDOUT should be:
      """
      /foo/
      """
