/*
   Merge Dithering and Pseudo Transparency Shader v2.8 - Pass 4
   by Sp00kyFox, 2014

   Blends pixels based on detected dithering patterns.

*/

// Parameter lines go here:
#pragma parameter VL    "MDAPT Vertical Lines"	0.0 0.0 1.0 1.0
#pragma parameter CB    "MDAPT Checkerboard"	1.0 0.0 1.0 1.0
#pragma parameter DEBUG "MDAPT Adjust View"	0.0 0.0 1.0 1.0
#pragma parameter linear_gamma "MDAPT Linear Gamma Blend"	0.0 0.0 1.0 1.0

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
uniform sampler2D OrigTexture;
#define Original OrigTexture
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float VL;
uniform COMPAT_PRECISION float CB;
uniform COMPAT_PRECISION float DEBUG;
uniform COMPAT_PRECISION float linear_gamma;
#else
#define VL 0.0
#define CB 1.0
#define DEBUG 0.0
#define linear_gamma 0.0
#endif

//#define TEX(dx,dy)   COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*SourceSize.zw)
//#define TEXt0(dx,dy) COMPAT_TEXTURE(Original, vTexCoord+vec2((dx),(dy))*SourceSize.zw)

vec4 TEX(float dx, float dy){
	if(linear_gamma > 0.5) return pow(COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*SourceSize.zw), vec4(2.2));
	else return COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*SourceSize.zw);
}

vec4 TEXt0(float dx, float dy){
	if(linear_gamma > 0.5) return pow(COMPAT_TEXTURE(Original, vTexCoord+vec2((dx),(dy))*SourceSize.zw), vec4(2.2));
	else return COMPAT_TEXTURE(Original, vTexCoord+vec2((dx),(dy))*SourceSize.zw);
}

bool eq(vec3 A, vec3 B){
	return (A == B);
}

float and(float a, float b){
	return min(a,b);
}

float or(float a, float b){
	return max(a,b);
}

float or(float a, float b, float c, float d, float e, float f, float g, float h, float i){
	return max(a, max(b, max(c, max(d, max(e, max(f, max(g, max(h,i))))))));
}

vec2 and(vec2 a, vec2 b){
	return min(a,b);
}

vec2 or(vec2 a, vec2 b){
	return max(a,b);
}

vec2 or(vec2 a, vec2 b, vec2 c, vec2 d){
	return max(a, max(b, max(c,d)));
}

void main()
{
	/*
		UL U UR
		L  C R
		DL D DR
	*/

	vec4 C = TEX( 0., 0.);		vec3 c = TEXt0( 0., 0.).xyz;
	vec2 L = TEX(-1., 0.).xy;	vec3 l = TEXt0(-1., 0.).xyz;
	vec2 R = TEX( 1., 0.).xy;	vec3 r = TEXt0( 1., 0.).xyz;
	vec2 U = TEX( 0.,-1.).xy;
	vec2 D = TEX( 0., 1.).xy;

	float  prVL = 0.0,		prCB = 0.0;
	vec3 fVL  = vec3(0.0),	fCB  = vec3(0.0);


	// Backpropagation
	C.xy = or(C.xy, and(C.zw, or(L.xy, R.xy, U.xy, D.xy)));


	if(VL > 0.5){
		float prSum = L.x + R.x;

		prVL = max(L.x, R.x);
		prVL = (prVL == 0.0) ? 1.0 : prSum/prVL;

		fVL  = (prVL*c + L.x*l + R.x*r)/(prVL + prSum);
		prVL = C.x;
	}


	if(CB > 0.5){
		vec3 u = TEXt0( 0.,-1.).xyz;
		vec3 d = TEXt0( 0., 1.).xyz;

		float eqCL = float(eq(c,l));
		float eqCR = float(eq(c,r));
		float eqCU = float(eq(c,u));
		float eqCD = float(eq(c,d));

		float prU = or(U.y, eqCU);
		float prD = or(D.y, eqCD);
		float prL = or(L.y, eqCL);
		float prR = or(R.y, eqCR);


		float prSum = prU  + prD  + prL  + prR;

		prCB = max(prL, max(prR, max(prU,prD)));
		prCB = (prCB == 0.0) ? 1.0 : prSum/prCB;

		//standard formula: C/2 + (L + R + D + U)/8
		fCB = (prCB*c + prU*u + prD*d + prL*l + prR*r)/(prCB + prSum);


		float UL = TEX(-1.,-1.).y;	vec3 ul = TEXt0(-1.,-1.).xyz;
		float UR = TEX( 1.,-1.).y;	vec3 ur = TEXt0( 1.,-1.).xyz;
		float DL = TEX(-1., 1.).y;	vec3 dl = TEXt0(-1., 1.).xyz;
		float DR = TEX( 1., 1.).y;	vec3 dr = TEXt0( 1., 1.).xyz;

		// Checkerboard Smoothing
		prCB = or(C.y, and(L.y, eqCL), and(R.y, eqCR), and(U.y, eqCU), and(D.y, eqCD), and(UL, float(eq(c,ul))), and(UR, float(eq(c,ur))), and(DL, float(eq(c,dl))), and(DR, float(eq(c,dr))));
	}


	if(DEBUG > 0.5)
		FragColor = vec4(prVL, prCB, 0.0, 0.0);

	vec4 final = (prCB >= prVL) ? vec4(mix(c, fCB, prCB), 1.0) : vec4(mix(c, fVL, prVL), 1.0);
	FragColor = (linear_gamma > 0.5) ? pow(final, vec4(1.0 / 2.2)) : final;
}
#endif
