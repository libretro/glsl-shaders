#version 130
// film noise
// by hunterk
// license: public domain

// Parameter lines go here:
#pragma parameter x_off_r "X Offset Red" 0.05 -1.0 1.0 0.01
#pragma parameter y_off_r "Y Offset Red" 0.05 -1.0 1.0 0.01
#pragma parameter x_off_g "X Offset Green" -0.05 -1.0 1.0 0.01
#pragma parameter y_off_g "Y Offset Green" -0.05 -1.0 1.0 0.01
#pragma parameter x_off_b "X Offset Blue" -0.05 -1.0 1.0 0.01
#pragma parameter y_off_b "Y Offset Blue" 0.05 -1.0 1.0 0.01
#pragma parameter grain_str "Grain Strength" 12.0 0.0 16.0 1.0
#pragma parameter hotspot "Hotspot Toggle" 1.0 0.0 1.0 1.0
#pragma parameter vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter noise_toggle "Film Scratches" 1.0 0.0 1.0 1.0

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D noise1;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float x_off_r;
uniform COMPAT_PRECISION float y_off_r;
uniform COMPAT_PRECISION float x_off_g;
uniform COMPAT_PRECISION float y_off_g;
uniform COMPAT_PRECISION float x_off_b;
uniform COMPAT_PRECISION float y_off_b;
uniform COMPAT_PRECISION float grain_str;
uniform COMPAT_PRECISION float hotspot;
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float noise_toggle;
#else
#define x_off_r 0.05
#define y_off_r 0.05
#define x_off_g -0.05
#define y_off_g -0.05
#define x_off_b -0.05
#define y_off_b 0.05
#define grain_str 12.0
#define hotspot 1.0
#define vignette 1.0
#define noise_toggle 1.0
#endif

//https://www.shadertoy.com/view/4sXSWs strength= 16.0
float filmGrain(vec2 uv, float strength, float timer ){       
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * ((mod(timer, 800.0) + 10.0) * 10.0);
	return  (mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
}

float hash( float n ){
    return fract(sin(n)*43758.5453123);
}

void main()
{
// a simple calculation for the vignette/hotspot effects
	vec2 middle = TEX0.xy - 0.25;
	float len = length(middle);
	float vig = smoothstep(0.0, 0.5, len);

// create the noise effects from a LUT of actual film noise
	vec4 film_noise1 = COMPAT_TEXTURE(noise1, vTexCoord.xx * 2.0 *
		sin(hash(mod(float(FrameCount), 47.0))));
	vec4 film_noise2 = COMPAT_TEXTURE(noise1, vTexCoord.xy * 2.0 *
		cos(hash(mod(float(FrameCount), 92.0))));

	vec2 red_coord = vTexCoord + 0.01 * vec2(x_off_r, y_off_r);
	vec3 red_light = COMPAT_TEXTURE(Source, red_coord).rgb;
	vec2 green_coord = vTexCoord + 0.01 * vec2(x_off_g, y_off_g);
	vec3 green_light = COMPAT_TEXTURE(Source, green_coord).rgb;
	vec2 blue_coord = vTexCoord + 0.01 * vec2(x_off_r, y_off_r);
	vec3 blue_light = COMPAT_TEXTURE(Source, blue_coord).rgb;

	vec3 film = vec3(red_light.r, green_light.g, blue_light.b);
	film += filmGrain(vTexCoord.xy, grain_str, float(FrameCount)); // Film grain

	film *= (vignette > 0.5) ? (1.0 - vig) : 1.0; // Vignette
	film += ((1.0 - vig) * 0.2) * hotspot; // Hotspot

// Apply noise effects (or not)
	if (hash(float(FrameCount)) > 0.99 && noise_toggle > 0.5)
		FragColor = vec4(mix(film, film_noise1.rgb, film_noise1.a), 1.0);
	else if (hash(float(FrameCount)) < 0.01 && noise_toggle > 0.5)
		FragColor = vec4(mix(film, film_noise2.rgb, film_noise2.a), 1.0);
	else
		FragColor = vec4(film, 1.0);
} 
#endif
