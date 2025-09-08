<?php

namespace FP_CLI;

use FP_CLI;
use FP_CLI\Dispatcher;
use FP_CLI\Dispatcher\CompositeCommand;
use FP_CLI\Dispatcher\Subcommand;
use FP_CLI\Fetchers;
use FP_CLI\Iterators\Exception;
use FP_CLI\Loggers;
use FP_CLI\Utils;
use FP_Error;

/**
 * Performs the execution of a command.
 *
 * @property-read string         $global_config_path
 * @property-read string         $project_config_path
 * @property-read array          $config
 * @property-read array          $extra_config
 * @property-read ContextManager $context_manager
 * @property-read string         $alias
 * @property-read array          $aliases
 * @property-read array          $arguments
 * @property-read array          $assoc_args
 * @property-read array          $runtime_config
 * @property-read bool           $colorize
 * @property-read array          $early_invoke
 * @property-read string         $global_config_path_debug
 * @property-read string         $project_config_path_debug
 * @property-read array          $required_files
 *
 * @package FP_CLI
 */
class Runner {

	/**
	 * List of byte-order marks (BOMs) to detect.
	 *
	 * @var array<string, string>
	 */
	const BYTE_ORDER_MARKS = [
		'UTF-8'       => "\xEF\xBB\xBF",
		'UTF-16 (BE)' => "\xFE\xFF",
		'UTF-16 (LE)' => "\xFF\xFE",
	];

	private $global_config_path;
	private $project_config_path;

	private $config;
	private $extra_config;

	private $context_manager;

	private $alias;

	private $aliases;

	private $arguments;
	private $assoc_args;
	private $runtime_config;

	private $colorize = false;

	private $early_invoke = [];

	private $global_config_path_debug;

	private $project_config_path_debug;

	private $required_files;

	public function __get( $key ) {
		if ( '_' === $key[0] ) {
			return null;
		}

		return $this->$key;
	}

	public function register_context_manager( ContextManager $context_manager ) {
		$this->context_manager = $context_manager;
	}

	/**
	 * Register a command for early invocation, generally before FinPress loads.
	 *
	 * @param string $when Named execution hook
	 * @param Subcommand $command
	 */
	public function register_early_invoke( $when, $command ) {
		$cmd_path     = array_slice( Dispatcher\get_path( $command ), 1 );
		$command_name = implode( ' ', $cmd_path );
		FP_CLI::debug( "Attaching command '{$command_name}' to hook {$when}", 'bootstrap' );
		$this->early_invoke[ $when ][] = $cmd_path;
		if ( $command->get_alias() ) {
			array_pop( $cmd_path );
			$cmd_path[] = $command->get_alias();
			$alias_name = implode( ' ', $cmd_path );
			FP_CLI::debug( "Attaching command alias '{$alias_name}' to hook {$when}", 'bootstrap' );
			$this->early_invoke[ $when ][] = $cmd_path;
		}
	}

	/**
	 * Perform the early invocation of a command.
	 *
	 * @param string $when Named execution hook
	 */
	private function do_early_invoke( $when ): void {
		FP_CLI::debug( "Executing hook: {$when}", 'hooks' );
		if ( ! isset( $this->early_invoke[ $when ] ) ) {
			return;
		}

		// Search the value of @when from the command method.
		$real_when = '';
		$r         = $this->find_command_to_run( $this->arguments );
		if ( is_array( $r ) ) {
			list( $command, $final_args, $cmd_path ) = $r;

			foreach ( $this->early_invoke as $_when => $_path ) {
				foreach ( $_path as $cmd ) {
					if ( $cmd === $cmd_path ) {
						$real_when = $_when;
					}
				}
			}
		}

		foreach ( $this->early_invoke[ $when ] as $path ) {
			if ( $this->cmd_starts_with( $path ) ) {
				if ( empty( $real_when ) || $real_when === $when ) {
					$this->run_command_and_exit();
				}
			}
		}
	}

	/**
	 * Get the path to the global configuration YAML file.
	 *
	 * @param bool $create_config_file Optional. If a config file doesn't exist,
	 *                                 should it be created? Defaults to false.
	 *
	 * @return string|false
	 */
	public function get_global_config_path( $create_config_file = false ) {
		$fp_cli_config_path = (string) getenv( 'FP_CLI_CONFIG_PATH' );

		if ( $fp_cli_config_path ) {
			$config_path                    = $fp_cli_config_path;
			$this->global_config_path_debug = 'Using global config from FP_CLI_CONFIG_PATH env var: ' . $config_path;
		} else {
			$config_path                    = Utils\get_home_dir() . '/.fp-cli/config.yml';
			$this->global_config_path_debug = 'Using default global config: ' . $config_path;
		}

		// If global config doesn't exist create one.
		if ( true === $create_config_file && ! file_exists( $config_path ) ) {
			$this->global_config_path_debug = "Default global config doesn't exist, creating one in {$config_path}";

			$dir = dirname( $config_path );

			if ( ! is_dir( $dir ) ) {
				mkdir( $dir, 0755, true );
			}

			touch( $config_path );

			if ( file_exists( $config_path ) ) {
				FP_CLI::debug( "Default global config does not exist, creating one in $config_path" );
			}
		}

		if ( is_readable( $config_path ) ) {
			return $config_path;
		}

		$this->global_config_path_debug = 'No readable global config found';

		return false;
	}

	/**
	 * Get the path to the project-specific configuration
	 * YAML file.
	 * fp-cli.local.yml takes priority over fp-cli.yml.
	 *
	 * @return string|false
	 */
	public function get_project_config_path() {
		$config_files = [
			'fp-cli.local.yml',
			'fp-cli.yml',
		];

		// Stop looking upward when we find we have emerged from a subdirectory
		// installation into a parent installation
		$project_config_path = Utils\find_file_upward(
			$config_files,
			(string) getcwd(),
			static function ( $dir ) {
				static $fp_load_count = 0;
				$fp_load_path         = $dir . DIRECTORY_SEPARATOR . 'fp-load.php';
				if ( file_exists( $fp_load_path ) ) {
					++$fp_load_count;
				}
				return $fp_load_count > 1;
			}
		);

		if ( null === $project_config_path ) {
			$this->project_config_path_debug = 'No project config found';
			return false;
		}

		$this->project_config_path_debug = 'Using project config: ' . $project_config_path;
		return $project_config_path;
	}

	/**
	 * Get the path to the packages directory
	 *
	 * @return string
	 */
	public function get_packages_dir_path() {
		$packages_dir = (string) getenv( 'FP_CLI_PACKAGES_DIR' );
		if ( $packages_dir ) {
			$packages_dir = Utils\trailingslashit( $packages_dir );
		} else {
			$packages_dir = Utils\get_home_dir() . '/.fp-cli/packages/';
		}
		return $packages_dir;
	}

	/**
	 * Attempts to find the path to the FP installation inside index.php
	 *
	 * @param string $index_path
	 * @return string|false
	 */
	private static function extract_subdir_path( $index_path ) {
		$index_code = (string) file_get_contents( $index_path );

		if ( ! preg_match( '|^\s*require\s*\(?\s*(.+?)/fp-blog-header\.php([\'"])|m', $index_code, $matches ) ) {
			return false;
		}

		$fp_path_src = $matches[1] . $matches[2];
		$fp_path_src = Utils\replace_path_consts( $fp_path_src, $index_path );

		$fp_path = eval( "return $fp_path_src;" ); // phpcs:ignore Squiz.PHP.Eval.Discouraged

		if ( ! Utils\is_path_absolute( $fp_path ) ) {
			$fp_path = dirname( $index_path ) . "/$fp_path";
		}

		return $fp_path;
	}

	/**
	 * Find the directory that contains the FinPress files.
	 * Defaults to the current working dir.
	 *
	 * @return string An absolute path.
	 */
	public function find_fp_root() {
		if ( isset( $this->config['path'] ) &&
			( is_bool( $this->config['path'] ) || empty( $this->config['path'] ) )
		) {
			FP_CLI::error( 'The --path parameter cannot be empty when provided.' );
		}

		if ( ! empty( $this->config['path'] ) ) {
			$path = $this->config['path'];
			if ( ! Utils\is_path_absolute( $path ) ) {
				$path = getcwd() . '/' . $path;
			}

			return $path;
		}

		if ( $this->cmd_starts_with( [ 'core', 'download' ] ) ) {
			return (string) getcwd();
		}

		$dir = (string) getcwd();

		while ( is_readable( $dir ) ) {
			if ( file_exists( "$dir/fp-load.php" ) ) {
				return $dir;
			}

			if ( file_exists( "$dir/index.php" ) ) {
				$path = self::extract_subdir_path( "$dir/index.php" );
				if ( ! empty( $path ) ) {
					return $path;
				}
			}

			$parent_dir = dirname( $dir );
			if ( empty( $parent_dir ) || $parent_dir === $dir ) {
				break;
			}
			$dir = $parent_dir;
		}

		return (string) getcwd();
	}

