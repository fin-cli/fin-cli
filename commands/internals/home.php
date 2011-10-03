<?php

// Add the command to the wp-cli
WP_CLI::addCommand('home', 'HomeCommand');

/**
 * Implement home command
 *
 * @package wp-cli
 * @subpackage commands/internals
 * @author Andreas Creten
 */
class HomeCommand extends WP_CLI_Command {

	public static function get_description() {
		return 'Open the wp-cli project on Github.';
	}

	/**
	 * Overwrite the dispatch method to have a command without sub-commands.
     *
     * @param array $args
	 * @param array $assoc_args
	 */
	protected function dispatch( $args, $assoc_args ) {
		if(empty($args)) {
			// The url for the wp-cli repository
			$repository_url = 'http://github.com/andreascreten/wp-cli';

			// Open the wp-cli page in the browser
			if(exec('which x-www-browser')) {
				system('x-www-browser '.$repository_url);
			}
			elseif(exec('which open')) {
				system('open '.$repository_url);
			}
			else {
				WP_CLI::error('No command found to open the homepage in the browser. Please open it manually: '.$repository_url);
				return;
			}

			WP_CLI::success('The wp-cli homepage should be opening in your browser.');
		}
		else {
			// Call the parent constructor
			parent::dispatch( $args, $assoc_args );
		}
	}

	/**
	 * Help function for this command.
	 *
	 * @param string $args
	 * @return void
	 */
	public function help($args = array()) {
		WP_CLI::line('This command has no arguments; when called it will open the wp-cli homepage in your browser.');
		WP_CLI::line();
		WP_CLI::line('Example usage:');
		WP_CLI::line('    wp home');
	}
}
