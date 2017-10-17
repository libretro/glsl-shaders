#version 130

/*
	Bilateral v1.0
	by Sp00kyFox, 2014

Bilateral Filter, calculates a weighted mean of surrounding pixels based on color and spatial distance.
This can be used to smooth color transitions or blend dithering to some extent while preserving sharp edges.
Increasing the radius leads to more pixel lookups and therefore to a lower shader performance.

*/

// Parameter lines go here:
#pragma parameter RAD "Bilateral Radius" 2.00 0.00 5.0 0.25
#pragma parameter CLR "Bilateral Color Thresh" 0.15 0.01 1.0 0.01
#pragma parameter CWGHT "Bilateral Central Wght" 0.25 0.0 2.0 0.05

#define TEX(dx,dy) COMPAT_TEXTURE(Source, vTexCoord + vec2((dx),(dy)) * t1)
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
COMPAT_VARYING vec2 t1;

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
	t1 = 1.0 / SourceSize.xy;
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
COMPAT_VARYING vec2 t1;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float RAD;
uniform COMPAT_PRECISION float CLR;
uniform COMPAT_PRECISION float CWGHT;
#else
#define RAD 2.0
#define CLR 0.15
#define CWGHT 0.25
#endif

const vec4 unit4  = vec4(1.0);

int   steps = int(ceil(RAD));
float clr   = -CLR * CLR;
float sigma = RAD * RAD / 2.0;
float cwght = 1.0 + CWGHT * max(1.0, 2.87029746*sigma + 0.43165242*RAD - 0.25219746);

float domain[13] = float[13](1.0, exp( -1.0/sigma), exp( -4.0/sigma), exp( -9.0/sigma), exp( -16.0/sigma), exp( -25.0/sigma), exp( -36.0/sigma),
				exp(-49.0/sigma), exp(-64.0/sigma), exp(-81.0/sigma), exp(-100.0/sigma), exp(-121.0/sigma), exp(-144.0/sigma));

float dist2(vec3 pt1, vec3 pt2)
{
	vec3 v = pt1 - pt2;
	return dot(v,v);
}

vec4 weight(int i, int j, vec3 org, mat4x3 A)
{
	return domain[i] * domain[j] * exp(vec4(dist2(org,A[0]), dist2(org,A[1]), dist2(org,A[2]), dist2(org,A[3]))/clr);
}

