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
wp option update blogdescription "Traditionsverein mit aktiver Jugendabteilung"
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
# Eltern-Theme: offizielles Standardtheme, langfristig gepflegt, keine Bindung an Drittanbieter (Entscheidung 2026-11-26).
# Child-Theme 'scbb' (Logo, Farben, Kopfbereich) liegt im Repo unter theme/scbb und wird von deploy.sh hochgeladen.
PARENT_THEME="twentytwentyfive"
THEME="scbb"
wp theme is-installed "$PARENT_THEME" || wp theme install "$PARENT_THEME"
if ! wp theme is-installed "$THEME"; then
  echo "FEHLER: Theme '$THEME' fehlt. Bitte über deploy.sh ausführen (lädt theme/scbb hoch)." >&2
  exit 1
fi
wp theme activate "$THEME"
# Andere Themes entfernen (außer aktivem Theme und Eltern-Theme).
for t in $(wp theme list --status=inactive --field=name); do
  [ "$t" = "$PARENT_THEME" ] && continue
  wp theme delete "$t"
done
# Design-Änderungen aus dem Website-Editor verwerfen: Quelle der Wahrheit sind die Dateien im Repo.
for type in wp_template wp_template_part wp_global_styles; do
  for id in $(wp post list --post_type="$type" --post_status=any --format=ids); do
    echo "-- verwerfe Editor-Anpassung $type #$id"
    wp post delete "$id" --force
  done
done
# Vereinslogo als Browser-Icon (Favicon) und Site-Logo; ersetzt den Springer aus dem Onboarding.
LOGO_ID=$(wp post list --post_type=attachment --meta_key=_scbb_asset --meta_value=logo --format=ids)
if [ -z "$LOGO_ID" ]; then
  LOGO_ID=$(wp media import "$WP_PATH/wp-content/themes/$THEME/assets/logo.png" --title="Logo Schachclub Bonn/Beuel" --alt="Logo Schachclub Bonn/Beuel" --porcelain)
  wp post meta update "$LOGO_ID" _scbb_asset logo
fi
wp option update site_icon "$LOGO_ID"
wp option update site_logo "$LOGO_ID"
# Startseite und News-Seite: siehe Abschnitt 4 (Seiten).

