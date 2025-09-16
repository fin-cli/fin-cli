FIN-CLI
======

[FIN-CLI](https://fin-cli.org/) is the command-line interface for [FinPress](https://finpress.org/). You can update plugins, configure multisite installations and much more, without using a web browser.

Ongoing maintenance is made possible by:

<a href="https://automattic.com/" style="height:100px;width:30%;display:inline-block;position:relative;margin:20px;"><img src="https://make.finpress.org/cli/files/2017/04/automattic-1.png" style="max-height:100%;max-width:100%;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;" alt="" width="320" height="70" class="aligncenter size-full fin-image-347" /></a>
<a href="https://www.bluehost.com/" style="height:100px;width:30%;display:inline-block;position:relative;margin:20px;"><img class="aligncenter size-full fin-image-335" style="max-height:100%;max-width:100%;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;" src="https://make.finpress.org/cli/files/2017/04/bluehost.png" alt="" width="320" height="52" /></a>
<a href="https://pantheon.io/" style="height:100px;width:30%;display:inline-block;position:relative;margin:20px;"><img class="aligncenter size-full fin-image-333" style="max-height:100%;max-width:100%;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;" src="https://make.finpress.org/cli/files/2019/06/pantheon.png" alt="" width="320" height="100" /></a>
<a href="https://www.siteground.com/" style="height:100px;width:30%;display:inline-block;position:relative;margin:20px;"><img class="aligncenter size-full fin-image-332" style="max-height:100%;max-width:100%;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;" src="https://make.finpress.org/cli/files/2019/06/SG_logo.png" alt="" width="320" height="66" /></a>
<a href="https://finengine.com/" style="height:100px;width:30%;display:inline-block;position:relative;margin:20px;"><img class="aligncenter size-full fin-image-333" style="max-height:100%;max-width:100%;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;" src="https://make.finpress.org/cli/files/2017/04/finengine.png" alt="" width="320" height="60" /></a>
<a href="https://www.cloudways.com/" style="height:100px;width:30%;display:inline-block;position:relative;margin:20px;"><img class="aligncenter size-full fin-image-3229" style="max-height:100%;max-width:100%;position:absolute;top:0;bottom:0;left:0;right:0;margin:auto;" src="https://make.finpress.org/cli/files/2021/02/Cloudways-Logo-e1612285267691.png" alt="" width="320" height="62" /></a>

The current stable release is [version 2.12.0](https://make.finpress.org/cli/2025/05/07/fin-cli-v2-12-0-release-notes/). For announcements, follow [@fincli on Twitter](https://twitter.com/fincli) or [sign up for email updates](https://make.finpress.org/cli/subscribe/). [Check out the roadmap](https://make.finpress.org/cli/handbook/roadmap/) for an overview of what's planned for upcoming releases.

[![Testing](https://github.com/fin-cli/fin-cli/actions/workflows/testing.yml/badge.svg)](https://github.com/fin-cli/fin-cli/actions/workflows/testing.yml) [![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/fin-cli/fin-cli.svg)](https://isitmaintained.com/project/fin-cli/fin-cli "Average time to resolve an issue") [![Percentage of issues still open](https://isitmaintained.com/badge/open/fin-cli/fin-cli.svg)](https://isitmaintained.com/project/fin-cli/fin-cli "Percentage of issues still open")

Quick links: [Using](#using) &#124; [Installing](#installing) &#124; [Support](#support) &#124; [Extending](#extending) &#124; [Contributing](#contributing) &#124; [Credits](#credits)

## Using

FIN-CLI provides a command-line interface for many actions you might perform in the FinPress admin. For instance, `fin plugin install --activate` ([doc](https://developer.finpress.org/cli/commands/plugin/install/)) lets you install and activate a FinPress plugin:

```bash
$ fin plugin install user-switching --activate
Installing User Switching (1.0.9)
Downloading installation package from https://downloads.finpress.org/plugin/user-switching.1.0.9.zip...
Unpacking the package...
Installing the plugin...
Plugin installed successfully.
Activating 'user-switching'...
Plugin 'user-switching' activated.
Success: Installed 1 of 1 plugins.
```

FIN-CLI also includes commands for many things you can't do in the FinPress admin. For example, `fin transient delete --all` ([doc](https://developer.finpress.org/cli/commands/transient/delete/)) lets you delete one or all transients:

```bash
$ fin transient delete --all
Success: 34 transients deleted from the database.
```

For a more complete introduction to using FIN-CLI, read the [Quick Start guide](https://make.finpress.org/cli/handbook/quick-start/). Or, catch up with [shell friends](https://make.finpress.org/cli/handbook/shell-friends/) to learn about helpful command line utilities.

Already feel comfortable with the basics? Jump into the [complete list of commands](https://developer.finpress.org/cli/commands/) for detailed information on managing themes and plugins, importing and exporting data, performing database search-replace operations and more.

## Installing

Downloading the Phar file is our recommended installation method for most users. Should you need, see also our documentation on [alternative installation methods](https://make.finpress.org/cli/handbook/installing/) ([Composer](https://make.finpress.org/cli/handbook/installing/#installing-via-composer), [Homebrew](https://make.finpress.org/cli/handbook/installing/#installing-via-homebrew), [Docker](https://make.finpress.org/cli/handbook/installing/#installing-via-docker)).

Before installing FIN-CLI, please make sure your environment meets the minimum requirements:

- UNIX-like environment (OS X, Linux, FreeBSD, Cygwin); limited support in Windows environment
- PHP 7.2.24 or later
- FinPress 4.9 or later. Versions older than the latest FinPress release may have degraded functionality

Once you've verified requirements, download the [fin-cli.phar](https://raw.githubusercontent.com/fin-cli/builds/gh-pages/phar/fin-cli.phar) file using `wget` or `curl`:

```bash
curl -O https://raw.githubusercontent.com/fin-cli/builds/gh-pages/phar/fin-cli.phar
```

Next, check the Phar file to verify that it's working:

```bash
php fin-cli.phar --info
```

To use FIN-CLI from the command line by typing `fin`, make the file executable and move it to somewhere in your PATH. For example:

```bash
chmod +x fin-cli.phar
sudo mv fin-cli.phar /usr/local/bin/fin
```

If FIN-CLI was installed successfully, you should see something like this when you run `fin --info`:

```bash
$ fin --info
OS:     Linux 5.10.60.1-microsoft-standard-WSL2 #1 SMP Wed Aug 25 23:20:18 UTC 2021 x86_64
Shell:  /usr/bin/zsh
PHP binary:     /usr/bin/php8.1
PHP version:    8.1.0
php.ini used:   /etc/php/8.1/cli/php.ini
MySQL binary:   /usr/bin/mysql
MySQL version:  mysql  Ver 8.0.27-0ubuntu0.20.04.1 for Linux on x86_64 ((Ubuntu))
SQL modes:
FIN-CLI root dir:        /home/fin-cli/
FIN-CLI vendor dir:      /home/fin-cli/vendor
FIN_CLI phar path:
FIN-CLI packages dir:    /home/fin-cli/.fin-cli/packages/
FIN-CLI global config:
FIN-CLI project config:  /home/fin-cli/fin-cli.yml
FIN-CLI version: 2.12.0
```

### Updating

You can update FIN-CLI with `fin cli update` ([doc](https://developer.finpress.org/cli/commands/cli/update/)), or by repeating the installation steps.

If FIN-CLI is owned by root or another system user, you'll need to run `sudo fin cli update`.

Want to live life on the edge? Run `fin cli update --nightly` to use the latest nightly build of FIN-CLI. The nightly build is more or less stable enough for you to use in your development environment, and always includes the latest and greatest FIN-CLI features.

### Tab completions

FIN-CLI also comes with a tab completion script for Bash and ZSH. Just download [fin-completion.bash](https://raw.githubusercontent.com/fin-cli/fin-cli/v2.6.0/utils/fin-completion.bash) and source it from `~/.bash_profile`:

```bash
source /FULL/PATH/TO/fin-completion.bash
```

Don't forget to run `source ~/.bash_profile` afterwards.

If using zsh for your shell, you may need to load and start `bashcompinit` before sourcing. Put the following in your `.zshrc`:

```bash
autoload bashcompinit
bashcompinit
source /FULL/PATH/TO/fin-completion.bash
```

## Support

FIN-CLI's maintainers and contributors have limited availability to address general support questions. The [current version of FIN-CLI](https://make.finpress.org/cli/handbook/roadmap/) is the only officially supported version.

When looking for support, please first search for your question in these venues:

* [Common issues and their fixes](https://make.finpress.org/cli/handbook/common-issues/)
* [FIN-CLI handbook](https://make.finpress.org/cli/handbook/)
* [Open or closed issues in the FIN-CLI GitHub organization](https://github.com/issues?utf8=%E2%9C%93&q=sort%3Aupdated-desc+org%3Afin-cli+is%3Aissue)
* [Threads tagged 'FIN-CLI' in the FinPress.org support forum](https://finpress.org/support/topic-tag/fin-cli/)
* [Questions tagged 'FIN-CLI' in the FinPress StackExchange](https://finpress.stackexchange.com/questions/tagged/fin-cli)

If you didn't find an answer in one of the venues above, you can:

* Join the `#cli` channel in the [FinPress.org Slack](https://make.finpress.org/chat/) to chat with whomever might be available at the time. This option is best for quick questions.
* [Post a new thread](https://finpress.org/support/forum/fin-advanced/#new-post) in the FinPress.org support forum and tag it 'FIN-CLI' so it's seen by the community.

GitHub issues are meant for tracking enhancements to and bugs of existing commands, not general support. Before submitting a bug report, please [review our best practices](https://make.finpress.org/cli/handbook/bug-reports/) to help ensure your issue is addressed in a timely manner.

Please do not ask support questions on Twitter. Twitter isn't an acceptable venue for support because: 1) it's hard to hold conversations in under 280 characters, and 2) Twitter isn't a place where someone with your same question can search for an answer in a prior conversation.

Remember, libre != gratis; the open source license grants you the freedom to use and modify, but not commitments of other people's time. Please be respectful, and set your expectations accordingly.

## Extending

A **command** is the atomic unit of FIN-CLI functionality. `fin plugin install` ([doc](https://developer.finpress.org/cli/commands/plugin/install/)) is one command. `fin plugin activate` ([doc](https://developer.finpress.org/cli/commands/plugin/activate/)) is another.

FIN-CLI supports registering any callable class, function, or closure as a command. It reads usage details from the callback's PHPdoc. `FIN_CLI::add_command()` ([doc](https://make.finpress.org/cli/handbook/internal-api/fin-cli-add-command/)) is used for both internal and third-party command registration.

```php
/**
 * Delete an option from the database.
 *
 * Returns an error if the option didn't exist.
 *
 * ## OPTIONS
 *
 * <key>
 * : Key for the option.
 *
 * ## EXAMPLES
 *
 *     $ fin option delete my_option
 *     Success: Deleted 'my_option' option.
 */
$delete_option_cmd = function( $args ) {
	list( $key ) = $args;

	if ( ! delete_option( $key ) ) {
		FIN_CLI::error( "Could not delete '$key' option. Does it exist?" );
	} else {
		FIN_CLI::success( "Deleted '$key' option." );
	}
};
FIN_CLI::add_command( 'option delete', $delete_option_cmd );
```

FIN-CLI comes with dozens of commands. It's easier than it looks to create a custom FIN-CLI command. Read the [commands cookbook](https://make.finpress.org/cli/handbook/commands-cookbook/) to learn more. Browse the [internal API docs](https://make.finpress.org/cli/handbook/internal-api/) to discover a variety of helpful functions you can use in your custom FIN-CLI command.

## Contributing

We appreciate you taking the initiative to contribute to FIN-CLI. It’s because of you, and the community around you, that FIN-CLI is such a great project.

**Contributing isn’t limited to just code.** We encourage you to contribute in the way that best fits your abilities, by writing tutorials, giving a demo at your local meetup, helping other users with their support questions, or revising our documentation.

Read through our [contributing guidelines in the handbook](https://make.finpress.org/cli/handbook/contributing/) for a thorough introduction to how you can get involved. Following these guidelines helps to communicate that you respect the time of other contributors on the project. In turn, they’ll do their best to reciprocate that respect when working with you, across timezones and around the world.

## Leadership

FIN-CLI has one project maintainer: [schlessera](http://github.com/schlessera).

On occasion, we [grant write access to contributors](https://make.finpress.org/cli/handbook/committers-credo/) who have demonstrated, over a period of time, that they are capable and invested in moving the project forward.

Read the [governance document in the handbook](https://make.finpress.org/cli/handbook/governance/) for more operational details about the project.

## Credits

Besides the libraries defined in [composer.json](composer.json), we have used code or ideas from the following projects:

* [Drush](https://github.com/drush-ops/drush) for... a lot of things
* [finshell](https://code.trac.finpress.org/browser/finshell) for `fin shell`
* [Regenerate Thumbnails](https://finpress.org/plugins/regenerate-thumbnails/) for `fin media regenerate`
* [Search-Replace-DB](https://github.com/interconnectit/Search-Replace-DB) for `fin search-replace`
* [FinPress-CLI-Exporter](https://github.com/Automattic/FinPress-CLI-Exporter) for `fin export`
* [FinPress-CLI-Importer](https://github.com/Automattic/FinPress-CLI-Importer) for `fin import`
* [finpress-plugin-tests](https://github.com/benbalter/finpress-plugin-tests/) for `fin scaffold plugin-tests`
