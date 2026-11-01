extends Node2D
# OCEAN GUARDIAN - COP31 demo oyunu (Godot 4.3+)
#
# Görsel ve ses dosyası YOKSA oyun kodla çizdiği basit şekilleri kullanır.
# res://assets/ klasörüne doğru isimle PNG koyarsan o görsel otomatik kullanılır.
# Dosya isimleri ve boyutları için REHBER.md'ye bak.

# ------------------------------------------------------------ AYARLAR
const W := 1280.0
const H := 720.0
const SURF := 300.0        # su yüzeyinin y konumu
const SEABED := 650.0      # deniz tabanının y konumu
const GAME_TIME := 90.0    # oyun süresi (saniye)

# DENİZ GÖRSELİ (assets/sea.png, 1280x449): su gövdesi + dalgalı üst kenar, üstü şeffaf.
# Kirli deniz ayrıca ÇİZİLMEZ: kirlilik (kahverengi çamur) bu temiz görselin üstüne kodla bindirilir.
const SEA_Y := 290.0           # sea.png üst satırının ekrandaki y konumu (dalga ortalaması SURF=300 çizgisine denk gelir)
const SEA_EDGE_ROWS := 16      # sea.png üstündeki yarı saydam (dalga) satır sayısı
const MUD_COLOR := Color(0.48, 0.33, 0.14)   # kirli denizin çamur rengi (kahverengi)
const MUD_ALPHA := 0.72                      # tam kirliyken su altı çamurunun yoğunluğu
# UFUK: gökyüzü ile deniz tek çizgide buluşur ve bu çizgi TEKNENİN ALT KENARIDIR (su çizgisi, y = SURF).
# Aradaki "üst deniz" şeridi kaldırıldı. Eski değerler: 200, sonra 240 (iskele güvertesi hizası). Şeridi geri istersen 240 yaz.
const HORIZON_Y := SURF
const HORIZON_FADE := 70.0                   # gökyüzü -> deniz geçişinin yüksekliği (px). 0 = sert çizgi, büyütürsen geçiş uzar
const SURFACE_MUD_MATCH := 1.0               # üst deniz kirliliği: 1.0 = su altıyla TAMAMEN AYNI renk, 0.7 gibi bir değer = daha açık kirli
const SURFACE_CLEAR_AT := 0.4                # kirlilik bunun altına inince üst deniz açık maviye dönmeye başlar (deniz %60 temizken)
const SEA_TOP_COLOR := Color(0.016, 0.427, 0.553)   # sea.png'nin su çizgisindeki rengi (temiz)

const PIXEL_ART := false   # pixel-art çiziyorsan true yap (bulanıklaşmayı önler)

# Tekne görseli kullanıyorsan: olta ucunun teknenin alt-orta noktasına göre yeri.
# Oltan görselde yanlış yerden çıkıyorsa BU İKİ DEĞERİ oynat.
const ROD_TIP_OFFSET := Vector2(-112.0, -70.0)   # boat.png (300x142): kamış ucu (38,47). Tekne 17 px aşağı indiği için y -87 -> -70
# Teknenin kamış ucu x yönü: tekne sağ uca varınca dönüp kamış sağa uzanır, sol uca varınca geri döner
func tip_dx() -> float:
    return -ROD_TIP_OFFSET.x if boat_flip else ROD_TIP_OFFSET.x


func hook_home_x() -> float:
    return clampf(boat_x + tip_dx(), 12.0, W - 12.0)


const BOAT_SINK := 25.0    # tekne görseli suya ne kadar gömülsün: boat.png altında 19 px şeffaf boşluk var, bu değerle teknenin KEMERİ tam su çizgisine (y=300) oturur

# İskele görselinin sol-üst köşesinin konumu
const PIER_POS := Vector2(0.0, 125.0)   # istasyon biraz aşağıda (eskiden 100)
const HUD_SCALE := 0.8     # üst HUD (çöp / kaynak / hedef / puan / süre) ölçeği: küçüldükçe gökyüzü açılır
const HUD_RAISE := 14.0    # üstteki çöp/kaynak paneli bu kadar yukarı kaydı

# BALIK BOYU ÖLÇÜMÜ: yeşil aralıktaki balıklar SATILIR, dışındakiler (yavru / çok büyük) denize BIRAKILIR
const SELL_MIN := 25.0     # cm (yeşil bölge başı)
const SELL_MAX := 40.0     # cm (yeşil bölge sonu)
const PRICE_PER_CM := 1.36 # satış fiyatı (para / cm), 28 cm = 38 para
const WEIGH_TIME := 1.6    # tartı animasyonu süresi (sn)
const RESCUE_NEED := 3     # kaplumbağa mini oyunu: kaç doğru kesik gerekir
const FISH_UNLOCK_CLEAN := 0.5   # deniz bu oranda temizlenince (0.5 = %50, kahveden maviye) BALIK TUTMA açılır
const ROD_COST := [40, 80, 140]   # Güçlü Olta Sv.1-3 (para). Sv.3 = çift kanca (2 çöp)
const BOAT_COST := [30, 60, 100]  # Tekne Motoru Sv.1-3 (para)

const ASSET_NAMES := [
    "background", "sky", "sea", "pier", "boat", "bottle", "can", "tire", "net", "cam_sise", "poset", "turtle_net_overlay", "fish_hamsi", "fish_levrek", "fish_lufer",
    "fish", "turtle_net", "turtle_free", "hook", "gear", "plank", "bait", "title", "coin",
    "menu_main", "menu_help", "menu_frame", "menu_settings",
    "intro_panel", "done_panel", "over_panel", "win_panel", "pause_panel", "intro_shell_blue", "intro_shell_pink", "intro_bin", "intro_turtle"
]
const SFX_NAMES := ["start", "cast", "collect", "craft", "rescue", "fish", "upgrade", "error", "end", "level", "win", "click"]
const SFX_EXT := ["wav", "ogg", "mp3"]

const S_MENU := 0
const S_PLAY := 1
const S_OVER := 2     # süre doldu, görevler tamamlanamadı
const S_INTRO := 3    # seviye başlangıç kartı
const S_DONE := 4     # seviye tamamlandı + okyanus bilgisi
const S_WEIGH := 6   # balık tartısı mini ekranı
const S_RESCUE := 7  # kaplumbağa kurtarma mini oyunu
const S_WIN := 5      # tüm seviyeler bitti
const S_HELP := 8      # Nasıl oynanır ekranı
const S_SETTINGS := 9  # Ayarlar ekranı
const S_PAUSE := 10    # ESC / dişli butonu ile açılan duraklatma menüsü

# Bu durumlarda sağ altta dişli butonu görünür ve ESC duraklatma menüsünü açar
const GEAR_STATES := [S_PLAY, S_WEIGH, S_RESCUE, S_INTRO, S_DONE]
const GEAR_BTN := Rect2(1208.0, 652.0, 56.0, 52.0)

# Menü görsellerindeki butonların konumu (assets/menu_main.png ve menu_help.png).
# Kendi menü görselini çizersen bu dikdörtgenleri görseline göre değiştir.
# Ana menü butonları 2x2 (menu_main.png içine çizili, hepsi 131x118)
const MENU_PLAY := Rect2(501.0, 272.0, 131.0, 118.0)
const MENU_CONT := Rect2(648.0, 272.0, 131.0, 118.0)   # 'Kaldığın yerden devam et' (kayıt yoksa sönük)
const MENU_HELP := Rect2(501.0, 404.0, 131.0, 118.0)
const MENU_SET := Rect2(648.0, 404.0, 131.0, 118.0)
const HELP_BACK := Rect2(545.0, 636.0, 200.0, 45.0)
# Ayarlar ekranı (assets/menu_settings.png): tıklanır alanlar. Kaydırıcı çubuğu ve topuzu kodla çizilir.
const SET_VOL_DN := Rect2(278.0, 258.0, 42.0, 46.0)
const SET_VOL_UP := Rect2(730.0, 258.0, 62.0, 46.0)
const SET_TRACK := Rect2(332.0, 271.0, 383.0, 20.0)
const SET_SLIDER := Rect2(325.0, 258.0, 398.0, 46.0)
const SET_UNMUTE := Rect2(809.0, 236.0, 95.0, 97.0)
const SET_MUTE := Rect2(914.0, 236.0, 96.0, 97.0)
const SET_FS := Rect2(433.0, 427.0, 200.0, 164.0)
const SET_WIN := Rect2(649.0, 427.0, 225.0, 164.0)
const SET_BACK := Rect2(533.0, 626.0, 230.0, 54.0)
const MUSIC_BASE_DB := -4.0   # müzik sesi 10/10 iken dB

# SEVİYELER: istediğin kadar ekle/çıkar. Deniz temizliği seviye sayısına göre otomatik dağılır.
# time = süre (sn), collect = çöp, rescue = kaplumbağa, release = balık (yemle işaretle). 0 = o görev yok.
const LEVELS := [
    {
        "name": "Kıyı Temizliği", "time": 70.0, "collect": 6, "rescue": 1, "release": 0,
        "fact": "Plastik şişeler denizde yüzlerce yıl bozunmadan kalabilir. Güneş ve dalgalar onları yok etmez, yalnızca mikroplastik denen minik parçalara ayırır."
    },
    {
        "name": "Derin Sular", "time": 80.0, "collect": 10, "rescue": 2, "release": 2,
        "fact": "Kaybolmuş ya da terk edilmiş balıkçı ağları yıllarca denizde kalıp kaplumbağa, balık ve yunusları yakalamaya devam eder. Kaplumbağalar plastik poşetleri denizanası sanıp yiyebilir."
    },
    {
        "name": "Mavi Gezegen", "time": 90.0, "collect": 14, "rescue": 2, "release": 3,
        "fact": "Okyanuslar, insanların saldığı karbondioksitin yaklaşık dörtte birini emer. Oksijenin yaklaşık yarısını da denizdeki mikroskobik bitkiler üretir. Okyanusu korumak iklimi korumaktır."
    },
]

# ------------------------------------------------------------ DURUM
var font: Font
var rng := RandomNumberGenerator.new()
var tex := {}
var sea_mud: ImageTexture = null   # sea.png dalga şeklinde çamur bindirmesi (yüklemede üretilir)

var state := S_MENU
var hud_xf := Transform2D.IDENTITY   # HUD ölçek+kaydırma matrisi (tüm yardımcı çizimlerle birleşir)
var hud_off := Vector2.ZERO   # HUD çizerken uygulanan kaydırma (draw_tex / draw_item sonrası korunur)
var lock := 0.0          # kart ekranlarında yanlışlıkla hızlı geçmeyi engeller (sn)
var ui_back := S_MENU        # Nasıl oynanır / Ayarlar'dan geri dönülecek ekran
var pause_prev := S_PLAY     # duraklatmadan önceki durum
var ui_focus := 0            # menüde seçili buton (klavye / fare üstü)
var volume := 7              # genel ses 0-10 (müzik + efektler)
var muted := false           # sessiz modu
var slider_drag := false     # ses kaydırıcısı sürükleniyor mu
var fullscreen := false
var time_left := GAME_TIME
var t := 0.0
var score := 0
var best := 0
var new_best := false
var collected := 0
var rescued := 0
var released := 0

var level_idx := 0
var lv_collect := 0
var lv_rescue := 0
var lv_release := 0
var dirt := 1.0          # 1 = çamurlu kirli deniz, 0 = tertemiz
var last_bonus := 0
var snap := {}
var menu_note := ""        # menüde kısa süre görünen uyarı
var menu_note_until := 0.0
var saved_prog := {}   # 'Kaldığın yerden devam et' için diske yazılan ilerleme (boşsa kayıt yok)

var boat_x := 780.0
var boat_flip := false   # true: tekne ters döndü, kamış SAĞA uzanır (sağ uçtaki balık/çöpe ulaşmak için)
var hook_state := 0   # 0 = boşta, 1 = iniyor, 2 = çekiliyor
var hook_depth := 0.0
var hook_x := 680.0
var hook_mode := 0    # 0 = Çöp Kancası (Sol tık / F), 1 = Balık Oltası (Sağ tık / G)
var fishing_open := false   # deniz yeterince temizlenince true olur
var banner_t := 0.0         # "Balık tutma açıldı" yazısının kalan süresi
var carrying: Dictionary = {}
var carrying2: Dictionary = {}   # Güçlü Olta Sv.3: ikinci çöp
var bait := 0
var bait_active := false
var inv := {"bottle": 0, "can": 0, "tire": 0, "net": 0}
var gears := 0
var planks := 0
var lvl_speed := 0
var lvl_magnet := 0
var coins := 0
var rod_lvl := 0
var boat_lvl := 0
var sold := 0

var weigh_f: Dictionary = {}
var weigh_t := 0.0
var rescue_tt: Dictionary = {}
var rescue_hits := 0
var rescue_time := 0.0
var rescue_speed := 1.0
var rescue_cursor := 0.0
var rescue_dir := 1.0
var rescue_zone_c := 0.5
var rescue_zone_w := 0.2
var rescue_flash := 0.0
var rescue_ok := true

var items: Array = []
var fish: Array = []
var turtles: Array = []
var texts: Array = []
var bubbles: Array = []
var spawn_timer := 0.0
var turtle_timer := 10.0
var fish_timer := 6.0

var sfx_streams := {}
var sfx_players: Array = []
var sfx_idx := 0
var music: AudioStreamPlayer


func _ready() -> void:
    font = ThemeDB.fallback_font
    # İstersen assets/font.ttf (veya .otf) koy, oyun o fontu kullanır (Türkçe karakter desteği olmalı)
    for fp in ["res://assets/font.ttf", "res://assets/font.otf"]:
        if ResourceLoader.exists(fp):
            font = load(fp)
            break
    rng.randomize()
    if PIXEL_ART:
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    load_assets()
    setup_audio()
    load_best()
    apply_settings()
    reset_game()


func load_assets() -> void:
    for n in ASSET_NAMES:
        var p := "res://assets/%s.png" % n
        if ResourceLoader.exists(p):
            tex[n] = load(p)
        else:
            tex[n] = null
    soften_sea_edge()
    build_sea_mud()


# sea.png'nin üst kenarındaki açık renkli köpük çizgisini kaldırır ve kenarı yumuşak bir geçişe çevirir:
# kenar satırlarının rengi su gövdesinin rengine çekilir, alfa dikey olarak bulanıklaştırılır.
# Böylece gökyüzü -> deniz geçişinde parlak ince çizgi kalmaz (kirli ve temiz suda da).
func soften_sea_edge() -> void:
    var tx: Texture2D = tex.get("sea")
    if tx == null:
        return
    var img: Image = tx.get_image()
    if img == null:
        return
    img.convert(Image.FORMAT_RGBA8)
    var w := img.get_width()
    var rows := mini(SEA_EDGE_ROWS + 6, img.get_height() - 1)
    var body_row := mini(SEA_EDGE_ROWS + 6, img.get_height() - 1)
    var src_a: Array = []
    for y in rows:
        var ra := PackedFloat32Array()
        ra.resize(w)
        for x in w:
            ra[x] = img.get_pixel(x, y).a
        src_a.append(ra)
    for x in w:
        var body := img.get_pixel(x, body_row)
        for y in rows:
            # alfa: dikey 7 satırlık ortalama (yumuşak geçiş)
            var sum := 0.0
            var cnt := 0.0
            for k in range(-3, 4):
                var yy := y + k
                if yy < 0:
                    sum += 0.0
                    cnt += 1.0
                elif yy < rows:
                    sum += float(src_a[yy][x])
                    cnt += 1.0
                else:
                    sum += 1.0
                    cnt += 1.0
            img.set_pixel(x, y, Color(body.r, body.g, body.b, sum / cnt))
    tex["sea"] = ImageTexture.create_from_image(img)


# sea.png'nin dalgalı üst kenarının şeklinde (aynı alfa) beyaz bir bindirme dokusu üretir.
# Kirlilik bu dokuyla çamur renginde bindirilir; böylece dalga tepeleri de kirlenir, şeffaf yerler boyanmaz.
func build_sea_mud() -> void:
    sea_mud = null
    var tx: Texture2D = tex.get("sea")
    if tx == null:
        return
    var src: Image = tx.get_image()
    if src == null:
        return
    src.convert(Image.FORMAT_RGBA8)
    var rows := mini(SEA_EDGE_ROWS, src.get_height())
    var mud := Image.create(src.get_width(), rows, false, Image.FORMAT_RGBA8)
    for y in rows:
        for x in src.get_width():
            mud.set_pixel(x, y, Color(1.0, 1.0, 1.0, src.get_pixel(x, y).a))
    sea_mud = ImageTexture.create_from_image(mud)


