extends MeshInstance3D
## Stilize su yuzeyi.
##
## - Dalga hareketi: vertex shader'da sinus (geometri gercekten kabarir)
## - Yari saydamlik
## - Kiyida acik renk + kopuk: arazi yukseklik dokusundan derinlik hesaplanir
##
## Doku ve parametreler `setup()` ile dunya scriptinden verilir.

# Su duzlemi: ada cevresinde yeterince sik olmali, yoksa kiyi hattinda
# testere disi olusur (14 000 m / 90 parca = 155 m'lik dev ucgenler).
@export var size: float = 3600.0
@export var subdivisions: int = 150
@export var wave_strength: float = 1.0
@export var wave_speed: float = 1.0

var _material: ShaderMaterial


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	mesh = plane
	# Su yuzeyi isinlari/golgeyi almaz, sadece isiklandirilir (performans).
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Dalga ayarlari (shader parametreleri).
func setup(wave_speed_value: float = 1.0, wave_strength_value: float = 1.0) -> void:
	if material_override is ShaderMaterial:
		var mat := material_override as ShaderMaterial
		mat.set_shader_parameter("wave_speed", wave_speed_value)
		mat.set_shader_parameter("wave_strength", wave_strength_value)
		print("[Water] hazir (yuzey=%.0f m, bolum=%d)" % [size, subdivisions])
