#!/usr/bin/env python3
"""Kreuztabelle aus der HTML-Ausgabe von Swiss-Chess („…-Kreuz.html“) als WordPress-Seite.

Aufruf: python3 tools/swiss_kreuz.py <Kreuz.html> <ziel.html> "<Seitentitel>"
  z. B. python3 tools/swiss_kreuz.py BlitzNovember2026-Kreuz.html content/blitzturniere/blitzturnier-2026-11.html "Blitzturnier November 2026"

Swiss-Chess kürzt Namen auf 17 Zeichen; bekannte Namen werden über NAMEN vervollständigt.
"""
import html
import re
import sys

# Von Swiss-Chess gekürzte oder abweichend geschriebene Namen -> Schreibweise auf der Website
NAMEN = {
    'Evtuschenko,Danie': 'Evtuschenko,Daniel',
    'Höfer,Severin Pau': 'Höfer,Severin Paul',
    'von der Lippe,Han': 'von der Lippe,Hans-Bernd',
    'Neese,Hans-Joachi': 'Neese,Hans-Joachim',
    'Köhler,Kurt Albre': 'Köhler,Kurt Albrecht',
    'Miller,Artyom': 'Miller,Artjom',
    'Miller,artjom': 'Miller,Artjom',
}


def zellen(zeile):
    return [html.unescape(re.sub(r'<[^>]+>', '', z)).replace('\xa0', ' ').strip()
            for z in re.findall(r'<T[DH][^>]*>(.*?)</T[DH]>', zeile, re.S | re.I)]


def lesen(pfad):
    with open(pfad, encoding='utf-8', errors='replace') as f:
        text = f.read()
    runden = int(re.search(r'nach&nbsp;der&nbsp;(\d+)\.', text).group(1))
    zeilen = re.findall(r'<TR[^>]*>(.*?)</TR>', text, re.S | re.I)
    kopf = next(zellen(z) for z in zeilen if '<TH' in z.upper())
    spieler = []
    for z in zeilen:
        c = zellen(z)
        if len(c) == len(kopf) and c[0].isdigit():
            name = re.sub(r',\s+', ',', c[1])
            c[1] = NAMEN.get(name, name)
            spieler.append(c)
    return runden, kopf, spieler


def vorname_name(n):
    nach, _, vor = n.partition(',')
    return f'{vor} {nach}'.strip()


def punkte(p):
    return p.replace('.0', '').replace('.5', ',5')


def seite(quelle, titel, runden, kopf, spieler):
    def zelle(i, wert):
        if i == 0:
            return f'{wert}.'
        if wert == '-':
            return '−'
        return html.escape(wert)

    def vorn(z):  # Punkte und Buchholz direkt hinter die Wertzahl (Spalten 4 und 5, bleiben beim Wischen stehen)
        return z[:3] + z[-2:] + z[3:-2]
    thead = ''.join(f'<th>{html.escape(k)}</th>' for k in vorn(kopf))
    tbody = ''.join('<tr>' + ''.join(f'<td>{zelle(i, w)}</td>' for i, w in enumerate(vorn(c))) + '</tr>' for c in spieler)
    erste = spieler[:3]
    sieger = (f'Es gewann <strong>{vorname_name(erste[0][1])}</strong> mit {punkte(erste[0][-2])} Punkten '
              f'vor {vorname_name(erste[1][1])} ({punkte(erste[1][-2])}) und {vorname_name(erste[2][1])} ({punkte(erste[2][-2])}).')
    kampflos = any(w in ('+', '-') for c in spieler for w in c[3:-2])
    hinweis = ' „+“/„−“: kampflos gewonnen/verloren.' if kampflos else ''
    ordner = quelle.split('/')[-2]
    zurueck = f'/turniere/{ordner}/'
    zurueck_text = {'blitzturniere': 'Blitzturnieren', 'schnellschachturniere': 'Schnellschachturnieren'}.get(ordner, 'Turnieren')
    return f'''<!-- Quelle: github.com/littlecapa/homepage_scbb/{quelle} – Änderungen bitte dort, deploy.sh überträgt sie. -->
<!-- Titel: {titel} -->
<!-- Grundlage: Swiss-Chess-Kreuztabelle, erzeugt mit tools/swiss_kreuz.py. -->

<!-- wp:paragraph {{"className":"is-style-lead"}} -->
<p class="is-style-lead">{len(spieler)} Teilnehmende, {runden} Runden Schweizer System. {sieger}</p>
<!-- /wp:paragraph -->

<!-- wp:heading -->
<h2 class="wp-block-heading">Kreuztabelle</h2>
<!-- /wp:heading -->

<!-- wp:table {{"hasFixedLayout":false,"className":"scbb-tabelle scbb-kreuz scbb-kreuz--wertung"}} -->
<figure class="wp-block-table scbb-tabelle scbb-kreuz scbb-kreuz--wertung"><table><thead><tr>{thead}</tr></thead><tbody>{tbody}</tbody></table><figcaption class="wp-element-caption">TWZ: Turnierwertzahl, Buchh: Buchholz-Wertung.{hinweis}</figcaption></figure>
<!-- /wp:table -->

<!-- wp:paragraph {{"className":"scbb-zurueck"}} -->
<p class="scbb-zurueck"><a href="{zurueck}">Zurück zu den {zurueck_text}</a></p>
<!-- /wp:paragraph -->
'''


if __name__ == '__main__':
    quelle, ziel, titel = sys.argv[1:4]
    runden, kopf, spieler = lesen(quelle)
    rel = re.sub(r'^.*?(content/)', r'\1', ziel)
    with open(ziel, 'w', encoding='utf-8') as f:
        f.write(seite(rel, titel, runden, kopf, spieler))
    offen = [c[1] for c in spieler if len(c[1]) == 17]
    print(f'{ziel}: {len(spieler)} Spieler, {runden} Runden')
    if offen:
        print('Evtl. gekürzte Namen:', '; '.join(offen))
