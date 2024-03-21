#version 110

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
uniform COMPAT_PRECISION float d_crawl;
uniform COMPAT_PRECISION float mini_hue1;
uniform COMPAT_PRECISION float mini_hue2;

#else
#define ph_mode 0.0
#define d_crawl 0.0
#define mini_hue2 0.0
#define mini_hue1 0.0

#endif

#define onedeg 0.017453
#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693
const mat3 RGBYUV = mat3(0.299, 0.587, 0.114,
                        -0.299, -0.587, 0.886, 
                         0.701, -0.587, -0.114);
void main() {

vec3 res = vec3(0.0);

float h_ph, v_ph, mod0 = 0.0;

if      (ph_mode == 0.0) {h_ph =  90.0*onedeg; v_ph = PI*0.6667; mod0 = 2.0;}
else if (ph_mode == 1.0) {h_ph = 110.0*onedeg; v_ph = PI;        mod0 = 2.0;}
else if (ph_mode == 2.0) {h_ph = 132.0*onedeg; v_ph = PI;        mod0 = 2.0;}
else if (ph_mode == 3.0) {h_ph =  96.0*onedeg; v_ph = PI*0.6667; mod0 = 3.0;}
else                     {h_ph =  90.0*onedeg; v_ph = PI;        mod0 = 1.0;}

float phase = floor(vTexCoord.x*SourceSize.x)*h_ph + mod(floor(vTexCoord.y*SourceSize.y),mod0)*v_ph;
phase += d_crawl *sin(mod(float(FrameCount/2),2.0))*PI;

res = COMPAT_TEXTURE(Source,vTexCoord).rgb*RGBYUV;
res.gb *=0.5*vec2(cos(phase+mini_hue1),sin(phase+mini_hue2));

float signal = dot(vec3(1.0),res);

FragColor.rgb = vec3(signal);
}
#endif 
