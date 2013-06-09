<?php

/**
 * Manage WordPress options.
 *
 * @package wp-cli
 */
class Option_Command extends WP_CLI_Command {

	/**
	 * Get an option.
	 *
	 * @synopsis <key> [--format=<format>]
	 */
	public function get( $args, $assoc_args ) {
		list( $key ) = $args;

		$value = get_option( $key );

		if ( false === $value )
			die(1);

		WP_CLI::print_value( $value, $assoc_args );
	}

	/**
	 * Add an option.
	 *
	 * @synopsis <key> [--format=<format>]
	 */
	public function add( $args, $assoc_args ) {
		$key = $args[0];

		$value = WP_CLI::read_value( $args[1], $assoc_args );

		if ( !add_option( $key, $value ) ) {
			WP_CLI::error( "Could not add option '$key'. Does it already exist?" );
		} else {
			WP_CLI::success( "Added '$key' option." );
		}
	}

	/**
	 * Update an option.
	 *
	 * @alias set
	 * @synopsis <key> [--format=<format>]
	 */
	public function update( $args, $assoc_args ) {
		$key = $args[0];

		$value = WP_CLI::read_value( $args[1], $assoc_args );

		if ( $value === get_option( $key ) )
			return;

		if ( !update_option( $key, $value ) ) {
			WP_CLI::error( "Could not update option '$key'." );
		} else {
			WP_CLI::success( "Updated '$key' option." );
		}
	}

	/**
	 * Delete an option.
	 *
	 * @synopsis <key>
	 */
	public function delete( $args ) {
		list( $key ) = $args;

		if ( !delete_option( $key ) ) {
			WP_CLI::error( "Could not delete '$key' option. Does it exist?" );
		} else {
			WP_CLI::success( "Deleted '$key' option." );
		}
	}
}

WP_CLI::add_command( 'option', 'Option_Command' );

