#version 110

#pragma parameter luma_cut "Luma Frequency Cut-Off" 0.15 0.01 1.0 0.01
#pragma parameter chroma_cut "Chroma Frequency Cut-Off" 0.1 0.0 1.0 0.01
#pragma parameter d_cr "Dot Crawl (snes,nes,pce)" 0.0 0.0 1.0 1.0
#pragma parameter sim_ntsc "Saturation" 1.5 0.0 2.0 0.05

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
    TEX0.xy = TexCoord.xy*1.0001;
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
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float luma_cut;
uniform COMPAT_PRECISION float chroma_cut;
uniform COMPAT_PRECISION float d_cr;
uniform COMPAT_PRECISION float sim_ntsc;
#else
#define luma_cut 0.0
#define chroma_cut 0.0
#define d_cr 0.0
#define sim_ntsc 0.0
#endif



#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693

const mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);


float kaizer (float N, float p)
{
    // Compute sinc filter.
    float k = sin(2.0 * luma_cut  * (N - (p - 1.0) / 2.0));
    return k;
}

void main() {
vec2 ps = vec2(SourceSize.z,0.0);
vec3 res = vec3(0.0);
float sum = 0.0;
float sumc = 0.0;
float phase = 0.0;

vec2 carrier;
for (int i=-8; i<8; i++)
{
float n = float(i);
float w = kaizer(4.0,n);
float cw = exp(-chroma_cut*n*n);

float iTimer = 0.0 ;
if (d_cr == 1.0) iTimer = mod(float(FrameCount/2),2.0);

phase = ((vTexCoord.x*SourceSize.x + n))*PI*0.5 +  mod(vTexCoord.y*InputSize.y*4.0+iTimer,2.0)*PI;
carrier = vec2(sim_ntsc*cos(phase),sim_ntsc*sin(phase));

res.r += COMPAT_TEXTURE(Source,vTexCoord + n*ps*0.5).r*w;
res.gb += COMPAT_TEXTURE(Source,vTexCoord + n*ps).gb*carrier*cw;
sum += w;
sumc += cw;
}
res.r /= sum;
res.gb /= sumc;
FragColor.rgb = res*YUV2RGB;
}
#endif
