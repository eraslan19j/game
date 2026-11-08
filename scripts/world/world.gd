extends Node3D

const CloudTextureGen = preload("res://scripts/world/cloud_texture.gd")
## Kucuk Dunya - ada sahnesi.
##
## Bu script:
##   - Gunes acisini ayarlar
##   - Su shader'ina arazi yukseklik dokusunu verir (kiyi rengi icin)
##   - Kamerayi yavasca sahnenin etrafinda dondurur (3D oldugu belli olsun diye)

@export var orbit_speed_deg: float = 6.0
@export var camera_distance: float = 60.0
@export var camera_height: float = 22.0
@export var camera_pitch_deg: float = -19.0
@export var sun_pitch_deg: float = -48.0
@export var sun_yaw_deg: float = -42.0

@onready var _sun: DirectionalLight3D = $Sun
@onready var _terrain: StaticBody3D = $Terrain
@onready var _water: MeshInstance3D = $Water
@onready var _clouds: MeshInstance3D = $Clouds
@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D


func _ready() -> void:
	# Gunes yonunu burada aciyoruz; .tscn icinde hatali matris olmasi riskini kaldirir.
	_sun.rotation_degrees = Vector3(sun_pitch_deg, sun_yaw_deg, 0.0)

	# Kamerayi merkeze bakacak sekilde yerlestir.
	var pitch := deg_to_rad(camera_pitch_deg)
	var camera_basis := Basis.from_euler(Vector3(pitch, 0.0, 0.0))
	_camera.transform = Transform3D(
		camera_basis,
		Vector3(0.0, camera_height, camera_distance)
	)

	# Bulutlar icin prosedurel gurultu dokusu (dis gorsel yok).
	if _clouds != null and _clouds.material_override is ShaderMaterial:
		var cloud_mat := _clouds.material_override as ShaderMaterial
		cloud_mat.set_shader_parameter("cloud_noise", CloudTextureGen.build())

	# Su, kiyi derinligini arazi dokusundan okur.
	_water.setup(
		_terrain.height_texture,
		_terrain.world_size,
		_terrain.height_min,
		_terrain.height_max
	)


func _process(delta: float) -> void:
	if orbit_speed_deg != 0.0:
		_camera_rig.rotate_y(deg_to_rad(orbit_speed_deg) * delta)
