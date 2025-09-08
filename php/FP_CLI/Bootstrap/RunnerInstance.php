<?php

namespace FP_CLI\Bootstrap;

use FP_CLI;
use FP_CLI\Runner;

/**
 * Class RunnerInstance.
 *
 * Convenience class for steps that make use of the `FP_CLI\Runner` object.
 *
 * @package FP_CLI\Bootstrap
 */
final class RunnerInstance {

	/**
	 * Return an instance of the `FP_CLI\Runner` object.
	 *
	 * Includes necessary class files first as needed.
	 *
	 * @return Runner
	 */
	public function __invoke() {
		if ( ! class_exists( 'FP_CLI\Runner' ) ) {
			require_once FP_CLI_ROOT . '/php/FP_CLI/Runner.php';
		}

		if ( ! class_exists( 'FP_CLI\Configurator' ) ) {
			require_once FP_CLI_ROOT . '/php/FP_CLI/Configurator.php';
		}

		return FP_CLI::get_runner();
	}
}
