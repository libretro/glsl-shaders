/*
    SNES Hires Blend Fix
    by OV2, Sp00kyFox, hunterk

Filter:    Nearest
Scale:    1x

The original shader has the problem that it blends every horizontal pair of adjacent pixels where it should only blend pairwise disjointed pixel pairs instead.

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
COMPAT_VARYING vec4 t1;

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
	vec2 ps = vec2(1.0 / TextureSize.x, 1.0 / TextureSize.y);
    float dx = ps.x;
    float dy = ps.y;
	t1 = TEX0.xxxy + vec4( -dx, 0., dx, 0.); // L, C, R
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
COMPAT_VARYING vec4 t1;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	// pixel location
	float fp = round(fract(0.5*vTexCoord.x*TextureSize.x));

	// reading the texels
	vec3 l = COMPAT_TEXTURE(Source, t1.xw).xyz;
	vec3 c = COMPAT_TEXTURE(Source, t1.yw).xyz;
	vec3 r = COMPAT_TEXTURE(Source, t1.zw).xyz;

	// output
	vec3 final;
	if (InputSize.x < 500.0) final = c;
	else
	{
		final = (((l.x == c.x)||(r.x == c.x))&&((l.y == c.y)||(r.y == c.y))&&((l.z == c.z)||(r.z == c.z))) ? c : (fp > 0.5 ? mix(c,r,0.5) : mix(c,l,0.5));
	}
	FragColor = vec4(final, 1.0);
}
#endif
