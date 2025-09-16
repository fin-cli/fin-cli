<?php

namespace FIN_CLI\Bootstrap;

use FIN_CLI;
use FIN_CLI\Runner;

/**
 * Class RunnerInstance.
 *
 * Convenience class for steps that make use of the `FIN_CLI\Runner` object.
 *
 * @package FIN_CLI\Bootstrap
 */
final class RunnerInstance {

	/**
	 * Return an instance of the `FIN_CLI\Runner` object.
	 *
	 * Includes necessary class files first as needed.
	 *
	 * @return Runner
	 */
	public function __invoke() {
		if ( ! class_exists( 'FIN_CLI\Runner' ) ) {
			require_once FIN_CLI_ROOT . '/php/FIN_CLI/Runner.php';
		}

		if ( ! class_exists( 'FIN_CLI\Configurator' ) ) {
			require_once FIN_CLI_ROOT . '/php/FIN_CLI/Configurator.php';
		}

		return FIN_CLI::get_runner();
	}
}
