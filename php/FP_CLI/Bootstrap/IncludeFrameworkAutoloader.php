<?php

namespace FP_CLI\Bootstrap;

use FP_CLI\Autoloader;

/**
 * Class IncludeFrameworkAutoloader.
 *
 * Loads the framework autoloader through an autoloader separate from the
 * Composer one, to avoid coupling the loading of the framework with bundled
 * commands.
 *
 * This only contains classes for the framework.
 *
 * @package FP_CLI\Bootstrap
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
		if ( ! class_exists( 'FP_CLI\Autoloader' ) ) {
			require_once FP_CLI_ROOT . '/php/FP_CLI/Autoloader.php';
		}

		$autoloader = new Autoloader();

		$mappings = [
			'FP_CLI'                   => FP_CLI_ROOT . '/php/FP_CLI',
			'cli'                      => FP_CLI_VENDOR_DIR . '/fp-cli/php-cli-tools/lib/cli',
			'Symfony\Component\Finder' => FP_CLI_VENDOR_DIR . '/symfony/finder/',
		];

		foreach ( $mappings as $namespace => $folder ) {
			$autoloader->add_namespace(
				$namespace,
				$folder
			);
		}

		include_once FP_CLI_VENDOR_DIR . '/fp-cli/mustangostang-spyc/Spyc.php';

		$autoloader->register();

		return $state;
	}
}
