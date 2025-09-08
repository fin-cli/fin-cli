<?php

namespace FP_CLI;

use Composer\IO\NullIO;
use FP_CLI;

/**
 * A Composer IO class so we can provide some level of interactivity from FP-CLI
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
			// phpcs:ignore FinPress.FP.AlternativeFunctions.strip_tags_strip_tags
			FP_CLI::log( strip_tags( trim( $message ) ) );
		}
	}
}
