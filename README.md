# Ocean Guardian - COP31 (Godot 4.3+)

Tüm anlatım için **REHBER.md** dosyasını oku.

Hızlı başlangıç: Godot 4.3+ aç -> Import -> bu klasördeki `project.godot` -> F5.
3 seviye var: her seviyede süre + görevler, deniz çamurludan maviye döner. Ayarlar: `LEVELS` (main.gd en üstü).
Görsellerini `assets/` klasörüne koy, oyun otomatik kullanır. Boyutlar için `sablon/` klasörüne bak.


v5 yenilikleri: balık tartısı (koruma aralığı + satış + para), para ile Güçlü Olta / Tekne Motoru (Sv.3 çift kanca), kaplumbağa kesme mini oyunu, iskele biraz aşağı / üst panel biraz yukarı. Ayrıntı: REHBER.md.
v6: sol tık = olta at/çek, tartıda yeşil bölge = satılabilir (25-40 cm), dışı = denize bırak.
v7: balık sayısı seviyeye göre artar (fish_target: 3/5/7), çöpler dibe batmaz, tüm derinliklere rastgele dağılır.
v8: seviye bilgisi ("Biliyor muydun?") ekranı artık tıklama/tuşla anında geçilmez (kısa bekleme).
v9: iki ayrı olta: Sol tık / F = Çöp Kancası (çöp + kaplumbağa), Sağ tık / G = Balık Oltası (sadece balık). Balık tutma kilitli başlar, deniz %50 temizlenip kahveden maviye dönünce açılır (FISH_UNLOCK_CLEAN). Açılınca bildirim, eko çubuğunda eşik işareti, kilitliyken alt panelde uyarı.

v10: Ana menü + Nasıl oynanır + Ayarlar (senin menü görsellerinle), ESC / dişli ile Duraklat menüsü (Devam et, Nasıl oynanır, Ayarlar, Ana menü), ses ve tam ekran ayarı (kaydedilir), YEMSİZ BALIK TUTMA YOK (Sağ tık / G yem ister), üst panelde ilk kutunun yukarı kaymasını düzelttim.

v24: Coastal_Drift müziği eklendi (assets/sfx/music.mp3, ses/sessiz ayarı geçerli). Tekne sağ uca varınca döner (kamış sağa uzanır), sol uca varınca geri döner: sağ kenardaki çöp/balığa ulaşılır.
v25: tekne dönünce bildirim yazısı kaldırıldı.
v26: yeni gökyüzü görseli (assets/sky.png, 1280x200). Dosya silinirse kodla çizilen eski gökyüzü kullanılır.
v27: yeni deniz görseli (assets/sea.png, senin yu.jpeg tasarımından: gerçek şeffaf dalga kenarı). Kirli deniz ayrıca çizilmedi: kirlilik temiz denizin üstüne kodla kahverengi çamur olarak bindirilir (MUD_COLOR / MUD_ALPHA), dalga tepeleri de kirlenir. Derin kısımda sert çizgi yerine yumuşak koyulaşma, su altında yavaş kayan ışık çizgileri. Dosya silinirse eski kodla çizilen deniz kullanılır.
v28: üst deniz (su yüzeyi şeridi) artık iskele güvertesinin hizasında başlıyor (HORIZON_Y=240) ve o da kirlenip temizleniyor; su altından bir tık açık kirli (SURFACE_MUD_TOP / SURFACE_MUD_NEAR). Gökyüzü alt satırı ufka kadar uzatıldı.
v29: üst deniz artık su altıyla TAMAMEN AYNI renge kirleniyor (alfa değil sonuç rengi eşitlendi, sapma en fazla 2 renk birimi) ve temizlendikçe birlikte açılıyor; deniz neredeyse temizken (dirt<0.4) şerit açık maviye dönüyor. Duman katmanı yalnızca gökyüzünde. Ayar: SURFACE_MUD_MATCH, SURFACE_CLEAR_AT.

v30: ufuk düzeltildi. Gökyüzü ve deniz tek çizgide birleşir, bu çizgi teknenin alt kenarıdır (HORIZON_Y = SURF). Üst deniz şeridi kaldırıldı. Tekne 17 px aşağı indi (BOAT_SINK 25, ROD_TIP_OFFSET.y -70), sky.png alt kenarı ufka oturur.

v31: kirli suda su yüzeyindeki parlak köpük çizgisi örtüldü (sea.png kenarı ikinci kez çamurla bindirilir); deniz temizlenince köpük geri gelir.

v32: gökyüzü-deniz arasındaki parlak ince çizgi kaldırıldı. sea.png köpük kenarı yumuşatıldı (soften_sea_edge) ve gökyüzünün alt 70 px kısmı su rengine gradyanla geçer (HORIZON_FADE, draw_horizon_blend). Kirli ve temiz suda ayrı ayrı çalışır.

v33: yeni gökyüzü (guy0.jpeg): beyaz kenarlar kırpıldı, güneş + bulut bandı sky.png olarak 1280x230 boyutuna sığdırıldı. Alt kenarı ufka oturur, üstteki boşluğu görselin üst satırı doldurur. Orijinal: tasarim/gokyuzu_orijinal.jpeg
