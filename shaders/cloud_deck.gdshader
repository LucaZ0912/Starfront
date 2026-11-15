shader_type canvas_item;
// 0.7.54.3 (Luz): a cloud deck you sink through on the way down to a cloud city – big billows in the giant's colours,
// lit from the upper left, their undersides in shade, ragged gaps through which the depth shows; scrolled as the ship
// sinks. In art pixels (3 screen px), like the rest. `alpha` fades the whole deck in and out.

uniform vec2 art_size = vec2(534.0, 300.0);
uniform vec2 offset = vec2(0.0);
uniform float scale = 1.0;
uniform float cover = 0.5;              // how much of the sky the deck covers (0 thin … 1 closed)
uniform float alpha = 1.0;
uniform vec4 lit : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform vec4 mid : source_color = vec4(0.9, 0.78, 0.6, 1.0);
uniform vec4 shade : source_color = vec4(0.6, 0.45, 0.32, 1.0);
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p + seed, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.5 + vnoise(p * 2.03 + 17.0) * 0.27 + vnoise(p * 4.1 + 41.0) * 0.15 + vnoise(p * 8.3 + 7.0) * 0.08;
}

void fragment() {
	vec2 px = floor(UV * art_size) + 0.5;
	vec2 q = (px + offset) / (scale * vec2(46.0, 30.0));
	float d = fbm(q);
	float d2 = fbm(q + vec2(0.05, 0.08));
	float edge = 1.0 - cover;
	if (d < edge) {
		discard;
	}
	float body = smoothstep(edge, edge + 0.12, d);
	float l = clamp((d - d2) * 14.0 + 0.5, 0.0, 1.0);               // lit from the upper left
	vec3 c = mix(shade.rgb, mid.rgb, l);
	c = mix(c, lit.rgb, smoothstep(0.62, 0.95, l) * body);
	c = mix(shade.rgb * 0.85, c, body);                              // the thin rims darker, seen against the depth
	c = floor(c * 24.0 + 0.5) / 24.0;
	COLOR = vec4(c, alpha * mix(0.55, 1.0, body));
}
