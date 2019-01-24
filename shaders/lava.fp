// Adapted by AFADoomer from https://github.com/prideout/recipes/blob/master/demo-Lava.glsl
uniform float fogDensity = 0.3;
uniform vec3 fogColor = vec3(0, 0, 0);
uniform float timer;

vec4 Process(vec4 color)
{
	vec4 noise = texture2D(foreground, vTexCoord.st);
	vec2 T1 = vTexCoord.st + vec2(1.5, -1.5) * mod(timer, 1024) * 0.02 + noise.xy * 2.0;
	vec2 T2 = vTexCoord.st + vec2(-0.5, 2.0) * mod(timer, 1024) * 0.01 + noise.xy * 2.0;
				
	float p = texture(foreground, T1 * 2.0).a;
				
	color = getTexel(T2 * 2.0);
	FragColor = color * (vec4(p, p, p, p) * 2.0) + (color * color - 0.1);

	if(FragColor.r > 1.0) { FragColor.bg += clamp(FragColor.r - 2.0, 0.0, 100.0); }
	if(FragColor.g > 1.0) { FragColor.rb += FragColor.g - 1.0; }
	if(FragColor.b > 1.0) { FragColor.rg += FragColor.b - 1.0; }

	// Use the composited image as its own brightmap
	vec4 brightpix = desaturate(FragColor);

	FragColor = vec4(min(FragColor.rgb + brightpix.rgb, 100.0), FragColor.a);

	return mix(FragColor, vec4(fogColor, FragColor.a), fogDensity);
}