func setup_audio() -> void:
    for n in SFX_NAMES:
        for ext in SFX_EXT:
            var p := "res://assets/sfx/%s.%s" % [n, ext]
            if ResourceLoader.exists(p):
                sfx_streams[n] = load(p)
                break
    for i in 6:
        var pl := AudioStreamPlayer.new()
        add_child(pl)
        sfx_players.append(pl)
    for ext in SFX_EXT:
        var mp := "res://assets/sfx/music.%s" % ext
        if ResourceLoader.exists(mp):
            var ms = load(mp)
            if "loop" in ms:
                ms.loop = true
            elif "loop_mode" in ms:
                ms.loop_mode = AudioStreamWAV.LOOP_FORWARD
            music = AudioStreamPlayer.new()
            music.stream = ms
            music.volume_db = -8.0
            add_child(music)
            music.play()
            break


func play_sfx(n: String) -> void:
    if not sfx_streams.has(n):
        return
    var pl: AudioStreamPlayer = sfx_players[sfx_idx]
    sfx_idx = (sfx_idx + 1) % sfx_players.size()
    pl.stream = sfx_streams[n]
    pl.play()


func load_best() -> void:
    var cfg := ConfigFile.new()
    if cfg.load("user://ocean_guardian.cfg") == OK:
        best = int(cfg.get_value("skor", "best", 0))
        volume = clampi(int(cfg.get_value("ayar", "volume", cfg.get_value("ayar", "music", 7))), 0, 10)
        muted = bool(cfg.get_value("ayar", "muted", false))
        fullscreen = bool(cfg.get_value("ayar", "fullscreen", false))
        var pg = cfg.get_value("ilerleme", "data", {})
        if pg is Dictionary and pg.has("levels_done"):
            saved_prog = pg


func save_best() -> void:
    save_all()


func save_all() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("skor", "best", best)
    cfg.set_value("ayar", "volume", volume)
    cfg.set_value("ayar", "muted", muted)
    cfg.set_value("ayar", "fullscreen", fullscreen)
    cfg.set_value("ilerleme", "data", saved_prog)
    cfg.save("user://ocean_guardian.cfg")


func vol_db(v: int) -> float:
    if v <= 0:
        return -80.0
    return linear_to_db(float(v) / 10.0)


func apply_settings() -> void:
    var v := 0 if muted else volume
    if music != null:
        music.volume_db = MUSIC_BASE_DB + vol_db(v)
    for pl in sfx_players:
        pl.volume_db = vol_db(v)
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func reset_game() -> void:
    time_left = GAME_TIME
    score = 0
    new_best = false
    collected = 0
    rescued = 0
    released = 0
    level_idx = 0
    lv_collect = 0
    lv_rescue = 0
    lv_release = 0
    dirt = 1.0
    last_bonus = 0
    snap = {}
    boat_x = 780.0
    boat_flip = false
    hook_state = 0
    hook_depth = 0.0
    hook_x = hook_home_x()
    carrying = {}
    bait = 0
    bait_active = false
    hook_mode = 0
    fishing_open = false
    banner_t = 0.0
    inv = {"bottle": 0, "can": 0, "tire": 0, "net": 0}
    gears = 0
    planks = 0
    lvl_speed = 0
    lvl_magnet = 0
    carrying2 = {}
    coins = 0
    rod_lvl = 0
    boat_lvl = 0
    sold = 0
    items.clear()
    fish.clear()
    turtles.clear()
    texts.clear()
    bubbles.clear()
    for i in 16:
        spawn_item(true)
    for i in 3:
        spawn_fish(true)
    for i in 2:
        spawn_turtle()
    for i in 25:
        bubbles.append(Vector2(rng.randf_range(0, W), rng.randf_range(SURF, SEABED)))


func start_game() -> void:
    reset_game()
    begin_level()
    state = S_INTRO


func lvl() -> Dictionary:
    return LEVELS[level_idx]


# Yeni seviyeyi hazırlar (sayaçlar, süre, olta, dünya)
func begin_level() -> void:
    lock = 0.7
    lv_collect = 0
    lv_rescue = 0
    lv_release = 0
    time_left = float(lvl()["time"])
    hook_state = 0
    hook_depth = 0.0
    hook_x = hook_home_x()
    bait_active = false
    hook_mode = 0
    var start_clean := float(level_idx) / float(LEVELS.size())
    if start_clean >= FISH_UNLOCK_CLEAN - 0.0001:
        if not fishing_open:
            fishing_open = true
            banner_t = 4.0
    else:
        fishing_open = false
        banner_t = 0.0
    drop_carried()
    for i in range(turtles.size() - 1, -1, -1):
        if turtles[i]["free"]:
            turtles.remove_at(i)
    while turtles.size() < 2:
        spawn_turtle()
    while items.size() < 16:
        spawn_item(true)
    while live_fish() < fish_target():
        spawn_fish(true)
    turtle_timer = 10.0
    snap = {
        "score": score, "collected": collected, "rescued": rescued, "released": released,
        "inv": inv.duplicate(), "gears": gears, "planks": planks, "bait": bait,
        "lvl_speed": lvl_speed, "lvl_magnet": lvl_magnet,
        "coins": coins, "rod_lvl": rod_lvl, "boat_lvl": boat_lvl, "sold": sold
    }


# Başarısız seviyeyi, seviye başındaki envanterle yeniden dener
func retry_level() -> void:
    if not snap.is_empty():
        score = int(snap["score"])
        collected = int(snap["collected"])
        rescued = int(snap["rescued"])
        released = int(snap["released"])
        inv = snap["inv"].duplicate()
        gears = int(snap["gears"])
        planks = int(snap["planks"])
        bait = int(snap["bait"])
        lvl_speed = int(snap["lvl_speed"])
        lvl_magnet = int(snap["lvl_magnet"])
        coins = int(snap["coins"])
        rod_lvl = int(snap["rod_lvl"])
        boat_lvl = int(snap["boat_lvl"])
        sold = int(snap["sold"])
    begin_level()
    state = S_INTRO


# Bir seviye bitince para, puan ve yükseltmeler diske yazılır; ana menüden devam edilir.
func save_progress(levels_done: int) -> void:
    saved_prog = {
        "levels_done": levels_done, "score": score, "collected": collected, "rescued": rescued,
        "released": released, "inv": inv.duplicate(), "gears": gears, "planks": planks, "bait": bait,
        "lvl_speed": lvl_speed, "lvl_magnet": lvl_magnet,
        "coins": coins, "rod_lvl": rod_lvl, "boat_lvl": boat_lvl, "sold": sold
    }
    save_all()


func has_progress() -> bool:
    return not saved_prog.is_empty()


# Kayıtlı ilerlemede oynanacak yeni seviye var mı? (ileride seviye eklenince otomatik true olur)
func can_continue() -> bool:
    return has_progress() and int(saved_prog["levels_done"]) < LEVELS.size()


func continue_game() -> void:
    if not can_continue():
        return
    var p := saved_prog
    reset_game()
    score = int(p.get("score", 0))
    collected = int(p.get("collected", 0))
    rescued = int(p.get("rescued", 0))
    released = int(p.get("released", 0))
    var pi: Dictionary = p.get("inv", {})
    for k in inv.keys():
        inv[k] = int(pi.get(k, 0))
    gears = int(p.get("gears", 0))
    planks = int(p.get("planks", 0))
    bait = int(p.get("bait", 0))
    lvl_speed = int(p.get("lvl_speed", 0))
    lvl_magnet = int(p.get("lvl_magnet", 0))
    coins = int(p.get("coins", 0))
    rod_lvl = int(p.get("rod_lvl", 0))
    boat_lvl = int(p.get("boat_lvl", 0))
    sold = int(p.get("sold", 0))
    level_idx = int(p["levels_done"])
    begin_level()
    state = S_INTRO


func continue_info() -> String:
    if not has_progress():
        return ""
    var n := int(saved_prog["levels_done"])
    if n >= LEVELS.size():
        return "Tüm seviyeler tamamlandı · yeni seviyeler yakında"
    return "Seviye %d · %d puan · %d para" % [n + 1, int(saved_prog.get("score", 0)), int(saved_prog.get("coins", 0))]


func goals_met() -> bool:
    var l := lvl()
    return lv_collect >= int(l["collect"]) and lv_rescue >= int(l["rescue"]) and lv_release >= int(l["release"])


func check_level_done() -> void:
    if state == S_PLAY and goals_met():
        complete_level()


func complete_level() -> void:
    lock = 1.8   # "Biliyor muydun?" bilgisi hemen geçilmesin
    last_bonus = int(time_left) * 2
    score += last_bonus
    bait_active = false
    hook_state = 0
    hook_depth = 0.0
    drop_carried()
    save_progress(level_idx + 1)
    if level_idx >= LEVELS.size() - 1:
        update_best()
        state = S_WIN
        play_sfx("win")
    else:
        state = S_DONE
        play_sfx("level")


func end_game() -> void:
    lock = 1.0
    state = S_OVER
    bait_active = false
    update_best()
    play_sfx("end")


func update_best() -> void:
    if score > best:
        best = score
        new_best = true
        save_best()


# Görev listesi: [etiket, şu anki, hedef]
func goal_lines() -> Array:
    var l := lvl()
    var out: Array = []
    if int(l["collect"]) > 0:
        out.append(["Çöp topla", lv_collect, int(l["collect"])])
    if int(l["rescue"]) > 0:
        out.append(["Kaplumbağa kurtar", lv_rescue, int(l["rescue"])])
    if int(l["release"]) > 0:
        out.append(["Korunan balığı bırak", lv_release, int(l["release"])])
    return out


func level_progress() -> float:
    if state == S_DONE or state == S_WIN:
        return 1.0
    var tot := 0.0
    var got := 0.0
    for g in goal_lines():
        tot += float(g[2])
        got += minf(float(g[1]), float(g[2]))
    if tot <= 0.0:
        return 1.0
    return got / tot


# Deniz ne kadar kirli olmalı? Seviye + seviye içi ilerleme ile azalır.
func dirt_target() -> float:
    return clampf(1.0 - (float(level_idx) + level_progress()) / float(LEVELS.size()), 0.0, 1.0)


# ---------------------------------------------------------------- spawn

func spawn_item(initial: bool) -> void:
    var r := rng.randf()
    var ty := "bottle"
    if r < 0.35:
        ty = "bottle"
    elif r < 0.65:
        ty = "can"
    elif r < 0.85:
        ty = "tire"
    else:
        ty = "net"
    var y := rng.randf_range(SURF + 70.0, SEABED - 25.0)   # her derinlikte rastgele
    # Görünüm çeşitliliği: şişe türü bazen cam şişe, teneke türü bazen poşet olur (puan/geri dönüşüm aynı)
    var skin := ty
    if ty == "bottle" and rng.randf() < 0.4:
        skin = "cam_sise"
    elif ty == "can" and rng.randf() < 0.4:
        skin = "poset"
    items.append({
        "type": ty,
        "skin": skin,
        "pos": Vector2(rng.randf_range(420.0, W - 50.0), y),
        "rot": rng.randf() * TAU,
        "seed": rng.randf() * 10.0,
        "vx": rng.randf_range(-8.0, 8.0)
    })


# Seviye başına hedef balık sayısı (Sv.1: 3, Sv.2: 5, Sv.3: 7). Artırmak için "2.0" çarpanını büyüt.
func fish_target() -> int:
    return 3 + level_idx * 2


func live_fish() -> int:
    var n := 0
    for f in fish:
        if not f["tagged"]:
            n += 1
    return n


func spawn_fish(initial: bool) -> void:
    var cols := [Color("8fa8d8"), Color("7fc4c4"), Color("c4b86a"), Color("a0a0b8"), Color("d08a6a")]
    var d := 1.0
    if rng.randf() < 0.5:
        d = -1.0
    var x := rng.randf_range(60.0, W - 60.0)
    if not initial:
        x = -60.0 if d > 0.0 else W + 60.0
    var cm := float(rng.randi_range(10, 50))
    fish.append({
        "pos": Vector2(x, rng.randf_range(SURF + 60.0, 540.0)),
        "dir": d,
        "speed": rng.randf_range(35.0, 80.0),
        "size": 0.7 + cm * 0.0144,
        "cm": cm,
        "col": cols[rng.randi() % cols.size()],
        "seed": rng.randf() * 10.0,
        "skin": ["fish_hamsi", "fish_levrek", "fish_lufer"][rng.randi() % 3],
        "tagged": false
    })


func spawn_turtle() -> void:
    turtles.append({
        "pos": Vector2(rng.randf_range(480.0, W - 120.0), rng.randf_range(450.0, 570.0)),
        "free": false,
        "vel": Vector2.ZERO,
        "seed": rng.randf() * 10.0
    })


func msg(s: String, col: Color = Color.WHITE) -> void:
    var y := SURF - 130.0 - float(texts.size()) * 24.0
    texts.append({"s": s, "pos": Vector2(boat_x, maxf(y, 40.0)), "life": 1.8, "col": col})


func warn(s: String) -> void:
    msg(s, Color("ffd27a"))
    play_sfx("error")


# ---------------------------------------------------------------- menüler
# Ana menü, Nasıl oynanır, Ayarlar ve Duraklat menüsü. Fare (üstüne gel / tıkla) ve klavye (yön tuşları + Enter) çalışır.

func is_ui_state() -> bool:
    return state == S_MENU or state == S_PAUSE or state == S_HELP or state == S_SETTINGS


func has_menu_art() -> bool:
    return tex.get("menu_main") != null


func ui_buttons() -> Array:
    var out: Array = []
    match state:
        S_MENU:
            if has_menu_art():
                out = [
                    {"id": "play", "label": "BAŞLA", "rect": MENU_PLAY},
                    {"id": "continue", "label": "DEVAM ET", "rect": MENU_CONT},
                    {"id": "help", "label": "NASIL OYNANIR?", "rect": MENU_HELP},
                    {"id": "settings", "label": "AYARLAR", "rect": MENU_SET},
                ]
            else:
                var lbl := ["BAŞLA", "NASIL OYNANIR?", "AYARLAR"]
                var ids := ["play", "help", "settings"]
                for i in 3:
                    out.append({"id": ids[i], "label": lbl[i], "rect": Rect2(490.0, 320.0 + float(i) * 84.0, 300.0, 60.0)})
                if has_progress():
                    out.append({"id": "continue", "label": "KALDIĞIN YERDEN DEVAM ET", "rect": Rect2(440.0, 570.0, 400.0, 56.0)})
        S_PAUSE:
            var lbl2 := ["DEVAM ET", "NASIL OYNANIR?", "AYARLAR", "ANA MENÜ"]
            var ids2 := ["resume", "help", "settings", "menu"]
            for i in 4:
                if tex.get("pause_panel") != null:
                    out.append({"id": ids2[i], "label": lbl2[i], "rect": PAUSE_BTNS[i]})
                else:
                    out.append({"id": ids2[i], "label": lbl2[i], "rect": Rect2(490.0, 205.0 + float(i) * 76.0, 300.0, 60.0)})
        S_HELP:
            var r := HELP_BACK if tex.get("menu_help") != null else Rect2(490.0, 600.0, 300.0, 52.0)
            out = [{"id": "back", "label": "MENÜYE DÖN", "rect": r}]
        S_SETTINGS:
            out = [
                {"id": "vol_dn", "label": "-", "rect": SET_VOL_DN},
                {"id": "vol_up", "label": "+", "rect": SET_VOL_UP},
                {"id": "vol_slider", "label": "", "rect": SET_SLIDER},
                {"id": "unmute", "label": "SES AÇIK", "rect": SET_UNMUTE},
                {"id": "mute", "label": "SESSİZ", "rect": SET_MUTE},
                {"id": "fs_on", "label": "TAM EKRAN", "rect": SET_FS},
                {"id": "fs_off", "label": "PENCERE", "rect": SET_WIN},
                {"id": "back", "label": "MENÜYE DÖN", "rect": SET_BACK},
            ]
    return out


func ui_hit(pos: Vector2) -> int:
    var bs := ui_buttons()
    for i in bs.size():
        var r: Rect2 = bs[i]["rect"]
        if r.has_point(pos):
            return i
    return -1


# Ayarlar ekranında odak satır bazlıdır (0 ses seviyesi, 1 ses aç/kapat, 2 görüntü modu, 3 geri)
func focus_of(i: int) -> int:
    if state != S_SETTINGS:
        return i
    var id := str(ui_buttons()[i]["id"])
    if id.begins_with("vol"):
        return 0
    if id == "unmute" or id == "mute":
        return 1
    if id == "fs_on" or id == "fs_off":
        return 2
    return 3


func open_pause() -> void:
    pause_prev = state
    state = S_PAUSE
    ui_focus = 0
    play_sfx("click")


func close_pause() -> void:
    state = pause_prev
    play_sfx("click")


