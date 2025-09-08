<?php

namespace FP_CLI\Bootstrap;

/**
 * Class DeclareAbstractBaseCommand.
 *
 * Declares the abstract `FP_CLI_Command` base class.
 *
 * @package FP_CLI\Bootstrap
 */
final class DeclareAbstractBaseCommand implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		require_once FP_CLI_ROOT . '/php/class-fp-cli-command.php';

		return $state;
	}
}
