"""Ana menü / Ayarlar / Nasıl Oynanır görsellerini duraklat çerçevesine (mercanlı turkuaz çerçeve,
yunus + balık süsü, koyu lacivert zemin) dönüştürür. İçerik (yazı, buton, ikon) olduğu gibi korunur,
bu yüzden butonların tıklama alanları değişmez.
Kullanım:  python3 gen_menus.py <orijinal assets klasörü> <çıktı klasörü>
"""
import sys, os
from PIL import Image
import numpy as np

src_dir, out_dir = sys.argv[1], sys.argv[2]
NAVY = (11, 28, 49)
pause = Image.open(os.path.join(src_dir, "pause_panel.png")).convert("RGBA")
SW, SH = pause.size
TOP, CW = 140, 130

def crop(b): return pause.crop(b)

def clean_blue(img, max_row):
    """İç panelin mavi dolgu/kenar piksellerini lacivertle değiştirir (mercan renklerine dokunmaz)."""
    a = np.array(img)
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    m = (b > g + 8) & (r < 75) & (a[..., 3] > 0)
    m[max_row:, :] = False
    a[m, :3] = NAVY
    return Image.fromarray(a)

tl, tr = crop((0, 0, CW, TOP)), crop((SW - CW, 0, SW, TOP))
bl = clean_blue(crop((0, SH - 97, CW, SH)), 32)
br = clean_blue(crop((SW - CW, SH - 97, SW, SH)), 32)
top_strip = crop((160, 0, 161, TOP)).resize((50, TOP), Image.NEAREST)
bot = crop((250, SH - 87, 251, SH)).resize((50, 87), Image.NEAREST)
ba = np.array(bot); ba[:20, :, :3] = NAVY; bot_strip = Image.fromarray(ba)
LW = 44
left_strip = crop((0, 200, LW, 300)); right_strip = crop((SW - LW, 200, SW, 300))

def tile(strip, n, horiz=True):
    w, h = strip.size
    out = Image.new("RGBA", (n, h) if horiz else (w, n), (0, 0, 0, 0))
    p = 0
    while p < n:
        out.paste(strip, (p, 0) if horiz else (0, p)); p += w if horiz else h
    return out

def ring(W, H):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    img.alpha_composite(tile(top_strip, W - 2 * CW), (CW, 0))
    mid_h = H - TOP - 87
    mid = Image.new("RGBA", (W, mid_h), (0, 0, 0, 0))
    mid.alpha_composite(Image.new("RGBA", (W - 2 * LW, mid_h), NAVY + (255,)), (LW, 0))
    mid.alpha_composite(tile(left_strip, mid_h, False), (0, 0))
    mid.alpha_composite(tile(right_strip, mid_h, False), (W - LW, 0))
    img.alpha_composite(mid, (0, TOP))
    img.alpha_composite(tile(bot_strip, W - 2 * CW), (CW, H - 87))
    img.alpha_composite(tl, (0, 0)); img.alpha_composite(tr, (W - CW, 0))
    img.alpha_composite(bl, (0, H - 97)); img.alpha_composite(br, (W - CW, H - 97))
    return img

# ad: (yeni çerçeve kutusu x0,y0,x1,y1), (eski halka kutusu), silinecek eski yunus/balık kutuları, silinecek ek alanlar
JOBS = {
    "menu_main":     ((279, 14, 1013, 714), (295, 27, 997, 700),  [(322, 55, 420, 120), (322, 120, 378, 155), (875, 65, 970, 130)]),
    "menu_help":     ((279, 14, 1013, 714), (295, 27, 997, 700),  [(322, 55, 420, 155), (875, 65, 970, 130)]),
    "menu_settings": ((206, 14, 1082, 714), (222, 27, 1066, 700), [(250, 55, 360, 165), (930, 65, 1040, 140)]),
}
BG_KEY = np.array([9, 18, 21])

for name, (nb, ob, erase) in JOBS.items():
    old = Image.open(os.path.join(src_dir, name + ".png")).convert("RGB")
    a = np.array(old).copy()
    ox0, oy0, ox1, oy1 = ob
    # 1) eski halkayı ve parıltısını dış zeminden kopyalayarak sil
    for y in range(oy0 - 14, oy1 + 15):
        a[y, ox0 - 14:ox0 + 12] = a[y, ox0 - 22]
        a[y, ox1 - 11:ox1 + 15] = a[y, ox1 + 22]
    for x in range(ox0 - 14, ox1 + 15):
        a[oy0 - 14:oy0 + 12, x] = a[oy0 - 22, x]
        a[oy1 - 11:oy1 + 15, x] = a[min(oy1 + 22, 719), x]
    base = Image.fromarray(a).convert("RGBA")
    # 2) yeni çerçeve
    x0, y0, x1, y1 = nb
    base.alpha_composite(ring(x1 - x0, y1 - y0), (x0, y0))
    # 3) eski içerik: zemin rengi şeffaflaştırılır, eski yunus/balık silinir
    inner = np.array(old).astype(int)
    d = np.sqrt(((inner - BG_KEY) ** 2).sum(axis=2))
    alpha = np.clip((d - 14) / 30.0, 0, 1)
    mask = np.zeros(alpha.shape, bool)
    mask[oy0 + 12:oy1 - 11, ox0 + 12:ox1 - 11] = True      # sadece eski halkanın içi
    for (ex0, ey0, ex1, ey1) in erase: mask[ey0:ey1, ex0:ex1] = False
    alpha = alpha * mask
    layer = np.dstack([inner.clip(0, 255).astype(np.uint8), (alpha * 255).astype(np.uint8)])
    base.alpha_composite(Image.fromarray(layer, "RGBA"))
    base.convert("RGB").save(os.path.join(out_dir, name + ".png"))
    print(name, "ok")
