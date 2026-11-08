extends MeshInstance3D
## Stilize su yuzeyi.
##
## - Dalga hareketi: vertex shader'da sinus (geometri gercekten kabarir)
## - Yari saydamlik
## - Kiyida acik renk + kopuk: arazi yukseklik dokusundan derinlik hesaplanir
##
## Doku ve parametreler `setup()` ile dunya scriptinden verilir.

@export var size: float = 3000.0
@export var subdivisions: int = 100
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


## Arazi bilgisini shader'a aktar. terrain_height_texture her zaman
## world_size x world_size alanini kaplar (merkez: 0,0).
func setup(terrain_height_texture: Texture2D, terrain_size: float, h_min: float, h_max: float) -> void:
	if material_override is ShaderMaterial:
		_material = material_override
	if _material == null:
		push_warning("Su materyali atanmamis (Water node'unda material_override yok).")
		return
	if terrain_height_texture != null:
		_material.set_shader_parameter("terrain_height", terrain_height_texture)
	print("[Water] doku=%s arazi=%.1f m  dalga=%.2f  yuzey=%.0f m  bolum=%d"
		% ["var" if terrain_height_texture != null else "YOK", terrain_size,
		wave_strength, size, subdivisions])
	_material.set_shader_parameter("terrain_size", terrain_size)
	_material.set_shader_parameter("height_min", h_min)
	_material.set_shader_parameter("height_max", h_max)
