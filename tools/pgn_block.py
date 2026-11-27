#!/usr/bin/env python3
"""Partien als nachspielbaren Block des Plugins RPB Chessboard („rpb-chessboard/pgn“).

Als Modul:  from pgn_block import rpb_block   (z. B. in tools/alt-news-export.py)
Als Skript: python3 tools/pgn_block.py <datei.html> …
            ersetzt aufklappbare PGN-Texte (Block „Details“ mit „Partie …“ + Code-Block) durch den Viewer-Block.
"""
import html
import json
import re
import sys

# Alter Stand: Partie als aufklappbarer Text (Details + Code)
ALT = re.compile(
    r'<!-- wp:details -->\n<details class="wp-block-details"><summary>Partie[^<]*</summary>'
    r'<!-- wp:code -->\n<pre class="wp-block-code"><code>(.*?)</code></pre>\n<!-- /wp:code --></details>\n<!-- /wp:details -->',
    re.S,
)


def rpb_block(pgn):
    """PGN-Text -> selbstschließender Block; Attribut-JSON wie WordPress es serialisiert (ohne --, <, >, &, ")."""
    pgn = re.sub(r'(\d+)\.\s*\.\.(?!\.)', r'\1...', pgn)  # „25. .. Te5“ (alte Seite) ist kein gültiges PGN -> „25... Te5“
    attrs = json.dumps({'pgn': pgn.strip() + '\n'}, ensure_ascii=False)
    for zeichen, ersatz in (('\\"', '\\u0022'), ('--', '\\u002d\\u002d'), ('<', '\\u003c'), ('>', '\\u003e'), ('&', '\\u0026')):
        attrs = attrs.replace(zeichen, ersatz)
    return f'<!-- wp:rpb-chessboard/pgn {attrs} /-->'


def umstellen(text):
    return ALT.subn(lambda m: rpb_block(html.unescape(m.group(1))), text)


if __name__ == '__main__':
    for datei in sys.argv[1:]:
        with open(datei, encoding='utf-8') as f:
            neu, n = umstellen(f.read())
        if n:
            with open(datei, 'w', encoding='utf-8') as f:
                f.write(neu)
        print(n, datei)
