<?php

use \WP_CLI\Utils;
use \WP_CLI\Dispatcher;

/**
 * Wrapper class for WP-CLI
 *
 * @package wp-cli
 */
class WP_CLI {

	public static $root;

	private static $man_dirs = array();

	private static $config;

	private static $arguments, $assoc_args;

	/**
	 * Add a command to the wp-cli list of commands
	 *
	 * @param string $name The name of the command that will be used in the cli
	 * @param string|object $implementation The command implementation
	 */
	static function add_command( $name, $implementation ) {
		self::$root->add_command( $name, $implementation );
	}

	static function add_man_dir( $dest_dir, $src_dir ) {
		$dest_dir = realpath( $dest_dir ) . '/';

		if ( $src_dir )
			$src_dir = realpath( $src_dir ) . '/';

		self::$man_dirs[ $dest_dir ] = $src_dir;
	}

	static function get_man_dirs() {
		return self::$man_dirs;
	}

	/**
	 * Display a message in the cli
	 *
	 * @param string $message
	 */
	static function out( $message, $handle = STDOUT ) {
		if ( WP_CLI_QUIET )
			return;

		fwrite( $handle, \cli\Colors::colorize( $message, ! \cli\Shell::isPiped() ) );
	}

	/**
	 * Display a message in the CLI and end with a newline
	 *
	 * @param string $message
	 */
	static function line( $message = '' ) {
		self::out( $message . "\n" );
	}

	/**
	 * Display an error in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param bool $exit
	 */
	static function error( $message, $exit = true ) {
		if ( !isset( self::$config['completions'] ) ) {
			$label = 'Error';
			$msg = '%R' . $label . ': %n' . self::error_to_string( $message );
			self::out( $msg . "\n", STDERR );
		}

		if ( $exit )
			exit(1);
	}

	/**
	 * Display a success in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function success( $message, $label = 'Success' ) {
		if ( WP_CLI_QUIET )
			return;

		self::line( '%G' . $label . ': %n' . $message );
	}

	/**
	 * Display a warning in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function warning( $message, $label = 'Warning' ) {
		if ( WP_CLI_QUIET )
			return;

		$msg = '%C' . $label . ': %n' . self::error_to_string( $message );
		self::out( $msg . "\n", STDERR );
	}

	/**
	 * Ask for confirmation before running a destructive operation.
	 */
	static function confirm( $question, $assoc_args ) {
		if ( !isset( $assoc_args['yes'] ) ) {
			self::out( $question . " [y/n] " );

			$answer = trim( fgets( STDIN ) );

			if ( 'y' != $answer )
				exit;
		}
	}

	/**
	 * Read a value, from various formats
	 *
	 * @param mixed $value
	 * @param array $assoc_args
	 */
	static function read_value( $value, $assoc_args = array() ) {
		if ( isset( $assoc_args['json'] ) ) {
			$value = json_decode( $value, true );
		}

		return $value;
	}

	/**
	 * Display a value, in various formats
	 *
	 * @param mixed $value
	 * @param array $assoc_args
	 */
	static function print_value( $value, $assoc_args = array() ) {
		if ( isset( $assoc_args['json'] ) ) {
			$value = json_encode( $value );
		} elseif ( is_array( $value ) || is_object( $value ) ) {
			$value = var_export( $value );
		}

		echo $value . "\n";
	}

	/**
	 * Convert a wp_error into a string
	 *
	 * @param mixed $errors
	 * @return string
	 */
	static function error_to_string( $errors ) {
		if( is_string( $errors ) ) {
			return $errors;
		} elseif( is_wp_error( $errors ) && $errors->get_error_code() ) {
			foreach( $errors->get_error_messages() as $message ) {
				if( $errors->get_error_data() )
					return $message . ' ' . $errors->get_error_data();
				else
					return $message;
			}
		}
	}

	/**
	 * Composes positional and associative arguments into a string.
	 *
	 * @param array
	 * @return string
	 */
	static function compose_args( $args, $assoc_args = array() ) {
		$str = ' ' . implode( ' ', array_map( 'escapeshellarg', $args ) );

		foreach ( $assoc_args as $key => $value ) {
			if ( true === $value )
				$str .= " --$key";
			else
				$str .= " --$key=" . escapeshellarg( $value );
		}

		return $str;
	}

	/**
	 * Launch an external process that takes over I/O.
	 *
	 * @param string Command to call
	 * @param bool Whether to exit if the command returns an error status
	 *
	 * @return int The command exit status
	 */
	static function launch( $command, $exit_on_error = true ) {
		$r = proc_close( proc_open( $command, array( STDIN, STDOUT, STDERR ), $pipes ) );

		if ( $r && $exit_on_error )
			exit($r);

		return $r;
	}

	private static function parse_args() {
		$r = Utils\parse_args( array_slice( $GLOBALS['argv'], 1 ) );

		list( self::$arguments, self::$assoc_args ) = $r;

		// foo --help  ->  help foo
		if ( isset( self::$assoc_args['help'] ) ) {
			array_unshift( self::$arguments, 'help' );
			unset( self::$assoc_args['help'] );
		}

		// {plugin|theme} update --all  ->  {plugin|theme} update-all
		if ( count( self::$arguments ) > 1 && in_array( self::$arguments[0], array( 'plugin', 'theme' ) )
			&& self::$arguments[1] == 'update'
			&& isset( self::$assoc_args['all'] )
		) {
			self::$arguments[1] = 'update-all';
			unset( self::$assoc_args['all'] );
		}

		self::split_special( array(
			'path', 'url', 'blog', 'user', 'require',
			'quiet', 'completions', 'man', 'syn-list'
		) );
	}

