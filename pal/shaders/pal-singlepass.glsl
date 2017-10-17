/*
    pal-singlepass.slang

    svo's PAL single pass shader, ported to libretro
    ------------------------------------------------
    "Software composite video modulation/demodulation experiments

    The idea is to reproduce in GLSL shaders realistic composite-like
    artifacting by applying PAL modulation and demodulation.
    
    Digital texture, passed through the model of an analog channel,
    should suffer same effects as its analog counterpart and exhibit properties,
    such as dot crawl and colour bleeding, that may be desirable for faithful
    reproduction of look and feel of old computer games."
    
    https://github.com/svofski/CRT

    Copyright (c) 2016, Viacheslav Slavinsky
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
    THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Parameter lines go here:
#pragma parameter FIR_GAIN    "FIR lowpass gain"               1.5 0.0 5.0 0.1
#pragma parameter FIR_INVGAIN "Inverse gain for luma recovery" 1.1 0.0 5.0 0.1
#pragma parameter PHASE_NOISE "Phase noise"                    1.0 0.0 5.0 0.1

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
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

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float FIR_GAIN;
uniform COMPAT_PRECISION float FIR_INVGAIN;
uniform COMPAT_PRECISION float PHASE_NOISE;
#else
#define FIR_GAIN 1.5
#define FIR_INVGAIN 1.1
#define PHASE_NOISE 1.0
#endif

/* Subcarrier frequency */
#define FSC          4433618.75

/* Line frequency */
#define FLINE        15625.

#define VISIBLELINES 312.

#define PI           3.14159265358

#define RGB_to_YIQ  mat3( 0.299,    0.595716,  0.211456,\
                            0.587,   -0.274453, -0.522591,\
                            0.114,   -0.321263,  0.311135)

#define YIQ_to_RGB  mat3( 1.0   ,   1.0,       1.0,\
                            0.9563,  -0.2721,   -1.1070,\
                            0.6210,  -0.6474,    1.7046)

#define RGB_to_YUV  mat3( 0.299,   -0.14713,   0.615,\
                            0.587,   -0.28886,  -0.514991,\
                            0.114,    0.436,    -0.10001)

#define YUV_to_RGB  mat3( 1.0,      1.0,       1.0,\
                            0.0,     -0.39465,   2.03211,\
                            1.13983, -0.58060,   0.0)
                            
#define fetch(ofs,center,invx) COMPAT_TEXTURE(Source, vec2((ofs) * (invx) + center.x, center.y))

#define FIRTAPS 20.
#if __VERSION__ < 130
float FIR1 = -0.008030271;
float FIR2 = 0.003107906;
float FIR3 = 0.016841352;
float FIR4 = 0.032545161;
float FIR5 = 0.049360136;
float FIR6 = 0.066256720;
float FIR7 = 0.082120150;
float FIR8 = 0.095848433;
float FIR9 = 0.106453014;
float FIR10 = 0.113151423;
float FIR11 = 0.115441842;
float FIR12 = 0.113151423;
float FIR13 = 0.106453014;
float FIR14 = 0.095848433;
float FIR15 = 0.082120150;
float FIR16 = 0.066256720;
float FIR17 = 0.049360136;
float FIR18 = 0.032545161;
float FIR19 = 0.016841352;
float FIR20 = 0.003107906;
#else
float FIR[FIRTAPS] = float[FIRTAPS] (
   -0.008030271,
    0.003107906,
    0.016841352,
    0.032545161,
    0.049360136,
    0.066256720,
    0.082120150,
    0.095848433,
    0.106453014,
    0.113151423,
    0.115441842,
    0.113151423,
    0.106453014,
    0.095848433,
    0.082120150,
    0.066256720,
    0.049360136,
    0.032545161,
    0.016841352,
    0.003107906
);
#endif

/* subcarrier counts per scan line = FSC/FLINE = 283.7516 */
/* We save the reciprocal of this only to optimize it */
float counts_per_scanline_reciprocal = 1.0 / (FSC/FLINE);

float width_ratio;
float height_ratio;
float altv;
float invx;

/* http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/ */
float rand(vec2 co)
{
    float a  = 12.9898;
    float b  = 78.233;
    float c  = 43758.5453;
    float dt = dot(co.xy, vec2(a, b));
    float sn = mod(dt,3.14);

    return fract(sin(sn) * c);
}

float modulated(vec2 xy, float sinwt, float coswt) 
{
    vec3 rgb = fetch(0., xy, invx).xyz;
    vec3 yuv = RGB_to_YUV * rgb;

    return clamp(yuv.x + yuv.y * sinwt + yuv.z * coswt, 0.0, 1.0);    
}

vec2 modem_uv(vec2 xy, float ofs) {
    float t  = (xy.x + ofs * invx) * SourceSize.x;
    float wt = t * 2. * PI / width_ratio;

    float sinwt = sin(wt);
    float coswt = cos(wt + altv);

    vec3 rgb = fetch(ofs, xy, invx).xyz;
    vec3 yuv = RGB_to_YUV * rgb;
    float signal = clamp(yuv.x + yuv.y * sinwt + yuv.z * coswt, 0.0, 1.0);
    
    if (PHASE_NOISE != 0.)
    {
        /* .yy is horizontal noise, .xx looks bad, .xy is classic noise */
        vec2 seed = xy.yy * float(FrameCount);
        wt        = wt + PHASE_NOISE * (rand(seed) - 0.5);
        sinwt     = sin(wt);
        coswt     = cos(wt + altv);
    }

    return vec2(signal * sinwt, signal * coswt);
}

void main()
{
    vec2 xy      = vTexCoord;
    width_ratio  = SourceSize.x * (counts_per_scanline_reciprocal);
    height_ratio = SourceSize.y / VISIBLELINES;
    altv         = mod(floor(xy.y * VISIBLELINES + 0.5), 2.0) * PI;
    invx         = 0.25 * (counts_per_scanline_reciprocal); // equals 4 samples per Fsc period

    // lowpass U/V at baseband
    vec2 filtered = vec2(0.0, 0.0);
#if __VERSION__ < 130 //unroll the loop
	vec2 uv;
	
	#define macro_loopz(c)	uv = modem_uv(xy, float(c) - FIRTAPS*0.5); \
        filtered += FIR_GAIN * uv * FIR##c;
		
	macro_loopz(1)
	macro_loopz(2)
	macro_loopz(3)
	macro_loopz(4)
	macro_loopz(5)
	macro_loopz(6)
	macro_loopz(7)
	macro_loopz(8)
	macro_loopz(9)
	macro_loopz(10)
	macro_loopz(11)
	macro_loopz(12)
	macro_loopz(13)
	macro_loopz(14)
	macro_loopz(15)
	macro_loopz(16)
	macro_loopz(17)
	macro_loopz(18)
	macro_loopz(19)
	macro_loopz(20)
#else
    for (int i = 0; i < FIRTAPS; i++) {
        vec2 uv   = modem_uv(xy, i - FIRTAPS*0.5);
        filtered += FIR_GAIN * uv * FIR[i];
    }
#endif
    float t  = xy.x * SourceSize.x;
    float wt = t * 2. * PI / width_ratio;

    float sinwt = sin(wt);
    float coswt = cos(wt + altv);

    float luma = modulated(xy, sinwt, coswt) - FIR_INVGAIN * (filtered.x * sinwt + filtered.y * coswt);
    vec3 yuv_result = vec3(luma, filtered.x, filtered.y);

    FragColor = vec4(YUV_to_RGB * yuv_result, 1.0);
} 
#endif
