<?php

namespace FIN_CLI\Bootstrap;

/**
 * Class DeclareMainClass.
 *
 * Declares the main `FIN_CLI` class.
 *
 * @package FIN_CLI\Bootstrap
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
		require_once FIN_CLI_ROOT . '/php/class-fin-cli.php';

		return $state;
	}
}
