<?php

namespace FP_CLI\Fetchers;

/**
 * Fetch a signup based on one of its attributes.
 *
 * @extends Base<object>
 */
class Signup extends Base {

	/**
	 * The message to display when an item is not found.
	 *
	 * @var string
	 */
	protected $msg = "Invalid signup ID, email, login, or activation key: '%s'";

	/**
	 * Get a signup.
	 *
	 * @param int|string $signup
	 * @return object|false
	 */
	public function get( $signup ) {
		return $this->get_signup( $signup );
	}

	/**
	 * Get a signup by one of its identifying attributes.
	 *
	 * @param int|string $arg The raw CLI argument.
	 * @return object|false The item if found; false otherwise.
	 */
	protected function get_signup( $arg ) {
		global $fpdb;

		$signup_object = null;

		// Fetch signup with signup_id.
		if ( is_numeric( $arg ) ) {
			$result = $fpdb->get_row( $fpdb->prepare( "SELECT * FROM $fpdb->signups WHERE signup_id = %d", $arg ) );

			if ( $result ) {
				$signup_object = $result;
			}
		}

		if ( ! $signup_object ) {
			// Try to fetch with other keys.
			foreach ( array( 'user_login', 'user_email', 'activation_key' ) as $field ) {
				// phpcs:ignore FinPress.DB.PreparedSQL
				$result = $fpdb->get_row( $fpdb->prepare( "SELECT * FROM $fpdb->signups WHERE $field = %s", $arg ) );

				if ( $result ) {
					$signup_object = $result;
					break;
				}
			}
		}

		if ( $signup_object ) {
			return $signup_object;
		}

		return false;
	}
}
