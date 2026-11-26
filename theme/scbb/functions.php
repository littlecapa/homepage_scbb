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
		'instagram'   => 'https://www.instagram.com/schachclub_bonn_beuel/',
		'insta_name'  => '@schachclub_bonn_beuel',
		'spenden'     => 'https://www.hiermitherz.de/project/unterstuetzung-der-schachjugend-des-sc-bonn-beuel-3c0610/',
	);
}

/**
 * Instagram-Symbol als Inline-SVG (keine externen Dateien, kein Tracking).
 */
function scbb_icon_instagram( $size = 20 ) {
	return sprintf(
		'<svg class="scbb-icon" width="%1$d" height="%1$d" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="5" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="4.2" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="17.4" cy="6.6" r="1.3" fill="currentColor"/></svg>',
		(int) $size
	);
}

/**
 * Herz-Symbol für Spenden-Links.
 */
function scbb_icon_herz( $size = 18 ) {
	return sprintf(
		'<svg class="scbb-icon" width="%1$d" height="%1$d" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 21s-7.5-4.6-9.6-9.3C.9 8.3 3 4.5 6.7 4.5c2.1 0 3.6 1.1 4.3 2.6.7-1.5 2.2-2.6 4.3-2.6 3.7 0 5.8 3.8 4.3 7.2C19.5 16.4 12 21 12 21z" fill="currentColor"/></svg>',
		(int) $size
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
