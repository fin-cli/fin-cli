<?php

namespace FP_CLI\Bootstrap;

/**
 * Class LoadUtilityFunctions.
 *
 * Loads the functions available through `FP_CLI\Utils`.
 *
 * @package FP_CLI\Bootstrap
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
		require_once FP_CLI_ROOT . '/php/utils.php';

		return $state;
	}
}
