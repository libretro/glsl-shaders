#version 120

/*
   Hyllian's Fast Bilateral 3D Shader
   
   Copyright (C) 2011/2016 Hyllian - sergiogdb@gmail.com

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

// Parameter lines go here:
#pragma parameter FB_RES "Bilateral Internal Res" 2.0 1.0 8.0 1.0
#pragma parameter SIGMA_R "Bilateral Blur" 0.4 0.0 2.0 0.1
#pragma parameter SIGMA_D "Bilateral Space" 3.0 0.0 10.0 0.2
// END PARAMETERS //

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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform float FB_RES;
uniform float SIGMA_R;
uniform float SIGMA_D;
#else
#define FB_RES 2.0
#define SIGMA_R 0.4
#define SIGMA_D 3.0
#endif

#define GET(M,K) (COMPAT_TEXTURE(Source,tc+M*dx+K*dy).xyz)

#define BIL(M,K) {\
	col=GET(M,K);\
	ds=M*M+K*K;\
	weight=exp(-ds/sd2)*exp(-(col-center)*(col-center)/si2);\
	color+=(weight*col);\
	wsum+=weight;\
	}

void main()
{
      float ds, sd2, si2;
      float sigma_d = SIGMA_D;
      float sigma_r = SIGMA_R*0.04;

      vec3 color = vec3(0.0, 0.0, 0.0);
      vec3 wsum = vec3(0.0, 0.0, 0.0);
      vec3 weight;

      vec2 dx = vec2(FB_RES, 0.0) * SourceSize.zw;
      vec2 dy = vec2(0.0, FB_RES) * SourceSize.zw;

      sd2 = 2.0 * sigma_d * sigma_d;
      si2 = 2.0 * sigma_r * sigma_r;

      vec2 tc = vTexCoord;

      vec3 col;
      vec3 center = GET(0,0);
     // center = sqrt(center);

      BIL(-2,-2)
      BIL(-1,-2)
      BIL( 0,-2)
      BIL( 1,-2)
      BIL( 2,-2)
      BIL(-2,-1)
      BIL(-1,-1)
      BIL( 0,-1)
      BIL( 1,-1)
      BIL( 2,-1)
      BIL(-2, 0)
      BIL(-1, 0)
      BIL( 0, 0)
      BIL( 1, 0)
      BIL( 2, 0)
      BIL(-2, 1)
      BIL(-1, 1)
      BIL( 0, 1)
      BIL( 1, 1)
      BIL( 2, 1)
      BIL(-2, 2)
      BIL(-1, 2)
      BIL( 0, 2)
      BIL( 1, 2)
      BIL( 2, 2)

      // Weight normalization
      color /= wsum;

      FragColor = vec4(color, 1.);
} 
#endif
