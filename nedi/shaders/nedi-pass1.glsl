#version 150

/*
   NEDI Shader  -  pass1

// This file is a part of MPDN Extensions.
// https://github.com/zachsaw/MPDN_Extensions
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3.0 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library.
// 

   Sources ported from this discussion thread:

      http://forum.doom9.org/showthread.php?t=170727
   
   Ported by Hyllian - 2015.
*/

#define saturate(c) clamp(c, 0.0, 1.0)
#define lerp(c) mix(c)
#define mul(a,b) (b*a)
#define fmod(c) mod(c)
#define frac(c) fract(c)
#define tex2D(a,b) COMPAT_TEXTURE(a,b)
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define int2 ivec2
#define int3 ivec3
#define int4 ivec4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4
#define float2x2 mat2x2
#define float2x3 mat2x3
#define float3x3 mat3x3
#define float4x4 mat4x4
#define float4x2 mat4x2

#define s0 Source
#define FIX(c) (c * 1.00001)

#define NEDI_WEIGHT2 4.0
#define NEDI_N2 24.0
#define NEDI_E2 0.0
#define NEDI_OFFSET2 0.0

#define ITERATIONS  3
#define WGT   2.

#define width  (SourceSize.x)
#define height (SourceSize.y)

#define px (1.0 * (SourceSize.z))
#define py (0.4999 * (SourceSize.w))

#define offset NEDI_OFFSET2

#define Value(xy) (tex2D(s0,tex+float2(px,py)*(xy)).rgb)//-float4(0,0.4999,0.4999,0))

#define Get(xy) (dot(Value(xy),float3(.2126, .7152, .0722))+offset)
#define Get4(xy) (float2(Get(xy+WGT*dir[0])+Get(xy+WGT*dir[1]),Get(xy+WGT*dir[2])+Get(xy+WGT*dir[3])))

#define sqr(x) (dot(x,x))
#define I (float2x2(1.,0.,0.,1.))

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

//Cramer's method
float2 solve(float2x2 A,float2 b)
{
	return float2(determinant(float2x2(b,A[1])),determinant(float2x2(A[0],b)))/determinant(A);
}

void main()
{
	float2 tex = vTexCoord;

	float4 c0 = tex2D(s0,tex);

	//Skip pixels on wrong grid
	if ((frac(tex.x*width/2.0)<0.5)&&(frac(tex.y*height)<0.5) || (frac(tex.x*width/2.0)>0.5)&&(frac(tex.y*height)>0.5))
	{
		FragColor = c0;
	}
	else
	{
	
	//Define window and directions
	vec2 dir1 = vec2(-1., 0.);
	vec2 dir2 = vec2( 1., 0.);
	vec2 dir3 = vec2( 0., 1.);
	vec2 dir4 = vec2( 0.,-1.);
  	float2 dir[4] =  vec2[](dir1, dir2, dir3, dir4);

	mat4x2 wind1 = mat4x2(-1.,0.,1.,0.,0.,1.,0.,-1.);
	mat4x2 wind2 = mat4x2(-1.,0.,1.,0.,0.,1.,0.,-1.);
	mat4x2 wind3 = mat4x2(-2.,-1.,2.,1.,-1.,2.,1.,-2.);
	mat4x2 wind4 = mat4x2(-3.,-2.,3.,2.,-2.,3.,2.,-3.);
	mat4x2 wind5 = mat4x2(-2.,1.,2.,-1.,1.,2.,-1.,-2.);
	mat4x2 wind6 = mat4x2(-3.,2.,3.,-2.,2.,3.,-2.,-3.);
	mat4x2 wind7 = mat4x2(-4.,-1.,4.,1.,-1.,4.,1.,-4.);
	mat4x2 wind8 = mat4x2(-4.,1.,4.,-1.,1.,4.,-1.,-4.);
  	float4x2 wind[7] = mat4x2[](wind1, wind2, wind3, wind4, wind5, wind6, wind7);

/*
                                         wind[1]              wind[2]
-3                                                                 
-2             dir        wind[0]            2                 1 
-1              4           4          4                             4  
 0            1   2       1   2                   
 1              3           3                   3           3       
 2                                        1                       2
 3                                                                     
*/

/*
                                         wind[1]              wind[2]
-3                                            3                1   
-2             dir        wind[0] 
-1            1   4        1   3      1                                3
 0                                     
 1            3   2        2   4                  4        2    
 2
 3                                        2                        4   
*/

	//Initialization
	float2x2 R = float2x2(0.0);
	float2 r = float2(0.0);

        float m[7] = float[](NEDI_WEIGHT2, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);

	//Calculate (local) autocorrelation coefficients
	for (int k = 0; k<ITERATIONS; k+= 1){
		float4 y = float4(Get(wind[k][0]),Get(wind[k][1]),Get(wind[k][2]),Get(wind[k][3]));
		float4x2 C = float4x2(Get4(wind[k][0]),Get4(wind[k][1]),Get4(wind[k][2]),Get4(wind[k][3]));
		R += mul(transpose(C),m[k]*C);
		r += mul(y,m[k]*C);
	}
	
	//Normalize
	float n = NEDI_N2;
	R /= n; r /= n;

	//Calculate a =  R^-1 . r
	float e = NEDI_E2;
	float2 a = solve(R+e*e*I,r+e*e/2.0);

	//Nomalize 'a' (prevents overshoot)
	a = .25 + float2(.4999,-.4999)*clamp(a[0]-a[1],-1.0,1.0);

	//Calculate result
	float2x3 x = float2x3(Value(dir[0])+Value(dir[1]),Value(dir[2])+Value(dir[3])) * float2x2(a,a);
	float3 c = float3(x[0].xyz);
	
	FragColor = float4(c, 1.0);//+float4(0,0.49999,0.49999,0);
	}
} 
#endif