func toggle_fullscreen() -> void:
    fullscreen = not fullscreen
    apply_settings()
    save_all()


func change_vol(d: int) -> void:
    volume = clampi(volume + d, 0, 10)
    if d > 0:
        muted = false
    apply_settings()
    save_all()
    play_sfx("click")


# Kaydırıcıda fare x konumundan ses seviyesini ayarlar (0-10)
func set_volume_from_x(x: float) -> void:
    var f := clampf((x - SET_TRACK.position.x) / SET_TRACK.size.x, 0.0, 1.0)
    volume = int(round(f * 10.0))
    muted = false
    apply_settings()


func set_muted(v: bool) -> void:
    muted = v
    apply_settings()
    save_all()
    play_sfx("click")


func set_fullscreen(v: bool) -> void:
    if fullscreen != v:
        fullscreen = v
        apply_settings()
        save_all()
    play_sfx("click")


func ui_activate(id: String) -> void:
    match id:
        "play":
            play_sfx("click")
            start_game()
        "continue":
            if can_continue():
                play_sfx("click")
                continue_game()
            else:
                menu_note = "Tüm seviyeler tamamlandı, yeni seviyeler yakında!" if has_progress() else "Kayıtlı ilerleme yok. Önce bir seviye bitir!"
                menu_note_until = t + 2.5
                play_sfx("error")
        "help":
            play_sfx("click")
            ui_back = state
            state = S_HELP
            ui_focus = 0
        "settings":
            play_sfx("click")
            ui_back = state
            state = S_SETTINGS
            ui_focus = 0
        "back":
            play_sfx("click")
            slider_drag = false
            state = ui_back
            ui_focus = 0
        "resume":
            close_pause()
        "menu":
            play_sfx("click")
            reset_game()
            state = S_MENU
            ui_focus = 0
        "vol_dn":
            change_vol(-1)
        "vol_up":
            change_vol(1)
        "unmute":
            set_muted(false)
        "mute":
            set_muted(true)
        "fs_on":
            set_fullscreen(true)
        "fs_off":
            set_fullscreen(false)


func ui_key(e: InputEventKey) -> void:
    var k := e.keycode
    var up: bool = k == KEY_UP or k == KEY_W
    var dn: bool = k == KEY_DOWN or k == KEY_S
    var lf: bool = k == KEY_LEFT or k == KEY_A
    var rt: bool = k == KEY_RIGHT or k == KEY_D
    var ok: bool = k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE
    if k == KEY_ESCAPE:
        if state == S_PAUSE:
            close_pause()
        elif state == S_HELP or state == S_SETTINGS:
            ui_activate("back")
        return
    var n := 4 if state == S_SETTINGS else ui_buttons().size()
    if up:
        ui_focus = (ui_focus - 1 + n) % n
    elif dn:
        ui_focus = (ui_focus + 1) % n
    if state == S_SETTINGS:
        if lf or rt:
            var d := -1 if lf else 1
            if ui_focus == 0:
                change_vol(d)
            elif ui_focus == 1:
                set_muted(rt)
            elif ui_focus == 2:
                set_fullscreen(lf)
        elif ok:
            if ui_focus == 1:
                set_muted(not muted)
            elif ui_focus == 2:
                set_fullscreen(not fullscreen)
            elif ui_focus == 3:
                ui_activate("back")
        return
    if ok:
        var bs := ui_buttons()
        if ui_focus >= 0 and ui_focus < bs.size():
            ui_activate(str(bs[ui_focus]["id"]))


# true dönerse olay menü tarafından işlendi demektir
func ui_input(event: InputEvent) -> bool:
    var mp := get_global_mouse_position()
    if event is InputEventMouseMotion:
        if is_ui_state():
            if slider_drag and state == S_SETTINGS:
                set_volume_from_x(mp.x)
                ui_focus = 0
                return true
            var hi := ui_hit(mp)
            if hi >= 0:
                ui_focus = focus_of(hi)
            return true
        return false
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if is_ui_state():
            if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
                var ci := ui_hit(mp)
                if ci >= 0:
                    var cid := str(ui_buttons()[ci]["id"])
                    if cid == "vol_slider":
                        slider_drag = true
                        set_volume_from_x(mp.x)
                    else:
                        ui_activate(cid)
            elif not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and slider_drag:
                slider_drag = false
                save_all()
                play_sfx("click")
            return true
        if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and GEAR_STATES.has(state) and GEAR_BTN.has_point(mp):
            open_pause()
            return true
        return false
    if event is InputEventKey:
        var e: InputEventKey = event
        if not e.pressed or e.echo:
            return false
        if e.keycode == KEY_F11:
            toggle_fullscreen()
            return true
        if is_ui_state():
            ui_key(e)
            return true
        if e.keycode == KEY_ESCAPE and GEAR_STATES.has(state):
            open_pause()
            return true
    return false


func update_cursor() -> void:
    var mp := get_global_mouse_position()
    var hov := false
    if is_ui_state():
        hov = ui_hit(mp) >= 0
    elif state == S_WIN and tex.get("win_panel") != null:
        hov = WIN_BTN_AGAIN.has_point(mp) or WIN_BTN_MENU.has_point(mp)
    elif GEAR_STATES.has(state):
        hov = GEAR_BTN.has_point(mp)
    DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND if hov else DisplayServer.CURSOR_ARROW)


# ---------------------------------------------------------------- girdi

func _unhandled_input(event: InputEvent) -> void:
    if ui_input(event):
        return
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
            if state == S_PLAY:
                cast_or_reel(1)
            return
        if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
            if lock > 0.0 and state != S_PLAY and state != S_RESCUE and state != S_MENU:
                return
            match state:
                S_PLAY:
                    cast_or_reel(0)
                S_RESCUE:
                    rescue_press()
                S_WEIGH:
                    var wmp := get_global_mouse_position()
                    if weigh_btn_b().has_point(wmp):
                        weigh_decide(true)
                    elif weigh_btn_s().has_point(wmp):
                        weigh_decide(false)
                S_MENU:
                    start_game()
                S_INTRO:
                    state = S_PLAY
                    play_sfx("start")
                S_DONE:
                    level_idx += 1
                    begin_level()
                    state = S_INTRO
                S_OVER:
                    retry_level()
                S_WIN:
                    var wp := get_global_mouse_position()
                    if tex.get("win_panel") == null:
                        start_game()
                    elif WIN_BTN_AGAIN.has_point(wp):
                        start_game()
                    elif WIN_BTN_MENU.has_point(wp):
                        reset_game()
                        state = S_MENU
        return
    if not (event is InputEventKey):
        return
    var e: InputEventKey = event
    if not e.pressed or e.echo:
        return
    var enter: bool = e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER
    var confirm: bool = enter or e.keycode == KEY_SPACE
    if lock > 0.0 and (state == S_INTRO or state == S_DONE or state == S_OVER or state == S_WIN):
        return
    if state == S_MENU:
        if confirm:
            start_game()
        elif e.keycode == KEY_C and has_progress():
            ui_activate("continue")
        return
    if state == S_INTRO:
        if confirm:
            state = S_PLAY
            play_sfx("start")
        return
    if state == S_DONE:
        if confirm:
            level_idx += 1
            begin_level()
            state = S_INTRO
        return
    if state == S_OVER:
        if e.keycode == KEY_R or enter:
            retry_level()
        elif e.keycode == KEY_M or e.keycode == KEY_ESCAPE:
            reset_game()
            state = S_MENU
        return
    if state == S_WIN:
        if e.keycode == KEY_R or enter:
            start_game()
        elif e.keycode == KEY_M or e.keycode == KEY_ESCAPE:
            reset_game()
            state = S_MENU
        return
    if state == S_WEIGH:
        if e.keycode == KEY_B:
            weigh_decide(true)
        elif e.keycode == KEY_S:
            weigh_decide(false)
        return
    if state == S_RESCUE:
        if confirm or e.keycode == KEY_F:
            rescue_press()
        return
    match e.keycode:
        KEY_F:
            cast_or_reel(0)
        KEY_G:
            cast_or_reel(1)
        KEY_SPACE:
            craft_bait()
        KEY_E:
            recycle()
        KEY_1:
            upgrade(1)
        KEY_2:
            upgrade(2)
        KEY_3:
            upgrade(3)
        KEY_4:
            upgrade(4)


# mode 0 = Çöp Kancası (çöp + kaplumbağa), mode 1 = Balık Oltası (sadece balık, deniz temizlenince açılır)
func cast_or_reel(mode: int = 0) -> void:
    if hook_state == 0:
        if mode == 1 and not fishing_open:
            var thr := int(round(FISH_UNLOCK_CLEAN * 100.0))
            var cur := int(round((1.0 - dirt) * 100.0))
            warn("Balık tutma kilitli: deniz %%%d temiz olunca açılır (şu an %%%d)" % [thr, cur])
            return
        if mode == 1 and bait <= 0:
            warn("Yem yok! Önce yem yap (Boşluk: 2 şişe/teneke = 2 yem)")
            return
        hook_mode = mode
        hook_state = 1
        hook_x = hook_home_x()
        bait_active = false
        play_sfx("cast")
        if mode == 1 and bait > 0:
            bait -= 1
            bait_active = true
    elif mode == hook_mode:
        if hook_state == 1:
            hook_state = 2
    else:
        warn("Önce oltayı çek")


func craft_bait() -> void:
    var small: int = inv["bottle"] + inv["can"]
    if small < 2:
        warn("Yem için 2 şişe/teneke lazım")
        return
    var need := 2
    while need > 0:
        if inv["bottle"] >= inv["can"] and inv["bottle"] > 0:
            inv["bottle"] -= 1
        else:
            inv["can"] -= 1
        need -= 1
    bait += 2
    play_sfx("craft")
    msg("+2 Yem üretildi!", Color("ffb347"))


func near_pier() -> bool:
    return boat_x < 620.0 and hook_state == 0


func recycle() -> void:
    if not near_pier():
        warn("İskeleye yaklaş (sola) ve oltayı çek")
        return
    var tires: int = inv["tire"]
    var nets: int = inv["net"]
    if tires + nets == 0:
        warn("Lastik veya ağ lazım")
        return
    gears += tires
    planks += nets
    score += (tires + nets) * 5
    inv["tire"] = 0
    inv["net"] = 0
    play_sfx("craft")
    msg("Dönüştürüldü: +%d dişli +%d tahta" % [tires, nets], Color("9cff7a"))


func upgrade(kind: int) -> void:
    if kind == 1:
        if lvl_speed >= 3:
            warn("Olta hızı maksimum")
        elif gears < 2:
            warn("2 dişli gerek")
        else:
            gears -= 2
            lvl_speed += 1
            play_sfx("upgrade")
            msg("Olta hızı Sv.%d" % lvl_speed, Color("9cff7a"))
    elif kind == 2:
        if lvl_magnet >= 3:
            warn("Mıknatıs maksimum")
        elif planks < 2:
            warn("2 tahta gerek")
        else:
            planks -= 2
            lvl_magnet += 1
            play_sfx("upgrade")
            msg("Mıknatıs Sv.%d" % lvl_magnet, Color("9cff7a"))
    elif kind == 3:
        if rod_lvl >= 3:
            warn("Güçlü Olta maksimum")
        elif coins < int(ROD_COST[rod_lvl]):
            warn("%d para gerek" % int(ROD_COST[rod_lvl]))
        else:
            coins -= int(ROD_COST[rod_lvl])
            rod_lvl += 1
            play_sfx("upgrade")
            msg("Güçlü Olta Sv.%d" % rod_lvl, Color("9cff7a"))
            if rod_lvl >= 3:
                msg("ÇİFT KANCA! Artık 2 çöp taşırsın", Color("ffe27a"))
    elif kind == 4:
        if boat_lvl >= 3:
            warn("Tekne Motoru maksimum")
        elif coins < int(BOAT_COST[boat_lvl]):
            warn("%d para gerek" % int(BOAT_COST[boat_lvl]))
        else:
            coins -= int(BOAT_COST[boat_lvl])
            boat_lvl += 1
            play_sfx("upgrade")
            msg("Tekne Motoru Sv.%d" % boat_lvl, Color("9cff7a"))


# ---------------------------------------------------------------- güncelleme

func rod_tip() -> Vector2:
    return Vector2(boat_x + tip_dx(), SURF - 6.0 + ROD_TIP_OFFSET.y + sin(t * 2.0) * 2.0)


func hook_pos() -> Vector2:
    return Vector2(hook_x, SURF + hook_depth)


func _process(delta: float) -> void:
    t += delta
    lock = maxf(0.0, lock - delta)
    queue_redraw()
    update_cursor()
    if state == S_PAUSE or state == S_HELP or state == S_SETTINGS:
        return   # duraklatılmış: dünya, süre ve olta donar

    for i in range(texts.size() - 1, -1, -1):
        var tx: Dictionary = texts[i]
        tx["life"] = float(tx["life"]) - delta
        var p: Vector2 = tx["pos"]
        p.y -= 28.0 * delta
        tx["pos"] = p
        if float(tx["life"]) <= 0.0:
            texts.remove_at(i)

    for i in bubbles.size():
        var b: Vector2 = bubbles[i]
        b.y -= 22.0 * delta
        if b.y < SURF:
            b = Vector2(rng.randf_range(0, W), SEABED)
        bubbles[i] = b

    dirt = lerpf(dirt, dirt_target(), clampf(1.2 * delta, 0.0, 1.0))
    if state == S_PLAY:
        banner_t = maxf(0.0, banner_t - delta)
        if not fishing_open and 1.0 - dirt_target() >= FISH_UNLOCK_CLEAN - 0.0001:
            unlock_fishing()
    update_world(delta)
    if state == S_WEIGH:
        weigh_t += delta
    elif state == S_RESCUE:
        update_rescue(delta)

    if state != S_PLAY:
        return

    time_left -= delta
    if time_left <= 0.0:
        time_left = 0.0
        end_game()
        return

    # tekne
    var dir := 0.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        dir -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        dir += 1.0
    boat_x = clampf(boat_x + dir * (250.0 + float(boat_lvl) * 50.0) * delta, 470.0, 1170.0)
    if hook_state == 0:
        if boat_x >= 1169.0 and not boat_flip:
            boat_flip = true
        elif boat_x <= 471.0 and boat_flip:
            boat_flip = false
    hook_x = lerpf(hook_x, hook_home_x(), clampf(6.0 * delta, 0.0, 1.0))

    # olta
    var spd := 200.0 + float(lvl_speed) * 60.0
    var max_d := SEABED - SURF - 10.0
    if hook_state == 1:
        hook_depth += spd * delta
        if hook_depth >= max_d:
            hook_depth = max_d
            hook_state = 2
    elif hook_state == 2:
        hook_depth -= spd * 1.3 * delta
        if hook_depth <= 0.0:
            hook_depth = 0.0
            hook_state = 0
            finish_cast()
    if hook_state != 0:
        check_hook()


# Dünya (çöpler, balıklar, kaplumbağalar) menüde ve oyun sonunda da canlı kalır
func update_world(delta: float) -> void:
    for it in items:
        var p: Vector2 = it["pos"]
        var ivx := float(it.get("vx", 0.0))
        p.x += ivx * delta
        if p.x < 420.0 or p.x > W - 40.0:
            ivx = -ivx
            it["vx"] = ivx
            p.x = clampf(p.x, 420.0, W - 40.0)
        it["pos"] = p
    if state == S_PLAY:
        spawn_timer -= delta
        if spawn_timer <= 0.0:
            spawn_timer = 1.8
            if items.size() < 22:
                spawn_item(false)

    var hp := hook_pos()
    for f in fish:
        var fp: Vector2 = f["pos"]
        var attracted: bool = hook_mode == 1 and bait_active and hook_state != 0 and not f["tagged"] and fp.distance_to(hp) < 280.0 + float(rod_lvl) * 40.0
        if attracted:
            var v := (hp - fp).normalized()
            fp += v * 80.0 * delta
            if absf(v.x) > 0.2:
                f["dir"] = 1.0 if v.x > 0.0 else -1.0
        else:
            fp.x += float(f["dir"]) * float(f["speed"]) * delta
            if fp.x > W + 60.0 or fp.x < -60.0:
                if f["tagged"]:
                    f["gone"] = true
                else:
                    fp.x = -60.0 if fp.x > 0.0 else W + 60.0
        f["pos"] = fp
    for i in range(fish.size() - 1, -1, -1):
        if fish[i].get("gone", false):
            fish.remove_at(i)
    fish_timer -= delta
    if fish_timer <= 0.0:
        fish_timer = 6.0
        var live := 0
        for f in fish:
            if not f["tagged"]:
                live += 1
        if live < fish_target():
            spawn_fish(false)

    for i in range(turtles.size() - 1, -1, -1):
        var tt: Dictionary = turtles[i]
        tt["cool"] = maxf(0.0, float(tt.get("cool", 0.0)) - delta)
        if tt["free"]:
            var tp: Vector2 = tt["pos"]
            var tv: Vector2 = tt["vel"]
            tp += tv * delta
            tt["pos"] = tp
            if tp.x < -100.0 or tp.x > W + 100.0 or tp.y < SURF - 20.0:
                turtles.remove_at(i)
    if state == S_PLAY:
        turtle_timer -= delta
        if turtle_timer <= 0.0:
            turtle_timer = 14.0
            var tangled := 0
            for tt in turtles:
                if not tt["free"]:
                    tangled += 1
            if tangled < 2:
                spawn_turtle()


