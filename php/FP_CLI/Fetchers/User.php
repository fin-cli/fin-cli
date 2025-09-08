<?php

namespace FP_CLI\Fetchers;

use FP_CLI;
use FP_User;

/**
 * Fetch a FinPress user based on one of its attributes.
 *
 * @extends Base<\FP_User>
 */
class User extends Base {

	/**
	 * The message to display when an item is not found.
	 *
	 * @var string
	 */
	protected $msg = "Invalid user ID, email or login: '%s'";

	/**
	 * Get a user object by one of its identifying attributes.
	 *
	 * @param string|int $arg The raw CLI argument.
	 * @return FP_User|false The item if found; false otherwise.
	 */
	public function get( $arg ) {

		if ( getenv( 'FP_CLI_FORCE_USER_LOGIN' ) ) {
			$this->msg = "Invalid user login: '%s'";
			return get_user_by( 'login', $arg );
		}

		if ( is_numeric( $arg ) ) {
			$check = get_user_by( 'login', $arg );
			$user  = get_user_by( 'id', $arg );
			if ( $check && $user ) {
				FP_CLI::warning(
					sprintf(
						'Ambiguous user match detected (both ID and user_login exist for identifier \'%d\'). FP-CLI will default to the ID, but you can force user_login instead with FP_CLI_FORCE_USER_LOGIN=1.',
						$arg
					)
				);
			}
		} elseif ( is_email( $arg ) ) {
			$user = get_user_by( 'email', $arg );
			// Logins can be emails.
			if ( ! $user ) {
				$user = get_user_by( 'login', $arg );
			}
		} else {
			$user = get_user_by( 'login', $arg );
		}

		return $user;
	}
}
