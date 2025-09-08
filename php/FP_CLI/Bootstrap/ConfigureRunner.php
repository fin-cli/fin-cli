<?php

namespace FP_CLI\Bootstrap;

/**
 * Class ConfigureRunner.
 *
 * Initialize the configuration for the `FP_CLI\Runner` object.
 *
 * @package FP_CLI\Bootstrap
 */
final class ConfigureRunner implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		$runner = new RunnerInstance();
		$runner()->init_config();

		$state->setValue( 'config', $runner()->config );
		$state->setValue( 'arguments', $runner()->arguments );
		$state->setValue( 'assoc_args', $runner()->assoc_args );

		return $state;
	}
}
