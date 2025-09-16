<?php

namespace {
	define( 'FIN_CLI_PHAR_PATH', '' );
	define( 'FIN_CLI_ROOT', '' );
	define( 'FIN_CLI_VERSION', '' );

	define( 'ABSPATH', '' );
	define( 'FIN_CONTENT_DIR', '' );
	define( 'FIN_PLUGIN_DIR', '' );
	define( 'FIN_DEBUG', true );
	define( 'FIN_DEBUG_DISPLAY', true );
	define( 'FIN_DEBUG_LOG', '' );
	define( 'FININC', '' );
	define( 'AUTH_COOKIE', '' );
	define( 'SECURE_AUTH_COOKIE', '' );
	define( 'DAY_IN_SECONDS', 1 );
}

namespace {
	class Requests_Exception extends FinOrg\Requests\Exception {
	}

	class XCache_Object_Cache {
	}

	class Requests_Response extends FinOrg\Requests\Response {
	}

	class findb {
		/**
		 * @param string $text The raw text to be escaped. The input typed by the user
		 *                      should have no extra or deleted slashes.
		 * @return string
		 */
		public function esc_like( $text ) {
		}
	}

	/**
	 * @param  string|array<string> $idents A single identifier or an array of identifiers.
	 * @return string|array<string> An escaped string if given a string, or an array of escaped strings if given an array of strings.
	 *
	 * @phpstan-return ($idents is string ? string : array<string>)
	 */
	function esc_sql( $idents ) {
	}
}

namespace LCache {
	class Integrated {
	}
}

namespace FinOrg\Requests {
	class Exception extends \Exception {
		/**
		 * Like {@see \Exception::getCode()}, but a string code.
		 *
		 * @return string
		 */
		public function getType() {
		}

		/**
		 * Gives any relevant data
		 *
		 * @return mixed
		 */
		public function getData() {
		}
	}

	class Response {
		/**
		 * Response body
		 *
		 * @var string
		 */
		public $body = '';

		/**
		 * Raw HTTP data from the transport
		 *
		 * @var string
		 */
		public $raw = '';

		/**
		 * Headers, as an associative array
		 *
		 * @var \FinOrg\Requests\Response\Headers Array-like object representing headers
		 */
		public $headers = [];

		/**
		 * Status code, false if non-blocking
		 *
		 * @var integer|boolean
		 */
		public $status_code = false;

		/**
		 * Protocol version, false if non-blocking
		 *
		 * @var float|boolean
		 */
		public $protocol_version = false;

		/**
		 * Whether the request succeeded or not
		 *
		 * @var boolean
		 */
		public $success = false;

		/**
		 * Number of redirects the request used
		 *
		 * @var integer
		 */
		public $redirects = 0;

		/**
		 * URL requested
		 *
		 * @var string
		 */
		public $url = '';

		/**
		 * Previous requests (from redirects)
		 *
		 * @var array Array of \FinOrg\Requests\Response objects
		 */
		public $history = [];

		/**
		 * Cookies from the request
		 *
		 * @var array Array-like object representing a cookie jar
		 */
		public $cookies = [];
	}
}
