<?php

WP_CLI::add_command('option', 'Option_Command');

/**
 * Implement option command
 *
 * @package wp-cli
 * @subpackage commands/internals
 */
class Option_Command extends WP_CLI_Command {

	/**
	 * Add an option
	 *
	 * @param array $args
	 **/
	public function add( $args, $assoc_args ) {
		if ( count( $args ) < 2 ) {
			WP_CLI::line( "usage: wp option add <option-name> <option-value>" );
			exit;
		}

		list( $key, $value ) = self::read_name_and_value( $args, $assoc_args );

		if ( !add_option( $key, $value ) ) {
			WP_CLI::error( "Could not add option '$key'. Does it already exist?" );
		}
	}

	/**
	 * Update an option
	 *
	 * @param array $args
	 **/
	public function update( $args, $assoc_args ) {
		if ( count( $args ) < 2 ) {
			WP_CLI::line( "usage: wp option update <option-name> <option-value>" );
			exit;
		}

		list( $key, $value ) = self::read_name_and_value( $args, $assoc_args );

		if ( $value === get_option( $key ) )
			return;

		if ( !update_option( $key, $value ) ) {
			WP_CLI::error( "Could not update option '$key'." );
		}
	}
	
	private function read_name_and_value( $args, $assoc_args) {
		list( $key, $value ) = $args;
		
		if ( isset( $assoc_args['json'] ) ) {
			$value = json_decode( $value, true );
		}
		
		return array( $key, $value );
	}

	/**
	 * Delete an option
	 *
	 * @param array $args
	 **/
	public function delete( $args ) {
		if ( empty( $args ) ) {
			WP_CLI::line( "usage: wp option get <option-name>" );
			exit;
		}

		list( $key ) = $args;

		if ( !delete_option( $key ) ) {
			WP_CLI::error( "Could not delete '$key' option. Does it exist?" );
		}
	}

	/**
	 * Get an option
	 *
	 * @param array $args
	 **/
	public function get( $args, $assoc_args ) {
		if ( empty( $args ) ) {
			WP_CLI::line( "usage: wp option get <option-name>" );
			exit;
		}

		list( $key ) = $args;

		$value = get_option( $key );

		if ( false === $value )
			die(1);

		WP_CLI::print_value( $value, $assoc_args );
	}
}
