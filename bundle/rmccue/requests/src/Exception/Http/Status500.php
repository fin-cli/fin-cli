<?php
/**
 * Exception for 500 Internal Server Error responses
 *
 * @package Requests\Exceptions
 */

namespace FpOrg\Requests\Exception\Http;

use FpOrg\Requests\Exception\Http;

/**
 * Exception for 500 Internal Server Error responses
 *
 * @package Requests\Exceptions
 */
final class Status500 extends Http {
	/**
	 * HTTP status code
	 *
	 * @var integer
	 */
	protected $code = 500;

	/**
	 * Reason phrase
	 *
	 * @var string
	 */
	protected $reason = 'Internal Server Error';
}
