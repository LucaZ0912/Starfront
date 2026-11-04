// Colossal asteroid (phase 0.5 package 5): procedural pixel-art rock, lit by the star.
// The silhouette is the same polygon the game uses for collisions and the radar shadow
// (ColossusShape), roughened a little with noise. Height and lighting come from the distance to
// the outline: round bodies get a dome, the angular shard gets flat facets (one plane per edge).
// Detail and pixel size adapt to the zoom (uniform `pixels` is updated every frame), so the
// rock keeps the same chunky pixel-art look as the ships – from far away and up close.
//   kind 0 = metallic: dark iron, bright metal veins, specular glints
//   kind 1 = stony:    ochre/rust strata, dense craters with sunlit rims
//   kind 2 = icy:      bright ice, deep blue glowing crevasses, frost sparkle, soft halo
//   shape 0 = potato, 1 = contact binary, 2 = angular shard
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 col_dark : source_color = vec4(0.12, 0.11, 0.1, 1.0);
uniform vec4 col_mid : source_color = vec4(0.36, 0.32, 0.28, 1.0);
uniform vec4 col_light : source_color = vec4(0.62, 0.56, 0.5, 1.0);
uniform vec4 col_accent : source_color = vec4(0.8, 0.5, 0.3, 1.0);
uniform int kind = 1;
uniform int shape = 0;
uniform float seed = 1.0;
uniform vec2 light_dir = vec2(-0.7, -0.6);   // towards the star
uniform float pixels = 256.0;                // art pixels across the quad
uniform vec2 poly[64];                       // outline in quad space (-1..1)
uniform int poly_n = 0;
uniform float depth_max = 0.4;              // deepest point inside the outline (quad space)

// Signed distance to the outline (negative inside); g = outward direction of the nearest edge,
// e = index of that edge (for per-facet variation).
float sd_poly(vec2 p, out vec2 g, out float e) {
	vec2 d0 = p - poly[0];
	float best = dot(d0, d0);
	vec2 bv = d0;
	float s = 1.0;
	e = 0.0;
	for (int i = 0; i < 64; i++) {
		if (i >= poly_n) break;
		int j = i == 0 ? poly_n - 1 : i - 1;
		vec2 ed = poly[j] - poly[i];
		vec2 w = p - poly[i];
		vec2 b = w - ed * clamp(dot(w, ed) / dot(ed, ed), 0.0, 1.0);
		float bd = dot(b, b);
		if (bd < best) { best = bd; bv = b; e = float(i); }
		bool c1 = p.y >= poly[i].y;
		bool c2 = p.y < poly[j].y;
		bool c3 = ed.x * w.y > ed.y * w.x;
		if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) s = -s;
	}
	float dist = sqrt(best);
	g = bv / max(dist, 1e-5);
	return s * dist;
}

// height of the rounded body at p (0 outside)
float dome(vec2 p, float hr) {
	vec2 g;
	float e;
	float u = clamp(-sd_poly(p, g, e) / hr, 0.0, 1.0);
	return hr * sqrt(1.0 - (1.0 - u) * (1.0 - u));
}

