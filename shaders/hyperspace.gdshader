// Warp/hyperspace tunnel: radial light streaks + vortex.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 tint : source_color = vec4(0.5, 0.75, 1.0, 1.0);
uniform float intensity = 1.0;
uniform float speed = 1.5;
uniform float swirl = 0.0;   // 1 = hyperspace (vortex), 0 = warp (streaks)
uniform vec2 aspect = vec2(1.777, 1.0);

void fragment() {
	vec2 uv = (UV - 0.5) * aspect;
	uv = floor(uv * 260.0) / 260.0;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float depth = 0.12 / max(r, 0.001) + TIME * speed;
	float seg = floor((a + PI) / (2.0 * PI) * 220.0);
	float h = hash21(vec2(seg, 3.1));
	float s = fract(depth * 0.35 + h * 9.0);
	float streak = smoothstep(0.75, 1.0, s) * smoothstep(0.03, 0.35, r) * step(0.45, h);
	vec3 col = tint.rgb * streak * 1.6;
	float tun = fbm(vec2(a * 2.0 + depth * swirl * 0.6, depth * 0.8));
	col += tint.rgb * tun * 0.35 * smoothstep(0.0, 0.5, r) * (0.4 + swirl);
	col += mix(tint.rgb, vec3(1.0), 0.6) * smoothstep(0.18, 0.0, r) * 1.2;
	COLOR = vec4(col, intensity);
}
