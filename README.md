# homepage_scbb – WordPress-Konfiguration Schachclub Bonn Beuel

Wiederholbare Einrichtung der Vereinsseite bei IONOS (Hosting für WordPress Grow), per WP-CLI über SSH.

| Pfad | Zweck | Wie oft |
| --- | --- | --- |
| `deploy.sh` | lädt das Theme hoch und führt `setup.sh` auf dem Server aus | nach jeder Änderung |
| `setup.sh` | Konfiguration: Einstellungen, Theme, erlaubte Plugins, Pflichtseiten | beliebig oft, gleiches Ergebnis |
| `theme/scbb/` | Child-Theme von Twenty Twenty-Five: Logo, Farben, Schrift, Kopfbereich | wird von `deploy.sh` 1:1 auf den Server gespiegelt |
| `migrations/NNN-*.sh` | einmalige Aufräum- oder Umbauschritte an Inhalten | je genau einmal, merkt sich das selbst |
| `tools/header-board.py` | erzeugt die Brett-Grafik `theme/scbb/assets/header-board.svg` | nur bei Design-Änderung |

`setup.sh` und die Migrationen legen vorher ein Datenbank-Backup in `~/backups` auf dem Server an.

**Wichtig:** Design-Änderungen im WordPress-Website-Editor werden beim nächsten `deploy.sh` verworfen. Quelle der Wahrheit sind die Dateien in `theme/scbb/`.

## Ausführen

```bash
# einmalig: Zugang hinterlegen (Datei ist in .gitignore, Werte siehe Runbook)
echo 'SCBB_SSH=<ssh-benutzer>@<ssh-host>' > .deploy.env

# bei neuer Installation zuerst die Migrationen
ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/001-ionos-onboarding-aufraeumen.sh

# danach und nach jeder Änderung
./deploy.sh
```

Nach CSS-Änderungen die `Version` in `theme/scbb/style.css` erhöhen, damit Browser die neue Datei laden.

SSH-Zugangsdaten stehen im Runbook, **nicht** in diesem öffentlichen Repo:
https://littlecapa.atlassian.net/wiki/spaces/HS/pages/871661569

Inhalte (Beiträge, Fotos) gehören nicht hierher, sondern in Backups bzw. den WordPress-Export.
