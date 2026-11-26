# homepage_scbb – WordPress-Konfiguration Schachclub Bonn Beuel

Wiederholbare Einrichtung der Vereinsseite bei IONOS (Hosting für WordPress Grow), per WP-CLI über SSH.

| Datei | Zweck | Wie oft |
| --- | --- | --- |
| `setup.sh` | Konfiguration: Einstellungen, Theme, erlaubte Plugins, Pflichtseiten | beliebig oft, gleiches Ergebnis |
| `migrations/NNN-*.sh` | einmalige Aufräum- oder Umbauschritte an Inhalten | je genau einmal, merkt sich das selbst |

Beide Skripte legen vorher ein Datenbank-Backup in `~/backups` auf dem Server an.

## Ausführen

```bash
# bei neuer Installation zuerst die Migrationen, dann setup.sh
ssh <ssh-benutzer>@<ssh-host> 'bash -s' < migrations/001-ionos-onboarding-aufraeumen.sh
ssh <ssh-benutzer>@<ssh-host> 'bash -s' < setup.sh
```

SSH-Zugangsdaten stehen im Runbook, **nicht** in diesem öffentlichen Repo:
https://littlecapa.atlassian.net/wiki/spaces/HS/pages/871661569

Inhalte (Beiträge, Fotos) gehören nicht hierher, sondern in Backups bzw. den WordPress-Export.
