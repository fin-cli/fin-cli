<?php

namespace FIN_CLI\Bootstrap;

use FIN_CLI\Autoloader;

/**
 * Class IncludeFrameworkAutoloader.
 *
 * Loads the framework autoloader through an autoloader separate from the
 * Composer one, to avoid coupling the loading of the framework with bundled
 * commands.
 *
 * This only contains classes for the framework.
 *
 * @package FIN_CLI\Bootstrap
 */
final class IncludeFrameworkAutoloader implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		if ( ! class_exists( 'FIN_CLI\Autoloader' ) ) {
			require_once FIN_CLI_ROOT . '/php/FIN_CLI/Autoloader.php';
		}

		$autoloader = new Autoloader();

		$mappings = [
			'FIN_CLI'                   => FIN_CLI_ROOT . '/php/FIN_CLI',
			'cli'                      => FIN_CLI_VENDOR_DIR . '/fin-cli/php-cli-tools/lib/cli',
			'Symfony\Component\Finder' => FIN_CLI_VENDOR_DIR . '/symfony/finder/',
		];

		foreach ( $mappings as $namespace => $folder ) {
			$autoloader->add_namespace(
				$namespace,
				$folder
			);
		}

		include_once FIN_CLI_VENDOR_DIR . '/fin-cli/mustangostang-spyc/Spyc.php';

		$autoloader->register();

		return $state;
	}
}
