<?php

namespace FP_CLI\Bootstrap;

/**
 * Class InitializeColorization.
 *
 * Initialize the colorization through the `FP_CLI\Runner` object.
 *
 * @package FP_CLI\Bootstrap
 */
final class InitializeColorization implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		$runner = new RunnerInstance();
		$runner()->init_colorization();

		return $state;
	}
}
