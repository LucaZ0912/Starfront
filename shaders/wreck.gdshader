shader_type canvas_item;
// 0.7.53.6 (Luz, package 53b): a ship of the game come down – its own picture at ground scale (15 art px a metre):
// sampled smoothly so its outline stays round, hull plates laid over it (seams, rivets, a shade per plate), a dark
// rim, burnt (greyed, darker, soot). `cut` leaves out a share of its length – the stern torn away, or only the stern.

uniform vec2 px_size = vec2(64.0, 24.0);   // the picture's size in its own pixels
uniform float art_per_px = 20.0;          // art px per picture pixel
uniform float burnt = 0.45;
uniform vec2 cut = vec2(-1.0, -1.0);      // [from, to) of the length (0 stern .. 1 nose) left out

varying vec4 v_mod;

void vertex() {
	v_mod = COLOR;
}

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float alpha_at(sampler2D tex, vec2 uv) {
	return texture(tex, uv).a;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5 || (UV.x >= cut.x && UV.x < cut.y)) {
		discard;
	}
	vec3 col = c.rgb;
	vec2 lq = UV * px_size * art_per_px;                // ship-local art px
	float row = floor(lq.y / 12.0);
	float px = lq.x + (mod(row, 2.0) * 9.0);
	float plate = floor(px / 18.0);
	col *= 1.0 - 0.08 * h(vec2(plate, row)) + 0.05 * h(vec2(plate + 7.0, row));
	float sx = mod(px, 18.0);
	float sy = mod(lq.y, 12.0);
	if (sx < 1.0 || sy < 1.0) {
		col *= 0.7;
	} else if (sx < 2.0 || sy < 2.0) {
		col *= 1.08;
	}
	if ((floor(sx) == 3.0 || floor(sx) == 15.0) && floor(sy) == 3.0) {
		col *= 1.25;
	}
	// the rim
	vec2 d = 0.6 / px_size;
	if (alpha_at(TEXTURE, UV + vec2(0.0, d.y)) < 0.5 || alpha_at(TEXTURE, UV - vec2(d.x, 0.0)) < 0.5 || c.a < 0.65) {
		col *= 0.55;
	}
	// a torn edge where it broke apart
	if (cut.x >= 0.0 && abs(UV.x - cut.x) < 0.012 && cut.x > 0.0) {
		col *= 0.35 + 0.4 * h(floor(lq / 3.0));
	}
	if (cut.y < 1.0 && abs(UV.x - cut.y) < 0.012) {
		col *= 0.35 + 0.4 * h(floor(lq / 3.0));
	}
	float g = dot(col, vec3(0.333));
	col = mix(col, vec3(g), burnt * 0.55) * (1.0 - burnt * 0.3);
	if (h(floor(lq / 6.0)) < burnt * 0.22) {
		col *= 0.55 + 0.2 * h(floor(lq));
	}
	COLOR = vec4(col, 1.0) * v_mod;
}
