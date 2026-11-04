// Pixel-art star with a shimmering corona.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform float pixels = 120.0;
uniform float radius = 0.45;

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	float d = length(c);
	float ang = atan(c.y, c.x);
	vec4 outc = vec4(0.0);
	if (d < radius) {
		float n = fbm(c * 6.0 + vec2(TIME * 0.15, -TIME * 0.1));
		float lv = floor((0.75 + 0.5 * n - d / radius * 0.35) * 4.0) / 4.0;
		vec3 col = mix(color.rgb, vec3(1.0, 1.0, 0.95), clamp(lv - 0.4, 0.0, 1.0));
		outc = vec4(col * (0.8 + 0.4 * lv), 1.0);
	} else {
		float flick = fbm(vec2(ang * 3.0, TIME * 0.4)) * 0.35;
		float g = 1.0 - (d - radius) / (1.0 - radius);
		g = clamp(g + flick - 0.2, 0.0, 1.0);
		g = pow(g, 2.2);
		g = floor(g * 6.0) / 6.0;
		outc = vec4(color.rgb, g * 0.85);
	}
	COLOR = outc;
}
