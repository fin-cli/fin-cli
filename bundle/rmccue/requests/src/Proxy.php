<?php
/**
 * Proxy connection interface
 *
 * @package Requests\Proxy
 * @since   1.6
 */

namespace FpOrg\Requests;

use FpOrg\Requests\Hooks;

/**
 * Proxy connection interface
 *
 * Implement this interface to handle proxy settings and authentication
 *
 * Parameters should be passed via the constructor where possible, as this
 * makes it much easier for users to use your provider.
 *
 * @see \FpOrg\Requests\Hooks
 *
 * @package Requests\Proxy
 * @since   1.6
 */
interface Proxy {
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
