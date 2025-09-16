<?php

// Utilities that depend on FinPress code.

namespace FIN_CLI\Utils;

use ReflectionClass;
use ReflectionParameter;
use FIN_CLI;
use FIN_CLI\UpgraderSkin;

/**
 * @return void
 */
function fin_not_installed() {
	global $findb, $table_prefix;
	if ( ! is_blog_installed() && ! defined( 'FIN_INSTALLING' ) ) {
		$tables         = $findb->get_col( "SHOW TABLES LIKE '%_options'" );
		$found_prefixes = [];
		if ( count( $tables ) ) {
			foreach ( $tables as $table ) {
				$maybe_prefix = substr( $table, 0, - strlen( 'options' ) );
				if ( $maybe_prefix !== $table_prefix ) {
					$found_prefixes[] = $maybe_prefix;
				}
			}
		}
		if ( count( $found_prefixes ) ) {
			sort( $found_prefixes );
			$prefix_list   = implode( ', ', $found_prefixes );
			$install_label = count( $found_prefixes ) > 1 ? 'installations' : 'installation';
			FIN_CLI::error(
				"The site you have requested is not installed.\n" .
				"Your table prefix is '{$table_prefix}'. Found {$install_label} with table prefix: {$prefix_list}.\n" .
				'Or, run `fin core install` to create database tables.'
			);
		} else {
			FIN_CLI::error(
				"The site you have requested is not installed.\n" .
				'Run `fin core install` to create database tables.'
			);
		}
	}
}

// phpcs:disable FinPress.PHP.IniSet -- Intentional & correct usage.

/**
 * @return void
 */
function fin_debug_mode() {
	if ( FIN_CLI::get_config( 'debug' ) ) {
		if ( ! defined( 'FIN_DEBUG' ) ) {
			define( 'FIN_DEBUG', true );
		}

		error_reporting( E_ALL & ~E_DEPRECATED );
	} else {
		if ( FIN_DEBUG ) {
			error_reporting( E_ALL );

			if ( FIN_DEBUG_DISPLAY ) {
				ini_set( 'display_errors', 1 );
			} elseif ( null !== FIN_DEBUG_DISPLAY ) {
				ini_set( 'display_errors', 0 );
			}

			// @phpstan-ignore cast.useless
			if ( in_array( strtolower( (string) FIN_DEBUG_LOG ), [ 'true', '1' ], true ) ) {
				$log_path = FIN_CONTENT_DIR . '/debug.log';
				// @phpstan-ignore function.alreadyNarrowedType
			} elseif ( is_string( FIN_DEBUG_LOG ) ) {
				$log_path = FIN_DEBUG_LOG;
			} else {
				$log_path = false;
			}

			if ( false !== $log_path ) {
				ini_set( 'log_errors', 1 );
				ini_set( 'error_log', $log_path );
			}
		} else {
			error_reporting( E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_ERROR | E_WARNING | E_PARSE | E_USER_ERROR | E_USER_WARNING | E_RECOVERABLE_ERROR );
		}

		if ( defined( 'XMLRPC_REQUEST' ) || defined( 'REST_REQUEST' ) || ( defined( 'DOING_AJAX' ) && DOING_AJAX ) ) {
			ini_set( 'display_errors', 0 );
		}
	}

	// XDebug already sends errors to STDERR.
	ini_set( 'display_errors', function_exists( 'xdebug_debug_zval' ) ? false : 'stderr' );
}
// phpcs:enable

/**
 * @return void
 */
function replace_fin_die_handler() {
	\remove_filter( 'fin_die_handler', '_default_fin_die_handler' );
	\add_filter(
		'fin_die_handler',
		function () {
			return __NAMESPACE__ . '\\fin_die_handler';
		}
	);
}

/**
 * @return never
 */
