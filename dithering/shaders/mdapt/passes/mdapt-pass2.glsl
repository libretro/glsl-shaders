/*
   Merge Dithering and Pseudo Transparency Shader v2.8 - Pass 2
   by Sp00kyFox, 2014

   Eliminating isolated detections.

*/

// Parameter lines go here:
#pragma parameter VL_LO "MDAPT VL LO Thresh" 1.25 0.0 10.0 0.05
#pragma parameter VL_HI "MDAPT VL HI Thresh" 1.75 0.0 10.0 0.05
#pragma parameter CB_LO "MDAPT CB LO Thresh" 5.25 0.0 25.0 0.05
#pragma parameter CB_HI "MDAPT CB HI Thresh" 5.75 0.0 25.0 0.05

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
    TEX0.xy = TexCoord.xy;
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float VL_LO;
uniform COMPAT_PRECISION float VL_HI;
uniform COMPAT_PRECISION float CB_LO;
uniform COMPAT_PRECISION float CB_HI;
#else
#define VL_LO 1.25
#define VL_HI 1.75
#define CB_LO 5.25
#define CB_HI 5.75
#endif

#define TEX(dx,dy) COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*SourceSize.zw)
#define and(x,y) min(x,y)
#define or(x,y)  max(x,y)

vec2 sigmoid(vec2 signal){
	return smoothstep(vec2(VL_LO, CB_LO), vec2(VL_HI, CB_HI), signal);
}

void main()
{
	/*
		NW  UUL U2 UUR NE
		ULL UL  U1 UR  URR
		L2  L1  C  R1  R2
		DLL DL  D1 DR  DRR
		SW  DDL D2 DDR SE
	*/

	vec2 C = TEX( 0., 0.).xy;


	vec2 hits = vec2(0.0);

	//phase 1
	vec2 L1 = TEX(-1., 0.).xy;
	vec2 R1 = TEX( 1., 0.).xy;
	vec2 U1 = TEX( 0.,-1.).xy;
	vec2 D1 = TEX( 0., 1.).xy;

	//phase 2
	vec2 L2 = and(TEX(-2., 0.).xy, L1);
	vec2 R2 = and(TEX( 2., 0.).xy, R1);
	vec2 U2 = and(TEX( 0.,-2.).xy, U1);
	vec2 D2 = and(TEX( 0., 2.).xy, D1);
	vec2 UL = and(TEX(-1.,-1.).xy, or(L1, U1));
	vec2 UR = and(TEX( 1.,-1.).xy, or(R1, U1));
	vec2 DL = and(TEX(-1., 1.).xy, or(L1, D1));
	vec2 DR = and(TEX( 1., 1.).xy, or(R1, D1));

	//phase 3
	vec2 ULL = and(TEX(-2.,-1.).xy, or(L2, UL));
	vec2 URR = and(TEX( 2.,-1.).xy, or(R2, UR));
	vec2 DRR = and(TEX( 2., 1.).xy, or(R2, DR));
	vec2 DLL = and(TEX(-2., 1.).xy, or(L2, DL));
	vec2 UUL = and(TEX(-1.,-2.).xy, or(U2, UL));
	vec2 UUR = and(TEX( 1.,-2.).xy, or(U2, UR));
	vec2 DDR = and(TEX( 1., 2.).xy, or(D2, DR));
	vec2 DDL = and(TEX(-1., 2.).xy, or(D2, DL));

	//phase 4
	hits += and(TEX(-2.,-2.).xy, or(UUL, ULL));
	hits += and(TEX( 2.,-2.).xy, or(UUR, URR));
	hits += and(TEX(-2., 2.).xy, or(DDL, DLL));
	hits += and(TEX( 2., 2.).xy, or(DDR, DRR));

	hits += (ULL + URR + DRR + DLL + L2 + R2) + vec2(0.0, 1.0) * (C + U1 + U2 + D1 + D2 + L1 + R1 + UL + UR + DL + DR + UUL + UUR + DDR + DDL);

   FragColor = vec4(C * sigmoid(hits), C);
}
#endif