	/**
	 * Set FinPress root as a given path.
	 *
	 * @param string $path
	 */
	private static function set_fp_root( $path ) {
		if ( ! defined( 'ABSPATH' ) ) {
			// phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedConstantFound -- Declaring a FP native constant.
			define( 'ABSPATH', Utils\normalize_path( Utils\trailingslashit( $path ) ) );
		} elseif ( ! is_null( $path ) ) {
			FP_CLI::error_multi_line(
				[
					'The --path parameter cannot be used when ABSPATH is already defined elsewhere',
					'ABSPATH is defined as: "' . ABSPATH . '"',
				]
			);
		}
		FP_CLI::debug( 'ABSPATH defined: ' . ABSPATH, 'bootstrap' );

		$_SERVER['DOCUMENT_ROOT'] = realpath( $path );
	}

	/**
	 * Guess which URL context FP-CLI has been invoked under.
	 *
	 * @param array $assoc_args
	 * @return string|false
	 */
	private static function guess_url( $assoc_args ) {
		if ( isset( $assoc_args['blog'] ) ) {
			$assoc_args['url'] = $assoc_args['blog'];
		}

		if ( isset( $assoc_args['url'] ) ) {
			$url = $assoc_args['url'];

			if ( true === $url ) {
				FP_CLI::warning( 'The --url parameter expects a value.' );
			}

			return $url;
		}

		return false;
	}

	/**
	 * Checks if the arguments passed to the FP-CLI binary start with the specified prefix.
	 *
	 * @param array $prefix An array of strings specifying the expected start of the arguments passed to the FP-CLI binary.
	 *                      For example, `['user', 'list']` checks if the arguments passed to the FP-CLI binary start with `user list`.
	 *
	 * @return bool `true` if the arguments passed to the FP-CLI binary start with the specified prefix, `false` otherwise.
	 */
	private function cmd_starts_with( $prefix ): bool {
		return array_slice( $this->arguments, 0, count( $prefix ) ) === $prefix;
	}

	/**
	 * Given positional arguments, find the command to execute.
	 *
	 * @param array $args
	 * @return array|string Command, args, and path on success; error message on failure
	 */
	public function find_command_to_run( $args ) {
		$command = FP_CLI::get_root_command();

		FP_CLI::do_hook( 'find_command_to_run_pre' );

		$cmd_path = [];

		while ( ! empty( $args ) && $command->can_have_subcommands() ) {
			$cmd_path[] = $args[0];
			$full_name  = implode( ' ', $cmd_path );

			$subcommand = $command->find_subcommand( $args );

			if ( ! $subcommand ) {
				if ( count( $cmd_path ) > 1 ) {
					$child       = array_pop( $cmd_path );
					$parent_name = implode( ' ', $cmd_path );
					$suggestion  = $this->get_subcommand_suggestion( $child, $command );

					if ( 'network' === $parent_name && 'option' === $child ) {
						$suggestion = 'meta';
					}

					return sprintf(
						"'%s' is not a registered subcommand of '%s'. See 'fp help %s' for available subcommands.%s",
						$child,
						$parent_name,
						$parent_name,
						! empty( $suggestion ) ? PHP_EOL . "Did you mean '{$suggestion}'?" : ''
					);
				}

				$suggestion = $this->get_subcommand_suggestion( $full_name, $command );

				// If the functions are available, it means FinPress is available
				// and has already been loaded.
				if ( function_exists( '\taxonomy_exists' ) ) {
					if ( \taxonomy_exists( $cmd_path[0] ) ) {
						$suggestion = 'fp term <command>';
					} elseif ( \post_type_exists( $cmd_path[0] ) ) {
						$suggestion = "fp post --post_type={$cmd_path[0]} <command>";
					}
				}

				return sprintf(
					"'%s' is not a registered fp command. See 'fp help' for available commands.%s",
					$full_name,
					! empty( $suggestion ) ? PHP_EOL . "Did you mean '{$suggestion}'?" : ''
				);
			}

			if ( $this->is_command_disabled( $subcommand ) ) {
				return sprintf(
					"The '%s' command has been disabled from the config file.",
					$full_name
				);
			}

			$command = $subcommand;
		}

		return [ $command, $args, $cmd_path ];
	}

	/**
	 * Find the FP-CLI command to run given arguments, and invoke it.
	 *
	 * @param array $args        Positional arguments including command name
	 * @param array $assoc_args  Associative arguments for the command.
	 * @param array $options     Configuration options for the function.
	 */
	public function run_command( $args, $assoc_args = [], $options = [] ) {
		FP_CLI::do_hook( 'before_run_command', $args, $assoc_args, $options );

		if ( ! empty( $options['back_compat_conversions'] ) ) {
			list( $args, $assoc_args ) = self::back_compat_conversions( $args, $assoc_args );
		}
		$r = $this->find_command_to_run( $args );
		if ( is_string( $r ) ) {
			FP_CLI::error( $r );
		}

		list( $command, $final_args, $cmd_path ) = $r;

		$name = implode( ' ', $cmd_path );

		$extra_args = [];

		if ( isset( $this->extra_config[ $name ] ) ) {
			$extra_args = $this->extra_config[ $name ];
		}

		FP_CLI::debug( 'Running command: ' . $name, 'bootstrap' );
		try {
			$command->invoke( $final_args, $assoc_args, $extra_args );
		} catch ( Exception $e ) {
			FP_CLI::error( $e->getMessage() );
		}
	}

	/**
	 * Show synopsis if the called command is a composite command
	 */
	public function show_synopsis_if_composite_command() {
		$r = $this->find_command_to_run( $this->arguments );
		if ( is_array( $r ) ) {
			list( $command ) = $r;

			if ( $command->can_have_subcommands() ) {
				$command->show_usage();
				exit;
			}
		}
	}

	private function run_command_and_exit( $help_exit_warning = '' ): void {
		$this->show_synopsis_if_composite_command();
		$this->run_command( $this->arguments, $this->assoc_args );
		if ( $this->cmd_starts_with( [ 'help' ] ) ) {
			// Help couldn't find the command so exit with suggestion.
			$suggestion_or_disabled = $this->find_command_to_run( array_slice( $this->arguments, 1 ) );
			if ( is_string( $suggestion_or_disabled ) ) {
				if ( $help_exit_warning ) {
					FP_CLI::warning( $help_exit_warning );
				}
				FP_CLI::error( $suggestion_or_disabled );
			}
			// Should never get here.
		}
		exit;
	}

	/**
	 * Perform a command against a remote server over SSH (or a container using
	 * scheme of "docker", "docker-compose", or "docker-compose-run").
	 *
	 * @param string $connection_string Passed connection string.
	 */
	private function run_ssh_command( $connection_string ): void {

		FP_CLI::do_hook( 'before_ssh' );

		$bits = Utils\parse_ssh_url( $connection_string );

		$pre_cmd = getenv( 'FP_CLI_SSH_PRE_CMD' );
		if ( $pre_cmd ) {
			FP_CLI::warning( "FP_CLI_SSH_PRE_CMD found, executing the following command(s) on the remote machine:\n $pre_cmd" );

			$pre_cmd = rtrim( $pre_cmd, ';' ) . '; ';
		}

		$env_vars = '';
		if ( getenv( 'FP_CLI_STRICT_ARGS_MODE' ) ) {
			$env_vars .= 'FP_CLI_STRICT_ARGS_MODE=1 ';
		}

		$fp_binary = getenv( 'FP_CLI_SSH_BINARY' ) ?: 'fp';
		$fp_args   = array_slice( $GLOBALS['argv'], 1 );

		if ( $this->alias && ! empty( $fp_args[0] ) && $this->alias === $fp_args[0] ) {
			array_shift( $fp_args );
			$runtime_alias = [];
			foreach ( $this->aliases[ $this->alias ] as $key => $value ) {
				if ( 'ssh' === $key ) {
					continue;
				}
				$runtime_alias[ $key ] = $value;
			}
			if ( ! empty( $runtime_alias ) ) {
				$encoded_alias = json_encode(
					[
						$this->alias => $runtime_alias,
					]
				);
				$fp_binary     = "FP_CLI_RUNTIME_ALIAS='{$encoded_alias}' {$fp_binary} {$this->alias}";
			}
		}

		foreach ( $fp_args as $k => $v ) {
			if ( preg_match( '#--ssh=#', $v ) ) {
				unset( $fp_args[ $k ] );
			}
		}

		$fp_command = $pre_cmd . $env_vars . $fp_binary . ' ' . implode( ' ', array_map( 'escapeshellarg', $fp_args ) );

		if ( isset( $bits['scheme'] ) && 'docker-compose-run' === $bits['scheme'] ) {
			$fp_command = implode( ' ', $fp_args );
		}

		$escaped_command = $this->generate_ssh_command( $bits, $fp_command );

		passthru( $escaped_command, $exit_code );
		if ( 255 === $exit_code ) {
			FP_CLI::error( 'Cannot connect over SSH using provided configuration.', 255 );
		} else {
			exit( $exit_code );
		}
	}

