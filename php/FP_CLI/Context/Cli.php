<?php

namespace FP_CLI\Context;

use FP_CLI;
use FP_CLI\Context;

/**
 * Default FP-CLI context.
 */
final class Cli implements Context {

	/**
	 * Process the context to set up the environment correctly.
	 *
	 * @param array $config Associative array of configuration data.
	 *
	 * @return void
	 */
	public function process( $config ) {
		// Nothing needs to be done for now, as this is the default.
	}
}
