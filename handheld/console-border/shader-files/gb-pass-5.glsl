// Parameter lines go here:
#pragma parameter SCALE "Box Scale" 0.6667 0.6667 1.5 0.33333
#pragma parameter OUT_X "Out X" 1600.0 1600.0 4800.0 8000.0
#pragma parameter OUT_Y "Out Y" 800.0 800.0 2400.0 400.0

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
 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
COMPAT_VARYING vec2 tex_border;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SCALE;
uniform COMPAT_PRECISION float OUT_X;
uniform COMPAT_PRECISION float OUT_Y;
#else
#define SCALE 0.66667
#define OUT_X 1600.0
#define OUT_Y 800.0
#endif

void main()
{
    gl_Position =	MVPMatrix * VertexCoord;
	vec2 scale	=	(OutputSize.xy / InputSize.xy) / SCALE;
	vec2 middle	=	vec2(0.5, 0.5) * InputSize.xy / TextureSize.xy;
	vec2 diff	=	TexCoord.xy - middle;
    TEX0.xy		=	middle + diff * scale;
	middle		=	vec2(0.5, 0.5);
	tex_border	=	TEX0.xy * (TextureSize.xy / InputSize.xy);
	vec2 dist	=	tex_border - middle;
	tex_border	=	middle + dist * OutputSize.xy / vec2(OUT_X, OUT_Y) / scale;
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
uniform sampler2D BORDER;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 tex_border;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	vec4 frame	=	COMPAT_TEXTURE(Source, vTexCoord).rgba;
	vec4 border	=	COMPAT_TEXTURE(BORDER, tex_border).rgba;
	FragColor	=	vec4(mix(frame, border, border.a));
} 
#endif
