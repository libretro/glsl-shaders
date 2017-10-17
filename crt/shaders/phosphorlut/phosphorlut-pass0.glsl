// Parameter lines go here:
#pragma parameter PHOSPHOR_SCALE_X "Phosphor Scale X" 2.0 1.0 12.0 1.0
#pragma parameter PHOSPHOR_SCALE_Y "Phosphor Scale Y" 4.0 1.0 12.0 1.0
#pragma parameter phosphor_layout "Phosphor Layout" 1.0 1.0 3.0 1.0

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

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
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
uniform sampler2D Pass1Texture;
uniform sampler2D shadow;
uniform sampler2D aperture;
uniform sampler2D slot;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PHOSPHOR_SCALE_X;
uniform COMPAT_PRECISION float PHOSPHOR_SCALE_Y;
uniform COMPAT_PRECISION float phosphor_layout;
#else
#define PHOSPHOR_SCALE_X 2.0
#define PHOSPHOR_SCALE_Y 4.0
#define phosphor_layout 1.0
#endif

#define firstPass Pass1Texture

void main()
{
	vec2 LUTeffectiveCoord = vec2(fract(vTexCoord.x * SourceSize.x / PHOSPHOR_SCALE_X), fract(vTexCoord.y * SourceSize.y / PHOSPHOR_SCALE_Y));
	vec4 phosphor_grid;

	vec4 screen = vec4(COMPAT_TEXTURE(firstPass, vTexCoord).rgb, 1.0);
	if (phosphor_layout == 1.0) phosphor_grid = vec4(COMPAT_TEXTURE(shadow, LUTeffectiveCoord).rgb, 1.0);
	if (phosphor_layout == 2.0) phosphor_grid = vec4(COMPAT_TEXTURE(aperture, LUTeffectiveCoord).rgb, 1.0);
	if (phosphor_layout == 3.0) phosphor_grid = vec4(COMPAT_TEXTURE(slot, LUTeffectiveCoord).rgb, 1.0);
   FragColor = screen * phosphor_grid;
} 
#endif
