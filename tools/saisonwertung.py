#!/usr/bin/env python3
"""Saisonwertung der Blitz- bzw. Schnellschach-Turnierserie aus den Monatsseiten berechnen.

Aufruf: python3 tools/saisonwertung.py blitz|schnellschach

Liest alle Monatsseiten (content/blitzturniere/blitzturnier-JJJJ-MM.html bzw. content/schnellschachturniere/…),
vergibt Punkte nach der Ausschreibung und schreibt den Ergebnis-Kasten (Links auf die Monate) und die Tabelle
„Saisonwertung“ in die Seite der Serie (content/turniere-blitz.html bzw. turniere-schnellschach.html), zwischen
die Karten „Wann?/Wo?“ und den Zurück-Link.

Ausschreibung 2026/27 (scbb.de):
- Die 16 Besten eines Turniers erhalten 40, 35, 30, 26 Punkte, danach je 2 weniger (Platz 16: 2 Punkte).
  Teilen sich mehrere einen Platz (gleiche Nr. in der Kreuztabelle), bekommen sie den Durchschnitt der Punkte.
- Es zählen die 8 besten Resultate.
- Gleichstand: Blitz – höhere Einzelresultate vorn; Schnellschach – weniger Wertungen vorn.
Vereine stehen in tools/vereine.json (Spielername wie in den Kreuztabellen -> Verein).
"""
import glob
import html
import json
import os
import re
import sys


SERIEN = {
    'blitz': ('blitzturniere', 'blitzturnier', 'content/turniere-blitz.html', 'einzel'),
    'schnellschach': ('schnellschachturniere', 'schnellschachturnier', 'content/turniere-schnellschach.html', 'anzahl'),
}
STAFFEL = [40, 35, 30] + [26 - 2 * i for i in range(13)]  # Platz 1–16
BESTE = 8
MONATE = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']
KURZ = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez']


def monatspunkte(datei):
    """{Spieler: Punkte} für ein Turnier"""
    text = open(datei, encoding='utf-8').read()
    tbody = re.search(r'<tbody>(.*?)</tbody>', text, re.S).group(1)
    zeilen = [(int(nr), html.unescape(name)) for nr, name in re.findall(r'<tr><td>(\d+)\.</td><td>([^<]*)</td>', tbody)]
    punkte = {}
    for nr in sorted({nr for nr, _ in zeilen}):
        gruppe = [i for i, (n, _) in enumerate(zeilen) if n == nr]
        schnitt = sum(STAFFEL[i] if i < len(STAFFEL) else 0 for i in gruppe) / len(gruppe)
        for i in gruppe:
            if schnitt:
                punkte[zeilen[i][1]] = schnitt
    return punkte


def zahl(p):
    return f'{p:g}'.replace('.', ',')


def berechnen(serie):
    ordner, praefix, _, _ = SERIEN[serie]
    monate = []
    for datei in sorted(glob.glob(f'content/{ordner}/{praefix}-*.html')):
        jahr, mon = map(int, re.search(r'(\d{4})-(\d{2})\.html$', datei).groups())
        monate.append((jahr, mon, os.path.basename(datei)[:-5], monatspunkte(datei)))
    return monate


