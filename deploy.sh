#!/usr/bin/env bash
# Rollt den Stand dieses Repos auf den Server aus:
#   1. Child-Theme theme/scbb hochladen (Server-Kopie wird exakt angeglichen)
#   2. setup.sh auf dem Server ausführen
# Zugang: Umgebungsvariable SCBB_SSH=<benutzer>@<host> oder Datei .deploy.env (nicht im Repo, siehe Runbook).
set -euo pipefail
cd "$(dirname "$0")"

[ -f .deploy.env ] && source .deploy.env
: "${SCBB_SSH:?SCBB_SSH fehlt – z. B. in .deploy.env: SCBB_SSH=benutzer@host}"

echo "== Theme hochladen"
rsync -az --delete --exclude '.DS_Store' theme/scbb/ "$SCBB_SSH:public/wp-content/themes/scbb/"

echo "== Rechtstexte hochladen"
rsync -az --delete --exclude '.DS_Store' content/ "$SCBB_SSH:scbb-content/"

echo "== setup.sh ausführen"
ssh "$SCBB_SSH" 'bash -s' < setup.sh
