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

#pragma parameter MASK "Color Subcarrier Artifacts"  0.2 0.0 1.0 0.01
#pragma parameter COMPOSITE_LOWPASS "Composite Lowpass"  0.95 0.0 4.0 0.05
#pragma parameter COL_BLEED "Chroma Bleed"  0.25 0.0 2.0 0.05
#pragma parameter NTSC_COL "NTSC Colors "  0.0 0.0 1.0 1.0
#pragma parameter BRIGHTNESS "Brightness"  1.0 0.0 2.0 0.05
#pragma parameter SATURATION "Saturation"  2.0 0.0 2.0 0.05
#pragma parameter FRINGING "Fringing "  0.25 0.0 1.0 0.01
#pragma parameter ARTIFACTS "Artifacts "  0.25 0.0 1.0 0.01

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
uniform COMPAT_PRECISION float BRIGHTNESS;
uniform COMPAT_PRECISION float SATURATION;
uniform COMPAT_PRECISION float FRINGING;
uniform COMPAT_PRECISION float ARTIFACTS;

#else
#define MASK 0.7
#define COMPOSITE_LOWPASS 1.0
#define COL_BLEED 1.0
#define NTSC_COL 0.0
#define BRIGHTNESS 1.0
#define SATURATION 1.0
#define FRINGING 0.0
#define ARTIFACTS 0.0
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



mat3 original = mat3(
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0
);

#define Time sin(float(FrameCount/2))

void main()
{

   // GLES error if mat out of main, considered a const not accepting variables? 
   mat3 mix_mat = mat3(
    BRIGHTNESS, FRINGING, FRINGING,
    ARTIFACTS, 1.0, 0.0,
    ARTIFACTS, 0.0, 1.0
);

    vec2 cent = floor(vTexCoord*SourceSize.xy)+0.5;
    vec2 coords = cent*SourceSize.zw;
    coords = vec2(mix(vTexCoord.x,coords.x,0.2),coords.y);

    vec3 res = COMPAT_TEXTURE(Source,coords).rgb; res *= RGBtoYIQ;
    vec3 initial = COMPAT_TEXTURE(Source,coords-vec2(SourceSize.z,0.0)).rgb; initial *= RGBtoYIQ;
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
    vec3 lumweight = vec3(0.3,0.6,0.1);
    float ydiff = dot(lumweight.gb,initial.gb)-dot(lumweight.gb,resr.gb);
    float ydiffl = dot(lumweight,initial)-dot(lumweight,resrr);
   
    float chroma_phase = 0.6667 * PI * (mod(vTexCoord.y*SourceSize.y, 3.0) + Time);
    float mod_phase = chroma_phase + vTexCoord.x*SourceSize.x*2.0*PI/3.0;
    float i_mod = cos(mod_phase);
    float q_mod = sin(mod_phase);


         res.yz *= vec2(i_mod,q_mod);
        if (ydiff < 0.0  ) res = mix(res*original,res*mix_mat,MASK);
         res.yz *= vec2(i_mod,q_mod);
//for testing
//if (ydiff < 0.00  ) res = vec3(0.0,1.0,1.0);

///
    res *= YIQtoRGB;
    if (NTSC_COL == 1.0)res *= NTSC;
    float gray = dot(lumweight,res);
    res = mix(vec3(gray),res,SATURATION);
    FragColor = vec4(res,1.0);
}

#endif
