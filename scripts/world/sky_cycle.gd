extends Node
## Gok, gunes ve atmosfer dongusu.
##
## Dongu ~10 dakika (600 sn). 4 ana evre:
##   gundogumu -> ogle -> gunbatimi -> gece -> (tekrar)
##
## Ayarlar `project.godot` yerine burada sabit; sahne dugumleriyle eslesir.
## Kalite ayarlari (golge, bulut yogunlugu) QualitySettings tarafindan cagrilir.

@export var day_length: float = 600.0
@export var start_phase: float = 0.28
@export var sun_distance: float = 300.0
@export var day_light_energy: float = 0.25
@export var night_light_energy: float = 0.10

# (faz, gokyuzu ust, gokyuzu ufuk, gunes rengi, sis rengi, ortam enerjisi, bulut rengi)
const KEYS := [
	{"p": 0.00, "top": Color(0.37, 0.47, 0.72), "hor": Color(0.92, 0.84, 0.80),
	 "sun": Color(1.0, 0.76, 0.58), "fog": Color(0.93, 0.84, 0.79),
	 "amb": 0.85, "cloud": Color(1.0, 0.85, 0.80)},
	{"p": 0.09, "top": Color(0.20, 0.42, 0.78), "hor": Color(0.98, 0.82, 0.64),
	 "sun": Color(1.0, 0.70, 0.45), "fog": Color(0.97, 0.86, 0.74),
	 "amb": 1.00, "cloud": Color(1.0, 0.90, 0.80)},
	{"p": 0.14, "top": Color(0.18, 0.47, 0.85), "hor": Color(1.0, 0.92, 0.76),
	 "sun": Color(1.0, 0.90, 0.72), "fog": Color(0.97, 0.93, 0.82),
	 "amb": 1.15, "cloud": Color(1.0, 0.98, 0.94)},
	{"p": 0.25, "top": Color(0.16, 0.51, 0.90), "hor": Color(0.98, 0.95, 0.88),
	 "sun": Color(1.0, 0.97, 0.92), "fog": Color(0.96, 0.95, 0.90),
	 "amb": 1.30, "cloud": Color(1.0, 1.0, 1.0)},
	{"p": 0.50, "top": Color(0.14, 0.48, 0.88), "hor": Color(0.97, 0.94, 0.86),
	 "sun": Color(1.0, 0.96, 0.90), "fog": Color(0.95, 0.93, 0.87),
	 "amb": 1.25, "cloud": Color(1.0, 1.0, 1.0)},
	{"p": 0.62, "top": Color(0.17, 0.46, 0.83), "hor": Color(1.0, 0.86, 0.64),
	 "sun": Color(1.0, 0.84, 0.60), "fog": Color(0.98, 0.88, 0.70),
	 "amb": 1.10, "cloud": Color(1.0, 0.94, 0.86)},
	{"p": 0.72, "top": Color(0.29, 0.40, 0.71), "hor": Color(0.99, 0.70, 0.50),
	 "sun": Color(1.0, 0.62, 0.38), "fog": Color(0.97, 0.76, 0.62),
	 "amb": 0.92, "cloud": Color(1.0, 0.78, 0.72)},
	{"p": 0.80, "top": Color(0.22, 0.28, 0.56), "hor": Color(0.78, 0.55, 0.60),
	 "sun": Color(0.86, 0.55, 0.52), "fog": Color(0.74, 0.62, 0.68),
	 "amb": 0.62, "cloud": Color(0.86, 0.74, 0.82)},
	{"p": 0.88, "top": Color(0.10, 0.13, 0.31), "hor": Color(0.30, 0.34, 0.52),
	 "sun": Color(0.55, 0.62, 0.90), "fog": Color(0.28, 0.32, 0.50),
	 "amb": 0.38, "cloud": Color(0.52, 0.58, 0.76)},
	{"p": 0.96, "top": Color(0.09, 0.12, 0.28), "hor": Color(0.26, 0.32, 0.48),
	 "sun": Color(0.50, 0.58, 0.86), "fog": Color(0.24, 0.29, 0.46),
	 "amb": 0.34, "cloud": Color(0.46, 0.53, 0.72)},
]