// crater field: returns (depth 0..1 inside a crater, slope xy) or a rim marker (z = -9)
vec3 craters(vec2 p, float scale, float density) {
	vec2 ip = floor(p * scale);
	vec2 fp = fract(p * scale);
	vec3 res = vec3(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			float h = hash21(ip + g + seed * 5.7);
			if (h > density) continue;
			vec2 o = vec2(hash21(ip + g + 19.1), hash21(ip + g + 41.3)) * 0.6 + 0.2;
			float r = 0.18 + 0.3 * hash21(ip + g + 7.7);
			vec2 dv = fp - (g + o);
			float d = length(dv) / r;
			if (d < 1.0) {
				res = vec3(1.0 - d, 0.0, 0.0);
				res.yz = dv / r;
			} else if (d < 1.25 && res.x == 0.0) {
				res.y = 1.0 - (d - 1.0) / 0.25;
				res.z = -9.0;
			}
		}
	}
	return res;
}

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	vec4 outc = vec4(0.0);
	if (poly_n >= 3) {
		vec2 g;
		float edge;
		float d = sd_poly(c, g, edge);
		// rough the outline: medium bumps + small jaggies (less on the clean-cut shard)
		float rough = shape == 2 ? 0.45 : 1.0;
		d += ((fbm(c * 5.0 + seed * 2.0) - 0.5) * 0.05 + (vnoise(c * 24.0 + seed) - 0.5) * 0.016) * rough;
		if (d < 0.0) {
			float t = -d;                                   // depth inside the outline
			// large-scale shape normal: dome for round bodies, flat facets for the shard
			vec3 ns;
			if (shape == 2) {
				float slope = 1.1 + 1.4 * hash21(vec2(edge, seed));      // each facet its own tilt
				ns = normalize(vec3(g * slope * step(t, 0.55), 1.0));
				ns = normalize(ns + vec3(g * 0.25, 0.0));
			} else {
				// dome over the distance field, sampled wide so the medial ridge is rounded off
				float hr = depth_max * 1.05;
				float ew = max(depth_max * 0.35, 0.03);
				float hE = dome(c + vec2(ew, 0.0), hr);
				float hW = dome(c - vec2(ew, 0.0), hr);
				float hS = dome(c + vec2(0.0, ew), hr);
				float hN = dome(c - vec2(0.0, ew), hr);
				ns = normalize(vec3((hW - hE) / (2.0 * ew), (hN - hS) / (2.0 * ew), 0.9));
			}
			vec2 tp = c * 3.0 + seed;                      // terrain coordinates
			// bumpy terrain normal from fbm gradient
			float e = 0.01;
			float h0 = fbm(tp * 2.0);
			float hx = fbm((tp + vec2(e, 0.0)) * 2.0);
			float hy = fbm((tp + vec2(0.0, e)) * 2.0);
			vec3 n = normalize(ns + vec3(h0 - hx, h0 - hy, 0.0) * 5.0);
			// craters (big and small), stony has the most, the fresh shard the fewest
			float dens = kind == 1 ? 0.55 : (kind == 0 ? 0.35 : 0.2);
			if (shape == 2) dens *= 0.55;
			vec3 cb = craters(c + seed, 3.0, dens);
			vec3 cs = craters(c + seed * 1.7, 9.0, dens);
			vec3 L = normalize(vec3(light_dir, 0.55));
			float rim = 0.0;
			for (int k = 0; k < 2; k++) {
				vec3 cr = k == 0 ? cb : cs;
				if (cr.x > 0.0) {
					n = normalize(n + vec3(-cr.yz * 0.9, 0.0));
				} else if (cr.z < -8.0) {
					rim = max(rim, cr.y);
				}
			}
			float diff = clamp(dot(n, L), 0.0, 1.0);
			// large-scale self shadow (night side) + terminator
			float day = clamp(dot(ns, L) * 1.4 + 0.3, 0.0, 1.0);
			float light = mix(day, diff * day, 0.7) * 0.85 + 0.12;
			light += rim * 0.25 * day;
			// fine surface grain (visible up close, where the art has many pixels)
			float g1 = vnoise(tp * 14.0) - 0.5;
			float g2 = vnoise(tp * 41.0 + 7.0) - 0.5;
			light += (g1 * 0.22 + g2 * 0.12) * (0.4 + 0.6 * day);
			float gl_rate = 0.004 * min(1.0, pow(120.0 / pixels, 2.0));   // same glint count at every zoom
			float mask = vnoise(tp * 1.4 + seed * 0.3 + 2.0);   // veins/crevasses come and go
			// colour by class
			float tt = fbm(tp * 1.3 + 4.0);
			vec3 base = mix(col_mid.rgb, col_light.rgb, smoothstep(0.35, 0.7, tt));
			float glow = 0.0;
			if (kind == 0) {
				base = mix(col_dark.rgb, col_mid.rgb, 0.6 + 0.4 * tt);
				float vein = abs(fbm(tp * 2.6 + 9.0) - 0.5);
				if (vein < 0.011 && mask > 0.42) { base = mix(col_accent.rgb, vec3(1.0), 0.25); light = max(light, 0.55 * day + 0.2); }
				if (hash21(floor(uv * pixels) + seed) > 1.0 - gl_rate && diff > 0.6 && day > 0.4) { base = vec3(1.0); light = 1.2; }
			} else if (kind == 1) {
				float strata = fbm(vec2(tp.x * 0.6 + tp.y * 1.4, tp.y * 0.3) * 2.0);
				base = mix(col_mid.rgb, col_light.rgb, smoothstep(0.4, 0.62, strata));
				if (hash21(floor(uv * pixels) + seed * 2.0) > 1.0 - gl_rate * 1.5) base = col_accent.rgb;
			} else {
				base = mix(col_light.rgb, vec3(0.93, 0.97, 1.0), 0.55);
				float crev = abs(fbm(tp * 2.2 + 3.0) - 0.5);
				if (crev < 0.012 && mask > 0.38) {
					base = col_accent.rgb * 0.75;
					glow = 0.35;
					light = max(light, 0.3);
				}
				float tw = hash21(floor(uv * pixels) + floor(TIME * 3.0) + seed);
				if (tw > 1.0 - gl_rate && diff > 0.5 && day > 0.4) { base = vec3(1.0); light = 1.3; }
			}
			// shard: bright freshly broken facet edges facing the star
			if (shape == 2 && t < 0.02 && dot(g, normalize(light_dir)) > 0.2) light += 0.25;
			// pixel-art ramp: 6 light levels
			float lv = floor(clamp(light, 0.0, 1.2) * 6.0 + 0.5) / 6.0;
			vec3 col = mix(col_dark.rgb * 0.45 + vec3(0.025, 0.03, 0.045), base, clamp(lv, 0.0, 1.0)) * (lv > 1.0 ? 1.15 : 1.0);
			col += col_accent.rgb * glow * (1.0 - lv * 0.5);
			// dark contour line along the silhouette
			if (t < 2.0 / pixels * 2.0) col *= 0.55;
			outc = vec4(col, 1.0);
		} else if (kind == 2 && d < 0.05) {
			// icy halo on the sunlit side
			float a = (1.0 - d / 0.05) * 0.35;
			a *= clamp(dot(g, normalize(light_dir)) + 0.6, 0.0, 1.0);
			outc = vec4(col_light.rgb, floor(a * 4.0) / 4.0);
		}
	}
	COLOR = outc * COLOR;   // keep the node's modulate (fade while the ship is underneath)
}
