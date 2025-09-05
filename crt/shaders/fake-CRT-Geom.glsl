#version 110

/*
   A shader by DariusG 2023-24-25
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter bogus1 " [ COLORS ] " 0.0 0.0 0.0 0.0
#pragma parameter a_col_temp "Color Temperature (0.01 ~ 200K)" 0.0 -0.15 0.15 0.01
#pragma parameter a_sat "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter a_boostd "Bright Boost Dark" 1.45 1.0 2.0 0.05
#pragma parameter a_boostb "Bright Boost Bright" 1.05 1.0 2.0 0.05
#pragma parameter bogus2 " [ SCANLINES/MASK ] " 0.0 0.0 0.0 0.0
#pragma parameter scanl "Scanlines Low" 0.5 0.0 0.5 0.05
#pragma parameter scanh "Scanlines High" 0.4 0.0 0.5 0.05
#pragma parameter a_interlace "Interlace On/Off" 1.0 0.0 1.0 1.0
#pragma parameter a_MTYPE "Mask Type, Fine/Coarse/LCD" 0.0 0.0 2.0 1.0
#pragma parameter a_MSIZE "Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter a_MASK "Mask Strength" 0.15 0.0 0.5 0.05
#pragma parameter bogus3 " [ GEOMETRY ] " 0.0 0.0 0.0 0.0
#pragma parameter warpx "Curvature Horizontal" 0.03 0.0 0.2 0.01
#pragma parameter warpy "Curvature Vertical" 0.04 0.0 0.2 0.01
#pragma parameter a_corner "Corner Roundness" 0.03 0.0 0.2 0.01
#pragma parameter bsmooth "Border Smoothness" 250.0 100.0 1000.0 25.0
#pragma parameter a_vignette "Vignette On/Off" 1.0 0.0 1.0 1.0
#pragma parameter a_vigstr "Vignette Strength" 0.3 0.0 1.0 0.05

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
#else

#define warpx 0.0
#define warpy 0.0
#define a_vignette 0.0
#define a_vigstr 0.0
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
#endif

#define TEX2D(c) COMPAT_TEXTURE(Texture,(c))
#define FIX(c) max(abs(c), 1e-5)

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
// use "Quilez" sharper scaling for Y axis
    COMPAT_PRECISION float y = ogl2pos.y;
    COMPAT_PRECISION float i = floor(y) + 0.50;
    COMPAT_PRECISION float f = y - i;
    y = (i + 16.0*f*f*f*f*f)*ps.y;
  vec2 ratio_scale = ogl2pos - vec2(0.5); ;
  vec2 uv_ratio = fract(ratio_scale);
  vec2 xy = (floor(ratio_scale) + vec2(0.5))*ps;
  xy.y = y;
  // Horizontal Lanczos2 coeffs (4 taps)
  vec4 coeffs = pi * vec4(1.0 + uv_ratio.x, uv_ratio.x, 1.0 - uv_ratio.x, 2.0 - uv_ratio.x);
  coeffs = FIX(coeffs);
  coeffs = 2.0 * sin(coeffs) * sin(coeffs*0.5) / (coeffs*coeffs);
  coeffs /= dot(coeffs, vec4(1.0));

  // Fetch 4 samples from current and next scanline
  vec4 c0 = TEX2D(xy + vec2(-ps.x, 0.0));
  vec4 c1 = TEX2D(xy + vec2( 0.0 , 0.0));
  vec4 c2 = TEX2D(xy + vec2( ps.x, 0.0));
  vec4 c3 = TEX2D(xy + vec2( 2.0*ps.x, 0.0));
  vec4 res  = clamp(mat4(c0,c1,c2,c3) * coeffs, 0.0, 1.0);

float w = dot(vec3(0.33),res.rgb);

// color temp approximate
res.rgb *= vec3(1.0 + a_col_temp, 1.0 - a_col_temp * 0.2, 1.0 - a_col_temp);

float scan = mix(scanl, scanh,w);

// masks
float sz = 1.0;
float m_m = maskpos;
if (a_MTYPE == 1.0) sz = 0.6666;
if (a_MTYPE == 2.0) m_m = ogl2pos.x*2.0*pi;
res *= a_MASK*sin(m_m*sz)+1.0-a_MASK;

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

float l = dot(res.rgb,vec3(0.3,0.6,0.1));
res.rgb = mix(vec3(l),res.rgb,a_sat);

res *= mix(a_boostd,a_boostb,l);

FragColor.rgb = sqrt(res.rgb)*corner(cpos);
}
#endif
