#version 120

/*
   Hyllian's crt-nobody Shader
   
   Copyright (C) 2011-2022 Hyllian - sergiogdb@gmail.com

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

#pragma parameter VSCANLINES   "Vertical Scanlines"  0.0   0.0   1.0 1.0
#pragma parameter SCAN_SIZE    "Scanlines Size"      0.86  0.0   2.0 0.01
#pragma parameter COLOR_BOOST  "Color Boost"         1.25  1.0   2.0 0.05
#pragma parameter InputGamma   "INPUT GAMMA"         2.4   0.0   4.0 0.1
#pragma parameter OutputGamma  "OUTPUT GAMMA"        2.2   0.0   3.0 0.1

#define PIX_SIZE    1.11

#define saturate(c) clamp(c, 0.0, 1.0)
#define lerp(a,b,c) mix(a,b,c)
#define mul(a,b) (b*a)
#define fmod(c,d) mod(c,d)
#define frac(c) fract(c)
#define tex2D(c,d) COMPAT_TEXTURE(c,d)
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define int2 ivec2
#define int3 ivec3
#define int4 ivec4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4
#define float2x2 mat2x2
#define float3x3 mat3x3
#define float4x4 mat4x4

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
COMPAT_VARYING vec4 t1;
COMPAT_VARYING float pix_sizex;
COMPAT_VARYING float scan_sizey;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float VSCANLINES;
uniform COMPAT_PRECISION float SCAN_SIZE;
uniform COMPAT_PRECISION float COLOR_BOOST;
uniform COMPAT_PRECISION float InputGamma;
uniform COMPAT_PRECISION float OutputGamma;
#else
#define VSCANLINES  0.0
#define SCAN_SIZE   0.86
#define COLOR_BOOST 1.25
#define InputGamma  2.4
#define OutputGamma 2.2
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy * 1.0001;

    pix_sizex  = mix(PIX_SIZE, SCAN_SIZE, VSCANLINES);
    scan_sizey = mix(SCAN_SIZE, PIX_SIZE, VSCANLINES);
   
    float2 ps = float2(SourceSize.z, SourceSize.w);
	float dx = ps.x;
	float dy = ps.y;

	t1.xy = float2( dx,  0.); // F
	t1.zw = float2(  0., dy); // H
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
COMPAT_VARYING vec4 t1;
COMPAT_VARYING float pix_sizex;
COMPAT_VARYING float scan_sizey;


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float VSCANLINES;
uniform COMPAT_PRECISION float SCAN_SIZE;
uniform COMPAT_PRECISION float COLOR_BOOST;
uniform COMPAT_PRECISION float InputGamma;
uniform COMPAT_PRECISION float OutputGamma;
#else
#define VSCANLINES  0.0
#define SCAN_SIZE   0.86
#define COLOR_BOOST 1.25
#define InputGamma  2.4
#define OutputGamma 2.2
#endif

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#define decal Source

#define GAMMA_IN(color)     pow(color, float3(InputGamma, InputGamma, InputGamma))
#define GAMMA_OUT(color)    pow(color, float3(1.0 / OutputGamma, 1.0 / OutputGamma, 1.0 / OutputGamma))

float wgt(float size)
{
   size = clamp(size, -1.0, 1.0);

   size = 1.0 - size * size;

   return size * size * size;
}


void main()
{
    float2 pos = frac(vTexCoord*SourceSize.xy)-float2(0.5, 0.5); // pos = pixel position
    float2 dir = sign(pos); // dir = pixel direction
    pos        = abs(pos);

    float2 g1 = dir*t1.xy;
    float2 g2 = dir*t1.zw;

    float3 A = GAMMA_IN(tex2D(decal, vTexCoord       ).xyz);
    float3 B = GAMMA_IN(tex2D(decal, vTexCoord +g1   ).xyz);
    float3 C = GAMMA_IN(tex2D(decal, vTexCoord    +g2).xyz);
    float3 D = GAMMA_IN(tex2D(decal, vTexCoord +g1+g2).xyz);

    float2 dx = float2(pos.x, 1.0-pos.x) / pix_sizex;
    float2 dy = float2(pos.y, 1.0-pos.y) / scan_sizey;

    float2 wx = float2(wgt(dx.x), wgt(dx.y));
    float2 wy = float2(wgt(dy.x), wgt(dy.y));

    float3 color = (A*wx.x + B*wx.y)*wy.x + (C*wx.x + D*wx.y)*wy.y;

    color *= COLOR_BOOST;

    color  = GAMMA_OUT(color);

    FragColor = vec4(color, 1.0);
} 
#endif
