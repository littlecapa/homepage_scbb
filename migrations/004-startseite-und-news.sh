#!/usr/bin/env bash
# Einmalige Migration: Onboarding-Seiten weiterverwenden.
#   'start' (Entwurf)  -> „Startseite“, veröffentlicht; wird page_on_front (Inhalt aus templates/front-page.html)
#   'blog'  (Entwurf)  -> Slug 'news', Titel „News“, veröffentlicht; wird page_for_posts
# Entscheidung 2026-11-27. Läuft nur einmal (Option scbb_migration_004).
# Ausführen VOR dem nächsten deploy.sh: ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/004-startseite-und-news.sh
set -euo pipefail

WP_PATH="${WP_PATH:-$HOME/public}"
wp() { command wp --path="$WP_PATH" "$@"; }

if wp option get scbb_migration_004 >/dev/null 2>&1; then
  echo "Migration 004 wurde bereits am $(wp option get scbb_migration_004) ausgeführt – nichts zu tun."
  exit 0
fi

START_ID=$(wp post list --post_type=page --name=start --post_status=any --format=ids)
if [ -n "$START_ID" ]; then
  wp post update "$START_ID" --post_title="Startseite" --post_content="" --post_status=publish
fi

BLOG_ID=$(wp post list --post_type=page --name=blog --post_status=any --format=ids)
NEWS_ID=$(wp post list --post_type=page --name=news --post_status=any --format=ids)
if [ -n "$BLOG_ID" ] && [ -z "$NEWS_ID" ]; then
  wp post update "$BLOG_ID" --post_name=news --post_title="News" --post_content="" --post_status=publish
fi

wp option add scbb_migration_004 "$(date +%Y-%m-%d)"
echo "Fertig."
