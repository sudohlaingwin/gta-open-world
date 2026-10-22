shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// High-Fidelity Myanmar Tropical Foliage & Paddy Sway Shader (Mobile Vulkan Optimized)
uniform vec4 foliage_color : source_color = vec4(0.24, 0.62, 0.16, 1.0);
uniform vec4 stalk_color : source_color = vec4(0.16, 0.40, 0.10, 1.0);
uniform vec4 sun_transmission_color : source_color = vec4(0.48, 0.85, 0.22, 1.0);
uniform float wind_speed : hint_range(0.2, 5.0) = 1.8;
uniform float wind_strength : hint_range(0.02, 0.8) = 0.22;
uniform float flutter_speed : hint_range(1.0, 15.0) = 6.5;
uniform float flutter_strength : hint_range(0.01, 0.25) = 0.08;

void vertex() {
	if (VERTEX.y > 0.08) {
		float height_weight = clamp(VERTEX.y / 1.6, 0.0, 1.5);
		float height_sq = height_weight * height_weight;
		
		// Dual-harmonic macro wind swaying
		float wind_main = sin(TIME * wind_speed + VERTEX.x * 1.8 + VERTEX.z * 1.2) * wind_strength;
		float wind_gust = sin(TIME * (wind_speed * 1.6) + VERTEX.x * 0.9 + VERTEX.z * 2.4) * (wind_strength * 0.45);
		float total_macro_sway = (wind_main + wind_gust) * height_sq;
		
		// High-frequency leaf tip fluttering (breeze across rice paddies and palm fronds)
		float leaf_flutter = sin(TIME * flutter_speed + VERTEX.x * 6.0 + VERTEX.z * 5.0) * flutter_strength * height_weight;
		
		VERTEX.x += total_macro_sway + leaf_flutter * 0.7;
		VERTEX.z += (total_macro_sway * 0.65) + leaf_flutter;
		VERTEX.y -= abs(total_macro_sway) * 0.15; // Realistic drooping arc under strong gusts
	}
}

void fragment() {
	float gradient = clamp(UV.y, 0.0, 1.0);
	vec3 base_col = mix(stalk_color.rgb, foliage_color.rgb, gradient);
	
	// Subtle fake subsurface scattering / backlighting for lush tropical vegetation
	float sss_factor = clamp(dot(NORMAL, vec3(0.0, 0.8, -0.6)), 0.0, 1.0) * 0.25;
	vec3 final_col = mix(base_col, sun_transmission_color.rgb, sss_factor * gradient);
	
	ALBEDO = final_col;
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
}