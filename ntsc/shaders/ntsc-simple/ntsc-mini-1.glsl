#version 110

#pragma parameter ph_mode "Phase: 1:ZX,2:MD,3:NES/SNES,4:Artifacts" 2.0 0.0 4.0 1.0
#pragma parameter mini_sharp "Resolution" 1.0 0.1 4.0 0.1
#pragma parameter Fl "Freq. Cutoff" 0.2 0.01 1.0 0.01
#pragma parameter lpass "Chroma Low Pass" 0.05 0.0 1.0 0.01
#pragma parameter d_crawl "Dot Crawl" 0.3 0.0 1.0 0.05
#pragma parameter mini_hue1 "Hue Shift I" 0.1 -6.0 6.0 0.05
#pragma parameter mini_hue2 "Hue Shift Q" -0.1 -6.0 6.0 0.05
#pragma parameter mini_sat "Saturation" 2.0 0.0 4.0 0.05

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
uniform COMPAT_PRECISION float ph_mode;
uniform COMPAT_PRECISION float Fl;
uniform COMPAT_PRECISION float lpass;
uniform COMPAT_PRECISION float d_crawl;
uniform COMPAT_PRECISION float mini_hue;
uniform COMPAT_PRECISION float mini_sat;
uniform COMPAT_PRECISION float mini_sharp;

#else
#define ph_mode 90.0
#define Fl 90.0
#define lpass 0.2
#define d_crawl 0.0
#define mini_hue 0.0
#define mini_sat 0.0
#define mini_sharp 1.0
#endif

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693
#define s 1.0
#define onedeg 0.017453

const mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);

float kaizer (float N, float p)
{
    // Compute sinc filter.
    float k = sin(2.0 * Fl / s * (N - (p - 1.0) / 2.0));
    return k;
}

void main() {

vec3 yuv = vec3(0.0);
vec2 ps = vec2(SourceSize.z,0.0);
float sum = 0.0; float sumc = 0.0;


// luma
for (int i=0; i<4; i++)
{
float p = float (i);
vec2 pos = vTexCoord + ps*p/mini_sharp -ps;
// Window
float w = kaizer(4.0,p);
yuv.r += COMPAT_TEXTURE(Source,pos).r*w;
sum += w;
}
yuv.r /= sum;

vec3 line = vec3(0.0);

//chroma
for (int i=-4; i<4; i++)
{
float p = float (i);
// Low-pass 
float w = exp(-lpass*p*p);

float h_ph, v_ph, mod0 = 0.0;
if      (ph_mode == 0.0) {h_ph =  90.0*onedeg; v_ph = PI*0.6667; mod0 = 2.0;}
else if (ph_mode == 1.0) {h_ph = 110.0*onedeg; v_ph = PI;        mod0 = 2.0;}
else if (ph_mode == 2.0) {h_ph = 132.0*onedeg; v_ph = PI;        mod0 = 2.0;}
else if (ph_mode == 3.0) {h_ph =  96.0*onedeg; v_ph = PI*0.6667; mod0 = 3.0;}
else                     {h_ph =  90.0*onedeg; v_ph = PI;        mod0 = 1.0;}

float phase = floor(vTexCoord.x*SourceSize.x + p)*h_ph + mod(floor(vTexCoord.y*SourceSize.y),mod0)*v_ph;
phase += mini_hue;
phase += d_crawl *sin(mod(float(FrameCount/2),2.0))*PI;

vec2 qam = mini_sat*vec2(cos(phase),sin(phase));

line.gb = COMPAT_TEXTURE(Source,vTexCoord + ps*p).gb*qam*w;

yuv.gb += line.gb;
sumc += w;
}
yuv.gb /= sumc;

FragColor.rgb = yuv*YUV2RGB;
}
#endif 
