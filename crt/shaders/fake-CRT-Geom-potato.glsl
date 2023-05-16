// Simple scanlines and mask effect
// original by hunterk, edit by DariusG

///////////////////////  Runtime Parameters  ///////////////////////
#pragma parameter SCANLINE "Scanline Intensity" 0.30 0.0 1.0 0.05
#pragma parameter MSK "Mask Brightness" 0.7 0.0 1.0 0.05



#define pi 3.141592

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
COMPAT_VARYING float fragpos;

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
    TEX0.xy = TexCoord.xy*1.0001;
    fragpos=TEX0.x*OutputSize.x*TextureSize.x/InputSize.x;
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
COMPAT_VARYING float fragpos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SCANLINE_BASE_BRIGHTNESS;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float MSK;


#else
#define SCANLINE 0.30
#define MSK 0.70

#endif

// MSK mask calculation
     
      float Mask(float pos)
      {
      float mf = fract(pos * 0.5);

      if (mf < 0.5) return (MSK);
      else return (1.0);
  
      }

void main()
{
    float OGL2Pos = vTexCoord.y*SourceSize.y;
    float cent = floor(OGL2Pos)+0.5;
    float ycoord = cent*SourceSize.w; 

   vec3 res = texture2D(Source, vec2(vTexCoord.x, ycoord)).rgb;

     res *= SCANLINE*sin(fract(vTexCoord.y*SourceSize.y)*pi)+1.0-SCANLINE ; 

     res *= Mask(fragpos);

    FragColor = vec4(res,1.0);
} 
#endif
