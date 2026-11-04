// Cyberpunk backdrop: dark tint, scanlines and a slow flicker.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.02, 0.0, 0.05, 0.86);
uniform vec4 glow : source_color = vec4(0.9, 0.2, 0.7, 1.0);

void fragment() {
	float line = 0.5 + 0.5 * sin(FRAGCOORD.y * 1.7);
	float v = 1.0 - 0.22 * line;
	float sweep = smoothstep(0.0, 0.02, abs(fract(UV.y - TIME * 0.05) - 0.5) - 0.48);
	vec3 c = tint.rgb * v + glow.rgb * 0.03 * (1.0 - sweep);
	float vignette = smoothstep(1.2, 0.4, length(UV - 0.5) * 1.6);
	COLOR = vec4(c * (0.6 + 0.4 * vignette), tint.a);
}
