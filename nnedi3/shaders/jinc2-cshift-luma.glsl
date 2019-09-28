#version 130

/*
   Hyllian's jinc windowed-jinc 2-lobe with anti-ringing Shader
   
   Copyright (C) 2011-2014 Hyllian/Jararaca - sergiogdb@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

      /*
         This is an approximation of Jinc(x)*Jinc(x*r1/r2) for x < 2.5,
         where r1 and r2 are the first two zeros of jinc function.
         For a jinc 2-lobe best approximation, use A=0.5 and B=0.825.
      */  

// A=0.5, B=0.825 is the best jinc approximation for x<2.5. if B=1.0, it's a lanczos filter.
// Increase A to get more blur. Decrease it to get a sharper picture. 
// B = 0.825 to get rid of dithering. Increase B to get a fine sharpness, though dithering returns.

// Parameter lines go here:
#pragma parameter JINC2_WINDOW_SINC "Window Sinc Param" 0.44 0.0 1.0 0.01
#pragma parameter JINC2_SINC "Sinc Param" 0.82 0.0 1.0 0.01
#pragma parameter JINC2_AR_STRENGTH "Anti-ringing Strength" 0.5 0.0 1.0 0.1

#define halfpi  1.5707963267948966192313216916398
#define pi    3.1415926535897932384626433832795
#define wa    (JINC2_WINDOW_SINC*pi)
#define wb    (JINC2_SINC*pi)

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
    TEX0.xy = TexCoord.xy * 1.0001;
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
uniform COMPAT_PRECISION float JINC2_WINDOW_SINC;
uniform COMPAT_PRECISION float JINC2_SINC;
uniform COMPAT_PRECISION float JINC2_AR_STRENGTH;
#else
#define JINC2_WINDOW_SINC 0.44
#define JINC2_SINC 0.82
#define JINC2_AR_STRENGTH 0.5
#endif

// Calculates the distance between two points
float d(vec2 pt1, vec2 pt2)
{
  vec2 v = pt2 - pt1;
  return sqrt(dot(v,v));
}

float min4(float a, float b, float c, float d)
{
    return min(a, min(b, min(c, d)));
}

float max4(float a, float b, float c, float d)
{
    return max(a, max(b, max(c, d)));
}

vec4 resampler(vec4 x)
{
	vec4 res;
	res.x = (x.x==0.0) ?  wa*wb  :  sin(x.x*wa)*sin(x.x*wb)/(x.x*x.x);
	res.y = (x.y==0.0) ?  wa*wb  :  sin(x.y*wa)*sin(x.y*wb)/(x.y*x.y);
	res.z = (x.z==0.0) ?  wa*wb  :  sin(x.z*wa)*sin(x.z*wb)/(x.z*x.z);
	res.w = (x.w==0.0) ?  wa*wb  :  sin(x.w*wa)*sin(x.w*wb)/(x.w*x.w);
	return res;
}

void main()
{
	  float color;
	  mat4x4 weights;

	  vec2 dx = vec2(1.0, 0.0);
	  vec2 dy = vec2(0.0, 1.0);

	  //Correct NNEDI3's center shift
	  vec2 pc = vec2(((vTexCoord.x / SourceSize.z) - 0.5), ((vTexCoord.y / SourceSize.w) - 0.5));
	  
	  vec2 tc = (floor(pc-vec2(0.5,0.5))+vec2(0.5,0.5));
	 
	  weights[0] = resampler(vec4(d(pc, tc    -dx    -dy), d(pc, tc           -dy), d(pc, tc    +dx    -dy), d(pc, tc+2.0*dx    -dy)));
	  weights[1] = resampler(vec4(d(pc, tc    -dx       ), d(pc, tc              ), d(pc, tc    +dx       ), d(pc, tc+2.0*dx       )));
	  weights[2] = resampler(vec4(d(pc, tc    -dx    +dy), d(pc, tc           +dy), d(pc, tc    +dx    +dy), d(pc, tc+2.0*dx    +dy)));
	  weights[3] = resampler(vec4(d(pc, tc    -dx+2.0*dy), d(pc, tc       +2.0*dy), d(pc, tc    +dx+2.0*dy), d(pc, tc+2.0*dx+2.0*dy)));

	  dx = dx * SourceSize.zw;
	  dy = dy * SourceSize.zw;
	  tc = tc * SourceSize.zw;
	 
	 // reading the texels
	 
	  float c00 = COMPAT_TEXTURE(Source, tc    -dx    -dy).x;
	  float c10 = COMPAT_TEXTURE(Source, tc           -dy).x;
	  float c20 = COMPAT_TEXTURE(Source, tc    +dx    -dy).x;
	  float c30 = COMPAT_TEXTURE(Source, tc+2.0*dx    -dy).x;
	  float c01 = COMPAT_TEXTURE(Source, tc    -dx       ).x;
	  float c11 = COMPAT_TEXTURE(Source, tc              ).x;
	  float c21 = COMPAT_TEXTURE(Source, tc    +dx       ).x;
	  float c31 = COMPAT_TEXTURE(Source, tc+2.0*dx       ).x;
	  float c02 = COMPAT_TEXTURE(Source, tc    -dx    +dy).x;
	  float c12 = COMPAT_TEXTURE(Source, tc           +dy).x;
	  float c22 = COMPAT_TEXTURE(Source, tc    +dx    +dy).x;
	  float c32 = COMPAT_TEXTURE(Source, tc+2.0*dx    +dy).x;
	  float c03 = COMPAT_TEXTURE(Source, tc    -dx+2.0*dy).x;
	  float c13 = COMPAT_TEXTURE(Source, tc       +2.0*dy).x;
	  float c23 = COMPAT_TEXTURE(Source, tc    +dx+2.0*dy).x;
	  float c33 = COMPAT_TEXTURE(Source, tc+2.0*dx+2.0*dy).x;

	  //  Get min/max samples
	  float min_sample = min4(c11, c21, c12, c22);
	  float max_sample = max4(c11, c21, c12, c22);

      color = dot(vec4(c00, c10, c20, c30), weights[0]);
      color += dot(vec4(c01, c11, c21, c31), weights[1]);
      color += dot(vec4(c02, c12, c22, c32), weights[2]);
      color += dot(vec4(c03, c13, c23, c33), weights[3]);
	  color = color/(dot(weights * vec4(1.0), vec4(1.0)));

	  // Anti-ringing
	  float aux = color;
	  color = clamp(color, min_sample, max_sample);

	  color = mix(aux, color, JINC2_AR_STRENGTH);

	  // final sum and weight normalization
	  FragColor = vec4(color, 1.0, 1.0, 1.0);
} 
#endif
