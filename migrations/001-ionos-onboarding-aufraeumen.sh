#!/usr/bin/env bash
# Einmalige Migration: Reste des IONOS/Extendify-Onboardings vom 2026-11-26 entfernen.
# Der KI-Assistent hat erfundene Blogbeiträge und Seiten mit Platzhaltertexten veröffentlicht.
# Entscheidung 2026-11-26: Beiträge löschen, Seiten als Gerüst behalten, aber auf Entwurf setzen.
# Läuft nur einmal: danach ist die Option scbb_migration_001 gesetzt und weitere Läufe tun nichts.
# Reihenfolge: vor setup.sh ausführen.
# Ausführen: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/001-ionos-onboarding-aufraeumen.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

if wp option get scbb_migration_001 >/dev/null 2>&1; then
  echo "Migration 001 wurde bereits am $(wp option get scbb_migration_001) ausgeführt – nichts zu tun."
  exit 0
fi

echo "== Datenbank-Backup"
mkdir -p "$HOME/backups"
wp db export "$HOME/backups/db-$(date +%Y%m%d-%H%M%S)-migration-001.sql" --quiet

delete_by_slug() {  # delete_by_slug <post_type> <slug>...
  local type=$1; shift
  for slug in "$@"; do
    for id in $(wp post list --post_type="$type" --name="$slug" --post_status=any --format=ids); do
      wp post delete "$id" --force
    done
  done
}

echo "== Erfundene Blogbeiträge und Beispielinhalte löschen"
delete_by_slug post \
  hello-world \
  tipps-fuer-ihre-erste-schacheroeffnung-im-verein \
  rueckblick-auf-das-packende-ligawochenende-in-bonn \
  wie-schachtraining-die-konzentration-bei-kindern-foerdert \
  die-spannendsten-endspiele-unserer-letzten-vereinsmeisterschaft \
  strategien-gegen-den-zeitnot-stress-am-turnierbrett \
  vom-anfaenger-zum-ligaspieler-ein-erfahrungsbericht \
  taktikschulung-am-vereinsabend-mattmuster-erfolgreich-erkennen \
  warum-das-koenigliche-spiel-generationen-verbindet
delete_by_slug page sample-page ticket-details ticket-quittung

echo "== Datenschutz-Seite: WordPress-Vorlage auf Slug 'datenschutz' umstellen"
for id in $(wp post list --post_type=page --name=privacy-policy --post_status=any --format=ids); do
  wp post update "$id" --post_name=datenschutz --post_title="Datenschutzerklärung"
done

echo "== Seitengerüst behalten, aber auf Entwurf (Platzhaltertexte)"
for slug in start ueber team kontakt blog impressum; do
  for id in $(wp post list --post_type=page --name="$slug" --post_status=publish --format=ids); do
    wp post update "$id" --post_status=draft
  done
done

echo "== Theme-Anpassungen des Extendify-Themes entfernen"
for type in wp_template wp_template_part; do
  for id in $(wp post list --post_type="$type" --post_status=any --format=ids); do
    if [ "$(wp post term list "$id" wp_theme --field=slug 2>/dev/null)" = "extendable" ]; then
      wp post delete "$id" --force
    fi
  done
done
echo "== Vom Assistenten erzeugte Navigationen entfernen"
delete_by_slug wp_navigation navigation site-navigation footer-navigation

wp option add scbb_migration_001 "$(date +%Y-%m-%d)"
echo "Fertig."
