<?php

use FIN_CLI\Tests\TestCase;

class FINCLITest extends TestCase {

	public function testGetPHPBinary(): void {
		$this->assertSame( FIN_CLI\Utils\get_php_binary(), FIN_CLI::get_php_binary() );
	}

	public function testErrorToString(): void {
		$this->expectException( 'InvalidArgumentException' );
		$this->expectExceptionMessage( "Unsupported argument type passed to FIN_CLI::error_to_string(): 'boolean'" );
		// @phpstan-ignore argument.type
		FIN_CLI::error_to_string( true );
	}
}
