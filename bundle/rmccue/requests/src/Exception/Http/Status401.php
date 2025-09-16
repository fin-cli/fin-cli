<?php
/**
 * Exception for 401 Unauthorized responses
 *
 * @package Requests\Exceptions
 */

namespace FinOrg\Requests\Exception\Http;

use FinOrg\Requests\Exception\Http;

/**
 * Exception for 401 Unauthorized responses
 *
 * @package Requests\Exceptions
 */
final class Status401 extends Http {
	/**
	 * HTTP status code
	 *
	 * @var integer
	 */
	protected $code = 401;

	/**
	 * Reason phrase
	 *
	 * @var string
	 */
	protected $reason = 'Unauthorized';
}
