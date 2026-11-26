<?php
/**
 * Child-Theme SC Bonn Beuel.
 * Quelle: github.com/littlecapa/homepage_scbb – Änderungen bitte dort, nicht auf dem Server.
 */

add_action(
	'wp_enqueue_scripts',
	function () {
		wp_enqueue_style( 'scbb', get_stylesheet_uri(), array(), wp_get_theme()->get( 'Version' ) );
	}
);

add_action(
	'after_setup_theme',
	function () {
		add_editor_style( 'style.css' );
	}
);
