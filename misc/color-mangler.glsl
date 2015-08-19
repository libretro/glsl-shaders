#pragma parameter display_gamma "Display Gamma" 2.2 0.0 10.0 0.1
#pragma parameter target_gamma "Target Gamma" 2.2 0.0 10.0 0.1
#pragma parameter sat "Saturation" 1.0 0.0 3.0 0.01
#pragma parameter lum "Luminance" 1.0 0.0 5.0 0.01
#pragma parameter cntrst "Contrast" 1.0 0.0 2.0 0.01
#pragma parameter r "Red" 1.0 0.0 2.0 0.01
#pragma parameter g "Green" 1.0 0.0 2.0 0.01
#pragma parameter b "Blue" 1.0 0.0 2.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter blr "Black-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter blg "Black-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter blb "Black-Blue Tint" 0.0 0.0 1.0 0.005
#ifdef PARAMETER_UNIFORM
uniform float display_gamma;
uniform float target_gamma;
uniform float sat;
uniform float lum;
uniform float cntrst;
uniform float blr;
uniform float blg;
uniform float blb;
uniform float r;
uniform float g;
uniform float b;
uniform float rg;
uniform float rb;
uniform float gr;
uniform float gb;
uniform float br;
uniform float bg;
#else
#define display_gamma 2.2
#define target_gamma 2.2
#define sat 1.0
#define lum 1.0
#define cntrst 1.0
#define blr 0.0
#define blg 0.0
#define blb 0.0
#define r 1.0
#define g 1.0
#define b 1.0
#define rg 0.0
#define rb 0.0
#define gr 0.0
#define gb 0.0
#define br 0.0
#define bg 0.0
#endif

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
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    vec4 _oColor;
    vec2 _otexCoord;
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    _oPosition1 = gl_Position;
    _oColor = COLOR;
    _otexCoord = TexCoord.xy;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
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

struct output_dummy {
    vec4 _color;
};

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
//standard texture sample looks like this: COMPAT_TEXTURE(Texture, TEX0.xy);

void main()
{
    output_dummy _OUT;

vec4 screen = pow(COMPAT_TEXTURE(Texture, TEX0.xy), vec4(target_gamma)).rgba; //sample image in linear colorspace
vec4 avglum = vec4(0.5);
screen = mix(screen, avglum, (1.0 - cntrst));

mat4 color = mat4(
r,  gr,  br, blr,
rg,   g,  bg, blg,
rb,  gb,   b, blb,
0.0, 0.0, 0.0, 1.0);
			  
mat4 adjust = mat4(
(1.0 - sat) * 0.3086 + sat, (1.0 - sat) * 0.6094, (1.0 - sat) * 0.0820, 0.0,
(1.0 - sat) * 0.3086, (1.0 - sat) * 0.6094 + sat, (1.0 - sat) * 0.0820, 0.0,
(1.0 - sat) * 0.3086, (1.0 - sat) * 0.6094, (1.0 - sat) * 0.0820 + sat, 0.0,
1.0, 1.0, 1.0, 1.0);

color *= adjust;
screen = clamp(screen * lum, 0.0, 1.0);
screen = screen * color;
screen = pow(screen, vec4(1.0 / display_gamma));

    _OUT._color = screen;
    FragColor = _OUT._color;
    return;
} 
#endif
