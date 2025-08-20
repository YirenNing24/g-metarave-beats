shader_type canvas_item;

uniform float aspect = 2.0;
uniform vec2 size = vec2(0.3);
uniform float speed = 0.7;
uniform float ySpread = 1.6;
uniform int numBlocks = 70;
uniform float basePulse = 0.33;
uniform vec4 color1 : source_color = vec4(0.0,0.3, 0.6, 1.0);

float rand(float x)
{
    return fract(sin(x) * 4358.5453123);
}

float rand2(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5357);
}

float pulseColor()
{
	float myPulse = basePulse + sin(TIME) * 0.1;
	return myPulse < 1.0 ? myPulse : 1.0;
}

float box(vec2 p, vec2 b, float r)
{
  return length(max(abs(p)-b,0.0))-r;
}

void fragment()
{
	float pulse = pulseColor();

	vec2 uv = UV - 0.5;
	vec4 color = pulse*color1*0.5*(0.9-cos(uv.x*8.0));
	uv.x *= aspect;

	for (int i = 0; i < numBlocks; i++)
	{
		float z = 1.0-0.7*rand(float(i)*1.4333); // 0=far, 1=near
		float tickTime = TIME*z*speed + float(i)*1.23753;
		float tick = floor(tickTime);

		vec2 pos = vec2(0.6*aspect*(rand(tick)-0.5), sign(uv.x)*ySpread*(0.5-fract(tickTime)));
		pos.x += 0.24*sign(pos.x); // move aside
		if (abs(pos.x) < 0.1) pos.x++; // stupid fix; sign sometimes returns 0

		float b = box(uv-pos, size, 0.01);
		float dust = z*smoothstep(0.22, 0.0, b)*pulse*0.5;
		float block = 0.2*z*smoothstep(0.002, 0.0, b);
		float shine = 0.6*z*pulse*smoothstep(-0.002, b, 0.007);
		color += dust*color1 + block*z + shine;
	}

	color -= rand2(uv)*0.04;
	COLOR = vec4(color);
}