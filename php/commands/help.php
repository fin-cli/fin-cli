<?php

if ( ! class_exists( 'Help_Command' ) ) {
	require_once __DIR__ . '/src/Help_Command.php';
}

FIN_CLI::add_command( 'help', 'Help_Command' );
