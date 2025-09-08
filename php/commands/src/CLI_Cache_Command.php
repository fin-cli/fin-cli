<?php

/**
 * Manages the internal FP-CLI cache,.
 *
 * ## EXAMPLES
 *
 *     # Remove all cached files.
 *     $ fp cli cache clear
 *     Success: Cache cleared.
 *
 *     # Remove all cached files except for the newest version of each one.
 *     $ fp cli cache prune
 *     Success: Cache pruned.
 *
 * @when before_fp_load
 */
class CLI_Cache_Command extends FP_CLI_Command {

	/**
	 * Clears the internal cache.
	 *
	 * ## EXAMPLES
	 *
	 *     $ fp cli cache clear
	 *     Success: Cache cleared.
	 *
	 * @subcommand clear
	 */
	public function cache_clear() {
		$cache = FP_CLI::get_cache();

		if ( ! $cache->is_enabled() ) {
			FP_CLI::error( 'Cache directory does not exist.' );
		}

		$cache->clear();

		FP_CLI::success( 'Cache cleared.' );
	}

	/**
	 * Prunes the internal cache.
	 *
	 * Removes all cached files except for the newest version of each one.
	 *
	 * ## EXAMPLES
	 *
	 *     $ fp cli cache prune
	 *     Success: Cache pruned.
	 *
	 * @subcommand prune
	 */
	public function cache_prune() {
		$cache = FP_CLI::get_cache();

		if ( ! $cache->is_enabled() ) {
			FP_CLI::error( 'Cache directory does not exist.' );
		}

		$cache->prune();

		FP_CLI::success( 'Cache pruned.' );
	}
}
