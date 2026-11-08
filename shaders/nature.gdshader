shader_type spatial;
// Dogal yasam (agac / cali / cim / cicek) icin toon malzeme.
//
// - Bantli isik + serin golge tonu (araziyle ayni dil)
// - Ruzgar: yukseklik arttikca artan yatay salinim (cim ve yapraklar sallanir)
// - Vertex rengi ile tur bazli renk cesitliligi

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shade_tint : source_color = vec4(0.34, 0.46, 0.66, 1.0);
uniform float bands = 3.0;
uniform float rim_strength = 0.18;
uniform vec4 rim_tint : source_color = vec4(1.0, 0.93, 0.78, 1.0);
uniform float brightness = 1.0;
uniform float roughness_value = 0.95;

uniform float wind_strength = 0.14;
uniform float wind_speed = 1.1;
uniform float wind_bend_power = 1.6;
uniform float wind_height = 1.0;


void vertex() {
	// Yerel yukseklik: 0 (taban) -> 1 (tepe). Ruzgar tabanı oynatmaz.
	float h = clamp(VERTEX.y / max(wind_height, 0.001), 0.0, 1.0);
	float bend = pow(h, wind_bend_power) * wind_strength;

	// Tohum: her ornek farkli fazda sallansin (INSTANCE_ID).
	float phase = float(INSTANCE_ID) * 1.7391;
	float t = TIME * wind_speed + phase;
	float sway_x = sin(t + VERTEX.x * 0.7 + VERTEX.z * 0.45);
	float sway_z = cos(t * 0.83 + VERTEX.z * 0.6 + VERTEX.x * 0.31);

	// Dunya uzayinda sabit yon (tum bitkiler ayni ruzgara tepki verir).
	VERTEX.x += sway_x * bend;
	VERTEX.z += sway_z * bend * 0.7;
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), bend * 0.4));
}

void fragment() {
	vec3 base = tint.rgb * COLOR.rgb;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = (base + rim * rim_strength * rim_tint.rgb * 0.3) * brightness;
	ALPHA = 1.0;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	// Yumusak sarma + bantli isik: cizgi film havasi korunur ama
	// renkler soluklasmasin (eski surumde isik+ortam asiri parlama yapiyordu).
	float ndl = dot(NORMAL, LIGHT);
	float wrapped = clamp(ndl * 0.5 + 0.5, 0.0, 1.0);
	float q = floor(wrapped * bands + 0.5) / bands;
	q = clamp(q, 0.30, 1.0);
	vec3 shade = shade_tint.rgb;
	DIFFUSE_LIGHT += mix(shade, vec3(1.0), smoothstep(0.25, 1.0, q)) * LIGHT_COLOR * ATTENUATION * q / PI;
}
