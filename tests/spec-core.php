<?php

class CoreCommandSpec extends WP_CLI_Spec {

	/** @scenario */
	public function emptyDir() {
		$this
			->given( 'empty dir' )

			->when( 'invoking', 'core is-installed' )
			->then( 'return code should be', 1 );
	}

	/** @scenario */
	public function noWpConfig() {
		$this
			->given( 'empty dir' )
			->and( 'wp files' )

			->when( 'invoking', 'core is-installed' )
			->then( 'return code should be', 1 )

			->when( 'invoking', 'core install' )
			->then( 'stderr',
				"Error: wp-config.php not found.\n" .
				"Either create one manually or use `wp core config`.\n"
			)

			->when( 'invoking', 'core config' )
			->then( 'return code should be', 0 );
	}

	/** @scenario */
	public function dbDoesntExist() {
		$this
			->given( 'empty dir' )
			->and( 'wp files' )
			->and( 'wp config' )

			->when( 'invoking', '' )
			->then( 'return code should be', 1 )
			->and( 'stderr', "Error: Can’t select database\n" )
			->and( 'stdout', '' )

			->when( 'invoking', 'db create' )
			->then( 'return code should be', 0 );
	}

	/** @scenario */
	public function dbTablesNotInstalled() {
		$this
			->given( 'empty dir' )
			->and( 'wp files' )
			->and( 'wp config' )
			->and( 'database' )

			->when( 'invoking', 'core is-installed' )
			->then( 'return code should be', 1 )

			->when( 'invoking', '' )
			->then( 'stderr',
				"Error: The site you have requested is not installed.\n" .
				"Run `wp core install`.\n"
			)

			->when( 'invoking', 'core install' )
			->then( 'return code should be', 0 )

			->when( 'invoking', 'post list --ids' )
			->then( 'stdout', "1" );
	}

	/** @scenario */
	public function fullInstall() {
		$this
			->given( 'wp install' )

			->when( 'invoking', 'core is-installed' )
			->then( 'return code should be', 0 );
	}

	/** @scenario */
	public function customWpContentDir() {
		$this
			->given( 'wp install' )
			->and( 'custom wp-content dir' )

			->when( 'invoking', 'theme status twentytwelve' )
			->then( 'return code should be', 0 )

			->when( 'invoking', 'plugin status hello' )
			->then( 'return code should be', 0 );
	}
}

