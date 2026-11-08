# Küçük Dünya 🌿

Küçük ölçekli, **3D keşif ve fotoğraf çekme** macerası. Savaş yok.
Sıcak, renkli bir görsel dil hedefliyor. Godot 4 (GDScript) ile geliştiriliyor, Android'e çıkar.

> Durum: **Aşama 4 — Doğal yaşam.** Adaya **220 ağaç (4 çeşit)**, 260 çalı, 170 kaya,
> 900 çiçek, **16.000 tutam çimen** (MultiMesh + rüzgârda salınma) ve kıyıda kum yamaları eklendi.
> Yerleşim tamamen **kodla ve yükseklik/eğim/kıyı kurallarına göre** üretiliyor (harici görsel yok).
> Kamera otomatik dönüyor. Yürüme ve fotoğraf çekme sonraki adımlarda eklenecek.

### ⚡ Performans (ölçüldü)
| Ölçüm | Değer |
|---|---|
| Çizim çağrısı (draw call) | **12** |
| Üçgen sayısı | **~360.000** |
| Bitki başına çizim çağrısı | 1 (tüm ağaçlar/çimenler MultiMesh) |
| CI (yazılım OpenGL, GPU yok) | ~9-15 FPS |
| Hedef | **orta seviye telefonda 30+ FPS** |

> Not: CI makinelerinde ekran kartı yok; ölçüm **yazılım renderer (llvmpipe)** ile yapılıyor,
> bu yüzden oradaki FPS gerçek telefon performansını göstermez. Telefonda ölçmek için
> **AYAR → Bilgi** bölümündeki FPS sayacına bak.

## 🎛️ Ayar menüsü

Sol üstteki **AYAR** düğmesine dokun. Menüden:
- **Kalite:** Düşük / Orta / Yüksek (gölge, bulut yoğunluğu, sis, render ölçeği)
- **Dil:** Türkçe / English
- **Bilgi:** o anki FPS ve günün saati

Seçim telefon hafızasında saklanır, uygulama kapanıp açılınca hatırlanır.

---

## 📁 Klasör yapısı

```
game/
├─ project.godot            ← Godot proje ayarları (motor bunu okur)
├─ export_presets.cfg       ← Android export ayarları (APK bununla derlenir)
├─ icon.svg                 ← Uygulama ikonu
├─ PROJE_KURALLARI.md       ← Bu projede uyulan kurallar
├─ CREDITS.md               ← Dış görsel/ses kaynakları ve lisansları
├─ scenes/
│  └─ world/
│     └─ world.tscn         ← Açılış sahnesi: ada, su, gökyüzü, güneş, kamera
├─ shaders/
│  ├─ water.gdshader        ← Stilize su (dalga, saydamlık, kıyı rengi)
│  ├─ toon.gdshader         ← Boyalı/çizgi film görünümü (bantlı ışık, renkli gölge)
│  ├─ clouds.gdshader       ← Kodla üretilen bulut kubbesi
│  └─ nature.gdshader       ← Bitkiler için toon + rüzgâr shader'ı
├─ scripts/
│  └─ world/
│     ├─ world.gd            ← Sahneyi canlandıran script (güneş, kamera, su bağlantısı)
│     ├─ terrain.gd          ← Ada arazi üretimi (noise + çarpışma + renkler)
│     ├─ water.gd            ← Su yüzeyi
│     ├─ sky_cycle.gd        ← 10 dakikalık gün döngüsü (renk/sis/güneş)
│     ├─ quality_settings.gd ← Kalite presetleri (Autoload)
│     ├─ cloud_texture.gd    ← Bulutlar için kodla üretilen doku
│     ├─ nature.gd           ← Bitki/kaya/kum yerleşimi (yükseklik + eğim kuralı)
│     ├─ nature_meshes.gd    ← Ağaç (4 çeşit), çalı, çiçek, kaya, çimen modelleri
│     └─ perf_log.gd         ← FPS/çizim istatistiği
├─ scripts/ui/
│  ├─ settings_menu.gd       ← Dokunmatik ayar menüsü
│  └─ i18n.gd                ← TR/EN metin tablosu (Autoload)
└─ .github/workflows/
   └─ android-debug.yml      ← Her push'ta APK derleyen otomatik hat
```

Yeni klasörler ileride `scenes/player/`, `scenes/props/`, `scripts/player/`, `assets/` olarak eklenecek.

---

## 1️⃣ APK'yı indir (tek link)

Telefonun tarayıcısında şu linke dokun:

