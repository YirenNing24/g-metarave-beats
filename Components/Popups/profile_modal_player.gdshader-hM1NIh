shader_type canvas_item;

uniform float gradient_width : hint_range(0.0, 1.0) = 0.5; // Right side fade width
uniform vec4 panel_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Panel base color

uniform float border_thickness : hint_range(0.0, 0.1) = 0.02; // Thickness of top border
uniform vec4 border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Border color
uniform float border_fade_width : hint_range(0.0, 0.5) = 0.2; // How much the border fades on the sides

uniform float shadow_height : hint_range(0.0, 0.2) = 0.1; // Shadow fade size
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5); // Shadow color

void fragment() {
	// === Right-Side Transparency Fade ===
	float fade_factor = (UV.x - (1.0 - gradient_width)) / gradient_width;
	fade_factor = clamp(fade_factor, 0.0, 1.0);
	vec4 base_color = vec4(panel_color.rgb, panel_color.a * (1.0 - fade_factor)); // Ensure panel color is applied

	// === Top Border with Side Gradation ===
	float border_mask = step(UV.y, border_thickness);

	// Left and Right Gradation for the Border
	float border_fade = (UV.x / border_fade_width); // Left side fade
	border_fade = min(border_fade, (1.0 - UV.x) / border_fade_width); // Right side fade
	border_fade = clamp(border_fade, 0.0, 1.0);

	// Blend the border color with transparency on its sides
	vec4 border = mix(vec4(0.0), border_color, border_fade) * border_mask; // Fix border mixing

	// === Shadow under the top border ===
	float shadow_factor = (UV.y - border_thickness) / shadow_height;
	shadow_factor = clamp(shadow_factor, 0.0, 1.0);
	vec4 shadow = vec4(shadow_color.rgb, shadow_color.a * (1.0 - shadow_factor));

	// === Combine Everything Correctly ===
	vec4 final_color = base_color; // Start with base color
	final_color = mix(final_color, border, border_mask * border.a); // Apply border properly
	final_color = mix(final_color, shadow, shadow_factor * shadow.a); // Apply shadow without affecting base

	COLOR = final_color;
}
