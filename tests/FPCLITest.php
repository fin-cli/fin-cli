<?php

use FP_CLI\Tests\TestCase;

class FPCLITest extends TestCase {

	public function testGetPHPBinary(): void {
		$this->assertSame( FP_CLI\Utils\get_php_binary(), FP_CLI::get_php_binary() );
	}

	public function testErrorToString(): void {
		$this->expectException( 'InvalidArgumentException' );
		$this->expectExceptionMessage( "Unsupported argument type passed to FP_CLI::error_to_string(): 'boolean'" );
		// @phpstan-ignore argument.type
		FP_CLI::error_to_string( true );
	}
}
