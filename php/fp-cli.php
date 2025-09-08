<?php

// Can be used by plugins/themes to check if FP-CLI is running or not.
define( 'FP_CLI', true );
define( 'FP_CLI_VERSION', trim( (string) file_get_contents( FP_CLI_ROOT . '/VERSION' ) ) );
define( 'FP_CLI_START_MICROTIME', microtime( true ) );

if ( file_exists( FP_CLI_ROOT . '/vendor/autoload.php' ) ) {
	define( 'FP_CLI_VENDOR_DIR', FP_CLI_ROOT . '/vendor' );
} elseif ( file_exists( dirname( dirname( FP_CLI_ROOT ) ) . '/autoload.php' ) ) {
	define( 'FP_CLI_VENDOR_DIR', dirname( dirname( FP_CLI_ROOT ) ) );
} elseif ( file_exists( dirname( FP_CLI_ROOT ) . '/vendor/autoload.php' ) ) {
	define( 'FP_CLI_VENDOR_DIR', dirname( FP_CLI_ROOT ) . '/vendor' );
} else {
	define( 'FP_CLI_VENDOR_DIR', FP_CLI_ROOT . '/vendor' );
}

require_once FP_CLI_ROOT . '/php/compat.php';

// Set common headers, to prevent warnings from plugins.
$_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.0';
$_SERVER['HTTP_USER_AGENT'] = ( ! empty( getenv( 'FP_CLI_USER_AGENT' ) ) ? getenv( 'FP_CLI_USER_AGENT' ) : 'FP CLI ' . FP_CLI_VERSION );
$_SERVER['REQUEST_METHOD']  = 'GET';
$_SERVER['REMOTE_ADDR']     = '127.0.0.1';

require_once FP_CLI_ROOT . '/php/bootstrap.php';

if ( getenv( 'FP_CLI_EARLY_REQUIRE' ) ) {
	foreach ( explode( ',', (string) getenv( 'FP_CLI_EARLY_REQUIRE' ) ) as $fp_cli_early_require ) {
		require_once trim( $fp_cli_early_require );
	}
	unset( $fp_cli_early_require );
}

FP_CLI\bootstrap();
