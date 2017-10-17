/*
   Merge Dithering and Pseudo Transparency Shader v2.8 - Pass 1
   by Sp00kyFox, 2014

   Preparing checkerboard patterns.

*/

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

#define TEX(dx,dy) COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*SourceSize.zw)


float and(float a, float b){
	return min(a,b);
}

float and(float a, float b, float c){
	return min(a, min(b,c));
}

float or(float a, float b){
	return max(a,b);
}

float or(float a, float b, float c, float d, float e){
	return max(a, max(b, max(c, max(d,e))));
}



void main()
{
	/*
		UL U UR
		L  C R
		DL D DR
	*/

	vec3 C = TEX( 0., 0.).xyz;
	vec3 L = TEX(-1., 0.).xyz;
	vec3 R = TEX( 1., 0.).xyz;
	vec3 D = TEX( 0., 1.).xyz;
	vec3 U = TEX( 0.,-1.).xyz;

	float UL = TEX(-1.,-1.).z;
	float UR = TEX( 1.,-1.).z;
	float DL = TEX(-1., 1.).z;
	float DR = TEX( 1., 1.).z;

	// Checkerboard Pattern Completion
	float prCB = or(C.z,
		and(L.z, R.z, or(U.x, D.x)),
		and(U.z, D.z, or(L.y, R.y)),
		and(C.x, or(and(UL, UR), and(DL, DR))),
		and(C.y, or(and(UL, DL), and(UR, DR))));
   FragColor = vec4(C.x, prCB, 0.0, 0.0);
}
#endif
