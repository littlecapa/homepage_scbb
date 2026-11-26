<?php
/**
 * Child-Theme SC Bonn Beuel.
 * Quelle: github.com/littlecapa/homepage_scbb – Änderungen bitte dort, nicht auf dem Server.
 */

/**
 * Zentrale Vereinsdaten. Werden im Kopf, im Vereinsabend-Kasten und im Fußbereich verwendet.
 * Hier ändern, dann ./deploy.sh.
 */
function scbb_daten() {
	return array(
		'name'        => 'Schachclub Bonn/Beuel e.V.',
		'email'       => 'scbonnbeuel@gmail.com',
		'ort_name'    => 'Tenten – Haus der Begegnung',
		'ort_strasse' => 'An der Wolfsburg 1',
		'ort_plz_ort' => '53225 Bonn-Beuel',
		'ort_bus'     => 'Bus 163/550 und 640, Haltestelle „An der Wolfsburg“',
	);
}

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
