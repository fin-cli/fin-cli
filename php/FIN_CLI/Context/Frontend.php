<?php

namespace FIN_CLI\Context;

use FIN_CLI;
use FIN_CLI\Context;

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
