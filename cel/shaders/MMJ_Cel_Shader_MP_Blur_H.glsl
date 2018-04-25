/*
----------------------------------------------------------------
MMJ's Cel Shader v2.01 - Multi-Pass 
----------------------------------------------------------------
Based on the original blur-gauss-h shader code.

Used to blur the outlines, which is helpful at higher internal
resolution settings to increase the line thickness.

Parameters:
-----------
Blur Weight - Horizontal = Adjusts horizontal blur factor.
----------------------------------------------------------------
*/

#pragma parameter BlurWeightH "Blur Weight - Horizontal" 0.0 0.0 16.0 1.0


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
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	gl_Position = MVPMatrix * VertexCoord;
	TEX0 = TexCoord;
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

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BlurWeightH;
#else
#define BlurWeightH 0.0
#endif

void main()
{
	vec2 PIXEL_SIZE = SourceSize.zw;
  vec4 C = COMPAT_TEXTURE(Source, vTexCoord);
  float L = 0.0, J = 0.0;
  for(int i = 1; i <= int(BlurWeightH); ++i) {
    L = 1.0 / i;
    J = 0.5 * i * PIXEL_SIZE.x;
    C = mix(C, mix(COMPAT_TEXTURE(Source, vTexCoord + vec2(J, 0.0)), COMPAT_TEXTURE(Source, vTexCoord - vec2(J, 0.0)), 0.5), L);
  }
  FragColor = C;
}
#endif