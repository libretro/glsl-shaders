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

// Ribbon Assault -  2014-02-26
// https://www.shadertoy.com/view/MdBGDK

// Inspired by the 'Kali2 scope' - https://www.shadertoy.com/view/lsBGWK
// Should be fast full-screen for everybody. : )
// Use mouse for manual movement.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float gTime = iGlobalTime+11.0;

    float f = 3., g = 3.;
	vec2 res = iResolution.xy;
#ifdef MOUSE
	vec2 mou = iMouse.xy;
	if (iMouse.z < 0.5)
	{
		mou = vec2(sin(gTime * .3)*sin(gTime * .17) * 1. + sin(gTime * .3),(1.0-cos(gTime * .632))*sin(gTime * .131)*1.0+cos(gTime * .3));
		mou = (mou+1.0) * res;
	}
#else
   vec2 mou = vec2(0.0, 0.0);
   mou = vec2(sin(gTime * .3)*sin(gTime * .17) * 1. + sin(gTime * .3),(1.0-cos(gTime * .632))*sin(gTime * .131)*1.0+cos(gTime * .3));
   mou = (mou+1.0) * res;
#endif
	vec2 z = ((-res+2.0 * fragCoord.xy) / res.y);
	vec2 p = ((-res+2.0+mou) / res.y);
	for( int i = 0; i < 20; i++) 
	{
		float d = dot(z,z);
		z = (vec2( z.x, -z.y ) / d) + p; 
		z.x =  abs(z.x);
		f = max( f, (dot(z-p,z-p) ));
		g = min( g, sin(dot(z+p,z+p))+1.0);
	}
	f = abs(-log(f) / 3.5);
	g = abs(-log(g) / 8.0);
	fragColor = vec4(min(vec3(g, g*f, f), 1.0),1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