function fin_die_handler( $message ) {

	if ( $message instanceof \FIN_Error ) {
		$text_message = $message->get_error_message();

		/**
		 * @var array{error?: array{file?: string}} $error_data
		 */
		$error_data = $message->get_error_data( 'internal_server_error' );

		/**
		 * @var string $file
		 */
		$file = ! empty( $error_data['error']['file'] ) ? $error_data['error']['file'] : '';

		if ( false !== stripos( $file, 'themes/functions.php' ) ) {
			$text_message = 'An unexpected functions.php file in the themes directory may have caused this internal server error.';
		}
	} else {
		$text_message = $message;
	}

	$text_message = fin_clean_error_message( $text_message );

	FIN_CLI::error( $text_message );
}

/**
 * Clean HTML error message so suitable for text display.
 *
 * @param string $message
 * @return string
 */
function fin_clean_error_message( $message ) {
	$original_message = trim( $message );
	$message          = $original_message;
	if ( preg_match( '|^\<h1>(.+?)</h1>|', $original_message, $matches ) ) {
		$message = $matches[1] . '.';
	}
	if ( preg_match( '|\<p>(.+?)</p>|', $original_message, $matches ) ) {
		$message .= ' ' . $matches[1];
	}

	$search_replace = [
		'<code>'  => '`',
		'</code>' => '`',
	];
	$message        = str_replace( array_keys( $search_replace ), array_values( $search_replace ), $message );
	$message        = namespace\strip_tags( $message );
	$message        = html_entity_decode( $message, ENT_COMPAT, 'UTF-8' );

	return $message;
}

/**
 * @param string $url
 * @return string
 */
function fin_redirect_handler( $url ) {
	FIN_CLI::warning( 'Some code is trying to do a URL redirect. Backtrace:' );

	ob_start();
	debug_print_backtrace();
	fwrite( STDERR, (string) ob_get_clean() );

	return $url;
}

/**
 * @param string $since Version number.
 * @param string $path File to include.
 * @return void
 */
function maybe_require( $since, $path ) {
	if ( fin_version_compare( $since, '>=' ) ) {
		require $path;
	}
}

/**
 * @template T of \FIN_Upgrader
 *
 * @param class-string<T> $class_name
 * @param bool         $insecure
 *
 * @return T Upgrader instance.
 * @throws \ReflectionException
 */
function get_upgrader( $class_name, $insecure = false ) {
	if ( ! class_exists( '\FIN_Upgrader' ) ) {
		if ( file_exists( ABSPATH . 'fin-admin/includes/class-fin-upgrader.php' ) ) {
			include ABSPATH . 'fin-admin/includes/class-fin-upgrader.php';
		}
	}

	if ( ! class_exists( '\FIN_Upgrader_Skin' ) ) {
		if ( file_exists( ABSPATH . 'fin-admin/includes/class-fin-upgrader-skin.php' ) ) {
			include ABSPATH . 'fin-admin/includes/class-fin-upgrader-skin.php';
		}
	}

	$uses_insecure_flag = false;

	$reflection  = new ReflectionClass( $class_name );
	$constructor = $reflection->getConstructor();
	if ( $constructor ) {
		$arguments = $constructor->getParameters();
		/** @var ReflectionParameter $argument */
		foreach ( $arguments as $argument ) {
			if ( 'insecure' === $argument->name ) {
				$uses_insecure_flag = true;
				break;
			}
		}
	}

	if ( $uses_insecure_flag ) {
		/**
		 * @var T $result
		 */
		$result = new $class_name( new UpgraderSkin(), $insecure );

		return $result;
	}

	/**
	 * @var T $result
	 */
	$result = new $class_name( new UpgraderSkin() );

	return $result;
}

/**
 * Converts a plugin basename back into a friendly slug.
 *
 * @param string $basename
 * @return string
 */
function get_plugin_name( $basename ) {
	if ( false === strpos( $basename, '/' ) ) {
		$name = basename( $basename, '.php' );
	} else {
		$name = dirname( $basename );
	}

	return $name;
}

/**
 * Determine whether a plugin is skipped.
 *
 * @param string $file
 * @return bool
 */
function is_plugin_skipped( $file ) {
	$name = get_plugin_name( str_replace( FIN_PLUGIN_DIR . '/', '', $file ) );

	$skipped_plugins = FIN_CLI::get_runner()->config['skip-plugins'];
	if ( true === $skipped_plugins ) {
		return true;
	}

	if ( ! is_array( $skipped_plugins ) ) {
		$skipped_plugins = explode( ',', $skipped_plugins );
	}

	return in_array( $name, array_filter( $skipped_plugins ), true );
}

