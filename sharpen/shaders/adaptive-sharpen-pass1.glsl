#version 130

/* Ported by Hyllian and hunterk - 2015 / 2017 */

// Copyright (c) 2015-2017, bacondither
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// First pass, MUST BE PLACED IMMEDIATELY BEFORE THE SECOND PASS IN THE CHAIN

// Adaptive sharpen - version 2017-04-11 - (requires ps >= 3.0)
// Tuned for use post-resize, EXPECTS FULL RANGE GAMMA LIGHT

// Compatibility defines:
#define mul(a,b) (b*a)
#define saturate(c) clamp(c, 0.0, 1.0)

//-------------------------------------------------------------------------------------------------
#define w_offset        1.0                  // Edge channel offset, must be the same in all passes
//-------------------------------------------------------------------------------------------------

// Get destination pixel values
#define get(x,y)    ( saturate(COMPAT_TEXTURE(Source, coord + vec2(x*(px), y*(py))).rgb) )

// Component-wise distance
#define b_diff(pix) ( abs(blur - c##pix) )

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

vec4 frag_op(sampler2D Source, vec2 coord, float px, float py)
{
	// Get points and clip out of range values (BTB & WTW)
	// [                c9                ]
	// [           c1,  c2,  c3           ]
	// [      c10, c4,  c0,  c5, c11      ]
	// [           c6,  c7,  c8           ]
	// [                c12               ]
//	vec3 c[13] = vec3[]( get( 0., 0.), get(-1.,-1.), get( 0.,-1.), get( 1.,-1.), get(-1., 0.),
//	                 get( 1., 0.), get(-1., 1.), get( 0., 1.), get( 1., 1.), get( 0.,-2.),
//	                 get(-2., 0.), get( 2., 0.), get( 0., 2.) );
	vec3 c0 = get( 0., 0.);
	vec3 c1 = get(-1.,-1.);
	vec3 c2 = get( 0.,-1.);
	vec3 c3 = get( 1.,-1.);
	vec3 c4 = get(-1., 0.);
	vec3 c5 = get( 1., 0.);
	vec3 c6 = get(-1., 1.);
	vec3 c7 = get( 0., 1.);
	vec3 c8 = get( 1., 1.);
	vec3 c9 = get( 0.,-2.);
	vec3 c10 = get(-2., 0.);
	vec3 c11 = get( 2., 0.);
	vec3 c12 = get( 0., 2.);

	// Blur, gauss 3x3
	vec3 blur  = (2.*(c2+c4+c5+c7) + (c1+c3+c6+c8) + 4.*c0)/16.;
	float blur_Y = (blur.r/3. + blur.g/3. + blur.b/3.);

	// Contrast compression, center = 0.5, scaled to 1/3
	float c_comp = saturate(0.266666681 + 0.9*exp2(-7.4*blur_Y));

	// Edge detection
	// Relative matrix weights
	// [          1,         ]
	// [      4,  5,  4      ]
	// [  1,  5,  6,  5,  1  ]
	// [      4,  5,  4      ]
	// [          1          ]
	float edge = length( 1.38*(b_diff(0))
	                   + 1.15*(b_diff(2) + b_diff(4)  + b_diff(5)  + b_diff(7))
	                   + 0.92*(b_diff(1) + b_diff(3)  + b_diff(6)  + b_diff(8))
	                   + 0.23*(b_diff(9) + b_diff(10) + b_diff(11) + b_diff(12)) );

	return vec4( (COMPAT_TEXTURE(Source, coord).rgb), (edge*c_comp + w_offset) );
}

void main()
{
	vec2 tex = vTexCoord;

	float px = 1.0 / SourceSize.x;
	float py = 1.0 / SourceSize.y;

	FragColor = vec4(frag_op(Source, tex, px, py));
} 
#endif
