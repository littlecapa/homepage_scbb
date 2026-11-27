# Erzeugt eine perspektivische Schachbrett-Grafik (SVG) für den Kopfbereich.
import sys
W, H = 900, 200
BG = "#fff"  # Hintergrund des Kopfbereichs (muss zu style.css passen)
LIGHT, DARK = "#e3e9f6", "#16213a"  # Brettfelder (helle Felder leicht blau, damit sie sich vom Weiß abheben)
# Brett-Eckpunkte: hinten schmal (oben), vorne breit (unten), rechts ausgerichtet
back_y, front_y = 70, 215
back_l, back_r = 470, 830
front_l, front_r = 300, 1000
def lerp(a, b, t): return a + (b - a) * t
def row_y(t):
    # perspektivische Verkürzung: hintere Reihen dichter
    return back_y + (front_y - back_y) * (t ** 1.6)
def x_at(col_t, y):
    t = (y - back_y) / (front_y - back_y)
    l = lerp(back_l, front_l, t); r = lerp(back_r, front_r, t)
    return lerp(l, r, col_t)
out = []
out.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" preserveAspectRatio="xMaxYMid slice">')
out.append('<defs>'
  '<linearGradient id="fade" x1="0" x2="1" y1="0" y2="0">'
  f'<stop offset="0" stop-color="{BG}" stop-opacity="1"/>'
  f'<stop offset="0.38" stop-color="{BG}" stop-opacity="1"/>'
  f'<stop offset="0.7" stop-color="{BG}" stop-opacity="0.15"/>'
  f'<stop offset="1" stop-color="{BG}" stop-opacity="0"/></linearGradient>'
  '<linearGradient id="depth" x1="0" x2="0" y1="0" y2="1">'
  f'<stop offset="0" stop-color="{BG}" stop-opacity="0.75"/>'
  f'<stop offset="0.6" stop-color="{BG}" stop-opacity="0"/></linearGradient>'
  '<radialGradient id="glow" cx="0.72" cy="0.55" r="0.45">'
  f'<stop offset="0" stop-color="#4169e1" stop-opacity="0.18"/>'
  f'<stop offset="1" stop-color="#4169e1" stop-opacity="0"/></radialGradient>'
  '</defs>')
out.append(f'<rect width="{W}" height="{H}" fill="{BG}"/>')
out.append(f'<rect width="{W}" height="{H}" fill="url(#glow)"/>')
for r in range(8):
    y0, y1 = row_y(r/8), row_y((r+1)/8)
    for c in range(8):
        pts = [(x_at(c/8, y0), y0), (x_at((c+1)/8, y0), y0), (x_at((c+1)/8, y1), y1), (x_at(c/8, y1), y1)]
        light = (r + c) % 2 == 0
        fill = LIGHT if light else DARK
        out.append('<polygon points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in pts) + f'" fill="{fill}"/>')
# blaue Brettkante vorne/hinten wie die Wellen im Logo
out.append(f'<line x1="{back_l}" y1="{back_y}" x2="{back_r}" y2="{back_y}" stroke="#4169e1" stroke-width="2"/>')
out.append(f'<rect width="{W}" height="{H}" fill="url(#depth)"/>')
out.append(f'<rect width="{W}" height="{H}" fill="url(#fade)"/>')
out.append('</svg>')
open(sys.argv[1], "w").write("\n".join(out))
