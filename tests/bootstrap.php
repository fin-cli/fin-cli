<?php

if ( ! defined( 'FP_CLI_ROOT' ) ) {
	define( 'FP_CLI_ROOT', dirname( __DIR__ ) );
}

if ( file_exists( FP_CLI_ROOT . '/vendor/autoload.php' ) ) {
	define( 'FP_CLI_VENDOR_DIR', FP_CLI_ROOT . '/vendor' );
} elseif ( file_exists( dirname( dirname( FP_CLI_ROOT ) ) . '/autoload.php' ) ) {
	define( 'FP_CLI_VENDOR_DIR', dirname( dirname( FP_CLI_ROOT ) ) );
}

require_once FP_CLI_VENDOR_DIR . '/autoload.php';
require_once FP_CLI_ROOT . '/php/utils.php';
require_once FP_CLI_ROOT . '/bundle/rmccue/requests/src/Autoload.php';

require_once __DIR__ . '/includes/fpdb.php';

\WpOrg\Requests\Autoload::register();
