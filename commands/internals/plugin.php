<?php

WP_CLI::addCommand('plugin', 'PluginCommand');

require_once(ABSPATH.'wp-admin/includes/plugin.php');
require_once(ABSPATH.'wp-admin/includes/plugin-install.php');

/**
 * Implement plugin command
 *
 * @package wp-cli
 * @subpackage commands/internals
 * @author Andreas Creten
 */
class PluginCommand extends WP_CLI_Command {

	private $mu_plugins;

	/**
	 * Get the status of one or all plugins
	 *
	 * @param array $args
	 * @return void
	 */
	function status( $args = array(), $vars = array() ) {
		$this->mu_plugins = get_mu_plugins();

		if ( empty( $args ) ) {
			$this->list_plugins();
			return;
		}

		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__ );

		$details = $this->get_details( $file );

		$status = $this->get_status( $file, true );

		$version = $details[ 'Version' ];

		if ( WP_CLI::get_update_status( $file, 'update_plugins' ) )
			$version .= ' (%gUpdate available%n)';

		WP_CLI::line( 'Plugin %9' . $name . '%n details:' );
		WP_CLI::line( '    Status: ' . $status .'%n' );
		WP_CLI::line( '    Name: ' . $details[ 'Name' ] );
		WP_CLI::line( '    Version: ' . $version );
		WP_CLI::line( '    Author: ' . $details[ 'Author' ] );
		WP_CLI::line( '    Description: ' . $details[ 'Description' ] );
	}

	private function list_plugins() {
		// Force WordPress to update the plugin list
		wp_update_plugins();

		$plugins = get_plugins();

		$plugins = array_merge( $plugins, $this->mu_plugins );

		// Print the header
		WP_CLI::line('Installed plugins:');

		foreach ($plugins as $file => $plugin) {
			if ( false === strpos( $file, '/' ) )
				$name = str_replace('.php', '', basename($file));
			else
				$name = dirname($file);

			if ( WP_CLI::get_update_status( $file, 'update_plugins' ) ) {
				$line = ' %yU%n';
			} else {
				$line = '  ';
			}

			$line .= $this->get_status( $file ) . " $name%n";

			WP_CLI::line( $line );
		}

		// Print the footer
		WP_CLI::line();

		$legend = array(
			'I' => 'Inactive',
			'%gA' => 'Active',
			'%cM' => 'Must Use',
		);

		if ( is_multisite() )
			$legend['%bN'] = 'Network Active';

		WP_CLI::legend( $legend );
	}

	private function get_status( $file, $long = false ) {
		if ( isset( $this->mu_plugins[ $file ] ) ) {
			$line  = '%c';
			$line .= $long ? 'Must Use' : 'M';
		} elseif ( is_plugin_active_for_network( $file ) ) {
			$line  = '%b';
			$line .= $long ? 'Network Active' : 'N';
		} elseif ( is_plugin_active( $file ) ) {
			$line  = '%g';
			$line .= $long ? 'Active' : 'A';
		} else {
			$line  = $long ? 'Inactive' : 'I';
		}

		return $line;
	}

	/**
	 * Activate a plugin
	 *
	 * @param array $args
	 * @return void
	 */
	function activate( $args ) {
		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__ );

		activate_plugin( $file );

		if ( !is_plugin_active( $file ) ) {
			WP_CLI::error( 'Could not activate this plugin: ' . $name );
		} else {
			WP_CLI::line( 'Plugin activated.' );
		}
	}

	/**
	 * Deactivate a plugin
	 *
	 * @param array $args
	 * @return void
	 */
	function deactivate( $args ) {
		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__ );

		deactivate_plugins( $file );

		if ( !is_plugin_inactive( $file ) ) {
			WP_CLI::error( 'Could not deactivate this plugin: '.$name );
		} else {
			WP_CLI::line( 'Plugin deactivated.' );
		}
	}

	/**
	 * Toggle a plugin's activation state
	 *
	 * @param array $args
	 * @return void
	 */
	function toggle( $args ) {
		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__ );

		if ( is_plugin_active( $file ) ) {
			$this->deactivate( $args );
		} else {
			$this->activate( $args );
		}
	}

	/**
	 * Install a new plugin
	 *
	 * @param array $args
	 * @return void
	 */
	function install( $args ) {
		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__, false );

		// Force WordPress to update the plugin list
		wp_update_plugins();

		// Get plugin info from the WordPress servers
		$api = plugins_api( 'plugin_information', array( 'slug' => stripslashes( $name ) ) );
		$status = install_plugin_install_status( $api );

		WP_CLI::line( 'Installing '.$api->name.' ('.$api->version.')' );

		// Check what to do
		switch ( $status['status'] ) {
		case 'update_available':
		case 'install':
			if ( !class_exists( 'Plugin_Upgrader' ) ) {
				require_once( ABSPATH.'wp-admin/includes/class-wp-upgrader.php' );
			}

			// Install the plugin
			ob_start( 'strip_tags' );
			$upgrader = new Plugin_Upgrader( new CLI_Upgrader_Skin );
			$result = $upgrader->install( $api->download_link );
			$feedback = ob_get_clean();

			if ( $result !== null ) {
				WP_CLI::error( $result );
			}
			else {
				WP_CLI::line();
				WP_CLI::line( strip_tags( str_replace( array( '&#8230;', 'Plugin installed successfully.' ), array( " ...\n", '' ), html_entity_decode( $feedback ) ) ) );
				WP_CLI::success( 'The plugin is successfully installed' );
			}
			break;
		case 'newer_installed':
			WP_CLI::error( sprintf( 'Newer version ( %s ) installed', $status['version'] ) );
			break;
		case 'latest_installed':
			WP_CLI::error( 'Latest version already installed' );

			if ( is_plugin_inactive( $file ) ) {
				WP_CLI::warning( 'If you want to activate the plugin, run: %2wp plugin activate '.$name.'%n' );
			}
			break;
		}
	}

	/**
	 * Delete a plugin
	 *
	 * @param array $args
	 * @return void
	 */
	function delete( $args ) {
		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__ );

		if ( !delete_plugins( array( $file ) ) ) {
			WP_CLI::error( 'There was an error while deleting the plugin.' );
		}
	}

	/**
	 * Update a plugin
	 *
	 * @param array $args
	 * @return void
	 */
	function update( $args ) {
		list( $file, $name ) = $this->parse_name( $args, __FUNCTION__ );

		// Force WordPress to update the plugin list
		wp_update_plugins();

		if ( !class_exists( 'Plugin_Upgrader' ) ) {
			require_once( ABSPATH.'wp-admin/includes/class-wp-upgrader.php' );
		}

		WP_CLI::line( 'Updating '.$name );

		// Upgrading the plugin
		ob_start( 'strip_tags' );
		$upgrader = new Plugin_Upgrader( new CLI_Upgrader_Skin );
		$result = $upgrader->upgrade( $file );
		$feedback = ob_get_clean();

		if ( $result !== null ) {
			WP_CLI::error( $feedback );
		}
		else {
			WP_CLI::line();
			WP_CLI::line( html_entity_decode( strip_tags( $feedback ) ) );
			WP_CLI::success( 'The plugin is successfully updated.' );
		}
	}

	/* PRIVATES */

	/**
	 * Get the details of a plugin
	 *
	 * @param string $file
	 * @return array
	 */
	private function get_details( $file ) {
		$plugin_folder = get_plugins(  '/' . plugin_basename( dirname( $file ) ) );
		$plugin_file = basename( ( $file ) );

		return $plugin_folder[$plugin_file];
	}

	/**
	 * Parse the name of a plugin to a filename, check if it exists
	 *
	 * @param array $args
	 * @param string $sub_command
	 * @param bool $exit
	 * @return array
	 */
	private function parse_name( $args, $sub_command, $exit = true ) {
		if ( empty( $args ) ) {
			WP_CLI::line( "usage: wp plugin $sub_command <plugin-name>" );
			exit;
		}

		$name = $args[0];

		$plugins = get_plugins( '/' . $name );

		if ( !empty( $plugins ) ) {
			$file = $name . '/' . key( $plugins );
		}
		else {
			$file = $name . '.php';
			$plugins = get_plugins();
			if ( !isset( $plugins[$file] && $sub_command != 'install' ) ) {
				if ( $exit ) {
					WP_CLI::error( "The plugin '$name' could not be found." );
					exit();
				}

				return false;
			}
		}

		return array( $file, $name );
	}

	/**
	 * Help function for this command
	 */
	public static function help() {
		WP_CLI::line( <<<EOB
usage: wp plugin <sub-command> [<plugin-name>]

Available sub-commands:
   status       display status of all installed plugins or of a particular plugin
   activate     activate a particular plugin
   deactivate   deactivate a particular plugin
   toggle       toggle activation state of a particular plugin
   install      install a plugin from wordpress.org
   update       update a plugin from wordpress.org
   delete       delete a plugin
EOB
		);
	}
}
