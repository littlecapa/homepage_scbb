#!/usr/bin/env bash
# Konfiguration der Vereinsseite Schachclub Bonn Beuel (IONOS Managed WordPress).
# Idempotent: jeder Lauf führt zum selben Ergebnis. Fasst keine Inhalte an.
# Ausführen: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < setup.sh
# Runbook: https://littlecapa.atlassian.net/wiki/spaces/HS/pages/871661569
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

echo "== 0. Datenbank-Backup"
mkdir -p "$HOME/backups"
wp db export "$HOME/backups/db-$(date +%Y%m%d-%H%M%S)-setup.sql" --quiet
ls -1t "$HOME/backups"/db-*.sql | tail -n +11 | xargs -r rm --   # nur die letzten 10 behalten

echo "== 1. Grundeinstellungen"
wp option update blogname "Schachclub Bonn Beuel"
wp option update blogdescription ""                       # TODO: Untertitel festlegen
wp language core is-installed de_DE || wp language core install de_DE
wp site switch-language de_DE
wp option update timezone_string "Europe/Berlin"
wp option update date_format "j. F Y"
wp option update time_format "H:i"
wp option update start_of_week 1
wp rewrite structure '/%postname%/' --hard
# Während des Aufbaus für Suchmaschinen gesperrt. Beim Livegang auf 1 setzen.
wp option update blog_public 0
# Kommentare und Pingbacks aus (Spam, Moderationsaufwand).
wp option update default_comment_status closed
wp option update default_ping_status closed
wp option update default_pingback_flag 0

echo "== 2. Theme"
# Offizielles Standardtheme, langfristig gepflegt, keine Bindung an Drittanbieter (Entscheidung 2026-11-26).
THEME="twentytwentyfive"
wp theme is-installed "$THEME" || wp theme install "$THEME"
wp theme activate "$THEME"
# Andere Themes entfernen (außer dem aktiven).
for t in $(wp theme list --status=inactive --field=name); do
  wp theme delete "$t"
done

echo "== 3. Plugins"
# Erlaubte Plugins: alles, was hier nicht steht, wird entfernt.
# IONOS-System-Plugins (ionos-*) und Must-Use-Plugins (Installatron-Automatik) werden nicht angefasst.
PLUGINS_KEEP=(
  # Bewusst leer (Entscheidung 2026-11-26). Neues Plugin nur mit Begründung als Kommentar.
)
for p in $(wp plugin list --status=active --field=name; wp plugin list --status=inactive --field=name); do
  case "$p" in ionos-*) continue ;; esac
  if [[ " ${PLUGINS_KEEP[*]-} " == *" $p "* ]]; then continue; fi
  echo "-- entferne $p"
  wp plugin deactivate "$p" --quiet || true
  wp plugin delete "$p"
done
for p in "${PLUGINS_KEEP[@]-}"; do
  [ -z "$p" ] && continue
  wp plugin is-installed "$p" || wp plugin install "$p"
  wp plugin activate "$p"
done

echo "== 4. Pflichtseiten"
ensure_page() {  # ensure_page <slug> <titel>  – legt Seite als Entwurf an, falls nicht vorhanden
  local id
  id=$(wp post list --post_type=page --name="$1" --post_status=any --format=ids)
  if [ -z "$id" ]; then
    wp post create --post_type=page --post_name="$1" --post_title="$2" --post_status=draft --porcelain
  else
    echo "$id"
  fi
}
ensure_page impressum "Impressum" >/dev/null
PRIVACY_ID=$(ensure_page datenschutz "Datenschutzerklärung")
wp option update wp_page_for_privacy_policy "$PRIVACY_ID"
# Texte werden im Dashboard gepflegt (Inhalt, nicht Konfiguration).

echo "== 5. Menüstruktur"
# TODO: Navigation-Block für Twenty Twenty-Five (Aktuelles · Verein · Training · Mannschaften · Turniere · Jugend · Kontakt).

echo "== 6. Benutzerrollen"
# TODO: persönliche Konten statt Sammel-Admin, Rollen für Webmaster, Turnierleiter, Jugendwart.

wp cache flush --quiet || true
echo "Fertig."
