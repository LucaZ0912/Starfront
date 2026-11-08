// Pixel-art black hole (package 37): event horizon, photon ring, a turning accretion disc seen at a slant (one side
// brighter – it comes towards us), the far side of the disc bent up over the hole by its gravity and a thin arc
// beneath it.
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.5, 0.15, 1.0);    // outer disc
uniform vec4 color2 : source_color = vec4(1.0, 0.92, 0.7, 1.0);   // hot inner disc
uniform float pixels = 500.0;
uniform float horizon = 0.16;        // event horizon radius relative to the quad half-width
uniform float seed = 1.0;
uniform float tilt = 0.2;            // how flat the disc looks (0 = edge on)

// streaky plasma at polar position (angle a, distance r) of the disc
float disc_tex(float a, float r, float t) {
	float swirl = a * 5.0 - t * 1.6 / (r + 0.15);
	return fbm(vec2(swirl, r * 26.0 + seed)) * 0.7 + 0.3 * vnoise(vec2(a * 30.0 - t * 4.0 / (r + 0.2), r * 60.0));
}

vec4 disc_colour(float r, float a, float t, float r_in, float r_out) {
	if (r < r_in || r > r_out) {
		return vec4(0.0);
	}
	float k = (r - r_in) / (r_out - r_in);           // 0 inner edge → 1 outer edge
	float tex = disc_tex(a, r, t);
	float bright = (1.0 - k) * (0.55 + 0.75 * tex);
	bright *= 1.0 + 0.5 * cos(a);                     // the side coming towards us is brighter
	vec3 col = mix(color2.rgb, color.rgb, smoothstep(0.0, 0.7, k));
	col = mix(col * 0.5, col, tex);
	float al = clamp(bright * 1.6, 0.0, 1.0) * (1.0 - smoothstep(0.75, 1.0, k));
	return vec4(col * (0.6 + 0.6 * bright), al);
}

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	float d = length(c);
	float t = TIME;
	float h = horizon;
	float r_in = h * 1.6;
	float r_out = 0.98;
	vec4 outc = vec4(0.0);
	// the disc in its plane (seen at a slant: squashed vertically)
	vec2 e = vec2(c.x, c.y / tilt);
	float de = length(e);
	float ae = atan(e.y, e.x);
	vec4 disc = disc_colour(de, ae, t, r_in, r_out);
	bool near_half = c.y > 0.0;                      // the half of the disc in front of the hole
	// far half of the disc bent up over the hole (lensed image): a band round the top of the horizon
	vec4 lens_top = vec4(0.0);
	if (c.y < h * 0.15) {
		float rl = (d - h * 1.08) / (h * 1.25);       // 0 at the photon ring … 1 outwards
		if (rl > 0.0 && rl < 1.0) {
			float al = atan(c.y, c.x);
			lens_top = disc_colour(r_in + rl * (r_out * 0.55 - r_in), al * 1.0 + 3.1416, t, r_in, r_out);
			lens_top.a *= smoothstep(h * 0.15, -h * 0.25, c.y) * 0.95;
		}
	}
	// thin arc under the hole: the underside of the disc's inner edge
	vec4 lens_low = vec4(0.0);
	if (c.y > 0.0) {
		float rl2 = (d - h * 1.06) / (h * 0.55);
		if (rl2 > 0.0 && rl2 < 1.0) {
			lens_low = disc_colour(r_in + rl2 * h * 0.9, atan(c.y, c.x), t, r_in, r_out);
			lens_low.a *= 0.8 * smoothstep(0.0, h * 0.4, c.y);
		}
	}
	// layers, back to front: far disc half → lensed arcs → horizon → photon ring → near disc half
	if (!near_half) {
		outc = disc;
	}
	outc = mix(outc, vec4(lens_low.rgb, 1.0), lens_low.a);
	outc.a = max(outc.a, lens_low.a);
	outc = mix(outc, vec4(lens_top.rgb, 1.0), lens_top.a);
	outc.a = max(outc.a, lens_top.a);
	if (d < h) {
		outc = vec4(0.0, 0.0, 0.0, 1.0);
	}
	float ring = 1.0 - smoothstep(0.0, 0.012, abs(d - h * 1.04));
	outc = mix(outc, vec4(color2.rgb, 1.0), ring * 0.9);
	outc.a = max(outc.a, ring * 0.9);
	if (near_half) {
		outc = mix(outc, vec4(disc.rgb, 1.0), disc.a);
		outc.a = max(outc.a, disc.a);
	}
	outc.rgb = floor(outc.rgb * 14.0) / 14.0;
	outc.a = floor(outc.a * 8.0) / 8.0;
	COLOR = outc;
}
