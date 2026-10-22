shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Authentic Myanmar Realistic Ayeyarwady River Water PBR Shader
uniform vec4 shallow_color : source_color = vec4(0.24, 0.48, 0.42, 0.88);
uniform vec4 deep_color : source_color = vec4(0.12, 0.28, 0.32, 0.96);
uniform vec4 sediment_color : source_color = vec4(0.42, 0.34, 0.22, 0.92);
uniform float wave_speed : hint_range(0.1, 3.0) = 0.95;
uniform float wave_amplitude : hint_range(0.01, 0.4) = 0.12;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.04;

void vertex() {
	float t = TIME * wave_speed;
	float wave1 = sin(VERTEX.x * 1.2 + t) * cos(VERTEX.z * 0.9 + t * 0.75);
	float wave2 = sin(VERTEX.x * 2.4 - t * 1.1) * cos(VERTEX.z * 1.8 + t);
	VERTEX.y += (wave1 + wave2 * 0.45) * wave_amplitude;
	NORMAL = normalize(vec3(
		-cos(VERTEX.x * 1.2 + t) * wave_amplitude * 1.2,
		1.0,
		-cos(VERTEX.z * 0.9 + t * 0.75) * wave_amplitude * 0.9
	));
}

void fragment() {
	vec2 uv_flow1 = UV * 8.0 + vec2(TIME * 0.14, TIME * 0.06);
	vec2 uv_flow2 = UV * 14.0 - vec2(TIME * 0.08, -TIME * 0.16);
	float ripple1 = sin(uv_flow1.x * 6.28) * cos(uv_flow1.y * 6.28);
	float ripple2 = sin(uv_flow2.x * 6.28) * cos(uv_flow2.y * 6.28);
	float foam = clamp((ripple1 + ripple2 - 0.92) * 2.2, 0.0, 0.35);

	// Mix authentic Myanmar alluvial river sediment with emerald deep channel
	vec3 base_water = mix(shallow_color.rgb, deep_color.rgb, 0.5);
	vec3 water_col = mix(base_water, sediment_color.rgb, 0.25);
	ALBEDO = mix(water_col, vec3(0.94, 0.97, 0.98), foam);
	ALPHA = shallow_color.a;
	ROUGHNESS = roughness_val;
	METALLIC = 0.15;
	SPECULAR = 0.98;
}