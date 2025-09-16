<?php

namespace FIN_CLI\Bootstrap;

/**
 * Class LoadDispatcher.
 *
 * Loads the dispatcher that will dispatch command names to file locations.
 *
 * @package FIN_CLI\Bootstrap
 */
final class LoadDispatcher implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		require_once FIN_CLI_ROOT . '/php/dispatcher.php';

		return $state;
	}
}
