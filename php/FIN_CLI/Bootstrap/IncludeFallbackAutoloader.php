<?php

namespace FIN_CLI\Bootstrap;

use FIN_CLI;

/**
 * Class IncludeFallbackAutoloader.
 *
 * Loads the fallback autoloader that is provided through the `composer.json`
 * file.
 *
 * @package FIN_CLI\Bootstrap
 */
final class IncludeFallbackAutoloader extends AutoloaderStep {

	/**
	 * Get the autoloader paths to scan for an autoloader.
	 *
	 * @return string[] Array of autoloader paths, or an empty array if none are found.
	 */
	protected function get_autoloader_paths() {
		$autoloader_paths = [
			FIN_CLI_VENDOR_DIR . '/autoload.php',
		];

		$custom_vendor = $this->get_custom_vendor_folder();
		if ( false !== $custom_vendor ) {
			array_unshift(
				$autoloader_paths,
				FIN_CLI_ROOT . '/../../../' . $custom_vendor . '/autoload.php'
			);
		}

		FIN_CLI::debug(
			sprintf(
				'Fallback autoloader paths: %s',
				implode( ', ', $autoloader_paths )
			),
			'bootstrap'
		);

		return $autoloader_paths;
	}
}
