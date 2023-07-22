#version 110

/*
   Simple dither shader by DariusG 2023
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/


#define iTime float(FrameCount)
#define pi 3.141592
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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
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

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float threshold;

#else
#define threshold 0.1
#endif



/*blurry dither
vec3 dith = vec3(.0);
float counter = 1.0;
for (int x = -1; x<2; x++)
{
    vec2 uv = vec2(vTexCoord.x*SourceSize.x+float(x), vTexCoord.y*SourceSize.y)/SourceSize.xy;    
    dith += texture2D(Source,uv).rgb;
    counter = counter+1.0;   
}
    res = (res+dith)/counter;
*/ 

void main()
{
vec2 pos = vTexCoord;


//          --------same---------
//          |                   | 
//       lleft left res right rright
//               |        |   
//               ---same---
//        
//        = there is a dither pattern


vec3 res   = COMPAT_TEXTURE(Source,pos).rgb;
vec3 left  = COMPAT_TEXTURE(Source,pos + vec2(SourceSize.z, 0.0)).rgb; 
vec3 right = COMPAT_TEXTURE(Source,pos - vec2(SourceSize.z, 0.0)).rgb;
vec3 lleft = COMPAT_TEXTURE(Source,pos + vec2(SourceSize.z*2.0, 0.0)).rgb;
vec3 rright= COMPAT_TEXTURE(Source,pos - vec2(SourceSize.z*2.0, 0.0)).rgb;

float cond1 = lleft == rright  ? 1.0 :0.0;
float cond2 = left == right  ? 1.0 :0.0;

float lumres = dot(vec3(0.2,0.7,0.1),res);
float lumright = dot(vec3(0.2,0.7,0.1),right);
float diff = lumres-lumright;
res = cond2 == 1.0 && cond1 !=1.0 && diff < 0.0 ? (res*3.0+right)/4.0 : res;

res = cond1 == 1.0 && cond2 == 1.0 && left != lleft ? (res+right)/2.0 : res;

FragColor = vec4(res,1.0);
}
#endif
