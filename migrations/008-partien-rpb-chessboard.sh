#!/usr/bin/env bash
# Migration: Partien in Beiträgen nachspielbar machen (Plugin RPB Chessboard, siehe setup.sh).
# Ersetzt in allen Beiträgen den aufklappbaren PGN-Text (Block „Details“ mit „Partie …“ + Code-Block,
# erzeugt von Migration 007) durch den Block „rpb-chessboard/pgn“. Feste Seiten aus content/ stellt deploy.sh um.
# Wiederholbar: Beiträge ohne alten PGN-Text bleiben unverändert.
# Ausführen NACH deploy.sh (Plugin muss aktiv sein): ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/008-partien-rpb-chessboard.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

wp plugin is-active rpb-chessboard || { echo "Plugin rpb-chessboard ist nicht aktiv – erst deploy.sh ausführen."; exit 1; }

PHP=$(mktemp --suffix=.php)
trap 'rm -f "$PHP"' EXIT
cat > "$PHP" <<'PHPCODE'
<?php
$muster = '#<!-- wp:details -->\n<details class="wp-block-details"><summary>Partie[^<]*</summary>'
	. '<!-- wp:code -->\n<pre class="wp-block-code"><code>(.*?)</code></pre>\n<!-- /wp:code --></details>\n<!-- /wp:details -->#s';
$n = 0;
foreach ( get_posts( array( 'post_type' => 'post', 'post_status' => 'any', 'numberposts' => -1, 's' => '<summary>Partie' ) ) as $p ) {
	$neu = preg_replace_callback(
		$muster,
		function ( $m ) {
			$pgn = trim( html_entity_decode( $m[1], ENT_QUOTES | ENT_HTML5, 'UTF-8' ) ) . "\n";
			return '<!-- wp:rpb-chessboard/pgn ' . serialize_block_attributes( array( 'pgn' => $pgn ) ) . ' /-->';
		},
		$p->post_content,
		-1,
		$anzahl
	);
	if ( $anzahl ) {
		wp_update_post( array( 'ID' => $p->ID, 'post_content' => wp_slash( $neu ) ) );
		WP_CLI::log( "#{$p->ID} {$p->post_title}: $anzahl Partie(n) umgestellt" );
		$n += $anzahl;
	}
}
WP_CLI::success( "$n Partie(n) umgestellt." );
PHPCODE

wp eval-file "$PHP"
wp option update scbb_migration_008 "$(date +%Y-%m-%d)"
