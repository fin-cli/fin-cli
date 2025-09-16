<?php

use FIN_CLI\Extractor;
use FIN_CLI\Loggers;
use FIN_CLI\Tests\TestCase;
use FIN_CLI\Utils;

class ExtractorTest extends TestCase {

	public static $copy_overwrite_files_prefix = 'fin-cli-test-utils-copy-overwrite-files-';

	public static $expected_fin = [
		'index1.php',
		'license2.php',
		'fin-admin/',
		'fin-admin/about3.php',
		'fin-admin/includes/',
		'fin-admin/includes/file4.php',
		'fin-admin/widgets5.php',
		'fin-config6.php',
		'fin-includes/',
		'fin-includes/file7.php',
		'xmlrpc8.php',
	];

	public static $logger      = null;
	public static $prev_logger = null;

	public function set_up(): void {
		parent::set_up();

		self::$prev_logger = FIN_CLI::get_logger();

		self::$logger = new Loggers\Execution();
		FIN_CLI::set_logger( self::$logger );

		// Remove any failed tests detritus.
		$temp_dirs = glob( Utils\get_temp_dir() . self::$copy_overwrite_files_prefix . '*' );

		$this->assertNotFalse( $temp_dirs );

		foreach ( $temp_dirs as $temp_dir ) {
			Extractor::rmdir( $temp_dir );
		}
	}

	public function tear_down(): void {
		// Restore logger.
		FIN_CLI::set_logger( self::$prev_logger );

		parent::tear_down();
	}

	public function test_rmdir(): void {
		list( $temp_dir, $src_dir, $fin_dir ) = self::create_test_directory_structure();

		$this->assertTrue( is_dir( $fin_dir ) );
		Extractor::rmdir( $fin_dir );
		$this->assertFalse( file_exists( $fin_dir ) );

		$this->assertTrue( is_dir( $temp_dir ) );
		Extractor::rmdir( $temp_dir );
		$this->assertFalse( file_exists( $temp_dir ) );
	}