	/**
	 * Generate a shell command from the parsed connection string.
	 *
	 * @param array $bits Parsed connection string.
	 * @param string $fp_command FP-CLI command to run.
	 * @return string
	 */
	private function generate_ssh_command( $bits, $fp_command ) {
		$escaped_command = '';

		// Set default values.
		foreach ( [ 'scheme', 'user', 'host', 'port', 'path', 'key', 'proxyjump' ] as $bit ) {
			if ( ! isset( $bits[ $bit ] ) ) {
				$bits[ $bit ] = null;
			}

			FP_CLI::debug( 'SSH ' . $bit . ': ' . $bits[ $bit ], 'bootstrap' );
		}

		/**
		 * @var array{scheme: string|null, user: string|null, host: string, port: int|null, path: string|null, key: string|null, proxyjump: string|null} $bits
		 */

		/*
		 * posix_isatty(STDIN) is generally true unless something was passed on stdin
		 * If autodetection leads to false (fd on stdin), then `-i` is passed to `docker` cmd
		 * (unless FP_CLI_DOCKER_NO_INTERACTIVE is set)
		 */
		$is_stdout_tty = function_exists( 'posix_isatty' ) && posix_isatty( STDOUT );
		$is_stdin_tty  = function_exists( 'posix_isatty' ) ? posix_isatty( STDIN ) : true;

		$docker_compose_v2_version_cmd = Utils\esc_cmd( Utils\force_env_on_nix_systems( 'docker' ) . ' compose %s', 'version' );
		$docker_compose_cmd            = ! empty( Process::create( $docker_compose_v2_version_cmd )->run()->stdout )
				? 'docker compose'
				: 'docker-compose';

		if ( 'docker' === $bits['scheme'] ) {
			$command = 'docker exec %s%s%s%s%s sh -c %s';

			$escaped_command = sprintf(
				$command,
				$bits['user'] ? '--user ' . escapeshellarg( $bits['user'] ) . ' ' : '',
				$bits['path'] ? '--workdir ' . escapeshellarg( $bits['path'] ) . ' ' : '',
				$is_stdout_tty && ! getenv( 'FP_CLI_DOCKER_NO_TTY' ) ? '-t  ' : '',
				$is_stdin_tty || getenv( 'FP_CLI_DOCKER_NO_INTERACTIVE' ) ? '' : '-i ',
				escapeshellarg( $bits['host'] ),
				escapeshellarg( $fp_command )
			);
		}

		if ( 'docker-compose' === $bits['scheme'] ) {
			$command = '%s exec %s%s%s%s sh -c %s';

			$escaped_command = sprintf(
				$command,
				$docker_compose_cmd,
				$bits['user'] ? '--user ' . escapeshellarg( $bits['user'] ) . ' ' : '',
				$bits['path'] ? '--workdir ' . escapeshellarg( $bits['path'] ) . ' ' : '',
				$is_stdout_tty || getenv( 'FP_CLI_DOCKER_NO_TTY' ) ? '' : '-T ',
				escapeshellarg( $bits['host'] ),
				escapeshellarg( $fp_command )
			);
		}

		if ( 'docker-compose-run' === $bits['scheme'] ) {
			$command = '%s run %s%s%s%s%s %s';

			$escaped_command = sprintf(
				$command,
				$docker_compose_cmd,
				$bits['user'] ? '--user ' . escapeshellarg( $bits['user'] ) . ' ' : '',
				$bits['path'] ? '--workdir ' . escapeshellarg( $bits['path'] ) . ' ' : '',
				$is_stdout_tty || getenv( 'FP_CLI_DOCKER_NO_TTY' ) ? '' : '-T ',
				$is_stdin_tty || getenv( 'FP_CLI_DOCKER_NO_INTERACTIVE' ) ? '' : '-i ',
				escapeshellarg( $bits['host'] ),
				$fp_command
			);
		}

		// For "vagrant" & "ssh" schemes which don't provide a working-directory option, use `cd`
		if ( $bits['path'] ) {
			$fp_command = 'cd ' . escapeshellarg( $bits['path'] ) . '; ' . $fp_command;
		}

		// Vagrant ssh-config.
		if ( 'vagrant' === $bits['scheme'] ) {
			$cache     = FP_CLI::get_cache();
			$cache_key = 'vagrant:' . $this->project_config_path;
			if ( $cache->has( $cache_key ) ) {
				$cached = (string) $cache->read( $cache_key );
				$values = json_decode( $cached, true );
			} else {
				$ssh_config = (string) shell_exec( 'vagrant ssh-config 2>/dev/null' );
				if ( preg_match_all( '#\s*(?<NAME>[a-zA-Z]+)\s(?<VALUE>.+)\s*#', $ssh_config, $matches ) ) {
					$values = array_combine( $matches['NAME'], $matches['VALUE'] );
					$cache->write( $cache_key, (string) json_encode( $values ) );
				}
			}

			/**
			 * @var array{HostName?: string, Port?: int, User?: string, IdentityFile?: string} $values
			 */

			if ( empty( $bits['host'] ) || ( isset( $values['Host'] ) && $bits['host'] === $values['Host'] ) ) {
				$bits['scheme'] = 'ssh';
				$bits['host']   = isset( $values['HostName'] ) ? $values['HostName'] : '';
				$bits['port']   = isset( $values['Port'] ) ? $values['Port'] : '';
				$bits['user']   = isset( $values['User'] ) ? $values['User'] : '';
				$bits['key']    = isset( $values['IdentityFile'] ) ? $values['IdentityFile'] : '';
			}

			// If we could not resolve the bits still, fallback to just `vagrant ssh`
			if ( 'vagrant' === $bits['scheme'] ) {
				$command = 'vagrant ssh -c %s %s';

				$escaped_command = sprintf(
					$command,
					escapeshellarg( $fp_command ),
					escapeshellarg( $bits['host'] )
				);
			}
		}

		// Default scheme is SSH.
		if ( 'ssh' === $bits['scheme'] || null === $bits['scheme'] ) {
			$command = 'ssh %s %s %s';

			if ( $bits['user'] ) {
				$bits['host'] = $bits['user'] . '@' . $bits['host'];
			}

			if ( ! empty( $this->alias ) ) {
				$alias_config = isset( $this->aliases[ $this->alias ] ) ? $this->aliases[ $this->alias ] : false;

				if ( is_array( $alias_config ) ) {
					$bits['proxyjump'] = isset( $alias_config['proxyjump'] ) ? $alias_config['proxyjump'] : '';
					$bits['key']       = isset( $alias_config['key'] ) ? $alias_config['key'] : '';
				}
			}

			$command_args = [
				$bits['proxyjump'] ? sprintf( '-J %s', escapeshellarg( $bits['proxyjump'] ) ) : '',
				$bits['port'] ? sprintf( '-p %d', (int) $bits['port'] ) : '',
				$bits['key'] ? sprintf( '-i %s', escapeshellarg( $bits['key'] ) ) : '',
				$is_stdout_tty ? '-t' : '-T',
				FP_CLI::get_config( 'debug' ) ? '-vvv' : '-q',
			];

			$escaped_command = sprintf(
				$command,
				implode( ' ', array_filter( $command_args ) ),
				escapeshellarg( $bits['host'] ),
				escapeshellarg( $fp_command )
			);
		}

		FP_CLI::debug( 'Running SSH command: ' . $escaped_command, 'bootstrap' );

		return $escaped_command;
	}

	/**
	 * Check whether a given command is disabled by the config.
	 *
	 * @return bool
	 */
	public function is_command_disabled( $command ) {
		$path = implode( ' ', array_slice( Dispatcher\get_path( $command ), 1 ) );
		return in_array( $path, $this->config['disabled_commands'], true );
	}

