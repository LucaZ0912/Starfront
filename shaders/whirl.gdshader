shader_type canvas_item;
// Package 59 (Luz): the Threshold swirling into the black hole in its own middle, like a whirlpool filter laid on
// the ship. The picture is square with the hole in its centre; "twist" winds it up (strongest near the centre),
// "pull" draws everything inwards until nothing is left.

uniform float twist = 0.0;        // radians of winding at the centre
uniform float pull = 0.0;         // 0 = as it is … 1 = all of it in the hole
uniform vec4 tint : source_color = vec4(0.6, 0.38, 1.0, 1.0);

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;                       // 0 centre … 1 edge
	// what shows here came from further out: the inner parts go first, the tips trail behind in a spiral
	float s = 1.0 - pull;
	float r_src = r / max(pow(s, 1.0 + 0.7 * (1.0 - clamp(r, 0.0, 1.0))), 0.0005);
	float k = clamp(1.0 - r, 0.0, 1.0);
	float a = twist * pow(k, 1.3);
	float ang = atan(d.y, d.x) - a;
	vec2 uv = vec2(0.5) + vec2(cos(ang), sin(ang)) * r_src * 0.5;
	vec4 c = vec4(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0 && r_src <= 1.0) {
		c = texture(TEXTURE, uv);
	}
	// the hull glows violet as it winds in, and fades at the very end
	float heat = clamp(pull * 1.3, 0.0, 1.0) * clamp(1.0 - r * 1.2, 0.0, 1.0);
	c.rgb = mix(c.rgb, tint.rgb * 1.3, heat * 0.75);
	c.a *= 1.0 - smoothstep(0.9, 1.0, pull);
	COLOR = c;
}
