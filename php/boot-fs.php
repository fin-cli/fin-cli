<?php

// This file needs to parse without error in PHP < 5.3

if ( 'cli' !== PHP_SAPI ) {
	echo "Only CLI access.\n";
	die( -1 );
}

if ( version_compare( PHP_VERSION, '7.2.24', '<' ) ) {
	printf( "Error: FIN-CLI requires PHP %s or newer. You are running version %s.\n", '7.2.24', PHP_VERSION );
	die( -1 );
}

define( 'FIN_CLI_ROOT', dirname( __DIR__ ) );

require_once FIN_CLI_ROOT . '/php/fin-cli.php';