func unlock_fishing() -> void:
    fishing_open = true
    banner_t = 4.0
    play_sfx("level")
    msg("Balık tutma açıldı! (Sağ tık / G, yem şart: Boşluk)", Color("ffe27a"))


func carry_cap() -> int:
    return 2 if rod_lvl >= 3 else 1


func carry_count() -> int:
    var n := 0
    if not carrying.is_empty():
        n += 1
    if not carrying2.is_empty():
        n += 1
    return n


func drop_carried() -> void:
    if not carrying.is_empty():
        items.append(carrying)
    if not carrying2.is_empty():
        items.append(carrying2)
    carrying = {}
    carrying2 = {}


func price_of(cm: float) -> int:
    return int(round(cm * PRICE_PER_CM))


func in_protected(cm: float) -> bool:
    return cm < SELL_MIN or cm > SELL_MAX   # yeşil aralığın dışı = korunur, bırakılmalı


func check_hook() -> void:
    var hp := hook_pos()
    var rad := 22.0 + float(lvl_magnet) * 8.0
    if hook_mode == 0 and carry_count() < carry_cap():
        for i in range(items.size() - 1, -1, -1):
            var it: Dictionary = items[i]
            var ip: Vector2 = it["pos"]
            if ip.distance_to(hp) < rad + 8.0:
                if carrying.is_empty():
                    carrying = it
                else:
                    carrying2 = it
                items.remove_at(i)
                play_sfx("collect")
                if carry_count() >= carry_cap():
                    hook_state = 2
                    msg("Çöp tutuldu!", Color("c8f0ff"))
                else:
                    msg("Çöp tutuldu! 2. çöp için devam et (F: çek)", Color("c8f0ff"))
                break
    for tt in turtles:
        if hook_mode != 0 or tt["free"] or float(tt.get("cool", 0.0)) > 0.0:
            continue
        var tp: Vector2 = tt["pos"]
        if tp.distance_to(hp) < 55.0 + float(lvl_magnet) * 5.0:
            start_rescue(tt)
            return
    for i in range(fish.size() - 1, -1, -1):
        var f: Dictionary = fish[i]
        if hook_mode != 1 or f["tagged"] or not bait_active:
            continue   # yemsiz balık tutulmaz
        var fp: Vector2 = f["pos"]
        if fp.distance_to(hp) < 44.0 + float(rod_lvl) * 6.0:
            fish.remove_at(i)
            start_weigh(f)
            return


# ---------------------------------------------------------------- balık tartısı (mini ekran)

func start_weigh(f: Dictionary) -> void:
    weigh_f = f
    weigh_t = 0.0
    bait_active = false
    state = S_WEIGH
    play_sfx("fish")


# release = true: denize bırak, false: sat
func weigh_decide(release: bool) -> void:
    if weigh_t < WEIGH_TIME:
        return
    var cm := float(weigh_f["cm"])
    var prot := in_protected(cm)
    var hp := hook_pos()
    state = S_PLAY
    hook_state = 2
    if release:
        weigh_f["tagged"] = true
        weigh_f["pos"] = hp
        weigh_f["dir"] = -1.0 if rng.randf() < 0.5 else 1.0
        weigh_f["speed"] = 140.0
        fish.append(weigh_f)
        if prot:
            score += 15
            released += 1
            lv_release += 1
            play_sfx("fish")
            texts.append({"s": "Balık korundu, denize bırakıldı +15", "pos": hp, "life": 2.2, "col": Color("7dff9a")})
        else:
            score += 2
            texts.append({"s": "Balık denize bırakıldı", "pos": hp, "life": 1.8, "col": Color("c8f0ff")})
    else:
        if prot:
            score = maxi(0, score - 20)
            warn("Korunan boy! Ceza -20 puan")
        else:
            var pr := price_of(cm)
            coins += pr
            sold += 1
            play_sfx("craft")
            texts.append({"s": "Balık satıldı +%d para" % pr, "pos": hp, "life": 2.0, "col": Color("ffe27a")})
    weigh_f = {}
    check_level_done()


# ---------------------------------------------------------------- kaplumbağa kurtarma (mini oyun: ağı doğru anda kes)

func start_rescue(tt: Dictionary) -> void:
    rescue_tt = tt
    rescue_hits = 0
    rescue_time = 10.0
    rescue_speed = 0.8
    rescue_cursor = 0.0
    rescue_dir = 1.0
    rescue_flash = 0.0
    new_rescue_zone()
    state = S_RESCUE
    play_sfx("collect")


func new_rescue_zone() -> void:
    rescue_zone_w = maxf(0.10, 0.22 - 0.04 * float(rescue_hits))
    rescue_zone_c = rng.randf_range(0.15, 0.85)


func update_rescue(delta: float) -> void:
    rescue_time -= delta
    rescue_flash = maxf(0.0, rescue_flash - delta)
    rescue_cursor += rescue_dir * rescue_speed * delta
    if rescue_cursor >= 1.0:
        rescue_cursor = 1.0
        rescue_dir = -1.0
    elif rescue_cursor <= 0.0:
        rescue_cursor = 0.0
        rescue_dir = 1.0
    if rescue_time <= 0.0:
        rescue_fail()


func rescue_press() -> void:
    if absf(rescue_cursor - rescue_zone_c) <= rescue_zone_w * 0.5:
        rescue_hits += 1
        rescue_flash = 0.35
        rescue_ok = true
        play_sfx("craft")
        if rescue_hits >= RESCUE_NEED:
            finish_rescue()
            return
        rescue_speed = 0.8 + 0.25 * float(rescue_hits)
        new_rescue_zone()
    else:
        rescue_time -= 1.5
        rescue_flash = 0.35
        rescue_ok = false
        play_sfx("error")


func rescue_fail() -> void:
    rescue_tt["cool"] = 4.0
    state = S_PLAY
    hook_state = 2
    warn("Ağ kesilemedi! Tekrar dene")


func finish_rescue() -> void:
    var tt := rescue_tt
    state = S_PLAY
    tt["free"] = true
    var sx := -1.0 if rng.randf() < 0.5 else 1.0
    tt["vel"] = Vector2(sx * 90.0, -22.0)
    var tp: Vector2 = tt["pos"]
    score += 50
    rescued += 1
    lv_rescue += 1
    play_sfx("rescue")
    texts.append({"s": "Kaplumbağa kurtarıldı! +50", "pos": tp, "life": 2.2, "col": Color("7dff9a")})
    check_level_done()


func finish_cast() -> void:
    bait_active = false
    for c in [carrying, carrying2]:
        if not c.is_empty():
            bank_item(c)
    carrying = {}
    carrying2 = {}
    hook_mode = 0
    check_level_done()


func bank_item(c: Dictionary) -> void:
    var ty: String = c["type"]
    inv[ty] += 1
    var pts := 10
    if ty == "tire":
        pts = 20
    elif ty == "net":
        pts = 25
    score += pts
    collected += 1
    lv_collect += 1
    msg("+%d puan" % pts, Color("9cff7a"))


# ---------------------------------------------------------------- çizim yardımcıları

func ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
    var pts := PackedVector2Array()
    for i in 20:
        var a := TAU * float(i) / 20.0
        pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
    draw_colored_polygon(pts, col)


func txt(s: String, pos: Vector2, size: int, col: Color) -> void:
    draw_string(font, pos + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.6 * col.a))
    draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func txt_r(s: String, right_x: float, y: float, size: int, col: Color) -> void:
    draw_string(font, Vector2(right_x - 400.0 + 2.0, y + 2.0), s, HORIZONTAL_ALIGNMENT_RIGHT, 400.0, size, Color(0, 0, 0, 0.6 * col.a))
    draw_string(font, Vector2(right_x - 400.0, y), s, HORIZONTAL_ALIGNMENT_RIGHT, 400.0, size, col)


func txt_c(s: String, cx: float, y: float, size: int, col: Color) -> void:
    draw_string(font, Vector2(cx - 500.0 + 2.0, y + 2.0), s, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, size, Color(0, 0, 0, 0.6 * col.a))
    draw_string(font, Vector2(cx - 500.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, size, col)


# Metni max_w genişliğine sığana kadar küçülterek ortalı çizer
func txt_fit(s: String, cx: float, y: float, size: int, max_w: float, col: Color) -> void:
    var sz := size
    while sz > 10 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > max_w:
        sz -= 1
    txt_c(s, cx, y, sz, col)


func txt_wrap(s: String, cx: float, y: float, width: float, size: int, col: Color) -> void:
    draw_multiline_string(font, Vector2(cx - width / 2.0 + 2.0, y + 2.0), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, -1, Color(0, 0, 0, 0.6 * col.a))
    draw_multiline_string(font, Vector2(cx - width / 2.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, -1, col)


func panel(r: Rect2, border: Color = Color("3a4f78"), fill_a: float = 1.0) -> void:
    draw_rect(r, Color(0.11, 0.153, 0.25, fill_a))
    draw_rect(r, border, false, 3.0)


# Görseli merkezine göre çizer. Görsel yoksa false döner (kodla çizilen yedek kullanılır).
func draw_tex(n: String, c: Vector2, rot: float = 0.0, sc: Vector2 = Vector2.ONE, mod: Color = Color.WHITE) -> bool:
    var tx: Texture2D = tex.get(n)
    if tx == null:
        return false
    draw_set_transform_matrix(hud_xf * Transform2D(rot, c).scaled_local(sc))
    draw_texture(tx, -tx.get_size() * 0.5, mod)
    draw_set_transform_matrix(hud_xf)
    return true


# Görseli sol-üst köşesine göre çizer.
func draw_tex_tl(n: String, tl: Vector2) -> bool:
    var tx: Texture2D = tex.get(n)
    if tx == null:
        return false
    draw_texture(tx, tl)
    return true


# Görseli verilen kutuya sığacak şekilde küçültüp ortalayarak çizer (HUD ikonları için).
func draw_tex_fit(n: String, c: Vector2, box: float) -> bool:
    var tx: Texture2D = tex.get(n)
    if tx == null:
        return false
    var sz := tx.get_size()
    var s := minf(1.0, box / maxf(sz.x, sz.y))
    return draw_tex(n, c, 0.0, Vector2(s, s))


func draw_item(ty: String, pos: Vector2, rot: float, s: float = 1.0, skin: String = "") -> void:
    var tn := skin if (skin != "" and tex.get(skin) != null) else ty
    if draw_tex(tn, pos, rot, Vector2(s, s)):
        return
    draw_set_transform_matrix(hud_xf * Transform2D(rot, pos).scaled_local(Vector2(s, s)))
    match ty:
        "bottle":
            draw_rect(Rect2(-5, -12, 10, 24), Color("9fd8f0"))
            draw_rect(Rect2(-3, -17, 6, 6), Color("3b7bd9"))
            draw_rect(Rect2(-5, -2, 10, 6), Color(1, 1, 1, 0.6))
        "can":
            draw_rect(Rect2(-8, -10, 16, 20), Color("b9b9b9"))
            draw_rect(Rect2(-8, -4, 16, 8), Color("c0392b"))
            draw_rect(Rect2(-8, -10, 16, 3), Color("e0e0e0"))
        "tire":
            draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color("2b2b33"), 10.0)
            draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 24, Color("4a4a55"), 2.0)
        "net":
            for i in 5:
                draw_line(Vector2(-20 + i * 10, -14), Vector2(-20 + i * 10, 14), Color("1d3550"), 2.0)
            for j in 4:
                draw_line(Vector2(-20, -14 + j * 9), Vector2(20, -14 + j * 9), Color("1d3550"), 2.0)
    draw_set_transform_matrix(hud_xf)


func draw_item_hud(ty: String, pos: Vector2) -> void:
    if draw_tex_fit(ty, pos, 40.0):
        return
    draw_item(ty, pos, 0.0, 0.85)


func draw_gear(pos: Vector2) -> void:
    if draw_tex_fit("gear", pos, 36.0):
        return
    draw_circle(pos, 10.0, Color("9aa3ad"))
    for i in 8:
        var a := TAU * float(i) / 8.0
        draw_circle(pos + Vector2(cos(a), sin(a)) * 12.0, 3.0, Color("9aa3ad"))
    draw_circle(pos, 4.0, Color("1c2740"))


func draw_plank(pos: Vector2) -> void:
    if draw_tex_fit("plank", pos, 36.0):
        return
    draw_rect(Rect2(pos.x - 13.0, pos.y - 8.0, 26, 16), Color("b98348"))
    draw_rect(Rect2(pos.x - 13.0, pos.y - 8.0, 26, 16), Color("6b4a22"), false, 2.0)


func draw_bait_icon(pos: Vector2, box: float) -> void:
    if draw_tex_fit("bait", pos, box):
        return
    draw_circle(pos, box * 0.28, Color("ff9a3c"))


func draw_fish(pos: Vector2, d: float, sz: float, col: Color, tagged: bool, skin: String = "") -> void:
    # Balık görselleri (fish_hamsi / fish_levrek / fish_lufer) SAĞA bakar ve kendi renkleriyle çizilir.
    # Hiçbiri yoksa eski fish.png (renk ile boyanır) ya da kodla çizilen balık kullanılır.
    var tn := skin if (skin != "" and tex.get(skin) != null) else "fish"
    var mod := Color.WHITE if tn != "fish" else col
    if draw_tex(tn, pos, 0.0, Vector2(d * sz, sz), mod):
        if tagged:
            draw_circle(pos + Vector2(-2.0 * d * sz, -16.0 * sz), 4.0, Color("5fff7a"))
        return
    var tail := PackedVector2Array([
        pos + Vector2(-16.0 * d * sz, 0),
        pos + Vector2(-30.0 * d * sz, -10.0 * sz),
        pos + Vector2(-30.0 * d * sz, 10.0 * sz)])
    draw_colored_polygon(tail, col.darkened(0.2))
    ellipse(pos, 20.0 * sz, 10.0 * sz, col)
    ellipse(pos + Vector2(0, 4.0 * sz), 14.0 * sz, 4.0 * sz, col.lightened(0.35))
    draw_circle(pos + Vector2(10.0 * d * sz, -3.0 * sz), 2.5, Color.BLACK)
    if tagged:
        draw_circle(pos + Vector2(-2.0 * d * sz, -8.0 * sz), 3.0, Color("5fff7a"))


func draw_turtle(pos: Vector2, free: bool, face: float) -> void:
    var d := -1.0 if face < 0.0 else 1.0
    # turtle_net.png ve turtle_free.png SAĞA bakmalı
    if free:
        if draw_tex("turtle_free", pos, 0.0, Vector2(d, 1.0)):
            return
    elif draw_tex("turtle_net", pos, 0.0, Vector2(d, 1.0)):
        return
    elif draw_tex("turtle_free", pos, 0.0, Vector2(d, 1.0)):
        # ağa dolanmış kaplumbağa: serbest kaplumbağa + atık ağı görseli
        draw_tex("turtle_net_overlay", pos + Vector2(2.0 * d, 2.0), 0.0, Vector2(d * 0.95, 0.95), Color(1, 1, 1, 0.9))
        return
    ellipse(pos + Vector2(-18.0 * d, 14.0), 10.0, 5.0, Color("3f9a52"))
    ellipse(pos + Vector2(14.0 * d, 14.0), 10.0, 5.0, Color("3f9a52"))
    ellipse(pos + Vector2(34.0 * d, -2.0), 12.0, 9.0, Color("4faa5a"))
    draw_circle(pos + Vector2(38.0 * d, -4.0), 2.0, Color.BLACK)
    ellipse(pos, 30.0, 21.0, Color("9a6a3a"))
    ellipse(pos, 22.0, 14.0, Color("b98348"))
    draw_line(pos + Vector2(-20, 0), pos + Vector2(20, 0), Color("7a5028"), 2.0)
    draw_line(pos + Vector2(0, -14), pos + Vector2(0, 14), Color("7a5028"), 2.0)
    if not free and draw_tex("turtle_net_overlay", pos + Vector2(2.0 * d, 2.0), 0.0, Vector2(d, 1.0), Color(1, 1, 1, 0.95)):
        return
    if not free:
        for i in 7:
            draw_line(pos + Vector2(-34 + i * 11, -26), pos + Vector2(-34 + i * 11, 26), Color(0.7, 0.9, 1.0, 0.8), 1.5)
        for j in 5:
            draw_line(pos + Vector2(-36, -24 + j * 12), pos + Vector2(36, -24 + j * 12), Color(0.7, 0.9, 1.0, 0.8), 1.5)
        draw_line(pos + Vector2(-36, 24), pos + Vector2(-60, 40), Color(0.7, 0.9, 1.0, 0.8), 1.5)


