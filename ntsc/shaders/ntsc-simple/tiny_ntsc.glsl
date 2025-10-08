#version 110

/*
   TINY_NTSC DariusG 2025 

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/
#pragma parameter u_comb "Comb Filter Strength" 0.7 0.0 1.0 0.05
#pragma parameter LPY "Luma Bandwidth" 1.3 0.0 2.0 0.02
#pragma parameter LPC "Chroma Bandwidth" 0.1 0.0 1.0 0.01
#pragma parameter c_gain "Chroma Gain" 1.5 0.0 3.0 0.05
#pragma parameter d_crawl "Dot Crawl" 1.0 0.0 1.0 1.0

#define PI 3.1415926
#define TAU 6.2831852
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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING float maskpos;

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
    scale = SourceSize.xy/InputSize.xy;
    ogl2pos = TEX0.xy*TextureSize;
    maskpos = TEX0.x*OutputSize.x*scale.x;
    invdims = 1.0/TextureSize;
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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float maskpos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 ogl2pos;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float u_comb;
uniform COMPAT_PRECISION float c_gain;
uniform COMPAT_PRECISION float LPY;
uniform COMPAT_PRECISION float LPC;
uniform COMPAT_PRECISION float d_crawl;
#else
#define u_comb 0.7
#define c_gain 1.5
#define LPY 0.4
#define LPC 0.2
#define d_crawl 1.0

#endif

#define phase_choose  (InputSize.x < 300.0 ? 3.0 :2.0)
#define h_phase_choose  (InputSize.x < 300.0 ? 1.0 :2.0)
#define gamma(c) c*c

#define timer (d_crawl== 1.0? mod(float(FrameCount),2.0)*TAU/phase_choose : 0.0)

vec3 rgb2yiq(vec3 rgb) {
    float y = dot(rgb, vec3(0.299, 0.587, 0.114));
    float i = dot(rgb, vec3(0.595716, -0.274453, -0.321263));
    float q = dot(rgb, vec3(0.211456, -0.522591, 0.311135));
    return vec3(y, i, q);
}
vec3 yiq2rgb(vec3 yiq) {
    float r = yiq.x + 0.9563 * yiq.y + 0.6210 * yiq.z;
    float g = yiq.x - 0.2721 * yiq.y - 0.6474 * yiq.z;
    float b = yiq.x - 1.1070 * yiq.y + 1.7046 * yiq.z;
    return vec3(r, g, b);
}

void main()
{
    vec3 final = vec3(0.0);
    float sumY = 0.0;
    float sumC = 0.0;
    vec2 dx = vec2(invdims.x,0.0);
    vec2 dy = vec2(0.0,invdims.y*0.25);
    float line_phase =  mod(floor(ogl2pos.y),phase_choose)*TAU/phase_choose;
// minimalistic 3 passes for performance
    for (int i=-1; i<2; i++)
    {
        float n = float(i);
        float wY = exp(-LPY*n*n);
        float wC = exp(-LPC*n*n);
        // we'll always have 170.666 color samples per line (3.579545 mhz)
        // fix retroarch glsl vTexCoord [0.0,1.0] by multiplying "scale"
        float phase = ((vTexCoord.x + n*invdims.x)*scale.x*170.666 )*TAU/h_phase_choose;
        phase += timer;
        phase += line_phase;
        float cs = cos(phase);
        float sn = sin(phase);
        vec3 burst1 = vec3(1.0, cs, sn);
        vec3 burst2 = vec3(1.0,-cs,-sn);
        vec3 res1 = rgb2yiq(COMPAT_TEXTURE(Source,vTexCoord + n*dx).rgb); 
        vec3 res2 = rgb2yiq(COMPAT_TEXTURE(Source,vTexCoord + n*dx - dy).rgb); 
        res1 *= burst1;   
        res2 *= burst2;   
        float comp1 = dot(vec3(1.0),res1);
        float comp2 = dot(vec3(1.0),res2);
        // comb filter
        float luma = (comp1+comp2)*0.5; // chroma cancelled!
        final.r += luma*wY;
        vec2 chroma = (comp1-luma*u_comb)*wC*burst1.gb*c_gain;
        final.g += chroma.x;
        final.b += chroma.y + chroma.x*0.15; // bleed some I to Q

        sumY += wY;
        sumC += wC;
    }
    final.r /= sumY;
    final.gb /= sumC;
    FragColor.rgb = yiq2rgb(final);
}
#endif
