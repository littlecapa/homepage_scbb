#!/usr/bin/env bash
# Einmalige Migration: Bericht U16 gegen SF Rheinbach (21.11.2026) als News in der Kategorie „Mannschaften“.
# Foto: theme/scbb/assets/fotos/mannschaft-u16.jpg (dasselbe wie auf /mannschaften/u16/), wird als Beitragsbild importiert.
# Ausführen NACH deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/006-news-u16-rheinbach.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }
FOTO="$WP_PATH/wp-content/themes/scbb/assets/fotos/mannschaft-u16.jpg"

if wp option get scbb_migration_006 >/dev/null 2>&1; then
  echo "Migration 006 wurde bereits am $(wp option get scbb_migration_006) ausgeführt – nichts zu tun."
  exit 0
fi

# Kategorie „Mannschaften“ (Berichte zu Mannschaftskämpfen)
KAT_ID=$(wp term list category --slug=mannschaften --field=term_id)
if [ -z "$KAT_ID" ]; then
  KAT_ID=$(wp term create category "Mannschaften" --slug=mannschaften \
    --description="Berichte von unseren Mannschaftskämpfen" --porcelain)
fi

POST_ID=$(wp post create --post_type=post --post_status=publish \
  --post_date="2026-11-21 19:00:00" \
  --post_name=u16-auftakt-rheinbach \
  --post_category="$KAT_ID" \
  --post_title="U16: Knappe Niederlage zum Auftakt – erster Sieg für Melih" --porcelain)

BILD=$(wp media import "$FOTO" --post_id="$POST_ID" --featured_image \
  --title="U16 beim Mannschaftskampf" --alt="Unsere U16-Spieler beim Mannschaftskampf am Brett" --porcelain)
U_BILD=$(wp eval "echo wp_get_attachment_image_url($BILD, 'large');")

INHALT=$(cat <<HTML
<!-- wp:paragraph -->
<p>Am 21.11.2026 stand für unsere Jugendmannschaft der erste Mannschaftskampf auf dem Programm! Gegen die erfahrenen Gegner aus Rheinbach entwickelte sich ein spannender Wettkampf, den wir am Ende knapp mit 7:9 verloren haben ☺️</p>
<!-- /wp:paragraph -->

<!-- wp:image {"id":$BILD,"sizeSlug":"large","linkDestination":"none","className":"scbb-foto"} -->
<figure class="wp-block-image size-large scbb-foto"><img src="$U_BILD" alt="Unsere U16-Spieler beim Mannschaftskampf am Brett" class="wp-image-$BILD"/></figure>
<!-- /wp:image -->

<!-- wp:paragraph -->
<p>Ein ganz besonderer Glückwunsch geht an Melih, der heute seinen allerersten Sieg in einer offiziellen Turnierpartie feiern konnte! 🏆🎉👏</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Wir freuen uns schon auf eure nächsten Wettkämpfe! Weiter so 🤍🫶🏼</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph {"className":"scbb-pfeil"} -->
<p class="scbb-pfeil"><a href="/mannschaften/u16/">Aufstellung, Ergebnisse und Termine der U16</a></p>
<!-- /wp:paragraph -->
HTML
)
wp post update "$POST_ID" --post_content="$INHALT" \
  --post_excerpt="Im ersten Mannschaftskampf unterlag unsere U16 den erfahrenen Rheinbachern knapp mit 7:9 – und Melih feierte seinen allerersten Sieg in einer offiziellen Turnierpartie."

wp option add scbb_migration_006 "$(date +%Y-%m-%d)"
echo "Fertig: Beitrag $POST_ID (Kategorie $KAT_ID), Bild $BILD."
