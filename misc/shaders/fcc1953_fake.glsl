/*
  FCC 1953 - look alike colors

*/

#pragma parameter bogus " [ PAL: 0.23  0.52  0.10 ] " 0.0 0.0 0.0 0.0
#pragma parameter R "Red Channel" 0.21 0.0 1.0 0.01
#pragma parameter G "Green Channel" 0.71 0.0 1.0 0.01
#pragma parameter B "Blue Channel" 0.09 0.0 1.0 0.01

#define pi 3.14159

#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float something;
#else

#define something 1.0

#endif

/* COMPATIBILITY
   - GLSL compilers
*/

uniform vec2 TextureSize;
varying vec2 TEX0;

#if defined(VERTEX)
uniform mat4 MVPMatrix;
attribute vec4 VertexCoord;
attribute vec2 TexCoord;
uniform vec2 InputSize;
uniform vec2 OutputSize;

void main()
{
	TEX0 = TexCoord;                    
	gl_Position = MVPMatrix * VertexCoord;     
}

#elif defined(FRAGMENT)

uniform sampler2D Texture;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define FragColor gl_FragColor
#define Source Texture

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float R;
uniform COMPAT_PRECISION float G;
uniform COMPAT_PRECISION float B;


#else
#define R 1.0
#define G 0.93
#define B 1.0

#endif

void main()
{
	vec3 res = texture2D(Source, vTexCoord).rgb;
	res /= vec3(R,G,B);
  	res *= vec3(0.29,0.60,0.11);
	FragColor = vec4(res, 1.0);
}
#endif