@onready var _env_node: WorldEnvironment = get_node_or_null("../WorldEnvironment")
@onready var _sun: DirectionalLight3D = get_node_or_null("../Sun")

var phase: float = 0.0
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _cloud_mat: ShaderMaterial
var _sun_base_energy: float = 1.35
var _night_mode: bool = false


func _ready() -> void:
	phase = start_phase
	if _env_node != null:
		_env = _env_node.environment
		if _env != null and _env.sky != null:
			_sky_mat = _env.sky.sky_material as ProceduralSkyMaterial
	if _sun != null:
		_sun_base_energy = day_light_energy
	var clouds := get_node_or_null("../Clouds")
	if clouds != null and clouds.material_override is ShaderMaterial:
		_cloud_mat = clouds.material_override
	_apply(phase)


func _process(delta: float) -> void:
	if day_length <= 0.0:
		return
	phase = fmod(phase + delta / day_length, 1.0)
	_apply(phase)


func _apply(p: float) -> void:
	var k := _sample(p)

	if _sky_mat != null:
		_sky_mat.sky_top_color = k["top"]
		_sky_mat.sky_horizon_color = k["hor"]
		_sky_mat.ground_horizon_color = k["hor"]

	if _env != null:
		_env.ambient_light_color = k["hor"].lerp(k["top"], 0.4)
		_env.ambient_light_energy = k["amb"]
		if _env.fog_enabled:
			_env.fog_light_color = k["fog"]

	# Gunes acisi: faz 0.25 -> ogle (tepede), 0.75 -> gunbatimi (ufukta).
	var sun_t: float = (p - 0.25) * TAU
	var elevation: float = sin(sun_t) * 1.02
	var dir := Vector3(cos(sun_t) * 0.55, elevation, 0.62).normalized()
	if _sun != null:
		var up := Vector3.UP
		if absf(dir.dot(up)) > 0.98:
			up = Vector3.FORWARD
		_sun.look_at_from_position(Vector3.ZERO, -dir, up)
		var day_factor: float = clampf(elevation * 2.2 + 0.15, 0.0, 1.0)
		_sun.light_energy = lerpf(night_light_energy, _sun_base_energy, day_factor)
		_sun.light_color = k["sun"]
		_night_mode = elevation < -0.05
		_sun.shadow_enabled = _sun.shadow_enabled and not _night_mode

	if _cloud_mat != null:
		var cloud_col: Color = k["cloud"]
		_cloud_mat.set_shader_parameter("cloud_color", cloud_col)
		_cloud_mat.set_shader_parameter("cloud_shade", cloud_col.lerp(k["fog"], 0.55))


func _sample(p: float) -> Dictionary:
	var n := KEYS.size()
	# Ilk anahtarin fazi 0, son 0.96; donguyu kapatmak icin 0.96 -> 1.0 arasi.
	var prev: Dictionary = KEYS[n - 1]
	var next: Dictionary = KEYS[0]
	var prev_p: float = 0.96
	var next_p: float = 1.0
	var found := false
	for i in n:
		var cur: Dictionary = KEYS[i]
		if cur["p"] <= p:
			prev = cur
			prev_p = cur["p"]
			var nxt: Dictionary = KEYS[(i + 1) % n]
			next = nxt
			next_p = nxt["p"] if i + 1 < n else 1.0 + float(nxt["p"])
			found = true
		else:
			break
	if not found:
		prev = KEYS[n - 1]
		prev_p = KEYS[n - 1]["p"]
		next = KEYS[0]
		next_p = 1.0

	var t: float = 0.0
	if next_p > prev_p:
		t = clampf((p - prev_p) / (next_p - prev_p), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)  # smoothstep

	var top: Color = (prev["top"] as Color).lerp(next["top"], t)
	var hor: Color = (prev["hor"] as Color).lerp(next["hor"], t)
	return {
		"top": top,
		"hor": hor,
		"sun": (prev["sun"] as Color).lerp(next["sun"], t),
		"fog": (prev["fog"] as Color).lerp(next["fog"], t),
		"amb": lerpf(prev["amb"], next["amb"], t),
		"cloud": (prev["cloud"] as Color).lerp(next["cloud"], t),
	}
