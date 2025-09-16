<?php

namespace FIN_CLI\Context;

use FIN_CLI;
use FIN_CLI\Context;
use FIN_Session_Tokens;

/**
 * Context which simulates the administrator backend.
 */
final class Admin implements Context {

	/**
	 * Process the context to set up the environment correctly.
	 *
	 * @param array $config Associative array of configuration data.
	 * @return void
	 */
	public function process( $config ) {
		if ( defined( 'FIN_ADMIN' ) ) {
			if ( ! FIN_ADMIN ) {
				FIN_CLI::warning( 'Could not fake admin request.' );
			}

			return;
		}

		FIN_CLI::debug( 'Faking an admin request', Context::DEBUG_GROUP );

		// Define `FIN_ADMIN` as being true. This causes the helper method
		// `is_admin()` to return true as well.
		define( 'FIN_ADMIN', true ); // phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedConstantFound

		// Set a fake entry point to ensure fin-includes/vars.php does not throw
		// notices/errors. This will be reflected in the global `$pagenow`
		// variable being set to 'fin-cli-fake-admin-file.php'.
		$_SERVER['PHP_SELF'] = '/fin-admin/fin-cli-fake-admin-file.php';

		// Bootstrap the FinPress administration area.
		FIN_CLI::add_fin_hook(
			'init',
			function () {
				$this->log_in_as_admin_user();
				$this->load_admin_environment();
			},
			defined( 'PHP_INT_MIN' ) ? PHP_INT_MIN : -2147483648, // phpcs:ignore PHPCompatibility.Constants.NewConstants.php_int_minFound
			0
		);
	}

	/**
	 * Ensure the current request is done under a logged-in administrator
	 * account.
	 *
	 * A lot of premium plugins/themes have their custom update routines locked
	 * behind an is_admin() call.
	 */
	private function log_in_as_admin_user(): void {
		// TODO: Add logic to find an administrator user.
		$admin_user_id = 1;

		fin_set_current_user( $admin_user_id );

		$expiration = time() + DAY_IN_SECONDS;

		$_COOKIE[ AUTH_COOKIE ] = fin_generate_auth_cookie(
			$admin_user_id,
			$expiration,
			'auth'
		);

		$_COOKIE[ SECURE_AUTH_COOKIE ] = fin_generate_auth_cookie(
			$admin_user_id,
			$expiration,
			'secure_auth'
		);
	}

	/**
	 * Load the admin environment.
	 *
	 * This tries to load `fin-admin/admin.php` while trying to avoid issues
	 * like re-loading the fin-config.php file (which redeclares constants).
	 *
	 * To make this work across FinPress versions, we use the actual file and
	 * modify it on-the-fly.
	 *
	 * @global string $hook_suffix
	 * @global string $pagenow
	 * @global int    $fin_db_version
	 * @global array  $_fin_submenu_nopriv
	 */
	private function load_admin_environment(): void {
		global $hook_suffix, $pagenow, $fin_db_version, $_fin_submenu_nopriv;

		if ( ! isset( $hook_suffix ) ) {
			$hook_suffix = 'index'; // phpcs:ignore FinPress.FIN.GlobalVariablesOverride.Prohibited
		}

		// Make sure we don't trigger a DB upgrade as that tries to redirect
		// the page.

		/**
		 * @var string $fin_db_version
		 */
		$fin_db_version = get_option( 'db_version' ); // phpcs:ignore FinPress.FIN.GlobalVariablesOverride.Prohibited
		$fin_db_version = (int) $fin_db_version; // phpcs:ignore FinPress.FIN.GlobalVariablesOverride.Prohibited

		// Ensure FIN does not iterate over an undefined variable in
		// `user_can_access_admin_page()`.
		if ( ! isset( $_fin_submenu_nopriv ) ) {
			$_fin_submenu_nopriv = []; // phpcs:ignore FinPress.FIN.GlobalVariablesOverride.Prohibited
		}

		$admin_php_file = (string) file_get_contents( ABSPATH . 'fin-admin/admin.php' );

		// First we remove the opening and closing PHP tags.
		$admin_php_file = (string) preg_replace( '/^<\?php\s+/', '', $admin_php_file );
		$admin_php_file = (string) preg_replace( '/\s+\?>$/', '', $admin_php_file );

		// Then we remove the loading of either fin-config.php or fin-load.php.
		$admin_php_file = (string) preg_replace( '/^\s*(?:include|require).*[\'"]\/?fin-(?:load|config)\.php[\'"]\s*\)?;\s*$/m', '', $admin_php_file );

		// We also remove the authentication redirect.
		$admin_php_file = (string) preg_replace( '/^\s*auth_redirect\(\);$/m', '', $admin_php_file );

		// Finally, we avoid sending headers.
		$admin_php_file   = (string) preg_replace( '/^\s*nocache_headers\(\);$/m', '', $admin_php_file );
		$_GET['noheader'] = true;

		eval( $admin_php_file ); // phpcs:ignore Squiz.PHP.Eval.Discouraged
	}
}
