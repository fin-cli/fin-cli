Feature: Manage a WordPress multisite installation

  Scenario: Install multisite
    Given a WP install

    When I run `wp core install-network`
    Then it should run without errors

    When I run the previous command again
    Then the return code should be 1

  Scenario: Delete a blog by id
    Given a WP multisite install

    When I run `wp blog create --slug=first --porcelain`
    Then it should run without errors
    And STDOUT should match '%d'
    And save STDOUT as {BLOG_ID}

    When I run `wp blog delete {BLOG_ID} --yes`
    Then it should run without errors
    And STDOUT should not be empty

    When I run the previous command again
    Then the return code should be 1

  Scenario: Delete a blog by slug
    Given a WP multisite install

    When I run `wp blog create --slug=first`
    Then it should run without errors
    And STDOUT should not be empty

    When I run `wp blog delete --slug=first --yes`
    Then it should run without errors
    And STDOUT should not be empty

    When I run the previous command again
    Then the return code should be 1
