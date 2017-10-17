#version 130

/*
	Scale2xSFX
	by Sp00kyFox, 2015

Filter:	Nearest
Scale:	2x

Scale2SFX improves upon the original Scale2x (aka EPX) by avoiding the occurence of artifacts.

*/

// Parameter lines go here:
#pragma parameter YTR "SCALE2xSFX Y Threshold" 48.0 0.0 255.0 1.0
#pragma parameter UTR "SCALE2xSFX U Threshold"  7.0 0.0 255.0 1.0
#pragma parameter VTR "SCALE2xSFX V Threshold"  6.0 0.0 255.0 1.0

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
#define float4x3 mat4x3

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
COMPAT_VARYING vec4 t3;
COMPAT_VARYING vec4 t4;
COMPAT_VARYING vec4 t5;

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
    TEX0.xy = TexCoord.xy;
   	float2 ps = float2(SourceSize.z, SourceSize.w);
	float dx = ps.x;
	float dy = ps.y;

	t1 = TEX0.xxxy + float4(-dx,  0., dx,-dy);	// A, B, C
	t2 = TEX0.xxxy + float4(-dx,  0., dx,  0.);	// D, E, F
	t3 = TEX0.xxxy + float4(-dx,  0., dx, dy);	// G, H, I
	t4 = TEX0.xyxy + float4(    0.,-2.*dy,-2.*dx,    0.);	// J, K
	t5 = TEX0.xyxy + float4( 2.*dx,    0.,    0., 2.*dy);	// L, M
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

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float YTR;
uniform COMPAT_PRECISION float UTR;
uniform COMPAT_PRECISION float VTR;
#else
#define YTR 48.0
#define UTR 7.0
#define VTR 6.0
#endif

mat3 YUV  = mat3(0.299, -0.168736, 0.5, 0.587, -0.331264, -0.418688, 0.114, 0.5, -0.081312);	// transponed
float3 thresh = float3(0.188235294, 0.02745098, 0.023529412);

bool eq(float3 A, float3 B){
	return (A==B);
}

bool neq(float3 A, float3 B){
	return (A!=B);
}

void main()
{
	// subpixel determination
	float2 fp = floor(2.0 * frac(vTexCoord*SourceSize.xy));

	/*
		    J
		  A B C		E0 E1
		K D E F L	E2 E3
		  G H I
		    M
	*/

	// reading the texels & colorspace conversion
	float3 b = tex2D(decal, t1.yw).xyz;
	float3 d = tex2D(decal, t2.xw).xyz;
	float3 e = tex2D(decal, t2.yw).xyz;
	float3 f = tex2D(decal, t2.zw).xyz;
	float3 h = tex2D(decal, t3.yw).xyz;

	float4x3 tmp = mul(float4x3(b,d,e,f), YUV);
	float3 B = tmp[0], D = tmp[1], E = tmp[2], F = tmp[3], H = mul(h, YUV);

	float3 A = tex2D(decal, t1.xw).xyz;
	float3 C = tex2D(decal, t1.zw).xyz;
	float3 G = tex2D(decal, t3.xw).xyz;
	float3 I = tex2D(decal, t3.zw).xyz;

	tmp = mul(float4x3(A,C,G,I), YUV);
	A = tmp[0], C = tmp[1], G = tmp[2], I = tmp[3];

	float3 J = tex2D(decal, t4.xy).xyz;
	float3 K = tex2D(decal, t4.zw).xyz;
	float3 L = tex2D(decal, t5.xy).xyz;
	float3 M = tex2D(decal, t5.zw).xyz;

	tmp = mul(float4x3(J,K,L,M), YUV);
	J = tmp[0], K = tmp[1], L = tmp[2], M = tmp[3];



	// parent condition
	bool par0 = neq(B,F) && neq(D,H);
	bool par1 = neq(B,D) && neq(F,H);

	// equality checks
	bool AE = eq(A,E), CE = eq(C,E), EG = eq(E,G), EI = eq(E,I);

	// artifact prevention
	bool art0 = CE || EG;
	bool art1 = AE || EI;



	// rules
	float3 E0 = eq(B,D) && par0 && (!AE || art0 || eq(A,J) || eq(A,K)) ? 0.5*(b+d) : e;
	float3 E1 = eq(B,F) && par1 && (!CE || art1 || eq(C,J) || eq(C,L)) ? 0.5*(b+f) : e;
	float3 E2 = eq(D,H) && par1 && (!EG || art1 || eq(G,K) || eq(G,M)) ? 0.5*(h+d) : e;
	float3 E3 = eq(F,H) && par0 && (!EI || art0 || eq(I,L) || eq(I,M)) ? 0.5*(h+f) : e;

	// subpixel output
	FragColor = vec4(fp.y == 0. ? (fp.x == 0. ? E0 : E1) : (fp.x == 0. ? E2 : E3), 1.0);
} 
#endif
