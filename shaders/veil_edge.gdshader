// Package 56: the Veil creeping in from the edges of the screen (the intro's jump) – dark folds of cloud with violet
// light along their front, closing in as `amount` rises from 0 to 1.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform float amount = 0.0;
uniform vec2 aspect = vec2(1.777, 1.0);
uniform float pixel = 220.0;
uniform float centre = 0.0;              // 1: it spreads from the middle out to the edges (the title card)

void fragment() {
	vec2 uv = floor(UV * pixel * aspect) / (pixel * aspect);
	vec2 p = (uv - 0.5) * aspect;
	float d = length(p / vec2(aspect.x, 1.0) * 2.0);           // 0 in the middle, ~1.41 in the corners
	float t = TIME * 0.18;
	vec2 q = p * 2.2;
	float n = fbm(q + vec2(t, -t * 0.7) + normalize(p + 0.0001) * t * 1.5) * 0.6 + fbm(q * 3.1 - vec2(t * 2.0, t)) * 0.25;
	float front = mix(1.6, 0.75, amount);
	float v = d + n * 0.45 - front;
	if (centre > 0.5) {
		v = mix(-0.25, 1.75, amount) - d - n * 0.45;
	}
	float cloud = smoothstep(-0.02, 0.18, v);
	float rim = smoothstep(-0.12, 0.0, v) * (1.0 - smoothstep(0.0, 0.14, v));
	vec3 col = mix(vec3(0.015, 0.0, 0.03), vec3(0.08, 0.015, 0.13), n);
	col += vec3(0.75, 0.35, 1.0) * rim * 1.3;
	col += vec3(0.5, 0.18, 0.8) * smoothstep(0.45, 0.75, n) * cloud * 0.3 * (1.0 - smoothstep(0.0, 0.5, v));
	if (centre > 0.5) {
		// behind the title: the Veil's folds keep moving, violet light catching in them
		float f2 = fbm(q * 1.4 + vec2(t * 0.8, t * 0.5));
		col += vec3(0.42, 0.14, 0.7) * smoothstep(0.45, 0.85, f2) * cloud * 0.55;
		col += vec3(0.25, 0.08, 0.4) * smoothstep(0.55, 0.9, n) * cloud * 0.4;
	}
	COLOR = vec4(col, max(cloud, rim * 0.85) * clamp(amount * 3.0, 0.0, 1.0));
}