	/**
	 * Returns fp-config.php code, skipping the loading of fp-settings.php.
	 *
	 * @param string $fp_config_path Optional. Config file path. If left empty, it tries to
	 *                               locate the fp-config.php file automatically.
	 *
	 * @return string
	 */
	public function get_fp_config_code( $fp_config_path = '' ) {
		if ( empty( $fp_config_path ) ) {
			$fp_config_path = Utils\locate_fp_config();
		}

		$fp_config_code = (string) file_get_contents( $fp_config_path );

		// Detect and strip byte-order marks (BOMs).
		// This code assumes they can only be found on the first line.
		foreach ( self::BYTE_ORDER_MARKS as $bom_name => $bom_sequence ) {
			FP_CLI::debug( "Looking for {$bom_name} BOM", 'bootstrap' );

			$length = strlen( $bom_sequence );

			while ( substr( $fp_config_code, 0, $length ) === $bom_sequence ) {
				FP_CLI::warning(
					"{$bom_name} byte-order mark (BOM) detected in fp-config.php file, stripping it for parsing."
				);

				$fp_config_code = substr( $fp_config_code, $length );
			}
		}

		$count = 0;

		$fp_config_code = (string) preg_replace( '/\s*require(?:_once)?\s*.*fp-settings\.php.*\s*;/', '', $fp_config_code, -1, $count );

		if ( 0 === $count ) {
			FP_CLI::error( 'Strange fp-config.php file: fp-settings.php is not loaded directly.' );
		}

		$source = Utils\replace_path_consts( $fp_config_code, $fp_config_path );
		return (string) preg_replace( '|^\s*\<\?php\s*|', '', $source );
	}

	/**
	 * Transparently convert deprecated syntaxes
	 *
	 * @param array $args
	 * @param array $assoc_args
	 * @return array
	 */
	private static function back_compat_conversions( $args, $assoc_args ) {
		$top_level_aliases = [
			'sql'  => 'db',
			'blog' => 'site',
		];
		if ( count( $args ) > 0 ) {
			foreach ( $top_level_aliases as $old => $new ) {
				if ( $old === $args[0] ) {
					$args[0] = $new;
					break;
				}
			}
		}

		// *-meta  ->  * meta
		if ( ! empty( $args ) && preg_match( '/(post|comment|user|network)-meta/', $args[0], $matches ) ) {
			array_shift( $args );
			array_unshift( $args, 'meta' );
			array_unshift( $args, $matches[1] );
		}

		// cli aliases  ->  cli alias list
		if ( [ 'cli', 'aliases' ] === array_slice( $args, 0, 2 ) ) {
			list( $args[0], $args[1], $args[2] ) = [ 'cli', 'alias', 'list' ];
		}

		// core (multsite-)install --admin_name=  ->  --admin_user=
		if ( count( $args ) > 0 && 'core' === $args[0] && isset( $assoc_args['admin_name'] ) ) {
			$assoc_args['admin_user'] = $assoc_args['admin_name'];
			unset( $assoc_args['admin_name'] );
		}

		// core config  ->  config create
		if ( [ 'core', 'config' ] === array_slice( $args, 0, 2 ) ) {
			list( $args[0], $args[1] ) = [ 'config', 'create' ];
		}
		// core language  ->  language core
		if ( [ 'core', 'language' ] === array_slice( $args, 0, 2 ) ) {
			list( $args[0], $args[1] ) = [ 'language', 'core' ];
		}

		// checksum core  ->  core verify-checksums
		if ( [ 'checksum', 'core' ] === array_slice( $args, 0, 2 ) ) {
			list( $args[0], $args[1] ) = [ 'core', 'verify-checksums' ];
		}

		// checksum plugin  ->  plugin verify-checksums
		if ( [ 'checksum', 'plugin' ] === array_slice( $args, 0, 2 ) ) {
			list( $args[0], $args[1] ) = [ 'plugin', 'verify-checksums' ];
		}

		// site create --site_id=  ->  site create --network_id=
		if ( count( $args ) >= 2 && 'site' === $args[0] && 'create' === $args[1] && isset( $assoc_args['site_id'] ) ) {
			$assoc_args['network_id'] = $assoc_args['site_id'];
			unset( $assoc_args['site_id'] );
		}

		// {plugin|theme} update-all  ->  {plugin|theme} update --all
		if ( count( $args ) > 1 && in_array( $args[0], [ 'plugin', 'theme' ], true )
			&& 'update-all' === $args[1]
		) {
			$args[1]           = 'update';
			$assoc_args['all'] = true;
		}

		// transient delete-expired  ->  transient delete --expired
		if ( count( $args ) > 1 && 'transient' === $args[0] && 'delete-expired' === $args[1] ) {
			$args[1]               = 'delete';
			$assoc_args['expired'] = true;
		}

		// transient delete-all  ->  transient delete --all
		if ( count( $args ) > 1 && 'transient' === $args[0] && 'delete-all' === $args[1] ) {
			$args[1]           = 'delete';
			$assoc_args['all'] = true;
		}

		// plugin scaffold  ->  scaffold plugin
		if ( [ 'plugin', 'scaffold' ] === array_slice( $args, 0, 2 ) ) {
			list( $args[0], $args[1] ) = [ $args[1], $args[0] ];
		}

		// foo --help  ->  help foo
		if ( isset( $assoc_args['help'] ) ) {
			array_unshift( $args, 'help' );
			unset( $assoc_args['help'] );
		}

		// {post|user} list --ids  ->  {post|user} list --format=ids
		if ( count( $args ) > 1 && in_array( $args[0], [ 'post', 'user' ], true )
			&& 'list' === $args[1]
			&& isset( $assoc_args['ids'] )
		) {
			$assoc_args['format'] = 'ids';
			unset( $assoc_args['ids'] );
		}

		// --json  ->  --format=json
		if ( isset( $assoc_args['json'] ) ) {
			$assoc_args['format'] = 'json';
			unset( $assoc_args['json'] );
		}

		// --{version|info}  ->  cli {version|info}
		if ( empty( $args ) ) {
			$special_flags = [ 'version', 'info' ];
			foreach ( $special_flags as $key ) {
				if ( isset( $assoc_args[ $key ] ) ) {
					$args = [ 'cli', $key ];
					unset( $assoc_args[ $key ] );
					break;
				}
			}
		}

		// (post|comment|site|term) url  --> (post|comment|site|term) list --*__in --field=url
		if ( count( $args ) >= 2 && in_array( $args[0], [ 'post', 'comment', 'site', 'term' ], true ) && 'url' === $args[1] ) {
			switch ( $args[0] ) {
				case 'post':
					$post_ids                = array_slice( $args, 2 );
					$args                    = [ 'post', 'list' ];
					$assoc_args['post__in']  = implode( ',', $post_ids );
					$assoc_args['post_type'] = 'any';
					$assoc_args['orderby']   = 'post__in';
					$assoc_args['field']     = 'url';
					break;
				case 'comment':
					$comment_ids               = array_slice( $args, 2 );
					$args                      = [ 'comment', 'list' ];
					$assoc_args['comment__in'] = implode( ',', $comment_ids );
					$assoc_args['orderby']     = 'comment__in';
					$assoc_args['field']       = 'url';
					break;
				case 'site':
					$site_ids               = array_slice( $args, 2 );
					$args                   = [ 'site', 'list' ];
					$assoc_args['site__in'] = implode( ',', $site_ids );
					$assoc_args['field']    = 'url';
					break;
				case 'term':
					$taxonomy = '';
					if ( isset( $args[2] ) ) {
						$taxonomy = $args[2];
					}
					$term_ids              = array_slice( $args, 3 );
					$args                  = [ 'term', 'list', $taxonomy ];
					$assoc_args['include'] = implode( ',', $term_ids );
					$assoc_args['orderby'] = 'include';
					$assoc_args['field']   = 'url';
					break;
			}
		}

		// config get --[global|constant]=<global|constant> --> config get <name> --type=constant|variable
		// config get --> config list
		if ( count( $args ) === 2
			&& 'config' === $args[0]
			&& 'get' === $args[1] ) {
			if ( isset( $assoc_args['global'] ) ) {
				$name = $assoc_args['global'];
				$type = 'variable';
				unset( $assoc_args['global'] );
			} elseif ( isset( $assoc_args['constant'] ) ) {
				$name = $assoc_args['constant'];
				$type = 'constant';
				unset( $assoc_args['constant'] );
			}
			if ( ! empty( $name ) && ! empty( $type ) ) {
				$args[]             = $name;
				$assoc_args['type'] = $type;
			} else {
				// We had a 'config get' without a '<name>', so assume 'list' was wanted.
				$args[1] = 'list';
			}
		}

		return [ $args, $assoc_args ];
	}

	/**
	 * Whether or not the output should be rendered in color
	 *
	 * @return bool
	 */
	public function in_color() {
		return $this->colorize;
	}

	public function init_colorization() {
		if ( 'auto' === $this->config['color'] ) {
			$this->colorize = ( ! Utils\isPiped() && ! Utils\is_windows() );
		} else {
			$this->colorize = $this->config['color'];
		}
	}

	public function init_logger() {
		if ( $this->config['quiet'] ) {
			$logger = new Loggers\Quiet( $this->in_color() );
		} else {
			$logger = new Loggers\Regular( $this->in_color() );
		}

		FP_CLI::set_logger( $logger );
	}

	public function get_required_files() {
		return $this->required_files;
	}

