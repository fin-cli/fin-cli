<?php

/**
 * Manage network custom fields.
 *
 * @package wp-cli
 */
class Network_Meta_Command extends \WP_CLI\CommandWithMeta {
	protected $meta_type = 'site';
}

WP_CLI::add_command( 'network-meta', 'Network_Meta_Command', array(
	'before_invoke' => function () {
		if ( !is_multisite() ) {
			WP_CLI::error( 'This is not a multisite install.' );
		}
	}
) );

