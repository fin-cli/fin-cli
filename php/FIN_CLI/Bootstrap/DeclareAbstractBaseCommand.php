<?php

namespace FIN_CLI\Bootstrap;

/**
 * Class DeclareAbstractBaseCommand.
 *
 * Declares the abstract `FIN_CLI_Command` base class.
 *
 * @package FIN_CLI\Bootstrap
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
		require_once FIN_CLI_ROOT . '/php/class-fin-cli-command.php';

		return $state;
	}
}
