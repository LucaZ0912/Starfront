// Pixel-art neutron star (package 37): a tiny blinding core, huge loops of magnetic field lines with plasma
// flowing along them, and two jets along the magnetic axis that sweep round like a lighthouse.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(0.5, 0.6, 1.0, 1.0);     // field lines
uniform vec4 color2 : source_color = vec4(0.45, 1.0, 0.95, 1.0);  // jets
uniform float pixels = 400.0;
uniform float core = 0.03;          // core radius relative to the quad half-width
uniform float seed = 1.0;
uniform float spin = 0.12;           // turns of the magnetic axis (rad / s)

vec2 rot(vec2 p, float a) {
	float cs = cos(a);
	float sn = sin(a);
	return vec2(cs * p.x + sn * p.y, -sn * p.x + cs * p.y);
}

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	float d = length(c);
	float t = TIME;
	float axis = 0.75 + seed + t * spin;
	vec2 p = rot(c, axis);                 // p.y along the magnetic axis
	float a = 0.0;
	vec3 col = vec3(0.0);
	// field lines: dipole loops r = L sin²θ, each pair seen a little tilted (wider or narrower)
	for (int k = 0; k < 7; k++) {
		float fk = float(k);
		float L = 0.2 + 0.11 * fk + 0.05 * hash21(vec2(fk, seed));
		float squash = 0.55 + 0.9 * hash21(vec2(seed, fk + 2.0));
		vec2 q = vec2(p.x * squash, p.y);
		float r = length(q);
		float s = abs(q.x) / max(r, 0.0001);
		float f = r / max(s * s, 0.0001);
		float w = 0.02 + 0.035 * L;
		float line = exp(-pow((f - L) / w, 2.0));
		line *= smoothstep(core * 1.5, core * 5.0, r);                     // they all meet in the core
		float flow = 0.78 + 0.22 * sin(r * 25.0 - t * (2.0 + fk * 0.3) + fk * 1.7);   // plasma pulsing along the line
		float bright = line * flow * (1.0 - 0.45 * fk / 7.0);
		col += mix(color.rgb, vec3(0.85, 0.9, 1.0), line * 0.5) * bright;
		a = max(a, bright);
	}
	// jets along the axis, both ways, flickering and fading towards the edge
	float along = abs(p.y);
	float jw = 0.004 + along * 0.006;
	float jet = exp(-pow(p.x / jw, 2.0)) * smoothstep(core, core * 3.0, along) * (1.0 - smoothstep(0.7, 1.0, along));
	jet *= 0.75 + 0.25 * sin(along * 90.0 - t * 30.0);
	col += color2.rgb * jet * 1.4;
	a = max(a, jet);
	// the core and its glow
	float glow = exp(-d / (core * 3.0)) * 1.8;                      // blinding core
	float halo = exp(-d / (core * 9.0)) * 0.35;                     // a bluish halo round it
	col += vec3(0.95, 0.97, 1.0) * glow * 2.0 + color.rgb * halo;
	a = max(a, max(glow, halo * 0.8));
	if (d < core) {
		col = vec3(1.0);
		a = 1.0;
	}
	a = floor(clamp(a, 0.0, 1.0) * 7.0) / 7.0;
	COLOR = vec4(min(col, vec3(1.0)), a);
}
