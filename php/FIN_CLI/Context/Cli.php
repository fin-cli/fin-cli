<?php

namespace FIN_CLI\Context;

use FIN_CLI;
use FIN_CLI\Context;

/**
 * Default FIN-CLI context.
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
