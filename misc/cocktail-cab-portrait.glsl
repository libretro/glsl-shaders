#pragma parameter height "CocktailTable Image Height" 1.99 -3.0 3.0 0.01
#pragma parameter width "CocktailTable Image Width" 0.8 -5.0 5.0 0.05
#pragma parameter location "CocktailTable Image Location" -0.235 -2.0 2.0 0.005
#pragma parameter zoom "CocktailTable Zoom" 0.51 -2.0 5.0 0.01

#define mul(a,b) (b*a)

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
uniform COMPAT_PRECISION float height;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float location;
uniform COMPAT_PRECISION float zoom;
#else
#define height 1.99
#define width 0.8
#define location -0.235
#define zoom 0.51
#endif

void main()
{
	mat4 RotationMatrix = mat4( height, 0.0, 0.0, 0.0,
         0.0, width, 0.0, 0.0,
         0.0, 0.0, 1.0, 0.0,
         0.0, 0.0, 0.0, 1.0 );
	gl_Position = mul((MVPMatrix * VertexCoord), RotationMatrix);
	vec2 shift = 0.5 * InputSize.xy / TextureSize.xy;
	TEX0.xy = ((TexCoord.xy-shift) / zoom) + shift;
	t1 = ((mat2(-1.0, 0.0, 0.0, -1.0) * (TexCoord.xy - shift)) / zoom) + shift;
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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float height;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float location;
uniform COMPAT_PRECISION float zoom;
#endif

void main()
{
    FragColor = COMPAT_TEXTURE(Source, vTexCoord + vec2(0.0, location)) + COMPAT_TEXTURE(Source, t1 + vec2(0.0, location));
} 
#endif
