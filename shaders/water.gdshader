shader_type spatial;
// Stilize su: hafif dalga (vertex), yari saydam, kiyida acik renk + kopuk.
// Derinlik tamamen GEOMETRIDEN gelir: derin bolgelerde duzlemle kamera
// arasindaki mesafe artar. Doku okumaya bagimli degil (guvenli).
render_mode shadows_disabled, fog_disabled;

uniform vec4 shallow_color : source_color = vec4(0.10, 0.40, 0.55, 1.0);
uniform vec4 deep_color : source_color = vec4(0.04, 0.20, 0.38, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.99, 0.99, 1.0);
uniform vec4 shore_color : source_color = vec4(0.72, 0.93, 0.90, 1.0);
uniform float wave_speed = 1.0;
uniform float wave_strength = 1.0;
uniform float alpha_shallow = 0.55;
uniform float alpha_deep = 1.0;
uniform float depth_near = 60.0;
uniform float depth_far = 130.0;

varying vec3 world_pos;

float wave_height(vec2 p, float t) {
	float h = 0.0;
	h += sin(p.x * 0.33 + p.y * 0.11 + t * 1.1) * 0.085;
	h += sin(p.y * 0.27 - p.x * 0.07 - t * 0.9) * 0.070;
	h += sin((p.x + p.y) * 0.16 + t * 1.7) * 0.045;
	return h * wave_strength;
}

void vertex() {
	float t = TIME * wave_speed;
	// Dalgalar kiyiya yakinken soner: boylece ada ile suyun bulusma hatti
	// duzgun bir cizgi olur (dalga yuzunden testere disi olusmaz).
	float world_r = length((MODEL_MATRIX * vec4(VERTEX, 1.0)).xz);
	float damp = smoothstep(78.0, 150.0, world_r);
	float h0 = wave_height(VERTEX.xz, t) * damp;
	VERTEX.y += h0;

	float e = 0.9;
	float hx = wave_height(VERTEX.xz + vec2(e, 0.0), t) * damp;
	float hz = wave_height(VERTEX.xz + vec2(0.0, e), t) * damp;
	vec3 n = normalize(vec3(-(hx - h0) / e, 1.0, -(hz - h0) / e));
	NORMAL = normalize(mix(NORMAL, n, 0.75));

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Renk, kameraya olan mesafeye DEGIL ada merkezine olan uzakliga bagli:
	// boylece kamera donerken deniz rengi degismez (eskiden asiri parlak
	// halkalar olusuyordu).
	float island_dist = length(world_pos.xz);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, smoothstep(74.0, 104.0, island_dist));

	// Kiyi hattinda ince kopuk cizgisi.
	float foam = 1.0 - smoothstep(71.0, 78.0, island_dist);
	col = mix(col, foam_color.rgb, foam * 0.45);

	ALBEDO = col;
	ROUGHNESS = 0.55;
	METALLIC = 0.0;
	SPECULAR = 0.04;

	// ONEMLI: ALPHA'ya HIC deger yazmiyoruz. Godot'ta ALPHA yazmak materyali
	// saydam hatta alir; saydam materyal DERINLIK YAZMAZ ve arazinin 200x200 m
	// kare tabani suyun ustune cizilip "kare" olarak gorunur. ALPHA yazmayinca
	// su opak olur, derinligi yazar ve kare tamamen kaybolur.
	//
	// Kiyi hissi renkle veriliyor: foam halkasi (yukarida).
}