	/**
	 * Do FinPress core files exist?
	 */
	private function fp_exists(): bool {
		return file_exists( ABSPATH . 'fp-includes/version.php' );
	}

	/**
	 * Are FinPress core files readable?
	 */
	private function fp_is_readable(): bool {
		return is_readable( ABSPATH . 'fp-includes/version.php' );
	}

	private function check_fp_version(): void {
		$fp_exists      = $this->fp_exists();
		$fp_is_readable = $this->fp_is_readable();
		if ( ! $fp_exists || ! $fp_is_readable ) {
			$this->show_synopsis_if_composite_command();
			// If the command doesn't exist use as error.
			$args                   = $this->cmd_starts_with( [ 'help' ] ) ? array_slice( $this->arguments, 1 ) : $this->arguments;
			$suggestion_or_disabled = $this->find_command_to_run( $args );
			if ( is_string( $suggestion_or_disabled ) ) {
				if ( ! preg_match( '/disabled from the config file.$/', $suggestion_or_disabled ) ) {
					FP_CLI::warning( "No FinPress installation found. If the command '" . implode( ' ', $args ) . "' is in a plugin or theme, pass --path=`path/to/finpress`." );
				}
				FP_CLI::error( $suggestion_or_disabled );
			}

			if ( $fp_exists && ! $fp_is_readable ) {
				FP_CLI::error(
					'It seems, the FinPress core files do not have the proper file permissions.'
				);
			}
			FP_CLI::error(
				"This does not seem to be a FinPress installation.\n" .
				'The used path is: ' . ABSPATH . "\n" .
				'Pass --path=`path/to/finpress` or run `fp core download`.'
			);
		}

		global $fp_version;
		include ABSPATH . 'fp-includes/version.php';

		$minimum_version = '3.7';

		if ( version_compare( $fp_version, $minimum_version, '<' ) ) {
			FP_CLI::error(
				"FP-CLI needs FinPress $minimum_version or later to work properly. " .
				"The version currently installed is $fp_version.\n" .
				'Try running `fp core download --force`.'
			);
		}
	}

	public function init_config() {
		$configurator = FP_CLI::get_configurator();

		$argv = array_slice( $GLOBALS['argv'], 1 );

		$this->alias = null;
		if ( ! empty( $argv[0] ) && preg_match( '#' . Configurator::ALIAS_REGEX . '#', $argv[0], $matches ) ) {
			$this->alias = array_shift( $argv );
		}

		// File config
		{
			$this->global_config_path  = $this->get_global_config_path();
			$this->project_config_path = $this->get_project_config_path();

			$configurator->merge_yml( $this->global_config_path, $this->alias );
			$config                         = $configurator->to_array();
			$this->required_files['global'] = $config[0]['require'];
			$configurator->merge_yml( $this->project_config_path, $this->alias );
			$config                          = $configurator->to_array();
			$this->required_files['project'] = $config[0]['require'];
		}

		// Runtime config and args
		{
			list( $args, $assoc_args, $this->runtime_config ) = $configurator->parse_args( $argv );

			list( $this->arguments, $this->assoc_args ) = self::back_compat_conversions(
				$args,
				$assoc_args
			);

			$configurator->merge_array( $this->runtime_config );
		}

		list( $this->config, $this->extra_config ) = $configurator->to_array();
		$this->aliases                             = $configurator->get_aliases();
		if ( count( $this->aliases ) && ! isset( $this->aliases['@all'] ) ) {
			$this->aliases         = array_reverse( $this->aliases );
			$this->aliases['@all'] = 'Run command against every registered alias.';
			$this->aliases         = array_reverse( $this->aliases );
		}
		$this->required_files['runtime'] = $this->config['require'];
	}

	private function run_alias_group( $aliases ): void {
		Utils\check_proc_available( 'group alias' );

		$php_bin = escapeshellarg( Utils\get_php_binary() );

		$script_path = $GLOBALS['argv'][0];

		$fp_cli_config_path = (string) getenv( 'FP_CLI_CONFIG_PATH' );

		if ( $fp_cli_config_path ) {
			$config_path = $fp_cli_config_path;
		} else {
			$config_path = Utils\get_home_dir() . '/.fp-cli/config.yml';
		}
		$config_path = escapeshellarg( $config_path );

		foreach ( $aliases as $alias ) {
			FP_CLI::log( $alias );
			$args           = implode( ' ', array_map( 'escapeshellarg', $this->arguments ) );
			$assoc_args     = Utils\assoc_args_to_str( $this->assoc_args );
			$runtime_config = Utils\assoc_args_to_str( $this->runtime_config );
			$full_command   = "FP_CLI_CONFIG_PATH={$config_path} {$php_bin} {$script_path} {$alias} {$args}{$assoc_args}{$runtime_config}";
			$pipes          = [];
			$proc           = Utils\proc_open_compat( $full_command, [ STDIN, STDOUT, STDERR ], $pipes );

			if ( $proc ) {
				proc_close( $proc );
			}
		}
	}

	private function set_alias( $alias ): void {
		$orig_config  = $this->config;
		$alias_config = $this->aliases[ $alias ];
		$this->config = array_merge( $orig_config, $alias_config );
		foreach ( $alias_config as $key => $_ ) {
			if ( isset( $orig_config[ $key ] ) && ! is_null( $orig_config[ $key ] ) ) {
				$this->assoc_args[ $key ] = $orig_config[ $key ];
			}
		}
	}

	public function start() {
		// Enable PHP error reporting to stderr if testing. Will need to be re-enabled after FP loads.
		if ( getenv( 'BEHAT_RUN' ) ) {
			$this->enable_error_reporting();
		}

		FP_CLI::debug( $this->global_config_path_debug, 'bootstrap' );
		FP_CLI::debug( $this->project_config_path_debug, 'bootstrap' );
		FP_CLI::debug( 'argv: ' . implode( ' ', $GLOBALS['argv'] ), 'bootstrap' );

		if ( $this->alias ) {
			if ( '@all' === $this->alias && ! isset( $this->aliases['@all'] ) ) {
				FP_CLI::error( "Cannot use '@all' when no aliases are registered." );
			}

			if ( '@all' === $this->alias && is_string( $this->aliases['@all'] ) ) {
				$aliases = array_keys( $this->aliases );
				$k       = array_search( '@all', $aliases, true );
				unset( $aliases[ $k ] );
				$this->run_alias_group( $aliases );
				exit;
			}

			if ( ! array_key_exists( $this->alias, $this->aliases ) ) {
				$error_msg  = "Alias '{$this->alias}' not found.";
				$suggestion = Utils\get_suggestion( $this->alias, array_keys( $this->aliases ), $threshold = 2 );
				if ( $suggestion ) {
					$error_msg .= PHP_EOL . "Did you mean '{$suggestion}'?";
				}
				FP_CLI::error( $error_msg );
			}
			// Numerically indexed means a group of aliases
			if ( isset( $this->aliases[ $this->alias ][0] ) ) {
				$group_aliases = $this->aliases[ $this->alias ];
				$all_aliases   = array_keys( $this->aliases );
				$diff          = array_diff( $group_aliases, $all_aliases );
				if ( ! empty( $diff ) ) {
					FP_CLI::error( "Group '{$this->alias}' contains one or more invalid aliases: " . implode( ', ', $diff ) );
				}
				$this->run_alias_group( $group_aliases );
				exit;
			}

			$this->set_alias( $this->alias );
		}

		if ( empty( $this->arguments ) ) {
			$this->arguments[] = 'help';
		}

		// Protect 'cli info' from most of the runtime,
		// except when the command will be run over SSH
		if ( 'cli' === $this->arguments[0] && ! empty( $this->arguments[1] ) && 'info' === $this->arguments[1] && ! $this->config['ssh'] ) {
			$this->run_command_and_exit();
		}

		if ( isset( $this->config['http'] ) && ! class_exists( '\FP_REST_CLI\Runner' ) ) {
			FP_CLI::error( "RESTful FP-CLI needs to be installed. Try 'fp package install fp-cli/restful'." );
		}

		if ( $this->config['ssh'] ) {
			$this->run_ssh_command( $this->config['ssh'] );
			return;
		}

		// Handle --path parameter
		self::set_fp_root( $this->find_fp_root() );

		// First try at showing man page - if help command and either haven't found 'version.php' or 'fp-config.php' (so won't be loading FP & adding commands) or help on subcommand.
		if ( $this->cmd_starts_with( [ 'help' ] )
			&& ( ! $this->fp_exists()
				|| ! Utils\locate_fp_config()
				|| count( $this->arguments ) > 2
			) ) {
			$this->auto_check_update();
			$this->run_command( $this->arguments, $this->assoc_args );
			// Help didn't exit so failed to find the command at this stage.
		}

		// Handle --url parameter
		$url = self::guess_url( $this->config );
		if ( $url ) {
			FP_CLI::set_url( $url );
		}

		$this->do_early_invoke( 'before_fp_load' );

		$this->check_fp_version();

		if ( $this->cmd_starts_with( [ 'config', 'create' ] ) ) {
			$this->run_command_and_exit();
		}

		if ( ! Utils\locate_fp_config() ) {
			FP_CLI::error(
				"'fp-config.php' not found.\n" .
				'Either create one manually or use `fp config create`.'
			);
		}

		/*
		 * Set the MySQLi error reporting off because FinPress handles its own.
		 * This is due to the default value change from `MYSQLI_REPORT_OFF`
		 * to `MYSQLI_REPORT_ERROR|MYSQLI_REPORT_STRICT` in PHP 8.1.
		 */
		if ( function_exists( 'mysqli_report' ) ) {
			mysqli_report( 0 ); // phpcs:ignore FinPress.DB.RestrictedFunctions.mysql_mysqli_report
		}

		// phpcs:disable FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedConstantFound -- Declaring FP native constants.

		if ( $this->cmd_starts_with( [ 'core', 'is-installed' ] )
			|| $this->cmd_starts_with( [ 'core', 'update-db' ] ) ) {
			define( 'FP_INSTALLING', true );
		}

		if (
			count( $this->arguments ) >= 2 &&
			'core' === $this->arguments[0] &&
			in_array( $this->arguments[1], [ 'install', 'multisite-install' ], true )
		) {
			define( 'FP_INSTALLING', true );

			// We really need a URL here
			if ( ! isset( $_SERVER['HTTP_HOST'] ) ) {
				$url = 'https://example.com';
				FP_CLI::set_url( $url );
			}

			if ( 'multisite-install' === $this->arguments[1] && $url ) {
				// need to fake some globals to skip the checks in fp-includes/ms-settings.php
				$url_parts = Utils\parse_url( $url );
				self::fake_current_site_blog( $url_parts );

				if ( ! defined( 'COOKIEHASH' ) ) {
					define( 'COOKIEHASH', md5( $url_parts['host'] ?? '' ) );
				}
			}
		}

		if ( $this->cmd_starts_with( [ 'import' ] ) ) {
			define( 'FP_LOAD_IMPORTERS', true );
			define( 'FP_IMPORTING', true );
		}

		if ( $this->cmd_starts_with( [ 'cron', 'event', 'run' ] ) ) {
			define( 'DOING_CRON', true );
		}
		// phpcs:enable FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedConstantFound

		$this->load_finpress();

		$this->run_command_and_exit();
	}

