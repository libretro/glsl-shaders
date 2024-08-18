#version 110

#pragma parameter freq_cut "Filter Frequencies" 0.08 0.03 0.35 0.01 
#pragma parameter n_sat "Saturation" 1.8 0.0 3.0 0.05
#pragma parameter d_crawl "Dot Crawl (SNES:on)" 0.0 0.0 1.0 1.0
#pragma parameter line_dl "SNES Line Delay" 0.0 0.0 1.0 1.0
#pragma parameter pal "PAL on/off" 0.0 0.0 1.0 1.0

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
uniform COMPAT_PRECISION float freq_cut;
uniform COMPAT_PRECISION float n_sat;
uniform COMPAT_PRECISION float d_crawl;
uniform COMPAT_PRECISION float line_dl;
uniform COMPAT_PRECISION float pal;

#else
#define freq_cut 1.0
#define n_sat 1.0
#define d_crawl 1.0
#define line_dl 1.0
#define pal 0.0
#endif

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693

const mat3 yiq_to_rgb = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);

void main()
{  
    float altv = 0.0;
    if (pal == 1.0) altv = mod(floor(vTexCoord.y * 312.0 + 0.5), 2.0) * PI;

    vec3 yiq = vec3(0.0);
    float counter = 0.0;
    for (int d = -8; d < 8; d++) 
    {
        float n = float(d);
        float w = exp(-freq_cut*n*n);
        vec2 pos = vec2(vTexCoord.x + n/TextureSize.x*0.5, vTexCoord.y);
        vec3 s = COMPAT_TEXTURE(Source, pos).rgb;
        float crawl = 0.0;
        if (d_crawl == 1.0) crawl = mod(float(FrameCount),2.0) * PI;
        float delay = 0.0;
        if (line_dl == 1.0) delay = vTexCoord.y*TextureSize.y*2.0;
        float t = vTexCoord.x*TextureSize.x*2.0 + n - delay + crawl;
        // compensate for Q small bandwidth
        yiq += w * s * vec3(1.0, n_sat*cos(t), 2.0*n_sat*sin(t+altv));

        counter += w;
    }

    yiq /= counter;
    
    FragColor.rgb = yiq*yiq_to_rgb;
}
#endif
