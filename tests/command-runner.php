<?php

class WP_CLI_Command_Runner {

	private $install_dir;

	public function __construct() {
		$this->install_dir = sys_get_temp_dir() . '/' . uniqid( "wp-cli-test-", TRUE );
		mkdir( $this->install_dir );
	}

	public function run( $command, $cwd = false ) {
		if ( !$cwd )
			$cwd = $this->install_dir;

		$wp_cli_path = getcwd() . "/bin/wp";

		$sh_command = "cd $cwd; $wp_cli_path $command";

		$process = proc_open( $sh_command, array(
			0 => STDIN,
			1 => array( 'pipe', 'w' ),
			2 => array( 'pipe', 'w' ),
		), $pipes );

		$stdout = stream_get_contents( $pipes[1] );
		fclose( $pipes[1] );

		$stderr = stream_get_contents( $pipes[2] );
		fclose( $pipes[2] );

		$return_code = proc_close( $process );

		return (object) compact( 'return_code', 'stdout', 'stderr' );
	}

	public function create_config( $db_settings ) {
		return $this->run( 'core config' . \WP_CLI\Utils\assoc_args_to_str( $db_settings ) );
	}

	public function define_custom_wp_content_dir() {
		$wp_config_path = $this->install_dir . '/wp-config.php';

		$wp_config_code = file_get_contents( $wp_config_path );

		$this->add_line_to_wp_config( $wp_config_code,
			"define( 'WP_CONTENT_DIR', dirname(__FILE__) . '/my-content' );" );

		$this->move_files( 'wp-content', 'my-content' );

		$this->add_line_to_wp_config( $wp_config_code,
			"define( 'WP_PLUGIN_DIR', __DIR__ . '/my-plugins' );" );

		$this->move_files( 'my-content/plugins', 'my-plugins' );

		file_put_contents( $wp_config_path, $wp_config_code );
	}

	private function move_files( $src, $dest ) {
		rename(
			$this->install_dir . '/' . $src,
			$this->install_dir . '/' . $dest
		);
	}

	private function add_line_to_wp_config( &$wp_config_code, $line ) {
		$token = "/* That's all, stop editing!";

		$wp_config_code = str_replace( $token, "$line\n\n$token", $wp_config_code );
	}

	public function run_install() {
		$cmd = 'core install' . \WP_CLI\Utils\assoc_args_to_str( array(
			'url' => 'http://example.com',
			'title' => 'WP CLI Tests',
			'admin_email' => 'admin@example.com',
			'admin_password' => 'password1'
		) );

		return $this->run( $cmd );
	}

	public function download_wordpress_files() {
		// We cache the results of "wp core download" to improve test performance
		// Ideally, we'd cache at the HTTP layer for more reliable tests
		$cache_dir = sys_get_temp_dir() . '/wp-cli-test-core-download-cache';
		if ( !file_exists( $cache_dir ) ) {
			mkdir( $cache_dir );
			$this->run( "core download", $cache_dir );
		}

		exec( "cp -r '$cache_dir/'* '$this->install_dir/'" );
	}
}
