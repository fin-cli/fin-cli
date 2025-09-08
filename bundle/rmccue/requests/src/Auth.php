<?php
/**
 * Authentication provider interface
 *
 * @package Requests\Authentication
 */

namespace FpOrg\Requests;

use FpOrg\Requests\Hooks;

/**
 * Authentication provider interface
 *
 * Implement this interface to act as an authentication provider.
 *
 * Parameters should be passed via the constructor where possible, as this
 * makes it much easier for users to use your provider.
 *
 * @see \FpOrg\Requests\Hooks
 *
 * @package Requests\Authentication
 */
interface Auth {
	/**
	 * Register hooks as needed
	 *
	 * This method is called in {@see \FpOrg\Requests\Requests::request()} when the user
	 * has set an instance as the 'auth' option. Use this callback to register all the
	 * hooks you'll need.
	 *
	 * @see \FpOrg\Requests\Hooks::register()
	 * @param \FpOrg\Requests\Hooks $hooks Hook system
	 */
	public function register(Hooks $hooks);
}
