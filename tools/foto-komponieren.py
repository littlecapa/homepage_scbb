# Freigestellte PNGs (tools/foto-freistellen.swift) auf weichen Hintergrund setzen, 1200x1500 JPG.
import sys
from PIL import Image, ImageFilter, ImageDraw
W, H = 1200, 1500
def bg():
    # weicher Verlauf: oben fast weiß, unten helles Vereinsblau, radial aufgehellt
    top, bot = (250, 251, 254), (221, 230, 246)
    g = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / (H - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    g = g.resize((W, H))
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W*0.1, H*0.08, W*0.9, H*0.78), fill=150)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    return Image.composite(Image.new("RGB", (W, H), (255, 255, 255)), g, glow)
def mach(src, out):
    im = Image.open(src).convert("RGBA")
    a = im.split()[3].point(lambda v: 255 if v > 200 else (0 if v < 30 else v))
    im.putalpha(a)
    im = im.crop(a.getbbox())
    s = min(W * 0.86 / im.width, H * 0.86 / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x = (W - im.width) // 2
    y = (H - im.height) // 2 - 10
    c = bg()
    # Schatten: weich, leicht nach unten versetzt
    sh = Image.new("L", (W, H), 0)
    sh.paste(im.split()[3].point(lambda v: v * 0.35), (x + 14, y + 26))
    sh = sh.filter(ImageFilter.GaussianBlur(28))
    c = Image.composite(Image.new("RGB", (W, H), (40, 55, 90)), c, sh)
    c.paste(im, (x, y), im)
    c.save(out, quality=88, optimize=True, progressive=True)
# Aufruf: python3 tools/foto-komponieren.py frei.png ausgabe.jpg
mach(sys.argv[1], sys.argv[2])
