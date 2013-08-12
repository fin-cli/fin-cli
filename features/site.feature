Feature: Manage sites in a multisite installation

  Scenario: Delete a site by id
    Given a WP multisite install

    When I run `wp site create --slug=first --porcelain`
    Then STDOUT should be a number
    And save STDOUT as {SITE_ID}

    When I run `wp site list`
    Then STDOUT should be a table containing rows:
      | blog_id | domain      | path    |
      | 1       | example.com | /       |
      | 2       | example.com | /first/ |

    When I run `wp site delete {SITE_ID} --yes`
    Then STDOUT should not be empty

    When I try the previous command again
    Then the return code should be 1

  Scenario: Delete a site by slug
    Given a WP multisite install

    When I run `wp site create --slug=first`
    Then STDOUT should not be empty

    When I run `wp site delete --slug=first --yes`
    Then STDOUT should not be empty

    When I try the previous command again
    Then the return code should be 1

 Scenario: Empty a site
    Given a WP install

    When I run `wp post create --post_title='Test post' --post_content='Test content.' --porcelain`
    Then STDOUT should not be empty

    When I run `wp term create 'Test term' post_tag --slug=test --description='This is a test term'`
    Then STDOUT should not be empty

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --format=ids`
    Then STDOUT should be empty

    When I run `wp term list post_tag --format=ids`
    Then STDOUT should be empty