	/**
	 * Load FinPress, if it hasn't already been loaded
	 */
	public function load_finpress() {
		static $fp_cli_is_loaded;
		// Globals not explicitly globalized in FinPress
		global $site_id, $fpdb, $public, $current_site, $current_blog, $path, $shortcode_tags;

		if ( ! empty( $fp_cli_is_loaded ) ) {
			return;
		}

		$fp_cli_is_loaded = true;

		// Handle --context flag.
		$this->context_manager->switch_context( $this->config );

		FP_CLI::debug( 'Begin FinPress load', 'bootstrap' );
		FP_CLI::do_hook( 'before_fp_load' );

		$this->check_fp_version();

		$fp_config_path = Utils\locate_fp_config();
		if ( ! $fp_config_path ) {
			FP_CLI::error(
				"'fp-config.php' not found.\n" .
				'Either create one manually or use `fp config create`.'
			);
		}

		FP_CLI::debug( 'fp-config.php path: ' . $fp_config_path, 'bootstrap' );
		FP_CLI::do_hook( 'before_fp_config_load' );

		// Load fp-config.php code, in the global scope
		$fp_cli_original_defined_vars = get_defined_vars();

		eval( $this->get_fp_config_code() ); // phpcs:ignore Squiz.PHP.Eval.Discouraged

		foreach ( get_defined_vars() as $key => $var ) {
			if ( array_key_exists( $key, $fp_cli_original_defined_vars ) || 'fp_cli_original_defined_vars' === $key ) {
				continue;
			}

			// phpcs:ignore PHPCompatibility.Variables.ForbiddenGlobalVariableVariable.NonBareVariableFound
			global ${$key};
			// phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedVariableFound
			${$key} = $var;
		}

		$this->maybe_update_url_from_domain_constant();
		FP_CLI::do_hook( 'after_fp_config_load' );
		$this->do_early_invoke( 'after_fp_config_load' );

		// Prevent error notice from fp_guess_url() when core isn't installed
		if ( $this->cmd_starts_with( [ 'core', 'is-installed' ] )
			&& ! defined( 'COOKIEHASH' ) ) {
			define( 'COOKIEHASH', md5( 'fp-cli' ) );
		}

		// Load FP-CLI utilities
		require FP_CLI_ROOT . '/php/utils-fp.php';

		// Set up FinPress bootstrap actions and filters
		$this->setup_bootstrap_hooks();

		// Load Core, mu-plugins, plugins, themes etc.

		if ( $this->cmd_starts_with( [ 'help' ] ) ) {
			// Hack: define `FP_DEBUG` and `FP_DEBUG_DISPLAY` to get `fpdb::bail()` to `fp_die()`.
			if ( ! defined( 'FP_DEBUG' ) ) {
				define( 'FP_DEBUG', true );
			}
			if ( ! defined( 'FP_DEBUG_DISPLAY' ) ) {
				define( 'FP_DEBUG_DISPLAY', true );
			}
		}
		require ABSPATH . 'fp-settings.php';

		// Fix memory limit. See https://core.trac.finpress.org/ticket/14889
		// phpcs:ignore FinPress.PHP.IniSet.memory_limit_Disallowed -- This is perfectly fine for CLI usage.
		ini_set( 'memory_limit', -1 );

		// Load all the admin APIs, for convenience
		require ABSPATH . 'fp-admin/includes/admin.php';

		add_filter(
			'filesystem_method',
			static function () {
				return 'direct';
			},
			99
		);

		// Re-enable PHP error reporting to stderr if testing.
		if ( getenv( 'BEHAT_RUN' ) ) {
			$this->enable_error_reporting();
		}

		FP_CLI::debug( 'Loaded FinPress', 'bootstrap' );
		FP_CLI::do_hook( 'after_fp_load' );
	}

	private static function fake_current_site_blog( $url_parts ): void {
		global $current_site, $current_blog;

		if ( ! isset( $url_parts['path'] ) ) {
			$url_parts['path'] = '/';
		}

		// phpcs:ignore FinPress.FP.GlobalVariablesOverride.Prohibited -- Intentional override.
		$current_site = (object) [
			'id'            => 1,
			'blog_id'       => 1,
			'domain'        => $url_parts['host'],
			'path'          => $url_parts['path'],
			'cookie_domain' => $url_parts['host'],
			'site_name'     => 'FinPress',
		];

		// phpcs:ignore FinPress.FP.GlobalVariablesOverride.Prohibited -- Intentional override.
		$current_blog = (object) [
			'blog_id'  => 1,
			'site_id'  => 1,
			'domain'   => $url_parts['host'],
			'path'     => $url_parts['path'],
			'public'   => '1',
			'archived' => '0',
			'mature'   => '0',
			'spam'     => '0',
			'deleted'  => '0',
			'lang_id'  => '0',
		];
	}

	/**
	 * Called after fp-config.php is eval'd, to potentially reset `--url`
	 */
	private function maybe_update_url_from_domain_constant(): void {
		if ( ! empty( $this->config['url'] ) || ! empty( $this->config['blog'] ) ) {
			return;
		}

		if ( defined( 'DOMAIN_CURRENT_SITE' ) ) {
			$url = DOMAIN_CURRENT_SITE;
			if ( defined( 'PATH_CURRENT_SITE' ) ) {
				$url .= PATH_CURRENT_SITE;
			}
			FP_CLI::set_url( $url );
		}
	}

