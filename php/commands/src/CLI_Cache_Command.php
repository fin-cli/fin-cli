<?php

/**
 * Manages the internal FIN-CLI cache,.
 *
 * ## EXAMPLES
 *
 *     # Remove all cached files.
 *     $ fin cli cache clear
 *     Success: Cache cleared.
 *
 *     # Remove all cached files except for the newest version of each one.
 *     $ fin cli cache prune
 *     Success: Cache pruned.
 *
 * @when before_fin_load
 */
class CLI_Cache_Command extends FIN_CLI_Command {

	/**
	 * Clears the internal cache.
	 *
	 * ## EXAMPLES
	 *
	 *     $ fin cli cache clear
	 *     Success: Cache cleared.
	 *
	 * @subcommand clear
	 */
	public function cache_clear() {
		$cache = FIN_CLI::get_cache();

		if ( ! $cache->is_enabled() ) {
			FIN_CLI::error( 'Cache directory does not exist.' );
		}

		$cache->clear();

		FIN_CLI::success( 'Cache cleared.' );
	}

	/**
	 * Prunes the internal cache.
	 *
	 * Removes all cached files except for the newest version of each one.
	 *
	 * ## EXAMPLES
	 *
	 *     $ fin cli cache prune
	 *     Success: Cache pruned.
	 *
	 * @subcommand prune
	 */
	public function cache_prune() {
		$cache = FIN_CLI::get_cache();

		if ( ! $cache->is_enabled() ) {
			FIN_CLI::error( 'Cache directory does not exist.' );
		}

		$cache->prune();

		FIN_CLI::success( 'Cache pruned.' );
	}
}
