/*
	Anti-Flicker shader
	by hunterk
	License: public domain
	
	This shader detects large variations in luminance from frame to frame
	and then blends frames to smooth the transition. In flicker-based
	shadow effects, this should result in true transparency.
*/

#pragma parameter lum_diff_thresh "Flicker Luma Diff. Threshold" 0.5 0.0 1.0 0.05

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
COMPAT_ATTRIBUTE vec4 TexCoord;
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
uniform sampler2D PrevTexture;
uniform sampler2D Prev1Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float lum_diff_thresh;
#else
#define lum_diff_thresh 0.5
#endif

vec3 RGBtoYIQ(vec3 RGB)
  {
     const mat3 m = mat3(
     0.2989, 0.5870, 0.1140,
     0.5959, -0.2744, -0.3216,
     0.2115, -0.5229, 0.3114);
     return RGB * m;
  }

vec3 YIQtoRGB(vec3 YIQ)
  {
     const mat3 m = mat3(
     1.0, 0.956, 0.6210,
     1.0, -0.2720, -0.6474,
     1.0, -1.1060, 1.7046);
   return YIQ * m;
  }

void main()
{
    vec3 curr = RGBtoYIQ(COMPAT_TEXTURE(Source, vTexCoord).rgb);
    vec3 prev0 = RGBtoYIQ(COMPAT_TEXTURE(PrevTexture, vTexCoord).rgb);
    vec3 prev1 = RGBtoYIQ(COMPAT_TEXTURE(Prev1Texture, vTexCoord).rgb);

    if((abs(curr.r - prev0.r) > lum_diff_thresh) && (abs(curr.r - prev1.r) < 1.0 - lum_diff_thresh))
      FragColor.rgb = (prev0 + curr) / 2.;
    else
      FragColor.rgb = curr;
    FragColor.rgb = YIQtoRGB(FragColor.rgb);
    FragColor.a = 1.0;
} 
#endif
