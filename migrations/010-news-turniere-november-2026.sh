#!/usr/bin/env bash
# Migration: News zu den Monatsturnieren November 2026 (Kategorie „Turniere“), Text = Einleitung der Ergebnisseite,
# Link auf die Kreuztabelle unter /turniere/blitzturniere/… bzw. /turniere/schnellschachturniere/….
# Beiträge, deren Slug schon existiert, werden übersprungen -> gefahrlos wiederholbar.
# Ausführen NACH deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/010-news-turniere-november-2026.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

KAT_ID=$(wp term list category --slug=turniere --field=term_id)
[ -n "$KAT_ID" ] || { echo "Kategorie „Turniere“ fehlt (Migration 007)."; exit 1; }

beitrag() {  # beitrag <slug> <datum> <titel> <text> <link> <linktext>
  if [ -n "$(wp post list --post_type=post --post_status=any --name="$1" --field=ID)" ]; then
    echo "vorhanden, übersprungen: $1"; return
  fi
  local inhalt
  inhalt=$(cat <<HTML
<!-- wp:paragraph -->
<p>$4</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph {"className":"scbb-pfeil"} -->
<p class="scbb-pfeil"><a href="$5">$6</a></p>
<!-- /wp:paragraph -->
HTML
)
  wp post create --post_type=post --post_status=publish --post_date="$2" --post_name="$1" \
    --post_category="$KAT_ID" --post_title="$3" --post_content="$inhalt" \
    --post_excerpt="$(echo "$4" | sed 's/<[^>]*>//g')" --porcelain | sed "s/^/angelegt: #/"
}

beitrag blitzturnier-november-2026-adrian-mueller-gewinnt "2026-11-03 23:00:00" \
  "Blitzturnier November: Adrian Müller gewinnt" \
  "36 Teilnehmende, 11 Runden Schweizer System. Es gewann <strong>Adrian Müller</strong> mit 8,5 Punkten vor Oliver Albrecht (8) und Klaus Rybarczyk (8)." \
  "/turniere/blitzturniere/blitzturnier-2026-11/" "Kreuztabelle des Blitzturniers November 2026"

beitrag schnellschachturnier-november-2026-oliver-albrecht-gewinnt "2026-11-10 23:00:00" \
  "Schnellschachturnier November: Oliver Albrecht gewinnt" \
  "34 Teilnehmende, 5 Runden Schweizer System. Es gewann <strong>Oliver Albrecht</strong> mit 4,5 Punkten vor Florian Meinecke (4) und Joram Seewi (4)." \
  "/turniere/schnellschachturniere/schnellschachturnier-2026-11/" "Kreuztabelle des Schnellschachturniers November 2026"

wp option update scbb_migration_010 "$(date +%Y-%m-%d)"
