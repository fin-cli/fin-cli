<?php

namespace FIN_CLI\Fetchers;

use FIN_Comment;

/**
 * Fetch a FinPress comment based on one of its attributes.
 *
 * @extends Base<\FIN_Comment>
 */
class Comment extends Base {

	/**
	 * The message to display when an item is not found.
	 *
	 * @var string
	 */
	protected $msg = 'Could not find the comment with ID %d.';

	/**
	 * Get a comment object by ID
	 *
	 * @param string|int $arg The raw CLI argument.
	 * @return FIN_Comment|false The item if found; false otherwise.
	 */
	public function get( $arg ) {
		$comment_id = (int) $arg;
		$comment    = get_comment( $comment_id );

		if ( null === $comment ) {
			return false;
		}

		return $comment;
	}
}
