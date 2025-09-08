Feature: Utilities that depend on FinPress code

  Scenario: Clear FP cache
    Given a FP installation
    And a test.php file:
      """
      <?php
      FP_CLI::add_hook( 'after_fp_load', function () {
        global $fp_object_cache;
        echo empty( $fp_object_cache->cache ) . ',' . isset( $fp_object_cache->group_ops ) . ',' . isset( $fp_object_cache->stats ) . ',' . isset( $fp_object_cache->memcache_debug ) . "\n";
        FP_CLI\Utils\fp_clear_object_cache();
        echo empty( $fp_object_cache->cache ) . ',' . isset( $fp_object_cache->group_ops ) . ',' . isset( $fp_object_cache->stats ) . ',' . isset( $fp_object_cache->memcache_debug ) . "\n";
      } );
      """

    When I run `fp post create --post_title="Foo Bar" --porcelain`
    And I run `fp --require=test.php eval ''`
    Then STDOUT should be:
      """
      ,,,
      1,,,
      """

  # `fp db query` does not yet work on SQLite,
  # See https://github.com/fp-cli/db-command/issues/234
  @require-mysql
  Scenario: Get FP table names for single site install
    Given a FP installation
    And I run `fp db query "CREATE TABLE xx_fp_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_xx_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_posts_xx ( id int );"`
    And I run `fp db query "CREATE TABLE fp_categories ( id int );"`
    And I run `fp db query "CREATE VIEW fp_posts_view AS ( SELECT ID from fp_posts );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test FP get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'fp_*_options' or 'fp_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite installation. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $fpdb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $fpdb. Overrides --all-tables-with-prefix.
       *
       * [--base-tables-only]
       * : Restrict returned tables to those that are not views.
       *
       * [--views-only]
       * : Restrict returned tables to those that are views.
       */
      function test_fp_get_table_names( $args, $assoc_args ) {
        if ( $tables = FP_CLI\Utils\fp_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      FP_CLI::add_command( 'get_table_names', 'test_fp_get_table_names' );
      """

    When I run `fp --require=table_names.php get_table_names`
    Then STDOUT should contain:
      """
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      """
    And save STDOUT as {DEFAULT_STDOUT}

    When I run `fp --require=table_names.php get_table_names --all-tables-with-prefix --views-only`
    Then STDOUT should be:
      """
      fp_posts_view
      """

    When I run `fp --require=table_names.php get_table_names --all-tables --base-tables-only`
    Then STDOUT should not contain:
      """
      fp_posts_view
      """
    But STDOUT should contain:
      """
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_posts_xx
      fp_term_relationships
      fp_term_taxonomy
      """
  # Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      """

    When I run `fp --require=table_names.php get_table_names --scope=all`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --scope=blog`
    Then STDOUT should contain:
      """
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      """

    When I run `fp --require=table_names.php get_table_names --scope=global`
    Then STDOUT should be:
      """
      fp_usermeta
      fp_users
      """

    When I run `fp --require=table_names.php get_table_names --scope=ms_global`
    Then STDOUT should be empty

    When I run `fp --require=table_names.php get_table_names --scope=old`
    Then STDOUT should be:
      """
      fp_categories
      """

    When I run `fp --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      fp_categories
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_posts_view
      fp_posts_xx
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      fp_xx_posts
      """

    When I run `fp --require=table_names.php get_table_names --all-tables`
    Then STDOUT should contain:
      """
      fp_categories
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_posts_view
      fp_posts_xx
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      fp_xx_posts
      xx_fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts'`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*'`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts'`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --scope=blog`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I try `fp --require=table_names.php get_table_names '*_posts' --scope=global`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    When I run `fp --require=table_names.php get_table_names '*_posts' --network`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_posts
      fp_xx_posts
      """

    When I run `fp --require=table_names.php get_table_names '*fp_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      fp_posts_view
      fp_posts_xx
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_posts
      fp_xx_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --all-tables`
    Then STDOUT should be:
      """
      fp_posts
      fp_xx_posts
      xx_fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*fp_posts' --all-tables`
    Then STDOUT should be:
      """
      fp_posts
      xx_fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*' --all-tables`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      fp_posts_view
      fp_posts_xx
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts' --all-tables`
    Then STDOUT should be:
      """
      fp_posts
      fp_xx_posts
      """

    When I try `fp --require=table_names.php get_table_names non_existent_table`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: non_existent_table
      """
    And STDOUT should be empty

    When I run `fp --require=table_names.php get_table_names fp_posts non_existent_table`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names fp_posts non_existent_table 'fp_?ption*'`
    Then STDOUT should be:
      """
      fp_options
      fp_posts
      """

  # `fp db query` does not yet work on SQLite,
  # See https://github.com/fp-cli/db-command/issues/234
  @require-mysql
  Scenario: Get FP table names for multisite install
    Given a FP multisite install
    And I run `fp db query "CREATE TABLE xx_fp_posts ( id int );"`
    And I run `fp db query "CREATE TABLE xx_fp_2_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_xx_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_2_xx_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_posts_xx ( id int );"`
    And I run `fp db query "CREATE TABLE fp_2_posts_xx ( id int );"`
    And I run `fp db query "CREATE TABLE fp_categories ( id int );"`
    And I run `fp db query "CREATE TABLE fp_sitecategories ( id int );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test FP get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'fp_*_options' or 'fp_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite installation. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $fpdb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $fpdb. Overrides --all-tables-with-prefix.
       */
      function test_fp_get_table_names( $args, $assoc_args ) {
        if ( $tables = FP_CLI\Utils\fp_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      FP_CLI::add_command( 'get_table_names', 'test_fp_get_table_names' );
      """

    # With no subsite.
    When I run `fp --require=table_names.php get_table_names`
    # Leave out fp_blog_versions as it was never used and is removed with FP 5.3+.
    # Leave out fp_blogmeta for old FP compat.
    Then STDOUT should contain:
      """
      fp_blogs
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_registration_log
      fp_signups
      fp_site
      fp_sitemeta
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      """
    And save STDOUT as {DEFAULT_STDOUT}

    When I run `fp --require=table_names.php get_table_names --scope=all`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --scope=blog`
    Then STDOUT should contain:
      """
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      """

    When I run `fp --require=table_names.php get_table_names --scope=global`
    # Leave out fp_blog_versions as it was never used and is removed with FP 5.3+.
    # Leave out fp_blogmeta for old FP compat.
    Then STDOUT should contain:
      """
      fp_blogs
      fp_registration_log
      fp_signups
      fp_site
      fp_sitemeta
      fp_usermeta
      fp_users
      """
    And save STDOUT as {GLOBAL_STDOUT}

    When I run `fp --require=table_names.php get_table_names --scope=ms_global`
    # Leave out fp_blog_versions as it was never used and is removed with FP 5.3+.
    # Leave out fp_blogmeta for old FP compat.
    Then STDOUT should contain:
      """
      fp_blogs
      fp_registration_log
      fp_signups
      fp_site
      fp_sitemeta
      """

    When I run `fp --require=table_names.php get_table_names --scope=old`
    Then STDOUT should be:
      """
      fp_categories
      """

    When I run `fp --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    # With subsite.
    Given I run `fp site create --slug=foo`
    When I run `fp --require=table_names.php get_table_names`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --url=example.com/foo --scope=blog`
    Then STDOUT should contain:
      """
      fp_2_commentmeta
      fp_2_comments
      fp_2_links
      fp_2_options
      fp_2_postmeta
      fp_2_posts
      fp_2_term_relationships
      fp_2_term_taxonomy
      """
	# Leave out fp_2_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_2_terms
      """
    And save STDOUT as {SUBSITE_BLOG_STDOUT}

    When I run `fp --require=table_names.php get_table_names --url=example.com/foo`
    Then STDOUT should be:
      """
      {SUBSITE_BLOG_STDOUT}
      {GLOBAL_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {SUBSITE_BLOG_STDOUT}
      {DEFAULT_STDOUT}
      """
    And save STDOUT as {NETWORK_STDOUT}

    When I run `fp --require=table_names.php get_table_names --network --url=example.com/foo`
    Then STDOUT should be:
      """
      {NETWORK_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      fp_2_commentmeta
      fp_2_comments
      fp_2_links
      fp_2_options
      fp_2_postmeta
      fp_2_posts
      fp_2_posts_xx
      fp_2_term_relationships
      fp_2_term_taxonomy
      """
	# Leave out fp_2_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_2_terms
      fp_2_xx_posts
      """
    # Leave out fp_blog_versions as it was never used and is removed with FP 5.3+.
    # Leave out fp_blogmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_blogs
      fp_categories
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_posts_xx
      fp_registration_log
      fp_signups
      fp_site
      fp_sitecategories
      fp_sitemeta
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      fp_xx_posts
      """
    And save STDOUT as {ALL_TABLES_WITH_PREFIX_STDOUT}

    # Network overridden by all-tables-with-prefix.
    When I run `fp --require=table_names.php get_table_names --all-tables-with-prefix --network`
    Then STDOUT should contain:
      """
      {ALL_TABLES_WITH_PREFIX_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names --all-tables`
    Then STDOUT should be:
      """
      {ALL_TABLES_WITH_PREFIX_STDOUT}
      xx_fp_2_posts
      xx_fp_posts
      """
    And save STDOUT as {ALL_TABLES_STDOUT}

    # Network overridden by all-tables.
    When I run `fp --require=table_names.php get_table_names --all-tables --network`
    Then STDOUT should be:
      """
      {ALL_TABLES_STDOUT}
      """

    When I run `fp --require=table_names.php get_table_names '*_posts'`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --network`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*'`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*' --network`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts'`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts' --network`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --scope=blog`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --scope=blog --network`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_posts
      """

    When I try `fp --require=table_names.php get_table_names '*_posts' --scope=global`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    # Note: BC change 1.5.0, network does not override scope.
    When I try `fp --require=table_names.php get_table_names '*_posts' --scope=global --network`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    When I run `fp --require=table_names.php get_table_names '*_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_2_xx_posts
      fp_posts
      fp_xx_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      fp_posts_xx
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_2_xx_posts
      fp_posts
      fp_xx_posts
      """

    When I run `fp --require=table_names.php get_table_names '*_posts' --all-tables`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_2_xx_posts
      fp_posts
      fp_xx_posts
      xx_fp_2_posts
      xx_fp_posts
      """

    When I run `fp --require=table_names.php get_table_names '*fp_posts' --all-tables`
    Then STDOUT should be:
      """
      fp_posts
      xx_fp_posts
      """

    When I run `fp --require=table_names.php get_table_names 'fp_post*' --all-tables`
    Then STDOUT should be:
      """
      fp_postmeta
      fp_posts
      fp_posts_xx
      """

    When I run `fp --require=table_names.php get_table_names 'fp*osts' --all-tables`
    Then STDOUT should be:
      """
      fp_2_posts
      fp_2_xx_posts
      fp_posts
      fp_xx_posts
      """

    When I try `fp --require=table_names.php get_table_names non_existent_table`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: non_existent_table
      """
    And STDOUT should be empty

    When I run `fp --require=table_names.php get_table_names fp_posts non_existent_table`
    Then STDOUT should be:
      """
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names fp_posts non_existent_table 'fp_?ption*'`
    Then STDOUT should be:
      """
      fp_options
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names fp_posts non_existent_table 'fp_*ption?'`
    Then STDOUT should be:
      """
      fp_options
      fp_posts
      """

    When I run `fp --require=table_names.php get_table_names fp_posts non_existent_table 'fp_*ption?' --network`
    Then STDOUT should be:
      """
      fp_2_options
      fp_options
      fp_posts
      """

  @less-than-fp-6.1
  Scenario: Get FP table names for multisite install (site_categories only)
    Given a FP multisite install
    And I run `fp db query "CREATE TABLE xx_fp_posts ( id int );"`
    And I run `fp db query "CREATE TABLE xx_fp_2_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_xx_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_2_xx_posts ( id int );"`
    And I run `fp db query "CREATE TABLE fp_posts_xx ( id int );"`
    And I run `fp db query "CREATE TABLE fp_2_posts_xx ( id int );"`
    And I run `fp db query "CREATE TABLE fp_categories ( id int );"`
    And I run `fp db query "CREATE TABLE fp_sitecategories ( id int );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test FP get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'fp_*_options' or 'fp_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite installation. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $fpdb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $fpdb. Overrides --all-tables-with-prefix.
       */
      function test_fp_get_table_names( $args, $assoc_args ) {
        if ( $tables = FP_CLI\Utils\fp_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      FP_CLI::add_command( 'get_table_names', 'test_fp_get_table_names' );
      """
    And an enable_sitecategories.php file:
      """
      <?php
      FP_CLI::add_hook( 'after_fp_load', function () {
        add_filter( 'global_terms_enabled', '__return_true' );
      } );
      """

    When I run `fp --require=table_names.php --require=enable_sitecategories.php get_table_names`
    # Leave out fp_blog_versions as it was never used and is removed with FP 5.3+.
    # Leave out fp_blogmeta for old FP compat.
    Then STDOUT should contain:
      """
      fp_blogs
      fp_commentmeta
      fp_comments
      fp_links
      fp_options
      fp_postmeta
      fp_posts
      fp_registration_log
      fp_signups
      fp_site
      fp_sitecategories
      fp_sitemeta
      fp_term_relationships
      fp_term_taxonomy
      """
	# Leave out fp_termmeta for old FP compat.
    And STDOUT should contain:
      """
      fp_terms
      fp_usermeta
      fp_users
      """