echo "== 3. Plugins"
# Erlaubte Plugins: alles, was hier nicht steht, wird entfernt.
# IONOS-System-Plugins (ionos-*) und Must-Use-Plugins (Installatron-Automatik) werden nicht angefasst.
PLUGINS_KEEP=(
  # Neues Plugin nur mit Begründung als Kommentar (Grundsatz seit 2026-11-26: so wenige wie möglich).
  rpb-chessboard  # 2026-11-27: Partien nachspielbar (PGN-Viewer); Editor-Block „Schachpartie“ für News. Gepflegt, ohne externe Dienste.
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
# RPB Chessboard: Brett links fest neben der scrollbaren Notation (Standard „frame“ zeigt das Brett nur als Popup),
# Felder 40 px (Brett 320 px), ohne Zuggeräusch. Figuren in der Notation deutsch (K, D, T, L, S).
wp option update rpbchessboard_navigationBoard scrollLeft
wp option update rpbchessboard_nboSquareSize 40
wp option update rpbchessboard_playSound 0

echo "== 4. Pflichtseiten"
ensure_page() {  # ensure_page <slug> <titel> [eltern-id] [status beim Anlegen, Standard: draft]
  local id parent="${3:-0}" status="${4:-draft}"
  id=$(wp post list --post_type=page --name="$1" --post_status=any --format=ids)
  if [ -z "$id" ]; then
    wp post create --post_type=page --post_name="$1" --post_title="$2" --post_parent="$parent" --post_status="$status" --porcelain
  else
    if [ "$parent" != "0" ] && [ "$(wp post get "$id" --field=post_parent)" != "$parent" ]; then
      wp post update "$id" --post_parent="$parent" >&2
    fi
    echo "$id"
  fi
}
IMPRESSUM_ID=$(ensure_page impressum "Impressum")
PRIVACY_ID=$(ensure_page datenschutz "Datenschutzerklärung")
wp option update wp_page_for_privacy_policy "$PRIVACY_ID"

# Rechtstexte kommen aus dem Repo (content/*.html, von deploy.sh nach ~/scbb-content kopiert),
# damit jede Änderung nachvollziehbar ist. Veröffentlicht wird von Hand, wenn der Vorstand den Text bestätigt hat.
sync_content() {  # sync_content <post-id> <datei>
  local file="$HOME/scbb-content/$2" tmp
  [ -f "$file" ] || { echo "-- $2 nicht vorhanden, übersprungen"; return; }
  tmp=$(mktemp)
  grep -v -E '^<!-- (Quelle|Grundlage|Titel):' "$file" > "$tmp"
  if [ "$(wp post get "$1" --field=post_content)" != "$(cat "$tmp")" ]; then
    wp post update "$1" "$tmp"
  fi
  rm -f "$tmp"
}
sync_content "$IMPRESSUM_ID" impressum.html
sync_content "$PRIVACY_ID" datenschutz.html  # von scbb.de übernommen (2026-11-27), veröffentlicht von Hand

# Vereinsseiten aus dem Repo (Inhalte mit Namen, die sich nur bei Wahlen ändern).
UEBER_ID=$(ensure_page ueber "Über uns")
VORSTAND_ID=$(ensure_page vorstand "Vorstand" "$UEBER_ID")
SATZUNG_ID=$(ensure_page satzung "Satzung" "$UEBER_ID" publish)
DSO_ID=$(ensure_page datenschutzordnung "Datenschutzordnung" "$UEBER_ID" publish)
SCHUTZ_ID=$(ensure_page schutzkonzept "Schutzkonzept" "$UEBER_ID" publish)  # Kinder-/Jugendschutz, Version 1.0 vom 09.07.2026
sync_content "$UEBER_ID" ueber.html          # Inhalt von scbb.de/verein (2026-11-27)
sync_content "$VORSTAND_ID" vorstand.html
sync_content "$SATZUNG_ID" satzung.html
sync_content "$DSO_ID" datenschutzordnung.html
sync_content "$SCHUTZ_ID" schutzkonzept.html
# Über uns + Vorstand wurden als Entwurf angelegt; seit 2026-11-27 mit Inhalt -> veröffentlichen.
[ "$(wp post get "$UEBER_ID" --field=post_title)" = "Über uns" ] || wp post update "$UEBER_ID" --post_title="Über uns"  # hieß früher „Über“
for id in "$UEBER_ID" "$VORSTAND_ID"; do
  [ "$(wp post get "$id" --field=post_status)" = publish ] || wp post update "$id" --post_status=publish
done

# Jugendseiten (Inhalt von littlecapa.com/jugendschach übernommen, 2026-11-26). Beim Anlegen direkt veröffentlicht.
JUGEND_ID=$(ensure_page jugend "Schachjugend" 0 publish)
TRAINING_ID=$(ensure_page training "Jugendschachtraining" "$JUGEND_ID" publish)
sync_content "$JUGEND_ID" jugend.html
sync_content "$TRAINING_ID" jugend-training.html

# Startseite (Inhalt kommt aus templates/front-page.html) und News (Übersicht der Beiträge)
START_ID=$(ensure_page start "Startseite" 0 publish)
NEWS_ID=$(ensure_page news "News" 0 publish)
wp option update show_on_front page
wp option update page_on_front "$START_ID"
wp option update page_for_posts "$NEWS_ID"

# Detailseiten der Bereiche auf der Startseite
TURNIERE_ID=$(ensure_page turniere "Turniere" 0 publish)
MANNSCHAFTEN_ID=$(ensure_page mannschaften "Mannschaften" 0 publish)
sync_content "$TURNIERE_ID" turniere.html
# Unterseiten Turniere: /turniere/vereinsmeisterschaft/, /turniere/blitzturniere/, /turniere/schnellschachturniere/
VM_ID=$(ensure_page vereinsmeisterschaft "Vereinsmeisterschaft" "$TURNIERE_ID" publish)
BLITZ_ID=$(ensure_page blitzturniere "Blitzturniere" "$TURNIERE_ID" publish)
SCHNELL_ID=$(ensure_page schnellschachturniere "Schnellschachturniere" "$TURNIERE_ID" publish)
sync_content "$VM_ID" turniere-vereinsmeisterschaft.html
sync_content "$BLITZ_ID" turniere-blitz.html
sync_content "$SCHNELL_ID" turniere-schnellschach.html
# Vereinsschnellschachmeisterschaft (/turniere/vereinsschnellschachmeisterschaft/, von scbb.de übernommen) mit Archiv
VSSM_ID=$(ensure_page vereinsschnellschachmeisterschaft "Vereinsschnellschachmeisterschaft" "$TURNIERE_ID" publish)
sync_content "$VSSM_ID" turniere-vereinsschnellschachmeisterschaft.html
# Archive (Vereinsmeisterschaft, Vereinsschnellschachmeisterschaft): je Saison/Jahr content/<ordner>/<slug>.html,
# Seitentitel aus der Kopfzeile „<!-- Titel: … -->“, Elternseite = Hauptseite des Turniers
archiv_seiten() {  # archiv_seiten <ordner> <eltern-id>
  local f slug titel a_id
  for f in "$HOME/scbb-content/$1/"*.html; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .html)
    titel=$(sed -n 's/^<!-- Titel: \(.*\) -->$/\1/p' "$f")
    a_id=$(ensure_page "$slug" "$titel" "$2" publish)
    sync_content "$a_id" "$1/$slug.html"
  done
}
archiv_seiten vereinsmeisterschaft "$VM_ID"
archiv_seiten vereinsschnellschachmeisterschaft "$VSSM_ID"
# Monatsturniere: je Monat content/blitzturniere/blitzturnier-JJJJ-MM.html usw. (erzeugt mit tools/swiss_kreuz.py)
archiv_seiten blitzturniere "$BLITZ_ID"
archiv_seiten schnellschachturniere "$SCHNELL_ID"
sync_content "$MANNSCHAFTEN_ID" mannschaften.html
# Unterseiten Mannschaften: /mannschaften/1-mannschaft/ … /5-mannschaft/ (Slugs wie auf scbb.de), /u16/, /u20/
for n in 1 2 3 4 5; do
  M_ID=$(ensure_page "$n-mannschaft" "$n. Mannschaft" "$MANNSCHAFTEN_ID" publish)
  sync_content "$M_ID" "mannschaften-$n.html"
