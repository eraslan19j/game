# Küçük Dünya 🌿

Küçük ölçekli, **3D keşif ve fotoğraf çekme** macerası. Savaş yok.
Sıcak, renkli bir görsel dil hedefliyor. Godot 4 (GDScript) ile geliştiriliyor, Android'e çıkar.

> Durum: **Aşama 1 — İskelet.** Şu an sadece test sahnesi var (zemin, gökyüzü, güneş, dönen kamera).
> Yürüme, fotoğraf çekme gibi özellikler sonraki adımlarda eklenecek.

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
│     └─ world.tscn         ← Açılış sahnesi: zemin, gökyüzü, güneş, kamera, birkaç ağaç
├─ scripts/
│  └─ world/
│     └─ world.gd            ← Sahneyi canlandıran script
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
