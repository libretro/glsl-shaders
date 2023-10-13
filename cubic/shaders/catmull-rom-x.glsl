#version 110
/*
   catmull-rom-x Shader

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



#define pi 3.1415926535897932384626433


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
COMPAT_VARYING vec4 t2;



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
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0      
   
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
   
    vec2 ps = SourceSize.zw;
    float dx = ps.x;
    float dy = ps.y;

    TEX0.xy = TexCoord.xy*1.0001 - vec2(0.5, 0.0)*ps;
    t1 = vec4(TEX0.xy,TEX0.xy) + vec4( -dx, 0.0,    0.0, 0.0); 
    t2 = vec4(TEX0.xy,TEX0.xy) + vec4(  dx, 0.0, 2.0*dx, 0.0);

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
COMPAT_VARYING vec4 t2;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float C_ANTI_RINGING;

#else
#define C_ANTI_RINGING     1.0      
    
#endif

// Catmull-Rom parameters
const float  B =  0.0; 
const float  C =  0.5;
/*
const mat4 INV  = mat4((-B - 6.0*C)/6.0,           (3.0*B + 12.0*C)/6.0,            (-3.0*B - 6.0*C)/6.0,             B/6.0,
                      (12.0 - 9.0*B - 6.0*C)/6.0,  (-18.0 + 12.0*B + 6.0*C)/6.0,        0.0,                        (6.0 - 2.0*B)/6.0,
                     -(12.0 - 9.0*B - 6.0*C)/6.0,  (18.0 - 15.0*B - 12.0*C)/6.0,      (3.0*B + 6.0*C)/6.0,           B/6.0,
                      (B + 6.0*C)/6.0,                 -C,                                0.0,                       0.0);
*/
// precalculated
const mat4 INV = mat4(-0.5, 1.0, -0.5, 0.0,
                       1.5,-2.5,  0.0, 1.0,
                      -1.5, 2.0,  0.5, 0.0,
                       0.5,-0.5,  0.0, 0.0 );                   

void main()
{
  vec2 fp = fract(vTexCoord*SourceSize.xy);

  vec4 C0 = COMPAT_TEXTURE(Source, t1.xy);
  vec4 C1 = COMPAT_TEXTURE(Source, t1.zw);
  vec4 C2 = COMPAT_TEXTURE(Source, t2.xy);
  vec4 C3 = COMPAT_TEXTURE(Source, t2.zw);

  vec4 Px    = vec4(fp.x*fp.x*fp.x, fp.x*fp.x, fp.x, 1.0) * INV;
  vec4 color = mat4(C0, C1, C2, C3) * Px;

    // Anti-ringing
    if (C_ANTI_RINGING == 1.0)
    {
        vec4 aux = color;
        vec4 min_sample = min(min(C0, C1), min(C2, C3));
        vec4 max_sample = max(max(C0, C1), max(C2, C3));
        color = clamp(color, min_sample, max_sample);
        color = mix(aux, color, step(0.0, (C0-C1)*(C2-C3)));
    }

   FragColor = color;
}

#endif