shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Authentic Myanmar Realistic River Water PBR Shader
uniform vec4 shallow_color : source_color = vec4(0.18, 0.52, 0.58, 0.85);
uniform vec4 deep_color : source_color = vec4(0.08, 0.22, 0.32, 0.95);
uniform float wave_speed : hint_range(0.1, 3.0) = 0.8;
uniform float wave_amplitude : hint_range(0.01, 0.3) = 0.08;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.05;

void vertex() {
	float t = TIME * wave_speed;
	float wave1 = sin(VERTEX.x * 1.5 + t) * cos(VERTEX.z * 1.2 + t * 0.8);
	float wave2 = sin(VERTEX.x * 2.8 - t * 1.2) * cos(VERTEX.z * 2.4 + t);
	VERTEX.y += (wave1 + wave2 * 0.5) * wave_amplitude;
	NORMAL = normalize(vec3(
		-cos(VERTEX.x * 1.5 + t) * wave_amplitude * 1.5,
		1.0,
		-cos(VERTEX.z * 1.2 + t * 0.8) * wave_amplitude * 1.2
	));
}

void fragment() {
	ALBEDO = mix(shallow_color.rgb, deep_color.rgb, 0.5);
	ALPHA = shallow_color.a;
	ROUGHNESS = roughness_val;
	METALLIC = 0.15;
	SPECULAR = 0.8;
}