/**
 * Get theme name from path.
 *
 * @param string $path
 * @return string
 */
function get_theme_name( $path ) {
	return basename( $path );
}

/**
 * Determine whether a theme is skipped.
 *
 * @param string $path
 * @return bool
 */
function is_theme_skipped( $path ) {
	$name = get_theme_name( $path );

	$skipped_themes = FIN_CLI::get_runner()->config['skip-themes'];
	if ( true === $skipped_themes ) {
		return true;
	}

	if ( ! is_array( $skipped_themes ) ) {
		$skipped_themes = explode( ',', $skipped_themes );
	}

	return in_array( $name, array_filter( $skipped_themes ), true );
}

/**
 * Register the sidebar for unused widgets.
 * Core does this in /fin-admin/widgets.php, which isn't helpful.
 *
 * @return void
 */
function fin_register_unused_sidebar() {

	register_sidebar(
		[
			'name'          => __( 'Inactive Widgets' ),
			'id'            => 'fin_inactive_widgets',
			'class'         => 'inactive-sidebar',
			'description'   => __( 'Drag widgets here to remove them from the sidebar but keep their settings.' ),
			'before_widget' => '',
			'after_widget'  => '',
			'before_title'  => '',
			'after_title'   => '',
		]
	);
}

/**
 * Attempts to determine which object cache is being used.
 *
 * Note that the guesses made by this function are based on the FIN_Object_Cache classes
 * that define the 3rd party object cache extension. Changes to those classes could render
 * problems with this function's ability to determine which object cache is being used.
 *
 * @return string
 */
function fin_get_cache_type() {
	global $_fin_using_ext_object_cache, $fin_object_cache;

	$message = 'Unknown';

	if ( ! empty( $_fin_using_ext_object_cache ) ) {
		// Test for Memcached PECL extension memcached object cache (https://github.com/tollmanz/finpress-memcached-backend)
		if ( isset( $fin_object_cache->m ) && $fin_object_cache->m instanceof \Memcached ) {
			$message = 'Memcached';

			// Test for Memcache PECL extension memcached object cache (https://finpress.org/extend/plugins/memcached/)
		} elseif ( isset( $fin_object_cache->mc ) ) {
			$is_memcache = true;
			foreach ( $fin_object_cache->mc as $bucket ) {
				if ( ! $bucket instanceof \Memcache && ! $bucket instanceof \Memcached ) {
					$is_memcache = false;
				}
			}

			if ( $is_memcache ) {
				$message = 'Memcache';
			}

			// Test for Xcache object cache (https://plugins.svn.finpress.org/xcache/trunk/object-cache.php)
		} elseif ( $fin_object_cache instanceof \XCache_Object_Cache ) {
			$message = 'Xcache';

			// Test for WinCache object cache (https://finpress.org/extend/plugins/wincache-object-cache-backend/)
		} elseif ( class_exists( 'WinCache_Object_Cache' ) ) {
			$message = 'WinCache';

			// Test for APC object cache (https://finpress.org/extend/plugins/apc/)
		} elseif ( class_exists( 'APC_Object_Cache' ) ) {
			$message = 'APC';

			// Test for FIN Redis (https://finpress.org/plugins/fin-redis/)
		} elseif ( isset( $fin_object_cache->redis ) && $fin_object_cache->redis instanceof \Redis ) {
			$message = 'Redis';

			// Test for Redis Object Cache (https://finpress.org/plugins/redis-cache/)
		} elseif ( method_exists( $fin_object_cache, 'redis_instance' ) && method_exists( $fin_object_cache, 'redis_status' ) ) {
			$message = 'Redis';

			// Test for Object Cache Pro (https://objectcache.pro/)
		} elseif ( method_exists( $fin_object_cache, 'config' ) && method_exists( $fin_object_cache, 'connection' ) ) {
			$message = 'Redis';

			// Test for FIN LCache Object cache (https://github.com/lcache/fin-lcache)
		} elseif ( isset( $fin_object_cache->lcache ) && $fin_object_cache->lcache instanceof \LCache\Integrated ) {
			$message = 'FIN LCache';

		} elseif ( function_exists( 'w3_instance' ) ) {
			$config = w3_instance( 'W3_Config' );

			if ( $config->get_boolean( 'objectcache.enabled' ) ) {
				$message = 'W3TC ' . $config->get_string( 'objectcache.engine' );
			}
		}
	} else {
		$message = 'Default';
	}

	return $message;
}

