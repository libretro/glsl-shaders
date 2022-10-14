// version directive if necessary

// blendSoftlight
// based on:
// https://github.com/jamieowen/glsl-blend for blendSoftlight

#pragma parameter OverlayMix "Overlay Mix" 1.0 0.0 1.0 0.05
#pragma parameter SCALE "Box Scale" 0.6667 0.6667 1.5 0.33333
#pragma parameter OUT_X "Out X" 1600.0 1600.0 4800.0 8000.0
#pragma parameter OUT_Y "Out Y" 800.0 800.0 2400.0 400.0

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
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SCALE;
uniform COMPAT_PRECISION float OUT_X;
uniform COMPAT_PRECISION float OUT_Y;
#else
#define SCALE 0.66667
#define OUT_X 1600.0
#define OUT_Y 800.0
#endif

void main()
{
    gl_Position =   MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    
    // vec2 scale  =   (OutputSize.xy / InputSize.xy) / SCALE;
    // vec2 middle =   vec2(0.5, 0.5) * InputSize.xy / TextureSize.xy;
    // vec2 diff   =   TexCoord.xy - middle;
    // TEX0.xy     =   middle + diff * scale;
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
uniform sampler2D overlay;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float OverlayMix;
#else
#define OverlayMix 1.0
#endif

float blendSoftlight(float base, float blend) {
    return (blend<0.5)?(2.0*base*blend+base*base*(1.0-2.0*blend)):(sqrt(base)*(2.0*blend-1.0)+2.0*base*(1.0-blend));
}

void main()
{

    vec4 frame  =   COMPAT_TEXTURE(Source, vTexCoord).rgba;
    vec4 softlight =   COMPAT_TEXTURE(overlay, vTexCoord).rgba;

    vec4 ImageFinal  = frame;

    ImageFinal.r = blendSoftlight(frame.r,softlight.r);
    ImageFinal.g = blendSoftlight(frame.g,softlight.g);
    ImageFinal.b = blendSoftlight(frame.b,softlight.b);
    ImageFinal.a = blendSoftlight(frame.a,softlight.a);
    ImageFinal   = mix(frame,clamp(ImageFinal,0.0,OverlayMix),softlight.a);
    
    FragColor = vec4(ImageFinal);
} 
#endif
