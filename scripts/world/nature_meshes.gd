extends RefCounted
## Dogal yasam icin prosedurel modeller (dis varlik yok).
##
## Tum modeller ilkel mesh'lerden birlestirilir; boylece her tur tek bir
## ArrayMesh olur ve MultiMesh ile tek cizim cagrisinda cizilir.
##
## Yerel koordinat: taban y=0, yukari +y. Boyut 1 birim kabul edilir;
## gercek boyut MultiMesh transform'unda olceklendirilir.

const STYLE_LEAFY := 0
const STYLE_CONE := 1
const STYLE_PALM := 2
const STYLE_ROUND := 3


## Yaprakli / konik / palmiye / yuvarlak agac.
static func tree(style: int, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	match style:
		STYLE_CONE:
			_trunk(st, 0.13, 0.9)
			_cone(st, 0.62, 1.10, 1.05, 0.06)
			_cone(st, 0.50, 0.95, 1.85, 0.06)
			_cone(st, 0.36, 0.80, 2.55, 0.06)
		STYLE_PALM:
			_trunk(st, 0.10, 1.75)
			# 6 yaprak: yatay egik koniler
			var leaves := 6
			for i in leaves:
				var ang := TAU * float(i) / float(leaves) + rng.randf_range(-0.25, 0.25)
				_palm_leaf(st, ang, rng.randf_range(0.85, 1.15))
		STYLE_ROUND:
			_trunk(st, 0.12, 1.05)
			_ball(st, Vector3(0.0, 1.85, 0.0), 0.72, 10, 6)
			_ball(st, Vector3(0.32, 1.55, 0.12), 0.45, 8, 5)
			_ball(st, Vector3(-0.28, 1.60, -0.16), 0.42, 8, 5)
		_:
			# Yaprakli: ana govde + 3 yumusak tac
			_trunk(st, 0.16, 1.15)
			_ball(st, Vector3(0.0, 1.80, 0.0), 0.85, 12, 7)
			_ball(st, Vector3(0.42, 1.45, -0.22), 0.55, 9, 5)
			_ball(st, Vector3(-0.40, 1.52, 0.20), 0.50, 9, 5)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## Cali: alcak, 2-3 yumusak topak.
static func bush(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ball(st, Vector3(0.0, 0.28, 0.0), 0.34, 8, 5)
	_ball(st, Vector3(0.26, 0.22, 0.10), 0.24, 7, 4)
	_ball(st, Vector3(-0.22, 0.24, -0.12), 0.26, 7, 4)
	if rng.randf() > 0.5:
		_ball(st, Vector3(0.05, 0.44, -0.14), 0.20, 7, 4)
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## Cicek: ince sap + kucuk tac (vertex renkli).
static func flower(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_trunk(st, 0.016, 0.26, Color(0.55, 0.60, 0.55))
	_ball(st, Vector3(0.0, 0.28, 0.0), 0.055, 6, 3)
	_ball(st, Vector3(0.045, 0.27, 0.02), 0.040, 5, 3)
	_ball(st, Vector3(-0.042, 0.28, -0.015), 0.038, 5, 3)
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## Kaya: rastgele bozulmus alcak cok yuzlu.
static func rock(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 5
	var seg := 8
	var prev_ring: Array[Vector3] = []
	for r in rings + 1:
		var v := float(r) / float(rings)
		var y := v * 0.55
		var radius: float = sin(v * PI) * 0.55 + 0.02
		var ring: Array[Vector3] = []
		for i in seg:
			var a := TAU * float(i) / float(seg)
			var jitter: float = 1.0 + rng.randf_range(-0.22, 0.22)
			ring.append(Vector3(cos(a) * radius * jitter, y, sin(a) * radius * jitter))
		if r > 0:
			for i in seg:
				var i2 := (i + 1) % seg
				_tri(st, prev_ring[i], ring[i], prev_ring[i2])
				_tri(st, ring[i], ring[i2], prev_ring[i2])
		prev_ring = ring
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## Cim tutami: 3 ince capraz yaprak. Vertex rengi ile taban koyu, uc acik.
static func grass_tuft() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color(0.62, 0.62, 0.62)
	var light := Color(1.0, 1.0, 1.0)
	for i in 3:
		var a := TAU * float(i) / 3.0
		var dir := Vector3(cos(a), 0.0, sin(a)) * 0.16
		var tip := Vector3(cos(a) * 0.05, 0.42, sin(a) * 0.05)
		var side := Vector3(-sin(a), 0.0, cos(a)) * 0.05
		_vert(st, Vector3(0, 0, 0) - side, dark)
		_vert(st, Vector3(0, 0, 0) + side, dark)
		_vert(st, tip, light)
	return st.commit()


# ---------------------------------------------------------------- yardimcilar

static func _vert(st: SurfaceTool, p: Vector3, c: Color) -> void:
	st.set_color(c)
	st.add_vertex(p)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


static func _trunk(st: SurfaceTool, r: float, h: float, col: Color = Color(0.42, 0.30, 0.20)) -> void:
	var seg := 7
	var rings := 3
	for ri in rings:
		var y0 := h * float(ri) / float(rings)
		var y1 := h * float(ri + 1) / float(rings)
		var r0 := r * (1.0 - 0.18 * float(ri) / float(rings))
		var r1 := r * (1.0 - 0.18 * float(ri + 1) / float(rings))
		for i in seg:
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			_col_tri(st, p00, p01, p10, col)
			_col_tri(st, p01, p11, p10, col)


static func _col_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	for p in [a, b, c]:
		st.set_color(col)
		st.set_normal(n)
		st.add_vertex(p)


static func _ball(st: SurfaceTool, center: Vector3, radius: float, seg: int, rings: int, col: Color = Color(1, 1, 1)) -> void:
	for r in rings:
		var v0 := float(r) / float(rings)
		var v1 := float(r + 1) / float(rings)
		var phi0 := v0 * PI
		var phi1 := v1 * PI
		for i in seg:
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			var p00 := center + _sph(radius, phi0, a0)
			var p01 := center + _sph(radius, phi0, a1)
			var p10 := center + _sph(radius, phi1, a0)
			var p11 := center + _sph(radius, phi1, a1)
			_col_tri(st, p00, p01, p10, col)
			_col_tri(st, p01, p11, p10, col)


static func _sph(radius: float, phi: float, theta: float) -> Vector3:
	return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)) * radius


static func _cone(st: SurfaceTool, radius: float, height: float, base_y: float, _pad: float) -> void:
	var seg := 9
	var tip := Vector3(0.0, base_y + height, 0.0)
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var p0 := Vector3(cos(a0) * radius, base_y, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, base_y, sin(a1) * radius)
		_col_tri(st, p0, p1, tip, Color(1, 1, 1))
		# taban (kapat)
		_col_tri(st, p1, p0, Vector3(0.0, base_y, 0.0), Color(1, 1, 1))


static func _palm_leaf(st: SurfaceTool, angle: float, length: float) -> void:
	# Egik, iki ucgenli basit bir yaprak.
	var dir := Vector3(cos(angle), 0.0, sin(angle))
	var side := Vector3(-sin(angle), 0.0, cos(angle))
	var root := Vector3(0.0, 1.75, 0.0)
	var mid := root + dir * (length * 0.5) + Vector3(0, 0.22, 0)
	var tip := root + dir * length + Vector3(0, -0.10, 0)
	_col_tri(st, root, mid + side * 0.22, mid, Color(1, 1, 1))
	_col_tri(st, root, mid, mid - side * 0.22, Color(1, 1, 1))
	_col_tri(st, mid + side * 0.22, tip, mid, Color(1, 1, 1))
	_col_tri(st, mid, tip, mid - side * 0.22, Color(1, 1, 1))
