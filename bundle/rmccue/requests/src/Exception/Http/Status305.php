<?php
/**
 * Exception for 305 Use Proxy responses
 *
 * @package Requests\Exceptions
 */

namespace FpOrg\Requests\Exception\Http;

use FpOrg\Requests\Exception\Http;

/**
 * Exception for 305 Use Proxy responses
 *
 * @package Requests\Exceptions
 */
final class Status305 extends Http {
	/**
	 * HTTP status code
	 *
	 * @var integer
	 */
	protected $code = 305;

	/**
	 * Reason phrase
	 *
	 * @var string
	 */
	protected $reason = 'Use Proxy';
}
