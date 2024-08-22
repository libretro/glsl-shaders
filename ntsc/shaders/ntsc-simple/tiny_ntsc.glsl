#version 110

#pragma parameter comb "Comb Filter Strength" 0.8 0.0 1.0 0.05
#pragma parameter ln_delay "NES/SNES Line Delay" 1.0 0.0 1.0 1.0
#pragma parameter d_crawl "NES/SNES Dot Crawl" 1.0 0.0 1.0 1.0
#pragma parameter sharp_pix "Sharper" 0.0 0.0 1.0 1.0

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
    ogl2pos = TEX0.xy*TextureSize.xy;
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

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float comb;
uniform COMPAT_PRECISION float ln_delay;
uniform COMPAT_PRECISION float sharp_pix;
uniform COMPAT_PRECISION float d_crawl;
#else
#define comb 0.6
#define ln_delay 1.0
#define sharp_pix 0.0
#define d_crawl 1.0
#endif

#define PI   3.14159265358979323846

mat3 RGBYUV = mat3(0.299, 0.587, 0.114,
                        -0.299, -0.587, 0.886, 
                         0.701, -0.587, -0.114);

mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);

// max 170.666 color "dots" per line
#define NTSC_RES 170.6666

void main() 
{
float pixsize = 0.75; 
if (sharp_pix == 1.0) pixsize = 0.5;
vec2 dxy = vec2(SourceSize.z*pixsize,0.0);
vec2 dy = vec2(0.0,SourceSize.w*0.125);
vec3 final = vec3(0.0);
float sum = 0.0;
float timer = 0.0; if (d_crawl == 1.0) timer = mod(float(FrameCount),3.0);

for (int i=0; i<2; i++)
{
float n = float(i);
float w = exp(-0.15*n*n); // gaussian low pass

float line_delay = 0.0;
if (ln_delay == 1.0) line_delay = ogl2pos.y; // snes line delay
//snes line delay deployed at 170/256, 2/3 of pi(180'), 120' or 1/3 lines as in real snes
float phase = (ogl2pos.x + n - line_delay +timer)*PI*NTSC_RES/InputSize.x;
// comb filter line
float phaseup = phase + PI;

vec3 res   = COMPAT_TEXTURE(Source,vTexCoord -dxy + dxy*n).rgb*RGBYUV;
vec3 resup = COMPAT_TEXTURE(Source,vTexCoord -dxy + dxy*n +dy).rgb*RGBYUV;

vec3 carrier   = vec3(1.0, sin(phase  ), cos(phase));
vec3 carrierup = vec3(1.0, sin(phaseup), cos(phaseup));

res    *= carrier;
resup  *= carrierup;

float line   = dot(vec3(0.5),res);
float lineup = dot(vec3(0.5),resup);
// comb luma is line adding previous line, chroma is cancelled!
float luma   = line + lineup;
// comb chroma is line subtracting luma we already have!
float chroma = line - luma*0.5*comb;
final.r += luma*w;
final.gb += 2.0*vec2(chroma)*carrier.yz*w;
sum += w;
}

final.rgb /= sum;
FragColor.rgb = final*YUV2RGB;
}
#endif
