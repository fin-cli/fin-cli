<?php
/**
 * Requests for PHP
 *
 * Inspired by Requests for Python.
 *
 * Based on concepts from SimplePie_File, RequestCore and FP_Http.
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
		. ' Switch to the PSR-4 `FpOrg\Requests\...` class names at your earliest convenience.',
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
 * Based on concepts from SimplePie_File, RequestCore and FP_Http.
 *
 * @package Requests
 *
 * @deprecated 2.0.0 Use `FpOrg\Requests\Requests` instead for the actual functionality and
 *                   use `FpOrg\Requests\Autoload` for the autoloading.
 */
class Requests extends FpOrg\Requests\Requests {

	/**
	 * Deprecated autoloader for Requests.
	 *
	 * @deprecated 2.0.0 Use the `FpOrg\Requests\Autoload::load()` method instead.
	 *
	 * @codeCoverageIgnore
	 *
	 * @param string $class Class name to load
	 */
	public static function autoloader($class) {
		if (class_exists('FpOrg\Requests\Autoload') === false) {
			require_once dirname(__DIR__) . '/src/Autoload.php';
		}

		return FpOrg\Requests\Autoload::load($class);
	}

	/**
	 * Register the built-in autoloader
	 *
	 * @deprecated 2.0.0 Include the `FpOrg\Requests\Autoload` class and
	 *                   call `FpOrg\Requests\Autoload::register()` instead.
	 *
	 * @codeCoverageIgnore
	 */
	public static function register_autoloader() {
		require_once dirname(__DIR__) . '/src/Autoload.php';
		FpOrg\Requests\Autoload::register();
	}
}
