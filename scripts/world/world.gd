extends Node3D
## Basit 3D test sahnesi.
## Bu script sadece sahneyi "canli" gostermek icin var:
##   - Gunes'in acisini ayarlar
##   - Kamerayi yavasca sahnenin etrafinda dondurur (3D oldugu belli olsun diye)
##
## Kameranin donmesini istemiyorsan: orbit_speed_deg degerini 0 yap.

@export var orbit_speed_deg: float = 6.0
@export var camera_distance: float = 14.0
@export var camera_height: float = 6.0
@export var camera_pitch_deg: float = -20.0
@export var sun_pitch_deg: float = -48.0
@export var sun_yaw_deg: float = -42.0

@onready var _sun: DirectionalLight3D = $Sun
@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D


func _ready() -> void:
	# Gunes yonunu burada aciyruz; .tscn icinde hatali matris olmasi riskini boylece kaldiriyoruz.
	_sun.rotation_degrees = Vector3(sun_pitch_deg, sun_yaw_deg, 0.0)

	# Kamerayi merkeze bakacak sekilde yerlestir.
	var pitch := deg_to_rad(camera_pitch_deg)
	var camera_basis := Basis.from_euler(Vector3(pitch, 0.0, 0.0))
	_camera.transform = Transform3D(
		camera_basis,
		Vector3(0.0, camera_height, camera_distance)
	)


func _process(delta: float) -> void:
	if orbit_speed_deg != 0.0:
		_camera_rig.rotate_y(deg_to_rad(orbit_speed_deg) * delta)
