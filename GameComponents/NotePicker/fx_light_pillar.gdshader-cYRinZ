// This is a 3D shader
shader_type spatial;
// Pure light, no default shadows and shades
render_mode blend_add, unshaded;

// Make color selectable
uniform vec4 albedo : source_color;

// Effects configuration
uniform float brightness: hint_range(0.0, 10.0) = 1.0;
uniform float small_lines: hint_range(0.0, 1.0) = 1.0;
uniform float medium_lines: hint_range(0.0, 1.0) = 1.0;
uniform float big_lines: hint_range(0.0, 1.0) = 1.0;
uniform float horizontal_fade: hint_range(0.001, 1.0) = 1.0;
uniform float vertical_fade: hint_range(0.001, 10.0) = 2.0;
uniform float animation_speed: hint_range(0.01, 5.0) = 1.0;

// Simple cosine wave, moving horizontaly over time
float animate_cos(float phase, float speed) {
 return pow(0.5 * cos(phase * TAU + TIME * speed * animation_speed) + 0.5, 2.0);
}

void vertex() {
 // Make it always face camera direction, copied from Godot source code
 // Code imitted, see original on github
}

void fragment() {
 // Apply user-selected color and transparency
 ALBEDO = albedo.rgb;
 ALPHA = albedo.a;

 // Move point (0, 0) to quad center
 vec2 centered_UV = UV * 2.0 - 1.0;

 // This is where the "magic" happens
 float vertical_lines = 0.0;
 vertical_lines += animate_cos(centered_UV.x * 0.9, -2.1) * big_lines;
 vertical_lines += animate_cos(centered_UV.x * 1.9, -1.1) * medium_lines;
 vertical_lines += animate_cos(centered_UV.x * 2.9, 3.1) * small_lines;
 vertical_lines *= brightness;

 // Apply lines if there are any, keep solid color otherwise
 // This is done for demo purposes only, to make components
 // Of the effect visible
 if (small_lines + medium_lines + big_lines > 0.01) {
  ALPHA *= vertical_lines;
 }

 // Fade out left and right edges
 ALPHA *= pow(cos(centered_UV.x * PI) * 0.5 + 0.5, horizontal_fade);

 // Fade out top and bottom
 ALPHA *= pow(1.0 - abs(centered_UV.y), vertical_fade);

 // We implement fading differently for vertical and horizontal,
 // just to illustrate the idea that
 // different curves can achieve very similar effects
}