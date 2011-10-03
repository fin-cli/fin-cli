<?php

// Add the command to the wp-cli
WP_CLI::addCommand('core', 'CoreCommand');

/**
 * Implement core command
 *
 * @package wp-cli
 * @subpackage commands/internals
 * @author Andreas Creten
 */
class CoreCommand extends WP_CLI_Command {

	public static function get_description() {
		return 'Update the WordPress core.';
	}

	/**
	 * Update the WordPress core
	 *
	 * @param string $args
	 * @return void
	 */
	function update($args) {
		WP_CLI::line('Updating the WordPress core.');

		if(!class_exists('Core_Upgrader')) {
			require_once(ABSPATH.'wp-admin/includes/class-wp-upgrader.php');
		}
		ob_start();
		$upgrader = new Core_Upgrader(new CLI_Upgrader_Skin);
		$result = $upgrader->upgrade($current);
		$feedback = ob_get_clean();

		// Borrowed verbatim from wp-admin/update-core.php
		if(is_wp_error($result) ) {
			if('up_to_date' != $result->get_error_code()) {
				WP_CLI::error('Installation failed ('.WP_CLI::errorToString($result).').');
			}
			else {
				WP_CLI::success(WP_CLI::errorToString($result));
			}
		}
		else {
			WP_CLI::success('WordPress upgraded successfully.');
		}
	}
}
