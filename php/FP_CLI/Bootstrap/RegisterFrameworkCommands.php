<?php

namespace FP_CLI\Bootstrap;

use DirectoryIterator;
use Exception;
use FP_CLI;

/**
 * Class RegisterFrameworkCommands.
 *
 * Register the commands that are directly included with the framework.
 *
 * @package FP_CLI\Bootstrap
 */
final class RegisterFrameworkCommands implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		$cmd_dir = FP_CLI_ROOT . '/php/commands';

		$iterator = new DirectoryIterator( $cmd_dir );

		foreach ( $iterator as $filename ) {
			if ( '.php' !== substr( $filename, - 4 ) ) {
				continue;
			}

			try {
				FP_CLI::debug(
					sprintf(
						'Adding framework command: %s',
						"$cmd_dir/$filename"
					),
					'bootstrap'
				);

				include_once "$cmd_dir/$filename";
			} catch ( Exception $exception ) {
				FP_CLI::warning(
					"Could not add command {$cmd_dir}/{$filename}. Reason: " . $exception->getMessage()
				);
			}
		}

		return $state;
	}
}
