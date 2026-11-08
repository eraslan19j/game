shader_type spatial;
// Toon / "boyalı" gorunum: isigi bantlara boler, golgede serin ton verir,
// kenarlarda yumusak rim (isik halesi) ekler. GL Compatibility ile uyumlu.

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_vertex_color = true;
uniform float bands = 3.0;
uniform vec4 shade_tint : source_color = vec4(0.42, 0.52, 0.72, 1.0);
uniform vec4 rim_tint : source_color = vec4(1.0, 0.93, 0.78, 1.0);
uniform float rim_strength = 0.22;
uniform float roughness_value = 0.95;
uniform float brightness = 1.0;
// Arazi icin: ada disindaki (uzak + su alti) kisimlari kirp.

void fragment() {
	vec3 base = albedo.rgb;
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = (base + rim * rim_strength * rim_tint.rgb * 0.35) * brightness;
	ALPHA = albedo.a;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// Yumusak sarma: gölgeli taraf tamamen siyah olmasin (cizgi film havasi).
	float wrapped = clamp(ndl * 0.5 + 0.5, 0.0, 1.0);
	// Bantlama: 3-4 kademeli keskin gecisler.
	float q = floor(wrapped * bands + 0.5) / bands;
	q = clamp(q, 0.12, 1.0);
	vec3 tint = mix(shade_tint.rgb, vec3(1.0, 1.0, 1.0), smoothstep(0.2, 0.95, q));
	DIFFUSE_LIGHT += tint * LIGHT_COLOR * ATTENUATION * q * 0.82 / PI;
}
