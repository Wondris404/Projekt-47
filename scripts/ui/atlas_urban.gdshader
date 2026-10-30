shader_type canvas_item;
render_mode unshaded;

uniform float map_scale = 1.0;

void fragment() {
	// Decorative ~440 m blocks inside the real polygon, never outside it.
	// This is a texture, not surveyed streets or a municipal boundary.
	vec2 cell = floor(UV);
	vec2 uv = fract(UV);
	float seed = fract(sin(dot(cell,vec2(12.9898,78.233))) * 43758.5453);
	float roof = step(0.18,uv.x)*step(uv.x,0.85)*step(0.18,uv.y)*step(uv.y,0.85);
	vec3 roof_color = mix(vec3(0.49,0.39,0.32),vec3(0.72,0.69,0.61),seed);
	vec3 blocks = mix(vec3(0.31,0.33,0.31),roof_color,roof);
	// Hide subpixel blocks instead of enlarging the footprint to fit them.
	float detail = smoothstep(60.0,150.0,map_scale);
	COLOR = vec4(mix(vec3(0.52,0.50,0.45),blocks,detail),0.95);
}
