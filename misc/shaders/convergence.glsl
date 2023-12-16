#version 110

/*
convergence pass DariusG 2023. 
Run in Linear, BEFORE actual shader pass
*/

#pragma parameter C_STR "Convergence Overall Strength" 0.0 0.0 0.5 0.05
#pragma parameter Rx "Convergence Red Horiz." 0.0 -5.0 5.0 0.05
#pragma parameter Ry "Convergence Red Vert." 0.0 -5.0 5.0 0.05
#pragma parameter Gx "Convergence Green Horiz." 0.0 -5.0 5.0 0.05
#pragma parameter Gy "Convergence Green Vert." 0.0 -5.0 5.0 0.05
#pragma parameter Bx "Convergence Blue Horiz." 0.0 -5.0 5.0 0.05
#pragma parameter By "Convergence Blue Vert." 0.0 -5.0 5.0 0.05

#define pi 3.1415926535897932384626433

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0      
   
#endif

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
uniform COMPAT_PRECISION float C_STR;
uniform COMPAT_PRECISION float Rx;
uniform COMPAT_PRECISION float Ry;
uniform COMPAT_PRECISION float Gx;
uniform COMPAT_PRECISION float Gy;
uniform COMPAT_PRECISION float Bx;
uniform COMPAT_PRECISION float By;
#else
#define C_STR 0.0
#define Rx  0.0      
#define Ry  0.0      
#define Gx  0.0      
#define Gy  0.0      
#define Bx  0.0      
#define By  0.0      
    
#endif


void main()
{
vec2 dx = vec2(SourceSize.z,0.0);
vec2 dy = vec2(0.0,SourceSize.w);
vec2 pos = vTexCoord;
vec3 res0 = COMPAT_TEXTURE(Source,pos).rgb;
float resr = COMPAT_TEXTURE(Source,pos + dx*Rx + dy*Ry).r;
float resg = COMPAT_TEXTURE(Source,pos + dx*Gx + dy*Gy).g;
float resb = COMPAT_TEXTURE(Source,pos + dx*Bx + dy*By).b;

vec3 res = vec3(  res0.r*(1.0-C_STR) +  resr*C_STR,
                  res0.g*(1.0-C_STR) +  resg*C_STR,
                  res0.b*(1.0-C_STR) +  resb*C_STR 
                   );
FragColor.rgb = res;    
}
#endif
