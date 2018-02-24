// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter RETRO_PIXEL_SIZE "Retro Pixel Size" 0.84 0.0 1.0 0.01
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float RETRO_PIXEL_SIZE;
#else
#define RETRO_PIXEL_SIZE 0.84
#endif

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
// out variables go here as COMPAT_VARYING whatever

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
    TEX0.xy = VertexCoord.xy;
// Paste vertex contents here:
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

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

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// delete all 'params.' or 'registers.' or whatever in the fragment
float iGlobalTime = float(FrameCount)*0.025;
vec2 iResolution = OutputSize.xy;

// Star Swirl -  srtuss - 2014-10-08
// https://www.shadertoy.com/view/Xd2XDm

// playing around in with 2d things. has an 178 bpm breakbeat in it ^^

// srtuss, 2014

#define pi 3.1415926535897932384626433832795

float tri(float x)
{
	return abs(fract(x) * 2.0 - 1.0);
}

float dt(vec2 uv, float t)
{
	vec2 p = mod(uv * 10.0, 2.0) - 1.0;
	float v = 1.0 / (dot(p, p) + 0.01);
	p = mod(uv * 11.0, 2.0) - 1.0;
	v += 0.5 / (dot(p, p) + 0.01);
	return v * (sin(uv.y * 2.0 + t * 8.0) + 1.5);
}

float fun(vec2 uv, float a, float t)
{
	float beat = t * 178.0 / 4.0 / 60.0;
	float e = floor(beat) * 0.1 + 1.0;
	beat = fract(beat) * 16.0;
	float b1 = 1.0 - mod(beat, 10.0) / 10.0;
	float b2 = mod(beat, 8.0) / 8.0;
	b1 = exp(b1 * -1.0) * 0.1;
	b2 = exp(b2 * -4.0);
	e = floor(fract(sin(e * 272.0972) * 10802.5892) * 4.0) + 1.0;
	float l = length(uv);
	float xx = l - 0.5 + sin(mod(l * 0.5 - beat / 16.0, 1.0) * pi * 2.0);
	a += exp(xx * xx * -10.0) * 0.05;
	vec2 pp = vec2(a * e + l * sin(t * 0.4) * 2.0, l);
	pp.y = exp(l * -2.0) * 10.0 + tri(pp.x) + t * 2.0 - b1 * 4.0;
	float v = pp.y;
	v = sin(v) + sin(v * 0.5) + sin(v * 3.0) * 0.2;
	v = fract(v) + b2 * 0.2;
	v += exp(l * -4.5);
	v += dt(pp * vec2(0.5, 1.0), t) * 0.01;
	return v;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float t = iGlobalTime;
	vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
	uv.x *= 0.7 * iResolution.x / iResolution.y;
	float an = atan(uv.y, uv.x) / pi;
	float a = 0.02;
	float v =
		fun(uv, an, t + a * -3.) +
		fun(uv, an, t + a * -2.) * 6. +
		fun(uv, an, t + a * -1.) * 15. +
		fun(uv, an, t + a *  0.) * 20. +
		fun(uv, an, t + a *  1.) * 15. +
		fun(uv, an, t + a *  2.) * 6. +
		fun(uv, an, t + a *  3.);
	v /= 64.0;
	vec3 col;
	col = clamp(col, vec3(0.0), vec3(1.0));
	col = pow(vec3(v, v, v), vec3(0.5, 2.0, 1.5) * 8.0) * 3.0;
	col = pow(col, vec3(1.0 / 2.2));
	fragColor = vec4(col, 1.0);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
