shader_type canvas_item;
render_mode unshaded;

// Colour grade the existing Natural Earth terrain; no copied mod textures.
// Sample colour only: independent of tile UV, camera position and game time.
void fragment() {
	// CanvasItem fragment COLOR already includes the texture sample.
	vec4 source = COLOR;
	float light = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float blue = source.b - max(source.r * 1.02, source.g * 1.03);
	float water = smoothstep(0.005, 0.055, blue);
	vec3 earth = mix(vec3(light), source.rgb, 0.44);
	earth = earth * vec3(0.88, 0.86, 0.78) + vec3(0.065, 0.064, 0.057);
	vec3 ocean = mix(vec3(0.13, 0.19, 0.28), vec3(0.29, 0.39, 0.49), clamp(light * 1.9, 0.0, 1.0));
	COLOR = vec4(mix(earth, ocean, water), source.a);
}
