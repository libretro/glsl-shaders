// Cocktail Table Portrait
// by hunterk
// license: public domain

#pragma parameter width "Cocktail Width" 1.0 0.0 2.0 0.01
#pragma parameter height "Cocktail Height" 0.49 0.0 2.0 0.01
#pragma parameter x_loc "Cocktail X Mod" 0.0 -2.0 2.0 0.01
#pragma parameter y_loc "Cocktail Y Mod" 0.51 -2.0 2.0 0.01

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float width, height, x_loc, y_loc;
#else
#define width 1.0
#define height 0.49
#define x_loc 0.0
#define y_loc 0.51
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
	TEX0.xy = TEX0.xy - 0.5 * InputSize / TextureSize;
	TEX0.xy = TEX0.xy * vec2(1. / width, 1. / height);
	TEX0.xy = TEX0.xy + 0.5 * InputSize / TextureSize;
	t1.xy = 1.* InputSize / TextureSize - TEX0.xy;
	TEX0.xy -= vec2(x_loc, y_loc) * InputSize / TextureSize;
	t1.xy -= vec2(x_loc, y_loc) * InputSize / TextureSize;
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

void main()
{
	vec4 screen1 = COMPAT_TEXTURE(Source, vTexCoord);
	screen1 *= float(vTexCoord.x > 0.0001) * float(vTexCoord.y > 0.0001) * float(vTexCoord.x < 0.9999) * float(vTexCoord.y < 0.9999);
	vec4 screen2 = COMPAT_TEXTURE(Source, t1);
	screen2 *= float(t1.x > 0.0001) * float(t1.y > 0.0001) * float(t1.x < 0.9999) * float(t1.y < 0.9999);
	FragColor = screen1 + screen2;
} 
#endif
