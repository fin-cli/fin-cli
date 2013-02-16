Feature: core
  In order to manage WordPress
  As a UNIX user
  I need to be able to install it

  Scenario: Empty dir
    Given an empty directory
    When I run `wp core is-installed`
    Then the return code should be 1

  Scenario: No wp-config.php
    Given an empty directory
    And WP files

    When I run `wp core is-installed`
    Then the return code should be 1

    When I run `wp core install`
    Then STDERR should be:
      """
      Error: wp-config.php not found.
      Either create one manually or use `wp core config`.
      """
    
    When I run `wp core config`
    Then the return code should be 0
    And the wp-config.php file should exist

  Scenario: Database doesn't exist
    Given an empty directory
    And WP files
    And wp-config.php

    When I run `wp`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: Can’t select database
      """

    When I run `wp db create`
    Then the return code should be 0

  Scenario: Database tables not installed
    Given an empty directory
    And WP files
    And wp-config.php
    And a database

    When I run `wp core is-installed`
    Then the return code should be 1

    When I run `wp`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: The site you have requested is not installed.
      Run `wp core install`.
      """

    When I run `wp core install`
    Then the return code should be 0

    When I run `wp post list --ids`
    Then STDOUT should be:
      """
      1
      """

  Scenario: Full install
    Given WP install

    When I run `wp core is-installed`
    Then the return code should be 0

  Scenario: Custom wp-content directory
    Given WP install
    And custom wp-content directory

    When I run `wp theme status twentytwelve`
    Then the return code should be 0

    When I run `wp plugin status hello`
    Then the return code should be 0