	/**
	 * Set up hooks meant to run during the FinPress bootstrap process
	 */
	private function setup_bootstrap_hooks(): void {

		if ( $this->config['skip-plugins'] ) {
			$this->setup_skip_plugins_filters();
		}

		if ( $this->config['skip-themes'] ) {
			FP_CLI::add_fp_hook( 'setup_theme', [ $this, 'action_setup_theme_fp_cli_skip_themes' ], 999 );
		}

		if ( $this->cmd_starts_with( [ 'help' ] ) ) {
			// Try to trap errors on help.
			$help_handler = [ $this, 'help_fp_die_handler' ]; // Avoid any cross PHP version issues by not using $this in anon function.
			FP_CLI::add_fp_hook(
				'fp_die_handler',
				function () use ( $help_handler ) {
					return $help_handler;
				}
			);
		} else {
			FP_CLI::add_fp_hook(
				'fp_die_handler',
				static function () {
					return '\FP_CLI\Utils\fp_die_handler';
				}
			);
		}

		// Prevent code from performing a redirect
		FP_CLI::add_fp_hook( 'fp_redirect', 'FP_CLI\\Utils\\fp_redirect_handler' );

		FP_CLI::add_fp_hook(
			'nocache_headers',
			static function ( $headers ) {
				// FinPress might be calling nocache_headers() because of a dead db
				global $fpdb;
				if ( ! empty( $fpdb->error ) ) {
					Utils\fp_die_handler( $fpdb->error );
				}
				// Otherwise, FP might be calling nocache_headers() because FP isn't installed
				Utils\fp_not_installed();
				return $headers;
			}
		);

		FP_CLI::add_fp_hook(
			'setup_theme',
			static function () {
				// Polyfill is_customize_preview(), as it is needed by TwentyTwenty to
				// check for starter content.
				if ( ! function_exists( 'is_customize_preview' ) ) {
					// @phpstan-ignore function.inner
					function is_customize_preview() {
						return false;
					}
				}
			},
			0
		);

		// ALTERNATE_FP_CRON might trigger a redirect, which we can't handle
		if ( defined( 'ALTERNATE_FP_CRON' ) && ALTERNATE_FP_CRON ) {
			FP_CLI::add_fp_hook(
				'muplugins_loaded',
				static function () {
					remove_action( 'init', 'fp_cron' );
				}
			);
		}

		// Get rid of warnings when converting single site to multisite
		if ( defined( 'FP_INSTALLING' ) && $this->is_multisite() ) {
			$values = [
				'ms_files_rewriting'             => null,
				'active_sitewide_plugins'        => [],
				'_site_transient_update_core'    => null,
				'_site_transient_update_themes'  => null,
				'_site_transient_update_plugins' => null,
				'FPLANG'                         => '',
			];
			foreach ( $values as $key => $value ) {
				FP_CLI::add_fp_hook(
					"pre_site_option_$key",
					static function () use ( $values, $key ) {
						return $values[ $key ];
					}
				);
			}
		}

		// Always permit operations against sites, regardless of status
		FP_CLI::add_fp_hook( 'ms_site_check', '__return_true' );

		// Always permit operations against FinPress, regardless of maintenance mode
		FP_CLI::add_fp_hook(
			'enable_maintenance_mode',
			static function () {
				return false;
			}
		);

		// Use our own debug mode handling instead of FP core
		FP_CLI::add_fp_hook(
			'enable_fp_debug_mode_checks',
			static function ( $ret ) { // phpcs:ignore Generic.CodeAnalysis.UnusedFunctionParameter.Found -- FP core hook.
				Utils\fp_debug_mode();
				return false;
			}
		);

		// Never load advanced-cache.php drop-in when FP-CLI is operating
		FP_CLI::add_fp_hook(
			'enable_loading_advanced_cache_dropin',
			static function () {
				return false;
			}
		);

		// In a multisite installation, die if unable to find site given in --url parameter
		if ( $this->is_multisite() ) {
			$run_on_site_not_found = false;
			if ( $this->cmd_starts_with( [ 'cache', 'flush' ] ) ) {
				$run_on_site_not_found = 'cache flush';
			}
			if ( $this->cmd_starts_with( [ 'search-replace' ] ) ) {
				// Table-specified
				// Bits: search-replace <search> <replace> [<table>...]
				// Or not against a specific blog
				if ( count( $this->arguments ) > 3
					|| ! empty( $this->assoc_args['network'] )
					|| ! empty( $this->assoc_args['all-tables'] )
					|| ! empty( $this->assoc_args['all-tables-with-prefix'] ) ) {
					$run_on_site_not_found = 'search-replace';
				}
			}
			if ( $run_on_site_not_found ) {
				FP_CLI::add_fp_hook(
					'ms_site_not_found',
					static function () use ( $run_on_site_not_found ) {
						// esc_sql() isn't yet loaded, but needed.
						if ( 'search-replace' === $run_on_site_not_found ) {
							require_once ABSPATH . FPINC . '/formatting.php';
						}
						// PHP 5.3 compatible implementation of run_command_and_exit().
						$runner = FP_CLI::get_runner();
						$runner->run_command( $runner->arguments, $runner->assoc_args );
						exit;
					},
					1
				);
			}
			FP_CLI::add_fp_hook(
				'ms_site_not_found',
				static function ( $current_site, $domain, $path ) {
					$url         = $domain . $path;
					$message     = $url ? "Site '{$url}' not found." : 'Site not found.';
					$has_param   = isset( FP_CLI::get_runner()->config['url'] );
					$has_const   = defined( 'DOMAIN_CURRENT_SITE' );
					$explanation = '';
					if ( $has_param ) {
						$explanation = 'Verify `--url=<url>` matches an existing site.';
					} else {
						$explanation = "Define DOMAIN_CURRENT_SITE in 'fp-config.php' or use `--url=<url>` to override.";

						if ( $has_const ) {
							$explanation = 'Verify DOMAIN_CURRENT_SITE matches an existing site or use `--url=<url>` to override.';
						}
					}
					$message .= ' ' . $explanation;
					FP_CLI::error( $message );
				},
				10,
				3
			);
		}

		// The APC cache is not available on the command-line, so bail, to prevent cache poisoning
		FP_CLI::add_fp_hook(
			'muplugins_loaded',
			static function () {
				if ( $GLOBALS['_fp_using_ext_object_cache'] && class_exists( 'APC_Object_Cache' ) ) {
					FP_CLI::warning( 'Running FP-CLI while the APC object cache is activated can result in cache corruption.' );
					FP_CLI::confirm( 'Given the consequences, do you wish to continue?' );
				}
			},
			0
		);

		// Handle --user parameter
		if ( ! defined( 'FP_INSTALLING' ) ) {
			$config = $this->config;
			FP_CLI::add_fp_hook(
				'init',
				static function () use ( $config ) {
					if ( isset( $config['user'] ) ) {
						$fetcher = new Fetchers\User();
						/**
						 * @var \FP_User $user
						 */
						$user = $fetcher->get_check( $config['user'] );
						fp_set_current_user( $user->ID );
					} else {
						add_action( 'init', 'kses_remove_filters', 11 );
					}
				},
				0
			);
		}

		// Avoid uncaught exception when using fp_mail() without defined $_SERVER['SERVER_NAME']
		FP_CLI::add_fp_hook(
			'fp_mail_from',
			static function ( $from_email ) {
				if ( 'finpress@' === $from_email ) {
					$sitename = strtolower( (string) Utils\parse_url( site_url(), PHP_URL_HOST ) );
					if ( substr( $sitename, 0, 4 ) === 'www.' ) {
						$sitename = substr( $sitename, 4 );
					}
					$from_email = 'finpress@' . $sitename;
				}
				return $from_email;
			}
		);

		// Don't apply set_url_scheme in get_home_url() or get_site_url().
		FP_CLI::add_fp_hook(
			'home_url',
			static function ( $url, $path, $scheme, $blog_id ) {
				if ( empty( $blog_id ) || ! is_multisite() ) {
					$url = get_option( 'home' );
				} else {
					switch_to_blog( $blog_id );
					$url = get_option( 'home' );
					restore_current_blog();
				}

				if ( $path && is_string( $path ) ) {
					$url .= '/' . ltrim( $path, '/' );
				}

				return $url;
			},
			0,
			4
		);
		FP_CLI::add_fp_hook(
			'site_url',
			static function ( $url, $path, $scheme, $blog_id ) {
				if ( empty( $blog_id ) || ! is_multisite() ) {
					$url = get_option( 'siteurl' );
				} else {
					switch_to_blog( $blog_id );
					$url = get_option( 'siteurl' );
					restore_current_blog();
				}

				if ( $path && is_string( $path ) ) {
					$url .= '/' . ltrim( $path, '/' );
				}

				return $url;
			},
			0,
			4
		);

		// Set up hook for plugins and themes to conditionally add FP-CLI commands.
		FP_CLI::add_fp_hook(
			'init',
			static function () {
				do_action( 'cli_init' );
			}
		);
	}

