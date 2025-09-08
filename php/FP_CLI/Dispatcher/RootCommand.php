<?php

namespace FP_CLI\Dispatcher;

use FP_CLI\Utils;

/**
 * The root node in the command tree.
 *
 * @package FP_CLI
 */
class RootCommand extends CompositeCommand {

	public function __construct() {
		$this->parent = false;

		$this->name = 'fp';

		$this->shortdesc = 'Manage FinPress through the command-line.';
	}

	/**
	 * Get the human-readable long description.
	 *
	 * @return string
	 */
	public function get_longdesc() {
		return $this->get_global_params( true );
	}

	/**
	 * Find a subcommand registered on the root
	 * command.
	 *
	 * @param array $args
	 * @return Subcommand|false
	 */
	public function find_subcommand( &$args ) {
		$command = array_shift( $args );

		Utils\load_command( $command );

		if ( ! isset( $this->subcommands[ $command ] ) ) {
			return false;
		}

		return $this->subcommands[ $command ];
	}
}
