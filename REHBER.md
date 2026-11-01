# OCEAN GUARDIAN – COP31 | Kurulum ve Görsel Rehberi

## 1) Godot'ta açmak (5 dakika)

1. https://godotengine.org/download adresinden **Godot 4.3 veya üstünü** indir. Standart sürüm yeterli (".NET" sürümü gerekmez). Kurulum yok, zip'ten çıkan exe'yi çalıştır.
2. Bu zip'i bir klasöre **çıkar** (zip'in içinden açma, mutlaka çıkar).
3. Godot açılınca **Import** (İçe Aktar) → **Browse** → çıkardığın klasördeki `project.godot` dosyasını seç → **Import & Edit**.
4. Sağ üstteki **▶ (F5)** tuşuna bas. Oyun açılır. Hiç görsel eklemesen de oynanır (şekiller kodla çiziliyor).

## 2) Oyun nasıl çalışıyor

| Tuş | Ne yapar |
|---|---|
| Ok tuşları / A-D | Tekneyi sağa-sola oynatır |
| Sol tık / F | **ÇÖP KANCASI**: atar / geri çeker. Sadece çöp ve ağa dolanmış kaplumbağa tutar (Güçlü Olta Sv.3'te 1. çöpten sonra devam edip 2. çöpü de alabilirsin) |
| Sağ tık / G | **BALIK OLTASI**: atar / geri çeker. Sadece balık tutar. **Deniz %50 temizlenip kahveden maviye dönünce açılır**, o zamana kadar kilitlidir. Yem sadece bu oltada harcanır |
| Boşluk | 2 şişe/teneke → 2 yem |
| E | İskeleye yakınken (tekne sola) lastik → dişli, ağ → tahta |
| 1 / 2 | Olta hızı (2 dişli) / mıknatıs yarıçapı (2 tahta) yükseltmesi |
| 3 / 4 | **Güçlü Olta** / **Tekne Motoru** yükseltmesi (PARA ile, 3 seviye) |
| B / S | Balık tartısında: **B** = denize bırak, **S** = sat (yeşil bölgedeyse) |
| Boşluk / F | Kaplumbağa mini oyununda: ağı kes |
| Enter / Boşluk | Menüde ve seviye kartlarında ilerle |
| R / M | Kaybedince seviyeyi tekrar dene / menüye dön |
| **ESC** veya sağ alttaki **dişli** butonu | Duraklat menüsünü açar / kapatır (oyun donar) |
| F11 | Tam ekran aç/kapat |

**İki olta, iki tuş (v9):** Çöp Kancası (Sol tık / F) ile çöp ve kaplumbağa, Balık Oltası (Sağ tık / G) ile balık tutulur. Olta suda iken diğer tuş çalışmaz, önce oltayı çekmen gerekir. Balık oltası **kilitli** başlar: deniz yeterince temizlenince (varsayılan %50, `FISH_UNLOCK_CLEAN`) ekranda "BALIK TUTMA AÇILDI!" yazısı çıkar. Eko-puan çubuğundaki **BALIK** işareti açılma eşiğini gösterir (sarı = kilitli, yeşil = açık). Kilitliyken alttaki panel şu anki temizlik yüzdesini gösterir. Seviye başında kilit, denizin o anki temizliğine göre yeniden hesaplanır (Seviye 1-2 başı kilitli, Seviye 3 başı açık).

**Balık boyu ölçümü (mini ekran):** Oltaya balık takılınca oyun durur ve balığın boyu cetvelle ölçülür. Cetvelin **yeşil bölgesi (25 - 40 cm) satılabilir boydur**, korunan boyda cetvel **kırmızı** olur, dışı (yavru ya da çok büyük balık) korunur:
- Yeşil bölgedeki balığı **S** ile satarsın: boy (cm) × 1.36 para. İstersen yine de bırakabilirsin (+2 puan).
- Yeşil bölgenin dışındaki balığı **B** ile denize bırakırsan +15 puan ve "Korunan balığı bırak" görevi ilerler. Bunu **S** ile satarsan ceza (-20 puan) alırsın.
- Para ile **Güçlü Olta** (40 / 80 / 140 para) ve **Tekne Motoru** (30 / 60 / 100 para) yükseltilir. Güçlü Olta ayrıca balığı çekme/yem menzilini artırır. **Sv.3 = ÇİFT KANCA: tek atışta 2 çöp taşınır.** Tekne Motoru tekne hızını artırır.
- Yem (şişe/teneke ile) hâlâ balıkları oltaya çeker; yemsiz de balık tutulabilir ama şans ister.

**Kaplumbağa mini oyunu:** Ağa dolanmış kaplumbağaya olta değince ağı kesme mini oyunu açılır: imleç gidip gelir, **yeşil bölgedeyken Boşluk/F** ile kes. 3 doğru kesik kaplumbağayı kurtarır (+50). Kaçırırsan süre 1.5 sn azalır, 10 sn dolarsa kurtaramazsın (4 sn sonra tekrar deneyebilirsin). Mini oyun sırasında seviye süresi durur.

**Seviyeler:** 3 seviye var. Her seviyenin kendi **süresi ve görevleri** var (çöp topla, kaplumbağa kurtar, korunan balığı bırak). Görevleri süre bitmeden tamamlarsan seviye geçilir:
- Kalan saniye × 2 kadar **süre bonusu** alırsın.
- Bir **"Biliyor muydun?" okyanus bilgisi** çıkar.
- Süre bitip görevler eksikse seviye başarısız olur, **R** ile o seviyeyi tekrar denersin (envanterin seviye başındaki haline döner).

**Deniz rengi:** Oyun **çamurlu, kahverengi kirli deniz** ve griye boyalı gökyüzüyle başlar. Her görev ve her seviyeyle su yavaşça **berrak maviye** döner, 3. seviyeyi bitirince tertemiz olur. Sağ üstte "Deniz %" olarak görünür.

Puanlar: şişe 10, teneke 10, lastik 20, ağ 25, kaplumbağa 50, korunan balığı bırakmak 15.

### Seviyeleri değiştirmek (`main.gd` en üstü, `LEVELS`)
```gdscript
{
    "name": "Kıyı Temizliği", "time": 70.0,
    "collect": 6, "rescue": 1, "release": 0,
    "fact": "Okyanus bilgisi buraya..."
},
```
- `time`: o seviyenin süresi (saniye). Süreden emin değilsen bu sayıları oynat, oyun testinde en rahat ayar budur.
- `collect` / `rescue` / `release`: görev sayıları. 0 yaparsan o görev listede çıkmaz.
- Yeni seviye eklemek için bir `{ ... },` bloğu daha yaz. Deniz temizliği seviye sayısına göre kendiliğinden dağılır.
- Bilgi metni yaklaşık 3-4 satır (180-200 karakter) olursa ekrana sığar.

## 2b) Menüler

- **Ana menü**: BAŞLA / NASIL OYNANIR? / AYARLAR. Fareyle üstüne gel + tıkla, ya da yukarı-aşağı tuşları + Enter.
- **Nasıl oynanır**: görsel ekran. ESC veya MENÜYE DÖN ile geri dönülür. Duraklat menüsünden açılırsa oyuna geri döner.
- **Ayarlar**: tek ses kaydırıcısı (fareyle sürükle, hoparlör ikonlarına tıkla ya da sol-sağ tuşları), SES AÇIK / SESSİZ butonları, TAM EKRAN / PENCERE MODU butonları. Aktif seçenek altın çerçeveli, pasif olan koyu görünür. Değerler kaydedilir.
- **Oyun içi menü**: ESC veya sağ alttaki dişli → **DEVAM ET / NASIL OYNANIR? / AYARLAR / ANA MENÜ**. Menü açıkken süre, balıklar ve olta donar.
- **Yem şart**: Balık Oltası (Sağ tık / G) yemsiz atılamaz ve yemsiz balık tutulmaz. Önce Boşluk ile yem yap (2 şişe/teneke = 2 yem).

Menü görselini değiştirirsen butonların yeri `main.gd` en üstündeki `MENU_PLAY`, `MENU_HELP`, `MENU_SET`, `HELP_BACK` sabitleriyle ayarlanır. Orijinal tasarım dosyaların `tasarim/` klasöründe saklı.

## 3) GÖRSELLERİ NEREYE KOYACAKSIN

**Kural: PNG dosyasını `assets/` klasörüne, aşağıdaki isimle koy. Başka hiçbir şey yapma, kod değiştirme.**
Dosya yoksa oyun o şeyi kodla çizer, yani görselleri tek tek, istediğin sırayla ekleyebilirsin.

Nasıl koyarsın: Windows'ta proje klasöründeki `assets` klasörüne dosyayı kopyala. Godot açıksa pencereye geri dönünce otomatik içe aktarır. Sonra F5.
(Alternatif: dosyayı Godot'un sol altındaki **FileSystem** panelinde `assets` klasörünün üstüne sürükle.)

| Dosya adı | Boyut (px) | Açıklama |
|---|---|---|
| `background.png` | 1280×720 | (İsteğe bağlı; varsa gökyüzü + sea.png'nin yerine geçer.) **Temiz, mavi** gökyüzü + deniz + deniz tabanı (çamur ve gri hava efektini oyun kodla üstüne ekler, sen kirli versiyon çizme). **Su yüzeyi y=300, deniz tabanı y=650** çizgisinde olsun. İçinde iskele, tekne, çöp, balık OLMASIN. |
| `sea.png` | 1280×449 | **Deniz (su gövdesi).** Dalgalı üst kenarı ve üstü şeffaf PNG. Ekranda sol-üst köşesi **(0, 290)** konumunda durur (`SEA_Y`), dalga ortalaması su yüzeyi y=300 çizgisine denk gelir, alt kısım ekran dışına taşar. Orijinal tasarım dosyan `tasarim/yu.jpeg`. **Kirli deniz çizilmez**: kirlilik (kahverengi çamur) bu temiz görselin üstüne kodla bindirilir, dalga tepeleri de kirlenir. Çamur rengi / yoğunluğu: `MUD_COLOR`, `MUD_ALPHA`. Dosya silinirse kodla çizilen eski deniz kullanılır. |
| `pier.png` | 360×560 | İskele + dönüşüm makinesi + tabeladan oluşan tek parça. Sol-üst köşesi ekranda **(0,125)** (eskiden 100: istasyon biraz aşağı indi). **Güverte üst yüzeyi resimde y=115'te, güverte alt kenarı y=175'te (su yüzeyi)** olsun, ayaklar alt kenara kadar insin. Makine x=230–335 arasında olsun (E yazısı oraya çıkar). |
| `boat.png` | 300×170 | Balıkçı teknesi + balıkçı, olta kamışı dahil. Alt kenar su çizgisine oturur. **Olta ucu resimde (50, 88) noktasında** olsun (kamış sola uzansın). |
| `bottle.png` | ~21×58 | Plastik su şişesi |
| `cam_sise.png` | ~21×56 | Cam şişe (şişe türünün %40'ı bu görünümle çıkar, puan/yem aynı) |
| `can.png` | ~27×50 | Teneke |
| `poset.png` | ~35×54 | Plastik poşet (teneke türünün %40'ı bu görünümle çıkar, puan/yem aynı) |
| `tire.png` | 58×58 | Lastik |
| `net.png` | 65×68 | Balık ağı parçası |
| `fish.png` | 96×48 | **Sağa bakan** balık. **Açık gri / beyaz çiz**: oyun her balığı rastgele renge boyar. Koyu renk çizersen çok kararır. |
| `turtle_net.png` | 150×110 | **Sağa bakan** ağa dolanmış kaplumbağa (ağ üstünde) |
| `turtle_free.png` | 130×90 | **Sağa bakan** serbest kaplumbağa |
| `hook.png` | 24×32 | Olta iğnesi. **Üst-orta nokta** ip bağlanan yer. |
| `gear.png` | 32×32 | Dişli ikonu (arayüz) |
| `plank.png` | 32×32 | Tahta ikonu (arayüz) |
| `bait.png` | 32×32 | Yem ikonu (arayüz ve oltada görünür) |
| `coin.png` | 32×32 | İsteğe bağlı: para ikonu (arayüz). Yoksa kodla altın daire çizilir. |
| `menu_main.png` | 1280×720 | **Ana menü.** Senin `anamenu` tasarımın (1280×720'e oturtuldu). Butonlar (BAŞLA, NASIL OYNANIR?, AYARLAR) görselin üstünde tıklanır alanlardır. "En yüksek skorunuz" yazısını oyun kendisi çizer, görselde boş bırakıldı. |
| `menu_help.png` | 1280×720 | **Nasıl oynanır ekranı.** Senin tasarımın; oyunla uyuşmayan yazılar (yem kuralı, yükseltme tuşları) düzeltildi. "MENÜYE DÖN" tıklanır. |
| `menu_settings.png` | 1280×720 | **Ayarlar ekranı.** Senin tasarımın (1280×720'e oturtuldu, kaydırıcı çubuğu ve topuzu çıkarıldı, onları kod çizer). Tıklanır alanlar `main.gd` içinde `SET_*` sabitleridir. |
| `intro_panel.png` | 621×595 | **Seviye başlangıç kartı** çerçevesi (sarı çerçeve, mercan süsler, BAŞLA butonu). Seviye adı, görevler, süre ve ipucu yazıları kodla çizilir (`draw_intro`). |
| `done_panel.png` | 617×590 | **Seviye tamamlandı kartı** çerçevesi (DEVAM butonu dahil). Başlık, süre bonusu, deniz temizliği ve "Biliyor muydun?" yazıları kodla çizilir (`draw_level_done`). |
| `win_panel.png` | 823×691 | **Tebrikler (oyun sonu) kartı**: mercanlı çerçeve + TEKRAR OYNA / MENÜ butonları (şeffaf PNG). Yazılar kodla çizilir (`draw_win`), butonların tıklama alanları `WIN_BTN_AGAIN` / `WIN_BTN_MENU`. |
| `pause_panel.png` | 700×579 | **Duraklat menüsü** (ESC / dişli): çerçeve, başlık ve 4 hazır buton. Tıklama alanları `PAUSE_BTNS` sabitindedir. |
| `intro_shell_blue.png`, `intro_shell_pink.png`, `intro_bin.png`, `intro_turtle.png` | ~40×40 | Seviye kartındaki görev satırı simgeleri (şeffaf PNG). |
| `menu_frame.png` | 1280×720 | Eski ayarlar çerçevesi. Artık kullanılmıyor, silebilirsin. |
| `title.png` | 1280×720 | İsteğe bağlı: menü ekranı (menü kirli deniz görünümüyle açılır). Varsa menüdeki yazı panelinin yerine bu çıkar (yazıyı resmin içine sen çizeceksin). |
| `font.ttf` | – | İsteğe bağlı: kendi fontun (Türkçe karakterleri desteklemeli: ğ ş ı İ ç ö ü) |

Önemli: **Arka plan şeffaf (PNG, alpha)** olmalı: bottle, can, tire, net, fish, turtle, hook, gear, plank, bait, boat, pier. Sadece `background.png` ve `title.png` tam dolu olur.

### Şablon klasörü (`sablon/`)
Her dosyanın doğru boyutta, kılavuz çizgili boş şablonu `sablon/` içinde. Kullanımı:
1. Şablonu çizim programında aç, **üstüne yeni katmanda çiz**, kılavuz katmanını gizle/sil.
2. Şeffaf PNG olarak dışa aktar, aynı isimle `assets/` içine koy.
3. Şablonun kendisini `assets/` içine **kopyalama** (kırmızı çerçeveli haliyle oyunda görünür).

### Hangi programla çizersin?
- **Piskel** (piskelapp.com): tarayıcıda, ücretsiz, pixel-art için en kolay.
- **Krita** (ücretsiz) veya **GIMP**: elle çizim / vektör gibi düz çizim.
- **Photopea.com**: tarayıcıda Photoshop gibi, arka plan silme ve boyut ayarı için iyi.
- **Yapay zekâ ile görsel üretip** arka planını silmek de olur (remove.bg veya Photopea'da "arka plan sil"). Sonra boyutu yukarıdaki tabloya göre küçült. Üretirken "sağa bakan, düz arka plan, tek nesne" iste.
- **Hazır görsel**: kenney.nl (CC0, serbest), opengameart.org, itch.io ücretsiz asset paketleri. Lisansı kontrol et, yarışma/sunumda kaynağı yaz.

### Pixel-art çiziyorsan
`main.gd` dosyasının en üstünde `const PIXEL_ART := false` satırını `true` yap. Yoksa küçük görseller bulanık görünür. Pixel-art için küçük çiz (örn. balığı 48×24 çiz), sonra 2 kat büyütüp tablodaki boyuta getir (Nearest Neighbor ile).

### Görsel yerine oturmazsa (ince ayar)
`main.gd` en üstündeki sabitler:
- Olta teknenin yanlış yerinden çıkıyor → `ROD_TIP_OFFSET` (x, y). x sola (negatif) = kamışın ucu. Resimdeki olta ucu noktası = (X, Y) ise: `Vector2(X − 150, Y − 162)` yaz (300×170 tekne için).
- Üst denizin (teknenin durduğu su şeridi) başladığı yer: `HORIZON_Y` (240 = iskele güvertesinin üst yüzü; 200 yaparsan eski yüksek ufka döner). Üst deniz de kirlenir ve temizlendikçe açılır: kirli aralıkta su altıyla **tamamen aynı renktir** (`SURFACE_MUD_MATCH` = 1.0; 0.7 yaparsan bir tık açık kirli olur), deniz neredeyse temizlenince (`SURFACE_CLEAR_AT`, 0.4) açık maviye döner. Su altı çamuru: `MUD_COLOR`, `MUD_ALPHA`.
- Tekne suya fazla gömülü/havada → `BOAT_SINK` değerini değiştir.
- İskele kaymış → `PIER_POS`. Üstteki çöp/kaynak paneli yüksekliği → `HUD_RAISE`.
- Balık tutmanın açılacağı deniz temizliği: `FISH_UNLOCK_CLEAN` (0.5 = %50; 0.3 yaparsan Seviye 1'de açılır, 0.7 yaparsan Seviye 3'e kadar kilitli kalır).
- Balık tartısı ve para ayarları (korunan boy aralığı, fiyat, yükseltme fiyatları): `SELL_MIN`, `SELL_MAX`, `PRICE_PER_CM`, `ROD_COST`, `BOAT_COST`. Kaplumbağa mini oyun zorluğu: `RESCUE_NEED`.
- Sürelere ve zorluğa: `GAME_TIME`.

## 4) Ses ve müzik (isteğe bağlı)

Dosyaları `assets/sfx/` içine koy (`.wav`, `.ogg` veya `.mp3`), isimler:

| Dosya | Ne zaman çalar |
|---|---|
| `start` | Oyun başlayınca |
| `cast` | Olta atılınca |
| `collect` | Çöp oltaya takılınca |
| `craft` | Yem yapılınca / dönüştürünce |
| `rescue` | Kaplumbağa kurtarılınca |
| `fish` | Balık işaretlenince |
| `upgrade` | Yükseltme alınınca |
| `error` | "Malzeme yok" uyarısı |
| `click` | Menü butonu tıklanınca / seçilince |
| `end` | Süre bitip seviye başarısız olunca |
| `level` | Seviye tamamlanınca |
| `win` | Tüm seviyeler bitince (final) |
| `music` | Arka plan müziği (otomatik döngü) |

Ses üretmek için: **sfxr.me** (tarayıcıda, tek tıkla 8-bit ses, WAV indir), pixabay.com (ses ve müzik, ücretsiz), freesound.org (lisansa dikkat).

## 5) Oyunu başkasına vermek / yayınlamak

1. Godot'ta **Editor → Manage Export Templates → Download and Install** (bir kere).
2. **Project → Export → Add…**
   - **Web**: itch.io'ya yükleyip tarayıcıdan oynatabilirsin (en kolay sunum yolu). Çıkan klasörü zip'le, itch.io'da "HTML5" olarak yükle.
   - **Windows Desktop**: exe üretir.
3. **Export Project** de.

## 6) Kod haritası (`main.gd`)

| Bölüm | Ne var |
|---|---|
| `AYARLAR` | Boyutlar, süre, görsel ayarları |
| `LEVELS` | Seviye süresi, görevleri ve okyanus bilgileri |
| `begin_level`, `complete_level`, `dirt_target` | Seviye akışı ve su kirliliği hesabı |
| `spawn_*` | Çöp, balık, kaplumbağa üretimi (oranlar `spawn_item` içinde) |
| `_unhandled_input` | Tuşlar |
| `craft_bait`, `recycle`, `upgrade` | Dönüşüm ve yükseltmeler (1-4) |
| `start_weigh`, `weigh_decide`, `draw_weigh` | Balık tartısı mini ekranı |
| `start_rescue`, `rescue_press`, `draw_rescue` | Kaplumbağa kurtarma mini oyunu |
| `check_hook` | Olta neye çarptı, puanlar |
| `draw_*` | Çizimler (görsel varsa kullanır, yoksa şekil çizer) |
| `draw_menu`, `draw_end_screen` | Menü ve bitiş ekranı metinleri |

## 7) 2 günlük öneri plan

**Gün 1**: Godot'u aç, oyunu oyna, `LEVELS` içindeki süre ve görev sayılarını beğenene kadar ayarla. Görselleri önem sırasına göre ekle: `background` → `boat` → `fish` → `turtle_net`/`turtle_free` → çöpler → `pier` → ikonlar. Her görselden sonra F5 ile kontrol et.
**Gün 2**: Sesler, menü resmi, Web export, itch.io'ya yükle, sunum ekran görüntüleri. Zaman kalırsa: yeni çöp/canlı (yengeç, denizanası) ve metinleri COP31 mesajlarıyla zenginleştir.

## Sorun giderme
- **Görsel görünmüyor**: Dosya adı birebir aynı mı (küçük harf, `.png`)? `assets/` içinde mi (`sablon/` değil)? Godot'a geri dön, bir saniye bekle, tekrar F5.
- **Bulanık görsel**: `PIXEL_ART := true`.
- **Balıklar çok koyu**: `fish.png` açık renk olmalı.
- **Kaplumbağa/balık ters bakıyor**: Görsel sağa bakmalı.
- **Türkçe karakter bozuk**: Özel font kullanıyorsan Türkçe destekleyen font seç.
