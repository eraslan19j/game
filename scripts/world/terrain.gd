extends StaticBody3D
## Prosedurel ada arazi uretimi.
##
## - Tepeler/vadiler: FastNoiseLite (kodla uretilir, dis gorsel yok)
## - Ada sekli: merkeze uzakliga gore yumusak dusus (radial falloff)
## - Renkler: yukseklik + egime gore vertex renkleri (tek cizim cagrisi)
## - Carpisma: ayni mesh'ten uretilen trimesh (karakter uzerinde yuruyebilir)
## - Su icin: yukseklikleri kucuk bir dokuya yazip su shader'ina verir

@export var world_size: float = 200.0
@export var grid_cells: int = 176
@export var island_radius: float = 72.0
@export var sea_level: float = 0.0
@export var base_height: float = 5.5
@export var hill_amplitude: float = 9.0
@export var detail_amplitude: float = 3.0
@export var noise_seed: int = 20261108
@export var toon_material: Material = null

# Su shader'inin kullanacagi olcek (doku 0..1 arasina sikistirilir).
const HEIGHT_MIN: float = -30.0
const HEIGHT_MAX: float = 45.0

var height_texture: ImageTexture = null
var height_min: float = HEIGHT_MIN
var height_max: float = HEIGHT_MAX

# Dogal yasam (agac/cim/kaya) icin hizli sorgu: mesh uretilirken saklanir.
var heights_grid: PackedFloat32Array = PackedFloat32Array()
var grid_n: int = 0

var _cell: float = 1.0
var _noise_big: FastNoiseLite
var _noise_small: FastNoiseLite
var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_setup_noise()
	var built := _build_mesh()
	heights_grid = built["heights"]
	grid_n = built["n"]
	_add_collision(built["mesh"])
	_build_height_texture(built["heights"], built["n"])
	_report_stats(built["heights"])


