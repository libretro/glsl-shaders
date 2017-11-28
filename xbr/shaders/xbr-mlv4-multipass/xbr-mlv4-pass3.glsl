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

// compatibility macros
#define mul(a,b) (b*a)
#define saturate(c) clamp(c, 0.0, 1.0)
#define frac(x) (fract(x))
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4
#define float3x3 mat3x3
#define float4x3 mat4x3
#define float2x4 mat2x4
#define texture_size TextureSize
#define video_size InputSize
#define output_size OutputSize

#define round(X) floor((X)+0.5)

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
uniform COMPAT_PRECISION vec2 PassPrev3TextureSize;
uniform COMPAT_PRECISION vec2 PassPrev3InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
	float2 ps = float2(1.0/PassPrev3TextureSize.x, 1.0/PassPrev3TextureSize.y);
	float dx = ps.x;
	float dy = ps.y;

	//      A3 B3 C3
	//      A1 B1 C1
	//A2 A0  A  B  C C4 C6
	//D2 D0  D  E  F F4 F6
	//G2 G0  G  H  I I4 I6
	//      G5 H5 I5
	//      G7 H7 I7

	t1       = float4(dx, 0., 0., dy);  // F  H
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
uniform COMPAT_PRECISION vec2 PassPrev3TextureSize;
uniform COMPAT_PRECISION vec2 PassPrev3InputSize;
uniform sampler2D Texture;
uniform sampler2D PassPrev3Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

const float coef            = 2.0;
const float cf              = 4.0;
const float eq_threshold    = 15.0;
const float y_weight        = 48.0;
const float u_weight        = 7.0;
const float v_weight        = 6.0;
const float3x3 yuv          = float3x3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
const float3x3 yuv_weighted = float3x3(y_weight*yuv[0], u_weight*yuv[1], v_weight*yuv[2]);
const float4 maximo         = float4(255.0, 255.0, 255.0, 255.0);
const float4 low            = float4(-64.0, -64.0, -64.0, -64.0);
const float4 high           = float4( 64.0,  64.0,  64.0,  64.0);


const float2x4 sym_vectors  = float2x4(1.,  1.,   -1., -1.,    1., -1.,   -1.,  1.);

// Bx, Ay, C
const float3 lines[13] = float3[](
   float3(4.0, 4.0, 4.0),  //  0  NL
   float3(4.0, 4.0, 3.0),  //  1  LV0
   float3(4.0, 4.0, 2.0),  //  2  LV1
   float3(8.0, 4.0, 2.0),  //  3  LV2u
   float3(4.0, 8.0, 2.0),  //  4  LV2l
  float3(12.0, 4.0, 2.0),  //  5  LV3u
   float3(4.0,12.0, 2.0),  //  6  LV3l
  float3(16.0, 4.0, 2.0),  //  7  LV4u
   float3(4.0,16.0, 2.0),  //  8  LV4l

  float3(12.0, 4.0, 6.0),  //  9  LV3u
   float3(4.0,12.0, 6.0),  // 10  LV3l
  float3(16.0, 4.0, 6.0),  // 11  LV4u
   float3(4.0,16.0, 6.0)  // 12  LV4l
);

float4 remapTo01(float4 v, float4 low, float4 high)
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

void main()
{
	float px;

	float2 pos = frac(vTexCoord*PassPrev3TextureSize.xy)-float2(0.5, 0.5); // pos = pixel position
	float2 dir = sign(pos); // dir = pixel direction

	float2 g1 = dir*( saturate(-dir.y*dir.x)*t1.zw + saturate( dir.y*dir.x)*t1.xy);
	float2 g2 = dir*( saturate( dir.y*dir.x)*t1.zw + saturate(-dir.y*dir.x)*t1.xy);

	float3 E   = COMPAT_TEXTURE(PassPrev3Texture, vTexCoord    ).rgb;
	float3 F   = COMPAT_TEXTURE(PassPrev3Texture, vTexCoord +g1).rgb;
	float3 H   = COMPAT_TEXTURE(PassPrev3Texture, vTexCoord +g2).rgb;
	float3 I   = COMPAT_TEXTURE(PassPrev3Texture, vTexCoord +g1+g2).rgb;
	float3 F4  = COMPAT_TEXTURE(PassPrev3Texture, vTexCoord +2.0*g1).rgb;
	float3 H5  = COMPAT_TEXTURE(PassPrev3Texture, vTexCoord +2.0*g2).rgb;

	float e = dot(E, yuv_weighted[0]);
	float f = dot(F, yuv_weighted[0]);
	float h = dot(H, yuv_weighted[0]);
	float i = dot(I, yuv_weighted[0]);
	float f4= dot(F4, yuv_weighted[0]);
	float h5= dot(H5, yuv_weighted[0]);

	float4 icomp    = round(saturate(mul(dir, sym_vectors))); // choose info component

	float  infoE    = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord   ), icomp), 255.0); // retrieve 1st pass info
	float  infoF    = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord+g1), icomp), 255.0); // 1st pass info from neighbor r
	float  infoH    = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord+g2), icomp), 255.0); // 1st pass info from neighbor d

	float4 lparam;
	float2 addr;

	if (infoF == 8.0)
	{
		lparam.xyz = lines[12];
		px = float(df(f,f4) <= df(f,i));
		addr.x = 2.*px + saturate(1.0-px);
		addr.y = saturate(1.0-px);
	}
	else if (infoH == 7.0)
	{
		lparam.xyz = lines[11];
		px = float(df(h,h5) <= df(h,i));
		addr.x = saturate(1.0-px);
		addr.y = 2.*px + saturate(1.0-px);
	}
	else if (infoF == 6.0)
	{
		lparam.xyz = lines[10];
		px = float(df(f,f4) <= df(f,i));
		addr.x = 2.*px + saturate(1.0-px);
		addr.y = saturate(1.0-px);
	}
	else if (infoH == 5.0)
	{
		lparam.xyz = lines[9];
		px = float(df(h,h5) <= df(h,i));
		addr.x = saturate(1.0-px);
		addr.y = 2.*px + saturate(1.0-px);
	}
	else
	{
		px = float(df(e,f) <= df(e,h));
		addr.x = px;
		addr.y = saturate(1.0-px);

		lparam.xyz = (infoE == 8.0) ? lines[8] : ((infoE == 7.0) ? lines[7] : ((infoE == 6.0) ? lines[6] : ((infoE == 5.0) ? lines[5] : ((infoE == 4.0) ? lines[4] : ((infoE == 3.0) ? lines[3] : ((infoE == 2.0) ? lines[2] : ((infoE == 1.0) ? lines[1] : lines[0])))))));
	}

	bool inv = (dir.x*dir.y) < 0.0 ? true : false;

	// Rotate address from relative to absolute.
	addr = addr*dir.yx;
	addr = inv ? addr.yx : addr;

	// Rotate straight line equation from relative to absolute.
	lparam.xy = lparam.xy*dir.yx;
	lparam.xy = inv ? lparam.yx : lparam.xy;

	addr.x+=2.0;
	addr.y+=2.0;

	lparam.w = addr.x*8.0 + addr.y;

    FragColor = float4(remapTo01(lparam, low, high));
} 
#endif
