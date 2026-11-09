// Pixel-art planet (package 38): lit surface with a soft twilight edge, seas, polar caps, a cloud layer of its own,
// glowing lava flows, banded giants with vortices and big storms, craters, city lights on the night side, and
// rings in many shapes. Moons use it too (craters, a lumpy outline, glowing volcanoes – package 36).
shader_type canvas_item;
#include "res://shaders/noise.gdshaderinc"

uniform vec4 col_a : source_color = vec4(0.15, 0.3, 0.6, 1.0);   // low (sea)
uniform vec4 col_b : source_color = vec4(0.35, 0.6, 0.3, 1.0);   // mid (land)
uniform vec4 col_c : source_color = vec4(0.9, 0.9, 0.85, 1.0);   // high (mountains)
uniform vec4 atmo : source_color = vec4(0.5, 0.7, 1.0, 0.7);
uniform float pixels = 96.0;
uniform vec2 light_dir = vec2(-0.7, -0.5);  // direction towards the light source
uniform float seed = 1.0;
uniform float gas = 0.0;                    // 1 = banded giant
uniform float spin = 0.01;
uniform float radius = 0.86;                // planet radius relative to quad half-width
uniform float has_ring = 0.0;
// package 36: moons
uniform float craters = 0.0;
uniform float lumpy = 0.0;
uniform float glow = 0.0;
// package 38
uniform float sea = 0.0;                    // share of the surface under water (col_a)
uniform float clouds = 0.0;
uniform vec4 cloud_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float caps = 0.0;                   // polar caps
uniform float lava = 0.0;                   // glowing lava flows
uniform float storms = 0.0;                 // vortices and a big storm on a giant
uniform float faint = 0.0;                  // 1 = faint bands (ice giant)
uniform float city = 0.0;                   // lights of cities on the night side
uniform float city_style = 0.0;             // package 39: 1 = a capital world (structured: coasts, metropolises, highways)
uniform float metal = 0.0;                  // package 42: a metal world – bright ore veins in a dark iron crust, glinting
uniform float terraform = 0.0;              // 39c: 1 = half terraformed – green with seas on one side, desert on the other
uniform vec4 dry_a : source_color = vec4(0.62, 0.38, 0.22, 1.0);
uniform vec4 dry_b : source_color = vec4(0.85, 0.62, 0.36, 1.0);
uniform vec4 dry_c : source_color = vec4(0.95, 0.85, 0.6, 1.0);
uniform float ring_in = 1.3;                // ring inner / outer edge (planet radii), tilt (flattening)
uniform float ring_out = 1.85;
uniform float ring_tilt = 3.2;