void main()
{
	mat4x3 A, B;
	vec4 wghtA, wghtB;
	vec3 org = TEX(0.,0.).rgb, result = cwght*org;
	float  norm = cwght;
	
// GLSL doesn't like non-constants in loop initialization, so we have to
//   use if statements with parameters/variables instead :(
	if(int(ceil(RAD)) == 2){
		for(int x = 1; x <= 2; x++){
		
			A = mat4x3(TEX( x, 0.).rgb, TEX(-x, 0.).rgb, TEX( 0., x).rgb, TEX( 0.,-x).rgb);
			B = mat4x3(TEX( x, x).rgb, TEX( x,-x).rgb, TEX(-x, x).rgb, TEX(-x,-x).rgb);

			wghtA = weight(x, 0, org, A); wghtB = weight(x, x, org, B);	

			result += mul(wghtA, A)     + mul(wghtB, B);
			norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
		
			for(int y = 1; y < x; y++){
					
				A = mat4x3(TEX( x, y).rgb, TEX( x,-y).rgb, TEX(-x, y).rgb, TEX(-x,-y).rgb);
				B = mat4x3(TEX( y, x).rgb, TEX( y,-x).rgb, TEX(-y, x).rgb, TEX(-y,-x).rgb);

				wghtA = weight(x, y, org, A); wghtB = weight(y, x, org, B);	

				result += mul(wghtA, A)     + mul(wghtB, B);
				norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
			}
		}
	}
	else if(int(ceil(RAD)) == 3){
		for(int x = 1; x <= 3; x++){
		
			A = mat4x3(TEX( x, 0.).rgb, TEX(-x, 0.).rgb, TEX( 0., x).rgb, TEX( 0.,-x).rgb);
			B = mat4x3(TEX( x, x).rgb, TEX( x,-x).rgb, TEX(-x, x).rgb, TEX(-x,-x).rgb);

			wghtA = weight(x, 0, org, A); wghtB = weight(x, x, org, B);	

			result += mul(wghtA, A)     + mul(wghtB, B);
			norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
		
			for(int y = 1; y < x; y++){
					
				A = mat4x3(TEX( x, y).rgb, TEX( x,-y).rgb, TEX(-x, y).rgb, TEX(-x,-y).rgb);
				B = mat4x3(TEX( y, x).rgb, TEX( y,-x).rgb, TEX(-y, x).rgb, TEX(-y,-x).rgb);

				wghtA = weight(x, y, org, A); wghtB = weight(y, x, org, B);	

				result += mul(wghtA, A)     + mul(wghtB, B);
				norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
			}
		}
	}
	else if(int(ceil(RAD)) == 4){
		for(int x = 1; x <= 4; x++){
		
			A = mat4x3(TEX( x, 0.).rgb, TEX(-x, 0.).rgb, TEX( 0., x).rgb, TEX( 0.,-x).rgb);
			B = mat4x3(TEX( x, x).rgb, TEX( x,-x).rgb, TEX(-x, x).rgb, TEX(-x,-x).rgb);

			wghtA = weight(x, 0, org, A); wghtB = weight(x, x, org, B);	

			result += mul(wghtA, A)     + mul(wghtB, B);
			norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
		
			for(int y = 1; y < x; y++){
					
				A = mat4x3(TEX( x, y).rgb, TEX( x,-y).rgb, TEX(-x, y).rgb, TEX(-x,-y).rgb);
				B = mat4x3(TEX( y, x).rgb, TEX( y,-x).rgb, TEX(-y, x).rgb, TEX(-y,-x).rgb);

				wghtA = weight(x, y, org, A); wghtB = weight(y, x, org, B);	

				result += mul(wghtA, A)     + mul(wghtB, B);
				norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
			}
		}
	}
	else if(int(ceil(RAD)) == 5){
		for(int x = 1; x <= 5; x++){
		
			A = mat4x3(TEX( x, 0.).rgb, TEX(-x, 0.).rgb, TEX( 0., x).rgb, TEX( 0.,-x).rgb);
			B = mat4x3(TEX( x, x).rgb, TEX( x,-x).rgb, TEX(-x, x).rgb, TEX(-x,-x).rgb);

			wghtA = weight(x, 0, org, A); wghtB = weight(x, x, org, B);	

			result += mul(wghtA, A)     + mul(wghtB, B);
			norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
		
			for(int y = 1; y < x; y++){
					
				A = mat4x3(TEX( x, y).rgb, TEX( x,-y).rgb, TEX(-x, y).rgb, TEX(-x,-y).rgb);
				B = mat4x3(TEX( y, x).rgb, TEX( y,-x).rgb, TEX(-y, x).rgb, TEX(-y,-x).rgb);

				wghtA = weight(x, y, org, A); wghtB = weight(y, x, org, B);	

				result += mul(wghtA, A)     + mul(wghtB, B);
				norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
			}
		}
	}
	else if(int(ceil(RAD)) == 1){
		for(int x = 1; x <= 1; x++){
		
			A = mat4x3(TEX( x, 0.).rgb, TEX(-x, 0.).rgb, TEX( 0., x).rgb, TEX( 0.,-x).rgb);
			B = mat4x3(TEX( x, x).rgb, TEX( x,-x).rgb, TEX(-x, x).rgb, TEX(-x,-x).rgb);

			wghtA = weight(x, 0, org, A); wghtB = weight(x, x, org, B);	

			result += mul(wghtA, A)     + mul(wghtB, B);
			norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
		
			for(int y = 1; y < x; y++){
					
				A = mat4x3(TEX( x, y).rgb, TEX( x,-y).rgb, TEX(-x, y).rgb, TEX(-x,-y).rgb);
				B = mat4x3(TEX( y, x).rgb, TEX( y,-x).rgb, TEX(-y, x).rgb, TEX(-y,-x).rgb);

				wghtA = weight(x, y, org, A); wghtB = weight(y, x, org, B);	

				result += mul(wghtA, A)     + mul(wghtB, B);
				norm   += dot(wghtA, unit4) + dot(wghtB, unit4);
			}
		}
	}
    FragColor = vec4(result/norm, 1.0);
} 
#endif
