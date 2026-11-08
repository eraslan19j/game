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

## 1️⃣ APK'yı indir (tek tık)

1. Bilgisayarında veya telefonda tarayıcıdan şu adrese git:
   **https://github.com/eraslan19j/game/actions**
2. Soldaki listede **"Android Debug APK"** yazısına tıkla.
3. En üstteki, yeşil ✓ işaretli çalıştırmaya tıkla (en yeni olan).
4. Sayfayı aşağı kaydır → **Artifacts** başlığı altında
   **`kucuk-dunya-debug-apk`** yazısına tıkla.
5. `kucuk-dunya-debug-apk.zip` iner. Zip'i aç, içinde **`kucuk-dunya-debug.apk`** var.

> Derleme genelde **3–6 dakika** sürer. Sayfa yenileniyorsa bekle; sarı nokta dönerken hâlâ derliyor demektir.

---

## 2️⃣ APK'yı telefona kur

Telefonu USB ile bilgisayara bağla, sonra:

1. İndirdiğin `.apk` dosyasını telefonun **Downloads** klasörüne kopyala.
2. Telefonda **Dosyalar → Downloads** (İndirilenler) klasörünü aç.
3. `kucuk-dunya-debug.apk` dosyasına dokun.
4. Android uyaracak: *"Bilinmeyen kaynaklardan yüklemeye izin ver"* →
   **Ayarlar**'a götürür → **bu uygulamaya (Dosyalar/Chrome) izin ver** anahtarını aç.
5. Geri dön → **Yükle** → **Aç**.

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
