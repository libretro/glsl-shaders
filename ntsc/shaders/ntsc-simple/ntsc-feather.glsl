#version 110

/*
   Simple Composite-like shader by DariusG 2023
   This shader was created by observing my Amiga 500 
   connected to a CRT with A520 composite TV modulator.
   Not 100% accurate but gets the job done.

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter MASK "Color Subcarrier Artifacts"  0.08 0.0 1.0 0.01
#pragma parameter COMPOSITE_LOWPASS "Composite Lowpass"  0.8 0.0 2.0 0.05
#pragma parameter COL_BLEED "Chroma Bleed"  1.4 0.0 2.0 0.05
#pragma parameter NTSC_COL "NTSC Colors "  0.0 0.0 1.0 1.0

#define PI 3.141592
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
uniform COMPAT_PRECISION float MASK;
uniform COMPAT_PRECISION float COMPOSITE_LOWPASS;
uniform COMPAT_PRECISION float COL_BLEED;
uniform COMPAT_PRECISION float NTSC_COL;

#else
#define MASK 0.7
#define COMPOSITE_LOWPASS 1.0
#define COL_BLEED 1.0
#define NTSC_COL 0.0
#endif

mat3 RGBtoYIQ = mat3(
        0.2989, 0.5870, 0.1140,
        0.5959, -0.2744, -0.3216,
        0.2115, -0.5229, 0.3114);

mat3 YIQtoRGB = mat3(
        1.0, 0.956, 0.6210,
        1.0, -0.2720, -0.6474,
        1.0, -1.1060, 1.7046);

const mat3 NTSC = mat3(
    1.8088923,   -0.6480268,  -0.0833558,
   0.4062922 ,  0.6175271,   -0.0038849,
  -0.0025872,  -0.103848 ,  1.182318);

#define Time sin(float(FrameCount))


void main()
{
    float phase = InputSize.x<300.0 ? 4.0*PI/15.0 : PI/3.0;
    #define SC MASK*sin(vTexCoord.x*SourceSize.x*phase)+1.0-MASK

    vec2 cent = floor(vTexCoord*SourceSize.xy)+0.5;
    vec2 coords = cent*SourceSize.zw;
    coords = vec2(mix(vTexCoord.x,coords.x,0.2),coords.y);

    vec3 res = COMPAT_TEXTURE(Source,coords).rgb; res *= RGBtoYIQ;
    float onetexel = SourceSize.z*COMPOSITE_LOWPASS;
    float bleed = SourceSize.z*COL_BLEED;
    vec3 resr = COMPAT_TEXTURE(Source,coords-(vec2(2.0*bleed,0.0))).rgb; resr *= RGBtoYIQ;
    vec3 resru = COMPAT_TEXTURE(Source,coords-(vec2(onetexel,0.0))).rgb; resru *= RGBtoYIQ;
    vec3 resrr = COMPAT_TEXTURE(Source,coords-(vec2(3.0*bleed,0.0))).rgb; resrr *= RGBtoYIQ;
    
    vec3 resl = COMPAT_TEXTURE(Source,coords+(vec2(2.0*bleed,0.0))).rgb; resl *= RGBtoYIQ;
    vec3 reslu = COMPAT_TEXTURE(Source,coords+(vec2(bleed,0.0))).rgb; reslu *= RGBtoYIQ;
    vec3 resll = COMPAT_TEXTURE(Source,coords+(vec2(3.0*bleed,0.0))).rgb; resll *= RGBtoYIQ;
    
    //color bleed
    res.gb += (resr.gb+resl.gb+resrr.gb+resll.gb+reslu.gb+resru.gb); res.gb /= 7.0;
    //overall bluriness
    res.r = (res.r + resru.r)/2.0; 
        
    vec3 checker = COMPAT_TEXTURE(Source,vTexCoord - vec2(0.25/InputSize.x,0.0)).rgb;  checker *= RGBtoYIQ;  
    vec3 checkerl = COMPAT_TEXTURE(Source,vTexCoord + vec2(0.1/InputSize.x,0.0)).rgb;  checkerl *= RGBtoYIQ;  

    float diff = res.g-checker.g;
    float diffl = res.g-checkerl.g;
    float ydiff = res.r-checker.r;
    float ydiffl = res.r-checkerl.r;

    float x = mod(floor(vTexCoord.x*SourceSize.x),2.0);
    float y = mod(floor(vTexCoord.y*SourceSize.y),2.0);


//Color subcarrier pattern
    if (y == 0.0 && x == 0.0 && Time < 0.0 && diff > 0.0 || y == 0.0 && x == 1.0 && Time > 0.0 && diff > 0.0)
    
        res.b *= SC; // ok
    
    else if (y == 1.0 && x == 1.0 && Time < 0.0 && diff > 0.0 || y == 1.0 && x == 0.0 && Time > 0.0 && diff > 0.0)
    
        res.b *= SC; // ok
 
    else if (y == 0.0 && x == 0.0 && Time < 0.0 && ydiff < 0.0 || y == 0.0 && x == 1.0 && Time > 0.0 && ydiff < 0.0)
    
        res.r *= SC; // ok
    
    else if (y == 1.0 && x == 1.0 && Time < 0.0 && ydiff < 0.0 || y == 1.0 && x == 0.0 && Time > 0.0 && ydiff < 0.0)
        res.r *= SC; // ok
   
    else if (y == 0.0 && x == 0.0 && Time < 0.0 && ydiffl < 0.0 || y == 0.0 && x == 1.0 && Time > 0.0 && ydiffl < 0.0)
    
        res.r *= SC;
    
    else if (y == 1.0 && x == 1.0 && Time < 0.0 && ydiffl < 0.0 || y == 1.0 && x == 0.0 && Time > 0.0 && ydiffl < 0.0)
        res.r *= SC; 

//for testing
//if (ydiffl < 0.0) res = vec3(0.0);

///
    res *= YIQtoRGB;
    if (NTSC_COL == 1.0)res *= NTSC;
    FragColor = vec4(res,1.0);
}

#endif
