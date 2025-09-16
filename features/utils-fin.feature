Feature: Utilities that depend on FinPress code

  Scenario: Clear FIN cache
    Given a FIN installation
    And a test.php file:
      """
      <?php
      FIN_CLI::add_hook( 'after_fin_load', function () {
        global $fin_object_cache;
        echo empty( $fin_object_cache->cache ) . ',' . isset( $fin_object_cache->group_ops ) . ',' . isset( $fin_object_cache->stats ) . ',' . isset( $fin_object_cache->memcache_debug ) . "\n";
        FIN_CLI\Utils\fin_clear_object_cache();
        echo empty( $fin_object_cache->cache ) . ',' . isset( $fin_object_cache->group_ops ) . ',' . isset( $fin_object_cache->stats ) . ',' . isset( $fin_object_cache->memcache_debug ) . "\n";
      } );
      """

    When I run `fin post create --post_title="Foo Bar" --porcelain`
    And I run `fin --require=test.php eval ''`
    Then STDOUT should be:
      """
      ,,,
      1,,,
      """

  # `fin db query` does not yet work on SQLite,
  # See https://github.com/fin-cli/db-command/issues/234
  @require-mysql
  Scenario: Get FIN table names for single site install
    Given a FIN installation
    And I run `fin db query "CREATE TABLE xx_fin_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_xx_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_posts_xx ( id int );"`
    And I run `fin db query "CREATE TABLE fin_categories ( id int );"`
    And I run `fin db query "CREATE VIEW fin_posts_view AS ( SELECT ID from fin_posts );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test FIN get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'fin_*_options' or 'fin_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite installation. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $findb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $findb. Overrides --all-tables-with-prefix.
       *
       * [--base-tables-only]
       * : Restrict returned tables to those that are not views.
       *
       * [--views-only]
       * : Restrict returned tables to those that are views.
       */
      function test_fin_get_table_names( $args, $assoc_args ) {
        if ( $tables = FIN_CLI\Utils\fin_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      FIN_CLI::add_command( 'get_table_names', 'test_fin_get_table_names' );
      """

    When I run `fin --require=table_names.php get_table_names`
    Then STDOUT should contain:
      """
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      """
    And save STDOUT as {DEFAULT_STDOUT}

    When I run `fin --require=table_names.php get_table_names --all-tables-with-prefix --views-only`
    Then STDOUT should be:
      """
      fin_posts_view
      """

    When I run `fin --require=table_names.php get_table_names --all-tables --base-tables-only`
    Then STDOUT should not contain:
      """
      fin_posts_view
      """
    But STDOUT should contain:
      """
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_posts_xx
      fin_term_relationships
      fin_term_taxonomy
      """
  # Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      """

    When I run `fin --require=table_names.php get_table_names --scope=all`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --scope=blog`
    Then STDOUT should contain:
      """
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      """

    When I run `fin --require=table_names.php get_table_names --scope=global`
    Then STDOUT should be:
      """
      fin_usermeta
      fin_users
      """

    When I run `fin --require=table_names.php get_table_names --scope=ms_global`
    Then STDOUT should be empty

    When I run `fin --require=table_names.php get_table_names --scope=old`
    Then STDOUT should be:
      """
      fin_categories
      """

    When I run `fin --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      fin_categories
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_posts_view
      fin_posts_xx
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      fin_xx_posts
      """

    When I run `fin --require=table_names.php get_table_names --all-tables`
    Then STDOUT should contain:
      """
      fin_categories
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_posts_view
      fin_posts_xx
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      fin_xx_posts
      xx_fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts'`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*'`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts'`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --scope=blog`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I try `fin --require=table_names.php get_table_names '*_posts' --scope=global`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    When I run `fin --require=table_names.php get_table_names '*_posts' --network`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_posts
      fin_xx_posts
      """

    When I run `fin --require=table_names.php get_table_names '*fin_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      fin_posts_view
      fin_posts_xx
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_posts
      fin_xx_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --all-tables`
    Then STDOUT should be:
      """
      fin_posts
      fin_xx_posts
      xx_fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*fin_posts' --all-tables`
    Then STDOUT should be:
      """
      fin_posts
      xx_fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*' --all-tables`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      fin_posts_view
      fin_posts_xx
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts' --all-tables`
    Then STDOUT should be:
      """
      fin_posts
      fin_xx_posts
      """

    When I try `fin --require=table_names.php get_table_names non_existent_table`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: non_existent_table
      """
    And STDOUT should be empty

    When I run `fin --require=table_names.php get_table_names fin_posts non_existent_table`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names fin_posts non_existent_table 'fin_?ption*'`
    Then STDOUT should be:
      """
      fin_options
      fin_posts
      """

  # `fin db query` does not yet work on SQLite,
  # See https://github.com/fin-cli/db-command/issues/234
  @require-mysql
  Scenario: Get FIN table names for multisite install
    Given a FIN multisite install
    And I run `fin db query "CREATE TABLE xx_fin_posts ( id int );"`
    And I run `fin db query "CREATE TABLE xx_fin_2_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_xx_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_2_xx_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_posts_xx ( id int );"`
    And I run `fin db query "CREATE TABLE fin_2_posts_xx ( id int );"`
    And I run `fin db query "CREATE TABLE fin_categories ( id int );"`
    And I run `fin db query "CREATE TABLE fin_sitecategories ( id int );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test FIN get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'fin_*_options' or 'fin_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite installation. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $findb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $findb. Overrides --all-tables-with-prefix.
       */
      function test_fin_get_table_names( $args, $assoc_args ) {
        if ( $tables = FIN_CLI\Utils\fin_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      FIN_CLI::add_command( 'get_table_names', 'test_fin_get_table_names' );
      """

    # With no subsite.
    When I run `fin --require=table_names.php get_table_names`
    # Leave out fin_blog_versions as it was never used and is removed with FIN 5.3+.
    # Leave out fin_blogmeta for old FIN compat.
    Then STDOUT should contain:
      """
      fin_blogs
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_registration_log
      fin_signups
      fin_site
      fin_sitemeta
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      """
    And save STDOUT as {DEFAULT_STDOUT}

    When I run `fin --require=table_names.php get_table_names --scope=all`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --scope=blog`
    Then STDOUT should contain:
      """
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      """

    When I run `fin --require=table_names.php get_table_names --scope=global`
    # Leave out fin_blog_versions as it was never used and is removed with FIN 5.3+.
    # Leave out fin_blogmeta for old FIN compat.
    Then STDOUT should contain:
      """
      fin_blogs
      fin_registration_log
      fin_signups
      fin_site
      fin_sitemeta
      fin_usermeta
      fin_users
      """
    And save STDOUT as {GLOBAL_STDOUT}

    When I run `fin --require=table_names.php get_table_names --scope=ms_global`
    # Leave out fin_blog_versions as it was never used and is removed with FIN 5.3+.
    # Leave out fin_blogmeta for old FIN compat.
    Then STDOUT should contain:
      """
      fin_blogs
      fin_registration_log
      fin_signups
      fin_site
      fin_sitemeta
      """

    When I run `fin --require=table_names.php get_table_names --scope=old`
    Then STDOUT should be:
      """
      fin_categories
      """

    When I run `fin --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    # With subsite.
    Given I run `fin site create --slug=foo`
    When I run `fin --require=table_names.php get_table_names`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --url=example.com/foo --scope=blog`
    Then STDOUT should contain:
      """
      fin_2_commentmeta
      fin_2_comments
      fin_2_links
      fin_2_options
      fin_2_postmeta
      fin_2_posts
      fin_2_term_relationships
      fin_2_term_taxonomy
      """
	# Leave out fin_2_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_2_terms
      """
    And save STDOUT as {SUBSITE_BLOG_STDOUT}

    When I run `fin --require=table_names.php get_table_names --url=example.com/foo`
    Then STDOUT should be:
      """
      {SUBSITE_BLOG_STDOUT}
      {GLOBAL_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {SUBSITE_BLOG_STDOUT}
      {DEFAULT_STDOUT}
      """
    And save STDOUT as {NETWORK_STDOUT}

    When I run `fin --require=table_names.php get_table_names --network --url=example.com/foo`
    Then STDOUT should be:
      """
      {NETWORK_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      fin_2_commentmeta
      fin_2_comments
      fin_2_links
      fin_2_options
      fin_2_postmeta
      fin_2_posts
      fin_2_posts_xx
      fin_2_term_relationships
      fin_2_term_taxonomy
      """
	# Leave out fin_2_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_2_terms
      fin_2_xx_posts
      """
    # Leave out fin_blog_versions as it was never used and is removed with FIN 5.3+.
    # Leave out fin_blogmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_blogs
      fin_categories
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_posts_xx
      fin_registration_log
      fin_signups
      fin_site
      fin_sitecategories
      fin_sitemeta
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      fin_xx_posts
      """
    And save STDOUT as {ALL_TABLES_WITH_PREFIX_STDOUT}

    # Network overridden by all-tables-with-prefix.
    When I run `fin --require=table_names.php get_table_names --all-tables-with-prefix --network`
    Then STDOUT should contain:
      """
      {ALL_TABLES_WITH_PREFIX_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names --all-tables`
    Then STDOUT should be:
      """
      {ALL_TABLES_WITH_PREFIX_STDOUT}
      xx_fin_2_posts
      xx_fin_posts
      """
    And save STDOUT as {ALL_TABLES_STDOUT}

    # Network overridden by all-tables.
    When I run `fin --require=table_names.php get_table_names --all-tables --network`
    Then STDOUT should be:
      """
      {ALL_TABLES_STDOUT}
      """

    When I run `fin --require=table_names.php get_table_names '*_posts'`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --network`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*'`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*' --network`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts'`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts' --network`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --scope=blog`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --scope=blog --network`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_posts
      """

    When I try `fin --require=table_names.php get_table_names '*_posts' --scope=global`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    # Note: BC change 1.5.0, network does not override scope.
    When I try `fin --require=table_names.php get_table_names '*_posts' --scope=global --network`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    When I run `fin --require=table_names.php get_table_names '*_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_2_xx_posts
      fin_posts
      fin_xx_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      fin_posts_xx
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_2_xx_posts
      fin_posts
      fin_xx_posts
      """

    When I run `fin --require=table_names.php get_table_names '*_posts' --all-tables`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_2_xx_posts
      fin_posts
      fin_xx_posts
      xx_fin_2_posts
      xx_fin_posts
      """

    When I run `fin --require=table_names.php get_table_names '*fin_posts' --all-tables`
    Then STDOUT should be:
      """
      fin_posts
      xx_fin_posts
      """

    When I run `fin --require=table_names.php get_table_names 'fin_post*' --all-tables`
    Then STDOUT should be:
      """
      fin_postmeta
      fin_posts
      fin_posts_xx
      """

    When I run `fin --require=table_names.php get_table_names 'fin*osts' --all-tables`
    Then STDOUT should be:
      """
      fin_2_posts
      fin_2_xx_posts
      fin_posts
      fin_xx_posts
      """

    When I try `fin --require=table_names.php get_table_names non_existent_table`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: non_existent_table
      """
    And STDOUT should be empty

    When I run `fin --require=table_names.php get_table_names fin_posts non_existent_table`
    Then STDOUT should be:
      """
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names fin_posts non_existent_table 'fin_?ption*'`
    Then STDOUT should be:
      """
      fin_options
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names fin_posts non_existent_table 'fin_*ption?'`
    Then STDOUT should be:
      """
      fin_options
      fin_posts
      """

    When I run `fin --require=table_names.php get_table_names fin_posts non_existent_table 'fin_*ption?' --network`
    Then STDOUT should be:
      """
      fin_2_options
      fin_options
      fin_posts
      """

  @less-than-fin-6.1
  Scenario: Get FIN table names for multisite install (site_categories only)
    Given a FIN multisite install
    And I run `fin db query "CREATE TABLE xx_fin_posts ( id int );"`
    And I run `fin db query "CREATE TABLE xx_fin_2_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_xx_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_2_xx_posts ( id int );"`
    And I run `fin db query "CREATE TABLE fin_posts_xx ( id int );"`
    And I run `fin db query "CREATE TABLE fin_2_posts_xx ( id int );"`
    And I run `fin db query "CREATE TABLE fin_categories ( id int );"`
    And I run `fin db query "CREATE TABLE fin_sitecategories ( id int );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test FIN get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'fin_*_options' or 'fin_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite installation. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $findb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $findb. Overrides --all-tables-with-prefix.
       */
      function test_fin_get_table_names( $args, $assoc_args ) {
        if ( $tables = FIN_CLI\Utils\fin_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      FIN_CLI::add_command( 'get_table_names', 'test_fin_get_table_names' );
      """
    And an enable_sitecategories.php file:
      """
      <?php
      FIN_CLI::add_hook( 'after_fin_load', function () {
        add_filter( 'global_terms_enabled', '__return_true' );
      } );
      """

    When I run `fin --require=table_names.php --require=enable_sitecategories.php get_table_names`
    # Leave out fin_blog_versions as it was never used and is removed with FIN 5.3+.
    # Leave out fin_blogmeta for old FIN compat.
    Then STDOUT should contain:
      """
      fin_blogs
      fin_commentmeta
      fin_comments
      fin_links
      fin_options
      fin_postmeta
      fin_posts
      fin_registration_log
      fin_signups
      fin_site
      fin_sitecategories
      fin_sitemeta
      fin_term_relationships
      fin_term_taxonomy
      """
	# Leave out fin_termmeta for old FIN compat.
    And STDOUT should contain:
      """
      fin_terms
      fin_usermeta
      fin_users
      """
