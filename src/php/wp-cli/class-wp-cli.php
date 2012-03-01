<?php

/**
 * Wrapper class for WP-CLI
 *
 * @package wp-cli
 */
class WP_CLI {

	static $commands = array();

	/**
	 * Add a command to the wp-cli list of commands
	 *
	 * @param string $name The name of the command that will be used in the cli
	 * @param string $class The class to manage the command
	 */
	public function addCommand( $name, $class ) {
		self::$commands[$name] = $class;
	}

	/**
	 * Display a message in the cli
	 *
	 * @param string $message
	 */
	static function out( $message ) {
	    if ( defined( 'WP_CLI_SILENT' ) && WP_CLI_SILENT ) return;
		\cli\out($message);
	}

	/**
	 * Display a message in the CLI and end with a newline
	 *
	 * @param string $message
	 */
	static function line( $message = '' ) {
	    if ( defined( 'WP_CLI_SILENT' ) && WP_CLI_SILENT ) return;
		\cli\line($message);
	}

	/**
	 * Display an error in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function error( $message, $label = 'Error' ) {
		\cli\err( '%R' . $label . ': %n' . self::errorToString( $message ) );
		exit(1);
	}

	/**
	 * Display a success in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function success( $message, $label = 'Success' ) {
	    if ( defined( 'WP_CLI_SILENT' ) && WP_CLI_SILENT ) return;
		\cli\line( '%G' . $label . ': %n' . $message );
	}

	/**
	 * Display a warning in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function warning( $message, $label = 'Warning' ) {
	    if ( defined( 'WP_CLI_SILENT' ) && WP_CLI_SILENT ) return;
		\cli\line( '%C' . $label . ': %n' . $message );
	}

	/**
	 * Convert a wp_error into a String
	 *
	 * @param mixed $errors
	 * @return string
	 */
	static function errorToString( $errors ) {
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
	 * Splits a string into positional and associative arguments.
	 *
	 * @param string
	 * @return array
	 */
	static function parse_args( $arguments ) {
		$regular_args = array();
		$assoc_args = array();

		foreach ( $arguments as $arg ) {
			if ( preg_match( '|^--(\w+)$|', $arg, $matches ) ) {
				$assoc_args[ $matches[1] ] = true;
			} elseif ( preg_match( '|^--(\w+)=(.+)|', $arg, $matches ) ) {
				$assoc_args[ $matches[1] ] = $matches[2];
			} else {
				$regular_args[] = $arg;
			}
		}

		return array( $regular_args, $assoc_args );
	}

	/**
	 * Composes positional and associative arguments into a string
	 *
	 * @param array
	 * @return string
	 */
	static function compose_args( $args, $assoc_args = array() ) {
		$str = implode( ' ', $args );

		foreach ( $assoc_args as $key => $value ) {
			if ( true == $value )
				$str .= " --$key";
			else
				$str .= " --$key=$value";
		}

		return $str;
	}

	/**
	 * Display a legend
	 *
	 * @param array( code => title ) $legend
	 */
	static function legend( $legend ) {
		$legend[ '%yU' ] = 'Update Available';

		$legend_line = array();
		foreach ( $legend as $key => $title )
			$legend_line[] = "$key = $title%n";

		WP_CLI::line( 'Legend: ' . implode( ', ', $legend_line ) );
	}

	/**
	 * Sets the appropriate $_SERVER keys based on a given string
	 *
	 * @param string $url The URL
	 */
	static function set_url( $url ) {
	    $url_parts = parse_url( $url );
	    
	    if ( !isset( $url_parts['scheme'] ) ) {
	        $url_parts = parse_url( 'http://' . $url );
	    }
	    
		$_SERVER['HTTP_HOST'] = $url_parts['host'];
		$_SERVER['REQUEST_URI'] = $url_parts['path'] . (isset($url_parts['query']) ? '?' . $url_parts['query'] : '');
		$_SERVER['REQUEST_URL'] = $url_parts['path'];
		$_SERVER['QUERY_STRING'] = $url_parts['query'];
	}

	/**
	 * Return the beginning of the status line for a certain plugin or theme
	 *
	 * @param string $item The plugin or theme name
	 * @param string $key The transient key
	 *
	 * @return string
	 */
	static function get_update_status( $item, $key ) {
		$update_list = get_site_transient( $key );

		if ( isset( $update_list->response[ $item ] ) )
			return true;

		return false;
	}

	static function get_upgrader( $class ) {
		if ( !class_exists( 'WP_Upgrader' ) )
			require_once ABSPATH . 'wp-admin/includes/class-wp-upgrader.php';

		require WP_CLI_ROOT . '/class-cli-upgrader-skin.php';

		return new $class( new CLI_Upgrader_Skin );
	}
}

