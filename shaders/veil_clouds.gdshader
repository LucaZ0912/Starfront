// Package 40c (0.6.40.6): the Veil on the galaxy map – a slowly wavering band of black clouds round the cluster,
// with violet light catching in their folds and along their inner edge.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec2 centre = vec2(0.0);        // the middle of the cluster, in pixels of this rect
uniform vec2 radii = vec2(100.0, 60.0); // the core ellipse (CORE_R) in pixels
uniform float f_in = 2.36;              // where the clouds begin (× the core ellipse) …
uniform float f_out = 3.1;              // … and where they are thickest
uniform float pixel_size = 3.0;
uniform vec2 rect_size = vec2(1000.0, 600.0);

void fragment() {
	vec2 rel = UV * rect_size - centre;
	rel = floor(rel / pixel_size) * pixel_size;
	vec2 e = rel / radii;
	float d = length(e);
	float ang = atan(e.y, e.x);
	float t = TIME * 0.035;
	// the ragged, slowly moving inner edge
	float edge = f_in + 0.16 * (fbm(vec2(ang * 2.4 + t * 2.0, t)) - 0.5) + 0.07 * (fbm(vec2(ang * 9.0 - t * 3.0, 4.0)) - 0.5);
	// billowing clouds: noise in the plane (not along the ring), warped by itself, drifting slowly
	vec2 q = e * 1.5;
	vec2 warp = vec2(fbm(q + vec2(t, 1.7)), fbm(q + vec2(5.2, -t)));
	float n = fbm(q * 1.4 + warp * 1.8 + vec2(t * 0.8, -t * 0.5));
	float n2 = fbm(q * 2.0 + warp * 2.2 - vec2(t * 1.2, n * 0.8));
	float body = smoothstep(edge, edge + 0.22, d + (n - 0.5) * 0.25);
	body *= smoothstep(f_out + 1.6, f_out, d) * 0.4 + 0.6;
	if (body <= 0.01) {
		discard;
	}
	// black clouds: dark cores, a little lighter where they billow
	vec3 col = mix(vec3(0.0, 0.0, 0.004), vec3(0.11, 0.08, 0.14), smoothstep(0.42, 0.85, n2) * smoothstep(0.35, 0.7, n));
	// violet in the folds (thin ridges of the noise) and along the inner rim
	float ridge = (1.0 - smoothstep(0.0, 0.035, abs(n2 - 0.55))) * smoothstep(0.45, 0.65, n);
	float rim = 1.0 - smoothstep(0.0, 0.07, abs(d + (n - 0.5) * 0.25 - edge - 0.04));
	float pulse = 0.75 + 0.25 * sin(TIME * 0.8 + ang * 5.0 + n * 6.0);
	col += vec3(0.55, 0.2, 0.9) * ridge * 0.45 * pulse * body;
	col += vec3(0.62, 0.28, 1.0) * rim * 0.55 * pulse;
	float a = clamp(body * 0.97 + rim * 0.5, 0.0, 1.0);
	a = floor(a * 6.0) / 6.0;
	COLOR = vec4(col, a);
}
