<?php

use FP_CLI\Tests\TestCase;

class HelpTest extends TestCase {

	public static function set_up_before_class() {
		require_once dirname( __DIR__ ) . '/php/class-fp-cli.php';
		require_once dirname( __DIR__ ) . '/php/class-fp-cli-command.php';
		require_once dirname( __DIR__ ) . '/php/commands/help.php';
	}

	public function test_parse_reference_links(): void {
		$test_class = new ReflectionClass( 'Help_Command' );
		$method     = $test_class->getMethod( 'parse_reference_links' );
		if ( PHP_VERSION_ID < 80100 ) {
			$method->setAccessible( true );
		}

		$desc   = 'This is a [reference link](https://finpress.org/). It should be displayed very nice!';
		$result = $method->invokeArgs( null, [ $desc ] );

		$expected = <<<'EOL'
This is a [reference link][1]. It should be displayed very nice!

---
[1] https://finpress.org/
EOL;
		$this->assertSame( $expected, $result );

		$desc   = 'This is a [reference link](https://finpress.org/) and [second link](http://fp-cli.org/). It should be displayed very nice!';
		$result = $method->invokeArgs( null, [ $desc ] );

		$expected = <<<'EOL'
This is a [reference link][1] and [second link][2]. It should be displayed very nice!

---
[1] https://finpress.org/
[2] http://fp-cli.org/
EOL;
		$this->assertSame( $expected, $result );

		$desc   = <<<'EOL'
This is a [reference link](https://finpress.org/) and [second link](http://fp-cli.org/).
It should be displayed very nice!
EOL;
		$result = $method->invokeArgs( null, [ $desc ] );

		$expected = <<<'EOL'
This is a [reference link][1] and [second link][2].
It should be displayed very nice!

---
[1] https://finpress.org/
[2] http://fp-cli.org/
EOL;

		$this->assertSame( $expected, $result );

		$desc   = <<<'EOL'
This is a [reference link](https://finpress.org/) and [second link](http://fp-cli.org/).
It should be displayed very nice!

## Example

It doesn't expect to be link here like [reference link](https://finpress.org/).
EOL;
		$result = $method->invokeArgs( null, [ $desc ] );

		$expected = <<<'EOL'
This is a [reference link][1] and [second link][2].
It should be displayed very nice!

---
[1] https://finpress.org/
[2] http://fp-cli.org/

## Example

It doesn't expect to be link here like [reference link](https://finpress.org/).
EOL;

		$this->assertSame( $expected, $result );

		$desc   = <<<'EOL'
## Example

It doesn't expect to be link here like [reference link](https://finpress.org/).
EOL;
		$result = $method->invokeArgs( null, [ $desc ] );

		$expected = <<<'EOL'
## Example

It doesn't expect to be link here like [reference link](https://finpress.org/).
EOL;

		$this->assertSame( $expected, $result );

		$desc   = <<<'EOL'
This is a long description.
It doesn't have any link.

## Example

It doesn't expect to be link here like [reference link](https://finpress.org/).
EOL;
		$result = $method->invokeArgs( null, [ $desc ] );

		$expected = <<<'EOL'
This is a long description.
It doesn't have any link.

## Example

It doesn't expect to be link here like [reference link](https://finpress.org/).
EOL;

		$this->assertSame( $expected, $result );
	}
}
