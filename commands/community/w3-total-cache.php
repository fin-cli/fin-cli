<?php

// Add the command to the wp-cli, only if the plugin is loaded
if ( function_exists( 'w3tc_pgcache_flush' ) ) {
	WP_CLI::addCommand( 'total-cache', 'W3TotalCacheCommand' );
}

/**
 * The WP Super Cache plugin
 *
 * @package wp-cli
 * @subpackage commands/community
 * @author Andreas Creten
 */
class W3TotalCacheCommand extends WP_CLI_Command {

	/**
	 * Clear something from the cache
	 *
	 * @param array $args
	 * @param array $vars
	 * @return void
	 */
	function flush( $args = array(), $vars = array() ) {
		if ( function_exists( 'w3tc_pgcache_flush' ) ) {
			$cache_type = array_shift($args);

			switch($cache_type) {
				case 'db':
				case 'database':
					if ( w3tc_dbcache_flush() ) {
						WP_CLI::success( 'The object cache is flushed successfully.' );
					} else {
						WP_CLI::error( 'Flushing the object cache failed.' );
					}
				break;
				
				case 'minify':
					if ( w3tc_minify_flush() ) {
						WP_CLI::success( 'The object cache is flushed successfully.' );
					} else {
						WP_CLI::error( 'Flushing the object cache failed.' );
					}
				break;
				
				case 'object':
					if ( w3tc_objectcache_flush() ) {
						WP_CLI::success( 'The object cache is flushed successfully.' );
					} else {
						WP_CLI::error( 'Flushing the object cache failed.' );
					}
				break;
				
				case 'post':
				default:
					if ( isset($vars['post_id']) ) {
						if ( is_numeric( $vars['post_id'] ) ) {
							w3tc_pgcache_flush_post( $vars['post_id'] );
						} else {
							WP_CLI::error('This is not a valid post id.');
						}

						w3tc_pgcache_flush_post( $vars['post_id'] );
					}
					elseif ( isset( $vars['permalink'] ) ) {
						$id = url_to_postid( $vars['permalink'] );

						if ( is_numeric( $id ) ) {
							w3tc_pgcache_flush_post( $id );
						} else {
							WP_CLI::error('There is no post with this permalink.');
						}
					} else {
						w3tc_pgcache_flush();
					}
			}
		} else {
			WP_CLI::error('The W3 Total Cache could not be found, is it installed?');
		}
	}
	
	/**
	 * Help function for this command
	 *
	 * @param array $args
	 * @return void
	 */
	public function help($args = array()) {
		// Show the command description
			WP_CLI::out( <<<EOB
usage: wp total-cache flush [post|database|minify|object] [--post_id=<post-id>] [--permalink=<post-permalink>]

Avaliable sub-commands:
    flush       flushes whole cache
                --post_id=<id>                  flush specific ID
                --permalink=<post-permalink>    flush specific permalink
                database                        flushes database cache
                object                          flush object cache
                minify                          flush minify cache
EOB
            );
	}
}
