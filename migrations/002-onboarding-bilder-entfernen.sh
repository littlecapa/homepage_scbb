#!/usr/bin/env bash
# Einmalige Migration: Stockfotos und Logos aus dem IONOS/Extendify-Onboarding aus der Mediathek löschen.
# Betroffen sind nur Anhänge mit den typischen Onboarding-Titeln (40-stelliger Hash, featured-image-N,
# hello-world-featured, ext-site-icon-*, ext-custom-logo-*). Eigene Dateien (Meta _scbb_asset) bleiben.
# Entscheidung 2026-11-26. Läuft nur einmal (Option scbb_migration_002).
# Ausführen: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/002-onboarding-bilder-entfernen.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

if wp option get scbb_migration_002 >/dev/null 2>&1; then
  echo "Migration 002 wurde bereits am $(wp option get scbb_migration_002) ausgeführt – nichts zu tun."
  exit 0
fi

echo "== Datenbank-Backup"
mkdir -p "$HOME/backups"
wp db export "$HOME/backups/db-$(date +%Y%m%d-%H%M%S)-migration-002.sql" --quiet

echo "== Onboarding-Bilder löschen"
count=0
while IFS=, read -r id title; do
  [ "$id" = "ID" ] && continue
  title=${title//\"/}
  if wp post meta get "$id" _scbb_asset >/dev/null 2>&1; then
    continue
  fi
  if [[ "$title" =~ ^[0-9a-f]{40}$ || "$title" =~ ^featured-image-[0-9]+$ || "$title" == "hello-world-featured" \
        || "$title" == ext-site-icon-* || "$title" == ext-custom-logo-* ]]; then
    wp post delete "$id" --force --quiet
    count=$((count + 1))
  fi
done < <(wp post list --post_type=attachment --fields=ID,post_title --format=csv)
echo "-- $count Anhänge gelöscht"

wp option add scbb_migration_002 "$(date +%Y-%m-%d)"
echo "Fertig."
