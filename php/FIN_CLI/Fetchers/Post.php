<?php

namespace FIN_CLI\Fetchers;

use FIN_Post;

/**
 * Fetch a FinPress post based on one of its attributes.
 *
 * @extends Base<\FIN_Post>
 */
class Post extends Base {

	/**
	 * The message to display when an item is not found.
	 *
	 * @var string
	 */
	protected $msg = 'Could not find the post with ID %d.';

	/**
	 * Get a post object by ID
	 *
	 * @param string|int $arg The raw CLI argument.
	 * @return FIN_Post|false The item if found; false otherwise.
	 */
	public function get( $arg ) {
		/**
		 * @var FIN_Post|null $post
		 */
		$post = get_post( (int) $arg );

		if ( null === $post ) {
			return false;
		}

		return $post;
	}
}
