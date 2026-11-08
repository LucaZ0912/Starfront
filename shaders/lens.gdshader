// Gravitational lens round a black hole (package 37): bends what lies behind it – the stars and the nebula of the
// background – towards a ring round the hole. Reads the screen drawn so far.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float horizon = 0.07;        // event horizon radius relative to the quad half-width
uniform float strength = 1.0;
uniform vec2 quad_screen = vec2(0.2, 0.3);   // quad half-size as a share of the screen (x, y)

void fragment() {
	vec2 c = (UV - 0.5) * 2.0;
	float d = length(c);
	if (d >= 1.0) {
		discard;
	}
	// deflection grows towards the hole (∝ 1/d), fades to nothing at the quad edge
	float fade = 1.0 - smoothstep(0.55, 1.0, d);
	float bend = strength * horizon * 0.45 / max(d, horizon) * fade;
	vec2 dir = c / max(d, 0.0001);
	// no bending near the screen edge (it would pull in pixels from outside the screen)
	float edge = min(min(SCREEN_UV.x, 1.0 - SCREEN_UV.x), min(SCREEN_UV.y, 1.0 - SCREEN_UV.y));
	vec2 off = dir * bend * quad_screen * smoothstep(0.0, 0.2, edge);
	vec3 col = texture(screen_tex, clamp(SCREEN_UV + off, vec2(0.002), vec2(0.998))).rgb;
	// an Einstein ring: light piling up just outside the horizon
	float ring = exp(-pow((d - horizon * 1.6) / (horizon * 0.35), 2.0)) * 0.25 * fade;
	COLOR = vec4(col + vec3(ring), fade > 0.0 ? 1.0 : 0.0);
}
