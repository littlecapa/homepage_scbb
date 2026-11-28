#!/usr/bin/env bash
# Migration: Beitrag „Neue Vereinskleidung“ (Migration 005) um den Hinweis auf eine Nachbestellung ergänzen,
# unterhalb der Fotos. Wiederholbar: ergänzt nur, wenn der Hinweis noch fehlt.
# Ausführen NACH deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/011-news-vereinskleidung-nachbestellung.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

ID=$(wp post list --post_type=post --name=neue-vereinskleidung --field=ID)
[ -n "$ID" ] || { echo "Beitrag nicht gefunden."; exit 1; }
wp eval '
$p = get_post( '"$ID"' );
if ( false !== strpos( $p->post_content, "nochmal Bestellungen" ) ) { WP_CLI::log( "Hinweis schon vorhanden." ); return; }
$neu = "\n\n<!-- wp:paragraph -->\n<p>Keine Sorge, wenn jemand vergessen hat, etwas zu bestellen, oder ein zusätzliches Kleidungsstück möchte: Wir werden bald nochmal Bestellungen sammeln.</p>\n<!-- /wp:paragraph -->";
wp_update_post( array( "ID" => $p->ID, "post_content" => wp_slash( rtrim( $p->post_content ) . $neu ) ) );
WP_CLI::success( "Hinweis in Beitrag #{$p->ID} ergänzt." );
'
wp option update scbb_migration_011 "$(date +%Y-%m-%d)"