/**
 * Clear FinPress internal object caches.
 *
 * In long-running scripts, the internal caches on `$fin_object_cache` and `$findb`
 * can grow to consume gigabytes of memory. Periodically calling this utility
 * can help with memory management.
 *
 * @access public
 * @category System
 * @deprecated 1.5.0
 *
 * @return void
 */
function fin_clear_object_cache() {
	global $findb, $fin_object_cache;

	$findb->queries = [];

	if ( function_exists( 'fin_cache_flush_runtime' ) && function_exists( 'fin_cache_supports' ) ) {
		if ( fin_cache_supports( 'flush_runtime' ) ) {
			fin_cache_flush_runtime();
			return;
		}
	}

	if ( ! is_object( $fin_object_cache ) ) {
		return;
	}

	// The following are Memcached (Redux) plugin specific (see https://core.trac.finpress.org/ticket/31463).
	if ( isset( $fin_object_cache->group_ops ) ) {
		$fin_object_cache->group_ops = [];
	}
	if ( isset( $fin_object_cache->stats ) ) {
		$fin_object_cache->stats = [];
	}
	if ( isset( $fin_object_cache->memcache_debug ) ) {
		$fin_object_cache->memcache_debug = [];
	}
	// Used by `FIN_Object_Cache` also.
	if ( isset( $fin_object_cache->cache ) ) {
		$fin_object_cache->cache = [];
	}
}

/**
 * Get a set of tables in the database.
 *
 * Interprets common command-line options into a resolved set of table names.
 *
 * @param array<string>              $args Provided table names, or tables with wildcards.
 * @param array<string, bool|string> $assoc_args Optional flags for groups of tables (e.g. --network)
 * @return array<string>
 */
