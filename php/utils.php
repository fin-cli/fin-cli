<?php

// Utilities that do NOT depend on WordPress code.

namespace WP_CLI\Utils;

use \WP_CLI\Dispatcher;

function load_dependencies() {
	$vendor_paths = array(
		WP_CLI_ROOT . '/vendor',           // top-level project
		WP_CLI_ROOT . '/../../../vendor',  // part of a larger project
	);

	$has_autoload = false;

	foreach ( $vendor_paths as $vendor_path ) {
		if ( file_exists( $vendor_path . '/autoload.php' ) ) {
			require $vendor_path . '/autoload.php';
			$has_autoload = true;
			break;
		}
	}

	if ( !$has_autoload ) {
		fputs( STDERR, "Internal error: Can't find Composer autoloader.\n" );
		exit(3);
	}

	include WP_CLI_ROOT . '/php/Spyc.php';
}

function load_command( $name ) {
	$path = WP_CLI_ROOT . "/php/commands/$name.php";

	if ( is_readable( $path ) ) {
		include_once $path;
	}
}

function load_all_commands() {
	$cmd_dir = WP_CLI_ROOT . "/php/commands";

	$iterator = new \DirectoryIterator( $cmd_dir );

	foreach ( $iterator as $filename ) {
		if ( '.php' != substr( $filename, -4 ) )
			continue;

		include_once "$cmd_dir/$filename";
	}
}

/**
 * Search for file by walking up the directory tree until the first file is found or until $stop_check($dir) returns true
 * @param string|array The files (or file) to search for
 * @param string|null The directory to start searching from; defaults to CWD
 * @param callable Function which is passed the current dir each time a directory level is traversed
 * @return null|string Null if the file was not found
 */
function find_file_upward( $files, $dir = null, $stop_check = null ) {
	$files = (array) $files;
	if ( is_null( $dir ) ) {
		$dir = getcwd();
	}
	while ( is_readable( $dir ) ) {
		// Stop walking up when the supplied callable returns true being passed the $dir
		if ( is_callable( $stop_check ) && call_user_func( $stop_check, $dir ) ) {
			return null;
		}

		foreach ( $files as $file ) {
			$path = $dir . DIRECTORY_SEPARATOR . $file;
			if ( file_exists( $path ) ) {
				return $path;
			}
		}

		$parent_dir = dirname( $dir );
		if ( empty($parent_dir) || $parent_dir === $dir ) {
			break;
		}
		$dir = $parent_dir;
	}
	return null;
}

function is_path_absolute( $path ) {
	// Windows
	if ( ':' === $path[1] )
		return true;

	return $path[0] === '/';
}

/**
 * Composes positional arguments into a command string.
 *
 * @param array
 * @return string
 */
function args_to_str( $args ) {
	return ' ' . implode( ' ', array_map( 'escapeshellarg', $args ) );
}

/**
 * Composes associative arguments into a command string.
 *
 * @param array
 * @return string
 */
function assoc_args_to_str( $assoc_args ) {
	$str = '';

	foreach ( $assoc_args as $key => $value ) {
		if ( true === $value )
			$str .= " --$key";
		else
			$str .= " --$key=" . escapeshellarg( $value );
	}

	return $str;
}

/**
 * Given a template string and an arbitrary number of arguments,
 * returns the final command, with the parameters escaped.
 */
function esc_cmd( $cmd ) {
	if ( func_num_args() < 2 )
		trigger_error( 'esc_cmd() requires at least two arguments.', E_USER_WARNING );

	$args = func_get_args();

	$cmd = array_shift( $args );

	return vsprintf( $cmd, array_map( 'escapeshellarg', $args ) );
}

/**
 * Sets the appropriate $_SERVER keys based on a given string
 *
 * @param string $url The URL
 */
