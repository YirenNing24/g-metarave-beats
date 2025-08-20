shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 ScaleMult = vec2(0.9);  // Smaller value for larger aura
uniform float AuraProgres :hint_range(0.0, 1.0, 0.1) = 1.0;  // Full aura blending
uniform float TextureLaodMult :hint_range(0.0, 10.0, 0.01) = 8.0;
uniform float Tilling :hint_range(0.0, 60.0, 0.01) = 10.0;  // Lower value for larger aura pattern
uniform vec2 MovementDirSpeed = vec2(-0.3, 0.5);  // Adjusted for smoother movement
uniform vec2 MovementDirSpeed2 = vec2(0.3, 0.5);
uniform sampler2D color_gradiant :repeat_enable, filter_linear_mipmap;
uniform vec2 Noise_Seed = vec2(1.0);

vec2 random(vec2 uv){
    uv += Noise_Seed;
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);
    float bottom_left = dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0));
    float bottom_right = dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0));
    float top_left = dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0));
    float top_right = dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0));
    float bottom_mix = mix(bottom_left, bottom_right, blur.x);
    float top_mix = mix(top_left, top_right, blur.x);
    float final_value = mix(bottom_mix, top_mix, blur.y);
    return (final_value + 1.0) * 0.5;
}

vec4 AuraEffect(vec2 uv, vec4 CurrentColor, sampler2D OriginTexTure){
    vec2 TimeUV = MovementDirSpeed * TIME;
    vec2 TimeUV2 = MovementDirSpeed2 * TIME;
    vec2 ScaleMultFractment = (1.0 - ScaleMult)/2.0;
    vec2 compos_uv = uv * ScaleMult + ScaleMultFractment;
    vec4 alpha = textureLod(OriginTexTure, compos_uv, noise(uv * Tilling + TimeUV) * TextureLaodMult);
    vec4 GradientColors = texture(color_gradiant, fract( vec2(-uv.y, uv.x) + (TimeUV * 0.4)) ) * 3.0;
    vec4 sil = GradientColors * noise(uv * Tilling - TimeUV);
    sil.a = alpha.a * noise(uv * Tilling + TimeUV) * noise(uv * Tilling + TimeUV2) * 10.0;  // Enhanced alpha blending
    return mix(CurrentColor, sil * AuraProgres, (1.0 - CurrentColor.a));
}

void fragment() {
    COLOR = AuraEffect(UV, COLOR, TEXTURE);
}
