shader_type canvas_item;
// Package 54 (Luz, mockup_54v2): the sea of clouds of a gas giant under a cloud city – drawn under the map (the map
// leaves the void clear). Three layers far below, each moving slower than the deck as the view pans (parallax) and
// drifting in the wind: the deep (dark, a storm's lightning glowing in it), the billows in the giant's bands (lit from
// above, dark gaps going down into the deep, a storm eddy twisting them), thin wisps of haze nearer up. `scroll` is
// how far the skyrail's car has run. In art pixels (snapped) and a few colours, like everything on the ground.

uniform vec2 origin = vec2(0.0);          // art px of the rect's top-left in the world
uniform float px_per_art = 3.0;
uniform vec2 cam = vec2(0.0);             // art px: the top-left of the view
uniform float scroll = 0.0;
uniform vec4 band0 : source_color = vec4(0.93, 0.84, 0.66, 1.0);
uniform vec4 band1 : source_color = vec4(0.86, 0.66, 0.44, 1.0);
uniform vec4 band2 : source_color = vec4(0.95, 0.9, 0.78, 1.0);
uniform vec4 band3 : source_color = vec4(0.76, 0.5, 0.32, 1.0);
uniform vec4 band4 : source_color = vec4(0.9, 0.76, 0.56, 1.0);
uniform vec4 deep : source_color = vec4(0.42, 0.24, 0.16, 1.0);
uniform vec4 haze : source_color = vec4(0.95, 0.82, 0.62, 1.0);
uniform vec4 flash_col : source_color = vec4(0.85, 0.9, 1.0, 1.0);
uniform float flash = 0.0;
uniform vec2 flash_at = vec2(0.0);        // in the deep layer's coordinates
uniform vec2 vortex = vec2(400.0, 300.0); // in the billows' layer coordinates
uniform float light = 1.0;                // daylight 0 (night) … 1
uniform float seed = 0.0;

varying vec2 wpos;

void vertex() {
	wpos = origin + VERTEX / px_per_art;
}

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
	return vnoise(p) * 0.5 + vnoise(p * 2.03 + 17.0) * 0.3 + vnoise(p * 4.1 + 41.0) * 0.2;
}

vec3 band(float y) {
	float f = mod(y / 26.0, 5.0);
	float i = floor(f);
	float k = smoothstep(0.6, 1.0, f - i);
	vec3 a = band0.rgb;
	vec3 b = band1.rgb;
	if (i < 0.5) { a = band0.rgb; b = band1.rgb; }
	else if (i < 1.5) { a = band1.rgb; b = band2.rgb; }
	else if (i < 2.5) { a = band2.rgb; b = band3.rgb; }
	else if (i < 3.5) { a = band3.rgb; b = band4.rgb; }
	else { a = band4.rgb; b = band0.rgb; }
	return mix(a, b, k);
}

// The billows at layer point p: colour and density (the gaps are thin).
vec4 billows(vec2 p) {
	vec2 de = p - vortex;
	float dl = length(de / vec2(1.8, 0.8));
	if (dl < 90.0) {
		float a = (1.0 - dl / 90.0) * 2.6;
		de = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * de;
		p = vortex + de;
	}
	float wx = fbm(vec2(p.x / 70.0, p.y / 26.0)) * 40.0;
	float d = fbm(vec2((p.x + wx) / 30.0, p.y / 13.0));
	float d2 = fbm(vec2((p.x + wx + 2.5) / 30.0, (p.y + 2.5) / 13.0));
	vec3 c = band(p.y + wx * 0.5);
	float lit = clamp((d - d2) * 9.0 + 0.5, 0.0, 1.0);
	c = mix(c * 0.8, min(c * 1.14, vec3(1.0)), lit);
	return vec4(c, d);
}

void fragment() {
	vec2 w = floor(wpos) + 0.5;
	float t = TIME;
	// the deep: far down, barely moving, darker; lightning glows in it now and then
	vec2 q1 = (w - cam * 0.88 + vec2(scroll * 0.12, 0.0)) * 1.7;
	vec4 b1 = billows(q1 + vec2(311.0, 97.0));
	vec3 c1 = mix(deep.rgb, b1.rgb, 0.3) * (0.75 + 0.25 * b1.a);
	float fl = flash * exp(-length((q1 - flash_at) / vec2(1.0, 0.6)) / 70.0);
	c1 = mix(c1, flash_col.rgb, clamp(fl, 0.0, 0.85));
	// the billows: the giant's bands, the gaps down into the deep
	vec2 q2 = w - cam * 0.7 + vec2(scroll * 0.3 + t * 3.0, 0.0);
	vec4 b2 = billows(q2);
	vec3 c = mix(c1, b2.rgb, smoothstep(0.3, 0.5, b2.a));
	c = mix(c, haze.rgb, 0.2);
	// wisps of haze, nearer and faster
	vec2 q3 = (w - cam * 0.45 + vec2(scroll * 0.55 + t * 8.0, 0.0)) * vec2(0.8, 1.0);
	float wisp = smoothstep(0.6, 0.78, fbm(vec2(q3.x / 48.0, q3.y / 9.0) + 7.0));
	c = mix(c, min(haze.rgb * 1.08, vec3(1.0)), wisp * 0.55);
	// day and night over the giant
	c = mix(c * vec3(0.22, 0.26, 0.42), c, clamp(light, 0.0, 1.0));
	c = floor(c * 24.0 + 0.5) / 24.0;
	COLOR = vec4(c, 1.0);
}