function set_url_params( $url ) {
	$url_parts = parse_url( $url );

	if ( !isset( $url_parts['scheme'] ) ) {
		$url_parts = parse_url( 'http://' . $url );
	}

	$f = function( $key ) use ( $url_parts ) {
		return isset( $url_parts[ $key ] ) ? $url_parts[ $key ] : '';
	};

	if ( isset( $url_parts['host'] ) ) {
		$_SERVER['HTTP_HOST'] = $url_parts['host'];
		if ( isset( $url_parts['port'] ) ) {
			$_SERVER['HTTP_HOST'] .= ':' . $url_parts['port'];
		}

		$_SERVER['SERVER_NAME'] = substr($_SERVER['HTTP_HOST'], 0, strrpos($_SERVER['HTTP_HOST'], '.'));
	}

	$_SERVER['REQUEST_URI'] = $f('path') . ( isset( $url_parts['query'] ) ? '?' . $url_parts['query'] : '' );
	$_SERVER['SERVER_PORT'] = isset( $url_parts['port'] ) ? $url_parts['port'] : '80';
	$_SERVER['QUERY_STRING'] = $f('query');
	$_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.0';
	$_SERVER['HTTP_USER_AGENT'] = '';
	$_SERVER['REQUEST_METHOD'] = 'GET';
}

function locate_wp_config() {
	static $path;

	if ( null === $path ) {
		if ( file_exists( ABSPATH . 'wp-config.php' ) )
			$path = ABSPATH . 'wp-config.php';
		elseif ( file_exists( ABSPATH . '../wp-config.php' ) && ! file_exists( ABSPATH . '/../wp-settings.php' ) )
			$path = ABSPATH . '../wp-config.php';
		else
			$path = false;

		if ( $path )
			$path = realpath( $path );
	}

	return $path;
}

/**
 * Take a serialised array and unserialise it replacing elements as needed and
 * unserialising any subordinate arrays and performing the replace on those too.
 *
 * @source https://github.com/interconnectit/Search-Replace-DB
 *
 * @param string $from       String we're looking to replace.
 * @param string $to         What we want it to be replaced with
 * @param array  $data       Used to pass any subordinate arrays back to in.
 * @param bool   $serialised Does the array passed via $data need serialising.
 *
 * @return array	The original array with all elements replaced as needed.
 */
function recursive_unserialize_replace( $from = '', $to = '', $data = '', $serialised = false ) {

	// some unseriliased data cannot be re-serialised eg. SimpleXMLElements
	try {

		if ( is_string( $data ) && ( $unserialized = @unserialize( $data ) ) !== false ) {
			$data = recursive_unserialize_replace( $from, $to, $unserialized, true );
		}

		elseif ( is_array( $data ) ) {
			$_tmp = array( );
			foreach ( $data as $key => $value ) {
				$_tmp[ $key ] = recursive_unserialize_replace( $from, $to, $value, false );
			}

			$data = $_tmp;
			unset( $_tmp );
		}

		// Submitted by Tina Matter
		elseif ( is_object( $data ) ) {
			$dataClass = get_class( $data );

			$canReplace = true;
			if ( method_exists( $dataClass, '__construct' ) ) {
				$classConstructor = new \ReflectionMethod( $dataClass, '__construct' );

				if ( ! $classConstructor->isPublic() )
					$canReplace = false;
			}

			if ( $canReplace ) {
				$_tmp = new $dataClass();
				foreach ( $data as $key => $value ) {
					$_tmp->$key = recursive_unserialize_replace( $from, $to, $value, false );
				}

				$data = $_tmp;
				unset( $_tmp );
			}
		}

		else {
			if ( is_string( $data ) )
				$data = str_replace( $from, $to, $data );
		}

		if ( $serialised )
			return serialize( $data );

	} catch( Exception $error ) {

	}

	return $data;
}

/**
 * Output items in a table, JSON, CSV, ids, or the total count
 *
 * @param string        $format     Format to use: 'table', 'json', 'csv', 'ids', 'count'
 * @param array         $items      Data to output
 * @param array|string  $fields     Named fields for each item of data. Can be array or comma-separated list
 */
