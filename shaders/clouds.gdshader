shader_type spatial;
// Stilize bulut kubbesi: kodla uretilen gurultu dokusundan yumusak bulutlar.
// Kubbe kamerayi cevreledigi icin ic yuzu cizilir (cull_disabled).
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, fog_disabled;

uniform sampler2D cloud_noise : filter_linear, repeat_enable;
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 cloud_shade : source_color = vec4(0.86, 0.89, 0.96, 1.0);
uniform float coverage = 0.46;
uniform float softness = 0.22;
uniform float speed = 0.006;
uniform float tiling = 2.0;
uniform float alpha_scale = 0.92;
uniform float warp = 0.35;

void fragment() {
	vec2 base_uv = UV * tiling;
	vec2 drift = vec2(TIME * speed, TIME * speed * 0.35);

	// Iki katman: biri yavas buyuk bulutlar, digeri daha ince detay.
	float n1 = texture(cloud_noise, base_uv + drift).r;
	float n2 = texture(cloud_noise, base_uv * 2.13 - drift * 1.7 + vec2(0.37, 0.61)).r;
	float d = mix(n1, n2, warp);

	// Esik + yumusak gecis -> bulut kenarlari.
	float edge = 1.0 - coverage;
	float a = smoothstep(edge, edge + softness, d);

	// Bulutun alt kisimlari hafif koyu (hacim hissi).
	float v = clamp(UV.y, 0.0, 1.0);
	vec3 col = mix(cloud_shade.rgb, cloud_color.rgb, smoothstep(0.15, 0.75, a));

	ALBEDO = col;
	ALPHA = a * alpha_scale;
	// Ufka yaklastikca solsun (sert bant olusmasin).
	float horizon_fade = smoothstep(0.02, 0.30, v);
	ALPHA *= horizon_fade * (1.0 - smoothstep(0.72, 1.0, v) * 0.85);
}
