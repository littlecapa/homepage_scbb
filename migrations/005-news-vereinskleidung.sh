#!/usr/bin/env bash
# Einmalige Migration: erste News „Die neue Vereinskleidung ist eingetroffen.“ (2026-11-27)
# Bilder liegen in content/news/2026-11-27-vereinskleidung/ (von deploy.sh nach ~/scbb-content übertragen).
# Erstellt mit tools/foto-freistellen.swift + tools/foto-komponieren.py.
# Ausführen NACH deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/005-news-vereinskleidung.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }
DIR="$HOME/scbb-content/news/2026-11-27-vereinskleidung"

if wp option get scbb_migration_005 >/dev/null 2>&1; then
  echo "Migration 005 wurde bereits am $(wp option get scbb_migration_005) ausgeführt – nichts zu tun."
  exit 0
fi

POST_ID=$(wp post create --post_type=post --post_status=publish \
  --post_date="2026-11-27 12:00:00" \
  --post_name=neue-vereinskleidung \
  --post_title="Die neue Vereinskleidung ist eingetroffen." --porcelain)

VORNE=$(wp media import "$DIR/vereinskleidung-hoodie-vorne.jpg" --post_id="$POST_ID" --featured_image \
  --title="Vereins-Hoodie, Vorderseite" --alt="Blauer Vereins-Hoodie mit Logo-Aufnäher, Vorderseite" --porcelain)
HINTEN=$(wp media import "$DIR/vereinskleidung-hoodie-hinten.jpg" --post_id="$POST_ID" \
  --title="Vereins-Hoodie, Rückseite" --alt="Blauer Vereins-Hoodie mit Aufdruck „Schachclub Bonn Beuel“, Rückseite" --porcelain)
U_VORNE=$(wp eval "echo wp_get_attachment_image_url($VORNE, 'large');")
U_HINTEN=$(wp eval "echo wp_get_attachment_image_url($HINTEN, 'large');")

INHALT=$(cat <<HTML
<!-- wp:paragraph -->
<p>Mitglieder, die etwas bestellt haben, aber es in nächster Zeit nicht zum Vereinsabend schaffen, melden sich bitte <a href="mailto:scbonnbeuel@gmail.com">per E-Mail</a>. Dann organisieren wir eine Übergabe.</p>
<!-- /wp:paragraph -->

<!-- wp:gallery {"linkTo":"none","columns":2,"imageCrop":false,"className":"scbb-galerie"} -->
<figure class="wp-block-gallery has-nested-images columns-2 scbb-galerie"><!-- wp:image {"id":$VORNE,"sizeSlug":"large","linkDestination":"none"} -->
<figure class="wp-block-image size-large"><img src="$U_VORNE" alt="Blauer Vereins-Hoodie mit Logo-Aufnäher, Vorderseite" class="wp-image-$VORNE"/></figure>
<!-- /wp:image -->

<!-- wp:image {"id":$HINTEN,"sizeSlug":"large","linkDestination":"none"} -->
<figure class="wp-block-image size-large"><img src="$U_HINTEN" alt="Blauer Vereins-Hoodie mit Aufdruck „Schachclub Bonn Beuel“, Rückseite" class="wp-image-$HINTEN"/></figure>
<!-- /wp:image --></figure>
<!-- /wp:gallery -->
HTML
)
wp post update "$POST_ID" --post_content="$INHALT" --post_excerpt="Mitglieder, die etwas bestellt haben, aber es in nächster Zeit nicht zum Vereinsabend schaffen, melden sich bitte per E-Mail. Dann organisieren wir eine Übergabe."

wp option add scbb_migration_005 "$(date +%Y-%m-%d)"
echo "Fertig: Beitrag $POST_ID, Bilder $VORNE/$HINTEN."
