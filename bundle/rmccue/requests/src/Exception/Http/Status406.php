<?php
/**
 * Exception for 406 Not Acceptable responses
 *
 * @package Requests\Exceptions
 */

namespace FinOrg\Requests\Exception\Http;

use FinOrg\Requests\Exception\Http;

/**
 * Exception for 406 Not Acceptable responses
 *
 * @package Requests\Exceptions
 */
final class Status406 extends Http {
	/**
	 * HTTP status code
	 *
	 * @var integer
	 */
	protected $code = 406;

	/**
	 * Reason phrase
	 *
	 * @var string
	 */
	protected $reason = 'Not Acceptable';
}