# ---------------------------------------------------------------- çizim

func _draw() -> void:
    if state == S_HELP or state == S_SETTINGS:
        draw_ui_screen()
        return
    draw_sky_and_sea()
    draw_underwater()
    draw_pier()
    draw_boat()
    draw_hook()
    if state != S_MENU:
        draw_hud()
        for tx in texts:
            var c: Color = tx["col"]
            c.a = clampf(float(tx["life"]), 0.0, 1.0)
            var p: Vector2 = tx["pos"]
            txt_c(str(tx["s"]), p.x, p.y, 22, c)
        draw_banner()
    match state:
        S_MENU:
            draw_menu()
        S_INTRO:
            draw_intro()
        S_DONE:
            draw_level_done()
        S_OVER:
            draw_end_screen()
        S_WIN:
            draw_win()
        S_WEIGH:
            draw_weigh()
        S_RESCUE:
            draw_rescue()
        S_PAUSE:
            draw_pause()
    if GEAR_STATES.has(state):
        draw_gear_button()


func draw_sky_and_sea() -> void:
    if draw_tex_tl("background", Vector2.ZERO):
        draw_smog()
        draw_wave_line()
        return
    # gökyüzü: assets/sky.png (1280x200) varsa onu çiz, yoksa kodla çizilen gökyüzü
    var sky_tx: Texture2D = tex.get("sky")
    if sky_tx != null:
        # sky.png alt kenarı (bulutlu ufuk) su çizgisine oturur, üst boşluk görselin üst satırıyla doldurulur
        var sky_h := float(sky_tx.get_height())
        var sky_top := HORIZON_Y - sky_h
        if sky_top > 0.0:
            draw_texture_rect_region(sky_tx, Rect2(0, 0, W, sky_top), Rect2(0, 0, sky_tx.get_width(), 1.0))
        draw_texture(sky_tx, Vector2(0.0, sky_top))
    else:
        var cols := [Color("8fd3f0"), Color("7ccbed"), Color("69c2e8"), Color("5bb8e2")]
        for i in 4:
            draw_rect(Rect2(0, i * 50.0, W, 50.0), cols[i])
        draw_rect(Rect2(0, 200, W, HORIZON_Y - 200.0), cols[3])
        draw_circle(Vector2(1120, 80), 38.0, Color("fff2a8"))
        for k in 3:
            var cx := fmod(t * 8.0 + float(k) * 480.0, W + 300.0) - 150.0
            var cy := 70.0 + float(k) * 40.0
            ellipse(Vector2(cx, cy), 60.0, 16.0, Color(1, 1, 1, 0.9))
            ellipse(Vector2(cx + 30.0, cy - 12.0), 36.0, 14.0, Color(1, 1, 1, 0.9))
    draw_horizon_blend()
    draw_rect(Rect2(0, HORIZON_Y, W, SURF - HORIZON_Y), Color("3aa8d4"))
    var strip_h := SURF - HORIZON_Y
    if strip_h > 30.0:
        for i in 14:
            var sx := fmod(float(i) * 97.0 + t * 12.0, W)
            var sy := HORIZON_Y + 12.0 + float(i % 4) * (strip_h - 24.0) / 3.0
            draw_line(Vector2(sx, sy), Vector2(sx + 28.0, sy), Color(1, 1, 1, 0.35), 2.0)
    draw_surface_mud()
    var has_sea := draw_tex_tl("sea", Vector2(0.0, SEA_Y))
    if not has_sea:
        for i in 8:
            var f := float(i) / 7.0
            draw_rect(Rect2(0, SURF + float(i) * 50.0, W, 50.0), Color("2593bd").lerp(Color("0f4f73"), f))
    draw_rect(Rect2(0, SEABED, W, H - SEABED), Color("8c7d55"))
    draw_rect(Rect2(0, SEABED, W, 6), Color("a89a6a"))
    if has_sea:
        draw_sea_shimmer()
    draw_smog()
    if not has_sea:
        draw_wave_line()   # sea.png varsa dalga zaten görselin içinde


# Gökyüzünün alt kenarı (açık sis) ile deniz arasında parlak bir çizgi oluşmasın diye
# son HORIZON_FADE piksel yumuşakça deniz rengine geçer (kirliyse çamurlu renge, temizse mavi-yeşile).
func draw_horizon_blend() -> void:
    var c := water_top_color()
    var c0 := Color(c.r, c.g, c.b, 0.0)
    var c1 := Color(c.r, c.g, c.b, 1.0)
    var y0 := HORIZON_Y - HORIZON_FADE
    var y1 := HORIZON_Y + 4.0
    draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, y1), Vector2(0, y1)]),
        PackedColorArray([c0, c0, c1, c1]))


# Su altının su çizgisinde (y=SURF) o anki kirli rengi: temiz deniz rengi + çamur bindirmesi + hafif bulanıklık.
func water_top_color() -> Color:
    var c := SEA_TOP_COLOR.lerp(MUD_COLOR, MUD_ALPHA * dirt)
    return c.lerp(Color(0.30, 0.26, 0.12), 0.14 * dirt)


# Üst deniz (su yüzeyi şeridi) de su altıyla AYNI renge kirlenir ve temizlendikçe açılır.
# Aynı alfa değil aynı SONUÇ rengi hedeflenir (şerit temizken daha açık mavi olduğu için aynı alfa onu daha açık gösterirdi).
func draw_surface_mud() -> void:
    var wc := water_top_color()
    # Kirli aralıkta (dirt > SURFACE_CLEAR_AT) şerit su altıyla aynı renktir; deniz temizlenip dirt sıfıra inerken yumuşakça açık maviye döner.
    var a := smoothstep(0.0, SURFACE_CLEAR_AT, dirt) * SURFACE_MUD_MATCH
    draw_rect(Rect2(0, HORIZON_Y, W, SURF - HORIZON_Y), Color(wc.r, wc.g, wc.b, clampf(a, 0.0, 1.0)))


# Su altında yavaşça kayan ince ışık çizgileri (sea.png sabit olduğu için hareket hissi verir)
func draw_sea_shimmer() -> void:
    for i in 12:
        var sx := fmod(float(i) * 117.0 + t * 14.0, W + 80.0) - 40.0
        var sy := SURF + 8.0 + float((i * 7) % 5) * 10.0
        var ln := 24.0 + float(i % 3) * 10.0
        draw_line(Vector2(sx, sy), Vector2(sx + ln, sy), Color(0.75, 0.95, 1.0, 0.15), 2.0)


# Kirli havada gökyüzü grileşir
func draw_smog() -> void:
    # Gökyüzü artık deniz kirlendikçe/temizlendikçe renk değiştirmez: hep açık hali görünür.
    pass


func draw_wave_line() -> void:
    var pts := PackedVector2Array()
    var x := 0.0
    while x <= W:
        pts.append(Vector2(x, SURF + sin(x * 0.05 + t * 2.0) * 2.0))
        x += 16.0
    draw_polyline(pts, Color(0.75, 0.92, 0.97, 0.8).lerp(Color(0.55, 0.47, 0.28, 0.9), dirt), 3.0)


func draw_underwater() -> void:
    var has_bg: bool = tex.get("background") != null
    if not has_bg:
        if tex.get("pier") == null:
            for lx in [95.0, 240.0, 318.0]:
                draw_rect(Rect2(lx, SURF, 26, SEABED - SURF), Color("4a3319"))
                draw_rect(Rect2(lx, SURF, 6, SEABED - SURF), Color("63451f"))
        for i in 12:
            var gx := 30.0 + float(i) * 105.0
            var sway := sin(t * 1.5 + float(i)) * 4.0
            draw_line(Vector2(gx, SEABED), Vector2(gx + sway, SEABED - 28.0 - float(i % 3) * 8.0), Color("2f8a4a"), 4.0)
            draw_line(Vector2(gx + 8.0, SEABED), Vector2(gx + 8.0 - sway, SEABED - 20.0), Color("3aa45a"), 3.0)
    # çamurlu su: dirt 1 -> kahverengi bulanık, 0 -> berrak mavi
    var mud := Color(MUD_COLOR.r, MUD_COLOR.g, MUD_COLOR.b, MUD_ALPHA * dirt)
    if sea_mud != null:
        draw_texture(sea_mud, Vector2(0.0, SEA_Y), mud)   # dalga tepeleri dahil
        var body_y := SEA_Y + float(SEA_EDGE_ROWS)
        draw_rect(Rect2(0, body_y, W, H - body_y), mud)
    else:
        draw_rect(Rect2(0, SURF, W, H - SURF), mud)
    # derinlere doğru yumuşak koyulaşma (sert çizgi bırakmaz)
    var deep_top := SURF + 90.0
    var dc0 := Color(0.2, 0.15, 0.06, 0.0)
    var dc1 := Color(0.2, 0.15, 0.06, 0.32 * dirt)
    draw_polygon(PackedVector2Array([Vector2(0, deep_top), Vector2(W, deep_top), Vector2(W, H), Vector2(0, H)]),
        PackedColorArray([dc0, dc0, dc1, dc1]))
    for it in items:
        var p: Vector2 = it["pos"]
        var r := float(it["rot"]) + sin(t + float(it["seed"])) * 0.25
        draw_item(str(it["type"]), p + Vector2(sin(t * 0.8 + float(it["seed"])) * 3.0, 0), r, 1.0, str(it.get("skin", "")))
    for tt in turtles:
        var p: Vector2 = tt["pos"]
        var v: Vector2 = tt["vel"]
        var bob := Vector2(0, sin(t * 1.5 + float(tt["seed"])) * 3.0)
        draw_turtle(p + bob, bool(tt["free"]), v.x if bool(tt["free"]) else -1.0)
    for f in fish:
        var p: Vector2 = f["pos"]
        draw_fish(p + Vector2(0, sin(t * 2.0 + float(f["seed"])) * 4.0), float(f["dir"]), float(f["size"]), f["col"], bool(f["tagged"]), str(f.get("skin", "")))
    for b in bubbles:
        draw_arc(b, 3.0, 0.0, TAU, 8, Color(1, 1, 1, 0.35).lerp(Color(0.5, 0.4, 0.2, 0.5), dirt), 1.5)
    # eşyaların önünde hafif bulanıklık
    draw_rect(Rect2(0, SURF, W, H - SURF), Color(0.30, 0.26, 0.12, 0.14 * dirt))


func draw_pier() -> void:
    if draw_tex_tl("pier", PIER_POS):
        if state == S_PLAY and near_pier():
            draw_rect(Rect2(230, PIER_POS.y + 15.0, 105, 105), Color("ffe27a"), false, 3.0)
            var tires: int = inv["tire"]
            var nets: int = inv["net"]
            txt_c("E: Dönüştür (%d lastik, %d ağ)" % [tires, nets], 280.0, PIER_POS.y + 8.0, 16, Color("ffe27a"))
        return
    # kodla çizilen iskele: PIER_POS.y'ye göre aşağı kaydırılır
    draw_set_transform(Vector2(0.0, PIER_POS.y - 100.0), 0.0, Vector2.ONE)
    draw_rect(Rect2(0, 215, 340, 60), Color("8a5a2b"))
    for i in range(0, 340, 34):
        draw_rect(Rect2(i, 215, 3, 60), Color("5e3a1a"))
    draw_rect(Rect2(0, 215, 340, 8), Color("a87238"))
    draw_rect(Rect2(25, 95, 8, 60), Color("5e3a1a"))
    draw_rect(Rect2(237, 95, 8, 60), Color("5e3a1a"))
    draw_rect(Rect2(15, 88, 240, 52), Color("2f6b3a"))
    draw_rect(Rect2(15, 88, 240, 52), Color("5e3a1a"), false, 4.0)
    txt_c("GERİ DÖNÜŞÜM", 135.0, 112.0, 18, Color("d8ffd8"))
    txt_c("İSTASYONU", 135.0, 132.0, 18, Color("d8ffd8"))
    var bin_cols := [Color("3fae4c"), Color("7b8590"), Color("3b78c9")]
    for i in 3:
        var bx := 30.0 + float(i) * 62.0
        draw_rect(Rect2(bx, 160, 52, 55), bin_cols[i])
        draw_rect(Rect2(bx - 3.0, 156, 58, 10), bin_cols[i].darkened(0.3))
        draw_rect(Rect2(bx + 18.0, 178, 16, 16), Color(1, 1, 1, 0.5))
    draw_rect(Rect2(235, 120, 95, 95), Color("9aa5ab"))
    draw_rect(Rect2(245, 132, 75, 26), Color("2c3e44"))
    draw_rect(Rect2(252, 140, 30, 8), Color("5fff7a") if fmod(t, 1.0) < 0.6 else Color("2f8a4a"))
    draw_rect(Rect2(250, 180, 65, 14), Color("2c3e44"))
    if state == S_PLAY and near_pier():
        draw_rect(Rect2(230, 115, 105, 105), Color("ffe27a"), false, 3.0)
        var tires2: int = inv["tire"]
        var nets2: int = inv["net"]
        txt_c("E: Dönüştür (%d lastik, %d ağ)" % [tires2, nets2], 280.0, 108.0, 16, Color("ffe27a"))
    for bx in [8.0, 310.0]:
        draw_rect(Rect2(bx, 192, 22, 40), Color("6b4a22"))
        ellipse(Vector2(bx + 11.0, 192), 11.0, 5.0, Color("8a6330"))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_boat() -> void:
    var by := SURF - 6.0 + sin(t * 2.0) * 2.0
    var o := Vector2(boat_x, by)
    var bt: Texture2D = tex.get("boat")
    if bt != null:
        # boat.png: alt-orta noktası su çizgisine gelir
        var sz := bt.get_size()
        if boat_flip:
            draw_set_transform(o + hud_off, 0.0, Vector2(-1.0, 1.0))
            draw_texture(bt, Vector2(-sz.x * 0.5, -sz.y + BOAT_SINK))
            draw_set_transform(hud_off, 0.0, Vector2.ONE)
        else:
            draw_texture(bt, o + Vector2(-sz.x * 0.5, -sz.y + BOAT_SINK))
        return
    var hull := PackedVector2Array([
        o + Vector2(-125, -42), o + Vector2(125, -42), o + Vector2(100, 0), o + Vector2(-95, 0)])
    draw_colored_polygon(hull, Color("2f7f73"))
    draw_rect(Rect2(o.x - 126.0, o.y - 46.0, 252.0, 10.0), Color("e6dcb4"))
    draw_rect(Rect2(o.x - 96.0, o.y - 8.0, 196.0, 8.0), Color("b0392b"))
    draw_rect(Rect2(o.x - 30.0, o.y - 98.0, 70.0, 56.0), Color("d6cfae"))
    draw_rect(Rect2(o.x - 30.0, o.y - 106.0, 70.0, 10.0), Color("2f7f73"))
    draw_rect(Rect2(o.x - 20.0, o.y - 90.0, 20.0, 18.0), Color("86c5d8"))
    draw_rect(Rect2(o.x + 50.0, o.y - 118.0, 6.0, 40.0), Color("8a8f96"))
    draw_rect(Rect2(o.x - 6.0, o.y - 62.0, 22.0, 24.0), Color("5a7a3a"))
    draw_circle(o + Vector2(5, -72), 9.0, Color("e0b090"))
    draw_rect(Rect2(o.x - 6.0, o.y - 84.0, 22.0, 8.0), Color("8a4a2a"))
    draw_line(o + Vector2(0, -56), rod_tip(), Color("7a4a22"), 3.0)
    draw_rect(Rect2(o.x + 62.0, o.y - 86.0, 40.0, 44.0), Color("b98348"))
    draw_rect(Rect2(o.x + 62.0, o.y - 86.0, 40.0, 44.0), Color("6b4a22"), false, 3.0)
    var bags := mini(collected / 2, 5)
    for i in bags:
        draw_circle(o + Vector2(108.0 + float(i % 3) * 10.0, -50.0 - float(i / 3) * 16.0), 11.0, Color("24323f"))
    draw_rect(Rect2(o.x + 125.0, o.y - 50.0, 24.0, 38.0), Color("5a6068"))


