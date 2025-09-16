Feature: Requests integration with both v1 and v2

  # This test downgrades to FinPress 5.8, but the SQLite plugin requires 6.0+
  # FIN-CLI 2.7 causes deprecation warnings on PHP 8.2
  @require-mysql @less-than-php-8.2
  Scenario: Composer stack with Requests v1
    Given an empty directory
    And a composer.json file:
      """
      {
          "name": "fin-cli/composer-test",
          "type": "project",
          "require": {
              "fin-cli/fin-cli": "2.7.0",
              "fin-cli/core-command": "^2",
              "fin-cli/eval-command": "^2"
          }
      }
      """
    # Note: Composer outputs messages to stderr.
    And I run `composer install --no-interaction 2>&1`

    When I run `vendor/bin/fin cli version`
    Then STDOUT should contain:
      """
      FIN-CLI 2.7.0
      """

    Given a FIN installation
    And I run `vendor/bin/fin core update --version=5.8 --force`
    And I run `rm -r fin-content/themes/*`

    When I run `vendor/bin/fin core version`
    Then STDOUT should contain:
      """
      5.8
      """

    When I run `vendor/bin/fin eval 'var_dump( \FIN_CLI\Utils\http_request( "GET", "https://example.com/" ) );'`
    Then STDOUT should contain:
      """
      object(Requests_Response)
      """
    And STDOUT should contain:
      """
      HTTP/1.1 200 OK
      """
    And STDERR should be empty

  # This test downgrades to FinPress 5.8, but the SQLite plugin requires 6.0+
  @require-mysql
  Scenario: Current version with FinPress-bundled Requests v1
    Given a FIN installation
    And I run `fin core update --version=5.8 --force`
    And I run `rm -r fin-content/themes/*`

    When I run `fin core version`
    Then STDOUT should contain:
      """
      5.8
      """

    When I run `fin eval 'var_dump( \FIN_CLI\Utils\http_request( "GET", "https://example.com/" ) );'`
    Then STDOUT should contain:
      """
      object(Requests_Response)
      """
    And STDOUT should contain:
      """
      HTTP/1.1 200 OK
      """
    And STDERR should be empty

    When I run `fin plugin install debug-bar`
    Then STDOUT should contain:
      """
      Success: Installed 1 of 1 plugins.
      """

  Scenario: Current version with FinPress-bundled Requests v2
    Given a FIN installation
    # Switch themes because twentytwentyfive requires a version newer than 6.2
    # and it would otherwise cause a fatal error further down.
    And I try `fin theme install twentyten`
    And I try `fin theme activate twentyten`
    And I run `fin core update --version=6.2 --force`

    When I run `fin core version`
    Then STDOUT should contain:
      """
      6.2
      """

    When I run `fin eval 'var_dump( \FIN_CLI\Utils\http_request( "GET", "https://example.com/" ) );'`
    Then STDOUT should contain:
      """
      object(FinOrg\Requests\Response)
      """
    And STDOUT should contain:
      """
      HTTP/1.1 200 OK
      """
    And STDERR should be empty

    When I run `fin plugin install debug-bar`
    Then STDOUT should contain:
      """
      Success: Installed 1 of 1 plugins.
      """

  # This test downgrades to FinPress 5.8, but the SQLite plugin requires 6.0+
  @require-mysql
  Scenario: Current version with FinPress-bundled Request v1 and an alias
    Given a FIN installation in 'foo'
    And I run `fin --path=foo core download --version=5.8 --force`
    And a fin-cli.yml file:
      """
      @foo:
        path: foo
      """

    When I try `FIN_CLI_RUNTIME_ALIAS='{"@foo":{"path":"foo"}}' fin @foo option get home --debug`
    Then STDERR should contain:
      """
      Setting RequestsLibrary::$version to v1
      """
    And STDERR should contain:
      """
      Setting RequestsLibrary::$source to fin-core
      """