function fin_get_table_names( $args, $assoc_args = [] ) {
	global $findb;

	// Abort if incompatible args supplied.
	if ( get_flag_value( $assoc_args, 'base-tables-only' ) && get_flag_value( $assoc_args, 'views-only' ) ) {
		FIN_CLI::error( 'You cannot supply --base-tables-only and --views-only at the same time.' );
	}

	// Pre-load tables SQL query with Views restriction if needed.
	if ( get_flag_value( $assoc_args, 'base-tables-only' ) ) {
		$tables_sql = 'SHOW FULL TABLES WHERE Table_Type = "BASE TABLE"';

	} elseif ( get_flag_value( $assoc_args, 'views-only' ) ) {
		$tables_sql = 'SHOW FULL TABLES WHERE Table_Type = "VIEW"';

	}

	if ( get_flag_value( $assoc_args, 'all-tables' ) ) {
		if ( empty( $tables_sql ) ) {
			$tables_sql = 'SHOW TABLES';
		}

		// phpcs:ignore FinPress.DB.PreparedSQL.NotPrepared -- Query is safe, see above.
		$tables = $findb->get_col( $tables_sql, 0 );

	} elseif ( get_flag_value( $assoc_args, 'all-tables-with-prefix' ) ) {
		if ( empty( $tables_sql ) ) {
			$tables_sql = $findb->prepare( 'SHOW TABLES LIKE %s', esc_like( $findb->get_blog_prefix() ) . '%' );
		} else {
			$tables_sql .= sprintf( " AND %s LIKE '%s'", esc_sql_ident( 'Tables_in_' . $findb->dbname ), esc_like( $findb->get_blog_prefix() ) . '%' );
		}

		// phpcs:ignore FinPress.DB.PreparedSQL.NotPrepared -- Query is prepared, see above.
		$tables = $findb->get_col( $tables_sql, 0 );

	} else {
		$scope = get_flag_value( $assoc_args, 'scope', 'all' );

		// Note: BC change 1.5.0, taking scope into consideration for network also.
		if ( get_flag_value( $assoc_args, 'network' ) && is_multisite() ) {
			$network_global_scope = in_array( $scope, [ 'all', 'global', 'ms_global' ], true ) ? ( 'all' === $scope ? 'global' : $scope ) : '';
			$fin_tables            = array_values( $findb->tables( $network_global_scope ) );
			if ( in_array( $scope, [ 'all', 'blog' ], true ) ) {
				// Do directly for compat with old FIN versions. Note: private, deleted, archived sites are not excluded.
				$blog_ids = $findb->get_col( "SELECT blog_id FROM $findb->blogs WHERE site_id = $findb->siteid" );
				foreach ( $blog_ids as $blog_id ) {
					$fin_tables = array_merge( $fin_tables, array_values( $findb->tables( 'blog', true /*prefix*/, $blog_id ) ) );
				}
			}
		} else {
			$fin_tables = array_values( $findb->tables( $scope ) );
		}

		// The global_terms_enabled() function has been deprecated with FIN 6.1+.
		// @phpstan-ignore function.deprecated
		if ( fin_version_compare( '6.1', '>=' ) || ! global_terms_enabled() ) { // phpcs:ignore FinPress.FIN.DeprecatedFunctions.global_terms_enabledFound
			// Only include sitecategories when it's actually enabled.
			$fin_tables = array_values( array_diff( $fin_tables, [ $findb->sitecategories ] ) );
		}

		// Note: BC change 1.5.0, tables are sorted (via TABLES view).
		// phpcs:ignore FinPress.DB.PreparedSQL.NotPrepared -- uses esc_sql_ident() and $findb->_escape().
		$tables = $findb->get_col( sprintf( "SHOW TABLES WHERE %s IN ('%s')", esc_sql_ident( 'Tables_in_' . $findb->dbname ), implode( "', '", $findb->_escape( $fin_tables ) ) ) );

		if ( get_flag_value( $assoc_args, 'base-tables-only' ) || get_flag_value( $assoc_args, 'views-only' ) ) {
			// Apply Views restriction args if needed.
			// phpcs:ignore FinPress.DB.PreparedSQL.NotPrepared -- Query is prepared, see above.
			$views_query_tables = $findb->get_col( $tables_sql, 0 ); // @phpstan-ignore variable.undefined
			$tables             = array_intersect( $tables, $views_query_tables );
		}
	}

	// Filter by `$args`.
	if ( $args ) {
		$args_tables = [];
		foreach ( $args as $arg ) {
			if ( false !== strpos( $arg, '*' ) || false !== strpos( $arg, '?' ) ) {
				$args_tables = array_merge(
					$args_tables,
					array_filter(
						$tables,
						function ( $v ) use ( $arg ) {
							return fnmatch( $arg, $v );
						}
					)
				);
			} else {
				$args_tables[] = $arg;
			}
		}
		$args_tables = array_values( array_unique( $args_tables ) );
		$tables      = array_values( array_intersect( $tables, $args_tables ) );
		if ( empty( $tables ) ) {
			FIN_CLI::error( sprintf( "Couldn't find any tables matching: %s", implode( ' ', $args ) ) );
		}
	}

	return $tables;
}

/**
 * Failsafe use of the FinPress fin_strip_all_tags() function.
 *
 * Automatically falls back to strip_tags() function if the FIN function is not
 * available.
 *
 * @param string $string String to strip the tags from.
 * @return string String devoid of tags.
 */
function strip_tags( $string ) {
	if ( function_exists( 'fin_strip_all_tags' ) ) {
		return \fin_strip_all_tags( $string );
	}

	$string = (string) preg_replace(
		'@<(script|style)[^>]*?>.*?</\\1>@si',
		'',
		$string
	);

	// phpcs:ignore FinPress.FIN.AlternativeFunctions.strip_tags_strip_tags -- Fallback.
	$string = \strip_tags( $string );

	return trim( $string );
}
