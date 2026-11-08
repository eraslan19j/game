extends Node3D
## Adaya dogal yasam dagitir.
##
## Kurallar (egim + yukseklik + kiyi mesafesi):
##   - Kum      : deniz seviyesine yakin alcak serit (kiyi)
##   - Cim      : duz/az egimli, kumun ustundeki yesil alan (MultiMesh, ruzgarli)
##   - Cicek    : cim alaninda, kumeden kumeye
##   - Cali     : orta yukseklik, hafif egim
##   - Agac     : alcak-orta yukseklik, duz zemin (4 cesit, rastgele boyut/renk)
##   - Kaya     : her yerde, ozellikle dik yamaclarda ve kiyida
##
## Tum bitkiler MultiMesh ile cizilir: tur basina tek cizim cagrisi.

const Meshes = preload("res://scripts/world/nature_meshes.gd")
const NATURE_SHADER := preload("res://shaders/nature.gdshader")

# --- Yogunluklar (kalite ayari bunlari olceklendirir) ---
@export var tree_count: int = 220
@export var bush_count: int = 260
@export var rock_count: int = 170
@export var flower_count: int = 900
@export var grass_count: int = 16000
@export var sand_patch_count: int = 34

# --- Arama denemesi (reddedilen ornekler icin) ---
@export var max_attempts_multiplier: int = 12
@export var seed_value: int = 913377

# --- Agac renk paleti (canli, sicak tonlar) ---
const TREE_LEAF_COLORS := [
	Color(0.36, 0.66, 0.28),
	Color(0.46, 0.74, 0.30),
	Color(0.28, 0.58, 0.32),
	Color(0.58, 0.75, 0.32),
	Color(0.40, 0.70, 0.42),
	Color(0.66, 0.78, 0.34),
]
const BUSH_COLORS := [
	Color(0.30, 0.56, 0.26),
	Color(0.40, 0.64, 0.30),
	Color(0.24, 0.48, 0.28),
]
const FLOWER_COLORS := [
	Color(0.98, 0.55, 0.62),  # pembe
	Color(0.99, 0.86, 0.40),  # sari
	Color(0.72, 0.58, 0.95),  # mor
	Color(0.99, 0.97, 0.94),  # beyaz
	Color(0.98, 0.62, 0.32),  # turuncu
]
const ROCK_COLORS := [
	Color(0.62, 0.60, 0.57),
	Color(0.54, 0.53, 0.52),
	Color(0.70, 0.67, 0.62),
]
const SAND_COLOR := Color(0.89, 0.81, 0.60)

var _terrain: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _tree_material: ShaderMaterial
var _bush_material: ShaderMaterial
var _rock_material: ShaderMaterial
var _flower_material: ShaderMaterial
var _grass_material: ShaderMaterial
var _sand_material: ShaderMaterial

var _counts := {}
var _stats := {}


## Dunya scripti tarafindan cagrilir.
func build(terrain: StaticBody3D, quality_level: int) -> void:
	_terrain = terrain
	_rng.seed = seed_value
	_make_materials()

	var scale := _quality_scale(quality_level)

	_build_sand()
	_build_grass(int(float(grass_count) * scale))
	_build_flowers(int(float(flower_count) * scale))
	_build_bushes(int(float(bush_count) * scale))
	_build_trees(int(float(tree_count) * scale))
	_build_rocks(int(float(rock_count) * scale))

	print("[Nature] kalite=%d olcek=%.2f  agac=%d cali=%d kaya=%d cicek=%d cim=%d kum=%d" % [
		quality_level, scale,
		_counts.get("tree", 0), _counts.get("bush", 0), _counts.get("rock", 0),
		_counts.get("flower", 0), _counts.get("grass", 0), _counts.get("sand", 0)])


## Kaliteye gore bitki yogunlugu.
func _quality_scale(level: int) -> float:
	match level:
		0:  # Dusuk
			return 0.45
		2:  # Yuksek
			return 1.35
		_:
			return 1.0