done
U16_ID=$(ensure_page u16 "U16" "$MANNSCHAFTEN_ID" publish)
U20_ID=$(ensure_page u20 "U20" "$MANNSCHAFTEN_ID" publish)
sync_content "$U16_ID" mannschaften-u16.html
sync_content "$U20_ID" mannschaften-u20.html

# Termine (/termine/): Tabelle „Nächste Termine“, monatlich weiterrollen (content/termine.html)
TERMINE_ID=$(ensure_page termine "Nächste Termine" 0 publish)
wp post update "$TERMINE_ID" --post_title="Nächste Termine" >/dev/null  # Titel auch bei bestehender Seite
sync_content "$TERMINE_ID" termine.html

# Seiten-Templates: nur das Standard-Template des Themes (Reste des Extendify-Themes zurücksetzen).
for id in $(wp post list --post_type=page --post_status=any --format=ids); do
  tpl=$(wp post meta get "$id" _wp_page_template 2>/dev/null || true)
  if [ -n "$tpl" ] && [ "$tpl" != "default" ]; then
    echo "-- Seite #$id: Template '$tpl' -> default"
    wp post meta update "$id" _wp_page_template default
  fi
done

echo "== 5. Menüstruktur"
# Menüpunkte stehen im Kopfbereich: theme/scbb/patterns/header.php

echo "== 6. Benutzerrollen"
# TODO: persönliche Konten statt Sammel-Admin, Rollen für Webmaster, Turnierleiter, Jugendwart.

wp cache flush --quiet || true
echo "Fertig."
