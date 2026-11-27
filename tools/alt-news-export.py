#!/usr/bin/env python3
"""Beiträge der alten Website scbb.de (WordPress-REST-API) nach content/news/archiv/ übertragen.

Aufruf:  python3 tools/alt-news-export.py 2026-07-30 [bis-datum]
Ergebnis je Beitrag: content/news/archiv/<datum>-<slug>/
    meta.json   Titel, Datum, Slug, Kategorie, Beitragsbild
    inhalt.html Block-HTML; Bilder als Platzhalter {{bild:<datei>}} (ersetzt Migration 007 beim Import)
    *.jpg       Fotos (längste Seite max. 1600 px)
Import auf dem Server: migrations/007-news-archiv-scbb.sh (überspringt vorhandene Slugs).
"""
import html
import io
import json
import re
import sys
import subprocess
from pathlib import Path

from PIL import Image

API = 'https://scbb.de/wp-json/wp/v2'
ZIEL = Path(__file__).resolve().parent.parent / 'content' / 'news' / 'archiv'

# Alte Kategorien -> neue (Mannschaften / Turniere / Allgemein). „Top-News“ entfällt.
KATEGORIEN = {6: 'mannschaften', 7: 'turniere', 12: 'turniere', 22: 'turniere', 10: 'turniere',
              15: 'turniere', 8: 'turniere', 11: 'turniere', 1: 'allgemein'}
# Beitragsbilder, die NICHT übernommen werden: altes Logo, Vereinslogo, fremdes Bild (Lizenz unklar)
BILD_AUSLASSEN = {12, 5787, 100}
# Alte interne Links -> neue Seiten
LINKS = {
    'https://scbb.de/turniere/blitzturnierserie/': '/turniere/blitzturniere/',
    'https://scbb.de/turniere/schnellturnierserie/': '/turniere/schnellschachturniere/',
    'https://scbb.de/turniere/vereinsschnellschachmeisterschaft/': '/turniere/',
    'https://scbb.de/termine/': '/termine/',
}


def hole(url):
    # curl statt urllib: nutzt die Zertifikate des Systems (python.org-Python bringt keine mit)
    return subprocess.run(['curl', '-sSfL', '--max-time', '60', url], check=True, capture_output=True).stdout


def foto(url, ordner):
    """Originalgröße laden (ohne -WxH-Suffix), auf max. 1600 px verkleinern, als JPG speichern."""
    url = re.sub(r'-\d+x\d+(\.\w+)$', r'\1', url)
    name = re.sub(r'\.\w+$', '.jpg', url.rsplit('/', 1)[1])
    im = Image.open(io.BytesIO(hole(url))).convert('RGB')
    im.thumbnail((1600, 1600))
    im.save(ordner / name, quality=82, optimize=True)
    return name


def absatz(inner):
    return f'<!-- wp:paragraph -->\n<p>{inner}</p>\n<!-- /wp:paragraph -->\n\n'


def bildblock(name, alt, caption):
    cap = f'<figcaption class="wp-element-caption">{caption}</figcaption>' if caption else ''
    return (f'<!-- wp:image {{"sizeSlug":"large","linkDestination":"none","className":"scbb-foto"}} -->\n'
            f'<figure class="wp-block-image size-large scbb-foto"><img src="{{{{bild:{name}}}}}" alt="{html.escape(alt)}"/>{cap}</figure>\n'
            f'<!-- /wp:image -->\n\n')


