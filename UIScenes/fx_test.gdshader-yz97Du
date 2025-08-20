shader_type spatial;

uniform float aspect = 2.0;
uniform vec3 size = vec3(0.3, 0.3, 0.3);
uniform float speed = 0.7;
uniform float ySpread = 1.6;
uniform int numBlocks = 70;
uniform float basePulse = 0.33;
uniform vec4 color1 : source_color = vec4(0.0, 0.3, 0.6, 1.0);
uniform vec4 color2 : source_color = vec4(0.6, 0.0, 0.3, 1.0);

float rand(float x) {
    return fract(sin(x) * 4358.5453123);
}

float rand2(vec3 co) {
    return fract(sin(dot(co, vec3(12.9898, 78.233, 45.164))) * 43758.5357);
}

float pulseColor() {
    float myPulse = basePulse + sin(TIME) * 0.1;
    return myPulse < 1.0 ? myPulse : 1.0;
}

float box(vec3 p, vec3 b, float r) {
    return length(max(abs(p)-b, 0.0)) - r;
}

void fragment() {
    float pulse = pulseColor();

    vec3 worldPos = VERTEX;
    vec4 baseColor = worldPos.x > 0.0 ? color1 : color2;
    vec4 color = pulse * baseColor * 0.5 * (0.9 - cos(worldPos.x * 8.0));

    worldPos.x *= aspect;

    for (int i = 0; i < numBlocks; i++) {
        float z = 1.0 - 0.7 * rand(float(i) * 1.4333);
        float tickTime = TIME * z * speed + float(i) * 1.23753;
        float tick = floor(tickTime);

        vec3 pos = vec3(0.6 * aspect * (rand(tick) - 0.5),
                         sign(worldPos.x) * ySpread * (0.5 - fract(tickTime)),
                         rand(tick + 1.5) - 0.5);
        pos.x += 0.24 * sign(pos.x);
        if (abs(pos.x) < 0.1) pos.x += 1.0;

        float b = box(worldPos - pos, size, 0.01);
        float dust = z * smoothstep(0.22, 0.0, b) * pulse * 0.5;
        float block = 0.2 * z * smoothstep(0.002, 0.0, b);
        float shine = 0.6 * z * pulse * smoothstep(-0.002, b, 0.007);

        color += dust * baseColor + block * z + shine;
    }

    color -= rand2(worldPos) * 0.04;
    ALBEDO = color.rgb;
    ALPHA = color.a;
}
