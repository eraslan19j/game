# Proje Kuralları

Bu dosya, bu repoda yapılan tüm çalışmalarda geçerli kuralları tanımlar.
Her yeni işe başlamadan önce okunur ve uygulanır.

---

## 1. İletişim dili

- Kullanıcı **kodlama bilmiyor**. Tüm kodu ajan yazar.
- Açıklamalar **"nereye tıklayacağım"** seviyesinde, kısa ve numaralı adımlarla verilir.
- Teknik terim zorunluysa bir cümleyle sadeleştirilir.
- Uzun teori/rapor yok; adım + beklenen sonuç var.

## 2. İş bitirme protokolü (her iş için zorunlu)

1. Değişiklikleri **`main`** dalına gönder.
2. **GitHub Actions** üzerinde APK derlemesinin **başarılı** olduğunu doğrula.
3. Kullanıcıya APK'nın **doğrudan indirme linkini** ver:
   `https://github.com/eraslan19j/game/releases/latest/download/kucuk-dunya-debug.apk`
4. Telefonda **ne görülmesi gerektiğini** madde madde **test listesi** olarak yaz.

> "Derlendi" demek yetmez — Actions sonucu ve Release varlığı kontrol edilmeden iş bitmiş sayılmaz.

## 3. Çalışma biçimi

- **Küçük adımlarla** ilerle. Bir seferde **tek özellik**.
- Kullanıcının **istemediği özelliği ekleme**. Kapsam dışına çıkma.
- İstenmeyen bir şey gerekiyorsa önce **sor**, sonra yap.

## 4. Performans hedefi

- Hedef cihaz: **orta seviye Android telefon**.
- Hedef: **30+ FPS** (mümkünse 60).
- Ağır efektler (gölge, sis, glow, SSAO, yüksek çözünürlük vb.) ya varsayılan kapalı olur
  ya da **ayar menüsünden kapatılabilir** olur.
- Yeni özellik eklerken FPS'i düşürecek bir şey varsa belirtilir.

## 5. Oyun vizyonu

- Stilize (**çizgi film havalı**), renkli, **sıcak atmosferli** 3D.
- Tür: **keşif + fotoğraf çekme macerası**.
- **Savaş yok.** Şiddet yok.
- Mobil öncelikli: dokunmatik kontroller, yatay ekran.

## 6. Görsel ve model kaynakları

- Dışarıdan hazır görsel/model **gerekirse**, yalnızca:
  - **CC0 / ücretsiz** ve lisansı kullanıma uygun kaynaklar,
  - tercihen **Kenney**, **Quaternius**, **Poly Haven**.
- Kullanılan her dış varlık için **`CREDITS.md`** dosyasına şunlar yazılır:
  - varlık adı, yazar, kaynak link, lisans.
- İndirilemiyorsa **prosedürel** (kodla üretilen) çözüm yapılır. Dışa bağımlılık zorunlu değildir.

## 7. Hata ayıklama

- **Tahmin etme.** Logu, kaynak kodu veya belgeyi okuyup **nedenini bul**.
- Hata metni boş/yanıltıcıysa ilgili motorun/aracın **kaynak koduna** bakılır.
- Düzeltme sonrası **aynı hatanın gerçekten gittiği** doğrulanır.

## 8. Derleme ve yayınlama hattı

- `.github/workflows/android-debug.yml`:
  - `main`'e her push'ta **debug APK** derler,
  - ardından **`latest` etiketli GitHub Release**'i oluşturur veya güncelleştirir,
  - eski APK'yı siler, yenisini yükler,
  - APK'yı **`kucuk-dunya-debug.apk`** adıyla Release'e ekler.
- İş akışında **`contents: write`** izni bulunur.
- Sabit indirme linki:
  `https://github.com/eraslan19j/game/releases/latest/download/kucuk-dunya-debug.apk`
- `README.md` her zaman bu linki içerir; telefonda linke dokunmak APK indirmek için yeterlidir.

## 9. Depo görünürlüğü

- Sabit Release linkinin çalışması için depo **public** olmalıdır.
- Depo private ise kullanıcıya **söylenir** ve public yapmak için **nereye tıklayacağı** yazılır.
