#version 110
/*
   Simple S-video like shader by DariusG 2023
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter CHR_BLUR "CHROMA RESOLUTION" 1.5 1.0 10.0 0.1
#pragma parameter L_BLUR "LUMA RESOLUTION" 8.0 2.0 10.0 0.25
#pragma parameter CHROMA_SATURATION "CHROMA SATURATION" 5.0 0.0 15.0 0.1
#pragma parameter BRIGHTNESS "LUMA BRIGHTNESS" 0.55 0.0 2.0 0.01
#pragma parameter IHUE "I SHIFT (blue to orange)" 0.0 -1.0 1.0 0.01
#pragma parameter QHUE "Q SHIFT (green to purple)" 0.0 -1.0 1.0 0.01

// https://www.shadertoy.com/view/wlBcWG
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
uniform COMPAT_PRECISION float CHR_BLUR;
uniform COMPAT_PRECISION float L_BLUR;
uniform COMPAT_PRECISION float CHROMA_SATURATION;
uniform COMPAT_PRECISION float BRIGHTNESS;
uniform COMPAT_PRECISION float IHUE;
uniform COMPAT_PRECISION float QHUE;


#else
#define CHR_BLUR 4.0
#define L_BLUR 12.0
#define CHROMA_SATURATION 7.0
#define BRIGHTNESS 10.0
#define IHUE 0.0
#define QHUE 0.0
#endif

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693
#define FSC  3.57945*4.0

// Size of the decoding FIR filter
#define FIR_SIZE 20

// YIQ to RGB matrices
const mat3 yiq_to_rgb = mat3(1.000, 1.000, 1.000,
                             0.956,-0.272,-1.106,
                             0.621,-0.647, 1.703);

const mat3 rgb_to_yiq = mat3(0.299, 0.596, 0.211,
                             0.587,-0.274,-0.523,
                             0.114,-0.322, 0.312);

float blackman(float n, float N) {
    float a0 = (1.0 - 0.16) / 2.0;
    float a1 = 1.0 / 2.0;
    float a2 = 0.16 / 2.0;
    
    return a0 - (a1 * cos((2.0 * PI * n) / N)) + (a2 * cos((4.0 * PI * n) / N));
}

void main() {
// moved due to GLES fix. 
mat3 mix_mat = mat3(
    1.0, 0.0, 0.0,
    IHUE, 1.0, 0.0,
    QHUE, 0.0, 1.0
);

    // Chroma decoder oscillator frequency
    float fc = SourceSize.x*TAU;

    float counter = 0.0;
    vec3 yiq = vec3(0.0);

for (int d = -FIR_SIZE; d < FIR_SIZE; d++) {
        //luma encode/decode
        vec2 pos = vec2((vTexCoord.x + (float(d)/2.0/L_BLUR)*SourceSize.z), vTexCoord.y);
        vec3 s = COMPAT_TEXTURE(Source, pos).rgb; 
        s = rgb_to_yiq*s;
        // encode end
        // decode
        // Apply Blackman window for smoother colors
        float window = blackman(float(d/2 + 5), float(FIR_SIZE/2)); 

        yiq.r += s.r * BRIGHTNESS * window;

        // chroma encode/decode
        pos = vec2(vTexCoord.x + (float(d)/CHR_BLUR)*SourceSize.z, vTexCoord.y);
        s = COMPAT_TEXTURE(Source, pos).rgb;
        s = rgb_to_yiq*s;

        s.yz *= vec2(cos(fc*vTexCoord.x+11.0*PI/60.0),sin(fc*vTexCoord.x+11.0*PI/60.0)); 
        // encode end
        float wt = fc * (vTexCoord.x - float(d)*SourceSize.z);
        // decode
        // Apply Blackman window for smoother colors
        window = blackman(float(d + FIR_SIZE), float(FIR_SIZE * 2 + 1)); 

        yiq.yz += s.yz * vec2(cos(wt+11.0*PI/60.0), sin(wt+11.0*PI/60.0)) * window;

        counter++;
    }

    yiq.yz /= counter;
    yiq.r /= counter/4.0;

    // Saturate chroma (IQ)
    yiq.yz *= CHROMA_SATURATION;
    yiq *= mix_mat;
    FragColor = vec4((yiq_to_rgb * yiq), 1.0);
}
#endif
