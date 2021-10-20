// Simple scanlines with curvature and mask effects lifted from crt-geom
// original by hunterk

///////////////////////  Runtime Parameters  ///////////////////////
#pragma parameter brightboost "Brightness Boost" 1.10 0.00 2.00 0.10
#pragma parameter SCANLINE_SINE_COMP_B "Scanline Intensity" 0.30 0.0 1.0 0.05
#pragma parameter cgwg "cgwg mask str. " 0.3 0.0 1.0 0.1
#pragma parameter SCANLINE_SINE_COMP_A "Scanline Sine Comp A" 0.0 0.0 0.10 0.01
#pragma parameter SCANLINE_BASE_BRIGHTNESS "Scanline Base Brightness" 0.95 0.0 1.0 0.01



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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

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
uniform COMPAT_PRECISION float brightboost;
uniform COMPAT_PRECISION float SCANLINE_BASE_BRIGHTNESS;
uniform COMPAT_PRECISION float SCANLINE_SINE_COMP_A;
uniform COMPAT_PRECISION float SCANLINE_SINE_COMP_B;
uniform COMPAT_PRECISION float cgwg;

#else
#define brightboost 1.10
#define SCANLINE_BASE_BRIGHTNESS 0.95
#define SCANLINE_SINE_COMP_A 0.0
#define SCANLINE_SINE_COMP_B 0.30
#define cgwg 0.30

#endif


//scanline calculation
vec4 scanline(vec2 coord, vec4 frame)
{
	vec2 omega = vec2(3.1415 * OutputSize.x, 2.0 * 3.1415 * TextureSize.y);
	vec2 sine_comp = vec2(SCANLINE_SINE_COMP_A, SCANLINE_SINE_COMP_B);
	vec3 res = frame.xyz;
	
	vec3 scanline = res * (SCANLINE_BASE_BRIGHTNESS + dot(sine_comp * sin(coord * omega), vec2(1.0, 1.0)));

	return vec4(scanline.x, scanline.y, scanline.z, 1.0);
}

// CGWG mask calculation
	
	vec4 Mask(vec2 pos)
	{
	vec3 mask = vec3(0.5, 0.5, 0.5);
	  
	{
      float mf = fract(gl_FragCoord.x * 0.5);
      float mc = 1.0 - cgwg;	
      if (mf <0.5) { mask.r = 1.0; mask.g = mc; mask.b = 1.0; }
      else { mask.r = mc; mask.g = 1.0; mask.b = mc; };
   }  
		return vec4(mask, 1.0);
	}

void main()
{
	vec2 pos = TEX0.xy;
	vec4 res = COMPAT_TEXTURE(Source, pos);
// apply the mask
	res *= Mask(gl_FragCoord.xy * 1.0001);
	res *=brightboost;
    FragColor = scanline(pos, res),1.0;

} 
#endif
