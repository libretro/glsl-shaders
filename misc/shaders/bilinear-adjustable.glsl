/*
	Bilinear adjustable, by DariusG @2023.
	Inspired by crt-pi and Zfast-crt filters.
*/


#pragma parameter BLURX "Blur strength X" 0.8 0.0 1.0 0.1
#pragma parameter BLURY "Blur strength Y" 0.4 0.0 1.0 0.1

#define pi 3.14159

#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif


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
uniform vec2 OutputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define FragColor gl_FragColor
#define Source Texture


#ifdef PARAMETER_UNIFORM

uniform COMPAT_PRECISION float BLURX;
uniform COMPAT_PRECISION float BLURY;

#else

#define BLURX 1.0
#define BLURY 1.0

#endif


void main()
{
	vec2 blurry = vTexCoord;
	vec2 OGL2Pos = blurry*SourceSize.xy;
	vec2 inverse = floor(OGL2Pos)+0.5;
	vec2 nearest = inverse*SourceSize.zw;
	vec2 coords;
	 coords.x = mix(nearest.x, blurry.x, BLURX);
	 coords.y = mix(nearest.y, blurry.y, BLURY);

	vec3 res = texture2D(Source, coords).rgb;

	FragColor = vec4(res, 1.0);
}
#endif