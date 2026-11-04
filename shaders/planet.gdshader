// Pixel-art planet with lighting, rotation and atmosphere.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 col_a : source_color = vec4(0.15, 0.3, 0.6, 1.0);   // low (ocean)
uniform vec4 col_b : source_color = vec4(0.35, 0.6, 0.3, 1.0);   // mid (land)
uniform vec4 col_c : source_color = vec4(0.9, 0.9, 0.85, 1.0);   // high (mountains/ice)
uniform vec4 atmo : source_color = vec4(0.5, 0.7, 1.0, 0.7);
uniform float pixels = 96.0;
uniform vec2 light_dir = vec2(-0.7, -0.5);  // direction towards the light source
uniform float seed = 1.0;
uniform float gas = 0.0;                    // 1 = gas giant (bands)
uniform float spin = 0.01;
uniform float radius = 0.86;                // planet radius relative to quad half-width
uniform float has_ring = 0.0;

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	float d = length(c);
	vec3 L = normalize(vec3(light_dir, 0.55));
	vec4 outc = vec4(0.0);
	if (d < radius) {
		vec2 q = c / radius;
		float z = sqrt(max(0.0, 1.0 - dot(q, q)));
		vec3 n = vec3(q, z);
		vec2 st = q / (z + 1.0);
		st.x += TIME * spin;
		float h;
		if (gas > 0.5) {
			h = fbm(vec2(st.y * 7.0 + fbm(st * 4.0 + seed) * 0.8, seed * 3.1 + st.x * 0.6));
		} else {
			h = fbm(st * 3.2 + vec2(seed * 7.3, seed));
		}
		vec3 base = col_a.rgb;
		base = mix(base, col_b.rgb, step(0.47, h));
		base = mix(base, col_c.rgb, step(0.62, h));
		float diff = clamp(dot(n, L), 0.0, 1.0);
		float lv = floor(diff * 4.0 + 0.5) / 4.0;
		vec3 col = base * (0.12 + 0.95 * lv);
		col = mix(col, atmo.rgb, pow(1.0 - z, 3.0) * atmo.a * max(lv, 0.15));
		outc = vec4(col, 1.0);
	} else if (d < radius * 1.1 && atmo.a > 0.01) {
		vec2 q = c / d;
		float lit = clamp(dot(vec3(q, 0.0), L) + 0.4, 0.0, 1.0);
		float a = (1.0 - (d - radius) / (radius * 0.1)) * atmo.a * 0.7 * lit;
		a = floor(a * 4.0) / 4.0;
		outc = vec4(atmo.rgb, a);
	}
	// Ring (front half covers the planet, back half lies behind it)
	if (has_ring > 0.5) {
		float rd = length(vec2(c.x, c.y * 3.2));
		if (rd > radius * 1.3 && rd < radius * 1.85 && (d >= radius || c.y > 0.0)) {
			float band = fbm(vec2(rd * 20.0, seed));
			vec3 rcol = mix(col_c.rgb, col_b.rgb, step(0.5, band)) * (0.6 + 0.4 * step(0.0, c.y));
			outc = vec4(rcol, 0.9);
		}
	}
	COLOR = outc;
}
