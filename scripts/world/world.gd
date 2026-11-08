extends Node3D

const CloudTextureGen = preload("res://scripts/world/cloud_texture.gd")
## Kucuk Dunya - ada sahnesi.
##
## Bu script:
##   - Gunes acisini ayarlar
##   - Su shader'ina arazi yukseklik dokusunu verir (kiyi rengi icin)
##   - Kamerayi yavasca sahnenin etrafinda dondurur (3D oldugu belli olsun diye)

@export var orbit_speed_deg: float = 6.0
@export var camera_distance: float = 165.0
@export var camera_height: float = 78.0
@export var camera_pitch_deg: float = -30.0
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

	# Su dalga ayarlarini uygula.
	if _water.has_method("setup"):
		_water.setup()

	_probe_screen.call_deferred()


## Teshis: ekrandaki noktalara kamera isini gonder, ne gorunuyor logla.
func _probe_screen() -> void:
	await get_tree().create_timer(0.8).timeout
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		print("[Probe] kamera yok")
		return
	var vp_size := get_viewport().get_visible_rect().size
	print("[Probe] viewport=%s kamera=%s" % [str(vp_size), str(cam.global_position)])
	var space := get_world_3d().direct_space_state
	var pts := {
		"ust-orta": Vector2(0.5, 0.12), "orta": Vector2(0.5, 0.50),
		"alt-orta": Vector2(0.5, 0.92), "sol-alt": Vector2(0.12, 0.85),
	}
	for k in pts:
		var sp: Vector2 = pts[k] * vp_size
		var from := cam.project_ray_origin(sp)
		var to := from + cam.project_ray_normal(sp) * 5000.0
		var q := PhysicsRayQueryParameters3D.create(from, to)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			print("[Probe] %-8s (%s) -> fizik isabeti yok" % [k, str(sp)])
		else:
			var col = hit["collider"]
			print("[Probe] %-8s -> %s  y=%.2f  xz=(%.0f, %.0f)" % [
				k, col.name if col != null else "?", hit["position"].y,
				hit["position"].x, hit["position"].z])
	print("[Probe] su AABB: %s" % str(_water.get_aabb()))
	print("[Probe] su material: %s" % ("ShaderMaterial" if _water.material_override is ShaderMaterial else str(_water.material_override)))


func _process(delta: float) -> void:
	if orbit_speed_deg != 0.0:
		_camera_rig.rotate_y(deg_to_rad(orbit_speed_deg) * delta)
