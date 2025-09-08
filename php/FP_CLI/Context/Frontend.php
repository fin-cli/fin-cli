<?php

namespace FP_CLI\Context;

use FP_CLI;
use FP_CLI\Context;

/**
 * Context which simulates a frontend request.
 */
final class Frontend implements Context {

	/**
	 * Process the context to set up the environment correctly.
	 *
	 * @param array $config Associative array of configuration data.
	 *
	 * @return void
	 */
	public function process( $config ) {
		// TODO: Frontend context needs to be simulated here.
	}
}