func _make_materials() -> void:
	_tree_material = _new_material(Color(1, 1, 1), 0.14, 1.9)
	_bush_material = _new_material(Color(1, 1, 1), 0.10, 1.7)
	_rock_material = _new_material(Color(1, 1, 1), 0.0, 1.0)
	_flower_material = _new_material(Color(1, 1, 1), 0.16, 1.4)
	_grass_material = _new_material(Color(1, 1, 1), 0.20, 1.05)
	_sand_material = _new_material(Color(1, 1, 1), 0.0, 1.0)
	_grass_material.set_shader_parameter("wind_bend_power", 1.8)
	_grass_material.set_shader_parameter("wind_height", 0.42)
	_flower_material.set_shader_parameter("wind_bend_power", 1.5)
	_flower_material.set_shader_parameter("wind_height", 0.3)


func _new_material(col: Color, wind: float, wind_speed: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = NATURE_SHADER
	mat.set_shader_parameter("tint", col)
	mat.set_shader_parameter("wind_strength", wind)
	mat.set_shader_parameter("wind_speed", wind_speed)
	return mat


# ------------------------------------------------------------------ ornekleme

## Uygun bir nokta bulur. Kosullar saglanmazsa null doner.
func _pick(min_h: float, max_h: float, max_slope: float, radial_max: float = 1.0) -> Variant:
	var r_max: float = _terrain.island_radius * radial_max
	var attempts: int = int(float(100) * float(max_attempts_multiplier))
	for i in attempts:
		var ang: float = _rng.randf_range(0.0, TAU)
		var rad: float = sqrt(_rng.randf()) * r_max
		var x: float = cos(ang) * rad
		var z: float = sin(ang) * rad
		var h: float = _terrain.sample_height(x, z)
		if h < min_h or h > max_h:
			continue
		if _terrain.sample_slope(x, z) > max_slope:
			continue
		return Vector3(x, h, z)
	return null


func _slope_normal(x: float, z: float) -> Vector3:
	var e: float = 1.5
	var dx: float = (_terrain.sample_height(x + e, z) - _terrain.sample_height(x - e, z)) / (2.0 * e)
	var dz: float = (_terrain.sample_height(x, z + e) - _terrain.sample_height(x, z - e)) / (2.0 * e)
	return Vector3(-dx, 1.0, -dz).normalized()


# ------------------------------------------------------------------ insa

func _build_trees(count: int) -> void:
	# 4 cesit: yaprakli, konik, palmiye, yuvarlak. Her cesit kendi MultiMesh'i.
	var styles := [Meshes.STYLE_LEAFY, Meshes.STYLE_CONE, Meshes.STYLE_PALM, Meshes.STYLE_ROUND]
	var weights := [0.42, 0.26, 0.12, 0.20]
	var per_style := {}
	for i in styles.size():
		per_style[styles[i]] = []

	var made := 0
	for i in count * 3:
		if made >= count:
			break
		var spot = _pick(2.0, 22.0, 0.55, 0.94)
		if spot == null:
			continue
		var style: int = _weighted_pick(styles, weights)
		per_style[style].append({
			"pos": spot,
			"scale": _rng.randf_range(0.75, 1.55) * (1.25 if style == Meshes.STYLE_PALM else 1.0),
			"rot": _rng.randf_range(0.0, TAU),
			"color": TREE_LEAF_COLORS[_rng.randi() % TREE_LEAF_COLORS.size()],
		})
		made += 1

	var total := 0
	for style in styles:
		var items: Array = per_style[style]
		if items.is_empty():
			continue
		var mesh: ArrayMesh = Meshes.tree(style, _rng.randi())
		_add_multimesh("Tree_%d" % style, mesh, items, _tree_material)
		total += items.size()
	_counts["tree"] = total


func _build_bushes(count: int) -> void:
	var items := []
	for i in count * 4:
		if items.size() >= count:
			break
		var spot = _pick(1.2, 18.0, 0.75, 0.95)
		if spot == null:
			continue
		items.append({
			"pos": spot,
			"scale": _rng.randf_range(0.7, 1.5),
			"rot": _rng.randf_range(0.0, TAU),
			"color": BUSH_COLORS[_rng.randi() % BUSH_COLORS.size()],
		})
	if items.is_empty():
		return
	_add_multimesh("Bushes", Meshes.bush(_rng.randi()), items, _bush_material)
	_counts["bush"] = items.size()


func _build_rocks(count: int) -> void:
	var items := []
	for i in count * 4:
		if items.size() >= count:
			break
		# Kayalar dik yamaclari ve kiyiyi sever: iki farkli kosul.
		var spot = _pick(0.4, 20.0, 1.6, 0.98)
		if spot == null:
			continue
		var s: float = _rng.randf_range(0.4, 1.9)
		items.append({
			"pos": spot,
			"scale": s,
			"rot": _rng.randf_range(0.0, TAU),
			"color": ROCK_COLORS[_rng.randi() % ROCK_COLORS.size()],
		})
	if items.is_empty():
		return
	_add_multimesh("Rocks", Meshes.rock(_rng.randi()), items, _rock_material)
	_counts["rock"] = items.size()


func _build_flowers(count: int) -> void:
	var items := []
	for i in count * 4:
		if items.size() >= count:
			break
		var spot = _pick(1.6, 16.0, 0.5, 0.93)
		if spot == null:
			continue
		items.append({
			"pos": spot,
			"scale": _rng.randf_range(0.8, 1.6),
			"rot": _rng.randf_range(0.0, TAU),
			"color": FLOWER_COLORS[_rng.randi() % FLOWER_COLORS.size()],
		})
	if items.is_empty():
		return
	_add_multimesh("Flowers", Meshes.flower(_rng.randi()), items, _flower_material)
	_counts["flower"] = items.size()


func _build_grass(count: int) -> void:
	# Cim tek MultiMesh: 16.000 tutam tek cizim cagrisi.
	var mesh := Meshes.grass_tuft()
	var items := []
	for i in count * 2:
		if items.size() >= count:
			break
		var spot = _pick(1.3, 20.0, 0.85, 0.95)
		if spot == null:
			continue
		items.append({
			"pos": spot,
			"scale": _rng.randf_range(0.7, 1.5),
			"rot": _rng.randf_range(0.0, TAU),
			"color": Color(1, 1, 1).lerp(TREE_LEAF_COLORS[_rng.randi() % TREE_LEAF_COLORS.size()], 0.35),
		})
	if items.is_empty():
		return
	var mmi := _add_multimesh("Grass", mesh, items, _grass_material)
	if mmi != null:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_counts["grass"] = items.size()


func _build_sand() -> void:
	# Kiyida kum yamalari: duz yatay diskler (araziye oturtulmus).
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.04
	mesh.radial_segments = 12
	mesh.rings = 1
	var items := []
	for i in sand_patch_count * 8:
		if items.size() >= sand_patch_count:
			break
		# Deniz seviyesine yakin, hafif egimli kiyi seridi.
		var spot = _pick(-0.4, 2.2, 0.45, 0.99)
		if spot == null:
			continue
		items.append({
			"pos": spot + Vector3(0.0, 0.03, 0.0),
			"scale": _rng.randf_range(4.0, 11.0),
			"rot": _rng.randf_range(0.0, TAU),
			"color": SAND_COLOR.lerp(Color(1, 1, 1), _rng.randf_range(0.0, 0.25)),
		})
	if items.is_empty():
		return
	var mmi := _add_multimesh("SandPatches", mesh, items, _sand_material)
	if mmi != null:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_counts["sand"] = items.size()


# --------------------------------------------------------------- MultiMesh

## Ornekleri tek MultiMesh'te birlestirir. Donus: olusan MeshInstance3D.
func _add_multimesh(node_name: String, mesh: Mesh, items: Array,
		material: ShaderMaterial) -> MultiMeshInstance3D:
	if items.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()

	for i in items.size():
		var it: Dictionary = items[i]
		var pos: Vector3 = it["pos"]
		var s: float = it["scale"]
		var basis := Basis(Vector3.UP, it["rot"]).scaled(Vector3(s, s, s))
		# Egimli zeminde hafifce hizala (tam dik durmasin, dogal gorunsun).
		var n := _slope_normal(pos.x, pos.z)
		if n.dot(Vector3.UP) < 0.995:
			var tilt := Basis(Quaternion(Vector3.UP, n))
			basis = tilt * basis
		mm.set_instance_transform(i, Transform3D(basis, pos))
		mm.set_instance_color(i, it["color"])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)
	return mmi



func _weighted_pick(options: Array, weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += float(w)
	var r: float = _rng.randf() * total
	var acc := 0.0
	for i in options.size():
		acc += float(weights[i])
		if r <= acc:
			return options[i]
	return options[options.size() - 1]
