<?php

use FP_CLI\Tests\TestCase;
use FP_CLI\Utils;

class FPVersionCompareTest extends TestCase {

	/**
	 * Test basic functionality
	 */
	public function testBasic(): void {
		$GLOBALS['fp_version'] = '4.9-alpha-40870-src';
		$this->assertTrue( Utils\fp_version_compare( '4.8', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.8', '<' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-alpha-40870-src', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-alpha-40870-src', '=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-alpha-40870-src', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1', '<' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1-45000', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta2-46000', '<' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9', '>=' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9', '<' ) );

		$GLOBALS['fp_version'] = '4.9-beta1-45000';
		$this->assertTrue( Utils\fp_version_compare( '4.8', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.8', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-alpha-40870-src', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1-45000', '>=' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1-45000', '=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1-45000', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta2-46000', '<' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta2-46000', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9', '>=' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9', '<' ) );

		$GLOBALS['fp_version'] = '4.9-beta2-46000';
		$this->assertTrue( Utils\fp_version_compare( '4.8', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.8', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-alpha-40870-src', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-alpha-40870-src', '=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1-45000', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta2-45550', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta2-45550', '<' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9', '>=' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9', '<' ) );

		$GLOBALS['fp_version'] = '4.9-rc1-47000';
		$this->assertTrue( Utils\fp_version_compare( '4.8', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.8', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-alpha-40870-src', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-alpha-40870-src', '=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1-45000', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta2-45550', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta2-45550', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-rc2', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-rc2-48000', '<' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9', '>=' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9', '<' ) );

		$GLOBALS['fp_version'] = '4.9';
		$this->assertTrue( Utils\fp_version_compare( '4.8', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.8', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-alpha-40870-src', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-alpha-40870-src', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1-45000', '>' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9-beta1', '<' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9-beta1', '>' ) );
		$this->assertTrue( Utils\fp_version_compare( '4.9', '>=' ) );
		$this->assertFalse( Utils\fp_version_compare( '4.9', '<' ) );
	}
}
