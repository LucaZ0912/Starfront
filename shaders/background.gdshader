// Full-screen background: nebula + several star layers with parallax.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec2 offset = vec2(0.0);       // camera position in screen pixels
uniform vec4 neb_a : source_color = vec4(0.3, 0.15, 0.5, 1.0);
uniform vec4 neb_b : source_color = vec4(0.1, 0.35, 0.55, 1.0);
uniform float seed = 1.0;
uniform float neb_strength = 1.0;
uniform float pixel_size = 3.0;
uniform float veil = 0.0;               // package 40c: the edge of the Veil
uniform vec2 veil_dir = vec2(1.0, 0.0);

void fragment() {
	vec2 px = floor(FRAGCOORD.xy / pixel_size) * pixel_size;
	vec2 p = (px + offset * 0.04) / 700.0;
	float n = fbm(p * 1.6 + seed);
	float n2 = fbm(p * 2.7 - seed * 1.7 + vec2(n * 1.5));
	vec3 col = vec3(0.008, 0.01, 0.025);
	float a = smoothstep(0.45, 0.85, n2);
	float b = smoothstep(0.5, 0.9, n);
	a = floor(a * 5.0) / 5.0;
	b = floor(b * 5.0) / 5.0;
	col += neb_a.rgb * a * 0.35 * neb_strength + neb_b.rgb * b * 0.25 * neb_strength;
	if (veil > 0.0) {
		// a curtain of violet light, brighter towards the Veil, slowly rippling
		vec2 uv = (px - SCREEN_PIXEL_SIZE * 0.0) * SCREEN_PIXEL_SIZE - 0.5;
		float side = clamp(dot(uv, normalize(veil_dir)) + 0.55, 0.0, 1.2);
		float w = fbm(vec2(dot(px, vec2(-veil_dir.y, veil_dir.x)) / 260.0, TIME * 0.05) + seed);
		float folds = 0.5 + 0.5 * sin(dot(px, vec2(-veil_dir.y, veil_dir.x)) / 90.0 + w * 6.0 + TIME * 0.2);
		float v = floor(side * folds * (0.6 + w) * 5.0) / 5.0;
		col += vec3(0.42, 0.18, 0.75) * v * 0.22 * veil;
	}
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec2 sp = (FRAGCOORD.xy + offset * (0.08 + 0.12 * fi)) / (pixel_size * (1.0 + fi * 0.0));
		vec2 cell = floor(sp);
		float h = hash21(cell + fi * 31.7 + seed);
		if (h > 0.9965 - fi * 0.001) {
			float br = 0.35 + 0.65 * hash21(cell * 1.7 + fi);
			br *= 0.88 + 0.12 * sin(TIME * (0.35 + h * 0.9) + h * 50.0);     // 0.6.39.3: a gentle, slow twinkle
			vec3 sc = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.9, 0.7), hash21(cell + 3.0));
			col += sc * br * (1.0 - fi * 0.25);
		}
	}
	COLOR = vec4(col, 1.0);
}
