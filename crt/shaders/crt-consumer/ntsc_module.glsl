#version 110

/*
    NTSC module, DariusG 2025 — Universal NTSC Composite Emulator

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
    
*/
#pragma parameter dummy1 " [ ----NTSC---- ]" 0.0 0.0 0.0 0.0 
#pragma parameter u_svideo "S-Video" 0.0 0.0 1.0 1.0
#pragma parameter u_system "Clock: NES, MD, PCE(NTSC)" 0.0 0.0 2.0 1.0
#pragma parameter u_comb "Comb Filter Strength" 0.6 0.0 1.0 0.05
#pragma parameter u_chroma "Chroma Gain" 1.5 0.0 3.0 0.05
#pragma parameter LPY "Luma Resolution" 1.3 0.0 2.0 0.02
#pragma parameter LPC "Chroma Resolution" 0.2 0.0 0.4 0.01
#pragma parameter u_res "Taps" 3.0 1.0 3.0 1.0
#pragma parameter dummy2 " [ ----NTSC---- ]" 0.0 0.0 0.0 0.0 

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;


void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    ogl2pos = TEX0.xy*TextureSize;
    invdims = 1.0/TextureSize;
    scale = TextureSize/InputSize;
    maskpos = TEX0.xy*scale*OutputSize.xy;
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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;

#define Source Texture
#define vTexCoord TEX0.xy

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float u_system;
uniform COMPAT_PRECISION float u_comb;
uniform COMPAT_PRECISION float u_chroma;
uniform COMPAT_PRECISION float LPC;
uniform COMPAT_PRECISION float LPY;
uniform COMPAT_PRECISION float u_res;
uniform COMPAT_PRECISION float u_svideo;

#else
#define u_system 0.0
#define u_comb 0.4
#define u_chroma 1.5
#define LPC 0.08
#define LPY 1.25
#define u_res 30.0
#define u_svideo 0.0

#endif

#define GAMMAIN(color) color*color 
#define PI 3.14159265358979323846 

// --- YIQ conversion ---
vec3 rgb2yiq(vec3 rgb) {
    return vec3(
        dot(rgb, vec3(0.299, 0.587, 0.114)),
        dot(rgb, vec3(0.595716, -0.274453, -0.321263)),
        dot(rgb, vec3(0.211456, -0.522591, 0.311135))
    );
}
vec3 yiq2rgb(vec3 yiq) {
    return vec3(
        yiq.x + 0.9563*yiq.y + 0.6210*yiq.z,
        yiq.x - 0.2721*yiq.y - 0.6474*yiq.z,
        yiq.x - 1.1070*yiq.y + 1.7046*yiq.z
    );
}

// NTSC constants
const float NTSC_FREQ = 3.579545e6;
const float TAU = 6.28318530718;
// Example per-u_system pixel clocks (approx)
const float SNES_CLOCK = 5.369317e6;
const float MD_CLOCK   = 6.713e6;
const float PCE_CLOCK  = 7.15909e6;


// Compute subcarrier phase for a pixel coordinate
float ntsc_phase(float x, float y, float pixel_clock) {
    // Per-pixel phase drift
    float per_pixel = (NTSC_FREQ / pixel_clock * PI) * x ;

// u_system: 0.0 = SNES (not locked), 1.0 = MD/PCE (locked)
float per_line;
if (u_system == 0.0) {
    float framePhase = (mod(float(FrameCount), 2.0) < 1.0) ? ((8.0/12.0) * TAU) : 0.0;
    per_line = mod(y , 3.0)*TAU*0.666 + framePhase;
} else {
    // Locked systems: NTSC phase flips every line (180°)
    per_line = mod(y, 4.0)*NTSC_FREQ / pixel_clock * TAU;
}

    // Total phase
    return per_pixel + per_line;
}

vec3 tex(vec2 uv) { return COMPAT_TEXTURE(Source, uv).rgb; }
#define taps int(u_res)
void main() {
    vec2 dx = vec2(invdims.x,0.0);
    vec2 dy = vec2(0.0,invdims.y*0.5);
    float px = (ogl2pos.x);
    float py = floor(ogl2pos.y);
    float sumY = 0.0;
    float sumC = 0.0;
    vec3 final = vec3(0.0);



for (int i=-taps; i<taps+1; i++)
{
    float n = float(i);
    float wY = exp(-LPY*n*n);
    float wC = exp(-LPC*n*n);
    sumY += wY;
    sumC += wC;
    float phase = ntsc_phase(px + n, py, u_system == 0.0 ? SNES_CLOCK : u_system == 1.0 ? MD_CLOCK : PCE_CLOCK);
    float cs = cos(phase);
    float sn = sin(phase);
    vec2 burst1 = vec2( cs, sn);
    vec2 burst2 = vec2(-cs,-sn);
    vec3 res1 =rgb2yiq(tex(vTexCoord + n*dx));
    vec3 res2 =rgb2yiq(tex(vTexCoord + n*dx - dy));
    res1.gb *= burst1;
    res2.gb *= burst2;
    float comp1 = u_svideo == 0.0 ? dot(res1,vec3(1.0)) : dot(res1.gb,vec2(1.0)) ;
    float comp2 = u_svideo == 0.0 ? dot(res2,vec3(1.0)) : dot(res2.gb,vec2(1.0)) ;
    float luma =   u_svideo == 0.0 ? (comp1 + comp2)*0.5 : res1.r;
    final.r += luma*wY;
    final.gb +=  u_svideo == 0.0 ? (comp1-luma*u_comb)*wC*burst1*u_chroma : comp1*wC*burst1*u_chroma;

}
    final.r /= sumY;
    final.gb /= sumC;
    FragColor.rgb = yiq2rgb(final);
}
#endif
