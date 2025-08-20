shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;



uniform sampler2D texture_albedo : source_color;
uniform float threshold = 0.1;
uniform float effect_alpha_mult : hint_range(0,1) = 1.0;
uniform float direction : hint_range(0,1) = 0.5;
uniform float specular = 1.0;
uniform float metallic : hint_range(0,1) = 0.75;
uniform float roughness: hint_range(0,1) = 0.75;
uniform float emission_energy: hint_range(0,1) = 0.2;
uniform sampler2D gradient: source_color;
uniform sampler2D noise: source_color;

/* Scanline Effect Variables */
uniform float line_smoothness : hint_range(0, 0.1) = 0.045;
uniform float line_width : hint_range(0, 0.2) = 0.09;
uniform float scanline_brightness = 1.0;
uniform float rotation_deg : hint_range(-90, 90) = 30;
uniform float distortion : hint_range(1, 2) = 1.8;
uniform float speed = 0.7;
uniform float position : hint_range(0, 1) = 0;
uniform float position_min = 0.25;
uniform float position_max = 0.5;
uniform float scanline_alpha : hint_range(0, 1) = 1;

/* New: Scanline Timer */
uniform float scanline_interval : hint_range(0.1, 10.0) = 3.0; /* Time between appearances */
uniform float scanline_duration : hint_range(0.1, 5.0) = 1.0;   /* Duration scanline stays visible */

vec2 rotate_uv(vec2 uv, vec2 center, float rotation, bool use_degrees) {
	float _angle = use_degrees ? rotation * (3.1415926 / 180.0) : rotation;
	mat2 _rotation = mat2(
		vec2(cos(_angle), -sin(_angle)),
		vec2(sin(_angle), cos(_angle))
	);
	vec2 _delta = uv - center;
	_delta = _rotation * _delta;
	return _delta + center;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, UV);
	vec4 noise_tex = texture(noise, base_uv);
	vec4 gradient_tex = texture(gradient, vec2(
		(0.25 + (NORMAL.y * direction * 2.0 - NORMAL.x * (1.0 - direction) * 2.0) / 2.0 + (UV.y * direction + UV.x * (1.0 - direction)) / 2.0),
		0.0
	));

	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;

	/* Apply Material Properties */
	if (albedo_tex.r < threshold && albedo_tex.g < threshold && albedo_tex.b < threshold && albedo_tex.a > 0.3) {
		METALLIC = metallic;
		ROUGHNESS = roughness;
		SPECULAR = specular;

		/* Base holographic effect remains unchanged */
		vec3 holo_color = mix(ALBEDO, gradient_tex.rgb * (noise_tex.rgb * 2.0),
		                      (effect_alpha_mult - length(ALBEDO)) * gradient_tex.a * effect_alpha_mult);

		/* ---- Scanline Glow Effect ---- */
		vec2 center_uv = UV - vec2(0.5, 0.5);
		float gradient_to_edge = max(abs(center_uv.x), abs(center_uv.y)) * distortion;
		gradient_to_edge = 1.0 - gradient_to_edge;

		vec2 rotated_uv = rotate_uv(UV, vec2(0.5, 0.5), rotation_deg, true);
		float remapped_position = position_min + (position_max - position_min) * position;
		float remapped_time = fract(TIME * speed + remapped_position);
		remapped_time = -2.0 + 4.0 * remapped_time;

		vec2 offset_uv = rotated_uv.xy + vec2(remapped_time, 0.0);
		float line = abs(offset_uv.x) * gradient_to_edge;
		line = sqrt(line);

		float offset_plus = line_width + line_smoothness;
		float offset_minus = line_width - line_smoothness;
		float remapped_line = (line - offset_plus) / (offset_minus - offset_plus);
		remapped_line = clamp(remapped_line * scanline_brightness, 0.0, scanline_alpha);

		/* ---- Time-based Scanline Control ---- */
		float scanline_time = mod(TIME, scanline_interval);
		float scanline_visible = step(scanline_time, scanline_duration); /* 1 = Visible, 0 = Hidden */
		remapped_line *= scanline_visible; /* Only apply effect when visible */

		/* Blend Scanline Effect */
		vec3 scanline_effect = holo_color + (vec3(1.0) * remapped_line); /* Add highlights */

		/* Final Output */
		ALBEDO = holo_color;
		EMISSION = scanline_effect * emission_energy;
	}
}
