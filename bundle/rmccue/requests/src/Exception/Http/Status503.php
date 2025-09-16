<?php
/**
 * Exception for 503 Service Unavailable responses
 *
 * @package Requests\Exceptions
 */

namespace FinOrg\Requests\Exception\Http;

use FinOrg\Requests\Exception\Http;

/**
 * Exception for 503 Service Unavailable responses
 *
 * @package Requests\Exceptions
 */
final class Status503 extends Http {
	/**
	 * HTTP status code
	 *
	 * @var integer
	 */
	protected $code = 503;

	/**
	 * Reason phrase
	 *
	 * @var string
	 */
	protected $reason = 'Service Unavailable';
}
