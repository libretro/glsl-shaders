#version 110

/*
   Kaizer-window customizable by DariusG 2024.
   
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


#pragma parameter s " Sampling Rate [Hz] x" 4.0 1.0 8.0 1.0
#pragma parameter sy " Sampling Rate [Hz] y "8.0 1.0 8.0 1.0
#pragma parameter fL " Cutoff frequency fL [Hz] x " 1.9 0.01 8.0 0.01
#pragma parameter fLy " Cutoff frequency fL [Hz] y " 0.10 0.01 8.0 0.01
#pragma parameter l " Filter Length x" 7.0 1.0 33.0 2.0
#pragma parameter ly " Filter Length y" 2.0 1.0 33.0 1.0

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
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float fL;
uniform COMPAT_PRECISION float fLy;
uniform COMPAT_PRECISION float l;
uniform COMPAT_PRECISION float ly;
uniform COMPAT_PRECISION float s;
uniform COMPAT_PRECISION float sy;

#else
#define fL 0.2
#define fLy 0.2
#define l 1.0
#define ly 1.0
#define s 1.0
#define sy 1.0
#endif

// Configuration.
#define fS  int(s)  // Sampling rate.
#define leng  int(l) // Filter length, must be odd.
#define lengy  int(ly) // Filter length, must be odd.

float kaizer_x (float N, float p)
{
    // Compute sinc filter.
    float k = sin(2.0 * fL / s * (N - (p - 1.0) / 2.0));
    return k;
}
float kaizer_y (float N, float p)
{
    // Compute sinc filter.
    float k = sin(2.0 * fLy / sy * (N - (p - 1.0) / 2.0));
    return k;
}

void main()
{

float sum = 0.0;
vec3 res = vec3(0.0);
vec2 dx = vec2(SourceSize.z/s,0.0);
vec2 dy = vec2(0.0,SourceSize.w/sy);
vec2 xy = vTexCoord;
xy -= dx*l;

for (int i=0; i<leng; i++)
{
    float p = float (i);
    res += COMPAT_TEXTURE(Source,xy + dx*p).rgb*kaizer_x(float(leng),p);
    sum += kaizer_x(float(leng),p);
}
for (int i=0; i<lengy; i++)
{
    float p = float (i);
    res += COMPAT_TEXTURE(Source,xy + dy*p).rgb*kaizer_y(float(lengy),p);
    sum += kaizer_y(float(lengy),p);
}
    res /= sum;

    FragColor.rgb = res;
}
#endif

