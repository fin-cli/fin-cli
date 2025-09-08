Feature: Have a config file

  Scenario: No config file
    Given a FP installation

    When I run `fp --info`
    Then STDOUT should not contain:
      """
      fp-cli.yml
      """

    When I run `fp core is-installed` from 'fp-content'
    Then STDOUT should be empty

  Scenario: Config file in FP Root
    Given a FP installation
    And a sample.php file:
      """
      <?php
      """
    And a fp-cli.yml file:
      """
      require: sample.php
      """

    When I run `fp --info`
    Then STDOUT should contain:
      """
      fp-cli.yml
      """

    When I run `fp core is-installed`
    Then STDOUT should be empty

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `fp` from 'fp-content'
    Then STDOUT should contain:
      """
      fp <command>
      """

  Scenario: FP in a subdirectory
    Given a FP installation in 'foo'
    And a fp-cli.yml file:
      """
      path: foo
      """

    When I run `fp --info`
    Then STDOUT should contain:
      """
      fp-cli.yml
      """

    When I run `fp core is-installed`
    Then STDOUT should be empty

    When I run `fp core is-installed` from 'foo/fp-content'
    Then STDOUT should be empty

    When I run `mkdir -p other/subdir`
    And I run `fp core is-installed` from 'other/subdir'
    Then STDOUT should be empty

  Scenario: FP in a subdirectory (autodetected)
    Given a FP installation in 'foo'

    And an index.php file:
      """
      require('./foo/fp-blog-header.php');
      """
    When I run `fp core is-installed`
    Then STDOUT should be empty

    Given an index.php file:
      """
      require dirname(__FILE__) . '/foo/fp-blog-header.php';
      """
    When I run `fp core is-installed`
    Then STDOUT should be empty

    When I run `mkdir -p other/subdir`
    And I run `echo '<?php // Silence is golden' > other/subdir/index.php`
    And I run `fp core is-installed` from 'other/subdir'
    Then STDOUT should be empty

  Scenario: Nested installations
    Given a FP installation
    And a FP installation in 'foo'
    And a fp-cli.yml file:
      """
      """

    When I run `fp --info` from 'foo'
    Then STDOUT should not contain:
      """
      fp-cli.yml
      """

  Scenario: Disabled commands
    Given a FP installation
    And a config.yml file:
      """
      disabled_commands:
        - eval-file
        - core multisite-convert
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `FP_CLI_CONFIG_PATH=config.yml fp`
    Then STDOUT should not contain:
      """
      eval-file
      """

    When I try `FP_CLI_CONFIG_PATH=config.yml fp help eval-file`
    Then STDERR should contain:
      """
      Error: The 'eval-file' command has been disabled from the config file.
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `FP_CLI_CONFIG_PATH=config.yml fp core`
    Then STDOUT should not contain:
      """
      or: fp core multisite-convert
      """

    # TODO: Throwing deprecations with PHP 8.1+ and FP < 5.9
    When I try `FP_CLI_CONFIG_PATH=config.yml fp help core`
    Then STDOUT should not contain:
      """
      multisite-convert
      """

    When I try `FP_CLI_CONFIG_PATH=config.yml fp core multisite-convert`
    Then STDERR should contain:
      """
      command has been disabled
      """

    When I try `FP_CLI_CONFIG_PATH=config.yml fp help core multisite-convert`
    Then STDERR should contain:
      """
      Error: The 'core multisite-convert' command has been disabled from the config file.
      """

  Scenario: 'core config' parameters
    Given an empty directory
    And FP files
    And a fp-cli.yml file:
      """
      core config:
        dbname: finpress
        dbuser: root
        extra-php: |
          define( 'FP_DEBUG', true );
          define( 'FP_POST_REVISIONS', 50 );
      """

    When I run `fp core config --skip-check`
    And I run `grep FP_POST_REVISIONS fp-config.php`
    Then STDOUT should not be empty

  Scenario: Persist positional parameters when defined in a config
    Given a FP installation
    And a fp-cli.yml file:
      """
      user create:
        - examplejoe
        - joe@example.com
        user_pass: joe
        role: administrator
      """

    When I run `fp user create`
    Then STDOUT should not be empty

    When I run `fp user get examplejoe --field=roles`
    Then STDOUT should contain:
      """
      administrator
      """

    When I try `fp user create examplejane`
    Then STDERR should be:
      """
      Error: Sorry, that email address is already used!
      """

    When I run `fp user create examplejane jane@example.com`
    Then STDOUT should not be empty

    When I run `fp user get examplejane --field=roles`
    Then STDOUT should contain:
      """
      administrator
      """

  Scenario: Command-specific configs
    Given a FP installation
    And a fp-cli.yml file:
      """
      eval:
        foo: bar
      post list:
        format: count
      """

    # Arbitrary values should be passed, without warnings
    When I run `fp eval 'echo json_encode( $assoc_args );'`
    Then STDOUT should be JSON containing:
      """
      {"foo": "bar"}
      """

    # CLI args should trump config values
    When I run `fp post list`
    Then STDOUT should be a number
    When I run `fp post list --format=json`
    Then STDOUT should not be a number

  Scenario: Required files should not be loaded twice
    Given an empty directory
    And a custom-file.php file:
      """
      <?php
      define( 'FOOBUG', 'BAR' );
      """
    And a test-dir/config.yml file:
      """
      require:
        - ../custom-file.php
      """
    And a fp-cli.yml file:
      """
      require:
        - custom-file.php
      """

    When I run `FP_CLI_CONFIG_PATH=test-dir/config.yml fp help`
    Then STDERR should be empty

  Scenario: Load FinPress with `--debug`
    Given a FP installation

    When I try `fp option get home --debug`
    Then STDERR should contain:
      """
      No readable global config found
      """
    And STDERR should contain:
      """
      No project config found
      """
    And STDERR should contain:
      """
      Begin FinPress load
      """
    And STDERR should contain:
      """
      fp-config.php path:
      """
    And STDERR should contain:
      """
      Loaded FinPress
      """
    And STDERR should contain:
      """
      Running command: option get
      """
    And the return code should be 0

    When I try `fp option get home --debug=bootstrap`
    Then STDERR should contain:
      """
      No readable global config found
      """
    And STDERR should contain:
      """
      No project config found
      """
    And STDERR should contain:
      """
      Begin FinPress load
      """
    And STDERR should contain:
      """
      fp-config.php path:
      """
    And STDERR should contain:
      """
      Loaded FinPress
      """
    And STDERR should contain:
      """
      Running command: option get
      """
    And the return code should be 0

    When I try `fp option get home --debug=foo`
    Then STDERR should not contain:
      """
      No readable global config found
      """
    And STDERR should not contain:
      """
      No project config found
      """
    And STDERR should not contain:
      """
      Begin FinPress load
      """
    And STDERR should not contain:
      """
      fp-config.php path:
      """
    And STDERR should not contain:
      """
      Loaded FinPress
      """
    And STDERR should not contain:
      """
      Running command: option get
      """
    And the return code should be 0

  Scenario: Missing required files should not fatal FP-CLI
    Given an empty directory
    And a fp-cli.yml file:
      """
      require:
        - missing-file.php
      """

    When I try `fp help`
    Then STDERR should contain:
      """
      Error: Required file 'missing-file.php' doesn't exist (from project's fp-cli.yml).
      """

    When I run `fp cli info`
    Then STDOUT should not be empty

    When I run `fp --info`
    Then STDOUT should not be empty

  Scenario: Missing required file in global config
    Given an empty directory
    And a config.yml file:
      """
      require:
        - /foo/baz.php
      """

    When I try `FP_CLI_CONFIG_PATH=config.yml fp help`
    Then STDERR should contain:
      """
      Error: Required file 'baz.php' doesn't exist (from global config.yml).
      """

  Scenario: Missing required file as runtime argument
    Given an empty directory

    When I try `fp help --require=foo.php`
    Then STDERR should contain:
      """
      Error: Required file 'foo.php' doesn't exist (from runtime argument).
      """

  Scenario: Config inheritance from project to global
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      $command = function( $_, $assoc_args ) {
         echo json_encode( $assoc_args );
      };
      FP_CLI::add_command( 'test-cmd', $command, array( 'when' => 'before_fp_load' ) );
      """
    And a config.yml file:
      """
      test-cmd:
        foo: bar
        apple: banana
      apple: banana
      """
    And a fp-cli.yml file:
      """
      _:
        merge: true
      test-cmd:
        bar: burrito
        apple: apple
      apple: apple
      """

    When I run `fp --require=test-cmd.php test-cmd`
    Then STDOUT should be JSON containing:
      """
      {"bar":"burrito","apple":"apple"}
      """
    When I run `FP_CLI_CONFIG_PATH=config.yml fp --require=test-cmd.php test-cmd`
    Then STDOUT should be JSON containing:
      """
      {"foo":"bar","apple":"apple","bar":"burrito"}
      """

    Given a fp-cli.yml file:
      """
      _:
        merge: false
      test-cmd:
        bar: burrito
        apple: apple
      apple: apple
      """
    When I run `FP_CLI_CONFIG_PATH=config.yml fp --require=test-cmd.php test-cmd`
    Then STDOUT should be JSON containing:
      """
      {"bar":"burrito","apple":"apple"}
      """

  Scenario: Config inheritance from local to project
    Given an empty directory
    And a test-cmd.php file:
      """
      <?php
      $command = function( $_, $assoc_args ) {
         echo json_encode( $assoc_args );
      };
      FP_CLI::add_command( 'test-cmd', $command, array( 'when' => 'before_fp_load' ) );
      """
    And a fp-cli.yml file:
      """
      test-cmd:
        foo: bar
        apple: banana
      apple: banana
      """

    When I run `fp --require=test-cmd.php test-cmd`
    Then STDOUT should be JSON containing:
      """
      {"foo":"bar","apple":"banana"}
      """

    Given a fp-cli.local.yml file:
      """
      _:
        inherit: fp-cli.yml
        merge: true
      test-cmd:
        bar: burrito
        apple: apple
      apple: apple
      """

    When I run `fp --require=test-cmd.php test-cmd`
    Then STDOUT should be JSON containing:
      """
      {"foo":"bar","apple":"apple","bar":"burrito"}
      """

    Given a fp-cli.local.yml file:
      """
      test-cmd:
        bar: burrito
        apple: apple
      apple: apple
      """

    When I run `fp --require=test-cmd.php test-cmd`
    Then STDOUT should be JSON containing:
      """
      {"bar":"burrito","apple":"apple"}
      """

  Scenario: Config inheritance in nested folders
    Given an empty directory
    And a fp-cli.local.yml file:
      """
      @dev:
        ssh: vagrant@example.test/srv/www/example.com/current
        path: web/fp
      """
    And a site/fp-cli.yml file:
      """
      _:
        inherit: ../fp-cli.local.yml
      @otherdev:
        ssh: vagrant@otherexample.test/srv/www/otherexample.com/current
      """
    And a site/public/index.php file:
      """
      <?php
      """

    When I run `fp cli alias list`
    Then STDOUT should contain:
      """
      @all: Run command against every registered alias.
      @dev:
        path: web/fp
        ssh: vagrant@example.test/srv/www/example.com/current
      """

    When I run `cd site && fp cli alias list`
    Then STDOUT should contain:
      """
      @all: Run command against every registered alias.
      @dev:
        path: web/fp
        ssh: vagrant@example.test/srv/www/example.com/current
      @otherdev:
        ssh: vagrant@otherexample.test/srv/www/otherexample.com/current
      """

    When I run `cd site/public && fp cli alias list`
    Then STDOUT should contain:
      """
      @all: Run command against every registered alias.
      @dev:
        path: web/fp
        ssh: vagrant@example.test/srv/www/example.com/current
      @otherdev:
        ssh: vagrant@otherexample.test/srv/www/otherexample.com/current
      """

  @require-fp-3.9
  Scenario: FinPress installation with local dev DOMAIN_CURRENT_SITE
    Given a FP multisite installation
    And a local-dev.php file:
      """
      <?php
      define( 'DOMAIN_CURRENT_SITE', 'example.dev' );
      """
    And a fp-config.php file:
      """
      <?php
      if ( file_exists( __DIR__ . '/local-dev.php' ) ) {
        require_once __DIR__ . '/local-dev.php';
      }

      // ** MySQL settings ** //
      /** The name of the database for FinPress */
      define('DB_NAME', '{DB_NAME}');

      /** MySQL database username */
      define('DB_USER', '{DB_USER}');

      /** MySQL database password */
      define('DB_PASSWORD', '{DB_PASSWORD}');

      /** MySQL hostname */
      define('DB_HOST', '{DB_HOST}');

      /** Database Charset to use in creating database tables. */
      define('DB_CHARSET', 'utf8');

      /** The Database Collate type. Don't change this if in doubt. */
      define('DB_COLLATE', '');

      $table_prefix = 'fp_';

      define( 'FP_ALLOW_MULTISITE', true );
      define('MULTISITE', true);
      define('SUBDOMAIN_INSTALL', false);
      $base = '/';
      if ( ! defined( 'DOMAIN_CURRENT_SITE' ) ) {
        define('DOMAIN_CURRENT_SITE', 'example.com');
      }
      define('PATH_CURRENT_SITE', '/');
      define('SITE_ID_CURRENT_SITE', 1);
      define('BLOG_ID_CURRENT_SITE', 1);

      /* That's all, stop editing! Happy publishing. */

      /** Absolute path to the FinPress directory. */
      if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');

      /** Sets up FinPress vars and included files. */
      require_once(ABSPATH . 'fp-settings.php');
      """

    When I try `fp option get home`
    Then STDERR should be:
      """
      Error: Site 'example.dev/' not found. Verify DOMAIN_CURRENT_SITE matches an existing site or use `--url=<url>` to override.
      """

    When I run `fp option get home --url=example.com`
    Then STDOUT should be:
      """
      https://example.com
      """

  Scenario: BOM found in fp-config.php file
    Given a FP installation
    And a fp-config.php file:
      """
      <?php
      define('DB_NAME', '{DB_NAME}');
      define('DB_USER', '{DB_USER}');
      define('DB_PASSWORD', '{DB_PASSWORD}');
      define('DB_HOST', '{DB_HOST}');
      define('DB_CHARSET', 'utf8');
      define('DB_COLLATE', '');
      $table_prefix = 'fp_';

      /* That's all, stop editing! Happy publishing. */

      /** Sets up FinPress vars and included files. */
      require_once(ABSPATH . 'fp-settings.php');
      """
    And I run `awk 'BEGIN {print "\xef\xbb\xbf"} {print}' fp-config.php > fp-config.php`

    When I try `fp core is-installed`
    Then STDERR should not contain:
      """
      PHP Parse error: syntax error, unexpected '?'
      """
    And STDERR should contain:
      """
      Warning: UTF-8 byte-order mark (BOM) detected in fp-config.php file, stripping it for parsing.
      """

  Scenario: Strange fp-config.php file with missing fp-settings.php call
    Given a FP installation
    And a fp-config.php file:
      """
      <?php
      define('DB_NAME', '{DB_NAME}');
      define('DB_USER', '{DB_USER}');
      define('DB_PASSWORD', '{DB_PASSWORD}');
      define('DB_HOST', '{DB_HOST}');
      define('DB_CHARSET', 'utf8');
      define('DB_COLLATE', '');
      $table_prefix = 'fp_';

      /* That's all, stop editing! Happy publishing. */
      """

    When I try `fp core is-installed`
    Then STDERR should contain:
      """
      Error: Strange fp-config.php file: fp-settings.php is not loaded directly.
      """

  Scenario: Strange fp-config.php file with multi-line fp-settings.php call
    Given a FP installation
    And a fp-config.php file:
      """
      <?php
      if ( 1 === 1 ) {
        require_once ABSPATH . 'some-other-file.php';
      }

      define('DB_NAME', '{DB_NAME}');
      define('DB_USER', '{DB_USER}');
      define('DB_PASSWORD', '{DB_PASSWORD}');
      define('DB_HOST', '{DB_HOST}');
      define('DB_CHARSET', 'utf8');
      define('DB_COLLATE', '');
      $table_prefix = 'fp_';

      /* That's all, stop editing! Happy publishing. */

      /** Sets up FinPress vars and included files. */
      require_once
        ABSPATH . 'fp-settings.php'
      ;
      """

    When I try `fp core is-installed`
    Then STDERR should not contain:
      """
      Error: Strange fp-config.php file: fp-settings.php is not loaded directly.
      """

  Scenario: Code after fp-settings.php call should be loaded
    Given a FP installation
    And a fp-config.php file:
      """
      <?php
      if ( 1 === 1 ) {
        require_once ABSPATH . 'some-other-file.php';
      }

      define('DB_NAME', '{DB_NAME}');
      define('DB_USER', '{DB_USER}');
      define('DB_PASSWORD', '{DB_PASSWORD}');
      define('DB_HOST', '{DB_HOST}');
      define('DB_CHARSET', 'utf8');
      define('DB_COLLATE', '');
      $table_prefix = 'fp_';

      /* That's all, stop editing! Happy publishing. */

      /** Sets up FinPress vars and included files. */
      require_once
        ABSPATH . 'fp-settings.php'
      ;

      require_once ABSPATH . 'includes-file.php';
      """
    And a includes-file.php file:
      """
      <?php
      define( 'MY_CONSTANT', true );
      """
    And a some-other-file.php file:
      """
      <?php
      define( 'MY_OTHER_CONSTANT', true );
      """

    When I try `fp core is-installed`
    Then STDERR should not contain:
      """
      Error: Strange fp-config.php file: fp-settings.php is not loaded directly.
      """

    When I run `fp eval 'var_export( defined("MY_CONSTANT") );'`
    Then STDOUT should be:
      """
      true
      """

    When I run `fp eval 'var_export( defined("MY_OTHER_CONSTANT") );'`
    Then STDOUT should be:
      """
      true
      """

  Scenario: Be able to create a new global config file (including any new parent folders) when one doesn't exist
    # Delete this folder or else a rerun of the test will fail since the folder/file now exists
    When I run `[ -n "$HOME" ] && rm -rf "$HOME/doesnotexist"`
    And I try `FP_CLI_CONFIG_PATH=$HOME/doesnotexist/fp-cli.yml fp cli alias add 1 --debug`
    Then STDERR should match #Default global config does not exist, creating one in.+/doesnotexist/fp-cli.yml#
