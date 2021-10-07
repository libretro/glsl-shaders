// A version of the LUT shader that loads 2 LUTs.
// For use with Kurozumi's 64-bit colorspace LUTs.

#pragma parameter LUT_selector_param "Color Temp (1=D65, 2=D93)" 1.0 1.0 2.0 1.0
//#pragma parameter LUT_Size1 "LUT Size 1" 16.0 1.0 64.0 1.0
//#pragma parameter LUT_Size2 "LUT Size 2" 16.0 1.0 64.0 1.0

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
uniform sampler2D SamplerLUT1;
uniform sampler2D SamplerLUT2;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float LUT_selector_param;
#else
#define LUT_selector_param 1.0
#endif

const float LUT_Size1 = 64.0;
const float LUT_Size2 = 64.0; // hardcode these for Kurozumi's LUTs

int LUT_selector = int(LUT_selector_param);

// This shouldn't be necessary but it seems some undefined values can
// creep in and each GPU vendor handles that differently. This keeps
// all values within a safe range
vec4 mixfix(vec4 a, vec4 b, float c)
{
	return (a.z < 1.0) ? mix(a, b, c) : a;
}

void main()
{
	vec4 imgColor = COMPAT_TEXTURE(Source, vTexCoord.xy);
	vec4 color1, color2 = vec4(0.,0.,0.,0.);
	float red, green, blue1, blue2, mixer = 0.0;
	if(LUT_selector == 1)
	{
		red = ( imgColor.r * (LUT_Size1 - 1.0) + 0.4999 ) / (LUT_Size1 * LUT_Size1);
		green = ( imgColor.g * (LUT_Size1 - 1.0) + 0.4999 ) / LUT_Size1;
		blue1 = (floor( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
		blue2 = (ceil( imgColor.b  + 0.000001 * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
		mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
		color1 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue1, green ));
		color2 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue2, green ));
	}
	if(LUT_selector == 2)
	{
		red = ( imgColor.r * (LUT_Size2 - 1.0) + 0.4999 ) / (LUT_Size2 * LUT_Size2);
		green = ( imgColor.g * (LUT_Size2 - 1.0) + 0.4999 ) / LUT_Size2;
		blue1 = (floor( imgColor.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red;
		blue2 = (ceil( imgColor.b  + 0.000001 * (LUT_Size2 - 1.0) ) / LUT_Size2) + red;
		mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
		color1 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue1, green ));
		color2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue2, green ));
	}
	FragColor = mixfix(color1, color2, mixer);
} 
#endif
