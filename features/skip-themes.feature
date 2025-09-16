Feature: Skipping themes

  @require-fin-4.7
  Scenario: Skipping themes via global flag
    Given a FIN installation
    # Themes will already be installed on FIN core trunk.
    And I try `fin theme install twentysixteen`
    And I try `fin theme install twentyseventeen --activate`

    When I run `fin eval 'var_export( function_exists( "twentyseventeen_body_classes" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty

    # The specified theme should be skipped
    When I run `fin --skip-themes=twentyseventeen eval 'var_export( function_exists( "twentyseventeen_body_classes" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    # All themes should be skipped
    When I run `fin --skip-themes eval 'var_export( function_exists( "twentyseventeen_body_classes" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    # Skip another theme
    When I run `fin --skip-themes=twentysixteen eval 'var_export( function_exists( "twentyseventeen_body_classes" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty

    # The specified theme should still show up as an active theme
    When I run `fin --skip-themes theme status twentyseventeen`
    Then STDOUT should contain:
      """
      Active
      """
    And STDERR should be empty

    # Skip several themes
    When I run `fin --skip-themes=twentysixteen,twentyseventeen eval 'var_export( function_exists( "twentyseventeen_body_classes" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

  Scenario: Skip parent and child themes
    Given a FIN installation
    And I run `fin theme install moina moina-blog`

    When I run `fin theme activate moina`
    And I run `fin eval 'var_export( function_exists( "moina_setup" ) );'`
    Then STDOUT should be:
      """
      true
      """

    When I run `fin --skip-themes=moina eval 'var_export( function_exists( "moina_setup" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `fin theme activate moina-blog`
    And I run `fin eval 'var_export( function_exists( "moina_setup" ) );'`
    Then STDOUT should be:
      """
      true
      """

    When I run `fin eval 'var_export( function_exists( "moina_blog_scripts" ) );'`
    Then STDOUT should be:
      """
      true
      """

    When I run `fin --skip-themes=moina-blog eval 'var_export( function_exists( "moina_setup" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `fin --skip-themes=moina-blog eval 'var_export( function_exists( "moina_blog_scripts" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `fin --skip-themes=moina-blog eval 'echo get_template_directory();'`
    Then STDOUT should contain:
      """
      fin-content/themes/moina
      """
    And STDERR should be empty

    When I run `fin --skip-themes=moina-blog eval 'echo get_stylesheet_directory();'`
    Then STDOUT should contain:
      """
      fin-content/themes/moina-blog
      """
    And STDERR should be empty

  Scenario: Skipping multiple themes via config file
    Given a FIN installation
    And a fin-cli.yml file:
      """
      skip-themes:
        - classic
        - default
      """
    And I run `fin theme install classic --activate`
    And I run `fin theme install default`

    # The classic theme should show up as an active theme
    When I run `fin theme status`
    Then STDOUT should contain:
      """
      A classic
      """
    And STDERR should be empty

    # The default theme should show up as an installed theme
    When I run `fin theme status`
    Then STDOUT should contain:
      """
      I default
      """
    And STDERR should be empty

    And I run `fin theme activate default`

    # The default theme should be skipped
    When I run `fin eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

  @require-fin-6.1
  Scenario: Skip a theme using block patterns
    Given a FIN installation
    And I run `fin theme install blockline --activate`

    When I run `fin eval 'var_dump( function_exists( "blockline_support" ) );'`
    Then STDOUT should be:
      """
      bool(true)
      """

    When I run `fin --skip-themes=blockline eval 'var_dump( function_exists( "blockline_support" ) );'`
    Then STDOUT should be:
      """
      bool(false)
      """

  @require-fin-6.1 @require-php-7.2
  Scenario: Skip a theme using block patterns with Gutenberg active
    Given a FIN installation
    And I run `fin plugin install gutenberg --activate`
    And I run `fin theme install blockline --activate`

    When I run `fin eval 'var_dump( function_exists( "blockline_support" ) );'`
    Then STDOUT should be:
      """
      bool(true)
      """

    When I run `fin --skip-themes=blockline eval 'var_dump( function_exists( "blockline_support" ) );'`
    Then STDOUT should be:
      """
      bool(false)
      """

  @require-fin-5.2
  Scenario: Display a custom error message when themes/functions.php causes the fatal
    Given a FIN installation
    And a fin-content/themes/functions.php file:
      """
      <?php
      fin_cli_function_doesnt_exist_5240();
      """

    When I try `fin --skip-themes plugin list`
    Then STDERR should contain:
      """
      Error: An unexpected functions.php file in the themes directory may have caused this internal server error.
      """
