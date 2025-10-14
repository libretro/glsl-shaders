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
#pragma parameter u_system "Clock: SNES, MD/PCE/PS1" 0.0 0.0 1.0 1.0
#pragma parameter u_comb "Comb Filter Strength" 0.6 0.0 1.0 0.05
#pragma parameter u_chroma "Chroma Gain" 1.5 0.0 3.0 0.05
#pragma parameter LPY "Luma Resolution" 1.6 0.0 3.0 0.02
#pragma parameter LPC "Chroma Resolution" 0.32 0.0 0.8 0.01
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
#define TAU 6.2831852
#define cycles 170.666/InputSize.x
#define crawl (u_system == 0.0? mod(float(FrameCount),2.0)*TAU*cycles : 0.0);

vec3 yiq(vec3 c) {
  float Y = 0.299*c.r + 0.587*c.g + 0.114*c.b;
  float I = 0.5959*c.r - 0.2746*c.g - 0.3213*c.b;
  float Q = 0.2115*c.r - 0.5227*c.g + 0.3112*c.b;
  return vec3(Y,I,Q);
}
vec3 rgb(vec3 yiq) {
  float Y = yiq.x, I = yiq.y, Q = yiq.z;
  float R = Y + 0.9563*I + 0.6210*Q;
  float G = Y - 0.2721*I - 0.6474*Q;
  float B = Y - 1.1069*I + 1.7046*Q;
  return vec3(R,G,B);
}

#define taps int(u_res)
void main()
{   
    vec3 final = vec3(0.0);
    vec2 dx = vec2(invdims.x,0.0);
    vec2 dy = vec2(0.0,invdims.y*0.25);
    float sumY = 0.0;
    float sumI = 0.0;
    float sumQ = 0.0;

    float line = u_system == 0.0? floor(ogl2pos.y)*TAU*cycles :floor(ogl2pos.y)*PI;

    for (int i=-taps; i<taps+1; i++)
    {
    float n = float(i);
    float p = n;
    float wY = exp(-LPY*n*n);
    float wI = exp(-LPC*p*p);
    float wQ = exp(-LPC*p*p);
    sumY += wY;    
    sumI += wI;    
    sumQ += wQ;    
    float phase = (ogl2pos.x + n)*cycles*PI + line + crawl;
    float cs = cos(phase);
    float sn = sin(phase);
    vec3 burst1 = vec3(1.0,cs,sn);
    vec3 burst2 = vec3(1.0,-cs,-sn);
    vec3 res1 = yiq(COMPAT_TEXTURE(Source,vTexCoord + dx*n).rgb)*burst1;
    vec3 res2 = yiq(COMPAT_TEXTURE(Source,vTexCoord + dx*n - dy).rgb)*burst2;
    float signal1 = u_svideo == 0.0 ? dot(vec3(1.0),res1) : dot(vec2(1.0),res1.gb);
    float signal2 = dot(vec3(1.0),res2);
    float luma = u_svideo == 0.0 ? (signal1 + signal2)*0.5 : res1.r;
    final.r += luma*wY;
    final.g += u_svideo == 0.0 ? (signal1 - luma*u_comb)*wI*burst1.g*u_chroma :
    signal1 * wI*burst1.g*u_chroma;
    final.b += u_svideo == 0.0 ? (signal1 - luma*u_comb)*wQ*burst1.b*u_chroma :
    signal1 * wQ*burst1.b*u_chroma;
    }   
    final.r /= sumY;
    final.g += final.b*0.2;
    final.g /= sumI;
    final.b /= sumQ;
    FragColor.rgb = rgb(final);
}
#endif
