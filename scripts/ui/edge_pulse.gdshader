shader_type canvas_item;
// p47/gfx: farebny okraj obrazovky (kriza/vojna). Stred je priehladny. Autor: Projekt-47, CC0 1.0.
uniform vec4 tint : source_color = vec4(0.85, 0.12, 0.08, 1.0);
uniform float width = 0.22;

void fragment() {
	vec2 d = min(UV, 1.0 - UV);
	float e = 1.0 - smoothstep(0.0, width, min(d.x, d.y * 1.6));
	COLOR = vec4(tint.rgb, tint.a * e * 0.55);
}
