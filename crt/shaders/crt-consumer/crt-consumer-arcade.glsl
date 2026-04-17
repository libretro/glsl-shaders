#version 110

/*
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
    
*/

#pragma parameter dummy0 "   === GEOMETRY === " 0.0 0.0 0.0 0.0
#pragma parameter U_CURVE "Curvature" 1.4 0.0 30.0 0.1
#pragma parameter ZOOM_XY "Geometry: Overscan" 0.0 0.0 10.0 0.1  
#pragma parameter A_CORNER "Corner Roundness" 0.03 0.0 0.2 0.01
#pragma parameter B_SMOOTH "Border Smoothness" 250.0 100.0 1000.0 25.0
#pragma parameter U_VIGN "Vignette Attenuation" 0.6 0.0 2.0 0.05

#pragma parameter dummy1 "  === SCANLINES/MASK === " 0.0 0.0 0.0 0.0
#pragma parameter SCANLOW "Scanlines Strength Low" 0.45 0.0 0.5 0.05
#pragma parameter SCANHIGH "Scanlines Strength High" 0.2 0.0 0.5 0.05
#pragma parameter U_INTERL "Interlace On/Off" 1.0 0.0 1.0 1.0
#pragma parameter U_SHIMMER "Shimmering fix" 0.0 0.0 1.0 1.0
#pragma parameter M_SIZE "Mask Fine/Coarse" 2.0 2.0 3.0 1.0
#pragma parameter U_MASK "Mask Strength" 0.25 0.0 0.5 0.05
#pragma parameter U_SLOT "Slot Mask Enable" 1.0 0.0 1.0 1.0

#pragma parameter dummy2 "  === COLOR CONTROLS === " 0.0 0.0 0.0 0.0
#pragma parameter U_GLOW "Glow Strength" 0.12 0.0 1.0 0.01
#pragma parameter BOOSTD "Boost Dark Colors" 2.0 1.0 3.0 0.05
#pragma parameter BOOSTB "Boost Bright Colors" 1.0 1.0 2.0 0.05
#pragma parameter U_CRT "CRT Colors" 1.0 0.0 1.0 1.0

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
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float aspect;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float M_SIZE;

#else
#define M_SIZE 2.0

#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    invdims = 1.0/TextureSize;
    scale = TextureSize/InputSize;
    maskpos = TEX0.xy*scale*OutputSize.xy;
    ogl2pos = TEX0.xy*TextureSize;    
    aspect = TextureSize.x / TextureSize.y;
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


uniform sampler2D Texture;
uniform sampler2D PassPrev4Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float aspect;

#define Source Texture
#define vTexCoord TEX0.xy

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ZOOM_XY;
uniform COMPAT_PRECISION float U_MASK;
uniform COMPAT_PRECISION float A_CORNER;
uniform COMPAT_PRECISION float B_SMOOTH;
uniform COMPAT_PRECISION float SCANLOW;
uniform COMPAT_PRECISION float SCANHIGH;
uniform COMPAT_PRECISION float BOOSTD;
uniform COMPAT_PRECISION float BOOSTB;
uniform COMPAT_PRECISION float U_SLOT;
uniform COMPAT_PRECISION float M_SIZE;
uniform COMPAT_PRECISION float U_VIGN;
uniform COMPAT_PRECISION float U_CRT;
uniform COMPAT_PRECISION float U_GLOW;
uniform COMPAT_PRECISION float U_CURVE;
uniform COMPAT_PRECISION float U_INTERL;
uniform COMPAT_PRECISION float U_SHIMMER;
#else
#define ZOOM_XY 1.0
#define U_MASK 0.3
#define A_CORNER 0.0
#define B_SMOOTH 100.0
#define SCANLOW 0.5
#define SCANHIGH 0.25
#define BOOSTD 1.45
#define BOOSTB 1.05
#define U_SLOT 1.0
#define M_SIZE 2.0
#define U_VIGN 0.8
#define U_CRT 1.0
#define U_INTERL 1.0
#define U_GLOW 0.1
#define U_CURVE 0.1
#endif

#define grayweights vec3(0.3,0.59,0.11)
#define GAMMAIN(color) color*color 
#define PI 3.14159265358979323846 
#define TAU 6.2831852

