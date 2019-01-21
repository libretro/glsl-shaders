/*
   Merge Dithering and Pseudo Transparency Shader v2.8 - Pass 0
   by Sp00kyFox, 2014

   Neighbor analysis via color metric and dot product of the difference vectors.

*/

// Parameter lines go here:
#pragma parameter MODE "MDAPT Monochrome Analysis"	0.0 0.0 1.0 1.0
#pragma parameter PWR  "MDAPT Color Metric Exp"		2.0 0.0 10.0 0.1

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
uniform COMPAT_PRECISION float MODE;
uniform COMPAT_PRECISION float PWR;
#else
#define MODE 0.0
#define PWR 2.0
#endif

#define dotfix(x,y) clamp(dot(x,y), 0.0, 1.0)	// NVIDIA Fix
#define TEX(dx,dy) COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*SourceSize.zw)

// Reference: http://www.compuphase.com/cmetric.htm
float eq(vec3 A, vec3 B)
{
	vec3 diff = A-B;
	float  ravg = (A.x + B.x) * 0.5;

	diff *= diff * vec3(2.0 + ravg, 4.0, 3.0 - ravg);

	return pow( smoothstep(3.0, 0.0, sqrt(diff.x + diff.y + diff.z)), PWR );
}

float and(float a, float b, float c, float d, float e, float f){
	return min(a, min(b, min(c, min(d, min(e,f)))));
}

void main()
{
	/*
		  U
		L C R
		  D
	*/

	vec3 C = TEX( 0., 0.).xyz;
	vec3 L = TEX(-1., 0.).xyz;
	vec3 R = TEX( 1., 0.).xyz;
	vec3 U = TEX( 0.,-1.).xyz;
	vec3 D = TEX( 0., 1.).xyz;


	vec3 res = vec3(0.0);

	if(MODE > 0.5){
		res.x = float((L == R) && (C != L));
		res.y = float((U == D) && (C != U));
		res.z = float(bool(res.x) && bool(res.y) && (L == U));
	}
	else{
		vec3 dCL = normalize(C-L), dCR = normalize(C-R), dCD = normalize(C-D), dCU = normalize(C-U);

		res.x = dotfix(dCL, dCR) * eq(L,R);
		res.y = dotfix(dCU, dCD) * eq(U,D);
		res.z = and(res.x, res.y, dotfix(dCL, dCU) * eq(L,U), dotfix(dCL, dCD) * eq(L,D), dotfix(dCR, dCU) * eq(R,U), dotfix(dCR, dCD) * eq(R,D));
	}

   FragColor = vec4(res, 1.0);
}
#endif
