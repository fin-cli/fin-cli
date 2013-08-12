Feature: Manage WordPress terms

  Scenario: Creating/listing a term
    Given a WP install

    When I run `wp term create 'Test term' post_tag --slug=test --description='This is a test term' --porcelain`
    Then STDOUT should be a number

    When I try the previous command again
    Then STDERR should not be empty

    When I run `wp term list post_tag --format=json`
    Then STDOUT should be JSON containing:
      """
      [{"name":"Test term","slug":"test","description":"This is a test term","parent":"0","count":"0"}]
      """

    When I run `wp term list post_tag --fields=name,slug --format=csv`
    Then STDOUT should be CSV containing:
      | name      | slug |
      | Test term | test |

  Scenario: Creating/deleting a term
    Given a WP install

    When I run `wp term create 'Test delete term' post_tag --slug=test-delete --description='This is a test term to be deleted' --porcelain`
    Then STDOUT should be a number
    And save STDOUT as {TERM_ID}

    When I run `wp term delete {TERM_ID} post_tag`
    Then STDOUT should contain:
      """
      Deleted post_tag {TERM_ID}.
      """

    When I try the previous command again
    Then STDERR should not be empty
