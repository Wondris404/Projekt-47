shader_type canvas_item;
// p47/gfx: pozadie hernej obrazovky – vertikalny gradient, jemna vinetacia a velmi pomaly teply odlesk.
// Lacne (par operacii na pixel), funguje v GL Compatibility. Autor: Projekt-47, CC0 1.0.
uniform vec4 top_color : source_color = vec4(0.090, 0.106, 0.129, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.047, 0.055, 0.071, 1.0);
uniform vec4 glow_color : source_color = vec4(0.910, 0.639, 0.239, 1.0);
uniform float glow_strength = 0.05;
uniform float vignette = 0.35;
uniform float speed = 0.03;

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, uv.y));
	vec2 gp = vec2(0.5 + 0.35 * sin(TIME * speed), 0.15 + 0.08 * cos(TIME * speed * 1.3));
	float g = 1.0 - smoothstep(0.0, 0.75, distance(uv * vec2(1.6, 1.0), gp * vec2(1.6, 1.0)));
	col += glow_color.rgb * g * glow_strength;
	float v = smoothstep(0.95, 0.25, distance(uv, vec2(0.5)));
	col *= mix(1.0 - vignette, 1.0, v);
	// jemny dithering proti pruhom v gradiente
	float n = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) / 255.0;
	COLOR = vec4(col, 1.0);
}
