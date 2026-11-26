#!/usr/bin/env bash
# Einmalige Migration: Dateireste der entfernten Onboarding-Plugins aus wp-content/uploads löschen.
#   backup/     Originalkopien, die Imagify vor der Bildoptimierung angelegt hat (Stockfotos aus Migration 002)
#   beyondseo/  Log-Dateien von BeyondSEO
#   wpforms/    Cache von WPForms
#   et_temp/    leerer Temp-Ordner
# Entscheidung 2026-11-26. Läuft nur einmal (Option scbb_migration_003).
# Ausführen: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/003-plugin-reste-entfernen.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

if wp option get scbb_migration_003 >/dev/null 2>&1; then
  echo "Migration 003 wurde bereits am $(wp option get scbb_migration_003) ausgeführt – nichts zu tun."
  exit 0
fi

UPLOADS="$WP_PATH/wp-content/uploads"
for d in backup beyondseo wpforms et_temp; do
  if [ -d "$UPLOADS/$d" ]; then
    echo "-- lösche uploads/$d ($(du -sh "$UPLOADS/$d" | cut -f1))"
    rm -rf -- "${UPLOADS:?}/$d"
  fi
done

wp option add scbb_migration_003 "$(date +%Y-%m-%d)"
echo "Fertig."
