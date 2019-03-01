
///////////////
//	TV-out tweaks Linearized Multipass - Pass0
//	Author: aliaspider and RiskyJumps
//	License: GPLv3
////////////////////////////////////////////////////////


// this shader is meant to be used when running
// an emulator on a real CRT-TV @240p or @480i
////////////////////////////////////////////////////////

// simulate a composite connection instead of RGB
#pragma parameter TVOUT_COMPOSITE_CONNECTION "TVOut Composite Enable" 0.0 0.0 1.0 1.0

// use TV video color range (16-235)
// instead of PC full range (0-255)
#pragma parameter TVOUT_TV_COLOR_LEVELS "TVOut TV Color Levels Enable" 0.0 0.0 1.0 1.0

// gamma correction
#pragma parameter CRT_GAMMA "Gamma Adjustment" 2.2 0.1 5.0 0.1

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
COMPAT_VARYING vec4 TEX0;

#ifdef PARAMETER_UNIFORM // If the shader implementation understands #pragma parameters, this is defined.
uniform COMPAT_PRECISION float TVOUT_COMPOSITE_CONNECTION, TVOUT_TV_COLOR_LEVELS, CRT_GAMMA;
#else
// Fallbacks if parameters are not supported.
#define TVOUT_COMPOSITE_CONNECTION 0
#define TVOUT_TV_COLOR_LEVELS 0
#define CRT_GAMMA 2.2
#endif

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#define L(C) clamp((C -16.5/ 256.0)*256.0/(236.0-16.0),0.0,1.0)
#define LCHR(C) clamp((C -16.5/ 256.0)*256.0/(240.0-16.0),0.0,1.0)

vec3 LEVELS(vec3 c0)
{
   if (TVOUT_TV_COLOR_LEVELS > 0.5)
   {
      if (TVOUT_COMPOSITE_CONNECTION > 0.5)
         return vec3(L(c0.x),LCHR(c0.y),LCHR(c0.z));
      else
         return L(c0);
   }
   else
      return c0;
}

void main()
{
   FragColor = vec4(pow(LEVELS(COMPAT_TEXTURE(Source, vTexCoord).rgb), vec3(CRT_GAMMA)), 1.0);
}
#endif