**https://github.com/eraslan19j/game/releases/latest/download/kucuk-dunya-debug.apk**

`kucuk-dunya-debug.apk` dosyası inmeye başlar. Başka hiçbir şeye tıklaman gerekmez.
Bu link her zaman **en son sürümü** verir — derleme bitince otomatik güncellenir.

> Alternatif (Actions'tan): https://github.com/eraslan19j/game/actions →
> "Android Debug APK" → en üstteki yeşil ✓'li çalıştırma → **Artifacts** →
> `kucuk-dunya-debug-apk`.

## 2️⃣ APK'yı telefona kur

Doğrudan telefondan indirdiysen dosya zaten **Downloads** klasöründe:

1. Telefonda **Dosyalar → Downloads** (İndirilenler) klasörünü aç.
   *(Bilgisayardan indirdiysen `.apk`'yı USB ile telefonun Downloads klasörüne kopyala.)*
2. `kucuk-dunya-debug.apk` dosyasını bul ve üzerine dokun.
3. Android uyaracak: *"Bilinmeyen kaynaklardan yüklemeye izin ver"* →
   **Ayarlar**'a götürür → **bu uygulamaya (Dosyalar/Chrome) izin ver** anahtarını aç.
4. Geri dön → **Yükle** → **Aç**.

**Kurulmuyorsa:** telefonda *Play Protect* engelliyor olabilir →
**Play Store → profil → Play Protect → Ayarlar → "Uygulamaları tara"yı kapat**, sonra tekrar dene.
(Kendi debug APK'nız olduğu için bu normaldir, risk yok. Test bitince geri açabilirsin.)

**USB'den kurmak istersen (daha pratik):**
```
adb install -r kucuk-dunya-debug.apk
```

---

## 3️⃣ Test adımları (ne görmen gerekiyor)

Uygulamayı açtıktan sonra:

| # | Kontrol | Beklenen |
|---|---|---|
| 1 | Uygulama açılıyor mu? | Donmadan, ~2 saniyede açılır. Simge: mavi gökyüzü + yeşil tepe. |
| 2 | Ekran yatay mı? | Telefonu çevirdiğinde oyun yatay kalır. |
| 3 | Gökyüzü | Üstte mavi, ufukta sıcak krem tonu geçişi. Düz siyah/boş ekran **olmamalı**. |
| 4 | Zemin | Yeşil bir düzlem, üzerinde gölge düşüyor. |
| 5 | Ağaçlar & kayalar | 3 ağaç (kahve gövde + yeşil küre) ve 2 kaya görünür. |
| 6 | Işık | Nesnelerin bir yüzü aydınlık, diğer yüzü gölgeli. Her yer eşit parlak değil. |
| 7 | Hareket | Sahne yavaşça dönüyor (kamera ~1 tur / 60 sn). Hafif takılma olabilir, donma olmamalı. |
| 8 | Dokunmatik | Şu an bir işlev yok — bu aşamada normal. |
| 9 | Çıkış | Geri tuşu / home ile sorunsuz çıkar, çökme yok. |

**Bir şey ters giderse**, bana şunu söyle: hangi madde + ekran görüntüsü.

---

## 🔧 Kendi bilgisayarında açmak istersen (isteğe bağlı)

Kod yazmayacaksın ama sahneyi görmek istersen:

1. https://godotengine.org/download → **Godot 4.5.2** (standart sürüm) indir, kur.
2. Godot'u aç → **Import** → bu klasördeki **`project.godot`** dosyasını seç → **Import & Edit**.
3. Klavyeden **F5** → oyun bilgisayarında açılır.

> Windows'ta APK derlemek istersen Godot'nun "Export Templates" + Android SDK kurulumu gerekir; bunu senin yerine GitHub Actions yapıyor, o yüzden gerek yok.

---

## ⚙️ Otomatik derleme nasıl çalışıyor?

`.github/workflows/android-debug.yml`:
- `main` dalına her push'ta tetiklenir (Actions sekmesinden elle de başlatılabilir).
- `barichello/godot-ci:4.5.2` imajını kullanır — içinde Godot 4.5.2, JDK 17, Android SDK ve debug keystore hazır gelir.
- `export_presets.cfg` içindeki **"Android Debug"** preset'i ile `arm64-v8a` debug APK üretir.
- APK'yı `kucuk-dunya-debug-apk` adıyla artifact olarak yükler (30 gün saklanır).
- Derleme başarısız olursa `ci-logs` dalı oluşturulur ve tanılama logu oraya yazılır (`export.log`). Başarılı derlemede oluşmaz.
