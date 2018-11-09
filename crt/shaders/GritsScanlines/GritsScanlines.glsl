// GritsScanlines by torridgristle
// license: public domain (https://forums.libretro.com/t/lightweight-lut-based-scanline-glow-concept-prototype-glsl/18336/7)

#pragma parameter ScanlinesOpacity "Scanline Opacity" 0.9 0.0 1.0 0.05
#pragma parameter GammaCorrection "Gamma Correction" 1.2 0.5 2.0 0.1

//#define LuminanceDawnbringer
#define LuminanceLUT
//#define TrinitronColors

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
uniform sampler2D scanlines_LUT;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ScanlinesOpacity, GammaCorrection;
#else
#define ScanlinesOpacity 0.9
#define GammaCorrection 1.2
#endif

#ifdef LuminanceLUT

uniform sampler2D luminance_LUT;

#define LUT_SizeLum 16.0

	// Code taken from RetroArch's LUT shader
float luminancelut(vec4 org)
{
	vec4 imgColorLum = org;
	float redLum = ( imgColorLum.r * (LUT_SizeLum - 1.0) + 0.4999 ) / (LUT_SizeLum * LUT_SizeLum);
	float greenLum = ( imgColorLum.g * (LUT_SizeLum - 1.0) + 0.4999 ) / LUT_SizeLum;
	float blue1Lum = (floor( imgColorLum.b  * (LUT_SizeLum - 1.0) ) / LUT_SizeLum) + redLum;
	float blue2Lum = (ceil( imgColorLum.b  * (LUT_SizeLum - 1.0) ) / LUT_SizeLum) + redLum;
	float mixerLum = clamp(max((imgColorLum.b - blue1Lum) / (blue2Lum - blue1Lum), 0.0), 0.0, 32.0);
	float color1Lum = COMPAT_TEXTURE(luminance_LUT, vec2( blue1Lum, greenLum )).x;
	float color2Lum = COMPAT_TEXTURE(luminance_LUT, vec2( blue2Lum, greenLum )).x;
	return mix(color1Lum, color2Lum, mixerLum);
}
#endif

#ifdef TrinitronColors

uniform sampler2D color_LUT;

#define LUT_SizeTrinitron 32.0

vec4 TrinitronD50(vec4 org)
{
	vec4 imgColorTrinitron = org;
	float redTrinitron = ( imgColorTrinitron.r * (LUT_SizeTrinitron - 1.0) + 0.4999 ) / (LUT_SizeTrinitron * LUT_SizeTrinitron);
	float greenTrinitron = ( imgColorTrinitron.g * (LUT_SizeTrinitron - 1.0) + 0.4999 ) / LUT_SizeTrinitron;
	float blue1Trinitron = (floor( imgColorTrinitron.b  * (LUT_SizeTrinitron - 1.0) ) / LUT_SizeTrinitron) + redTrinitron;
	float blue2Trinitron = (ceil( imgColorTrinitron.b  * (LUT_SizeTrinitron - 1.0) ) / LUT_SizeTrinitron) + redTrinitron;
	float mixerTrinitron = clamp(max((imgColorTrinitron.b - blue1Trinitron) / (blue2Trinitron - blue1Trinitron), 0.0), 0.0, 32.0);
	vec4 color1Trinitron = COMPAT_TEXTURE(color_LUT, vec2( blue1Trinitron, greenTrinitron ));
	vec4 color2Trinitron = COMPAT_TEXTURE(color_LUT, vec2( blue2Trinitron, greenTrinitron ));
	vec4 fragColorTrinitron = mix(color1Trinitron, color2Trinitron, mixerTrinitron);
	return vec4(pow(fragColorTrinitron.rgb,vec3(GammaCorrection,GammaCorrection,GammaCorrection)),1.0);
} 
#endif

void main()
{
//Source Image
	vec4 org = COMPAT_TEXTURE(Source, vTexCoord);
   
#ifdef LuminanceLUT
// Use a 3DLUT instead of an equation so that it can use any arbitrary mess you can come up with.
	float luminance = luminancelut(org);
#elif defined LuminanceDawnbringer
// Dawnbringer's brightness equation from Dawnbringer's Toolbox scripts for Grafx2
	float luminance = sqrt(org.r*org.r*0.0676 + org.g*org.g*0.3025 + org.b*org.b*0.0361) * 1.5690256395005606;
#else
// Plain, standard, fine; slightly faster
	float luminance = ((0.299*org.r) + (0.587*org.g) + (0.114*org.b));
#endif

// Don't let it exceed 1.0
	luminance = clamp(luminance, 0.0001, 0.9999);

// Scanline Mapping, based on the Phosphor LUT shader's method of tiling a texture over the screen
	vec2 LUTeffectiveCoord = vec2(luminance,fract(vTexCoord.y*SourceSize.y));

// Scanline Layer
	vec4 screen = COMPAT_TEXTURE(scanlines_LUT, LUTeffectiveCoord);

// Output multiplying the scanlines into the original image, with control over opacity
#ifdef TrinitronColors
	org = TrinitronD50(org);
#endif
	FragColor = ((screen*ScanlinesOpacity)+(1.0 - ScanlinesOpacity)) * (org);
} 
#endif
