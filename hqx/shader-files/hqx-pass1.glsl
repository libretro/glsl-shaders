/*
* Copyright (C) 2003 Maxim Stepin ( maxst@hiend3d.com )
*
* Copyright (C) 2010 Cameron Zemek ( grom@zeminvaders.net )
*
* Copyright (C) 2014 Jules Blok ( jules@aerix.nl )
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter trY "Y Threshold" 48.0 0.0 255.0 1.0
#pragma parameter trU "U Threshold" 7.0 0.0 255.0 1.0
#pragma parameter trV "V Threshold" 6.0 0.0 255.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float trY;
uniform COMPAT_PRECISION float trU;
uniform COMPAT_PRECISION float trV;
#else
#define trY 48.0
#define trU 7.0
#define trV 6.0
#endif

#ifdef GL_ES
vec3 yuv_threshold = vec3(0.188235294, 0.02745098, 0.023529412);
#else
vec3 yuv_threshold = vec3(trY/255.0, trU/255.0, trV/255.0);
#endif
const mat3 yuv = mat3(0.299, -0.169, 0.5, 0.587, -0.331, -0.419, 0.114, 0.5, -0.081);
const vec3 yuv_offset = vec3(0.0, 0.5, 0.5);

bool diff(vec3 yuv1, vec3 yuv2) {
	bvec3 res = greaterThan(abs((yuv1 + yuv_offset) - (yuv2 + yuv_offset)) , yuv_threshold);
	return res.x || res.y || res.z;
}

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
COMPAT_VARYING vec4 t3;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
	float	dx	=	SourceSize.z;
	float	dy	=	SourceSize.w;
	//   +----+----+----+
	//   |    |    |    |
	//   | w1 | w2 | w3 |
	//   +----+----+----+
	//   |    |    |    |
	//   | w4 | w5 | w6 |
	//   +----+----+----+
	//   |    |    |    |
	//   | w7 | w8 | w9 |
	//   +----+----+----+
	t1	=	vTexCoord.xxxy + vec4(-dx, 0, dx, -dy); //  w1 | w2 | w3;
	t2	=	vTexCoord.xxxy + vec4(-dx, 0, dx,   0); //  w4 | w5 | w6;
	t3	=	vTexCoord.xxxy + vec4(-dx, 0, dx,  dy); //  w7 | w8 | w9;
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
COMPAT_VARYING vec4 t3;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	vec3	w1	=	yuv * COMPAT_TEXTURE(Source, t1.xw).rgb;
	vec3	w2	=	yuv * COMPAT_TEXTURE(Source, t1.yw).rgb;
	vec3	w3	=	yuv * COMPAT_TEXTURE(Source, t1.zw).rgb;

	vec3	w4	=	yuv * COMPAT_TEXTURE(Source, t2.xw).rgb;
	vec3	w5	=	yuv * COMPAT_TEXTURE(Source, t2.yw).rgb;
	vec3	w6	=	yuv * COMPAT_TEXTURE(Source, t2.zw).rgb;

	vec3	w7	=	yuv * COMPAT_TEXTURE(Source, t3.xw).rgb;
	vec3	w8	=	yuv * COMPAT_TEXTURE(Source, t3.yw).rgb;
	vec3	w9	=	yuv * COMPAT_TEXTURE(Source, t3.zw).rgb;

	vec3	pattern_1	=	vec3(diff(w5, w1),	diff(w5, w2),	diff(w5, w3));
	vec3	pattern_2	=	vec3(diff(w5, w4),	false,	diff(w5, w6));
	vec3	pattern_3	=	vec3(diff(w5, w7),	diff(w5, w8),	diff(w5, w9));
	vec4	cross		=	vec4(diff(w4, w2),	diff(w2, w6),	diff(w8, w4),	diff(w6, w8));
	
	vec2	index;
	index.x	=	dot(pattern_1, vec3(1, 2, 4)) +
				dot(pattern_2, vec3(8, 0, 16)) +
				dot(pattern_3, vec3(32, 64, 128));
	index.y	=	dot(cross, vec4(1, 2, 4, 8));
	
	FragColor	=	vec4(index / vec2(255.0, 15.0), 0.0, 1.0);
} 
#endif
