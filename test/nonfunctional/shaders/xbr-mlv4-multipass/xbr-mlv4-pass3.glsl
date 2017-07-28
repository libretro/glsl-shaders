#version 130

/*

   Hyllian's xBR MultiLevel4 Shader - Pass3
   
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

#define round(X) floor((X)+0.5)
#define saturate(c) clamp(c, 0.0, 1.0)
#define mul(a,b) (b*a)

const	float coef	=	2.0;
const	float cf	=	4.0;
const	float eq_threshold	=	15.0;
const	float y_weight	=	48.0;
const	float u_weight	=	7.0;
const	float v_weight	=	6.0;
const	vec3 yuv0	=	vec3(0.299, 0.587, 0.114);
const	vec3 yuv1	=	vec3(-0.169, -0.331, 0.499);
const	vec3 yuv2	=	vec3(0.499, -0.418, -0.0813);
const	vec3 yuv_weighted0	=	vec3(14.352, 28.176, 5.472);//precalculate y_weight * yuv[0];
const	vec3 yuv_weighted1	=	vec3(-1.183, -2.317, 3.493);//precalculate u_weight * yuv[1];
const	vec3 yuv_weighted2	=	vec3(2.994, -2.508, -0.488);//precalculate v_weight * yuv[2];
const	vec4 maximo	=	vec4(255.0, 255.0, 255.0, 255.0);
const	vec4 low	=	vec4(-64.0, -64.0, -64.0, -64.0);
const	vec4 high	=	vec4( 64.0,  64.0,  64.0,  64.0);

const	mat2x4 sym_vectors	=	mat2x4(1.,  1.,   -1., -1.,    1., -1.,   -1.,  1.);

// Bx, Ay, C
const vec3 lines0 =	vec3( 4.0,  4.0, 4.0);  //  0  NL
const vec3 lines1 =	vec3( 4.0,  4.0, 3.0);  //  1  LV0
const vec3 lines2 =	vec3( 4.0,  4.0, 2.0);  //  2  LV1
const vec3 lines3 =	vec3( 8.0,  4.0, 2.0);  //  3  LV2u
const vec3 lines4 =	vec3( 4.0,  8.0, 2.0);  //  4  LV2l
const vec3 lines5 =	vec3(12.0,  4.0, 2.0);  //  5  LV3u
const vec3 lines6 =	vec3( 4.0, 12.0, 2.0);  //  6  LV3l
const vec3 lines7 =	vec3(16.0,  4.0, 2.0);  //  7  LV4u
const vec3 lines8 =	vec3( 4.0, 16.0, 2.0);  //  8  LV4l
const vec3 lines9 =	vec3(12.0,  4.0, 6.0);  //  9  LV3u
const vec3 lines10 =	vec3( 4.0, 12.0, 6.0);  // 10  LV3l
const vec3 lines11 =	vec3(16.0,  4.0, 6.0);  // 11  LV4u
const vec3 lines12 =	vec3( 4.0, 16.0, 6.0);  // 12  LV4l

vec4 remapTo01(vec4 v, vec4 low, vec4 high)
{
	return saturate((v - low)/(high-low));
}

float remapFrom01(float v, float high)
{
	return round(high*v);
}

float df(float A, float B)
{
	return abs(A-B);
}

bool eq(float A, float B)
{
	return (df(A, B) < eq_threshold);
}

float weighted_distance(float a, float b, float c, float d, float e, float f, float g, float h)
{
	return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}

float bool_to_float(bool A)
{
	return A ? 1.0 : 0.0;
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
    TEX0.xy = TexCoord.xy * 1.0004;
	float	dx	=	OutSize.z;
	float	dy	=	OutSize.w;
   
	//      A3 B3 C3
	//      A1 B1 C1
	//A2 A0  A  B  C C4 C6
	//D2 D0  D  E  F F4 F6
	//G2 G0  G  H  I I4 I6
	//      G5 H5 I5
	//      G7 H7 I7
	
	t1	=	vec4(dx, 0., 0., dy);  // F  H
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
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform sampler2D Texture;
uniform sampler2D OrigTexture;
#define Original OrigTexture
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define OriginalSize vec4(OrigTextureSize.xy, 1.0 / OrigTextureSize.xy)

void main()
{
	float	px;

	vec2	pos	=	fract(vTexCoord.xy * OriginalSize.xy) - vec2(0.4999, 0.4999); // pos = pixel position
	vec2	dir	=	sign(pos); // dir = pixel direction

	vec2	g1	=	dir * ( saturate(-dir.y*dir.x) * t1.zw + saturate( dir.y*dir.x) * t1.xy );
	vec2	g2	=	dir * ( saturate( dir.y*dir.x) * t1.zw + saturate(-dir.y*dir.x) * t1.xy );

	vec3	E	=	texture(Original, vTexCoord    ).rgb;
	vec3	F	=	texture(Original, vTexCoord + g1).rgb;
	vec3	H	=	texture(Original, vTexCoord + g2).rgb;
	vec3	I	=	texture(Original, vTexCoord + g1 + g2).rgb;
	vec3	F4	=	texture(Original, vTexCoord + 2.0 * g1).rgb;
	vec3	H5	=	texture(Original, vTexCoord + 2.0 * g2).rgb;

	float	e	=	dot(E,  yuv_weighted0);
	float	f	=	dot(F,  yuv_weighted0);
	float	h	=	dot(H,  yuv_weighted0);
	float	i	=	dot(I,  yuv_weighted0);
	float	f4	=	dot(F4, yuv_weighted0);
	float	h5	=	dot(H5, yuv_weighted0);
	
	vec4	icomp	= round(saturate(mul(dir, sym_vectors))); // choose info component

	float	infoE	= remapFrom01(dot(texture(Source, vTexCoord   ), icomp), 255.0); // retrieve 1st pass info
	float	infoF	= remapFrom01(dot(texture(Source, vTexCoord+g1), icomp), 255.0); // 1st pass info from neighbor r
	float	infoH	= remapFrom01(dot(texture(Source, vTexCoord+g2), icomp), 255.0); // 1st pass info from neighbor d

	vec4 lparam;
	vec2 addr;
	
	if (infoF == 8.0)
	{
		lparam.xyz = lines12;
		px = bool_to_float(df(f,f4) <= df(f,i));
		addr.x = 2. * px + saturate(1.0 - px);
		addr.y = saturate(1.0 - px);
	}
	else if (infoH == 7.0)
	{
		lparam.xyz = lines11;
		px = bool_to_float(df(h,h5) <= df(h,i));
		addr.x = saturate(1.0 - px);
		addr.y = 2. * px + saturate(1.0 - px);
	}
	else if (infoF == 6.0)
	{
		lparam.xyz = lines10;
		px = bool_to_float(df(f,f4) <= df(f,i));
		addr.x = 2. * px + saturate(1.0 - px);
		addr.y = saturate(1.0 - px);
	}
	else if (infoH == 5.0)
	{
		lparam.xyz = lines9;
		px = bool_to_float(df(h,h5) <= df(h,i));
		addr.x = saturate(1.0 - px);
		addr.y = 2. * px + saturate(1.0 - px);
	}
	else
	{
		px = bool_to_float(df(e,f) <= df(e,h));
		addr.x = px;
		addr.y = saturate(1.0 - px);

		lparam.xyz = ((infoE == 1.0) ? lines1 : lines0);
		lparam.xyz = ((infoE == 2.0) ? lines2 : lparam.xyz);
		lparam.xyz = ((infoE == 3.0) ? lines3 : lparam.xyz);
		lparam.xyz = ((infoE == 4.0) ? lines4 : lparam.xyz);
		lparam.xyz = ((infoE == 5.0) ? lines5 : lparam.xyz);
		lparam.xyz = ((infoE == 6.0) ? lines6 : lparam.xyz);
		lparam.xyz = ((infoE == 7.0) ? lines7 : lparam.xyz);
		lparam.xyz = ((infoE == 8.0) ? lines8 : lparam.xyz);
	}

	bool inv = (dir.x*dir.y) < 0.0 ? true : false;

	// Rotate address from relative to absolute.
	addr = addr * dir.yx;
	addr = inv ? addr.yx : addr;

	// Rotate straight line equation from relative to absolute.
	lparam.xy = lparam.xy * dir.yx;
	lparam.xy = inv ? lparam.yx : lparam.xy;

	addr.x += 2.0;
	addr.y += 2.0;

	lparam.w = addr.x * 8.0 + addr.y;

	FragColor = vec4(remapTo01(lparam, low, high));
}
#endif

/*
19 1
9  1
4  0
2  0
1  1
0  0

0 0000   ND
1 0001   EDR0
2 0010   EDR
3 0011   EDRU
4 0100   EDRL
5 0101   EDRU3
6 0110   EDRL3

0   1 2 3 4
-2 -1 0 1 2

*/