mat3 crt = mat3(
 1.0,   0.05,  0.0,
-0.05,  1.0, -0.05,
 0.0,   0.05, 1.0
);

vec2 c_warp(vec2 uv)
{
    vec2 p = uv*2.0 - 1.0;

    p.x *= aspect;

    float r2 = dot(p, p);
    float k = 0.02;

    vec2 warped = vec2(p.x*(1.0 + k*r2 + k*0.5*r2*r2),p.y*(1.0 + 2.0*k*r2 + k*r2*r2));

    float zoom = 1.0 + k*1.5;
    warped /= vec2(zoom, zoom*1.03);

    warped.x /= aspect;

    return warped * 0.5 + 0.5;
} 

vec2 warp(vec2 uv)
{
    vec2 p = uv * 2.0 - 1.0;

    p.x *= aspect;

    float r2 = dot(p, p);
    float k = U_CURVE*0.01;

    vec2 warped = vec2(p.x*(1.0 + k*r2 + k*0.5*r2*r2),p.y*(1.0 + 2.0*k*r2 + k*r2*r2));

    float zoom = 1.0 + k*ZOOM_XY;
    warped /= vec2(zoom, zoom*1.03);

    warped.x /= aspect;

    return warped * 0.5 + 0.5;
}

float corner(vec2 coord)
{
                coord = min(coord, vec2(1.0)-coord);
                vec2 cdist = vec2(A_CORNER);
                coord = (cdist - min(coord, cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*B_SMOOTH, 0.0, 1.0);
}  
void main()
{
// --- warped UV ---
vec2 uv = warp(vTexCoord*scale);
// fixed crt "bezel"
vec2 corner_uv = c_warp(vTexCoord*scale);
    uv /= scale;
// --- pixel space ---
vec2 pp = uv * TextureSize;
if (InputSize.y > 300.0 && U_INTERL==1.0) pp.y += mod(float(FrameCount),2.0);
vec2 near = floor(pp) + 0.5;
vec2 f = fract(pp);
// smoothstep interpolation
    f = f*f*(3.0 - 2.0*f);
// max sharpness Y    
    f.y = f.y*f.y;
    f.y = f.y*f.y;
vec2 pos = (near + f) / TextureSize;
vec3 res = COMPAT_TEXTURE(PassPrev4Texture, pos).rgb;
     res += U_GLOW*grayweights*COMPAT_TEXTURE(Source, pos).rgb;

// crt like colors    
    if (U_CRT == 1.0) res *= crt;
float l = max(max(res.r, res.g), res.b);
res *= mix(BOOSTD,BOOSTB,l);
// FIXED SCANLINES
float scanpos = pp.y;    
float f1 = fract(scanpos*(InputSize.y > 300.0? 0.5 : 1.0) - (InputSize.y>300.0? U_INTERL*mod(float(FrameCount),2.0)*1.0:0.5)) - 0.5;
// vain attempt to fix some scanline shimmering near the screen edges
float dy = U_SHIMMER==0.0? 0.0 : distance(pos*scale,vec2(0.5));

float beam = mix(SCANLOW, SCANHIGH, l);

float s1 = beam*sin(f1 * TAU) + 1.0-beam;
float mask_ef = mix(U_MASK, U_MASK*0.6, l);
float m1 = mask_ef*sin(maskpos.x*2.0/M_SIZE*PI)+1.0-mask_ef;
float sl1 = U_SLOT == 1.0 ? 0.5*sin((maskpos.x/M_SIZE + maskpos.y)*PI) : 0.0;

// anti-alias scanlines anti-shimmer
    s1 = mix(s1, 1.0, dy);
    sl1 = mix(sl1, 0.0, dy);
   
    res *= m1;
// will add -0.5 to position 1 and +0.5 to position 2, just like crt-lottes    
    res += res*sl1;

// mild CRT gamma feel
    res = sqrt(res); res *= s1;

// vignette
    float dist = distance(corner_uv.x, 0.5);
    dist = dot(dist,dist)*U_VIGN;
    res *= mix(0.0, 1.0, 1.0-dist);
#if defined GL_ES
    // hacky clamp fix for GLES
    vec2 bordertest = (pos);
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec3(0.0);
#endif

// apply "bezel"       
    if(A_CORNER>0.0) res = res*corner(corner_uv);
    FragColor = vec4(res, 1.0);
}
#endif