	private static function split_special( $special_keys ) {
		foreach ( $special_keys as $key ) {
			if ( isset( self::$assoc_args[ $key ] ) ) {
				self::$config[ $key ] = self::$assoc_args[ $key ];
				unset( self::$assoc_args[ $key ] );
			}
		}
	}

	static function get_config() {
		return self::$config;
	}

	static function before_wp_load() {
		self::$root = new Dispatcher\RootCommand;

		self::add_man_dir(
			WP_CLI_ROOT . "../man/",
			WP_CLI_ROOT . "../man-src/"
		);

		self::$config = Utils\load_config( array(
			'path', 'url', 'user'
		) );

		self::parse_args();

		define( 'WP_CLI_QUIET', isset( self::$config['quiet'] ) );

		// Handle --version parameter
		if ( isset( self::$assoc_args['version'] ) && empty( self::$arguments ) ) {
			self::line( 'wp-cli ' . WP_CLI_VERSION );
			exit;
		}

		// Handle --info parameter
		if ( isset( self::$assoc_args['info'] ) && empty( self::$arguments ) ) {
			self::show_info();
			exit;
		}

		$_SERVER['DOCUMENT_ROOT'] = getcwd();

		// Handle --path
		Utils\set_wp_root( self::$config );

		// Handle --url and --blog parameters
		Utils\set_url( self::$config );

		if ( array( 'core', 'download' ) == self::$arguments ) {
			self::run_command();
			exit;
		}

		if ( !is_readable( WP_ROOT . 'wp-load.php' ) ) {
			WP_CLI::error( "This does not seem to be a WordPress install.", false );
			WP_CLI::line( "Pass --path=`path/to/wordpress` or run `wp core download`." );
			exit(1);
		}

		if ( array( 'core', 'config' ) == self::$arguments ) {
			self::run_command();
			exit;
		}

		if ( !Utils\locate_wp_config() ) {
			WP_CLI::error( "wp-config.php not found.", false );
			WP_CLI::line( "Either create one manually or use `wp core config`." );
			exit(1);
		}

		if ( self::cmd_starts_with( array( 'db' ) ) ) {
			Utils\load_wp_config();
			self::run_command();
			exit;
		}

		if (
			self::cmd_starts_with( array( 'core', 'install' ) ) ||
			self::cmd_starts_with( array( 'core', 'is-installed' ) )
		) {
			define( 'WP_INSTALLING', true );

			if ( !isset( $_SERVER['HTTP_HOST'] ) ) {
				Utils\set_url_params( 'http://example.com' );
			}
		}

		// Pretend we're in WP_ADMIN, to side-step full-page caching plugins
		define( 'WP_ADMIN', true );
		$_SERVER['PHP_SELF'] = '/wp-admin/index.php';
	}

	private static function cmd_starts_with( $prefix ) {
		return $prefix == array_slice( self::$arguments, 0, count( $prefix  ) );
	}

	static function after_wp_load() {
		require WP_CLI_ROOT . 'utils-wp.php';

		add_filter( 'filesystem_method', function() { return 'direct'; }, 99 );

		Utils\set_user( self::$config );

		if ( !defined( 'WP_INSTALLING' ) && isset( self::$config['url'] ) )
			Utils\set_wp_query();

		if ( isset( self::$config['require'] ) )
			require self::$config['require'];

		if ( isset( self::$config['man'] ) ) {
			self::generate_man( self::$arguments );
			exit;
		}

		// Handle --syn-list parameter
		if ( isset( self::$config['syn-list'] ) ) {
			foreach ( self::$root->get_subcommands() as $command ) {
				if ( $command instanceof Dispatcher\Composite ) {
					foreach ( $command->get_subcommands() as $subcommand )
						$subcommand->show_usage( '' );
				} else {
					$command->show_usage( '' );
				}
			}
			exit;
		}

		if ( isset( self::$config['completions'] ) ) {
			self::render_automcomplete();
			exit;
		}

		self::run_command();
	}

	private static function run_command() {
		$command = Dispatcher\traverse( self::$arguments, 'pre_invoke' );
		$command->invoke( self::$arguments, self::$assoc_args );
	}

	private static function show_info() {
		$php_bin = defined( 'PHP_BINARY' ) ? PHP_BINARY : getenv( 'WP_CLI_PHP_USED' );

		WP_CLI::line( "PHP binary:\t" . $php_bin );
		WP_CLI::line( "PHP version:\t" . PHP_VERSION );
		WP_CLI::line( "php.ini used:\t" . get_cfg_var( 'cfg_file_path' ) );
		WP_CLI::line( "wp-cli root:\t" . WP_CLI_ROOT );
		WP_CLI::line( "wp-cli version:\t" . WP_CLI_VERSION );
	}

	private static function generate_man( $args ) {
		$command = Dispatcher\traverse( $args );
		if ( !$command )
			WP_CLI::error( sprintf( "'%s' command not found." ) );

		foreach ( self::$man_dirs as $dest_dir => $src_dir ) {
			\WP_CLI\Man\generate( $src_dir, $dest_dir, $command );
		}
	}

	private static function render_automcomplete() {
		foreach ( self::$root->get_subcommands() as $name => $command ) {
			$subcommands = $command->get_subcommands();

			self::line( $name . ' ' . implode( ' ', array_keys( $subcommands ) ) );
		}
	}

	// back-compat
	static function addCommand( $name, $class ) {
		self::add_command( $name, $class );
	}
}

