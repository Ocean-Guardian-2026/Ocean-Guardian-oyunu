"""Duraklat çerçevesinden (pause_panel.png) diğer paneller için aynı tasarımda çerçeve üretir.
Kullanım:  python3 gen_panels.py <assets klasörü>
Çıktı: intro_panel.png, done_panel.png, over_panel.png
"""
import sys, os
from PIL import Image
import numpy as np

assets = sys.argv[1] if len(sys.argv) > 1 else "."
src = Image.open(os.path.join(assets, "pause_panel.png")).convert("RGBA")
SW, SH = src.size            # 700 x 579

TOP = 152                    # üst blok (kıvrım + başlık bandı + iç panelin üst kenarı)
BOT = 87                     # alt şerit yüksekliği (pause'da y=492..579)
CORN_W = 130                 # köşe blokları genişliği
LEFT_W = 60                  # sol/sağ kenar şeridi genişliği

def crop(box): return src.crop(box)

# --- parçalar
tl = crop((0, 0, CORN_W, TOP))
tr = crop((SW - CORN_W, 0, SW, TOP))
bl = crop((0, SH - 97, CORN_W, SH))
br = crop((SW - CORN_W, SH - 97, SW, SH))
top_strip = crop((160, 0, 161, TOP)).resize((50, TOP), Image.NEAREST)   # yazısız tek sütun -> dikişsiz üst şerit
bot_strip = crop((250, SH - BOT, 251, SH)).resize((50, BOT), Image.NEAREST)   # alt şerit (tek sütun)
left_strip = crop((0, 200, LEFT_W, 300))             # sol kenar (dikey tekrar)
right_strip = crop((SW - LEFT_W, 200, SW, 300))

# iç panel dolgusu: butonların solundaki temiz alandan satır satır renk (hafif degrade korunur)
arr = np.array(src)
fill_rows = arr[:, 70:170, :3].mean(axis=1)          # (SH,3)
def fill_color(frac):                                 # frac 0..1 : iç panel boyunca
    y = int(TOP + 4 + frac * (SH - BOT - TOP - 10))
    return tuple(int(v) for v in fill_rows[y])

# --- buton (AYARLAR butonundan: yazısız orta kısım yatay uzatılır)
BX0, BX1, BY0, BY1 = 180, 520, 330, 402
def make_button(bw, bh=None, glow=False):
    cap = 46
    btn = src.crop((BX0, BY0, BX1, BY1))
    h = btn.height
    left = btn.crop((0, 0, cap, h))
    right = btn.crop((btn.width - cap, 0, btn.width, h))
    mid_col = btn.crop((60, 0, 61, h))   # yazısız sütun
    out = Image.new("RGBA", (bw, h), (0, 0, 0, 0))
    out.paste(mid_col.resize((bw - 2 * cap, h), Image.NEAREST), (cap, 0))
    out.paste(left, (0, 0)); out.paste(right, (bw - cap, 0))
    return out

def tile_h(strip, width):
    out = Image.new("RGBA", (width, strip.height), (0, 0, 0, 0))
    x = 0
    while x < width:
        out.paste(strip, (x, 0)); x += strip.width
    return out

def tile_v(strip, height):
    out = Image.new("RGBA", (strip.width, height), (0, 0, 0, 0))
    y = 0
    while y < height:
        out.paste(strip, (0, y)); y += strip.height
    return out

def build(W, H, buttons=(), name="x", title_band_clean=True):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # üst şerit (orta)
    img.alpha_composite(tile_h(top_strip, W - 2 * CORN_W + 50).crop((0, 0, W - 2 * CORN_W, TOP)), (CORN_W, 0))
    # orta bölüm: iç panel dolgusu + kenarlar
    mid_h = H - TOP - BOT
    mid = Image.new("RGBA", (W, mid_h), (0, 0, 0, 0))
    px = mid.load()
    inner_l, inner_r = 48, W - 48
    for y in range(mid_h):
        c = fill_color(y / max(mid_h, 1))
        for x in range(inner_l, inner_r):
            px[x, y] = (*c, 255)
    mid.alpha_composite(tile_v(left_strip, mid_h), (0, 0))
    mid.alpha_composite(tile_v(right_strip, mid_h), (W - LEFT_W, 0))
    img.alpha_composite(mid, (0, TOP))
    # alt şerit
    img.alpha_composite(tile_h(bot_strip, W).crop((0, 0, W - 2 * CORN_W, BOT)), (CORN_W, H - BOT))
    # köşeler (en üstte)
    img.alpha_composite(tl, (0, 0)); img.alpha_composite(tr, (W - CORN_W, 0))
    img.alpha_composite(bl, (0, H - 97)); img.alpha_composite(br, (W - CORN_W, H - 97))
    # butonlar: (x, y, w) panel koordinatı
    for (bx, by, bw) in buttons:
        img.alpha_composite(make_button(bw), (bx, by))
    img.save(os.path.join(assets, name + ".png"))
    print(name, img.size)

BH = BY1 - BY0   # buton yüksekliği (72)

# Panel boyutları ve butonları (kod tarafındaki sabitlerle uyumlu olmalı)
build(720, 640, [((720 - 280) // 2, 640 - 72 - BH - 22, 280)], "intro_panel")      # BAŞLA
build(720, 640, [((720 - 280) // 2, 640 - 72 - BH - 22, 280)], "done_panel")       # DEVAM
build(760, 640, [((760 - 440) // 2, 640 - 72 - BH - 22, 440)], "over_panel")       # SEVİYEYİ TEKRAR DENE