func draw_hook() -> void:
    var tip := rod_tip()
    var hp := hook_pos()
    var fishing := hook_mode == 1
    var line_col := Color(1.0, 0.82, 0.4, 0.95) if fishing else Color(1, 1, 1, 0.9)
    var hook_col := Color(1.0, 0.9, 0.6) if fishing else Color.WHITE
    draw_line(tip, hp, line_col, 2.0 if fishing else 1.5)
    var ht: Texture2D = tex.get("hook")
    if ht != null:
        # hook.png: üst-orta noktası olta ipinin bittiği yerdir
        draw_texture(ht, hp - Vector2(ht.get_size().x * 0.5, 0.0), hook_col)
    else:
        var hc := Color("ffd27a") if fishing else Color("d8d8d8")
        draw_arc(hp + Vector2(0, 7), 6.0, 0.0, PI, 8, hc, 2.5)
        draw_line(hp, hp + Vector2(0, 7), hc, 2.5)
    if bait_active:
        draw_bait_icon(hp + Vector2(0, 14), 22.0)
        draw_arc(hp, 22.0 + sin(t * 8.0) * 3.0, 0.0, TAU, 20, Color(1, 0.7, 0.3, 0.4), 2.0)
    if not carrying.is_empty():
        draw_item(str(carrying["type"]), hp + Vector2(0, 30), sin(t * 4.0) * 0.3, 1.0, str(carrying.get("skin", "")))
    if not carrying2.is_empty():
        draw_item(str(carrying2["type"]), hp + Vector2(16, 54), sin(t * 4.0 + 1.0) * 0.3, 1.0, str(carrying2.get("skin", "")))


func set_hud_anchor(anchor: Vector2) -> void:
    hud_xf = Transform2D(0.0, hud_off + anchor * (1.0 - HUD_SCALE)).scaled_local(Vector2(HUD_SCALE, HUD_SCALE))
    draw_set_transform_matrix(hud_xf)


func draw_hud() -> void:
    hud_off = Vector2(0.0, -HUD_RAISE)
    set_hud_anchor(Vector2.ZERO)   # sol grup: sol-üst köşeye göre küçülür
    txt("Toplanan Çöp", Vector2(40, 36), 22, Color.WHITE)
    var kinds := ["bottle", "can", "tire", "net"]
    for i in 4:
        var x := 40.0 + float(i) * 92.0
        panel(Rect2(x, 46, 84, 52))
        draw_item_hud(kinds[i], Vector2(x + 22.0, 72.0))
        txt(str(inv[kinds[i]]), Vector2(x + 44.0, 82.0), 24, Color.WHITE)
    txt("Eko-Kaynaklar", Vector2(430, 36), 22, Color.WHITE)
    panel(Rect2(430, 46, 84, 52))
    draw_gear(Vector2(452, 72))
    txt(str(gears), Vector2(474, 82), 24, Color.WHITE)
    panel(Rect2(522, 46, 84, 52))
    draw_plank(Vector2(544, 72))
    txt(str(planks), Vector2(566, 82), 24, Color.WHITE)
    panel(Rect2(614, 46, 84, 52), Color("a86a22"))
    draw_bait_icon(Vector2(636, 72), 30.0)
    txt(str(bait), Vector2(658, 82), 24, Color.WHITE)
    txt("Yem", Vector2(620, 116), 16, Color("ffb347"))

    draw_goals()
    set_hud_anchor(Vector2(W, 0.0))   # sağ grup: sağ-üst köşeye göre küçülür
    var clean := clampf(1.0 - dirt, 0.0, 1.0)
    txt_r("EKO-PUAN · Deniz %%%d" % int(round(clean * 100.0)), W - 40.0, 36.0, 22, Color.WHITE)
    panel(Rect2(W - 300.0, 46.0, 260.0, 52.0), Color("3fae4c"))
    draw_rect(Rect2(W - 294.0, 52.0, 248.0 * clean, 40.0), Color("3a9a46"))
    ellipse(Vector2(W - 276.0, 72.0), 11.0, 16.0, Color("6bff7a"))
    var mk_x := W - 294.0 + 248.0 * FISH_UNLOCK_CLEAN
    var mk_col := Color("7dff9a") if fishing_open else Color("ffe27a")
    draw_line(Vector2(mk_x, 50.0), Vector2(mk_x, 94.0), mk_col, 3.0)
    txt("BALIK", Vector2(mk_x - 20.0, 114.0), 14, mk_col)
    txt_c(str(score), W - 150.0, 82.0, 26, Color.WHITE)
    txt_r("Kalan Süre", W - 40.0, 140.0, 22, Color.WHITE)
    panel(Rect2(W - 200.0, 150.0, 160.0, 48.0))
    var secs := int(ceil(time_left))
    var tcol := Color.WHITE if time_left > 10.0 else Color("ff6a5a")
    txt_c("%d:%02d" % [secs / 60, secs % 60], W - 120.0, 184.0, 30, tcol)

    draw_coin_panel()
    hud_off = Vector2.ZERO
    hud_xf = Transform2D.IDENTITY
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    panel(Rect2(170, 636, 940, 76))
    if fishing_open and bait <= 0:
        txt_c("BALIK İÇİN YEM ŞART!  Boşluk: 2 şişe/teneke = 2 yem   (şu an yemin yok)", W / 2.0, 660.0, 17, Color("ffb347"))
    elif fishing_open:
        txt_c("Satılabilir (yeşil): %d - %d cm    Diğerleri denize bırakılır    Fiyat: %.2f para/cm" % [int(SELL_MIN), int(SELL_MAX), PRICE_PER_CM], W / 2.0, 660.0, 17, Color("9cff7a"))
    else:
        txt_c("BALIK TUTMA KİLİTLİ: deniz %%%d temiz olunca açılır (şu an %%%d)" % [int(round(FISH_UNLOCK_CLEAN * 100.0)), int(round(clean * 100.0))], W / 2.0, 660.0, 17, Color("ffb347"))
    var fish_lbl := "Sağ tık / G: Balık Oltası" if fishing_open else "Sağ tık / G: Balık (kilitli)"
    txt_c("Sol tık / F: Çöp Kancası    %s    Boşluk: Yem    E: Dönüştür    Ok / A-D: Tekne" % fish_lbl, W / 2.0, 684.0, 17, Color.WHITE)
    var rod_s := "MAX" if rod_lvl >= 3 else "%d para" % int(ROD_COST[rod_lvl])
    var boat_s := "MAX" if boat_lvl >= 3 else "%d para" % int(BOAT_COST[boat_lvl])
    txt_c("[1] Hız Sv.%d (2 dişli)  [2] Mıknatıs Sv.%d (2 tahta)  [3] Olta Sv.%d (%s)  [4] Tekne Sv.%d (%s)" % [lvl_speed, lvl_magnet, rod_lvl, rod_s, boat_lvl, boat_s], W / 2.0, 704.0, 17, Color("ffe27a"))


func draw_banner() -> void:
    if banner_t <= 0.0:
        return
    var a := clampf(banner_t, 0.0, 1.0)
    panel(Rect2(340, 262, 600, 100), Color(0.23, 0.47, 0.79, a), 0.9 * a)
    txt_c("BALIK TUTMA AÇILDI!", W / 2.0, 308.0, 36, Color(1.0, 0.89, 0.48, a))
    txt_c("Deniz maviye döndü!   Sağ tık / G: Balık Oltası (yem gerekir)", W / 2.0, 344.0, 20, Color(0.78, 0.94, 1.0, a))


func draw_coin_panel() -> void:
    panel(Rect2(W - 370.0, 150.0, 160.0, 48.0), Color("c9a227"))
    var cc := Vector2(W - 346.0, 174.0)
    if not draw_tex_fit("coin", cc, 30.0):
        draw_circle(cc, 12.0, Color("f2c230"))
        draw_arc(cc, 8.0, 0.0, TAU, 16, Color("a8820f"), 2.0)
    txt(str(coins), Vector2(W - 322.0, 184.0), 26, Color.WHITE)
    if rod_lvl >= 3:
        txt("ÇİFT KANCA", Vector2(W - 370.0, 218.0), 16, Color("9cff7a"))


func draw_goals() -> void:
    var lines := goal_lines()
    panel(Rect2(716, 40, 250, 34.0 + 22.0 * float(lines.size())))
    txt("SEVİYE %d / %d" % [level_idx + 1, LEVELS.size()], Vector2(728, 62), 18, Color("ffe27a"))
    for i in lines.size():
        var g: Array = lines[i]
        var done: bool = int(g[1]) >= int(g[2])
        var col := Color("7dff9a") if done else Color.WHITE
        txt("%s  %d/%d" % [g[0], mini(int(g[1]), int(g[2])), int(g[2])], Vector2(728, 86.0 + 22.0 * float(i)), 17, col)


func draw_button(r: Rect2, label: String, focused: bool, size: int = 26) -> void:
    draw_rect(r, Color(0.04, 0.09, 0.15, 0.96))
    draw_rect(r.grow(-3.0), Color("3d7ba3") if focused else Color("2d5a7a"))
    draw_rect(r, Color("a8fbff") if focused else Color("2bcde6"), false, 3.0)
    txt_c(label, r.get_center().x, r.get_center().y + float(size) * 0.35, size, Color.WHITE)


# Hazır menü görselinin üstüne seçili butonun parlaması
func draw_ui_highlights() -> void:
    var bs := ui_buttons()
    if state == S_SETTINGS:
        return
    if ui_focus >= 0 and ui_focus < bs.size():
        var r: Rect2 = bs[ui_focus]["rect"]
        draw_rect(r, Color(0.5, 1.0, 1.0, 0.16))
        draw_rect(r, Color("a8fbff"), false, 3.0)


func draw_menu_backdrop() -> void:
    draw_rect(Rect2(0, 0, W, H * 0.5), Color("0a3c58"))
    draw_rect(Rect2(0, H * 0.5, W, H * 0.5), Color("041a33"))
    panel(Rect2(250, 40, 780, 640), Color("3eeaf6"), 0.96)


func draw_continue_button(r: Rect2, focused: bool = false) -> void:
    var ok := can_continue()
    draw_rect(r, Color(0.04, 0.09, 0.15, 0.96))
    draw_rect(r.grow(-3.0), Color("3d7ba3") if (focused and ok) else (Color("2d5a7a") if ok else Color("2a3b4a")))
    draw_rect(r, Color("a8fbff") if focused else (Color("2bcde6") if ok else Color("4a6a80")), false, 3.0)
    var cx := r.get_center().x
    txt_c("KALDIĞIN YERDEN DEVAM ET" if ok else "KAYITLI İLERLEME", cx, r.position.y + 23.0, 21, Color.WHITE if ok else Color("9fb4c4"))
    txt_c(continue_info(), cx, r.position.y + 42.0, 15, Color("ffe27a") if ok else Color("9fb4c4"))


func draw_menu() -> void:
    if draw_tex_tl("menu_main", Vector2.ZERO):
        if not can_continue():
            draw_rect(MENU_CONT, Color(0.02, 0.05, 0.08, 0.62))   # kayıt yoksa / seviye bittiyse sönük
        if has_progress():
            txt_c(continue_info(), 640.0, 592.0, 17, Color("ffe27a") if can_continue() else Color("9fb4c4"))
        if t < menu_note_until:
            txt_c(menu_note, 640.0, 626.0, 18, Color("ffb347"))
        txt_c("En yüksek skorunuz: %d" % best, 640.0, 672.0, 22, Color.WHITE)
        draw_ui_highlights()
        return
    # görsel yoksa kodla çizilen yedek menü
    draw_menu_backdrop()
    txt_c("OCEAN GUARDIAN", W / 2.0, 135.0, 60, Color("ffe27a"))
    txt_c("COP31 · Antalya  |  Okyanus Farkındalık Oyunu", W / 2.0, 180.0, 22, Color("7df9ff"))
    txt_c("Her yıl milyonlarca ton plastik denize karışıyor.", W / 2.0, 240.0, 22, Color.WHITE)
    txt_c("Çöpü topla, dönüştür, deniz canlılarını kurtar!", W / 2.0, 272.0, 22, Color.WHITE)
    var bs := ui_buttons()
    for i in bs.size():
        if str(bs[i]["id"]) == "continue":
            draw_continue_button(bs[i]["rect"], i == ui_focus)
        else:
            draw_button(bs[i]["rect"], str(bs[i]["label"]), i == ui_focus)
    txt_c("En yüksek skorunuz: %d" % best, W / 2.0, 664.0 if has_progress() else 610.0, 22, Color.WHITE)


func draw_ui_screen() -> void:
    if state == S_HELP:
        if draw_tex_tl("menu_help", Vector2.ZERO):
            draw_ui_highlights()
        else:
            draw_help_fallback()
    else:
        draw_settings()


func draw_help_fallback() -> void:
    draw_menu_backdrop()
    txt_c("NASIL OYNANIR?", W / 2.0, 105.0, 46, Color("ffe27a"))
    txt_c("Ocean Guardian'ı Kurtarma Kılavuzu", W / 2.0, 140.0, 22, Color("7df9ff"))
    var y := 200.0
    var lines := [
        ["Ok / A-D: tekneyi hareket ettir", Color.WHITE],
        ["Sol tık / F: ÇÖP KANCASI  (çöp ve ağa dolanmış kaplumbağa)", Color.WHITE],
        ["Sağ tık / G: BALIK OLTASI  (deniz %50 temizlenince açılır, YEM ŞART)", Color("8fc4ff")],
        ["Boşluk: 2 şişe/teneke = 2 yem  (yemsiz balık tutulmaz)", Color.WHITE],
        ["E: iskelede lastik → dişli, ağ → tahta    1-4: yükseltmeler", Color.WHITE],
        ["Tuttuğun balık tartılır: yeşil bölgedeyse S ile sat, değilse B ile bırak", Color.WHITE],
        ["Para ile Güçlü Olta (3) ve Tekne Motoru (4) al. Olta Sv.3: 2 çöp!", Color("ffe27a")],
        ["Görevleri süre bitmeden tamamla, deniz kahverengiden maviye dönsün!", Color("c8f0ff")],
        ["ESC: duraklat menüsü", Color("c8f0ff")],
    ]
    for ln in lines:
        txt_c(str(ln[0]), W / 2.0, y, 20, ln[1])
        y += 36.0
    var bs := ui_buttons()
    draw_button(bs[0]["rect"], str(bs[0]["label"]), true)


func draw_settings() -> void:
    var art := draw_tex_tl("menu_settings", Vector2.ZERO)
    if not art:
        # görsel yoksa kodla çizilen yedek ekran
        draw_menu_backdrop()
        txt_c("AYARLAR", W / 2.0, 105.0, 46, Color("ffe27a"))
        txt_c("Deniz Kurtarma Ekipmanı Kontrol Paneli", W / 2.0, 150.0, 22, Color("c8f0ff"))
        txt_c("SES AYARLARI", W / 2.0, 215.0, 24, Color("ffe27a"))
        txt_c("GÖRÜNTÜ AYARLARI", W / 2.0, 395.0, 24, Color("ffe27a"))
        for b in ui_buttons():
            if str(b["id"]) != "vol_slider":
                draw_button(b["rect"], str(b["label"]), false, 20)
    # ses kaydırıcısı
    draw_rect(SET_TRACK, Color("1f3647"))
    draw_rect(SET_TRACK, Color("142532"), false, 2.0)
    var fw := SET_TRACK.size.x * float(volume) / 10.0
    if fw > 0.0:
        var fc := Color("7c8a96") if muted else Color("3ea0e6")
        draw_rect(Rect2(SET_TRACK.position + Vector2(1.0, 1.0), Vector2(maxf(fw - 1.0, 0.0), SET_TRACK.size.y - 2.0)), fc)
        draw_rect(Rect2(SET_TRACK.position + Vector2(1.0, 1.0), Vector2(maxf(fw - 1.0, 0.0), 5.0)), fc.lightened(0.25))
    var ky := SET_TRACK.position.y + SET_TRACK.size.y / 2.0
    var kr := Rect2(SET_TRACK.position.x + fw - 13.0, ky - 22.0, 26.0, 44.0)
    draw_rect(kr, Color("e1e8ee"))
    draw_rect(Rect2(kr.position + Vector2(3.0, 3.0), kr.size - Vector2(6.0, 6.0)), Color("a9b4be"))
    draw_rect(kr, Color("5b6b78"), false, 2.0)
    # aktif seçimi göster: pasif olan karartılır, aktif olanın etrafına altın çerçeve çizilir
    var snd_on := SET_MUTE if muted else SET_UNMUTE
    var snd_off := SET_UNMUTE if muted else SET_MUTE
    var dsp_on := SET_FS if fullscreen else SET_WIN
    var dsp_off := SET_WIN if fullscreen else SET_FS
    for r in [snd_off, dsp_off]:
        draw_rect(r, Color(0.0, 0.05, 0.1, 0.45))
    for r in [snd_on, dsp_on]:
        draw_rect(r, Color("ffe27a"), false, 3.0)
    # klavye / fare odağı (satır bazlı)
    var fr := Rect2()
    match ui_focus:
        0:
            fr = SET_VOL_DN.merge(SET_VOL_UP).grow(4.0)
        1:
            fr = SET_UNMUTE.merge(SET_MUTE).grow(5.0)
        2:
            fr = SET_FS.merge(SET_WIN).grow(5.0)
        3:
            fr = SET_BACK.grow(3.0)
    if fr.size.x > 0.0:
        draw_rect(fr, Color(0.5, 1.0, 1.0, 0.10))
        draw_rect(fr, Color("a8fbff"), false, 3.0)


