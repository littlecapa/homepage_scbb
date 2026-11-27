#!/usr/bin/env bash
# Migration: Beitrag vom 31.08.2026 („Oliver Albrecht und Daio Moussavian sind die Schnellschachmeister 2026“)
# verlinkt auf die neue Seite /turniere/vereinsschnellschachmeisterschaft/ statt auf /turniere/
# (beim Import von scbb.de umgebogen, weil die Seite damals fehlte). Wiederholbar.
# Ausführen NACH deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/009-link-vereinsschnellschachmeisterschaft.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

ID=$(wp post list --post_type=post --name=oliver-albrecht-und-daio-moussavian-sind-die-schnellschachmeister-2026 --field=ID)
[ -n "$ID" ] || { echo "Beitrag nicht gefunden."; exit 1; }
wp eval '
$p   = get_post( '"$ID"' );
$alt = "href=\"/turniere/\">Bericht und Fotos zur Vereinsmeisterschaft im Schnellschach";
$neu = "href=\"/turniere/vereinsschnellschachmeisterschaft/\">Bericht und Fotos zur Vereinsmeisterschaft im Schnellschach";
if ( false === strpos( $p->post_content, $alt ) ) { WP_CLI::log( "Link schon umgestellt." ); return; }
wp_update_post( array( "ID" => $p->ID, "post_content" => wp_slash( str_replace( $alt, $neu, $p->post_content ) ) ) );
WP_CLI::success( "Link in Beitrag #{$p->ID} umgestellt." );
'
wp option update scbb_migration_009 "$(date +%Y-%m-%d)"