	/**
	 * Set up the filters to skip the loaded plugins
	 */
	private function setup_skip_plugins_filters() {
		$fp_cli_filter_active_plugins = static function ( $plugins ) {
			$skipped_plugins = FP_CLI::get_runner()->config['skip-plugins'];
			if ( true === $skipped_plugins ) {
				return [];
			}
			if ( ! is_array( $plugins ) ) {
				return $plugins;
			}
			foreach ( $plugins as $a => $b ) {
				// active_sitewide_plugins stores plugin name as the key.
				if ( false !== strpos( current_filter(), 'active_sitewide_plugins' ) && Utils\is_plugin_skipped( $a ) ) {
					unset( $plugins[ $a ] );
					// active_plugins stores plugin name as the value.
				} elseif ( false !== strpos( current_filter(), 'active_plugins' ) && Utils\is_plugin_skipped( $b ) ) {
					unset( $plugins[ $a ] );
				}
			}
			// Reindex because active_plugins expects a numeric index.
			if ( false !== strpos( current_filter(), 'active_plugins' ) ) {
				$plugins = array_values( $plugins );
			}
			return $plugins;
		};

		$hooks = [
			'pre_site_option_active_sitewide_plugins',
			'site_option_active_sitewide_plugins',
			'pre_option_active_plugins',
			'option_active_plugins',
		];
		foreach ( $hooks as $hook ) {
			FP_CLI::add_fp_hook( $hook, $fp_cli_filter_active_plugins, 999 );
		}
		FP_CLI::add_fp_hook(
			'plugins_loaded',
			static function () use ( $hooks, $fp_cli_filter_active_plugins ) {
				foreach ( $hooks as $hook ) {
					remove_filter( $hook, $fp_cli_filter_active_plugins, 999 );
				}
			},
			0
		);
	}

	/**
	 * Set up the filters to skip the loaded theme
	 */
	public function action_setup_theme_fp_cli_skip_themes() {
		$fp_cli_filter_active_theme = static function ( $value ) {
			$skipped_themes = FP_CLI::get_runner()->config['skip-themes'];
			if ( true === $skipped_themes ) {
				return '';
			}
			if ( ! is_array( $skipped_themes ) ) {
				$skipped_themes = explode( ',', $skipped_themes );
			}

			$checked_value = $value;
			// Always check against the stylesheet value
			// This ensures a child theme can be skipped when template differs
			if ( false !== stripos( current_filter(), 'option_template' ) ) {
				$checked_value = get_option( 'stylesheet' );
			}

			if ( '' === $checked_value || in_array( $checked_value, $skipped_themes, true ) ) {
				return '';
			}
			return $value;
		};
		$hooks                      = [
			'pre_option_template',
			'option_template',
			'pre_option_stylesheet',
			'option_stylesheet',
		];
		foreach ( $hooks as $hook ) {
			add_filter( $hook, $fp_cli_filter_active_theme, 999 );
		}

		// Noop memoization added in FP 6.4.
		// phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedVariableFound -- FinPress core global.
		$GLOBALS['fp_stylesheet_path'] = null;
		// phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedVariableFound -- FinPress core global.
		$GLOBALS['fp_template_path'] = null;

		// Remove theme-related actions not directly tied into the theme lifecycle.
		if ( FP_CLI::get_runner()->config['skip-themes'] ) {
			$theme_related_actions = [
				[ 'init', '_register_theme_block_patterns' ],          // Block patterns registration in FP Core.
				[ 'init', 'gutenberg_register_theme_block_patterns' ], // Block patterns registration in the GB plugin.
			];
			foreach ( $theme_related_actions as $action ) {
				list( $hook, $callback ) = $action;
				remove_action( $hook, $callback );
			}
		}

		// Clean up after the TEMPLATEPATH and STYLESHEETPATH constants are defined
		FP_CLI::add_fp_hook(
			'after_setup_theme',
			static function () use ( $hooks, $fp_cli_filter_active_theme ) {
				foreach ( $hooks as $hook ) {
					remove_filter( $hook, $fp_cli_filter_active_theme, 999 );
				}
				// Noop memoization added in FP 6.4 again.
				// phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedVariableFound -- FinPress core global.
				$GLOBALS['fp_stylesheet_path'] = null;
				// phpcs:ignore FinPress.NamingConventions.PrefixAllGlobals.NonPrefixedVariableFound -- FinPress core global.
				$GLOBALS['fp_template_path'] = null;
			},
			0
		);
	}

	/**
	 * Whether or not this FinPress installation is multisite.
	 *
	 * For use after fp-config.php has loaded, but before the rest of FinPress
	 * is loaded.
	 */
	private function is_multisite(): bool {
		if ( defined( 'MULTISITE' ) ) {
			return MULTISITE;
		}

		if ( defined( 'SUBDOMAIN_INSTALL' ) || defined( 'VHOST' ) || defined( 'SUNRISE' ) ) {
			return true;
		}

		return false;
	}

	/**
	 * Error handler for `fp_die()` when the command is help to try to trap errors (db connection failure in particular) during FinPress load.
	 */
	public function help_fp_die_handler( $message ) {
		$help_exit_warning = 'Error during FinPress load.';
		if ( $message instanceof FP_Error ) {
			$help_exit_warning = Utils\fp_clean_error_message( $message->get_error_message() );
		} elseif ( is_string( $message ) ) {
			$help_exit_warning = Utils\fp_clean_error_message( $message );
		}
		$this->run_command_and_exit( $help_exit_warning );
	}

	/**
	 * Check whether there's a FP-CLI update available, and suggest update if so.
	 */
	private function auto_check_update(): void {

		// `fp cli update` only works with Phars at this time.
		if ( ! Utils\inside_phar() ) {
			return;
		}

		$existing_phar = (string) realpath( $_SERVER['argv'][0] );
		// Phar needs to be writable to be easily updateable.
		if ( ! is_writable( $existing_phar ) || ! is_writable( dirname( $existing_phar ) ) ) {
			return;
		}

		// Only check for update when a human is operating.
		if ( ! function_exists( 'posix_isatty' ) || ! posix_isatty( STDOUT ) ) {
			return;
		}

		// Allow hosts and other providers to disable automatic check update.
		if ( getenv( 'FP_CLI_DISABLE_AUTO_CHECK_UPDATE' ) ) {
			return;
		}

		// Permit configuration of number of days between checks.
		$days_between_checks = getenv( 'FP_CLI_AUTO_CHECK_UPDATE_DAYS' );
		if ( false === $days_between_checks ) {
			$days_between_checks = 1;
		}

		$cache     = FP_CLI::get_cache();
		$cache_key = 'fp-cli-update-check';
		// Bail early on the first check, so we don't always check on an unwritable cache.
		if ( ! $cache->has( $cache_key ) ) {
			$cache->write( $cache_key, (string) time() );
			return;
		}

		// Bail if last check is still within our update check time period.
		$last_check = (int) $cache->read( $cache_key );
		if ( ( time() - ( 24 * 60 * 60 * (int) $days_between_checks ) ) < $last_check ) {
			return;
		}

		// In case the operation fails, ensure the timestamp has been updated.
		$cache->write( $cache_key, (string) time() );

		// Check whether any updates are available.
		ob_start();
		FP_CLI::run_command(
			[ 'cli', 'check-update' ],
			[
				'format' => 'count',
			]
		);
		$count = ob_get_clean();
		if ( ! $count ) {
			return;
		}

		// Looks like an update is available, so let's prompt to update.
		FP_CLI::run_command( [ 'cli', 'update' ] );
		// If the Phar was replaced, we can't proceed with the original process.
		exit;
	}

	/**
	 * Get a suggestion on similar (sub)commands when the user entered an
	 * unknown (sub)command.
	 *
	 * @param string                $entry        User entry that didn't match an
	 *                                            existing command.
	 * @param CompositeCommand|null $root_command Root command to start search for
	 *                                            suggestions at.
	 *
	 * @return string Suggestion that fits the user entry, or an empty string.
	 */
	private function get_subcommand_suggestion( $entry, $root_command = null ) {
		$commands = [];
		if ( ( $root_command instanceof CompositeCommand ) === false ) {
			$root_command = FP_CLI::get_root_command();
		}
		$this->enumerate_commands( $root_command, $commands );

		return Utils\get_suggestion( $entry, $commands, $threshold = 2 );
	}

	/**
	 * Recursive method to enumerate all known commands.
	 *
	 * @param CompositeCommand $command Composite command to recurse over.
	 * @param array            $list    Reference to list accumulating results.
	 * @param string           $parent  Parent command to use as prefix.
	 */
	private function enumerate_commands( CompositeCommand $command, array &$list, $parent = '' ): void {
		foreach ( $command->get_subcommands() as $subcommand ) {
			/** @var CompositeCommand $subcommand */
			$command_string = empty( $parent )
				? $subcommand->get_name()
				: "{$parent} {$subcommand->get_name()}";

			$list[] = $command_string;

			$this->enumerate_commands( $subcommand, $list, $command_string );
		}
	}

	/**
	 * Enables (almost) full PHP error reporting to stderr.
	 */
	private function enable_error_reporting(): void {
		if ( E_ALL !== error_reporting() ) {
			// Don't enable E_DEPRECATED as old versions of FP use PHP 4 style constructors and the mysql extension.
			error_reporting( E_ALL & ~E_DEPRECATED );
		}
		ini_set( 'display_errors', 'stderr' ); // phpcs:ignore FinPress.PHP.IniSet.display_errors_Disallowed
	}
}
