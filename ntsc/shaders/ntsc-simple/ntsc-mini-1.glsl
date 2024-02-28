#version 110

/*
ntsc-mini, composite shader based on actual ZX Spectrum RF images
https://i.imgur.com/t51E3zt.jpeg
DariuG @2024
*/

#pragma parameter crawl "Dot Crawl (Genesis off)" 0.0 0.0 1.0 1.0
#pragma parameter Y_lp "Luma Low Pass (sharper)" 0.08 0.0 1.0 0.01
#pragma parameter pi_mod "Pi mod. 1 degree-step/adjust hue" 0.633319 0.5 1.0 0.005555
#pragma parameter dummy "Genesis 0.53" 0.0 0.0 0.0 0.0
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
uniform COMPAT_PRECISION float crawl;
uniform COMPAT_PRECISION float Y_lp;
uniform COMPAT_PRECISION float pi_mod;

#else
#define crawl 1.0
#define Y_lp 0.2
#define pi_mod 0.5
#endif

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693

const mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);


void main() 
{
vec2 dx = vec2(SourceSize.z,0.0);
vec2 dy = vec2(0.0,SourceSize.w*0.5);
vec3 res = vec3(0.0);
float sum = 0.0;
float sumc = 0.0;

// Comb-filter YC separation idea borrowed from ntsc-blastem
for (int x=0; x<4; x++)
    {
        float n = float(x);
        float w = exp(-Y_lp*n*n);
        // add a lowpass to Luma too  
        vec3 line = w*COMPAT_TEXTURE(Source,vTexCoord + n*dx).rgb;        
        vec3 lineup = w*COMPAT_TEXTURE(Source,vTexCoord -dy + n*dx).rgb;        
        sum += w;
        // Comb-filter separate, idea borrowed from blastem and tweaked to ntsc-mini 
        vec3 ymix = (line+lineup)*0.5;
        res.r += ymix.r;
    }
    res.r /= sum;
for (int a=0; a<7; a++)
    {
        float b = float(a);  
        float phase = (vTexCoord.x*SourceSize.x + b)*PI*pi_mod + mod(vTexCoord.y*SourceSize.y,2.0)*PI ;
        if (crawl == 1.0) phase += sin(mod(float(FrameCount),2.0))*PI;
        vec3 carr = vec3(1.0,2.0*cos(phase),2.0*sin(phase));
        float w = 1.0-exp(-0.4*b*b);  

        vec3 cline   = COMPAT_TEXTURE(Source,vTexCoord -dx*3.0 + b*dx).rgb*carr;        
        vec3 clineup = COMPAT_TEXTURE(Source,vTexCoord -dx*3.0 -dy + b*dx).rgb*carr;  
        // Comb-filter separate, idea borrowed from blastem and tweaked to ntsc-mini 
        vec3 iqmix = cline - (cline+clineup);
        res.gb += iqmix.gb/7.0;
    }
    FragColor.rgb = res*YUV2RGB;
}
#endif 
