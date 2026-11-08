shader_type spatial;
// Stilize su: hafif dalga (vertex), yari saydam, kiyida acik renk + kopuk.
// Derinlik tamamen GEOMETRIDEN gelir: derin bolgelerde duzlemle kamera
// arasindaki mesafe artar. Doku okumaya bagimli degil (guvenli).
render_mode shadows_disabled;

uniform vec4 shallow_color : source_color = vec4(0.30, 0.78, 0.78, 1.0);
uniform vec4 deep_color : source_color = vec4(0.05, 0.31, 0.50, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.99, 0.99, 1.0);
uniform vec4 shore_color : source_color = vec4(0.72, 0.93, 0.90, 1.0);
uniform float wave_speed = 1.0;
uniform float wave_strength = 1.0;
uniform float alpha_shallow = 0.55;
uniform float alpha_deep = 0.95;
uniform float depth_near = 90.0;
uniform float depth_far = 330.0;

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
	float h0 = wave_height(VERTEX.xz, t);
	VERTEX.y += h0;

	float e = 0.9;
	float hx = wave_height(VERTEX.xz + vec2(e, 0.0), t);
	float hz = wave_height(VERTEX.xz + vec2(0.0, e), t);
	vec3 n = normalize(vec3(-(hx - h0) / e, 1.0, -(hz - h0) / e));
	NORMAL = normalize(mix(NORMAL, n, 0.75));

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Kamera ile bu nokta arasindaki mesafe: ada uzerinde kisa, acik denizde uzun.
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	// Ada merkezine uzaklik: kiyiya yakin mi?
	float island_dist = length(world_pos.xz);

	float far_mix = smoothstep(depth_near, depth_far, dist);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, far_mix);

	// Ada cevresinde ince acik kiyi halkasi.
	float shore = 1.0 - smoothstep(72.0, 96.0, island_dist);
	col = mix(col, shore_color.rgb, shore * 0.55);
	float foam = (1.0 - smoothstep(76.0, 84.0, island_dist)) * shore;
	col = mix(col, foam_color.rgb, foam * 0.6);

	ALBEDO = col;
	ROUGHNESS = 0.55;
	METALLIC = 0.0;
	SPECULAR = 0.04;

	// Kiyida daha saydam, acik denizde neredeyse opak.
	float a = mix(alpha_shallow, alpha_deep, far_mix);
	a = max(a, shore * 0.75);
	ALPHA = clamp(a, 0.0, 1.0);
}
