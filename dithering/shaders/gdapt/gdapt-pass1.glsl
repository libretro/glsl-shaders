/*
   Genesis Dithering and Pseudo Transparency Shader v1.3 - Pass 1
   by Sp00kyFox, 2014

   Blends pixels based on detected dithering patterns.

*/

// Parameter lines go here:
#pragma parameter STEPS "GDAPT Error Prevention LVL"	1.0 0.0 5.0 1.0
#pragma parameter DEBUG "GDAPT Adjust View"		0.0 0.0 1.0 1.0
#pragma parameter linear_gamma "Use Linear Gamma"		0.0 0.0 1.0 1.0

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
	t1 = 1.0 / SourceSize.xy;
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
COMPAT_VARYING vec2 t1;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float STEPS;
uniform COMPAT_PRECISION float DEBUG;
uniform COMPAT_PRECISION float linear_gamma;
#else
#define STEPS 1.0
#define DEBUG 0.0
#define linear_gamma 0.0
#endif

#define TEX(dx,dy) COMPAT_TEXTURE(Source, vTexCoord+vec2((dx),(dy))*t1)

void main()
{
	vec4 C = TEX( 0, 0);
	vec4 L = TEX(-1, 0);
	vec4 R = TEX( 1, 0);
	
	if(linear_gamma > 0.5)
	{
		C.xyz = pow(TEX( 0, 0).xyz, vec3(2.2)).xyz;
		L.xyz = pow(TEX(-1, 0).xyz, vec3(2.2)).xyz;
		R.xyz = pow(TEX( 1, 0).xyz, vec3(2.2)).xyz;
	}
	
	float str = 0.0;

	if(STEPS == 0.0){
		str = C.w;
	}
	else if(STEPS == 1.0){
		str = min(max(L.w, R.w), C.w);
	}
	else if(STEPS == 2.0){
		str = min(max(min(max(TEX(-2,0).w, R.w), L.w), min(R.w, TEX(2,0).w)), C.w);				
	}
	else if(STEPS == 3.0){
		float tmp = min(R.w, TEX(2,0).w);
		str = min(max(min(max(min(max(TEX(-3,0).w, R.w), TEX(-2,0).w), tmp), L.w), min(tmp, TEX(3,0).w)), C.w);
	}
	else if(STEPS == 4.0){
		float tmp1 = min(R.w, TEX(2,0).w);
		float tmp2 = min(tmp1, TEX(3,0).w);
		str = min(max(min(max(min(max(min(max(TEX(-4,0).w, R.w), TEX(-3,0).w), tmp1), TEX(-2,0).w), tmp2), L.w), min(tmp2, TEX(4,0).w)), C.w);
	}
	else{
		float tmp1 = min(R.w, TEX(2,0).w);
		float tmp2 = min(tmp1, TEX(3,0).w);
		float tmp3 = min(tmp2, TEX(4,0).w);
		str = min(max(min(max(min(max(min(max(min(max(TEX(-5,0).w, R.w), TEX(-4,0).w), tmp1), TEX(-3,0).w), tmp2), TEX(-2,0).w), tmp3), L.w), min(tmp3, TEX(5,0).w)), C.w);
	}


	if(DEBUG > 0.5)
		FragColor = vec4(str);

	float sum  = L.w + R.w;
	float wght = max(L.w, R.w);
	      wght = (wght == 0.0) ? 1.0 : sum/wght;

   vec4 final = vec4(mix(C.xyz, (wght*C.xyz + L.w*L.xyz + R.w*R.xyz)/(wght + sum), str), 1.0);
   FragColor = final;
   if(linear_gamma > 0.5) FragColor = pow(final, vec4(1.0 / 2.2));
} 
#endif