void fragment() {
	vec2 uv = (floor(UV * pixels) + 0.5) / pixels;
	vec2 c = (uv - 0.5) * 2.0;
	float d = length(c);
	vec3 L = normalize(vec3(light_dir, 0.55));
	vec4 outc = vec4(0.0);
	float rad = radius;
	if (lumpy > 0.5) {
		float ang = atan(c.y, c.x);
		rad *= 1.0 - 0.2 * vnoise(vec2(cos(ang), sin(ang)) * 1.6 + seed) - 0.06 * vnoise(vec2(cos(ang), sin(ang)) * 5.0 + seed * 2.0);
	}
	if (d < rad) {
		vec2 q = c / rad;
		float z = sqrt(max(0.0, 1.0 - dot(q, q)));
		vec3 n = vec3(q, z);
		vec2 st = q / (z + 1.0);
		vec2 sts = st + vec2(TIME * spin, 0.0);
		float h;
		vec3 base;
		float emit = 0.0;                         // light of its own (lava, volcanoes) – shines on the night side too
		vec3 emit_col = vec3(1.0, 0.45, 0.1);
		if (gas > 0.5) {
			// bands: latitude, warped by turbulence that is strongest at the band edges
			float lat = st.y * (faint > 0.5 ? 4.0 : 7.5);
			float turb = fbm(sts * vec2(3.0, 9.0) + seed) - 0.5;
			float band = fbm(vec2(lat + turb * (0.6 + 0.8 * storms), seed * 3.1 + sts.x * 0.4));
			h = band;
			base = mix(col_a.rgb, col_b.rgb, smoothstep(0.38, 0.55, h));
			base = mix(base, col_c.rgb, smoothstep(0.58, 0.72, h) * (faint > 0.5 ? 0.5 : 1.0));
			// small vortices along the band edges
			float vort = fbm(sts * 14.0 + seed * 1.7);
			base = mix(base, col_c.rgb * 1.05, step(0.74, vort) * storms * 0.6);
			// the big storm: an oval drifting with the bands
			if (storms > 0.0) {
				vec2 sp = vec2(fract(hash21(vec2(seed, 1.0)) + TIME * spin * 0.8) * 2.4 - 1.2, (hash21(vec2(seed, 2.0)) - 0.5) * 0.7);
				vec2 dv = (st - sp) * vec2(1.0, 2.1);
				float sd = length(dv);
				float rr = 0.13 + 0.08 * hash21(vec2(seed, 3.0));
				if (sd < rr) {
					float swirl = fbm(vec2(atan(dv.y, dv.x) * 2.0 + sd * 30.0 - TIME * 0.6, seed));
					vec3 scol = faint > 0.5 ? col_a.rgb * 0.45 : mix(vec3(0.78, 0.35, 0.22), col_c.rgb, 0.25);
					base = mix(base, scol * (0.8 + 0.4 * swirl), smoothstep(rr, rr * 0.6, sd) * storms);
				}
			}
		} else {
			h = fbm(st * 3.2 + vec2(seed * 7.3, seed));
			float hd = h + 0.18 * (fbm(st * 9.0 + seed * 2.3) - 0.5);       // finer detail
			float sea_lv = mix(0.0, 0.62, sea);
			if (sea > 0.0 && hd < sea_lv) {
				// sea: deeper is darker, shallow water near the coast lighter
				base = mix(col_a.rgb * 0.7, col_a.rgb * 1.25, smoothstep(sea_lv - 0.18, sea_lv, hd));
			} else {
				if (sea > 0.0) {
					// land on a world with seas: lowlands (b) up to highlands and mountains (c)
					float land = (hd - sea_lv) / max(0.62 - sea_lv + 0.25, 0.05);
					base = mix(col_b.rgb * (0.85 + 0.3 * fbm(st * 12.0 + seed)), col_c.rgb, smoothstep(0.35, 0.85, land));
				} else {
					base = mix(col_a.rgb, col_b.rgb, smoothstep(0.32, 0.5, hd));
					base = mix(base, col_c.rgb, smoothstep(0.55, 0.72, hd));
				}
			}
			// 39c: terraforming – beyond a ragged front the world is still desert (no seas, no green)
			if (terraform > 0.5) {
				float front = st.x + 0.22 * (fbm(st * 3.0 + seed * 1.7) - 0.5) + 0.06 * (fbm(st * 11.0 + seed) - 0.5);
				float dry = smoothstep(-0.02, 0.06, front);
				vec3 desert = mix(dry_a.rgb, dry_b.rgb, smoothstep(0.32, 0.5, hd));
				desert = mix(desert, dry_c.rgb, smoothstep(0.58, 0.74, hd));
				// along the front: first green patches in the sand
				float patches = step(0.55, fbm(st * 14.0 + seed * 3.0)) * (1.0 - smoothstep(0.06, 0.2, front));
				base = mix(base, desert, dry * (1.0 - patches * 0.8));
			}
			// polar caps with ragged edges
			if (caps > 0.0) {
				float lat2 = abs(q.y) + 0.12 * (fbm(st * 6.0 + seed) - 0.5);
				base = mix(base, vec3(0.94, 0.97, 1.0), step(1.0 - caps * 0.32, lat2));
			}
			// lava: glowing flows through a dark crust, slowly moving
			if (lava > 0.0) {
				float f = fbm(st * 4.5 + vec2(seed, TIME * 0.015));
				float vein = 1.0 - smoothstep(0.0, 0.06, abs(f - 0.5));
				float pool = smoothstep(0.66, 0.72, fbm(st * 2.5 + seed * 1.9));
				emit = max(vein, pool) * lava;
				emit_col = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.85, 0.35), vein * (0.5 + 0.5 * sin(TIME * 1.3 + f * 20.0)));
			}
		}
		// package 42: metal world – veins of copper and silver ore through the crust, plates of bare metal
		float glint = 0.0;
		if (metal > 0.0 && gas < 0.5) {
			float fv = fbm(st * 5.5 + vec2(seed * 2.1, seed * 0.7));
			float vein = 1.0 - smoothstep(0.0, 0.035, abs(fv - 0.5));
			float fv2 = fbm(st * 11.0 + vec2(seed, seed * 3.3));
			float vein2 = 1.0 - smoothstep(0.0, 0.025, abs(fv2 - 0.5));
			vec3 copper = vec3(0.86, 0.55, 0.3);
			vec3 silver = vec3(0.86, 0.88, 0.92);
			base = mix(base, copper, vein * 0.85 * metal);
			base = mix(base, silver, vein2 * 0.6 * metal);
			float plate = smoothstep(0.62, 0.66, fbm(st * 3.0 + seed * 4.4));
			base = mix(base, silver * 0.8, plate * 0.5 * metal);
			glint = max(max(vein, vein2 * 0.8), plate) * metal;
		}
		// craters: darker floor, a rim lit on the side facing the light
		float shade = 0.0;
		if (craters > 0.0) {
			for (int i = 0; i < 16; i++) {
				float fi = float(i);
				vec2 cp = vec2(hash21(vec2(fi, seed)), hash21(vec2(seed, fi + 3.7))) * 1.7 - 0.85;
				float cr = 0.05 + 0.17 * pow(hash21(vec2(fi * 1.3, seed + 9.1)), 2.0);
				vec2 dv = q - cp;
				float cd = length(dv) / cr;
				if (cd < 1.0) {
					float rim = smoothstep(0.7, 1.0, cd);
					float lit = dot(normalize(dv + 0.0001), normalize(light_dir));
					shade += craters * (mix(-0.3, 0.35 * lit, rim));
				}
			}
		}
		base = clamp(base * (1.0 + shade), 0.0, 1.0);
		// clouds: a layer of their own, drifting faster than the ground
		float cl = 0.0;
		if (clouds > 0.0) {
			vec2 cs = st * 3.6 + vec2(TIME * spin * 1.7 + seed * 2.0, seed);
			cl = smoothstep(0.62 - clouds * 0.18, 0.72 - clouds * 0.12, fbm(cs + 0.4 * fbm(cs * 2.0)));
			base = mix(base, cloud_col.rgb, cl * 0.92);
		}
		// light: four steps, a soft twilight edge tinted by the air
		float diff = dot(n, L);
		float lv = floor(clamp(diff, 0.0, 1.0) * 6.0 + 0.5) / 6.0;
		vec3 col = base * (0.1 + 0.95 * lv);
		float dusk = smoothstep(-0.08, 0.06, diff) * (1.0 - smoothstep(0.06, 0.22, diff));
		col = mix(col, atmo.rgb * 0.8, dusk * atmo.a * 0.25);
		col = mix(col, atmo.rgb, pow(1.0 - z, 3.0) * atmo.a * max(lv, 0.15));
		// package 42: metal glints where the light strikes the ore (twinkling pixels on the day side)
		if (glint > 0.0) {
			vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
			float spec = pow(max(dot(n, H), 0.0), 6.0);
			float tw = step(0.82, hash21(floor(uv * pixels) + floor(TIME * 1.5)));
			col += vec3(1.0, 0.95, 0.85) * glint * spec * (0.35 + 0.65 * tw) * step(0.05, diff);
		}
		// city lights on the night side: clusters along the coasts and in the lowlands, flickering a little
		if (city > 0.0 && gas < 0.5 && city_style > 0.5) {
			// package 39: a capital world – the lights follow the land: bright metropolises, a glittering band along
			// every coast, and highways strung between them; the open land and the sea stay dark
			float night = 1.0 - smoothstep(-0.05, 0.12, diff);
			float sea_lv2 = mix(0.0, 0.62, sea);
			float hd2 = h + 0.18 * (fbm(st * 9.0 + seed * 2.3) - 0.5);
			float on_land = step(sea_lv2, hd2);
			float coast = on_land * (1.0 - smoothstep(0.0, 0.045, hd2 - sea_lv2));
			float mfield = fbm(st * 2.6 + seed * 5.3);
			float metro = on_land * smoothstep(0.53, 0.6, mfield);
			float core = on_land * smoothstep(0.63, 0.69, mfield);
			float road = on_land * (1.0 - smoothstep(0.0, 0.016, abs(fbm(st * 1.8 + seed * 9.1) - 0.5)));
			road = max(road, on_land * (1.0 - smoothstep(0.0, 0.008, abs(fbm(st * 3.1 + seed * 2.7) - 0.5))) * 0.8);
			vec2 cell2 = floor(sts * pixels * 0.5);
			float rnd = hash21(cell2 + seed);
			float dens = max(max(coast * 0.8, metro * 0.9), road * 0.65);
			float lit = step(1.0 - dens, rnd) + core;
			float tw2 = 0.85 + 0.15 * sin(TIME * 2.0 + rnd * 30.0);
			float lights2 = clamp(lit, 0.0, 1.0) * night * (1.0 - cl * 0.6) * tw2;
			vec3 lc = mix(vec3(1.0, 0.78, 0.4), vec3(1.0, 0.95, 0.82), core);
			col = mix(col, lc, lights2);
			col += vec3(1.0, 0.7, 0.35) * metro * night * 0.12;              // the glow over the big cities
		} else if (city > 0.0 && gas < 0.5) {
			float night = 1.0 - smoothstep(-0.05, 0.12, diff);
			float landm = (sea > 0.0) ? step(mix(0.0, 0.62, sea), h + 0.18 * (fbm(st * 9.0 + seed * 2.3) - 0.5)) : 1.0;
			float region = smoothstep(0.3, 0.55, fbm(st * 5.0 + seed * 4.1));           // where people live
			vec2 cell = floor(sts * pixels * 0.45);
			float dot_l = step(1.0 - city * 0.8 * region, hash21(cell + seed));
			float tw = 0.8 + 0.2 * sin(TIME * 2.0 + hash21(cell) * 30.0);
			float lights = dot_l * landm * night * (1.0 - cl * 0.7) * tw;
			col = mix(col, vec3(1.0, 0.82, 0.45), lights);
		}
		// glowing lava / volcanoes (not lit – they glow on their own)
		if (glow > 0.5) {
			float v = fbm(st * 7.0 + vec2(seed * 3.3, seed));
			col = mix(col, vec3(1.0, 0.42, 0.08), step(0.66, v) * 0.9);
			col = mix(col, vec3(1.0, 0.85, 0.4), step(0.72, v));
		}
		col = mix(col, emit_col, emit);
		outc = vec4(col, 1.0);
	} else if (d < rad * 1.1 && atmo.a > 0.01) {
		vec2 q = c / d;
		float lit = clamp(dot(vec3(q, 0.0), L) + 0.4, 0.0, 1.0);
		float a = (1.0 - (d - rad) / (rad * 0.1)) * atmo.a * 0.7 * lit;
		a = floor(a * 4.0) / 4.0;
		outc = vec4(atmo.rgb, a);
	}
	// rings: bands with gaps (front half covers the planet, back half lies behind it); the planet's shadow falls
	// on the far side
	if (has_ring > 0.5) {
		float rd = length(vec2(c.x, c.y * ring_tilt)) / radius;
		if (rd > ring_in && rd < ring_out && (d >= radius || c.y > 0.0)) {
			float k = (rd - ring_in) / (ring_out - ring_in);
			float band = fbm(vec2(rd * 18.0, seed));
			float gap = step(0.18, abs(fract(k * (2.0 + floor(hash21(vec2(seed, 7.0)) * 3.0)) + 0.5 * hash21(vec2(seed, 8.0))) - 0.5));
			vec3 rcol = mix(col_c.rgb, col_b.rgb, step(0.5, band)) * (0.6 + 0.4 * step(0.0, c.y));
			float shadow = (c.y < 0.0 && abs(c.x) < radius * 0.9 && dot(normalize(vec2(c.x, 0.0) + 0.0001), light_dir) < 0.0) ? 0.55 : 1.0;
			float ra = (0.55 + 0.4 * band) * mix(0.25, 1.0, gap);
			outc = vec4(mix(outc.rgb, rcol * shadow, ra), max(outc.a, ra));
		}
	}
	COLOR = outc;
}
