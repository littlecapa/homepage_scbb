#!/usr/bin/env bash
# Migration: Beiträge der alten Website scbb.de (ab 30.07.2026) importieren.
# Daten: content/news/archiv/<datum>-<slug>/ (meta.json, inhalt.html, Fotos), erzeugt mit tools/alt-news-export.py,
# von deploy.sh nach ~/scbb-content übertragen.
# - Kategorie „Uncategorized“ wird zu „Allgemein“, neue Kategorie „Turniere“ (+ „Mannschaften“ aus Migration 006)
# - Slugs wie auf scbb.de -> alte Beitrags-Adressen bleiben nach dem Domain-Umzug gültig
# - Beiträge, deren Slug schon existiert, werden übersprungen -> gefahrlos wiederholbar, auch für weitere Exporte
# Ausführen NACH deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/007-news-archiv-scbb.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

PHP=$(mktemp --suffix=.php)
trap 'rm -f "$PHP"' EXIT
cat > "$PHP" <<'PHPCODE'
<?php
require_once ABSPATH . 'wp-admin/includes/media.php';
require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/image.php';

// Kategorien
$standard = get_term( (int) get_option( 'default_category' ), 'category' );
if ( $standard && 'uncategorized' === $standard->slug ) {
	wp_update_term( $standard->term_id, 'category', array( 'name' => 'Allgemein', 'slug' => 'allgemein' ) );
	WP_CLI::log( 'Kategorie Uncategorized -> Allgemein' );
}
$kat = array();
foreach ( array( 'allgemein' => 'Allgemein', 'mannschaften' => 'Mannschaften', 'turniere' => 'Turniere' ) as $slug => $name ) {
	$t = get_term_by( 'slug', $slug, 'category' );
	if ( ! $t ) {
		$r = wp_insert_term( $name, 'category', array( 'slug' => $slug ) );
		$t = get_term( $r['term_id'], 'category' );
		WP_CLI::log( "Kategorie $name angelegt" );
	}
	$kat[ $slug ] = (int) $t->term_id;
}

$basis = getenv( 'HOME' ) . '/scbb-content/news/archiv';
$neu   = 0;
foreach ( glob( "$basis/*/meta.json" ) as $datei ) {
	$dir  = dirname( $datei );
	$meta = json_decode( file_get_contents( $datei ), true );
	if ( get_posts( array( 'name' => $meta['slug'], 'post_type' => 'post', 'post_status' => 'any', 'numberposts' => 1 ) ) ) {
		WP_CLI::log( "vorhanden, übersprungen: {$meta['slug']}" );
		continue;
	}
	$id = wp_insert_post(
		array(
			'post_type'     => 'post',
			'post_status'   => 'publish',
			'post_title'    => $meta['titel'],
			'post_name'     => $meta['slug'],
			'post_date'     => $meta['datum'],
			'post_category' => array( $kat[ $meta['kategorie'] ] ?? $kat['allgemein'] ),
			'post_content'  => '',
		),
		true
	);
	if ( is_wp_error( $id ) ) {
		WP_CLI::error( $id->get_error_message() );
	}
	$inhalt = file_get_contents( "$dir/inhalt.html" );
	$bilder = array();
	foreach ( glob( "$dir/*.jpg" ) as $jpg ) {
		$tmp = wp_tempnam( basename( $jpg ) );
		copy( $jpg, $tmp );
		$att = media_handle_sideload( array( 'name' => basename( $jpg ), 'tmp_name' => $tmp ), $id );
		if ( is_wp_error( $att ) ) {
			WP_CLI::error( $att->get_error_message() );
		}
		$bilder[ basename( $jpg ) ] = $att;
		$url    = wp_get_attachment_image_url( $att, 'large' );
		$inhalt = str_replace( '{{bild:' . basename( $jpg ) . '}}', $url, $inhalt );
		if ( preg_match( '/<img src="' . preg_quote( $url, '/' ) . '" alt="([^"]*)"/', $inhalt, $m ) ) {
			update_post_meta( $att, '_wp_attachment_image_alt', html_entity_decode( $m[1] ) );
		}
	}
	wp_update_post( array( 'ID' => $id, 'post_content' => $inhalt ) );
	if ( ! empty( $meta['beitragsbild'] ) && isset( $bilder[ $meta['beitragsbild'] ] ) ) {
		set_post_thumbnail( $id, $bilder[ $meta['beitragsbild'] ] );
	}
	WP_CLI::log( "importiert: #$id {$meta['datum']} {$meta['titel']}" );
	++$neu;
}
WP_CLI::success( "$neu Beiträge importiert." );
PHPCODE

wp eval-file "$PHP"
wp option update scbb_migration_007 "$(date +%Y-%m-%d)"