## Izgara uzerinden iki dogrusal (bilinear) yukseklik: doga yerlestirmesi icin hizli.
func sample_height(x: float, z: float) -> float:
	if grid_n < 2:
		return height_at(x, z)
	var half: float = world_size * 0.5
	var fx: float = clampf((x + half) / _cell, 0.0, float(grid_n - 1) - 0.001)
	var fz: float = clampf((z + half) / _cell, 0.0, float(grid_n - 1) - 0.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx: float = fx - float(ix)
	var tz: float = fz - float(iz)
	var i0: int = iz * grid_n + ix
	var h00: float = heights_grid[i0]
	var h10: float = heights_grid[i0 + 1]
	var h01: float = heights_grid[i0 + grid_n]
	var h11: float = heights_grid[i0 + grid_n + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


## Egim: 0 = tamamen duz, 1 = cok dik. (normalin y'si = 1/sqrt(1+egim^2))
func sample_slope(x: float, z: float) -> float:
	var e: float = maxf(_cell, 0.5)
	var dx: float = (sample_height(x + e, z) - sample_height(x - e, z)) / (2.0 * e)
	var dz: float = (sample_height(x, z + e) - sample_height(x, z - e)) / (2.0 * e)
	return sqrt(dx * dx + dz * dz)


func sample_normal_y(x: float, z: float) -> float:
	var sl := sample_slope(x, z)
	return 1.0 / sqrt(1.0 + sl * sl)


## Baslangicta tek satir ozet yazar (ada gercekten ada mi?).
func _report_stats(heights: PackedFloat32Array) -> void:
	var h_min := 1.0e9
	var h_max := -1.0e9
	var above := 0
	for h in heights:
		h_min = minf(h_min, h)
		h_max = maxf(h_max, h)
		if h > sea_level:
			above += 1
	var land_pct := 100.0 * float(above) / float(heights.size())
	print("[Terrain] %dx%d  yukseklik=[%.1f .. %.1f] m  kara=%%%.1f  cevre=%.1f m"
		% [grid_cells, grid_cells, h_min, h_max, land_pct, world_size])


func _setup_noise() -> void:
	_noise_big = FastNoiseLite.new()
	_noise_big.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_big.seed = noise_seed
	_noise_big.frequency = 0.011
	_noise_big.fractal_octaves = 3
	_noise_big.fractal_lacunarity = 2.0
	_noise_big.fractal_gain = 0.45

	_noise_small = FastNoiseLite.new()
	_noise_small.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise_small.seed = noise_seed + 1337
	_noise_small.frequency = 0.055
	_noise_small.fractal_octaves = 2


## Belirli bir dunya noktasindaki arazi yuksekligi (metre).
## Baska scriptler (agac/kaya yerlestirme, ileride karakter) bunu kullanabilir.
func height_at(x: float, z: float) -> float:
	var d := Vector2(x, z).length() / maxf(island_radius, 0.001)
	# ADA KENARI: duz plato + dik kiyi. Onceki yumusak dusus 74 m genis
	# kayalik bir yamac olusturup suyu ufka itiyordu.
	var falloff := smoothstep(1.0, 0.74, d)

	var big := _noise_big.get_noise_2d(x, z)
	var small := _noise_small.get_noise_2d(x, z)
	var h := falloff * (base_height + big * hill_amplitude + small * detail_amplitude)
	# Kiyidan sonra hizli derinlesme: sig sahanligi yerine gercek derin su.
	h += (falloff - 1.0) * 7.0
	return h + sea_level


func is_underwater(x: float, z: float) -> bool:
	return height_at(x, z) < sea_level + 0.8


func _build_mesh() -> Dictionary:
	var n: int = grid_cells + 1
	_cell = world_size / float(grid_cells)
	var half: float = world_size * 0.5

	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for iz in n:
		var z: float = -half + float(iz) * _cell
		for ix in n:
			var x: float = -half + float(ix) * _cell
			heights[iz * n + ix] = height_at(x, z)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	verts.resize(n * n)
	norms.resize(n * n)
	cols.resize(n * n)

	for iz in n:
		for ix in n:
			var idx: int = iz * n + ix
			var x: float = -half + float(ix) * _cell
			var z: float = -half + float(iz) * _cell
			var h: float = heights[idx]
			# Denizin altindaki kisimlar su seviyesinin biraz altinda tutulur:
			# kiyi hattinda testere disi olusmaz, ada da havada durmaz.
			if h < -12.0:
				h = -12.0
			verts[idx] = Vector3(x, h, z)

			# Komsulardan egim -> normal (kenarlarda tek tarafli fark).
			var ix0: int = maxi(ix - 1, 0)
			var ix1: int = mini(ix + 1, n - 1)
			var iz0: int = maxi(iz - 1, 0)
			var iz1: int = mini(iz + 1, n - 1)
			var dx: float = maxf(float(ix1 - ix0) * _cell, 0.0001)
			var dz: float = maxf(float(iz1 - iz0) * _cell, 0.0001)
			var dhdx: float = (heights[iz * n + ix1] - heights[iz * n + ix0]) / dx
			var dhdz: float = (heights[iz1 * n + ix] - heights[iz0 * n + ix]) / dz
			var nrm := Vector3(-dhdx, 1.0, -dhdz).normalized()
			norms[idx] = nrm
			cols[idx] = _color_for(h, nrm.y)

	# ONEMLI: deniz seviyesinin ALTINDA kalan (deniz tabani) kareler HIC
	# uretilmez. Arazi 200x200 m'lik bir kare oldugu icin, taban uretildiginde
	# su yuzeyiyle derinlik catismasi yasaniyor ve goruntude belirgin bir KARE
	# olusuyordu. Sadece adanin kendisi cizilince boyle bir yuzey kalmiyor;
	# su zaten her yeri kapliyor. Kiyi hatti da daha dogal gorunuyor.
	const SEA_CULL: float = -4.5
	# Once hangi karelerin uretilecegine karar ver. Sonra kesim sinirindaki
	# (deniz alti komsusu olan) kose noktalarini su seviyesine indir: boylece
	# kiyi hatti duzgun bir cizgi olur, testere disi kalmaz.
	var keep: PackedByteArray = PackedByteArray()
	keep.resize(grid_cells * grid_cells)
	var edge_vert: PackedByteArray = PackedByteArray()
	edge_vert.resize(n * n)
	for iz in grid_cells:
		for ix in grid_cells:
			var i0: int = iz * n + ix
			var i1: int = i0 + 1
			var i2: int = i0 + n
			var i3: int = i2 + 1
			var inside: bool = not (heights[i0] < SEA_CULL and heights[i1] < SEA_CULL \
					and heights[i2] < SEA_CULL and heights[i3] < SEA_CULL)
			keep[iz * grid_cells + ix] = 1 if inside else 0
	for iz in grid_cells:
		for ix in grid_cells:
			if keep[iz * grid_cells + ix] == 0:
				continue
			var i0: int = iz * n + ix
			var i2: int = i0 + n
			var neigh: Array = []
			if ix > 0: neigh.append(keep[iz * grid_cells + (ix - 1)])
			if ix < grid_cells - 1: neigh.append(keep[iz * grid_cells + (ix + 1)])
			if iz > 0: neigh.append(keep[(iz - 1) * grid_cells + ix])
			if iz < grid_cells - 1: neigh.append(keep[(iz + 1) * grid_cells + ix])
			if neigh.has(0):
				edge_vert[i0] = 1
				edge_vert[i0 + 1] = 1
				edge_vert[i2] = 1
				edge_vert[i2 + 1] = 1
	# Kesim kenarini DUZGUN BIR DAIREYE oturt: aksi halde grid hucrelerinden
	# dolayi kiyida testere disi (zikzak) olusur. Kenar noktalari, ada
	# merkezinden bakildiginda sabit yaricapli bir cember uzerine cekilir.
	for iz in n:
		for ix in n:
			if edge_vert[iz * n + ix] == 1:
				var v: Vector3 = verts[iz * n + ix]
				verts[iz * n + ix] = Vector3(v.x, -5.0, v.z)

	var indices := PackedInt32Array()
	indices.resize(grid_cells * grid_cells * 6)
	var k: int = 0
	for iz in grid_cells:
		for ix in grid_cells:
			var i0: int = iz * n + ix
			var i1: int = i0 + 1
			var i2: int = i0 + n
			var i3: int = i2 + 1
			# Denizin altindaki kareler uretilmez (yukarida keep[] ile
			# isaretlendi). Kiyi hattinda kucuk bir "etek" birakilir: ada
			# havada yuzuyormus gibi durmaz. Etek deniz tabani renginde.
			if keep[iz * grid_cells + ix] == 0:
				continue
			# Saat yonunun tersi (yukari bakan yuz): ConcavePolygonShape3D
			# tek tarafli oldugu icin yon onemli — yanlissa isin/carpisma gecmez.
			indices[k] = i0
			indices[k + 1] = i1
			indices[k + 2] = i2
			k += 3
			indices[k] = i1
			indices[k + 1] = i3
			indices[k + 2] = i2
			k += 3
	indices.resize(k)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Toon (boyalı) malzeme; yoksa duz standart malzemeye dus.
	var mat: Material = toon_material
	if mat == null:
		var std := StandardMaterial3D.new()
		std.vertex_color_use_as_albedo = true
		std.roughness = 0.95
		std.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat = std
	mesh.surface_set_material(0, mat)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Mesh"
	_mesh_instance.mesh = mesh
	# Arazi golge dussun = KAPALI (200x200 m duz levha suya dev golge dusuruyordu).
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)

	return {"mesh": mesh, "heights": heights, "n": n}


func _add_collision(mesh: ArrayMesh) -> void:
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Shape"
	shape_node.shape = mesh.create_trimesh_shape()
	add_child(shape_node)


## Su shader'i icin yukseklik dokusu (0..1 araligina normalize edilmis).
func _build_height_texture(heights: PackedFloat32Array, n: int) -> void:
	# Gercek min/max'i bul: sabit aralik kullanmak derinligi yanlis hesaplatiyordu.
	var lo := 1.0e9
	var hi := -1.0e9
	for h in heights:
		lo = minf(lo, h)
		hi = maxf(hi, h)
	# Su yuzeyinin (0 m) tam ortada kalmasi icin araligi iki tarafa da genislet.
	var reach: float = maxf(maxf(absf(lo), absf(hi)), 1.0)
	height_min = -reach
	height_max = reach

	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var span: float = maxf(height_max - height_min, 0.001)
	for iz in n:
		for ix in n:
			var v: float = (heights[iz * n + ix] - height_min) / span
			v = clampf(v, 0.0, 1.0)
			img.set_pixel(ix, iz, Color(v, 0.0, 0.0))
	height_texture = ImageTexture.create_from_image(img)


## Cizgi film havasi icin yukseklik/egime gore sabit renkler.
func _color_for(h: float, normal_y: float) -> Color:
	# Su altindaki zemin de SU RENGINE boyanir: yari saydam suyun altindan
	# parlak kum gorunup "gri kare" gibi durmasini engeller.
	# Su shader'indaki derin/sig tonlarin AYNISI: deniz altindaki arazi
	# suyla ayni renkte olsun, kiyi cevresinde acik halka olusmasin.
	var seabed := Color(0.04, 0.20, 0.38)
	var seabed_shallow := Color(0.10, 0.40, 0.55)
	# Arazi zemin tonlari (bitki/agac tonlariyla ayni doygunlukta).
	var sand := Color(0.82, 0.72, 0.48)
	var grass_low := Color(0.20, 0.46, 0.16)
	var grass_high := Color(0.36, 0.60, 0.20)
	var rock := Color(0.45, 0.43, 0.40)

	if h < sea_level - 3.0:
		return seabed
	if h < sea_level - 0.2:
		return seabed.lerp(seabed_shallow, clampf((h - (sea_level - 3.0)) / 2.8, 0.0, 1.0))
	if h < sea_level + 1.0:
		return seabed_shallow.lerp(sand, clampf((h - (sea_level - 0.2)) / 1.2, 0.0, 1.0))
	# Sadece GERCEKTEN dik yamaclarda kaya rengi (eskiden 0.80 idi ve butun
	# tepeler kumlu lekeler gibi gorunuyordu).
	if normal_y < 0.60:
		return sand.lerp(rock, 0.55)
	var t: float = clampf((h - (sea_level + 1.0)) / 16.0, 0.0, 1.0)
	return grass_low.lerp(grass_high, t)
