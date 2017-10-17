#version 130

/*
   Hyllian's xBR level 3 pass0 Shader
   
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


   Incorporates some of the ideas from SABR shader. Thanks to Joshua Street.
*/

#define mul(a,b) (b*a)
#define saturate(c) clamp(c, 0.0, 1.0)

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
   
   	vec2 ps = vec2(1.0) / SourceSize.xy;
	float dx = ps.x;
	float dy = ps.y;

	//    A1 B1 C1
	// A0  A  B  C C4
	// D0  D  E  F F4
	// G0  G  H  I I4
	//    G5 H5 I5

	t1 = vTexCoord.xxxy + vec4( -dx, 0, dx,-2.0*dy); // A1 B1 C1
	t2 = vTexCoord.xxxy + vec4( -dx, 0, dx,    -dy); //  A  B  C
	t3 = vTexCoord.xxxy + vec4( -dx, 0, dx,      0); //  D  E  F
	t4 = vTexCoord.xxxy + vec4( -dx, 0, dx,     dy); //  G  H  I
	t5 = vTexCoord.xxxy + vec4( -dx, 0, dx, 2.0*dy); // G5 H5 I5
	t6 = vTexCoord.xyyy + vec4(-2.0*dx,-dy, 0,  dy); // A0 D0 G0
	t7 = vTexCoord.xyyy + vec4( 2.0*dx,-dy, 0,  dy); // C4 F4 I4
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

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

const float coef            = 2.0;
const float cf              = 4.0;
const vec4 eq_threshold   = vec4(15.0, 15.0, 15.0, 15.0);
const float y_weight        = 48.0;
const float u_weight        = 7.0;
const float v_weight        = 6.0;
const mat3 yuv          = mat3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
const mat3 yuv_weighted = mat3(y_weight*yuv[0], u_weight*yuv[1], v_weight*yuv[2]);
const vec4 bin1           = vec4( 1.0,  2.0,  4.0,   8.0);
const vec4 bin2           = vec4(16.0, 32.0, 64.0, 128.0);
const vec4 maximo         = vec4(255.0, 255.0, 255.0, 255.0);

vec4 df(vec4 A, vec4 B)
{
	return vec4(abs(A-B));
}

vec4 remapTo01(vec4 v, vec4 high)
{
	return (v/high);
}

vec4 remapFrom01(vec4 v, vec4 high)
{
	return (high*v + vec4(0.5, 0.5, 0.5, 0.5));
}

bvec4 eq(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold);
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

#define FILTRO(EDR0, EDR, LEFT, UP, LEFT3, UP3,    PX0, PX3, PX1,    LIN0, LIN3, LIN1,    PX)\
	if (LEFT && (!UP))\
	{\
		PX0  = bvec2( 0, PX);\
		PX3  = bvec2(PX,  1);\
		if (LEFT3)\
		{\
			LIN0 = bvec4(0, 1, 0, 0);\
			LIN3 = bvec4(1, 0, 0, 0);\
		}\
		else \
		{\
			LIN0 = bvec4(0, 0, 1, 0);\
			LIN3 = bvec4(0, 1, 1, 0);\
		}\
	}\
	else if (UP && (!LEFT))\
	{\
		PX0  = bvec2(false,    PX);\
		PX1  = bvec2(  !PX, false);\
		if (UP3)\
		{\
			LIN0 = bvec4(0, 1, 0, 1);\
			LIN1 = bvec4(1, 0, 0, 1);\
		}\
		else \
		{\
			LIN0 = bvec4(0, 0, 1, 1);\
			LIN1 = bvec4(0, 1, 1, 1);\
		}\
	}\
	else if (EDR)\
	{\
		LEFT = UP = LEFT3 = UP3 = false;\
		PX0  = bvec2(false, PX);\
		LIN0 = bvec4(0, 0, 0, 1);\
	}\
	else if (EDR0)\
	{\
		LEFT = UP = LEFT3 = UP3 = false;\
		PX0  = bvec2(false, PX);\
		LIN0 = bvec4(0, 0, 0, 0);\
	}\