def umwandeln(c, ordner):
    out = ''
    c = c.replace('<p><!--more--></p>', '').replace('<!--more-->', '')
    # PGN-Viewer (Plugin embed-chessboard) -> Partie als aufklappbarer Text
    def pgn(m):
        t = html.unescape(m.group(1)).strip()
        kopf = dict(re.findall(r'\[(\w+) "([^"]*)"\]', t))
        züge = re.sub(r'\s*\[\w+ "[^"]*"\]\s*', '', t).strip()
        tags = '\n'.join(f'[{k} "{v}"]' for k, v in kopf.items())
        titel = f'Partie {kopf.get("White", "")} – {kopf.get("Black", "")} ({kopf.get("Result", "")})'
        return ('\x00' + f'<!-- wp:details -->\n<details class="wp-block-details"><summary>{html.escape(titel)}</summary>'
                f'<!-- wp:code -->\n<pre class="wp-block-code"><code>{html.escape(tags + chr(10) + chr(10) + züge)}</code></pre>\n<!-- /wp:code --></details>\n<!-- /wp:details -->\n\n' + '\x00')
    c = re.sub(r"<div class='chessboard-wrapper'>.*?<textarea[^>]*>(.*?)</textarea>.*?</iframe></div>", pgn, c, flags=re.S)
    # Bilder mit Bildunterschrift
    def bild(m):
        b = m.group(0)
        src = re.search(r'src="([^"]+)"', b).group(1)
        cap = re.search(r'wp-caption-text">(.*?)</p>', b, re.S)
        name = foto(src, ordner)
        capt = cap.group(1).strip() if cap else ''
        return '\x00' + bildblock(name, html.unescape(re.sub('<[^>]+>', '', capt)) or 'Foto', capt) + '\x00'
    c = re.sub(r'<div id="attachment_\d+"[^>]*>.*?</div>', bild, c, flags=re.S)
    c = re.sub(r'<p>\s*(<img[^>]+>)\s*</p>', lambda m: bild(m), c)
    for teil in c.split('\x00'):
        if teil.startswith('<!-- wp:'):
            out += teil
            continue
        for p in re.findall(r'<p>(.*?)</p>', teil, re.S):
            p = p.replace('<br />\n', '<br>').replace('<br />', '<br>').strip()
            if not p or p == '&nbsp;':
                continue
            for alt, neu in LINKS.items():
                p = p.replace(f'href="{alt}"', f'href="{neu}"')
            # externe Links in neuem Tab
            p = re.sub(r'<a href="(https?://[^"]+)">', r'<a href="\1" target="_blank" rel="noopener">', p)
            out += absatz(p)
    return out.rstrip() + '\n'


# Alternativtexte für Beitragsbilder (Dateiname -> Text)
ALT = {
    'Aufstiegsfeier2026.jpg': 'Aufstiegsfeier 2026 im Biergarten Schänzchen',
    '1M-2627-01.jpg': 'Mannschaftsfoto der 2. Mannschaft, Saison 2026/27',
    '4M4-5M-01.jpg': 'Interner Mannschaftskampf: 4. gegen 5. Mannschaft',
    'VSM2026-03.jpg': 'Vereinsschnellschachmeisterschaft 2026',
}


def meta_alt(p, name=''):
    return ALT.get(name) or 'Foto zum Beitrag: ' + html.unescape(p['title']['rendered'])


def main():
    von = sys.argv[1]
    bis = sys.argv[2] if len(sys.argv) > 2 else '2100-01-01'
    posts = json.loads(hole(f'{API}/posts?after={von}T00:00:00&before={bis}T23:59:59&per_page=100'
                            '&_fields=id,date,slug,title,content,categories,featured_media'))
    for p in posts:
        ordner = ZIEL / f'{p["date"][:10]}-{p["slug"]}'
        ordner.mkdir(parents=True, exist_ok=True)
        inhalt = umwandeln(p['content']['rendered'], ordner)
        beitragsbild = None
        if p['featured_media'] and p['featured_media'] not in BILD_AUSLASSEN:
            m = json.loads(hole(f'{API}/media/{p["featured_media"]}?_fields=source_url'))
            beitragsbild = foto(m['source_url'], ordner)
        elif '{{bild:' in inhalt:
            beitragsbild = re.search(r'\{\{bild:([^}]+)\}\}', inhalt).group(1)
        if beitragsbild and f'{{{{bild:{beitragsbild}}}}}' not in inhalt:
            # Einzelansicht zeigt das Beitragsbild nicht -> nach dem ersten Absatz in den Text setzen
            erster = inhalt.find('<!-- /wp:paragraph -->\n\n')
            pos = erster + len('<!-- /wp:paragraph -->\n\n') if erster >= 0 else 0
            inhalt = inhalt[:pos] + bildblock(beitragsbild, meta_alt(p, beitragsbild), '') + inhalt[pos:]
        kat = next((KATEGORIEN[k] for k in p['categories'] if k in KATEGORIEN), 'allgemein')
        meta = {'titel': html.unescape(p['title']['rendered']), 'datum': p['date'].replace('T', ' '),
                'slug': p['slug'], 'kategorie': kat, 'beitragsbild': beitragsbild,
                'quelle': f'https://scbb.de/{p["slug"]}/'}
        (ordner / 'meta.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        (ordner / 'inhalt.html').write_text(inhalt, encoding='utf-8')
        print(meta['datum'][:10], kat.ljust(12), beitragsbild or '-', '|', meta['titel'])


if __name__ == '__main__':
    main()
