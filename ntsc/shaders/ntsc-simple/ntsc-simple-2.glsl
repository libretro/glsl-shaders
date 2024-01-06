#version 110

/*
   Simple S-video like shader by DariusG 2023
   
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter ntsc_sat "NTSC Saturation" 1.25 0.0 2.0 0.05
#pragma parameter afacts "NTSC Artifacts Strength (lowpass Y)" 0.02 0.0 1.0 0.01
#pragma parameter animate_afacts "NTSC Artifacts Animate" 1.0 0.0 1.0 1.0

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
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ntsc_sat;
uniform COMPAT_PRECISION float afacts;
uniform COMPAT_PRECISION float animate_afacts;

#else
#define ntsc_sat 1.0
#define afacts 0.0
#define animate_afacts 0.0
#endif

// this pass is a modification of https://www.shadertoy.com/view/3t2XRV

#define TAU  6.28318530717958647693
#define PI 3.1415926

//  Colorspace conversion matrix for YIQ-to-RGB
const mat3 YIQ2RGB = mat3(1.000, 1.000, 1.000,
                          0.956,-0.272,-1.106,
                          0.621,-0.647, 1.703);

void main()
{
vec2 size = SourceSize.xy;
vec2 uv = vTexCoord;

    //Sample composite signal and decode to YIQ
    vec3 YIQ = vec3(0);
    float sum = 0.0;
    for (int n=-2; n<2; n++) {
        // lowpass
        float w = exp(-afacts*float(n)*float(n));
        vec2 pos = uv + vec2(float(n) / size.x, 0.0);
        // low pass Y signal, high frequency chroma pattern is cut-off
        YIQ.x += COMPAT_TEXTURE(Source, pos).r*w ;
        sum += w;
        }
        YIQ.x /= sum;

    for (int n=-8; n<8; n++) {
        vec2 pos = uv + vec2(float(n) / size.x, 0.0);
        float phase = (vTexCoord.x*SourceSize.x + float(n))*PI/2.0 - vTexCoord.y*SourceSize.y*2.0;
    //animate to hide artifacts
    if (animate_afacts == 1.0) phase -= (vTexCoord.y*SourceSize.y*2.0)*PI*mod(float(FrameCount),2.0);
    // missing a bandpass here to weaken artifacts on high luminance
        YIQ.yz += COMPAT_TEXTURE(Source, pos).gb * ntsc_sat*vec2(cos(phase), sin(phase));
        }
    YIQ.yz /= 16.0;

    //  Convert YIQ signal to RGB
    YIQ = YIQ2RGB*YIQ;
    FragColor = vec4(YIQ, 1.0);
    
}
#endif
