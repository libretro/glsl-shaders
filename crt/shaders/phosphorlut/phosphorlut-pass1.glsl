// Parameter lines go here:
#pragma parameter diffusion "Halation Strength" 0.5 0.0 1.0 0.01
#pragma parameter out_gamma "Display Gamma" 2.2 1.5 3.0 0.1

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
uniform sampler2D Pass2Texture;
uniform sampler2D Pass3Texture;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float diffusion;
uniform COMPAT_PRECISION float out_gamma;
#else
#define diffusion 0.5
#define out_gamma 2.2
#endif

#define firstPass Pass1Texture
#define blurPassV Pass2Texture
#define blurPass Pass3Texture
#define phosphorPass Texture

void main()
{
#if __VERSION__ < 130 // linearize these textures if srgb_framebuffers aren't guaranteed
	vec3 scanlines = pow(COMPAT_TEXTURE(firstPass, vTexCoord).rgb, vec3(2.2));
//	vec3 blurV = pow(COMPAT_TEXTURE(blurPassV, vTexCoord).rgb, vec3(2.2));
	vec3 blurH = pow(COMPAT_TEXTURE(blurPass, vTexCoord).rgb, vec3(2.2));
	vec3 phosphors = pow(COMPAT_TEXTURE(phosphorPass, vTexCoord).rgb, vec3(2.2));
#else
	vec3 scanlines = COMPAT_TEXTURE(firstPass, vTexCoord).rgb;
//	vec3 blurV = COMPAT_TEXTURE(blurPassV, vTexCoord).rgb;
	vec3 blurH = COMPAT_TEXTURE(blurPass, vTexCoord).rgb;
	vec3 phosphors = COMPAT_TEXTURE(phosphorPass, vTexCoord).rgb;
#endif
	vec3 blurLines = (scanlines + blurH) / 2.0;
	vec3 glow = (phosphors + blurH) / 2.0;
	vec3 halation = mix(blurLines, phosphors, diffusion);
	//vec3 halation = 1.0 - (1.0 - phosphors) * (1.0 - blurLines);
	halation = 1.0 - (1.0 - halation) * (1.0 - scanlines);
   FragColor = vec4(pow(halation, vec3(1.0 / out_gamma)), 1.0);
} 
#endif
