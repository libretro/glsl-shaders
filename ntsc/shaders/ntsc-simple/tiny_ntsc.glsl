#version 110

/*
Tiny_NTSC by DariusG 2024-2025

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.
*/
#pragma parameter comb "Comb Filter Strength" 0.6 0.0 1.0 0.05
#pragma parameter taps "Filter Taps (slower)" 4.0 2.0 12.0 1.0
#pragma parameter lpf_w "Low Pass Width Y" 0.5 0.25 2.0 0.25
#pragma parameter lpf_w_c "Low Pass Width C" 1.0 0.25 4.0 0.25
#pragma parameter c_lpf "Chroma Low Pass (bleed)" 0.2 0.0 1.0 0.01
#pragma parameter y_lpf "Luma Low Pass (sharpness)" 0.3 0.0 1.0 0.01
#pragma parameter ntsc_sat "Saturation" 1.5 0.0 4.0 0.05
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
    ogl2pos = TEX0.xy*TextureSize;
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
COMPAT_VARYING vec2 ogl2pos;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float comb;
uniform COMPAT_PRECISION float taps;
uniform COMPAT_PRECISION float lpf_w;
uniform COMPAT_PRECISION float lpf_w_c;
uniform COMPAT_PRECISION float y_lpf;
uniform COMPAT_PRECISION float c_lpf;
uniform COMPAT_PRECISION float ntsc_sat;

#else
#define comb 0.3
#define taps 5.0
#define lpf_w 0.5
#define lpf_w_c 1.0
#define y_lpf 0.3
#define c_lpf 0.5
#define ntsc_sat 1.5
#endif

#define PI 3.1415926
#define timer  mod(float(FrameCount),2.0)

mat3 RGBYUV = mat3(0.299, 0.587, 0.114,
                        -0.299, -0.587, 0.886, 
                         0.701, -0.587, -0.114);

mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);


void main()
{
float v_sync = PI*170.666/InputSize.x;
float h_sync = v_sync;    

    vec2 p = vec2(SourceSize.z*lpf_w,0.0);
    vec2 pc = vec2(SourceSize.z*lpf_w_c,0.0);
    vec2 y = vec2(0.0,SourceSize.w*0.25);
    vec3 final = vec3(0.0);
    float sum = 0.0;
    float sumY = 0.0;
    int steps = int(taps); 

vec2 GL2pos = floor(ogl2pos);
//detect if 256x224 or 320x224 and define phase
float phase_y = InputSize.x<300.0? GL2pos.y*v_sync : 0.0;

for (int i=-int(steps); i<=int(steps); i++)
{
    float n = float(i);    
    float w  = exp(-c_lpf*n*n);
    float wY = exp(-y_lpf*n*n);
    // phase cycles every 3 pixels horizontally:
    float phase_x = (GL2pos.x + n)*h_sync;

// Combined horizontal + vertical phase in 3-phase space (NES):
    float phase = phase_x - phase_y  + timer;
    float c = cos(phase);
    float s = sin(phase);
    vec3 carrier   = vec3(1.0, c, s);
    vec3 carrierup = vec3(1.0, -c, -s);

// manual calculation, 3 calc instead of 9 for each texel    
    vec3 res    = COMPAT_TEXTURE(Source,vTexCoord + n*p).rgb;
    float R = res.r;
    res.r  = dot(res, vec3(0.299, 0.587, 0.114));
    res.g  = res.b - res.r;
    res.b  = R - res.r;
    vec3 resc   = COMPAT_TEXTURE(Source,vTexCoord + n*pc).rgb;
    float Rc = resc.r;
    resc.r  = dot(resc, vec3(0.299, 0.587, 0.114));
    resc.g  = resc.b - resc.r;
    resc.b  = Rc - resc.r;
    vec3 resup  = COMPAT_TEXTURE(Source,vTexCoord + n*p -y).rgb;
    float Rup = resup.r;
    resup.r  = dot(resup, vec3(0.299, 0.587, 0.114));
    resup.g  = resup.b - resup.r;
    resup.b  = resup.r - resup.r;
    vec3 resupc = COMPAT_TEXTURE(Source,vTexCoord + n*pc -y).rgb;
    float Rupc = resupc.r;
    resupc.r  = dot(resupc, vec3(0.299, 0.587, 0.114));
    resupc.g  = resupc.b - resupc.r;
    resupc.b  = Rupc- resupc.r;
// add color signal
    res   *= carrier;
    resc  *= carrier;
    resup *= carrierup;
    resupc *= carrierup;

    //get composite sample
    float line = dot(res,vec3(0.5));
    float lineup = dot(resup,vec3(0.5));

    float linec = dot(resc,vec3(0.5));
    float lineupc = dot(resupc,vec3(0.5));

    // comb luma is line adding previous line, chroma is cancelled!
    float luma   = line + lineup;
    float lumac   = linec + lineupc;
    // comb chroma is line subtracting luma we already have!
    float chroma = linec - lumac*0.5*comb;
    // lowpass Y and C, Luma has more bandwidth than Chroma (sharper)
    if (i>-(steps/2) && i<(steps/2 + 1))
    {
    final.r  += luma*wY;
    sumY += wY;
    }
    final.gb += vec2(chroma)*vec2(ntsc_sat,ntsc_sat*2.0)*carrier.yz*w;

    sum  += w;
}
    final.r  /= sumY;
    final.gb /= sum;
vec3 rgb;
rgb.r = final.r + 1.13983 * final.b;
rgb.g = final.r - 0.39465 * final.g - 0.58060 * final.b;
rgb.b = final.r + 2.03211 * final.g;


    FragColor.rgb = rgb;
}
#endif
