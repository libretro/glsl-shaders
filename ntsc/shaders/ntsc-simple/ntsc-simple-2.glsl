#version 110

/*
   Simple composite-video (more like RF) like shader by DariusG 2023
   
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter ntsc_sat "NTSC Saturation" 3.0 0.0 6.0 0.05
#pragma parameter y_width "Luma Width (Blurry)" 4.0 1.0 8.0 1.0
#pragma parameter iq_width "Chroma Width (Bleed)" 9.0 4.0 32.0 1.0
#pragma parameter afacts "Low Pass Luma" 0.05 0.0 1.0 0.01
#pragma parameter h_pass_c "High Pass Chroma" 0.05 0.01 1.0 0.01
#pragma parameter animate_afacts "NTSC Artifacts Animate" 0.0 0.0 1.0 1.0
#pragma parameter phase_shifti "Phase Shift I" 0.0 -5.0 5.0 0.05
#pragma parameter phase_shiftq "Phase Shift Q" 0.0 -5.0 5.0 0.05
#pragma parameter comp_rf "Composite/RF" 0.0 0.0 1.0 1.0
#pragma parameter rf_noise "RF noise" 0.05 0.0 1.0 0.01
#pragma parameter x_mod "PI x mod" 0.59 0.0 2.0 0.01
#pragma parameter dummy "ZX Spectrum:0.59, Gen:0.76" 0.0 0.0 0.0 0.0

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
uniform COMPAT_PRECISION float phase_shifti;
uniform COMPAT_PRECISION float phase_shiftq;
uniform COMPAT_PRECISION float iq_width;
uniform COMPAT_PRECISION float y_width;
uniform COMPAT_PRECISION float comp_rf;
uniform COMPAT_PRECISION float h_pass_c;
uniform COMPAT_PRECISION float x_mod;
uniform COMPAT_PRECISION float rf_noise;

#else
#define ntsc_sat 1.0
#define afacts 0.0
#define animate_afacts 0.0
#define phase_shifti 0.0
#define phase_shiftq 0.0
#define iq_width 8.0
#define y_width 2.0
#define comp_rf 0.0
#define h_pass_c 0.05
#define x_mod 0.05
#define rf_noise 0.05
#endif

// this pass is a modification of https://www.shadertoy.com/view/3t2XRV

#define TAU  6.28318530717958647693
#define PI 3.1415926

// Colorspace conversion matrix for YUV-to-RGB
// All modern CRTs use YUV instead of YIQ
const mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);

float hann(float i, int size, float phase) {
    return pow(sin((PI * (i + phase)) / float(size)), 2.0);
}

#define iTimer float(FrameCount)

float noise(vec2 co)
{
return fract(sin(iTimer * dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
vec2 size = SourceSize.xy;
vec2 uv = vTexCoord;
int a = int(iq_width);
int b = int(y_width);

    //Sample composite signal and decode to YUV
    vec3 YUV = vec3(0);
    float sum = 0.0;
    for (int n=-b; n<b; n++) {
        // lowpass
        float w = exp(-afacts*float(n)*float(n));
        vec2 pos = uv + vec2(float(n) / size.x/2.0, 0.0);
        // low pass Y signal, high frequency chroma pattern is cut-off
        YUV.x += COMPAT_TEXTURE(Source, pos).r*w ;
        sum += w;
        }
        YUV.x /= sum;
    float sumc = 0.0;
    for (int n=-a; n<a; n++) {
        vec2 pos = uv + vec2(float(n) / size.x, 0.0);
        float phase = (floor(vTexCoord.x*SourceSize.x + float(n)))*PI*x_mod - mod(floor(vTexCoord.y*SourceSize.y),2.0)*PI ;
    // High Pass Chroma
    float r = exp(-h_pass_c*float(n)*float(n));
    //animate to further hide artifacts
    if (animate_afacts == 1.0) phase += PI*sin(mod(float(FrameCount+1),2.0));
    // add optional hann window function
    vec2 carrier;
    if (comp_rf == 0.0) carrier = ntsc_sat*vec2(sin(phase+phase_shifti), cos(phase+phase_shiftq));
    else carrier = ntsc_sat*4.0*vec2(sin(phase+phase_shifti), cos(phase+phase_shiftq))*hann(float(n),a*4,0.0);
        YUV.yz += r*COMPAT_TEXTURE(Source, pos).gb * carrier;
        sumc += r;
        }
    YUV.yz /= sumc;

    //  Convert signal to RGB
    YUV = YUV*YUV2RGB;
    FragColor = vec4(YUV*(1.0+noise(vTexCoord)*rf_noise), 1.0);
    
}
#endif
