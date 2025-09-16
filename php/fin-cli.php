<?php

// Can be used by plugins/themes to check if FIN-CLI is running or not.
define( 'FIN_CLI', true );
define( 'FIN_CLI_VERSION', trim( (string) file_get_contents( FIN_CLI_ROOT . '/VERSION' ) ) );
define( 'FIN_CLI_START_MICROTIME', microtime( true ) );

if ( file_exists( FIN_CLI_ROOT . '/vendor/autoload.php' ) ) {
	define( 'FIN_CLI_VENDOR_DIR', FIN_CLI_ROOT . '/vendor' );
} elseif ( file_exists( dirname( dirname( FIN_CLI_ROOT ) ) . '/autoload.php' ) ) {
	define( 'FIN_CLI_VENDOR_DIR', dirname( dirname( FIN_CLI_ROOT ) ) );
} elseif ( file_exists( dirname( FIN_CLI_ROOT ) . '/vendor/autoload.php' ) ) {
	define( 'FIN_CLI_VENDOR_DIR', dirname( FIN_CLI_ROOT ) . '/vendor' );
} else {
	define( 'FIN_CLI_VENDOR_DIR', FIN_CLI_ROOT . '/vendor' );
}

require_once FIN_CLI_ROOT . '/php/compat.php';

// Set common headers, to prevent warnings from plugins.
$_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.0';
$_SERVER['HTTP_USER_AGENT'] = ( ! empty( getenv( 'FIN_CLI_USER_AGENT' ) ) ? getenv( 'FIN_CLI_USER_AGENT' ) : 'FIN CLI ' . FIN_CLI_VERSION );
$_SERVER['REQUEST_METHOD']  = 'GET';
$_SERVER['REMOTE_ADDR']     = '127.0.0.1';

require_once FIN_CLI_ROOT . '/php/bootstrap.php';

if ( getenv( 'FIN_CLI_EARLY_REQUIRE' ) ) {
	foreach ( explode( ',', (string) getenv( 'FIN_CLI_EARLY_REQUIRE' ) ) as $fin_cli_early_require ) {
		require_once trim( $fin_cli_early_require );
	}
	unset( $fin_cli_early_require );
}

FIN_CLI\bootstrap();
