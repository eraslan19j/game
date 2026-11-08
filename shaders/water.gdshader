shader_type spatial;
// Stilize su: hafif dalga (vertex), yari saydam, kiyida acik renk + kopuk.
// Arazi yukseklik dokusu R kanalinda 0..1 olarak gelir.

uniform sampler2D terrain_height : filter_linear, repeat_disable;
uniform float terrain_size = 200.0;
uniform float height_min = -30.0;
uniform float height_max = 45.0;
uniform float wave_speed = 1.0;
uniform float wave_strength = 1.0;
uniform vec4 shallow_color : source_color = vec4(0.48, 0.83, 0.80, 1.0);
uniform vec4 deep_color : source_color = vec4(0.10, 0.41, 0.55, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.99, 0.99, 1.0);
uniform float alpha_shallow = 0.42;
uniform float alpha_deep = 0.90;

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

	// Normal'i dalga turevi ile yumusakca boz.
	float e = 0.9;
	float hx = wave_height(VERTEX.xz + vec2(e, 0.0), t);
	float hz = wave_height(VERTEX.xz + vec2(0.0, e), t);
	vec3 n = normalize(vec3(-(hx - h0) / e, 1.0, -(hz - h0) / e));
	NORMAL = normalize(mix(NORMAL, n, 0.75));

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Bu noktanin altindaki arazi yuksekligi.
	vec2 tuv = world_pos.xz / terrain_size + 0.5;
	float inside = step(0.0, tuv.x) * step(tuv.x, 1.0) * step(0.0, tuv.y) * step(tuv.y, 1.0);
	float th = height_min;
	if (inside > 0.5) {
		float raw = texture(terrain_height, tuv).r;
		th = mix(height_min, height_max, raw);
	}

	// Su derinligi (0 = kiyi, buyuk = derin).
	float depth = clamp(world_pos.y - th, 0.0, 60.0);

	float deep_mix = smoothstep(0.4, 6.0, depth);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, deep_mix);

	// Kiyida beyaz kopuk bandi.
	float foam = 1.0 - smoothstep(0.0, 0.55, depth);
	col = mix(col, foam_color.rgb, foam * 0.85);

	ALBEDO = col;
	ROUGHNESS = 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.45;
	ALPHA = mix(alpha_shallow, alpha_deep, deep_mix) + foam * 0.25;
	ALPHA = clamp(ALPHA, 0.0, 1.0);

	// Hafif isilti (gunes parlamasi) icin normali kullaniyoruz; ekstra efekt yok.
	NORMAL_MAP_DEPTH = 0.0;
}
