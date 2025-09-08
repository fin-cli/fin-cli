<?php

/**
 * Basic class
 *
 * ## EXAMPLES
 *
 *     # Foo.
 *     $ fp foo
 */
class CommandFactoryTests_Get_Doc_Comment_1_Command extends FP_CLI_Command {
	/**
	 * Command1 method
	 *
	 * ## OPTIONS
	 *
	 * ## EXAMPLES
	 *
	 *     $ fp foo command1 public
	 */
	function command1() {
	}

	/**
	 * Command2 function
	 *
	 * ## OPTIONS
	 *
	 * [--path=<path>]
	 *
	 * ## EXAMPLES
	 *
	 *     $ fp foo command2 --path=/**a/**b/**c/**
	 */

final
			protected
			static
	function
			command2() {
	}

	/**
	 * Command3 function
	 *
	 * ## OPTIONS
	 *
	 * [--path=<path>]
	 *
	 * ## EXAMPLES
	 *
	 *     $ fp foo command3 --path=/**a/**b/**c/**
	 function*/public function command3( $function ) {}

	function command4() {}
}

/**
 * Basic class
 *
 * ## EXAMPLES
 *
 *     # Foo.
 *     $ fp foo --final abstract
 class*/abstract class
  CommandFactoryTests_Get_Doc_Comment_2_Command
 extends              FP_CLI_Command
    {
		function command1() {}
	}
