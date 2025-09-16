<?php

namespace FIN_CLI\Bootstrap;

/**
 * Class LoadUtilityFunctions.
 *
 * Loads the functions available through `FIN_CLI\Utils`.
 *
 * @package FIN_CLI\Bootstrap
 */
final class LoadUtilityFunctions implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		require_once FIN_CLI_ROOT . '/php/utils.php';

		return $state;
	}
}