def tabelle(serie, monate, vereine):
    _, _, _, regel = SERIEN[serie]
    spieler = {n for *_, p in monate for n in p}
    zeilen = []
    for n in spieler:
        werte = [p.get(n) for *_, p in monate]
        gezaehlt = sorted((w for w in werte if w), reverse=True)[:BESTE]
        gesamt = sum(gezaehlt)
        schluessel = (-gesamt, [-w for w in gezaehlt]) if regel == 'einzel' else (-gesamt, len(gezaehlt))
        zeilen.append((schluessel, n, werte, gesamt))
    zeilen.sort(key=lambda z: (z[0], z[1]))
    ordner = SERIEN[serie][0]
    kopf = ['#', 'Spieler', 'Gesamt'] + [
        f'<a href="/turniere/{ordner}/{slug}/">{KURZ[mon - 1]}&nbsp;{jahr % 100}</a>' for jahr, mon, slug, _ in monate] + ['Verein']
    tbody, platz, vorher = [], 0, None
    for i, (schluessel, n, werte, gesamt) in enumerate(zeilen):
        if schluessel != vorher:
            platz = i + 1
        vorher = schluessel
        zellen = [f'{platz}.', html.escape(n), f'{zahl(gesamt)}'] + [zahl(w) if w else '' for w in werte] + [html.escape(vereine.get(n, ''))]
        tbody.append('<tr>' + ''.join(f'<td>{z}</td>' for z in zellen) + '</tr>')
    thead = ''.join(f'<th>{k}</th>' for k in kopf)
    regeltext = ('Bei Gleichstand entscheiden die höheren Einzelresultate.' if regel == 'einzel'
                 else 'Bei Gleichstand liegt vorn, wer weniger Wertungen hat.')
    figur = (f'<figure class="wp-block-table scbb-tabelle scbb-kreuz scbb-saison"><table><thead><tr>{thead}</tr></thead>'
             f'<tbody>{"".join(tbody)}</tbody></table><figcaption class="wp-element-caption">Die 16 Besten eines Turniers erhalten '
             f'40, 35, 30 und 26 Punkte, danach je 2 Punkte weniger bis 2 Punkte für Platz 16; bei geteiltem Platz zählt der '
             f'Durchschnitt. Es zählen die {BESTE} besten Resultate. {regeltext} Ein Klick auf den Monat öffnet die Kreuztabelle.'
             f'</figcaption></figure>')
    return zeilen, figur


def schreiben(serie):
    ordner, praefix, seite, _ = SERIEN[serie]
    vereine = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'vereine.json'), encoding='utf-8'))
    monate = berechnen(serie)
    zeilen, figur = tabelle(serie, monate, vereine)
    links = ' · '.join(f'<a href="/turniere/{ordner}/{slug}/">{MONATE[mon - 1]} {jahr}</a>' for jahr, mon, slug, _ in reversed(monate))
    erste, letzte = monate[0], monate[-1]
    saison = f'{erste[0]}/{(erste[0] + 1) % 100:02d}' if erste[1] >= 7 else f'{erste[0] - 1}/{erste[0] % 100:02d}'
    block = f'''<!-- wp:group {{"className":"scbb-hinweis scbb-archiv","layout":{{"type":"default"}}}} -->
<div class="wp-block-group scbb-hinweis scbb-archiv">
<!-- wp:paragraph -->
<p><strong>Ergebnisse:</strong> {links}</p>
<!-- /wp:paragraph -->
</div>
<!-- /wp:group -->

<!-- wp:heading -->
<h2 class="wp-block-heading">Saisonwertung {saison}</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Stand nach dem Turnier im {MONATE[letzte[1] - 1]} {letzte[0]} ({len(monate)} {"Turnier" if len(monate) == 1 else "Turniere"}).</p>
<!-- /wp:paragraph -->

<!-- wp:table {{"hasFixedLayout":false,"className":"scbb-tabelle scbb-kreuz scbb-saison"}} -->
{figur}
<!-- /wp:table -->

'''
    text = open(seite, encoding='utf-8').read()
    anfang = text.index('<!-- wp:group {"className":"scbb-hinweis')
    ende = text.index('<!-- wp:paragraph {"className":"scbb-zurueck"}')
    open(seite, 'w', encoding='utf-8').write(text[:anfang] + block + text[ende:])
    fehlend = sorted(n for _, n, _, _ in zeilen if n not in vereine)
    print(f'{seite}: {len(monate)} Turniere, {len(zeilen)} Spieler in der Wertung')
    if fehlend:
        print('Verein unbekannt (tools/vereine.json ergänzen):', '; '.join(fehlend))
    return monate, zeilen


if __name__ == '__main__':
    schreiben(sys.argv[1])
