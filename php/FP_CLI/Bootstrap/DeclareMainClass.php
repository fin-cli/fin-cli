<?php

namespace FP_CLI\Bootstrap;

/**
 * Class DeclareMainClass.
 *
 * Declares the main `FP_CLI` class.
 *
 * @package FP_CLI\Bootstrap
 */
final class DeclareMainClass implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		require_once FP_CLI_ROOT . '/php/class-fp-cli.php';

		return $state;
	}
}
