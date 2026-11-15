shader_type canvas_item;
// Package 54 (Luz): the giant's sky through a window of the cloud city (the skyrail's car, the bar) – the sky in the
// giant's colours, thin streaks high up; below the horizon the sea of clouds in perspective, hazy towards the
// horizon, its bands and billows passing as the car runs (`scroll`). In art pixels.

uniform vec2 art_size = vec2(320.0, 32.0);
uniform float horizon = 0.55;
uniform float scroll = 0.0;
uniform vec4 sky_top : source_color = vec4(0.98, 0.9, 0.74, 1.0);
uniform vec4 sky_low : source_color = vec4(0.9, 0.7, 0.48, 1.0);
uniform vec4 band0 : source_color = vec4(0.93, 0.84, 0.66, 1.0);
uniform vec4 band1 : source_color = vec4(0.86, 0.66, 0.44, 1.0);
uniform vec4 band2 : source_color = vec4(0.76, 0.5, 0.32, 1.0);
uniform vec4 deep : source_color = vec4(0.42, 0.24, 0.16, 1.0);
uniform vec4 haze : source_color = vec4(0.95, 0.82, 0.62, 1.0);
uniform float light = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.5 + vnoise(p * 2.03 + 17.0) * 0.3 + vnoise(p * 4.1 + 41.0) * 0.2;
}

void fragment() {
	vec2 px = floor(UV * art_size) + 0.5;
	float y = px.y / art_size.y;
	float t = TIME;
	vec3 c;
	if (y < horizon) {
		float k = y / horizon;
		c = mix(sky_top.rgb, sky_low.rgb, k * k);
		float st = fbm(vec2((px.x + scroll * 0.05 + t * 2.0) / 60.0, px.y / 3.0));
		c = mix(c, min(sky_top.rgb * 1.08, vec3(1.0)), smoothstep(0.62, 0.75, st) * 0.5);
		c = mix(c, haze.rgb, smoothstep(0.6, 1.0, k) * 0.6);
	} else {
		float z = (y - horizon) / (1.0 - horizon);
		float depth = 1.0 / (z + 0.06);
		vec2 q = vec2((px.x - art_size.x * 0.5) / depth * 0.35 + scroll * 0.4 / depth + t * 2.0, 40.0 / (z + 0.06));
		float d = fbm(vec2(q.x / 18.0, q.y / 6.0));
		float f = mod(q.y / 9.0, 3.0);
		vec3 b = f < 1.0 ? mix(band0.rgb, band1.rgb, fract(f)) : (f < 2.0 ? mix(band1.rgb, band2.rgb, fract(f)) : mix(band2.rgb, band0.rgb, fract(f)));
		b = mix(deep.rgb, b, smoothstep(0.28, 0.5, d));
		c = mix(haze.rgb, b, smoothstep(0.0, 0.7, z));
	}
	c = mix(c * vec3(0.18, 0.22, 0.4), c, clamp(light, 0.0, 1.0));
	c = floor(c * 24.0 + 0.5) / 24.0;
	COLOR = vec4(c, 1.0);
}
