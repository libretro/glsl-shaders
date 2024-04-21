#version 110

/*
    zfast_crt_composite, A very simple CRT shader
    by metallic 77.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
    
*/

#pragma parameter Curvature "Curvature On/Off" 1.0 0.0 1.0 1.0
#pragma parameter blurx "Convergence X-Axis" 0.6 -2.0 2.0 0.05
#pragma parameter blury "Convergence Y-Axis" -0.10 -2.0 2.0 0.05
#pragma parameter scan "Scanlines Strength" 0.4 0.0 0.5 0.05
#pragma parameter maskc "Mask Strength" 0.35 0.0 0.5 0.05
#pragma parameter mask "Slot Strength" 0.3 0.0 0.5 0.05
#pragma parameter slotx "Mask Width" 3.0 2.0 3.0 1.0
#pragma parameter sat "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter ntsc_j "NTSC-J colors" 0.0 0.0 1.0 1.0

#define pi 3.14159265
#define SourceSize vec4(TextureSize.xy,1.0/TextureSize.xy)
#define scale  vec2(SourceSize.xy/InputSize.xy)
#define maskpos TEX0.x*OutputSize.x*scale.x
#define blur_y blury/(SourceSize.y*2.0)
#define blur_x blurx/(SourceSize.x*2.0)

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
COMPAT_VARYING vec2 warp;


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
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     2.0 
     
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    warp = TEX0.xy*scale;
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
COMPAT_VARYING vec2 warp;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float slotx;
uniform COMPAT_PRECISION float maskc;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float ntsc_j;
uniform COMPAT_PRECISION float scan;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float Curvature;
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
#else
#define slotx  3.0     
#define maskc  0.2     
#define mask  0.2     
#define  ntsc_j  1.0     
#define  scan  0.4    
#define  sat  1.15    
#define  Curvature  1.0   
#define blurx 0.45
#define blury -0.15  
#endif

vec2 Warp (vec2 pos)
{
    pos = pos*2.0-1.0;
    pos *= vec2(1.0+pos.y*pos.y*0.03, 1.0+pos.x*pos.x*0.04);
    pos = pos*0.5+0.5;
    return pos;
}

// GLES after Google Pixel Primaries:
// R 0.66, 0.34
// G 0.23, 0.72
// B 0.14, 0.01

#if defined GL_ES

mat3 hue = mat3(                
0.60722     ,0.25198 ,   0.27164,
-0.10833    ,0.98873 ,   0.19229,
-0.02558    ,0.12980 ,   1.10027);

#else
mat3 hue = mat3(                    
0.9501  ,   -0.0431 ,   0.0857  ,
0.0265  ,   0.9278  ,   0.0432  ,
0.0011  ,   -0.0206 ,   1.3153  );

#endif


void main()
{ 
    vec2 pos, corn;
    
    if (Curvature == 1.0){
    pos = Warp(warp);
    
    corn = min(pos,vec2(1.0)-pos);      
    corn.x = 0.000015/corn.x;  
    
    pos /= scale;  
    }
    else pos = vTexCoord;
    vec2 ogl2pos = pos*SourceSize.xy;
    vec2 p = ogl2pos+0.5;
    vec2 i = floor(p);
    vec2 f = p - i;       // -0.5 to 0.5
       f = f*f*(3.0-2.0*f);
       f.y *= f.y*f.y;    //sharper y
       p = (i + f-0.5)*SourceSize.zw;
    
     vec3 sample1 =  COMPAT_TEXTURE(Source,vec2(p.x + blur_x, p.y - blur_y)).rgb;
     vec3 res =  0.5*COMPAT_TEXTURE(Source,p).rgb;
     vec3 sample3 =  COMPAT_TEXTURE(Source,vec2(p.x - blur_x, p.y + blur_y)).rgb;
    
      res = vec3 (sample1.r*0.5  + res.r, 
                  sample1.g*0.25 + res.g + sample3.g*0.25, 
                                   res.b + sample3.b*0.5);
    vec3 clean = res;
    float w = max(max(res.r,res.g),res.b)*0.5;

res *=res;
if (ntsc_j == 1.0) {res *= hue; 
    res /= vec3(0.24,0.69,0.07);
    res *= vec3(0.3,0.6,0.1); 
    res = clamp(res,0.0,1.0);}
// mask
res *= maskc*sin(maskpos*pi*2.0/slotx)+1.0-maskc;

// slot mask calculations
float oddx = mod(maskpos,2.0*slotx) < slotx ? 1.0 : 0.0;
res *= mask*sin((ogl2pos.y*4.0+oddx)*pi)+1.1-mask;

// scanlines
res *= scan*sin(((ogl2pos.y+0.5)*2.0)*pi)+1.0-scan;
res = sqrt(res);

res = mix(res, clean, w);

float lum = dot(vec3(0.3,0.6,0.1),res);
res = mix(vec3(lum),res, sat);

res *= mix(1.45, 1.05, w);

if (Curvature == 1.0 && corn.y < corn.x || Curvature == 1.0 && corn.x < 0.00001 )
    res = vec3(0.0); 

    FragColor.rgb = res;
}
#endif
