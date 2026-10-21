shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Lush Myanmar Paddy & Foliage Wind Sway Shader
uniform vec4 foliage_color : source_color = vec4(0.28, 0.68, 0.18, 1.0);
uniform vec4 stalk_color : source_color = vec4(0.18, 0.45, 0.12, 1.0);
uniform float wind_speed : hint_range(0.2, 4.0) = 1.6;
uniform float wind_strength : hint_range(0.02, 0.5) = 0.12;

void vertex() {
	if (VERTEX.y > 0.1) {
		float sway = sin(TIME * wind_speed + VERTEX.x * 2.0 + VERTEX.z * 1.5) * wind_strength;
		VERTEX.x += sway * (VERTEX.y / 1.5);
		VERTEX.z += sway * 0.6 * (VERTEX.y / 1.5);
	}
}

void fragment() {
	ALBEDO = mix(stalk_color.rgb, foliage_color.rgb, clamp(UV.y, 0.0, 1.0));
	ROUGHNESS = 0.6;
	SPECULAR = 0.3;
}