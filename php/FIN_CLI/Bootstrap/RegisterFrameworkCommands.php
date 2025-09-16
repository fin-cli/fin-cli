<?php

namespace FIN_CLI\Bootstrap;

use DirectoryIterator;
use Exception;
use FIN_CLI;

/**
 * Class RegisterFrameworkCommands.
 *
 * Register the commands that are directly included with the framework.
 *
 * @package FIN_CLI\Bootstrap
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
		$cmd_dir = FIN_CLI_ROOT . '/php/commands';

		$iterator = new DirectoryIterator( $cmd_dir );

		foreach ( $iterator as $filename ) {
			if ( '.php' !== substr( $filename, - 4 ) ) {
				continue;
			}

			try {
				FIN_CLI::debug(
					sprintf(
						'Adding framework command: %s',
						"$cmd_dir/$filename"
					),
					'bootstrap'
				);

				include_once "$cmd_dir/$filename";
			} catch ( Exception $exception ) {
				FIN_CLI::warning(
					"Could not add command {$cmd_dir}/{$filename}. Reason: " . $exception->getMessage()
				);
			}
		}

		return $state;
	}
}
