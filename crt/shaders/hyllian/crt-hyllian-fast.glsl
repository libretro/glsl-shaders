/*
   Hyllian's CRT Shader
   with cgwg's magenta/green dotmask
   ported to GLSL by metallic77
  
   Copyright (C) 2011-2015 Hyllian - sergiogdb@gmail.com

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

#pragma parameter SHARPNESS "SHARPNESS" 1.0 1.0 2.0 1.0
#pragma parameter MASK_INTENSITY "MASK INTENSITY" 0.5 0.0 1.0 0.1
#pragma parameter InputGamma "INPUT GAMMA" 2.4 0.0 5.0 0.1
#pragma parameter OutputGamma "OUTPUT GAMMA" 2.2 0.0 5.0 0.1
#pragma parameter BRIGHTBOOST "BRIGHT BOOST" 1.5 0.0 2.0 0.1
#pragma parameter SCANLINES "SCANLINES STRENGTH" 0.72 0.0 1.0 0.02

#define GAMMA_IN(color)     pow(color, vec3(InputGamma, InputGamma, InputGamma))
#define GAMMA_OUT(color)    pow(color, vec3(1.0 / OutputGamma, 1.0 / OutputGamma, 1.0 / OutputGamma))

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
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 ps;

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
uniform COMPAT_PRECISION float SHARPNESS;
#else
#define SHARPNESS 1.0
#endif

void main()
{
   gl_Position = MVPMatrix * VertexCoord;
   vec2 tex_size = vec2(TextureSize.x * SHARPNESS, TextureSize.y);
   ps = 1.0/tex_size;
   TEX0.xy = TexCoord.xy + ps * vec2(-0.49999, 0.0);
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
COMPAT_VARYING vec2 ps;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float MASK_INTENSITY;
uniform COMPAT_PRECISION float InputGamma;
uniform COMPAT_PRECISION float OutputGamma;
uniform COMPAT_PRECISION float BRIGHTBOOST;
uniform COMPAT_PRECISION float SCANLINES;
#else
#define MASK_INTENSITY 0.5
#define InputGamma 2.4
#define OutputGamma 2.2
#define BRIGHTBOOST 0.0
#define SCANLINES 0.5
#endif

void main()
{
   vec2 dx = vec2(ps.x, 0.0);
   vec2 dy = vec2(0.0, ps.y);
   
   vec2 tc = (floor(vTexCoord.xy * SourceSize.xy) + vec2(0.49999, 0.49999)) / SourceSize.xy;
   
   vec2 fp = fract(vTexCoord.xy * SourceSize.xy);
   
   vec3 c10 = COMPAT_TEXTURE(Source, tc -       dx).xyz;
   vec3 c11 = COMPAT_TEXTURE(Source, tc           ).xyz;
   vec3 c12 = COMPAT_TEXTURE(Source, tc +       dx).xyz;
   vec3 c13 = COMPAT_TEXTURE(Source, tc + 2.0 * dx).xyz;
	
   vec4 lobes = vec4(fp.x*fp.x*fp.x, fp.x*fp.x, fp.x, 1.0);

   vec4 InvX = vec4(0.0);
// Horizontal cubic filter
    InvX.x = dot(vec4( -0.5, 1.0, -0.5, 0.0), lobes);
    InvX.y = dot(vec4(  1.5,-2.5,  0.0, 1.0), lobes);
    InvX.z = dot(vec4( -1.5, 2.0,  0.5, 0.0), lobes);
    InvX.w = dot(vec4(  0.5,-0.5,  0.0, 0.0), lobes);
	
    vec3 color = InvX.x*c10.xyz;
		 color+= InvX.y*c11.xyz;
		 color+= InvX.z*c12.xyz;
		 color+= InvX.w*c13.xyz;
	
	
	color = GAMMA_IN(color);
	
    float pos1 = 1.5-SCANLINES - abs(fp.y - 0.5);
    float d1 = max(0.0, min(1.0, pos1));
    float d = d1*d1*(3.0+BRIGHTBOOST - (2.0*d1));
	
    color = color*d;
    
// dotmask
    float mod_factor = TEX0.x * OutputSize.x * TextureSize.x / InputSize.x;
    vec4 dotMaskWeights = mix(
                                 vec4(1.0, 1.0-MASK_INTENSITY, 1.0, 1.),
                                 vec4(1.0-MASK_INTENSITY, 1.0, 1.0-MASK_INTENSITY, 1.),
                                 floor(mod(mod_factor, 2.0))
                                  );
    color *=vec3(dotMaskWeights.x,dotMaskWeights.y,dotMaskWeights.z);

    color  = GAMMA_OUT(color);
    FragColor = vec4(color.r, color.g, color.b, 1.0);
} 
#endif
