extends Node
## Kalite ayarlari (Dusuk / Orta / Yuksek) — Autoload olarak her yerden erisilir.
##
## Ayarlanabilenler:
##   - Golge kalitesi (kapali / dusuk / orta / yuksek)
##   - Bulut yogunlugu
##   - Sis yogunlugu
##   - Render olcegi (dusuk cozunurlukta render -> FPS)
##
## Secim `user://settings.cfg` dosyasina kaydedilir ve uygulama acilisinda hatirlanir.

signal quality_changed(level: int)

enum Level { LOW = 0, MEDIUM = 1, HIGH = 2 }

const LEVEL_NAMES := ["Dusuk", "Orta", "Yuksek"]
const SETTINGS_PATH := "user://settings.cfg"

const PRESETS := {
	Level.LOW: {
		"shadow_enabled": false,
		"shadow_size": 1024,
		"shadow_distance": 120.0,
		"shadow_filter": 0,
		"render_scale": 0.75,
		"cloud_coverage": 0.30,
		"cloud_alpha": 0.10,
		"fog_scale": 0.75,
		"msaa": 0,
	},
	Level.MEDIUM: {
		"shadow_enabled": true,
		"shadow_size": 2048,
		"shadow_distance": 220.0,
		"shadow_filter": 1,
		"render_scale": 0.9,
		"cloud_coverage": 0.46,
		"cloud_alpha": 0.14,
		"fog_scale": 1.0,
		"msaa": 0,
	},
	Level.HIGH: {
		"shadow_enabled": true,
		"shadow_size": 4096,
		"shadow_distance": 300.0,
		"shadow_filter": 2,
		"render_scale": 1.0,
		"cloud_coverage": 0.52,
		"cloud_alpha": 0.20,
		"fog_scale": 1.15,
		"msaa": 2,
	},
}

var level: int = Level.MEDIUM


func _ready() -> void:
	load_settings()
	# Ilk sahne hazir olduktan sonra uygula.
	apply.call_deferred()


func set_level(new_level: int) -> void:
	level = clampi(new_level, Level.LOW, Level.HIGH)
	apply()
	save_settings()
	quality_changed.emit(level)


func next_level() -> int:
	set_level((level + 1) % 3)
	return level


func preset() -> Dictionary:
	return PRESETS[level]


func apply() -> void:
	var p: Dictionary = PRESETS[level]
	var tree := get_tree()
	if tree == null:
		return

	# Render olcegi (dusuk cozunurlukte render -> daha yuksek FPS)
	var root := tree.root
	if root != null:
		if level == Level.HIGH:
			root.content_scale_factor = 1.0
		else:
			root.content_scale_factor = 1.0
		var vp := root.get_viewport()
		if vp != null:
			vp.scaling_3d_scale = float(p["render_scale"])
			vp.msaa_3d = int(p["msaa"])
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	# Sahnedeki isiklara/efektlere uygula
	for node in tree.get_nodes_in_group("quality_shadows"):
		if node is DirectionalLight3D:
			var light := node as DirectionalLight3D
			light.shadow_enabled = bool(p["shadow_enabled"])
			light.directional_shadow_max_distance = float(p["shadow_distance"])
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS

	var shadow_size := int(p["shadow_size"])
	RenderingServer.directional_shadow_atlas_set_size(shadow_size, true)

	for node in tree.get_nodes_in_group("quality_clouds"):
		if node is MeshInstance3D and (node as MeshInstance3D).material_override is ShaderMaterial:
			var mat := (node as MeshInstance3D).material_override as ShaderMaterial
			mat.set_shader_parameter("coverage", float(p["cloud_coverage"]))
			mat.set_shader_parameter("alpha_scale", float(p["cloud_alpha"]))

	for node in tree.get_nodes_in_group("quality_fog"):
		if node is WorldEnvironment and (node as WorldEnvironment).environment != null:
			var env := (node as WorldEnvironment).environment
			# Sahne dosyasindaki taban deger (0.00006) ile uyumlu: 0.004 cok fazlaydi,
			# tum goruntuyu soluk mavi sise boguyordu.
			env.fog_density = 0.0009 * float(p["fog_scale"])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", level)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		level = clampi(int(cfg.get_value("video", "quality", Level.MEDIUM)), Level.LOW, Level.HIGH)


func level_name() -> String:
	return LEVEL_NAMES[level]