function format_items( $format, $items, $fields ) {
	
	if ( 'ids' == $format ) {
		echo implode( ' ', $items );
		return;
	} else if ( 'count' == $format ) {
		echo count( $items );
		return;
	}

	if ( ! is_array( $fields ) )
		$fields = explode( ',', $fields );

	$output_items = array();
	foreach ( $items as $item ) {

		$output_item = new \stdClass;
		foreach ( $fields as $key => $field ) {

			if ( ! isset( $item->$field ) ) {
				unset( $fields[$key] );
				continue;
			}

			$output_item->$field = $item->$field;
		}

		$output_items[] = $output_item;
	}

	switch ( $format ) {
		case 'table':
			$table = new \cli\Table();

			$table->setHeaders( $fields );

			foreach ( $output_items as $item ) {
				$table->addRow( array_values( (array)$item ) );
			}

			$table->display();
			break;
		case 'csv':
		case 'json':

			if ( 'json' == $format )
				echo json_encode( $output_items );
			else
				write_csv( STDOUT, $output_items, $fields );
			break;
	}
}

/**
 * Write data as CSV to a given file.
 *
 * @param resource $fd         File descriptor
 * @param array    $rows       Array of rows to output
 * @param array    $headers    List of CSV columns (optional)
 */
function write_csv( $fd, $rows, $headers = array() ) {

	// Prepare the headers if they were specified
	if ( ! empty( $headers ) )
		fputcsv( $fd, $headers );

	foreach ( $rows as $row ) {
		$row = (array) $row;

		if ( ! empty( $headers ) ) {
			$build_row = array();
			foreach ( $headers as $key ) {
				$build_row[] = $row[ $key ];
			}
			$row = $build_row;
		}
		fputcsv( $fd, $row );
	}

}

/**
 * Launch system's $EDITOR to edit text
 *
 * @param  str  $content  Text to edit (eg post content)
 * @return str|bool       Edited text, if file is saved from editor
 *                        False, if no change to file
 */
function launch_editor_for_input( $input, $title = 'WP-CLI' ) {

	$tmpfile = wp_tempnam( $title );

	if ( !$tmpfile )
		\WP_CLI::error( 'Error creating temporary file.' );

	file_put_contents( $tmpfile, $input );

	\WP_CLI::launch( "\${EDITOR:-vi} '$tmpfile'" );

	$output = file_get_contents( $tmpfile );

	unlink( $tmpfile );

	if ( $output === $input )
		return false;

	return $output;
}

function run_mysql_query( $query, $args ) {
	// TODO: use PDO?

  $host_parts = explode( ':',  $args['host'] );
  if ( count( $host_parts ) == 2 ) {
    list( $host, $extra ) = $host_parts;
  } else {
    $host = $args['host'];
  }

	$arg_str = esc_cmd( '--host=%s --user=%s --execute=%s',
		$host, $args['user'], $query );

  if ( isset( $extra ) ) {
    if ( is_numeric($extra) ) {
      $arg_str .= esc_cmd( ' --port=%s --protocol=%s', intval( $extra ), 'tcp' );
    } else if ( trim($extra) !== '' ) {
      $arg_str .= esc_cmd( ' --socket=%s', trim( $extra ) );
    }
  }

	run_mysql_command( 'mysql', $arg_str, $args['pass'] );
}

function run_mysql_command( $cmd, $arg_str, $pass ) {
	$old_val = getenv( 'MYSQL_PWD' );

	$final_cmd = "$cmd --no-defaults $arg_str";

	putenv( 'MYSQL_PWD=' . $pass );
	$r = proc_close( proc_open( $final_cmd, array( STDIN, STDOUT, STDERR ), $pipes ) );
	putenv( 'MYSQL_PWD=' . $old_val );

	if ( $r ) exit( $r );
}

function mustache_render( $template_name, $data ) {
	$template = file_get_contents( WP_CLI_ROOT . "/templates/$template_name" );

	$m = new \Mustache_Engine;

	return $m->render( $template, $data );
}

function make_progress_bar( $message, $count ) {
	if ( \cli\Shell::isPiped() )
		return new \WP_CLI\NoOp;

	return new \cli\progress\Bar( $message, $count );
}

