#version 130

/*

   Hyllian's xBR MultiLevel4 Shader - Pass2
   
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
#define mul(a,b) (b*a)
#define saturate(c) clamp(c, 0.0, 1.0)

const float cf2	=	2.0;
const float cf3	=	4.0;
const float cf4	=	4.0;
const vec4 eq_threshold	=	vec4(15.0, 15.0, 15.0, 15.0);
const vec4 eq_threshold2	=	vec4( 5.0,  5.0,  5.0,  5.0);
const vec4 eq_threshold3	=	vec4(25.0, 25.0, 25.0, 25.0);
const float y_weight	=	48.0;
const float u_weight	=	7.0;
const float v_weight	=	6.0;
const vec3 yuv0	=	vec3(0.299, 0.587, 0.114);
const vec3 yuv1	=	vec3(-0.169, -0.331, 0.499);
const vec3 yuv2	=	vec3(0.499, -0.418, -0.0813);
const vec3 yuv_weighted0	=	vec3(14.352, 28.176, 5.472);//precalculate y_weight * yuv[0];
const vec3 yuv_weighted1	=	vec3(-1.183, -2.317, 3.493);//precalculate u_weight * yuv[1];
const vec3 yuv_weighted2	=	vec3(2.994, -2.508, -0.488);//precalculate v_weight * yuv[2];
const vec4 maximo	=	vec4(255.0, 255.0, 255.0, 255.0);


vec4 df(vec4 A, vec4 B)
{
	return vec4(abs(A-B));
}

bvec4 rd(vec4 A, vec4 B, vec4 C, vec4 D)
{
    return (greaterThan(df(C,D)/(df(A,B)+0.000000001) , vec4(2.0)));
}

bvec4 id(vec4 A, vec4 B, vec4 C, vec4 D)
{
    return greaterThan(df(C,D) , df(A,B));
}

vec4 remapTo01(vec4 v, vec4 high)
{
	return (v/high);
}

vec4 remapFrom01(vec4 v, vec4 high)
{
	return round(high*v);
}

bvec4 eq(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold);
}

bvec4 eq2(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold2);
}

bvec4 eq3(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold3);
}

vec4 weighted_distance(vec4 a, vec4 b, vec4 c, vec4 d, vec4 e, vec4 f, vec4 g, vec4 h)
{
	return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}

bvec4 and(bvec4 A, bvec4 B)
{
	return bvec4(A.x && B.x, A.y && B.y, A.z && B.z, A.w && B.w);
}

bvec4 or(bvec4 A, bvec4 B)
{
	return bvec4(A.x || B.x, A.y || B.y, A.z || B.z, A.w || B.w);
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
COMPAT_VARYING vec4 t4;
COMPAT_VARYING vec4 t5;
COMPAT_VARYING vec4 t6;
COMPAT_VARYING vec4 t7;

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
   
   	float dx = SourceSize.z;
	float dy = SourceSize.w;
   
	//    A1 B1 C1
	// A0  A  B  C C4
	// D0  D  E  F F4
	// G0  G  H  I I4
	//    G5 H5 I5
	
	t1 = vTexCoord.xxxy + vec4( -dx, 0., dx,-2.0*dy); // A1 B1 C1
	t2 = vTexCoord.xxxy + vec4( -dx, 0., dx,    -dy); //  A  B  C
	t3 = vTexCoord.xxxy + vec4( -dx, 0., dx,      0); //  D  E  F
	t4 = vTexCoord.xxxy + vec4( -dx, 0., dx,     dy); //  G  H  I
	t5 = vTexCoord.xxxy + vec4( -dx, 0., dx, 2.0*dy); // G5 H5 I5
	t6 = vTexCoord.xyyy + vec4(-2.0*dx,-dy, 0.,  dy); // A0 D0 G0
	t7 = vTexCoord.xyyy + vec4( 2.0*dx,-dy, 0.,  dy); // C4 F4 I4
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
uniform sampler2D OrigTexture;
#define Original OrigTexture
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;
COMPAT_VARYING vec4 t4;
COMPAT_VARYING vec4 t5;
COMPAT_VARYING vec4 t6;
COMPAT_VARYING vec4 t7;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define OriginalSize vec4(OrigTextureSize.xy, 1.0 / OrigTextureSize.xy)

void main()
{
	vec4 PA  = texture(Source, t2.xw);
	vec4 PB  = texture(Source, t2.yw);
	vec4 PC  = texture(Source, t2.zw);

	vec4 PD  = texture(Source, t3.xw);
	vec4 PE  = texture(Source, t3.yw);
	vec4 PF  = texture(Source, t3.zw);

	vec4 PG  = texture(Source, t4.xw);
	vec4 PH  = texture(Source, t4.yw);
	vec4 PI  = texture(Source, t4.zw);
	
	vec3 A1 = texture(Original, t1.xw).rgb;
	vec3 B1 = texture(Original, t1.yw).rgb;
	vec3 C1 = texture(Original, t1.zw).rgb;

	vec3 A  = texture(Original, t2.xw).rgb;
	vec3 B  = texture(Original, t2.yw).rgb;
	vec3 C  = texture(Original, t2.zw).rgb;

	vec3 D  = texture(Original, t3.xw).rgb;
	vec3 E  = texture(Original, t3.yw).rgb;
	vec3 F  = texture(Original, t3.zw).rgb;

	vec3 G  = texture(Original, t4.xw).rgb;
	vec3 H  = texture(Original, t4.yw).rgb;
	vec3 I  = texture(Original, t4.zw).rgb;

	vec3 G5 = texture(Original, t5.xw).rgb;
	vec3 H5 = texture(Original, t5.yw).rgb;
	vec3 I5 = texture(Original, t5.zw).rgb;

	vec3 A0 = texture(Original, t6.xy).rgb;
	vec3 D0 = texture(Original, t6.xz).rgb;
	vec3 G0 = texture(Original, t6.xw).rgb;

	vec3 C4 = texture(Original, t7.xy).rgb;
	vec3 F4 = texture(Original, t7.xz).rgb;
	vec3 I4 = texture(Original, t7.xw).rgb;
	
	vec4 b = mul( mat4x3(B, D, H, F), yuv_weighted0 );
	vec4 c = mul( mat4x3(C, A, G, I), yuv_weighted0 );
	vec4 e = mul( mat4x3(E, E, E, E), yuv_weighted0 );
	vec4 d = b.yzwx;
	vec4 f = b.wxyz;
	vec4 g = c.zwxy;
	vec4 h = b.zwxy;
	vec4 i = c.wxyz;
	
	vec4 i4 = mul( mat4x3(I4, C1, A0, G5), yuv_weighted0 );
	vec4 i5 = mul( mat4x3(I5, C4, A1, G0), yuv_weighted0 );
	vec4 h5 = mul( mat4x3(H5, F4, B1, D0), yuv_weighted0 );
	vec4 f4 = h5.yzwx;

	vec4 pe = remapFrom01(PE, maximo);
	vec4 pf = remapFrom01(PF, maximo);
	vec4 ph = remapFrom01(PH, maximo);
	vec4 pb = remapFrom01(PB, maximo);
	vec4 pd = remapFrom01(PD, maximo);
	
	vec4 f2 = vec4(pf.z, pb.w, pd.x, ph.y);
	vec4 h2 = vec4(ph.z, pf.w, pb.x, pd.y);
	vec4 f1 = vec4(pf.y, pb.z, pd.w, ph.x);
	vec4 h3 = vec4(ph.w, pf.x, pb.y, pd.z);

	bvec4 nbrs;
	nbrs.x = (pe.y > 1.0) || (pe.w > 1.0) ? true : false;
	nbrs.y = (pe.z > 1.0) || (pe.x > 1.0) ? true : false;
	nbrs.z = (pe.w > 1.0) || (pe.y > 1.0) ? true : false;
	nbrs.w = (pe.x > 1.0) || (pe.z > 1.0) ? true : false;
	
	bvec4 jag1;
	jag1.x = (f2.x > 1.0) || (h2.x > 1.0) ? true : false;
	jag1.y = (f2.y > 1.0) || (h2.y > 1.0) ? true : false;
	jag1.z = (f2.z > 1.0) || (h2.z > 1.0) ? true : false;
	jag1.w = (f2.w > 1.0) || (h2.w > 1.0) ? true : false;
	
	bvec4 jag2;
	jag2.x = (f2.x > 2.0) || (h2.x > 2.0) ? true : false;
	jag2.x = (f2.y > 2.0) || (h2.y > 2.0) ? true : false;
	jag2.x = (f2.z > 2.0) || (h2.z > 2.0) ? true : false;
	jag2.x = (f2.w > 2.0) || (h2.w > 2.0) ? true : false;
	
	bvec4 jag3;
	jag3.x = (f2.x > 4.0) || (h2.x > 4.0) ? true : false;
	jag3.y = (f2.y > 4.0) || (h2.y > 4.0) ? true : false;
	jag3.z = (f2.z > 4.0) || (h2.z > 4.0) ? true : false;
	jag3.w = (f2.w > 4.0) || (h2.w > 4.0) ? true : false;

	pe.x = (pe.x == 7.0 || pe.x == 8.0) ? ((jag3.x) ? pe.x : (pe.x - 2.0)) : pe.x;
	pe.y = (pe.y == 7.0 || pe.y == 8.0) ? ((jag3.y) ? pe.y : (pe.y - 2.0)) : pe.y;
	pe.z = (pe.z == 7.0 || pe.z == 8.0) ? ((jag3.z) ? pe.z : (pe.z - 2.0)) : pe.z;
	pe.w = (pe.w == 7.0 || pe.w == 8.0) ? ((jag3.w) ? pe.w : (pe.w - 2.0)) : pe.w;
	
	pe.x = (pe.x == 5.0 || pe.x == 6.0) ? ((jag2.x) ? pe.x : (pe.x - 2.0)) : pe.x;
	pe.y = (pe.y == 5.0 || pe.y == 6.0) ? ((jag2.y) ? pe.y : (pe.y - 2.0)) : pe.y;
	pe.z = (pe.z == 5.0 || pe.z == 6.0) ? ((jag2.z) ? pe.z : (pe.z - 2.0)) : pe.z;
	pe.w = (pe.w == 5.0 || pe.w == 6.0) ? ((jag2.w) ? pe.w : (pe.w - 2.0)) : pe.w;

	bvec4 jag91;
	jag91.x = ((id(h,i,e,h).x || id(i4,i,f4,i4).x) && (f2.x > 1.0) && (f1.x > 1.0));
	jag91.y = ((id(h,i,e,h).y || id(i4,i,f4,i4).y) && (f2.y > 1.0) && (f1.y > 1.0));
	jag91.z = ((id(h,i,e,h).z || id(i4,i,f4,i4).z) && (f2.z > 1.0) && (f1.z > 1.0));
	jag91.w = ((id(h,i,e,h).w || id(i4,i,f4,i4).w) && (f2.w > 1.0) && (f1.w > 1.0));
	
	bvec4 jag92;
	jag92.x = ((id(f,i,e,f).x || id(i5,i,h5,i5).x) && (h2.x > 1.0) && (h3.x > 1.0));
	jag92.y = ((id(f,i,e,f).y || id(i5,i,h5,i5).y) && (h2.y > 1.0) && (h3.y > 1.0));
	jag92.z = ((id(f,i,e,f).z || id(i5,i,h5,i5).z) && (h2.z > 1.0) && (h3.z > 1.0));
	jag92.w = ((id(f,i,e,f).w || id(i5,i,h5,i5).w) && (h2.w > 1.0) && (h3.w > 1.0));
	
	bvec4 jag93 = ( rd(h,g,e,g));
	bvec4 jag94 = ( rd(f,c,e,c));
	
	bvec4 jag9;
	jag9.x = (!(jag91.x && jag93.x || jag92.x && jag94.x));
	jag9.y = (!(jag91.y && jag93.y || jag92.y && jag94.y));
	jag9.z = (!(jag91.z && jag93.z || jag92.z && jag94.z));
	jag9.w = (!(jag91.w && jag93.w || jag92.w && jag94.w));

	pe.x = ((pe.x == 0.0) || (!nbrs.x || jag1.x) && jag9.x) ? pe.x : 1.0;
	pe.y = ((pe.y == 0.0) || (!nbrs.y || jag1.y) && jag9.y) ? pe.y : 1.0;
	pe.z = ((pe.z == 0.0) || (!nbrs.z || jag1.z) && jag9.z) ? pe.z : 1.0;
	pe.w = ((pe.w == 0.0) || (!nbrs.w || jag1.w) && jag9.w) ? pe.w : 1.0;
	
	FragColor = vec4(remapTo01(pe, maximo));
} 
#endif