	public function test_err_rmdir(): void {
		$msg = '';
		try {
			Extractor::rmdir( 'no-such-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}
		$this->assertTrue( false !== strpos( $msg, 'no-such-dir' ) );
		$this->assertTrue( empty( self::$logger->stderr ) );
	}

	public function test_copy_overwrite_files(): void {
		list( $temp_dir, $src_dir, $fin_dir ) = self::create_test_directory_structure();

		$dest_dir = $temp_dir . '/dest';

		Extractor::copy_overwrite_files( $fin_dir, $dest_dir );

		$files = self::recursive_scandir( $dest_dir );

		$this->assertSame( self::$expected_fin, $files );
		$this->assertTrue( empty( self::$logger->stderr ) );

		// Clean up.
		Extractor::rmdir( $temp_dir );
	}

	public function test_err_copy_overwrite_files(): void {
		$msg = '';
		try {
			Extractor::copy_overwrite_files( 'no-such-dir', 'dest-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}
		$this->assertTrue( false !== strpos( $msg, 'no-such-dir' ) );
		$this->assertTrue( empty( self::$logger->stderr ) );
	}

	public function test_extract_tarball(): void {
		if ( ! exec( 'tar --version' ) ) {
			$this->markTestSkipped( 'tar not installed.' );
		}

		list( $temp_dir, $src_dir, $fin_dir ) = self::create_test_directory_structure();

		$tarball  = $temp_dir . '/test.tar.gz';
		$dest_dir = $temp_dir . '/dest';

		// Create test tarball.
		$output     = [];
		$return_var = -1;
		// Need --force-local for Windows to avoid "C:" being interpreted as being on remote machine, and redirect for Mac as outputs verbosely on STDERR.
		$cmd = 'tar czvf %1$s' . ( Utils\is_windows() ? ' --force-local' : '' ) . ' --directory=%2$s/src finpress 2>&1';
		exec( Utils\esc_cmd( $cmd, $tarball, $temp_dir ), $output, $return_var );
		$this->assertSame( 0, $return_var );
		$this->assertFalse( empty( $output ) );

		// Normalize (Mac) output.
		$normalize = function ( $v ) {
			if ( 'a ' === substr( $v, 0, 2 ) ) {
				$v = substr( $v, 2 );
			}
			if ( '/' !== substr( $v, -1 ) && false === strpos( $v, '.' ) ) {
				$v .= '/';
			}
			return $v;
		};
		$output    = array_map( $normalize, $output );
		sort( $output );

		$this->assertSame( self::recursive_scandir( $src_dir ), $output );

		// Test.
		Extractor::extract( $tarball, $dest_dir );

		$files = self::recursive_scandir( $dest_dir );
		$this->assertSame( self::$expected_fin, $files );
		$this->assertTrue( empty( self::$logger->stderr ) );

		// Clean up.
		Extractor::rmdir( $temp_dir );
	}

	public function test_err_extract_tarball(): void {
		// Non-existent.
		$msg = '';
		try {
			Extractor::extract( 'no-such-tar.tar.gz', 'dest-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}

		$this->assertTrue( false !== strpos( $msg, 'no-such-tar' ) );
		$this->assertTrue( 0 === strpos( self::$logger->stderr, 'Warning: PharData failed' ) );
		$this->assertTrue( false !== strpos( self::$logger->stderr, 'no-such-tar' ) );

		// Reset logger.
		self::$logger->stderr = '';
		self::$logger->stdout = '';

		// Zero-length.
		$zero_tar = Utils\get_temp_dir() . 'zero-tar.tar.gz';
		touch( $zero_tar );
		$msg = '';
		try {
			Extractor::extract( $zero_tar, 'dest-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}
		unlink( $zero_tar );

		$this->assertTrue( false !== strpos( $msg, 'zero-tar' ) );
		$this->assertTrue( 0 === strpos( self::$logger->stderr, 'Warning: PharData failed' ) );
		$this->assertTrue( false !== strpos( self::$logger->stderr, 'zero-tar' ) );
	}

	public function test_extract_zip(): void {
		if ( ! class_exists( 'ZipArchive' ) ) {
			$this->markTestSkipped( 'ZipArchive not installed.' );
		}

		list( $temp_dir, $src_dir, $fin_dir ) = self::create_test_directory_structure();

		$zipfile  = $temp_dir . '/test.zip';
		$dest_dir = $temp_dir . '/dest';

		// Create test zip.
		$zip    = new ZipArchive();
		$result = $zip->open( $zipfile, ZipArchive::CREATE );
		$this->assertTrue( $result );
		$files = self::recursive_scandir( $src_dir );
		foreach ( $files as $file ) {
			if ( 0 === substr_compare( $file, '/', -1 ) ) {
				$result = $zip->addEmptyDir( $file );
			} else {
				$result = $zip->addFile( $src_dir . '/' . $file, $file );
			}
			$this->assertTrue( $result );
		}
		$result = $zip->close();
		$this->assertTrue( $result );

		// Test.
		Extractor::extract( $zipfile, $dest_dir );

		$files = self::recursive_scandir( $dest_dir );
		$this->assertSame( self::$expected_fin, $files );
		$this->assertTrue( empty( self::$logger->stderr ) );

		// Clean up.
		Extractor::rmdir( $temp_dir );
	}

	public function test_err_extract_zip(): void {
		if ( ! class_exists( 'ZipArchive' ) ) {
			$this->markTestSkipped( 'ZipArchive not installed.' );
		}

		// Non-existent.
		$msg = '';
		try {
			Extractor::extract( 'no-such-zip.zip', 'dest-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}
		$this->assertTrue( false !== strpos( $msg, 'no-such-zip' ) );
		$this->assertTrue( empty( self::$logger->stderr ) );

		// Reset logger.
		self::$logger->stderr = '';
		self::$logger->stdout = '';

		// Zero-length.
		$zero_zip = Utils\get_temp_dir() . 'zero-zip.zip';
		touch( $zero_zip );
		$msg = '';
		try {
			Extractor::extract( $zero_zip, 'dest-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}
		unlink( $zero_zip );
		$this->assertTrue( false !== strpos( $msg, 'zero-zip' ) );
		$this->assertTrue( empty( self::$logger->stderr ) );
	}

	public function test_err_extract(): void {
		$msg = '';
		try {
			Extractor::extract( 'not-supported.tar.xz', 'dest-dir' );
		} catch ( \Exception $e ) {
			$msg = $e->getMessage();
		}
		$this->assertSame( "Extraction only supported for '.zip' and '.tar.gz' file types.", $msg );
		$this->assertTrue( empty( self::$logger->stderr ) );
	}

	private static function create_test_directory_structure() {
		$temp_dir = Utils\get_temp_dir() . uniqid( self::$copy_overwrite_files_prefix, true );
		mkdir( $temp_dir );

		$src_dir = $temp_dir . '/src';
		mkdir( $src_dir );

		$fin_dir = $src_dir . '/finpress';
		mkdir( $fin_dir );

		foreach ( self::$expected_fin as $file ) {
			if ( 0 === substr_compare( $file, '/', -1 ) ) {
				mkdir( $fin_dir . '/' . $file );
			} else {
				touch( $fin_dir . '/' . $file );
			}
		}

		return [ $temp_dir, $src_dir, $fin_dir ];
	}

	private static function recursive_scandir( $dir, $prefix_dir = '' ) {
		$dirs = scandir( $dir );
		if ( ! $dirs ) {
			return [];
		}

		$ret = [];

		foreach ( array_diff( $dirs, [ '.', '..' ] ) as $file ) {
			if ( is_dir( $dir . '/' . $file ) ) {
				$ret[] = ( $prefix_dir ? ( $prefix_dir . '/' . $file ) : $file ) . '/';
				$ret   = array_merge( $ret, self::recursive_scandir( $dir . '/' . $file, $prefix_dir ? ( $prefix_dir . '/' . $file ) : $file ) );
			} else {
				$ret[] = $prefix_dir ? ( $prefix_dir . '/' . $file ) : $file;
			}
		}
		return $ret;
	}
}
