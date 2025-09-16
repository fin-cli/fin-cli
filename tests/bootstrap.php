<?php

if ( ! defined( 'FIN_CLI_ROOT' ) ) {
	define( 'FIN_CLI_ROOT', dirname( __DIR__ ) );
}

if ( file_exists( FIN_CLI_ROOT . '/vendor/autoload.php' ) ) {
	define( 'FIN_CLI_VENDOR_DIR', FIN_CLI_ROOT . '/vendor' );
} elseif ( file_exists( dirname( dirname( FIN_CLI_ROOT ) ) . '/autoload.php' ) ) {
	define( 'FIN_CLI_VENDOR_DIR', dirname( dirname( FIN_CLI_ROOT ) ) );
}

require_once FIN_CLI_VENDOR_DIR . '/autoload.php';
require_once FIN_CLI_ROOT . '/php/utils.php';
require_once FIN_CLI_ROOT . '/bundle/rmccue/requests/src/Autoload.php';

require_once __DIR__ . '/includes/findb.php';

\FinOrg\Requests\Autoload::register();
