/*
   ShadX's Natural Vision Shader

   Ported and tweaked by Hyllian - 2016
   parameterized by Sp00kyFox

*/

#pragma parameter GIN	"NaturalVision Gamma In"	2.2 0.0 10.0 0.05
#pragma parameter GOUT	"NaturalVision Gamma Out"	2.2 0.0 10.0 0.05
#pragma parameter Y	"NaturalVision Luminance"	1.1 0.0 10.0 0.01
#pragma parameter I	"NaturalVision Orange-Cyan"	1.1 0.0 10.0 0.01
#pragma parameter Q	"NaturalVision Magenta-Green"	1.1 0.0 10.0 0.01

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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
	uniform COMPAT_PRECISION float GIN;
	uniform COMPAT_PRECISION float GOUT;
	uniform COMPAT_PRECISION float Y;
	uniform COMPAT_PRECISION float I;
	uniform COMPAT_PRECISION float Q;
#else
	#define GIN	2.2
	#define GOUT	2.2
	#define Y	1.1
	#define I	1.1
	#define Q	1.1	
#endif

#define mul(a,b) (b*a)

const mat3x3 RGBtoYIQ = mat3x3(0.299,     0.587,     0.114,
					  0.595716, -0.274453, -0.321263,
					  0.211456, -0.522591,  0.311135);

const mat3x3 YIQtoRGB = mat3x3(1,  0.95629572,  0.62102442,
					  1, -0.27212210, -0.64738060,
					  1, -1.10698902,  1.70461500);

const vec3 YIQ_lo = vec3(0, -0.595716, -0.522591);
const vec3 YIQ_hi = vec3(1,  0.595716,  0.522591);

void main()
{
	vec3 c = COMPAT_TEXTURE(Source, vTexCoord).xyz;

	c = pow(c, vec3(GIN, GIN, GIN));
	c = mul(RGBtoYIQ, c);
	c = vec3(pow(c.x,Y), c.y*I, c.z*Q);
	c = clamp(c, YIQ_lo, YIQ_hi);
	c = mul(YIQtoRGB, c);
	c = pow(c, vec3(1.0/GOUT, 1.0/GOUT, 1.0/GOUT));

    FragColor = vec4(c, 1.0);
} 
#endif
