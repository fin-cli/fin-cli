Feature: Requests integration with both v1 and v2

  # This test downgrades to FinPress 5.8, but the SQLite plugin requires 6.0+
  # FP-CLI 2.7 causes deprecation warnings on PHP 8.2
  @require-mysql @less-than-php-8.2
  Scenario: Composer stack with Requests v1
    Given an empty directory
    And a composer.json file:
      """
      {
          "name": "fp-cli/composer-test",
          "type": "project",
          "require": {
              "fp-cli/fp-cli": "2.7.0",
              "fp-cli/core-command": "^2",
              "fp-cli/eval-command": "^2"
          }
      }
      """
    # Note: Composer outputs messages to stderr.
    And I run `composer install --no-interaction 2>&1`

    When I run `vendor/bin/fp cli version`
    Then STDOUT should contain:
      """
      FP-CLI 2.7.0
      """

    Given a FP installation
    And I run `vendor/bin/fp core update --version=5.8 --force`
    And I run `rm -r fp-content/themes/*`

    When I run `vendor/bin/fp core version`
    Then STDOUT should contain:
      """
      5.8
      """

    When I run `vendor/bin/fp eval 'var_dump( \FP_CLI\Utils\http_request( "GET", "https://example.com/" ) );'`
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
    Given a FP installation
    And I run `fp core update --version=5.8 --force`
    And I run `rm -r fp-content/themes/*`

    When I run `fp core version`
    Then STDOUT should contain:
      """
      5.8
      """

    When I run `fp eval 'var_dump( \FP_CLI\Utils\http_request( "GET", "https://example.com/" ) );'`
    Then STDOUT should contain:
      """
      object(Requests_Response)
      """
    And STDOUT should contain:
      """
      HTTP/1.1 200 OK
      """
    And STDERR should be empty

    When I run `fp plugin install debug-bar`
    Then STDOUT should contain:
      """
      Success: Installed 1 of 1 plugins.
      """

  Scenario: Current version with FinPress-bundled Requests v2
    Given a FP installation
    # Switch themes because twentytwentyfive requires a version newer than 6.2
    # and it would otherwise cause a fatal error further down.
    And I try `fp theme install twentyten`
    And I try `fp theme activate twentyten`
    And I run `fp core update --version=6.2 --force`

    When I run `fp core version`
    Then STDOUT should contain:
      """
      6.2
      """

    When I run `fp eval 'var_dump( \FP_CLI\Utils\http_request( "GET", "https://example.com/" ) );'`
    Then STDOUT should contain:
      """
      object(FpOrg\Requests\Response)
      """
    And STDOUT should contain:
      """
      HTTP/1.1 200 OK
      """
    And STDERR should be empty

    When I run `fp plugin install debug-bar`
    Then STDOUT should contain:
      """
      Success: Installed 1 of 1 plugins.
      """

  # This test downgrades to FinPress 5.8, but the SQLite plugin requires 6.0+
  @require-mysql
  Scenario: Current version with FinPress-bundled Request v1 and an alias
    Given a FP installation in 'foo'
    And I run `fp --path=foo core download --version=5.8 --force`
    And a fp-cli.yml file:
      """
      @foo:
        path: foo
      """

    When I try `FP_CLI_RUNTIME_ALIAS='{"@foo":{"path":"foo"}}' fp @foo option get home --debug`
    Then STDERR should contain:
      """
      Setting RequestsLibrary::$version to v1
      """
    And STDERR should contain:
      """
      Setting RequestsLibrary::$source to fp-core
      """
