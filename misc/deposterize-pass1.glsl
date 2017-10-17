/*
   Hyllian's Deposterize Shader - Pass1
   
   Copyright (C) 2011/2016 Hyllian/Jararaca - sergiogdb@gmail.com

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

// Parameter lines go here:
#pragma parameter EQ_THRESH2 "Eq Limit Vertical" 0.01 0.0 1.0 0.01
#pragma parameter DIFF_THRESH2 "Diff Limit Vertical" 0.06 0.0 1.0 0.01

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

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy * 1.0001;

	vec2 ps = vec2(SourceSize.zw);
	float dx = ps.x;
	float dy = ps.y;
	t1 = vTexCoord.xyyy + vec4(   0, -dy, 0,  dy); //  B  E  H
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float EQ_THRESH2;
uniform COMPAT_PRECISION float DIFF_THRESH2;
#else
#define EQ_THRESH2 0.01
#define DIFF_THRESH2 0.06
#endif

#define EQ   EQ_THRESH2
#define DF  DIFF_THRESH2

vec3 df3(vec3 c1, vec3 c2)
{
      return abs(c1 - c2);
}

bvec3 eq3(vec3 A, vec3 B)
{
	return lessThanEqual(df3(A, B) , vec3(EQ));
}

void main()
{
	vec3 res;

	vec3 B  = COMPAT_TEXTURE(Source, t1.xy).rgb;
	vec3 E  = COMPAT_TEXTURE(Source, t1.xz).rgb;
	vec3 H  = COMPAT_TEXTURE(Source, t1.xw).rgb;
	
	bvec3 test1 = eq3(B, H);
	bvec3 test2 = eq3(B, E);
	bvec3 test3 = eq3(E, H);
	
	bvec3 test4 = lessThanEqual(df3(E, H) , vec3(DF, DF, DF));
	bvec3 test5 = lessThanEqual(df3(B, E) , vec3(DF, DF, DF));

	res = ((test1 == bvec3(false)) && ((test4 == bvec3(true)) && (test2 == bvec3(true)) || (test5 == bvec3(true)) && (test3 == bvec3(true)))) ? 0.5*(B+H) : E;

	FragColor = vec4(res, 1.0);
} 
#endif
