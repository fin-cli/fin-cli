<?php

namespace WP_CLI;

/**
 * Base class for WP-CLI commands that deal with database objects.
 *
 * @package wp-cli
 */
abstract class CommandWithDBObject extends \WP_CLI_Command {

	protected $obj_type;
	protected $obj_id_key = 'ID';

	abstract protected function _create( $params );
	abstract protected function _update( $params );
	abstract protected function _delete( $obj_id, $assoc_args );

	public function create( $args, $assoc_args ) {
		unset( $assoc_args[ $this->obj_id_key ] );

		$obj_id = $this->_create( $assoc_args );

		if ( is_wp_error( $obj_id ) ) {
			\WP_CLI::error( $obj_id );
		}

		if ( isset( $assoc_args['porcelain'] ) )
			\WP_CLI::line( $obj_id );
		else
			\WP_CLI::success( "Created $this->obj_type $obj_id." );
	}

	public function update( $args, $assoc_args ) {
		$status = 0;

		if ( empty( $assoc_args ) ) {
			\WP_CLI::error( "Need some fields to update." );
		}

		foreach ( $args as $obj_id ) {
			$params = array_merge( $assoc_args, array( $this->obj_id_key => $obj_id ) );

			$status = $this->success_or_failure( $this->wp_error_to_resp(
				$this->_update( $params ),
				"Updated $this->obj_type $obj_id."
			) );
		}

		exit( $status );
	}

	public function delete( $args, $assoc_args ) {
		$status = 0;

		foreach ( $args as $obj_id ) {
			$r = $this->_delete( $obj_id, $assoc_args );
			$status = $this->success_or_failure( $r );
		}

		exit( $status );
	}

	protected function wp_error_to_resp( $r, $success_msg ) {
		if ( is_wp_error( $r ) )
			return array( 'error', $r->get_error_message() );
		else
			return array( 'success', $success_msg );
	}

	protected function success_or_failure( $r ) {
		list( $type, $msg ) = $r;

		if ( 'success' == $type ) {
			\WP_CLI::success( $msg );
			$status = 0;
		} else {
			\WP_CLI::warning( $msg );
			$status = 1;
		}

		return $status;
	}

	protected function show_single_field( $post, $field ) {
		$value = null;

		foreach ( array( $field, $this->obj_type . '_' . $field ) as $key ) {
			if ( isset( $post->$key ) ) {
				$value = $post->$key;
				break;
			}
		}

		if ( null === $value ) {
			\WP_CLI::error( "Invalid $this->obj_type field: $field." );
		} else {
			\WP_CLI::print_value( $value );
		}
	}
}