# Duraklat kartı (assets/pause_panel.png: çerçeve + başlık + 4 hazır buton; butonlar tıklama alanıdır)
const PAUSE_TL := Vector2(290.0, 70.0)
const PAUSE_BTNS := [
    Rect2(471.0, 233.0, 339.0, 71.0),   # DEVAM ET
    Rect2(471.0, 317.0, 339.0, 70.0),   # NASIL OYNANIR?
    Rect2(471.0, 402.0, 339.0, 69.0),   # AYARLAR
    Rect2(471.0, 485.0, 339.0, 70.0),   # ANA MENÜ
]


func draw_pause() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.03, 0.08, 0.62))
    if draw_tex_tl("pause_panel", PAUSE_TL):
        draw_ui_highlights()
        return
    panel(Rect2(450.0, 120.0, 380.0, 430.0), Color("3eeaf6"), 0.95)
    txt_c("DURAKLATILDI", W / 2.0, 178.0, 38, Color("ffe27a"))
    var bs := ui_buttons()
    for i in bs.size():
        draw_button(bs[i]["rect"], str(bs[i]["label"]), i == ui_focus)
    txt_c("ESC: Devam et", W / 2.0, 528.0, 18, Color("c8f0ff"))


func draw_gear_button() -> void:
    var hov := GEAR_BTN.has_point(get_global_mouse_position())
    panel(GEAR_BTN, Color("3eeaf6") if hov else Color("3a4f78"), 0.92)
    var c := GEAR_BTN.get_center() + Vector2(0.0, -6.0)
    var col := Color("c8f0ff")
    for i in 8:
        var a := TAU * float(i) / 8.0
        draw_circle(c + Vector2(cos(a), sin(a)) * 14.0, 4.0, col)
    draw_circle(c, 11.0, col)
    draw_circle(c, 5.0, Color("1c2740"))
    txt_c("ESC", c.x, GEAR_BTN.end.y - 7.0, 13, col)


# ---- Ortak kart stili: tüm kartlar duraklat kartıyla aynı mercanlı turkuaz çerçeveyi kullanır.
# Çerçeveler gen_panels.py ile pause_panel.png'den üretilir (başlık bandı: panel içi y≈45..145, iç panel y≈150..H-72).
const CARD_TITLE := Color("ffc86b")    # başlık rengi (DURAKLATILDI ile aynı)
const CARD_GOLD := Color("ffc86b")
const CARD_SOFT := Color("c8f0ff")
const CARD_TEXT := Color("f4fbff")


# Çerçevedeki yazısız butonun üzerine etiket ve parıltı çizer (nabız = Enter/Boşluk ile de basılabilir)
func draw_card_button(r: Rect2, label: String, size: int = 36, pulse: bool = true) -> void:
    var hot := r.has_point(get_global_mouse_position())
    var a := 0.5 + 0.5 * sin(t * 4.0) if pulse else 0.0
    if hot:
        draw_rect(r, Color(0.5, 1.0, 1.0, 0.20))
        draw_rect(r, Color("a8fbff"), false, 3.0)
    elif pulse:
        draw_rect(r, Color(0.5, 1.0, 1.0, 0.05 + 0.08 * a))
        draw_rect(r, Color(0.66, 0.98, 1.0, 0.35 + 0.45 * a), false, 3.0)
    txt_fit(label, r.get_center().x, r.get_center().y + float(size) * 0.36, size, r.size.x - 40.0, Color.WHITE)


# Hedef satırı: simge + "Ad: sayı" (seviye başlangıç ve süre doldu kartlarında ortak)
func draw_goal_row(gname: String, text: String, x_icon: float, cy: float, max_w: float, show_icon_after: bool) -> void:
    var shell := "intro_shell_pink" if gname.begins_with("Kaplumba") else "intro_shell_blue"
    draw_tex(shell, Vector2(x_icon, cy))
    var sz := 30
    while sz > 14 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > max_w:
        sz -= 1
    txt(text, Vector2(x_icon + 32.0, cy + 10.0), sz, CARD_TEXT)
    if not show_icon_after:
        return
    var ex := x_icon + 32.0 + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + 28.0
    if gname.begins_with("Çöp"):
        draw_tex("intro_bin", Vector2(ex, cy))
    elif gname.begins_with("Kaplumba"):
        draw_tex("intro_turtle", Vector2(ex + 8.0, cy))
    else:
        if not draw_tex_fit("fish_lufer", Vector2(ex, cy), 40.0):
            draw_tex_fit("fish", Vector2(ex, cy), 40.0)


# Seviye başlangıç kartı (assets/intro_panel.png 720x640; başlık, görevler ve BAŞLA etiketi kodla çizilir)
const INTRO_TL := Vector2(280.0, 40.0)
const INTRO_BTN := Rect2(500.0, 514.0, 280.0, 72.0)   # çerçevedeki yazısız buton


func draw_intro() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.45))
    if not draw_tex_tl("intro_panel", INTRO_TL):
        draw_intro_fallback()
        return
    var cx := 640.0
    txt_fit("SEVİYE %d / %d" % [level_idx + 1, LEVELS.size()], cx, 152.0, 44, 440.0, CARD_TITLE)
    txt_fit(str(lvl()["name"]), cx, 226.0, 32, 560.0, CARD_SOFT)
    var lines := goal_lines()
    var n := lines.size()
    var sp := 60.0 if n <= 2 else 50.0
    var cy := 322.0 - float(n - 1) * sp * 0.5
    for g in lines:
        var gname := str(g[0])
        draw_goal_row(gname, "•  %s: %d" % [gname, int(g[2])], 410.0, cy, 330.0, true)
        cy += sp
    txt_c("Süre: %d saniye" % int(lvl()["time"]), cx, 444.0, 28, Color("d8ecf8"))
    if fishing_open:
        txt_fit("Sağ tık / G: balık tut. Yeşilse S (sat), değilse B (bırak).", cx, 482.0, 19, 590.0, Color("ffdf3a"))
    else:
        txt_fit("Balık oltası (G / sağ tık) deniz %50 temizlenince açılır.", cx, 482.0, 19, 590.0, Color("ffdf3a"))
    draw_card_button(INTRO_BTN, "BAŞLA")


func draw_intro_fallback() -> void:
    panel(Rect2(330, 140, 620, 420), Color("3fae4c"), 0.82)
    txt_c("SEVİYE %d / %d" % [level_idx + 1, LEVELS.size()], W / 2.0, 200.0, 38, Color("9cff7a"))
    txt_c(str(lvl()["name"]), W / 2.0, 245.0, 28, Color("ffe27a"))
    txt_c("Görevler", W / 2.0, 305.0, 24, Color.WHITE)
    var lines := goal_lines()
    var y := 345.0
    for g in lines:
        txt_c("•  %s: %d" % [g[0], int(g[2])], W / 2.0, y, 22, Color.WHITE)
        y += 34.0
    txt_c("Süre: %d saniye" % int(lvl()["time"]), W / 2.0, y + 8.0, 22, Color("c8f0ff"))
    if fishing_open:
        txt_c("Sağ tık / G: balık tut. Yeşilse S (sat), değilse B (bırak).", W / 2.0, y + 44.0, 17, Color("ffb347"))
    else:
        txt_c("Balık oltası (G / sağ tık) deniz %50 temizlenince açılır.", W / 2.0, y + 44.0, 17, Color("ffb347"))
    var a := 0.55 + 0.45 * sin(t * 4.0)
    txt_c("ENTER veya BOŞLUK: Başla", W / 2.0, 525.0, 26, Color(1, 1, 1, a))


# Seviye tamamlandı kartı (assets/done_panel.png 720x640; yazılar kodla çizilir, DEVAM etiketi butonun üstüne)
const DONE_TL := Vector2(280.0, 40.0)
const DONE_BTN := Rect2(500.0, 514.0, 280.0, 72.0)


func draw_level_done() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.45))
    if not draw_tex_tl("done_panel", DONE_TL):
        draw_level_done_fallback()
        return
    var cx := 640.0
    txt_fit("SEVİYE %d TAMAMLANDI!" % (level_idx + 1), cx, 150.0, 42, 450.0, CARD_TITLE)
    txt_c("Süre bonusu: +%d puan" % last_bonus, cx, 222.0, 26, CARD_GOLD)
    var pct := int(round(float(level_idx + 1) / float(LEVELS.size()) * 100.0))
    txt_c("Deniz temizliği: %%%d" % pct, cx, 260.0, 26, Color("eaf6ff"))
    txt_c("Biliyor muydun?", cx, 326.0, 30, CARD_GOLD)
    txt_wrap(str(lvl()["fact"]), cx, 366.0, 560.0, 23, CARD_TEXT)
    draw_card_button(DONE_BTN, "DEVAM")


func draw_level_done_fallback() -> void:
    panel(Rect2(300, 100, 680, 450), Color("3fae4c"), 0.82)
    txt_c("SEVİYE %d TAMAMLANDI!" % (level_idx + 1), W / 2.0, 160.0, 38, Color("9cff7a"))
    txt_c("Süre bonusu: +%d puan" % last_bonus, W / 2.0, 205.0, 22, Color("ffe27a"))
    var pct := int(round(float(level_idx + 1) / float(LEVELS.size()) * 100.0))
    txt_c("Deniz temizliği: %%%d" % pct, W / 2.0, 240.0, 22, Color("c8f0ff"))
    txt_c("Biliyor muydun?", W / 2.0, 310.0, 26, Color("ffe27a"))
    txt_wrap(str(lvl()["fact"]), W / 2.0, 355.0, 600.0, 22, Color.WHITE)
    var a := 0.55 + 0.45 * sin(t * 4.0)
    txt_c("ENTER veya BOŞLUK: Sonraki seviye", W / 2.0, 515.0, 26, Color(1, 1, 1, a))


# Tebrikler kartı (assets/win_panel.png: mercanlı çerçeve + TEKRAR OYNA / MENÜ butonları; yazılar kodla çizilir)
const WIN_TL := Vector2(228.0, 14.0)
const WIN_BTN_AGAIN := Rect2(460.0, 616.0, 173.0, 51.0)   # çerçevedeki hazır TEKRAR OYNA butonu
const WIN_BTN_MENU := Rect2(656.0, 616.0, 174.0, 51.0)    # çerçevedeki hazır MENÜ butonu


# Kalın altın başlık: koyu kontur + altın dolgu
func txt_gold(s: String, cx: float, y: float, size: int) -> void:
    var dark := Color("5a3708")
    for o in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3), Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2), Vector2(0, 5)]:
        draw_string(font, Vector2(cx - 500.0 + o.x, y + o.y), s, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, size, dark)
    draw_string(font, Vector2(cx - 500.0, y + 2.0), s, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, size, Color("c88a1e"))
    draw_string(font, Vector2(cx - 500.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, 1000.0, size, Color("f6d36a"))


func draw_win() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.5))
    if not draw_tex_tl("win_panel", WIN_TL):
        draw_win_fallback()
        return
    var cx := 649.0
    var gold := Color("f2c96b")
    var title := "Çırak Temizlikçi"
    if score >= 700:
        title = "Okyanus Kahramanı"
    elif score >= 450:
        title = "Deniz Koruyucusu"
    txt_gold("TEBRİKLER!", cx, 231.0, 54)
    txt_fit("Deniz tertemiz, okyanus nefes alıyor!", cx, 257.0, 24, 520.0, Color("f4fbff"))
    txt_c(title, cx, 296.0, 28, gold)
    txt_c("Eko-Puan: %d" % score, cx, 328.0, 28, Color.WHITE)
    if new_best:
        txt_c("YENİ REKOR!", cx, 355.0, 20, Color("ee8a6e"))
    else:
        txt_c("En yüksek: %d" % best, cx, 355.0, 20, Color("c8f0ff"))
    txt_fit("•  Toplanan çöp: %d    •  Kurtarılan kaplumbağa: %d    •  Bırakılan balık: %d" % [collected, rescued, released], cx, 384.0, 19, 540.0, Color("eaf6ff"))
    txt_c("Biliyor muydun?", cx, 450.0, 25, gold)
    txt_wrap(str(lvl()["fact"]), cx, 483.0, 540.0, 19, Color("f4fbff"))
    txt_fit("Her küçük adım okyanusu değiştirir.", cx, 601.0, 22, 520.0, Color("f5dc9a"))
    # Butonlar çerçevede hazır; üzerine gelince parlar
    var mp := get_global_mouse_position()
    for r in [WIN_BTN_AGAIN, WIN_BTN_MENU]:
        if r.has_point(mp):
            draw_rect(r.grow(-2.0), Color(1.0, 0.9, 0.5, 0.22))
            draw_rect(r, Color(1.0, 0.88, 0.45, 0.85), false, 3.0)


func draw_win_fallback() -> void:
    panel(Rect2(300, 60, 680, 600), Color("3fae4c"), 0.84)
    txt_c("TEBRİKLER!", W / 2.0, 125.0, 50, Color("9cff7a"))
    txt_c("Deniz tertemiz, okyanus nefes alıyor!", W / 2.0, 168.0, 24, Color("c8f0ff"))
    var title := "Çırak Temizlikçi"
    if score >= 700:
        title = "Okyanus Kahramanı"
    elif score >= 450:
        title = "Deniz Koruyucusu"
    txt_c(title, W / 2.0, 220.0, 30, Color("ffe27a"))
    txt_c("Eko-Puan: %d" % score, W / 2.0, 268.0, 26, Color.WHITE)
    if new_best:
        txt_c("YENİ REKOR!", W / 2.0, 298.0, 20, Color("6bff7a"))
    else:
        txt_c("En yüksek: %d" % best, W / 2.0, 298.0, 20, Color("c8f0ff"))
    txt_c("Toplanan çöp: %d     Kurtarılan kaplumbağa: %d     Bırakılan balık: %d" % [collected, rescued, released], W / 2.0, 340.0, 20, Color.WHITE)
    txt_c("Biliyor muydun?", W / 2.0, 405.0, 24, Color("ffe27a"))
    txt_wrap(str(lvl()["fact"]), W / 2.0, 443.0, 600.0, 20, Color.WHITE)
    txt_c("Her küçük adım okyanusu değiştirir.", W / 2.0, 570.0, 22, Color("9cff7a"))
    txt_c("R / Enter: Yeniden oyna    M: Menü", W / 2.0, 622.0, 22, Color("ffe27a"))


# Süre doldu kartı (assets/over_panel.png 760x640; yazılar, simgeler ve buton etiketi kodla çizilir). Tüm seviyelerde aynı kart.
const OVER_TL := Vector2(260.0, 40.0)
const OVER_BTN := Rect2(420.0, 514.0, 440.0, 72.0)


func draw_end_screen() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.45))
    if not draw_tex_tl("over_panel", OVER_TL):
        draw_end_fallback()
        return
    var cx := 640.0
    txt_fit("SÜRE DOLDU!", cx, 152.0, 46, 440.0, CARD_TITLE)
    txt_fit("Seviye %d görevleri tamamlanamadı" % (level_idx + 1), cx, 220.0, 27, 620.0, CARD_SOFT)
    var lines := goal_lines()
    var n := lines.size()
    var sp := 48.0 if n <= 2 else 42.0
    var cy := 282.0 if n <= 2 else 268.0
    for g in lines:
        var gname := str(g[0])
        var line := "•  %s: %d / %d" % [gname, mini(int(g[1]), int(g[2])), int(g[2])]
        var sz := 30
        while sz > 14 and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > 360.0:
            sz -= 1
        var tw := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
        var x0 := cx - (54.0 + tw) * 0.5
        draw_goal_row(gname, line, x0 + 18.0, cy, 360.0, false)
        cy += sp
    txt_c("Eko-Puan: %d" % score, cx, 428.0, 30, Color("e8f0fa"))
    txt_fit("Her denemede deniz biraz daha temizlenir, bir daha dene!", cx, 474.0, 22, 640.0, CARD_GOLD)
    draw_card_button(OVER_BTN, "SEVİYEYİ TEKRAR DENE", 32)


