/*
   Scale2xPlus shader 

   - Copyright (C) 2007 guest(r) - guest.r@gmail.com

   - License: GNU-GPL  


   The Scale2x algorithm:

   - Scale2x Homepage: http://scale2x.sourceforge.net/

   - Copyright (C) 2001, 2002, 2003, 2004 Andrea Mazzoleni 

   - License: GNU-GPL  

 */
 
#define saturate(c) clamp(c, 0.0, 1.0)
#define lerp(a,b,c) mix(a,b,c)
#define mul(a,b) (b*a)
#define fmod(c,d) mod(c,d)
#define frac(c) fract(c)
#define tex2D(c,d) COMPAT_TEXTURE(c,d)
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
#define float3x3 mat3x3
#define float4x4 mat4x4

#define decal Source

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy; // E
   	float2 ps = float2(SourceSize.z, SourceSize.w);
	float dx = ps.x;
	float dy = ps.y;

	t1 = TEX0.xyxy + float4(  0,-dy,-dx,  0);	// B, D
	t2 = TEX0.xyxy + float4( dx,  0,  0, dy);	// F, H	
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

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
   float2 fp = frac(vTexCoord*SourceSize.xy);

   // Reading the texels

   float3 B = tex2D(decal, t1.xy).xyz;
   float3 D = tex2D(decal, t1.zw).xyz;
   float3 E = tex2D(decal, vTexCoord).xyz;
   float3 F = tex2D(decal, t2.xy).xyz;
   float3 H = tex2D(decal, t2.zw).xyz;

   float3 E0 = D == B && B != H && D != F ? D : E;
   float3 E1 = B == F && B != H && D != F ? F : E;
   float3 E2 = D == H && B != H && D != F ? D : E;
   float3 E3 = H == F && B != H && D != F ? F : E;

   // Product interpolation
   FragColor = float4((E3*fp.x+E2*(1.-fp.x))*fp.y+(E1*fp.x+E0*(1.-fp.x))*(1.-fp.y),1.);
} 
#endif