void main()
{
	bvec4 edr, edr_left, edr_up, edr3_left, edr3_up, px; // px = pixel, edr = edge detection rule
	bvec4 interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
	bvec4 interp_restriction_lv3_left, interp_restriction_lv3_up;
	bvec2 px0, px1, px2, px3;
	bvec4 lin0, lin1, lin2, lin3;

	vec3 A1 = COMPAT_TEXTURE(Source, t1.xw).rgb;
	vec3 B1 = COMPAT_TEXTURE(Source, t1.yw).rgb;
	vec3 C1 = COMPAT_TEXTURE(Source, t1.zw).rgb;

	vec3 A  = COMPAT_TEXTURE(Source, t2.xw).rgb;
	vec3 B  = COMPAT_TEXTURE(Source, t2.yw).rgb;
	vec3 C  = COMPAT_TEXTURE(Source, t2.zw).rgb;

	vec3 D  = COMPAT_TEXTURE(Source, t3.xw).rgb;
	vec3 E  = COMPAT_TEXTURE(Source, t3.yw).rgb;
	vec3 F  = COMPAT_TEXTURE(Source, t3.zw).rgb;

	vec3 G  = COMPAT_TEXTURE(Source, t4.xw).rgb;
	vec3 H  = COMPAT_TEXTURE(Source, t4.yw).rgb;
	vec3 I  = COMPAT_TEXTURE(Source, t4.zw).rgb;

	vec3 G5 = COMPAT_TEXTURE(Source, t5.xw).rgb;
	vec3 H5 = COMPAT_TEXTURE(Source, t5.yw).rgb;
	vec3 I5 = COMPAT_TEXTURE(Source, t5.zw).rgb;

	vec3 A0 = COMPAT_TEXTURE(Source, t6.xy).rgb;
	vec3 D0 = COMPAT_TEXTURE(Source, t6.xz).rgb;
	vec3 G0 = COMPAT_TEXTURE(Source, t6.xw).rgb;

	vec3 C4 = COMPAT_TEXTURE(Source, t7.xy).rgb;
	vec3 F4 = COMPAT_TEXTURE(Source, t7.xz).rgb;
	vec3 I4 = COMPAT_TEXTURE(Source, t7.xw).rgb;

	vec4 b = mul( mat4x3(B, D, H, F), yuv_weighted[0] );
	vec4 c = mul( mat4x3(C, A, G, I), yuv_weighted[0] );
	vec4 e = mul( mat4x3(E, E, E, E), yuv_weighted[0] );
	vec4 d = b.yzwx;
	vec4 f = b.wxyz;
	vec4 g = c.zwxy;
	vec4 h = b.zwxy;
	vec4 i = c.wxyz;

	vec4 i4 = mul( mat4x3(I4, C1, A0, G5), yuv_weighted[0] );
	vec4 i5 = mul( mat4x3(I5, C4, A1, G0), yuv_weighted[0] );
	vec4 h5 = mul( mat4x3(H5, F4, B1, D0), yuv_weighted[0] );
	vec4 f4 = h5.yzwx;

	vec4 c1 = i4.yzwx;
	vec4 g0 = i5.wxyz;
	vec4 b1 = h5.zwxy;
	vec4 d0 = h5.wxyz;

	bvec4 interp_restriction_lv0 = and(notEqual(e,f)  ,  notEqual(e,h));
	bvec4 comp1 = and(not(eq(h,h5)) , not(eq(h,i5)));
	bvec4 comp2 = and(not(eq(h,d)) , not(eq(h,g)));
	bvec4 comp3 = and(not(eq(f,f4)) , not(eq(f,i4)));
	bvec4 comp4 = and( not(eq(f,b)) , not(eq(f,c)) );
	bvec4 comp5 = and(eq(e,i) , or(comp3 , comp1));
	interp_restriction_lv1       = or( comp4 , or(comp2 , or(comp5 , or(eq(e,g) , eq(e,c)))));
	interp_restriction_lv2_left = and(notEqual(e,g)  ,  notEqual(d,g));
	interp_restriction_lv2_up   = and(notEqual(e,c)  ,  notEqual(b,c));
	interp_restriction_lv3_left = and(notEqual(e,g0) , notEqual(d0,g0));
	interp_restriction_lv3_up   = and(notEqual(e,c1) , notEqual(b1,c1));

	bvec4 edr0 = and(lessThan(weighted_distance( e, c, g, i, h5, f4, h, f) , weighted_distance( h, d, i5, f, i4, b, e, i)) , interp_restriction_lv0);

	edr       = and(edr0 , interp_restriction_lv1);
	edr_left  = and(lessThanEqual((coef*df(f,g)) , df(h,c)) , and(interp_restriction_lv2_left , edr));
	edr_up    = and(greaterThanEqual(df(f,g) , (coef*df(h,c))) , and(interp_restriction_lv2_up   , edr));
	edr3_left = and(lessThanEqual((cf*df(f,g0)) , df(h,c1)) , and(interp_restriction_lv3_left , edr_left));
	edr3_up   = and(greaterThanEqual(df(f,g0) , (cf*df(h,c1))) , and(interp_restriction_lv3_up   , edr_up));

	px  = lessThanEqual(df(e,f) , df(e,h));

	lin0 = lin1 = lin2 = lin3 = bvec4(1, 1, 1, 1);

	FILTRO(edr0.x, edr.x, edr_left.x, edr_up.x, edr3_left.x, edr3_up.x, px0, px3, px1, lin0, lin3, lin1, px.x);
	FILTRO(edr0.y, edr.y, edr_left.y, edr_up.y, edr3_left.y, edr3_up.y, px1, px0, px2, lin1, lin0, lin2, px.y);
	FILTRO(edr0.z, edr.z, edr_left.z, edr_up.z, edr3_left.z, edr3_up.z, px2, px1, px3, lin2, lin1, lin3, px.z);
	FILTRO(edr0.w, edr.w, edr_left.w, edr_up.w, edr3_left.w, edr3_up.w, px3, px2, px0, lin3, lin2, lin0, px.w);

	vec4 info = mul(
                          bin1, mat4(
                                          edr3_left,
                                          edr3_up,
                                          px0.x,  px1.x,  px2.x,  px3.x,
                                          px0.y,  px1.y,  px2.y,  px3.y
                                        )
                         );

	info +=       mul(bin2, mat4(
                                         lin0.x, lin1.x, lin2.x, lin3.x,
                                         lin0.y, lin1.y, lin2.y, lin3.y,
                                         lin0.z, lin1.z, lin2.z, lin3.z,
                                         lin0.w, lin1.w, lin2.w, lin3.w
                                        )
                         );
						 
   FragColor = vec4(remapTo01(info, maximo));
} 
#endif
