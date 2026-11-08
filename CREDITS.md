# CREDITS

Bu projede kullanılan dış kaynaklı görsel, model ve ses varlıklarının listesi.

## Durum: dış varlık kullanılmıyor

Şu an projedeki **tüm görseller kodla (prosedürel) üretiliyor** ve depo içinde tanımlı:

| Varlık | Nerede | Kaynak |
|---|---|---|
| Uygulama ikonu | `icon.svg` | Proje içinde elle çizilmiş SVG |
| Gökyüzü, ışık, sis | `scenes/world/world.tscn` | Godot `ProceduralSkyMaterial` + `Environment` |
| Zemin, ağaçlar, kayalar | `scenes/world/world.tscn` | Godot ilkel mesh'leri (`PlaneMesh`, `SphereMesh`, `CylinderMesh`, `BoxMesh`) |
| Renk paleti | `world.tscn` / `world.gd` | Proje içinde seçilmiş |

Bu nedenle üçüncü taraf lisans yükümlülüğü yoktur.

## Dış varlık eklenirse

Her yeni varlık için bu tabloya şu satır eklenir:
**varlık adı — yazar — kaynak link — lisans**

İzin verilen kaynaklar: Kenney, Quaternius, Poly Haven (CC0 / uygun lisans).
