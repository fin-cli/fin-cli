<?php

use FP_CLI\Configurator;
use FP_CLI\Loggers;
use FP_CLI\Tests\TestCase;

class ConfiguratorTest extends TestCase {

	public function testExtractAssoc(): void {
		$args = Configurator::extract_assoc( [ 'foo', '--bar', '--baz=text' ] );

		$this->assertCount( 1, $args[0] );
		$this->assertCount( 2, $args[1] );

		$this->assertEquals( 'foo', $args[0][0] );

		$this->assertEquals( 'bar', $args[1][0][0] );
		$this->assertTrue( $args[1][0][1] );

		$this->assertEquals( 'baz', $args[1][1][0] );
		$this->assertEquals( 'text', $args[1][1][1] );
	}

	public function testExtractAssocNoValue(): void {
		$args = Configurator::extract_assoc( [ 'foo', '--bar=', '--baz=text' ] );

		$this->assertCount( 1, $args[0] );
		$this->assertCount( 2, $args[1] );

		$this->assertEquals( 'foo', $args[0][0] );

		$this->assertEquals( 'bar', $args[1][0][0] );
		$this->assertEmpty( $args[1][0][1] );

		$this->assertEquals( 'baz', $args[1][1][0] );
		$this->assertEquals( 'text', $args[1][1][1] );
	}

	public function testExtractAssocGlobalLocal(): void {
		$args = Configurator::extract_assoc( [ '--url=foo.dev', '--path=fp', 'foo', '--bar=', '--baz=text', '--url=bar.dev' ] );

		$this->assertCount( 1, $args[0] );
		$this->assertCount( 5, $args[1] );
		$this->assertCount( 2, $args[2] );
		$this->assertCount( 3, $args[3] );

		$this->assertEquals( 'url', $args[2][0][0] );
		$this->assertEquals( 'foo.dev', $args[2][0][1] );
		$this->assertEquals( 'url', $args[3][2][0] );
		$this->assertEquals( 'bar.dev', $args[3][2][1] );
	}

	public function testExtractAssocDoubleDashInValue(): void {
		$args = Configurator::extract_assoc( [ '--test=text--text' ] );

		$this->assertCount( 0, $args[0] );
		$this->assertCount( 1, $args[1] );

		$this->assertEquals( 'test', $args[1][0][0] );
		$this->assertEquals( 'text--text', $args[1][0][1] );
	}

	/**
	 * FP_CLI::get_config does not show warnings for null values.
	 */
	public function testNullGetConfig(): void {
		// Init config so there is a config to check.
		$runner = FP_CLI::get_runner();
		$runner->init_config();

		// Previous.
		$prev_logger = FP_CLI::get_logger();

		$logger = new Loggers\Execution();
		FP_CLI::set_logger( $logger );

		$has_config = FP_CLI::has_config( 'url' );
		$get_config = FP_CLI::get_config( 'url' );

		$this->assertTrue( $has_config, 'has_config() is not true' );
		$this->assertTrue( false === strpos( $logger->stderr, 'Warning' ), 'Logger contains a "Warning"' );
		$this->assertNull( $get_config, 'get_config() is not null' );

		// Restore.
		FP_CLI::set_logger( $prev_logger );
	}
}
