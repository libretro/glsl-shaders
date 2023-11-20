#version 110

#pragma parameter bogus1 " [ COLORS ] " 0.0 0.0 0.0 0.0
#pragma parameter a_gamma_in "Gamma In" 2.45 1.0 4.0 0.05
#pragma parameter a_gamma_out "Gamma Out" 2.25 1.0 4.0 0.05
#pragma parameter a_col_temp "Color Temperature (0.01 ~ 200K)" 0.0 -0.15 0.15 0.01
#pragma parameter a_sat "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter a_boostd "Bright Boost Dark" 1.3 0.0 2.0 0.05
#pragma parameter a_boostb "Bright Boost Bright" 1.05 0.0 2.0 0.05
#pragma parameter bogus2 " [ SCANLINES/MASK ] " 0.0 0.0 0.0 0.0
#pragma parameter scanl "Scanlines Low" 0.4 0.0 0.5 0.05
#pragma parameter scanh "Scanlines High" 0.2 0.0 0.5 0.05
#pragma parameter a_interlace "Interlace On/Off" 1.0 0.0 1.0 1.0
#pragma parameter a_MTYPE "Mask Type, Fine/Coarse/LCD" 0.0 0.0 2.0 1.0
#pragma parameter a_MSIZE "Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter a_MASK "Mask Strength" 0.2 0.0 0.5 0.05
#pragma parameter bogus3 " [ GEOMETRY ] " 0.0 0.0 0.0 0.0
#pragma parameter a_sharper "Sharp Image" 0.0 0.0 1.0 1.0
#pragma parameter a_lanc "Lanczos Fake Artifacts" 1.0 0.0 1.0 1.0
#pragma parameter warpx "Curvature Horizontal" 0.03 0.0 0.2 0.01
#pragma parameter warpy "Curvature Vertical" 0.04 0.0 0.2 0.01
#pragma parameter a_corner "Corner Roundness" 0.03 0.0 0.2 0.01
#pragma parameter bsmooth "Border Smoothness" 600.0 100.0 1000.0 25.0
#pragma parameter a_vignette "Vignette On/Off" 1.0 0.0 1.0 1.0
#pragma parameter a_vigstr "Vignette Strength" 0.4 0.0 1.0 0.05

#define SourceSize vec4(TextureSize.xy, 1.0/TextureSize.xy)
#define scale vec2(SourceSize.xy/InputSize.xy)
#define pi 3.1415926

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
COMPAT_VARYING vec2 ps;
COMPAT_VARYING float maskpos;

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
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float a_MSIZE;

#else
#define a_MSIZE 1.0

#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    ps = 1.0/TextureSize.xy;
    maskpos = vTexCoord.x*OutputSize.x/a_MSIZE*scale.x*pi;
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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 ps;
COMPAT_VARYING float maskpos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float warpx;
uniform COMPAT_PRECISION float warpy;
uniform COMPAT_PRECISION float a_vignette;
uniform COMPAT_PRECISION float a_vigstr;
uniform COMPAT_PRECISION float a_gamma_in;
uniform COMPAT_PRECISION float a_gamma_out;
uniform COMPAT_PRECISION float a_col_temp;
uniform COMPAT_PRECISION float a_sat;
uniform COMPAT_PRECISION float a_boostd;
uniform COMPAT_PRECISION float a_boostb;
uniform COMPAT_PRECISION float a_interlace;
uniform COMPAT_PRECISION float scanl;
uniform COMPAT_PRECISION float scanh;
uniform COMPAT_PRECISION float a_MASK;
uniform COMPAT_PRECISION float a_MTYPE;
uniform COMPAT_PRECISION float a_corner;
uniform COMPAT_PRECISION float bsmooth;
uniform COMPAT_PRECISION float a_sharper;
uniform COMPAT_PRECISION float a_lanc;
#else

#define warpx 0.0
#define warpy 0.0
#define a_vignette 0.0
#define a_vigstr 0.0
#define a_gamma_in 2.4
#define a_gamma_out 2.2
#define a_col_temp 0.0
#define a_sat 1.0
#define a_boostd 1.0
#define a_boostb 1.0
#define a_interlace 1.0
#define scanl 0.4
#define scanh 0.25
#define a_MASK 0.15
#define a_MTYPE 1.0
#define a_corner 0.03
#define bsmooth 600.0
#define a_sharper 1.0
#define a_lanc 1.0
#endif

vec2 Warp(vec2 pos)
{
    pos = pos*2.0-1.0;
    pos *= vec2(1.0+pos.y*pos.y*warpx, 1.0+pos.x*pos.x*warpy);
    pos = pos*0.5+0.5;
    return pos;
}

float corner(vec2 coord)
{
                coord = min(coord, vec2(1.0)-coord);
                vec2 cdist = vec2(a_corner);
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*bsmooth,0.0, 1.0);
}  

void main()
{
vec2 pos = Warp(vTexCoord*scale);
vec2 cpos = pos;
pos /= scale;

// filter
vec2 ogl2pos = pos*SourceSize.xy;
vec2 xy = floor(ogl2pos)+0.5;
vec2 near = xy*ps;
vec2 d = ogl2pos-xy;
d = d*d*d*4.0*ps;
d = near+d;

// blurrier option
if (a_sharper == 0.0) d = vec2(pos.x,d.y);

vec3 res = COMPAT_TEXTURE(Source,d).rgb;

// fake Lanczos artifacts
vec3 resl = COMPAT_TEXTURE(Source,d + vec2(ps.x,0.0)).rgb;
vec3 resr = COMPAT_TEXTURE(Source,d - vec2(ps.x,0.0)).rgb;
vec3 lanc = resl*0.5+resr*0.5;
lanc *= lanc;

float w = dot(vec3(0.33),res);

if (a_sharper == 0.0 && a_lanc == 1.0) {res -= 0.2*lanc; res *= 1.15; res = clamp(res,0.0,1.0); } 
// color temp approximate
res *= vec3(1.0+a_col_temp,1.0-a_col_temp*0.2,1.0-a_col_temp);

float scan = mix(scanl,scanh,w);

res = pow(res, vec3(a_gamma_in));

float vig = 0.0;
if (a_vignette == 1.0){
vig = cpos.x-0.5;
vig = vig*vig*a_vigstr;
}
// Interlace handling
if (InputSize.y>400.0) {ogl2pos /= 2.0;
if (mod(float(FrameCount),2.0) > 0.0 && a_interlace == 1.0) ogl2pos += 0.5;
}

res *= (scan+vig)*sin((ogl2pos.y-0.25)*2.0*pi)+(1.0-scan-vig);
// masks
float sz = 1.0;
float m_m = maskpos;
if (a_MTYPE == 1.0) sz = 0.6666;
if (a_MTYPE == 2.0) m_m = ogl2pos.x*2.0*pi;
res *= a_MASK*sin(m_m*sz)+1.0-a_MASK;

res = pow(res,vec3(1.0/a_gamma_out));

float l = dot(res,vec3(0.3,0.6,0.1));
res = mix(vec3(l),res,a_sat);

res *= mix(a_boostd,a_boostb,l);

if (a_corner >0.0) res *= corner(cpos);
FragColor.rgb = res;
}
#endif
