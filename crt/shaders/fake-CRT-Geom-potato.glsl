#version 110

/*
   A shader by DariusG 2023
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter size "Mask Size" 2.0 2.0 3.0 1.0
#pragma parameter warp "Curvature" 0.12 0.0 0.3 0.01
#pragma parameter border "Border Smoothness" 0.02 0.0 0.2 0.005
#pragma parameter hheld_mode "Handheld mode" 0.0 0.0 1.0 1.0

#define PI   3.14159265358979323846
#define tau  6.283185

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
COMPAT_VARYING vec2 screenscale;
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
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float size;
#else
#define size 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    screenscale = SourceSize.xy/InputSize.xy;
    maskpos = TEX0.x*OutputSize.x*screenscale.x;
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
COMPAT_VARYING float maskpos;
COMPAT_VARYING vec2 screenscale;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float border;
uniform COMPAT_PRECISION float size;
uniform COMPAT_PRECISION float warp;
uniform COMPAT_PRECISION float hheld_mode;


#else
#define border 0.02
#define size 2.0
#define warp 0.12
#define hheld_mode 0.0

#endif


void main() 
{
vec2 pos = vTexCoord*screenscale; // 0.0 to 1.0 range

// curve horizontally & vertically
COMPAT_PRECISION float cx = pos.x - 0.5; // -0.5 to 0.5
COMPAT_PRECISION float cy = pos.y - 0.5; // -0.5 to 0.5
pos.x = pos.x + (cy * cy * warp * cx);
pos.y = pos.y + (cx * cx * warp * cy);
vec2 cpos = pos;

pos /= screenscale; 

vec2 spos = pos*SourceSize.xy;
vec2 near = floor(spos)+0.5;
vec2 f = spos - near;

pos.y = (near.y + 16.0*f.y*f.y*f.y*f.y*f.y)*SourceSize.w;    

vec3 res = COMPAT_TEXTURE(Source,pos).rgb;
    
float l = dot(vec3(0.25),res);

// get pixel position in screen space
float pix = floor(maskpos);
// Mask out every other line
if (mod(pix, size) == 0.0) {
    res.rgb *= 0.7; // mask
}

float scan_pow = 1.0;
float scn = 1.0;

if (hheld_mode == 0.0){
scan_pow = mix(0.5,0.2,l);    
scn = scan_pow*sin((spos.y-0.25)*tau)+1.0-scan_pow;
res *= scn;    
}

res *= mix(1.45,1.25,l);
res = sqrt(res);
// fade screen edges (linear falloff)
float fade_x = smoothstep(0.0, border, cpos.x) *
               smoothstep(0.0, border, 1.0 - cpos.x);
float fade_y = smoothstep(0.0, border, cpos.y) *
               smoothstep(0.0, border, 1.0 - cpos.y);
// combine fades
float fade = fade_x * fade_y;
res *= fade;
FragColor.rgb = res;
}
#endif
