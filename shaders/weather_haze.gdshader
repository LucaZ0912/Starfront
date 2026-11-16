shader_type canvas_item;
// Package 54e (Luz): the soft part of the weather over an outdoor map – fog banks, dust and snow haze drifting with the
// wind, and over a cloud city the giant's gas torn into long veils racing across the deck. Pixelated to the art's grid.
#include "res://shaders/noise.gdshaderinc"

uniform vec4 col_a : source_color = vec4(1.0);
uniform vec4 col_b : source_color = vec4(1.0);
uniform vec4 col_c : source_color = vec4(1.0);
uniform float amount = 0.0;          // 0 … 1
uniform vec2 drift = vec2(0.05, 0.0); // how fast it moves (in 400 px per second)
uniform vec2 stretch = vec2(1.0, 1.0);
uniform float veils = 0.0;           // 0: soft banks, 1: torn horizontal veils
uniform vec2 res = vec2(1920.0, 1080.0);
uniform vec2 shift = vec2(0.0);      // the camera's offset (screen px) – the haze stays with the ground
uniform float px = 3.0;              // the art's pixel size on screen
uniform float t = 0.0;

void fragment() {
	vec2 sp = floor((UV * res - shift) / px) * px;
	vec2 uv = sp / 400.0;
	vec2 p = uv * stretch + drift * t;
	float n = fbm(p);
	float n2 = fbm(p * 1.7 + vec2(3.1, 7.7) + drift * t * 0.6);
	float a;
	vec3 c;
	if (veils > 0.5) {
		// long torn veils of the giant's gas, darker under-layers between them
		float y = uv.y * 2.4 + n2 * 1.3;
		float band = pow(sin(y * 3.14159) * 0.5 + 0.5, 1.6);
		float tear = smoothstep(0.42, 0.6, n);
		float under = smoothstep(0.48, 0.68, n2) * (1.0 - band);
		float sel = fract(floor(y) * 0.37);
		c = mix(col_a.rgb, col_b.rgb, smoothstep(0.25, 0.75, n2) * 0.8 + step(0.62, sel) * 0.2);
		c = mix(c, col_c.rgb, clamp(under * 1.4, 0.0, 1.0));
		a = max(band * tear, under * 0.75) * (0.75 + 0.25 * n);
	} else {
		float m = n * 0.7 + n2 * 0.5;
		a = smoothstep(0.42, 0.8, m);
		c = mix(col_a.rgb, col_b.rgb, smoothstep(0.35, 0.7, n2));
	}
	COLOR = vec4(c, clamp(a * amount, 0.0, 1.0));
}
