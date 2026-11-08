// Pixel-art star (package 37): a boiling surface, limb darkening, sunspots, prominences that rise and fall on the
// limb, flares, the eruption of a coronal mass ejection and a shimmering corona.
// mode: 0 main sequence / white dwarf, 1 brown dwarf (banded, dim), 2 red supergiant (huge boiling cells,
// irregular limb).
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 0.97, 0.8, 1.0);   // the hot colour
uniform float pixels = 120.0;
uniform float radius = 0.45;
uniform float seed = 1.0;
uniform int mode = 0;
uniform float flares = 1.0;          // 0 = no prominences / flares
uniform float spots = 0.5;           // sunspots
uniform float cme_t = -1.0;          // < 0: none, 0 → 1: a coronal mass ejection erupting
uniform float cme_ang = 0.0;

float prominence(vec2 c, float rad, float i, float t) {
	float h0 = hash21(vec2(i, seed));
	float h1 = hash21(vec2(seed, i * 1.7));
	float period = 7.0 + 9.0 * h1;
	float ph = fract(t / period + h0);
	float life = smoothstep(0.0, 0.25, ph) * (1.0 - smoothstep(0.55, 0.75, ph));
	if (life <= 0.0) {
		return 0.0;
	}
	float a = h0 * 6.2832 + t * 0.004;
	vec2 n = vec2(cos(a), sin(a));
	vec2 tg = vec2(-n.y, n.x);
	vec2 p = c - n * rad * 0.97;
	float u = dot(p, tg);
	float v = dot(p, n);
	float w = rad * (0.06 + 0.12 * h1);
	float h = rad * (0.08 + 0.32 * h0) * (0.35 + 0.65 * smoothstep(0.0, 0.5, ph));   // rises, then hangs and fades
	if (v < -0.01) {
		return 0.0;
	}
	float e = sqrt((u / w) * (u / w) + (v / h) * (v / h));
	float band = 1.0 - smoothstep(0.1, 0.45, abs(e - 1.0));                     // a thick arch of plasma
	band = max(band, (1.0 - smoothstep(0.0, 1.0, e)) * 0.35);                   // glowing gas inside the arch
	band *= 0.6 + 0.4 * vnoise(vec2(u * 60.0 + t * 2.0, i));       // plasma filaments
	return band * life;
}

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	float d = length(c);
	float ang = atan(c.y, c.x);
	float t = TIME;
	float rad = radius;
	if (mode == 2) {
		// a red supergiant has no sharp edge: its limb heaves
		rad *= 1.0 + 0.045 * (vnoise(vec2(ang * 2.5 + seed, t * 0.25)) - 0.5) + 0.02 * (vnoise(vec2(ang * 7.0, t * 0.6 + seed)) - 0.5);
	}
	vec4 outc = vec4(0.0);
	if (d < rad) {
		vec2 q = c / rad;
		float z = sqrt(max(0.0, 1.0 - dot(q, q)));
		float n;
		if (mode == 1) {
			// brown dwarf: slow storm bands like a gas giant
			n = fbm(vec2(q.y * 5.0 + fbm(q * 3.0 + vec2(t * 0.02, seed)) * 0.9, seed * 2.0 + q.x * 0.5 + t * 0.03));
		} else if (mode == 2) {
			// red supergiant: huge convection cells rising and sinking
			vec2 w = vec2(fbm(q * 1.6 + vec2(seed, t * 0.05)), fbm(q * 1.6 + vec2(t * 0.04, seed + 3.0)));
			n = fbm(q * 2.2 + w * 1.8 + vec2(0.0, t * 0.03));
			n = mix(n, 0.5 + 0.5 * sin(n * 9.0 + t * 0.35), 0.25);
		} else {
			// granulation: small cells, slowly churning
			vec2 w = vec2(fbm(q * 4.0 + vec2(seed, t * 0.08)), fbm(q * 4.0 + vec2(t * 0.07, seed + 5.0)));
			n = fbm(q * 7.0 + w * 1.2);
		}
		float limb = 0.5 + 0.5 * pow(z, 0.6);
		float lv = floor(clamp(n * 1.1 + 0.15, 0.0, 1.0) * 5.0) / 5.0;
		vec3 dark = color.rgb * color.rgb * 0.75;          // deeper and more saturated, not muddy
		vec3 col = mix(dark, color.rgb, smoothstep(0.2, 0.6, lv));
		col = mix(col, color2.rgb, smoothstep(0.6, 1.0, lv));
		if (spots > 0.0 && mode == 0) {
			float sp = fbm(q * 3.5 + vec2(seed * 3.1, t * 0.004));
			col = mix(col, color.rgb * 0.18, step(1.0 - 0.28 * spots, sp) * 0.85);
		}
		// flares on the disc: bright patches that flash up now and then
		if (flares > 0.0) {
			float fl = vnoise(q * 9.0 + seed);
			float cell = hash21(vec2(floor(vnoise(q * 2.5 + seed * 1.3) * 24.0), seed));  // irregular regions, each flashing on its own
			float pulse = pow(max(0.0, sin(t * 0.45 + cell * 40.0)), 40.0);
			col = mix(col, mix(color2.rgb, vec3(1.0), 0.45), step(0.86, fl) * pulse * 0.85);
		}
		col *= limb;
		col = mix(col, color2.rgb, 0.12);                                        // a touch of the hot colour everywhere
		outc = vec4(floor(col * 12.0) / 12.0, 1.0);
	} else {
		// corona (pixel steps) – the wide soft halo is a separate sprite
		float flick = fbm(vec2(ang * 3.0, t * 0.4 + seed)) * 0.35;
		float g = 1.0 - (d - rad) / (1.0 - rad);
		g = clamp(g + flick - 0.2, 0.0, 1.0);
		g = pow(g, mode == 1 ? 4.0 : 3.0);
		g = floor(g * 6.0) / 6.0;
		outc = vec4(color.rgb, g * (mode == 1 ? 0.3 : 0.38));
		// prominences: loops of plasma rising from the limb and falling back
		if (flares > 0.0) {
			float pr = 0.0;
			for (int i = 0; i < 7; i++) {
				pr = max(pr, prominence(c, rad, float(i), t));
			}
			pr = floor(pr * 5.0) / 5.0;
			vec3 pc = mix(color.rgb, color2.rgb, 0.35 + 0.4 * pr);
			outc = vec4(mix(outc.rgb, pc, min(pr * 1.3, 1.0)), max(outc.a, pr * 0.95));
		}
	}
	// coronal mass ejection: a shell of plasma bursting from the limb and racing outwards
	if (cme_t >= 0.0) {
		vec2 n = vec2(cos(cme_ang), sin(cme_ang));
		vec2 base = n * rad;
		float s = rad * 0.15 + cme_t * (0.92 - rad);         // stays inside the picture (the shockwave carries on outside)
		vec2 p = c - base;
		float dd = length(p);
		float facing = dot(normalize(p + 0.0001), n);
		if (facing > 0.15 && d > rad * 0.98) {
			float shell = 1.0 - smoothstep(0.0, 0.05 + 0.08 * cme_t, abs(dd - s));
			float inner = (1.0 - smoothstep(0.0, s, dd)) * 0.35;
			float edge = 1.0 - smoothstep(0.72, 0.97, max(abs(c.x), abs(c.y)));   // fades before the picture's square edge
			float k = (shell + inner) * smoothstep(0.15, 0.6, facing) * (1.0 - cme_t) * edge;
			k *= 0.6 + 0.4 * fbm(vec2(atan(p.y, p.x) * 6.0, dd * 10.0 - t));
			k = floor(clamp(k, 0.0, 1.0) * 5.0) / 5.0;
			vec3 cc = mix(color2.rgb, vec3(1.0), 0.3);
			outc = vec4(mix(outc.rgb, cc, k), max(outc.a, k));
		}
	}
	COLOR = outc;
}