func draw_end_fallback() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.6))
    panel(Rect2(340, 140, 600, 420), Color("c0392b"), 0.84)
    txt_c("Süre Doldu!", W / 2.0, 200.0, 40, Color("ff8a7a"))
    txt_c("Seviye %d görevleri tamamlanamadı" % (level_idx + 1), W / 2.0, 245.0, 24, Color("ffe27a"))
    var y := 305.0
    for g in goal_lines():
        var done: bool = int(g[1]) >= int(g[2])
        txt_c("%s: %d / %d" % [g[0], mini(int(g[1]), int(g[2])), int(g[2])], W / 2.0, y, 22, Color("7dff9a") if done else Color.WHITE)
        y += 34.0
    txt_c("Eko-Puan: %d" % score, W / 2.0, y + 20.0, 24, Color.WHITE)
    txt_c("Her denemede deniz biraz daha temizlenir, bir daha dene!", W / 2.0, 470.0, 18, Color("c8f0ff"))
    txt_c("R / Enter: Seviyeyi tekrar dene    M: Menü", W / 2.0, 520.0, 22, Color("ffe27a"))


# ---------------------------------------------------------------- balık boyu ölçümü ekranı
# Tasarım görselinin koordinatları (yaklaşık 1240x864) 0.78 ölçekle ekrana yerleştirilir.
const WG_S := 0.78
const WG_O := Vector2(240.0, 42.0)
const WG_REF := Vector2(100.0, 35.0)
const RULER_MAX := 50.0   # cetvel 0 - 50 cm


func wg(ix: float, iy: float) -> Vector2:
    return WG_O + (Vector2(ix, iy) - WG_REF) * WG_S


func wr(x1: float, y1: float, x2: float, y2: float) -> Rect2:
    return Rect2(wg(x1, y1), Vector2(x2 - x1, y2 - y1) * WG_S)


func weigh_btn_b() -> Rect2:
    return wr(624.0, 518.0, 907.0, 612.0)


func weigh_btn_s() -> Rect2:
    return wr(624.0, 624.0, 907.0, 722.0)


# cm değerinin cetvel üzerindeki x konumu (tasarım koordinatı)
func ruler_x(cm: float) -> float:
    return 195.0 + clampf(cm, 0.0, RULER_MAX) * 14.2


func draw_octopus(p: Vector2, s: float) -> void:
    var body := Color("b5483f")
    var dark := Color("8a2f2a")
    for i in 6:
        var ox := (float(i) - 2.5) * 11.0 * s
        draw_line(p + Vector2(ox * 0.6, 14.0 * s), p + Vector2(ox * 1.5, 44.0 * s), dark, 5.0 * s)
        draw_line(p + Vector2(ox * 1.5, 44.0 * s), p + Vector2(ox * 1.5 + 8.0 * s, 52.0 * s), dark, 5.0 * s)
    ellipse(p, 32.0 * s, 28.0 * s, body)
    draw_circle(p + Vector2(-11.0 * s, 2.0 * s), 6.0 * s, Color.WHITE)
    draw_circle(p + Vector2(11.0 * s, 2.0 * s), 6.0 * s, Color.WHITE)
    draw_circle(p + Vector2(-10.0 * s, 4.0 * s), 3.0 * s, Color.BLACK)
    draw_circle(p + Vector2(12.0 * s, 4.0 * s), 3.0 * s, Color.BLACK)


func draw_dolphin(p: Vector2, s: float) -> void:
    var body := Color("5aa0e0")
    var belly := Color("bfe0ff")
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(-34.0, 26.0) * s, p + Vector2(-20.0, 0.0) * s, p + Vector2(0.0, -20.0) * s,
        p + Vector2(22.0, -22.0) * s, p + Vector2(44.0, -12.0) * s, p + Vector2(38.0, -6.0) * s,
        p + Vector2(16.0, 6.0) * s, p + Vector2(0.0, 22.0) * s, p + Vector2(-20.0, 34.0) * s]), body)
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(-34.0, 26.0) * s, p + Vector2(-24.0, 38.0) * s, p + Vector2(-44.0, 44.0) * s]), body.darkened(0.15))
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(2.0, -20.0) * s, p + Vector2(-6.0, -34.0) * s, p + Vector2(10.0, -20.0) * s]), body.darkened(0.1))
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(38.0, -6.0) * s, p + Vector2(16.0, 6.0) * s, p + Vector2(0.0, 22.0) * s, p + Vector2(8.0, 8.0) * s]), belly)
    draw_circle(p + Vector2(30.0, -14.0) * s, 2.5 * s, Color.BLACK)


func draw_weigh_btn(r: Rect2, label: String, icon: String, enabled: bool, warn_col: bool) -> void:
    var a := 1.0 if enabled else 0.5
    var hot := enabled and r.has_point(get_global_mouse_position())
    var fill := Color(0.2, 0.33, 0.52, a)
    if hot:
        fill = Color(0.27, 0.44, 0.68, a)
    draw_rect(r, fill)
    draw_rect(r, Color(0.96, 0.83, 0.42, a), false, 3.0)
    var ic := Vector2(r.position.x + 36.0, r.get_center().y)
    if icon == "release":
        var ac := Color(0.82, 0.62, 0.3, a)
        draw_line(ic + Vector2(-12.0, 12.0), ic + Vector2(12.0, -12.0), ac, 5.0)
        draw_colored_polygon(PackedVector2Array([ic + Vector2(16.0, -16.0), ic + Vector2(2.0, -14.0), ic + Vector2(14.0, -2.0)]), ac)
        draw_colored_polygon(PackedVector2Array([ic + Vector2(-16.0, 16.0), ic + Vector2(-2.0, 14.0), ic + Vector2(-14.0, 2.0)]), ac)
    else:
        if not draw_tex("coin", ic, 0.0, Vector2(1.1, 1.1), Color(1, 1, 1, a)):
            draw_circle(ic, 15.0, Color(0.96, 0.75, 0.15, a))
            draw_circle(ic, 10.0, Color(1.0, 0.86, 0.35, a))
    var tc := Color(1.0, 1.0, 1.0, a)
    if warn_col:
        tc = Color(1.0, 0.62, 0.56, a)
    var x0 := ic.x + 26.0
    var x1 := r.end.x - 8.0
    txt_fit(label, (x0 + x1) * 0.5, r.get_center().y + 8.0, 24, x1 - x0, tc)


func draw_weigh() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.07, 0.12, 0.7))
    var cm := float(weigh_f["cm"])
    var done := weigh_t >= WEIGH_TIME
    var prot := in_protected(cm)
    var red := done and prot   # denize bırakılacak boy: cetvel KIRMIZI
    var shown := cm
    if not done:
        shown = cm * (1.0 - exp(-weigh_t * 3.2)) + sin(weigh_t * 18.0) * 1.5 * exp(-weigh_t * 2.0)
    shown = clampf(shown, 0.0, RULER_MAX)
    var cx := wg(612.0, 0.0).x
    var gold_txt := Color("f0d078")
    var sec := Color("2c5886")
    var sec_b := Color("3f78b0")

    # dış çerçeve (neon turkuaz)
    var outer := wr(100.0, 35.0, 1125.0, 850.0)
    draw_rect(outer.grow(6.0), Color(0.18, 0.82, 0.91, 0.22))
    draw_rect(outer, Color("0b1a2e"))
    draw_rect(outer, Color("2fd0e8"), false, 4.0)

    # başlık
    txt_gold("BALIK BOYU ÖLÇÜMÜ", cx, wg(0.0, 140.0).y, 46)
    txt_fit("Deniz Kurtarma Ekipmanı Kontrol Paneli", cx, wg(0.0, 195.0).y, 26, 500.0, Color("b4c0e0"))
    draw_dolphin(wg(200.0, 112.0), 0.8)
    draw_tex_fit("fish_levrek", wg(1030.0, 122.0), 70.0)

    # ---- ölçüm kontrolü (cetvel)
    draw_rect(wr(140.0, 228.0, 1082.0, 432.0), sec)
    draw_rect(wr(140.0, 228.0, 1082.0, 432.0), sec_b, false, 3.0)
    txt_fit("ÖLÇÜM KONTROLÜ", cx, wg(0.0, 275.0).y, 28, 400.0, gold_txt)

    var rl := wr(165.0, 352.0, 930.0, 408.0)
    var body := Color("c9ced3")
    var ink := Color("3b4047")
    if red:
        body = Color("e04848")
        ink = Color("3d0808")
    draw_rect(rl, body)
    draw_rect(Rect2(rl.position.x, rl.end.y - 5.0, rl.size.x, 5.0), body.darkened(0.25))
    # yeşil satılabilir bölge
    var gx1 := wg(ruler_x(SELL_MIN), 0.0).x
    var gx2 := wg(ruler_x(SELL_MAX), 0.0).x
    draw_rect(Rect2(gx1, rl.position.y, gx2 - gx1, rl.size.y), Color(0.25, 0.85, 0.3, 0.75))
    draw_rect(rl, ink.lightened(0.25), false, 2.0)
    for i in range(0, 51):
        var tx := wg(ruler_x(float(i)), 0.0).x
        var th := 6.0
        if i % 10 == 0:
            th = 15.0
        elif i % 5 == 0:
            th = 11.0
        draw_line(Vector2(tx, rl.position.y), Vector2(tx, rl.position.y + th), ink, 1.5)
    for i in range(0, 6):
        var lx := wg(ruler_x(float(i * 10)), 0.0).x
        draw_string(font, Vector2(lx - 40.0, rl.end.y - 9.0), "%d cm" % (i * 10), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 15, ink)

    # balık simgesi cetvel üzerinde ölçülen boya kayar
    var mx := wg(ruler_x(shown), 0.0).x
    var mw := 122.0 * WG_S
    var mh := 74.0 * WG_S
    var mrect := Rect2(mx - mw * 0.5, rl.position.y - mh + 13.0 * WG_S, mw, mh)
    draw_rect(mrect, Color("1f6f8b"))
    draw_rect(mrect, Color("ff6a6a") if red else Color("e8d27a"), false, 3.0)
    var skin := str(weigh_f.get("skin", ""))
    if not draw_tex(skin, mrect.get_center(), 0.0, Vector2(0.8, 0.8)):
        ellipse(mrect.get_center(), 24.0, 11.0, weigh_f["col"])

    # durum kutusu (sağ üst)
    var bx := wr(942.0, 288.0, 1060.0, 406.0)
    var bfill := Color("7a5a22")
    var bline := Color("e8c864")
    var blabel := "SAĞLIKLI"
    if not done:
        bfill = Color("2d4a75")
        bline = Color("7fa6d6")
        blabel = "ÖLÇÜLÜYOR"
    elif prot:
        bfill = Color("8f2a2a")
        bline = Color("ff8a7a")
        blabel = "KORUNMALI"
    draw_rect(bx, bfill)
    draw_rect(bx, bline, false, 3.0)
    var bc := bx.get_center() + Vector2(0.0, -12.0)
    if not done:
        txt_c("...", bc.x, bc.y + 12.0, 36, Color.WHITE)
    elif prot:
        draw_line(bc + Vector2(-15.0, -15.0), bc + Vector2(15.0, 15.0), Color("ffe0d8"), 6.0)
        draw_line(bc + Vector2(-15.0, 15.0), bc + Vector2(15.0, -15.0), Color("ffe0d8"), 6.0)
    else:
        draw_polyline(PackedVector2Array([bc + Vector2(-16.0, 0.0), bc + Vector2(-5.0, 12.0), bc + Vector2(16.0, -14.0)]), Color("f6e6a8"), 6.0)
    txt_fit(blabel, bx.get_center().x, bx.end.y - 12.0, 15, bx.size.x - 8.0, Color.WHITE)

    # ---- ölçüm sonuçları ve aksiyonlar
    draw_rect(wr(140.0, 445.0, 1082.0, 748.0), sec)
    draw_rect(wr(140.0, 445.0, 1082.0, 748.0), sec_b, false, 3.0)
    txt_fit("ÖLÇÜM SONUÇLARI VE AKSİYONLAR", cx, wg(0.0, 495.0).y, 26, 600.0, gold_txt)

    # süs: küçük balıklar ve ahtapot
    draw_tex("fish_hamsi", wg(215.0, 612.0), 0.0, Vector2(0.45, 0.45), Color(0.8, 0.8, 1.0))
    draw_tex("fish_levrek", wg(292.0, 622.0), 0.0, Vector2(0.55, 0.55), Color(1.0, 0.85, 0.6))
    draw_tex("fish_lufer", wg(200.0, 668.0), 0.0, Vector2(0.6, 0.6), Color(0.7, 1.0, 0.8))
    draw_tex("fish_hamsi", wg(275.0, 697.0), 0.0, Vector2(0.4, 0.4), Color(1.0, 0.7, 0.5))
    draw_tex("fish_lufer", wg(1040.0, 585.0), 0.0, Vector2(-0.5, 0.5), Color(0.7, 0.9, 1.0))
    draw_tex("fish_hamsi", wg(940.0, 628.0), 0.0, Vector2(-0.4, 0.4), Color(1.0, 0.8, 0.5))
    draw_octopus(wg(1000.0, 655.0), 0.78)

    var rb := wr(330.0, 520.0, 610.0, 720.0)
    draw_rect(rb, Color("1b3050"))
    draw_rect(rb, Color("2d4a75"), false, 3.0)
    var rcx := rb.get_center().x
    txt_c("%d cm" % int(round(shown)), rcx, rb.position.y + 70.0, 56, Color("ff9a9a") if red else Color.WHITE)
    if not done:
        txt_fit("Ölçülüyor...", rcx, rb.position.y + 112.0, 22, rb.size.x - 14.0, Color("c8f0ff"))
    elif prot:
        var why := "Yavru" if cm < SELL_MIN else "Üreme Çağında"
        txt_fit("Durum: %s" % why, rcx, rb.position.y + 112.0, 22, rb.size.x - 14.0, Color("ff9a8a"))
        txt_fit("Satılamaz, denize bırak!", rcx, rb.position.y + 138.0, 19, rb.size.x - 14.0, Color("ffd0c8"))
    else:
        txt_fit("Durum: Sağlıklı", rcx, rb.position.y + 112.0, 22, rb.size.x - 14.0, Color.WHITE)
        txt_fit("Satılabilir Boy: %d para" % price_of(cm), rcx, rb.position.y + 138.0, 19, rb.size.x - 14.0, Color.WHITE)

    var sell_lbl := "S: Sat"
    if done and prot:
        sell_lbl = "S: Sat (YASAK, ceza)"
    elif done:
        sell_lbl = "S: Sat (+%d para)" % price_of(cm)
    draw_weigh_btn(weigh_btn_b(), "B: Denize Bırak", "release", done, false)
    draw_weigh_btn(weigh_btn_s(), sell_lbl, "sell", done, done and prot)


# ---------------------------------------------------------------- kaplumbağa kurtarma ekranı

func draw_rescue() -> void:
    draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.55))
    panel(Rect2(340, 80, 600, 540), Color("3fae4c"), 0.92)
    txt_c("KAPLUMBAĞAYI KURTAR!", W / 2.0, 135.0, 34, Color("9cff7a"))
    txt_c("İmleç yeşil bölgedeyken BOŞLUK ile ağı kes  (%d / %d)" % [rescue_hits, RESCUE_NEED], W / 2.0, 175.0, 20, Color.WHITE)
    var tc := Vector2(W / 2.0, 300.0)
    draw_turtle(tc, false, 1.0)
    for i in range(RESCUE_NEED - rescue_hits):
        draw_line(tc + Vector2(-120.0, -60.0 + float(i) * 45.0), tc + Vector2(120.0, 40.0 - float(i) * 30.0), Color(0.75, 0.92, 1.0, 0.9), 4.0)
    var bx := 390.0
    var bw := 500.0
    draw_rect(Rect2(bx, 440.0, bw, 36.0), Color(0.05, 0.08, 0.14))
    var zx := bx + (rescue_zone_c - rescue_zone_w * 0.5) * bw
    draw_rect(Rect2(zx, 440.0, rescue_zone_w * bw, 36.0), Color("3fae4c"))
    var border := Color("3a4f78")
    if rescue_flash > 0.0:
        border = Color("7dff9a") if rescue_ok else Color("ff6a5a")
    draw_rect(Rect2(bx, 440.0, bw, 36.0), border, false, 4.0)
    draw_rect(Rect2(bx + rescue_cursor * bw - 3.0, 430.0, 6.0, 56.0), Color.WHITE)
    var tcol := Color.WHITE if rescue_time > 3.0 else Color("ff6a5a")
    txt_c("Süre: %.1f" % maxf(rescue_time, 0.0), W / 2.0, 525.0, 26, tcol)
    txt_c("Iskalarsan süre 1.5 sn azalır!", W / 2.0, 570.0, 18, Color("ffe27a"))
