#version 110

#pragma parameter hue " Hue" -0.35 -6.5 6.5 0.05
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
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING float invdims;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    ogl2pos = TEX0.xy*TextureSize.xy;
    invdims = 1.0/TextureSize.y;
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
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING float invdims;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float hue;
uniform COMPAT_PRECISION float rf_signal;
uniform COMPAT_PRECISION float line_dl;

#else
#define hue 1.0
#define rf_signal 1.0
#define line_dl 0.0
#endif

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693

const mat3 RGBYUV =  mat3(0.299, 0.587, 0.114,
                        -0.299, -0.587, 0.886, 
                         0.701, -0.587, -0.114);
void main()
{
    float crawl = 0.0;
    if (rf_signal == 1.0) crawl = mod(float(FrameCount),2.0) * PI;
    float delay = 0.0;
    if (line_dl == 1.0) delay = vTexCoord.y*TextureSize.y*2.0;
    float f = vTexCoord.x*TextureSize.x*2.0 + hue - delay + crawl;
    vec2 carrier = vec2(cos(f), sin(f));
    vec3 res = COMPAT_TEXTURE(Source,vTexCoord).rgb*RGBYUV;
    res.gb *= carrier;
    float signal = dot(vec3(1.0),res);
    FragColor.rgb = vec3(signal);
}
#endif
