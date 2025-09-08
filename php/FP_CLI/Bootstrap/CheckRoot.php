<?php

namespace FP_CLI\Bootstrap;

use FP_CLI;
use FP_CLI\Utils;

/**
 * Class CheckRoot.
 *
 * Check if the user is running as root and aborts with a warning if they are.
 *
 * @package FP_CLI\Bootstrap
 */
class CheckRoot implements BootstrapStep {

	/**
	 * Process this single bootstrapping step.
	 *
	 * @param BootstrapState $state Contextual state to pass into the step.
	 *
	 * @return BootstrapState Modified state to pass to the next step.
	 */
	public function process( BootstrapState $state ) {
		/**
		 * @var array{'allow-root'?: bool} $config
		 */
		$config = $state->getValue( 'config', [] );
		if ( array_key_exists( 'allow-root', $config ) && true === $config['allow-root'] ) {
			// They're aware of the risks and set a flag to allow root.
			return $state;
		}

		if ( getenv( 'FP_CLI_ALLOW_ROOT' ) ) {
			// They're aware of the risks and set an environment variable to allow root.
			return $state;
		}

		/**
		 * @var string[] $args
		 */
		$args = $state->getValue( 'arguments', [] );
		if ( count( $args ) >= 2 && 'cli' === $args[0] && in_array( $args[1], [ 'update', 'info' ], true ) ) {
			// Make it easier to update root-owned copies.
			return $state;
		}

		if ( ! function_exists( 'posix_geteuid' ) ) {
			// POSIX functions not available.
			return $state;
		}

		if ( posix_geteuid() !== 0 ) {
			// Not root.
			return $state;
		}

		FP_CLI::error(
			"YIKES! It looks like you're running this as root. You probably meant to " .
			"run this as the user that your FinPress installation exists under.\n" .
			"\n" .
			"If you REALLY mean to run this as root, we won't stop you, but just " .
			'bear in mind that any code on this site will then have full control of ' .
			"your server, making it quite DANGEROUS.\n" .
			"\n" .
			"If you'd like to continue as root, please run this again, adding this " .
			"flag:  --allow-root\n" .
			"\n" .
			"If you'd like to run it as the user that this site is under, you can " .
			"run the following to become the respective user:\n" .
			"\n" .
			"    sudo -u USER -i -- fp <command>\n" .
			"\n"
		);
	}
}
