<?php

namespace FIN_CLI;

use Composer\IO\NullIO;
use FIN_CLI;

/**
 * A Composer IO class so we can provide some level of interactivity from FIN-CLI
 */
class ComposerIO extends NullIO {

	/**
	 * {@inheritDoc}
	 */
	public function isVerbose() {
		return true;
	}

	/**
	 * {@inheritDoc}
	 */
	public function write( $messages, $newline = true, $verbosity = self::NORMAL ) {
		self::output_clean_message( $messages );
	}

	/**
	 * {@inheritDoc}
	 */
	public function writeError( $messages, $newline = true, $verbosity = self::NORMAL ) {
		self::output_clean_message( $messages );
	}

	private static function output_clean_message( $messages ) {
		$messages = (array) preg_replace( '#<(https?)([^>]+)>#', '$1$2', $messages );
		foreach ( $messages as $message ) {
			// phpcs:ignore FinPress.FIN.AlternativeFunctions.strip_tags_strip_tags
			FIN_CLI::log( strip_tags( trim( $message ) ) );
		}
	}
}
