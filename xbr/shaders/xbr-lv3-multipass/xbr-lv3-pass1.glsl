#version 130

/*
   Hyllian's xBR level 3 pass1 Shader
   
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
COMPAT_VARYING vec2 delta;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
#define OriginalSize OrigTextureSize

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy * 1.0004;
   
   	vec2 ps = vec2(1.0/OriginalSize.x, 1.0/OriginalSize.y);
	float dx = ps.x;
	float dy = ps.y;

	//      A3 B3 C3
	//      A1 B1 C1
	//A2 A0  A  B  C C4 C6
	//D2 D0  D  E  F F4 F6
	//G2 G0  G  H  I I4 I6
	//      G5 H5 I5
	//      G7 H7 I7

	t1       = vec4(dx, 0., 0., dy);  // F  H
	delta    = vec2(InputSize.x/OutputSize.x, 0.5*InputSize.x/OutputSize.x); // Delta is the thickness of interpolation
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
uniform sampler2D OrigTexture;
#define Original OrigTexture
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec2 delta;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

const mat2x4 sym_vectors  = mat2x4(1.,  1.,   -1., -1.,    1., -1.,   -1.,  1.);

const vec3 lines[12] = vec3[](
   vec3(1.0, 1.0, 0.75),
   vec3(1.0, 1.0, 0.5),
   vec3(2.0, 1.0, 0.5),
   vec3(1.0, 2.0, 0.5),
   vec3(3.0, 1.0, 0.5),
   vec3(1.0, 3.0, 0.5),

   vec3(-1.0,  2.0, 0.5),
   vec3(2.0, -1.0, 0.5),
   vec3(-1.0,  3.0, 0.5),
   vec3(3.0, -1.0, 0.5),

   vec3(3.0, 1.0, 1.5),
   vec3(1.0, 3.0, 1.5)
);


float remapFrom01(float v, float high)
{
	return (high*v + 0.5);
}


vec3 remapFrom01(vec3 v, vec3 low, vec3 high)
{
	return round(mix(low, high, v));
}

vec4 unpack_info(float i)
{
	vec4 info;
	info.x = round(modf(i/2.0, i));
	info.y = round(modf(i/2.0, i));
	info.z = round(modf(i/2.0, i));
	info.w = i;

	return info;
}

void main()
{
	vec2 px; // px = pixel to blend
	float pxr, pxd, line, edr3_nrl, edr3_ndu;

	vec2 pos = fract(vTexCoord*SourceSize.xy)-vec2(0.5, 0.5); // pos = pixel position
	vec2 dir = sign(pos); // dir = pixel direction

	vec2 g1 = dir*( saturate(-dir.y*dir.x)*t1.zw + saturate( dir.y*dir.x)*t1.xy);
	vec2 g2 = dir*( saturate( dir.y*dir.x)*t1.zw + saturate(-dir.y*dir.x)*t1.xy);

	vec3 F   = COMPAT_TEXTURE(Original, vTexCoord +g1).xyz;
	vec3 B   = COMPAT_TEXTURE(Original, vTexCoord -g2).xyz;
	vec3 D   = COMPAT_TEXTURE(Original, vTexCoord -g1).xyz;
	vec3 H   = COMPAT_TEXTURE(Original, vTexCoord +g2).xyz;
	vec3 E   = COMPAT_TEXTURE(Original, vTexCoord    ).xyz;

	vec3 F4  = COMPAT_TEXTURE(Original, vTexCoord +2.0*g1).xyz;
	vec3 I   = COMPAT_TEXTURE(Original, vTexCoord  +g1+g2).xyz;
	vec3 H5  = COMPAT_TEXTURE(Original, vTexCoord +2.0*g2).xyz;

	vec4 icomp    = round(saturate(mul(dir, sym_vectors))); // choose info component
	float  info     = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord   ), icomp), 255.0); // retrieve 1st pass info
	float  info_nr  = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord+g1), icomp), 255.0); // 1st pass info from neighbor r
	float  info_nd  = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord+g2), icomp), 255.0); // 1st pass info from neighbor d

	modf(info/2.0f, info); // discard info
	modf(info/2.0f, info); // discard info
	px.x = round(modf(info/2.0, info));
	px.y = round(modf(info/2.0, info));

	vec4 flags = unpack_info(info); // retrieve 1st pass flags

	edr3_nrl = round(modf(info_nr/2.0, info_nr));
	modf(info_nr/2.0, info_nr); // discard info_nr
	modf(info_nr/2.0, info_nr); // discard info_nr
	pxr      = round(modf(info_nr/2.0, info_nr));

	modf(info_nd/2.0, info_nd); // discard info_nd
	edr3_ndu = round(modf(info_nd/2.0, info_nd));
	modf(info_nd/2.0, info_nd); // discard info_nd
	pxd      = round(modf(info_nd/2.0, info_nd));

	float aux = round(dot(vec4(8.0, 4.0, 2.0, 1.0), flags));
	vec3 slep;


	if (aux >= 6.0)
	{
		slep = (aux==6.0 ? lines[6] : (aux==7.0 ? lines[7] : (aux==8.0 ? lines[8] : (aux==9.0 ? lines[9] : (aux==10.0 ? lines[10] : lines[11])))));
	}
	else
	{
		slep = (aux==0.0 ? lines[0] : (aux==1.0 ? lines[1] : (aux==2.0 ? lines[2] : (aux==3.0 ? lines[3] : (aux==4.0 ? lines[4] : lines[5])))));
	}


	vec2 fp = (dir.x*dir.y) > 0.0 ? abs(pos) : abs(pos.yx);

	vec3 fp1 = vec3(fp.yx, -1.);

	vec3 color = E;
	float fx;

	if (aux < 10.0)
	{
		fx    = saturate(dot(fp1, slep)/(2.*delta.x)+0.5);
		color = mix(E, mix(mix(H, F, px.y), mix(D, B, px.y), px.x), fx); // interpolate if there's edge
	}
	else if (edr3_nrl == 1.0)
	{
		fx    = saturate(dot(fp1, lines[10])/(2.*delta.x)+0.5);
		color = mix(E, mix(I, F4, pxr), fx); // interpolate if there's edge
	}
	else if (edr3_ndu == 1.0)
	{
		fx    = saturate(dot(fp1, lines[11])/(2.*delta.x)+0.5);
		color = mix(E, mix(H5, I, pxd), fx); // interpolate if there's edge
	}

   FragColor = vec4(color, 1.0);
} 
#endif
