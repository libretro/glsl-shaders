/*
   SameBoy LCD shader
   Author: LIJI32
   License: MIT

   Copyright (c) 2015-2016 Lior Halphon

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/

#pragma parameter COLOR_LOW "Color Low" 0.8 0.0 1.5 0.05
#pragma parameter COLOR_HIGH "Color High" 1.0 0.0 1.5 0.05
#pragma parameter SCANLINE_DEPTH "Scanline Depth" 0.1 0.0 2.0 0.05

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
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
uniform COMPAT_PRECISION float COLOR_LOW;
uniform COMPAT_PRECISION float COLOR_HIGH;
uniform COMPAT_PRECISION float SCANLINE_DEPTH;
#else
#define COLOR_LOW 0.8
#define COLOR_HIGH 1.0
#define SCANLINE_DEPTH 0.1
#endif

void main()
{
    vec2 pos = fract(vTexCoord * SourceSize.xy);
    vec2 sub_pos = fract(vTexCoord * SourceSize.xy * 6.0);
    
    vec4 center = COMPAT_TEXTURE(Source, vTexCoord);
    vec4 left = COMPAT_TEXTURE(Source, vTexCoord - vec2(1.0 / SourceSize.x, 0.0));
    vec4 right = COMPAT_TEXTURE(Source, vTexCoord + vec2(1.0 / SourceSize.x, 0.0));
    
    if (pos.y < 1.0 / 6.0) {
        center = mix(center, COMPAT_TEXTURE(Source, vTexCoord + vec2(0.0, -1.0 / SourceSize.y)), 0.5 - sub_pos.y / 2.0);
        left =   mix(left,   COMPAT_TEXTURE(Source, vTexCoord + vec2(-1.0 / SourceSize.x, -1.0 / SourceSize.y)), 0.5 - sub_pos.y / 2.0);
        right =  mix(right,  COMPAT_TEXTURE(Source, vTexCoord + vec2( 1.0 / SourceSize.x, -1.0 / SourceSize.y)), 0.5 - sub_pos.y / 2.0);
        center *= sub_pos.y * SCANLINE_DEPTH + (1.0 - SCANLINE_DEPTH);
        left *= sub_pos.y * SCANLINE_DEPTH + (1.0 - SCANLINE_DEPTH);
        right *= sub_pos.y * SCANLINE_DEPTH + (1.0 - SCANLINE_DEPTH);
    }
    else if (pos.y > 5.0 / 6.0) {
        center = mix(center, COMPAT_TEXTURE(Source, vTexCoord + vec2(0, 1.0 / SourceSize.y)), sub_pos.y / 2.0);
        left =   mix(left,   COMPAT_TEXTURE(Source, vTexCoord + vec2(-1.0 / SourceSize.x, 1.0 / SourceSize.y)), sub_pos.y / 2.0);
        right =  mix(right,  COMPAT_TEXTURE(Source, vTexCoord + vec2( 1.0 / SourceSize.x, 1.0 / SourceSize.y)), sub_pos.y / 2.0);
        center *= (1.0 - sub_pos.y) * SCANLINE_DEPTH + (1.0 - SCANLINE_DEPTH);
        left *= (1.0 - sub_pos.y) * SCANLINE_DEPTH + (1.0 - SCANLINE_DEPTH);
        right *= (1.0 - sub_pos.y) * SCANLINE_DEPTH + (1.0 - SCANLINE_DEPTH);
    }
    
    
    vec4 midleft = mix(left, center, 0.5);
    vec4 midright = mix(right, center, 0.5);
    
    vec4 ret;
    if (pos.x < 1.0 / 6.0) {
        ret = mix(vec4(COLOR_HIGH * center.r, COLOR_LOW * center.g, COLOR_HIGH * left.b, 1.0),
                  vec4(COLOR_HIGH * center.r, COLOR_LOW * center.g, COLOR_LOW  * left.b, 1.0),
                  sub_pos.x);
    }
    else if (pos.x < 2.0 / 6.0) {
        ret = mix(vec4(COLOR_HIGH * center.r, COLOR_LOW  * center.g, COLOR_LOW * left.b, 1.0),
                  vec4(COLOR_HIGH * center.r, COLOR_HIGH * center.g, COLOR_LOW * midleft.b, 1.0),
                  sub_pos.x);
    }
    else if (pos.x < 3.0 / 6.0) {
        ret = mix(vec4(COLOR_HIGH * center.r  , COLOR_HIGH * center.g, COLOR_LOW * midleft.b, 1.0),
                  vec4(COLOR_LOW  * midright.r, COLOR_HIGH * center.g, COLOR_LOW * center.b, 1.0),
                  sub_pos.x);
    }
    else if (pos.x < 4.0 / 6.0) {
        ret = mix(vec4(COLOR_LOW * midright.r, COLOR_HIGH * center.g , COLOR_LOW  * center.b, 1.0),
                  vec4(COLOR_LOW * right.r   , COLOR_HIGH  * center.g, COLOR_HIGH * center.b, 1.0),
                  sub_pos.x);
    }
    else if (pos.x < 5.0 / 6.0) {
        ret = mix(vec4(COLOR_LOW * right.r, COLOR_HIGH * center.g  , COLOR_HIGH * center.b, 1.0),
                  vec4(COLOR_LOW * right.r, COLOR_LOW  * midright.g, COLOR_HIGH * center.b, 1.0),
                  sub_pos.x);
    }
    else {
        ret = mix(vec4(COLOR_LOW  * right.r, COLOR_LOW * midright.g, COLOR_HIGH * center.b, 1.0),
                  vec4(COLOR_HIGH * right.r, COLOR_LOW * right.g  ,  COLOR_HIGH * center.b, 1.0),
                  sub_pos.x);
    }
    
    FragColor = ret;
} 
#endif
