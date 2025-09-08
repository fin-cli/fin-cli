<?php

if ( ! class_exists( 'CLI_Command' ) ) {
	require_once __DIR__ . '/src/CLI_Command.php';
}

if ( ! class_exists( 'CLI_Cache_Command' ) ) {
	require_once __DIR__ . '/src/CLI_Cache_Command.php';
}

if ( ! class_exists( 'CLI_Alias_Command' ) ) {
	require_once __DIR__ . '/src/CLI_Alias_Command.php';
}

FP_CLI::add_command( 'cli', 'CLI_Command' );

FP_CLI::add_command( 'cli cache', 'CLI_Cache_Command' );

FP_CLI::add_command( 'cli alias', 'CLI_Alias_Command' );
