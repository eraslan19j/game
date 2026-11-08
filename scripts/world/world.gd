extends Node3D
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

	# Fizik dunyasi bir kare sonra hazir olur; carpisma testini ondan sonra yap.
	_verify_collision.call_deferred()

	# Su, kiyi derinligini arazi dokusundan okur.
	_water.setup(
		_terrain.height_texture,
		_terrain.world_size,
		_terrain.height_min,
		_terrain.height_max
	)


## Tanilama: arazi carpismasi gercekten calisiyor mu?
## Deniz seviyesinin ustunde oldugunu bildigimiz noktalara isin gonderir.
func _verify_collision() -> void:
	var space := get_world_3d().direct_space_state
	var tested := 0
	var hits := 0
	for p in [Vector2(0, 0), Vector2(20, 15), Vector2(-25, 30), Vector2(35, -20)]:
		var from := Vector3(p.x, 200.0, p.y)
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -300, 0))
		var hit := space.intersect_ray(query)
		tested += 1
		if not hit.is_empty():
			hits += 1
			print("[Collision] (%.0f, %.0f) -> carpisma y=%.2f" % [p.x, p.y, hit["position"].y])
		else:
			print("[Collision] (%.0f, %.0f) -> CARPISMA YOK" % [p.x, p.y])
	print("[Collision] sonuc: %d/%d nokta carpisti" % [hits, tested])


func _process(delta: float) -> void:
	if orbit_speed_deg != 0.0:
		_camera_rig.rotate_y(deg_to_rad(orbit_speed_deg) * delta)
