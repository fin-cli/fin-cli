<?php
/**
 * Requests for PHP
 *
 * Inspired by Requests for Python.
 *
 * Based on concepts from SimplePie_File, RequestCore and FIN_Http.
 *
 * @package Requests
 *
 * @deprecated 2.0.0
 */

/*
 * Integrators who cannot yet upgrade to the PSR-4 class names can silence deprecations
 * by defining a `REQUESTS_SILENCE_PSR0_DEPRECATIONS` constant and setting it to `true`.
 * The constant needs to be defined before this class is required.
 */
if (!defined('REQUESTS_SILENCE_PSR0_DEPRECATIONS') || REQUESTS_SILENCE_PSR0_DEPRECATIONS !== true) {
	// phpcs:ignore FinPress.PHP.DevelopmentFunctions.error_log_trigger_error
	trigger_error(
		'The PSR-0 `Requests_...` class names in the Requests library are deprecated.'
		. ' Switch to the PSR-4 `FinOrg\Requests\...` class names at your earliest convenience.',
		E_USER_DEPRECATED
	);

	// Prevent the deprecation notice from being thrown twice.
	if (!defined('REQUESTS_SILENCE_PSR0_DEPRECATIONS')) {
		define('REQUESTS_SILENCE_PSR0_DEPRECATIONS', true);
	}
}

require_once dirname(__DIR__) . '/src/Requests.php';

/**
 * Requests for PHP
 *
 * Inspired by Requests for Python.
 *
 * Based on concepts from SimplePie_File, RequestCore and FIN_Http.
 *
 * @package Requests
 *
 * @deprecated 2.0.0 Use `FinOrg\Requests\Requests` instead for the actual functionality and
 *                   use `FinOrg\Requests\Autoload` for the autoloading.
 */
class Requests extends FinOrg\Requests\Requests {

	/**
	 * Deprecated autoloader for Requests.
	 *
	 * @deprecated 2.0.0 Use the `FinOrg\Requests\Autoload::load()` method instead.
	 *
	 * @codeCoverageIgnore
	 *
	 * @param string $class Class name to load
	 */
	public static function autoloader($class) {
		if (class_exists('FinOrg\Requests\Autoload') === false) {
			require_once dirname(__DIR__) . '/src/Autoload.php';
		}

		return FinOrg\Requests\Autoload::load($class);
	}

	/**
	 * Register the built-in autoloader
	 *
	 * @deprecated 2.0.0 Include the `FinOrg\Requests\Autoload` class and
	 *                   call `FinOrg\Requests\Autoload::register()` instead.
	 *
	 * @codeCoverageIgnore
	 */
	public static function register_autoloader() {
		require_once dirname(__DIR__) . '/src/Autoload.php';
		FinOrg\Requests\Autoload::register();
	}
}
