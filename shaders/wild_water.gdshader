shader_type canvas_item;
// 53f-2 (Luz): the water of the wild, under the map (the map leaves it clear) – depth from the shore (tiles, a texture
// of one texel a tile), banded from shallow to deep; wave crests rolling in towards the shore, the surf running up the
// beach and back, whitecaps far out; a still creek just shimmers. In art pixels (snapped), like everything on the ground.

uniform sampler2D depth_tex : filter_linear, repeat_disable;
uniform vec2 art_size = vec2(1600.0, 1056.0);
uniform vec4 shallow : source_color = vec4(0.35, 0.78, 0.78, 1.0);
uniform vec4 mid : source_color = vec4(0.1, 0.45, 0.62, 1.0);
uniform vec4 deep : source_color = vec4(0.04, 0.2, 0.38, 1.0);
uniform vec4 foam : source_color = vec4(0.93, 0.97, 1.0, 1.0);
uniform float waves = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = floor(UV * art_size) + 0.5;
	float t = TIME;
	float d = texture(depth_tex, px / art_size).r * 16.0;          // art px from the shore
	d += (vnoise(px / 7.0) - 0.5) * 5.0;
	vec3 c = mix(shallow.rgb, mid.rgb, clamp(d / 22.0, 0.0, 1.0));
	c = mix(c, deep.rgb, clamp((d - 22.0) / 90.0, 0.0, 1.0));
	c *= 0.94 + 0.06 * vnoise(px / vec2(9.0, 4.0) + vec2(t * 0.3, 0.0));
	if (waves > 0.5) {
		// wave crests rolling in, broken up
		float crest = mod(d * 0.16 - t * 1.6 + sin(px.y * 0.08 + px.x * 0.02) * 0.6, 2.094);
		if (crest < 0.16 && d > 4.0 && d < 42.0 && vnoise(px / vec2(5.0, 3.0)) < 0.75) {
			c += vec3(0.3 * (1.0 - d / 42.0) + 0.06);
		}
		// whitecaps out at sea
		vec2 cap = floor(px / vec2(5.0, 1.0)) + vec2(floor(t * 0.7), 0.0);
		if (d > 60.0 && mod(px.y, 3.0) < 1.0 && hash(cap) < 0.006) {
			c = mix(c, foam.rgb, 0.7);
		}
	} else {
		// a still water just glints
		if (mod(px.y, 3.0) < 1.0 && hash(floor(px / vec2(4.0, 1.0)) + floor(t * 1.2)) < 0.012 && d > 6.0) {
			c = mix(c, foam.rgb, 0.4);
		}
	}
	// the surf at the edge: up the beach and back
	float surf = 3.0 + (sin(px.y * 0.3 + t * 2.0) * 1.5 + sin(t * 0.8 + px.x * 0.01) * 2.0) * (waves > 0.2 ? 1.0 : 0.3);
	if (d < surf) {
		c = mix(foam.rgb, c, hash(px + floor(t * 7.0)) * 0.6);
	}
	COLOR = vec4(c, 1.0);
}
