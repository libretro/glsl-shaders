/*
CMYK Halftone Dot Shader

Adapted from Stefan Gustavson's GLSL shader demo for WebGL:
http://webstaff.itn.liu.se/~stegu/OpenGLinsights/shadertutorial.html

Ported to RetroArch by hunterk

This shader is licensed in the public domain, as per S. Gustavson's original license.
Note: the MIT-licensed noise functions have been purposely removed.
*/

#pragma parameter frequency "CMYK HalfTone Dot Density" 225.0 25.0 700.0 25.0
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
uniform float frequency;
#else
#define frequency 550.0 // controls the density of the dot pattern
#endif

void main()
{
	// Distance to nearest point in a grid of
	// (frequency x frequency) points over the unit square
	mat2 rotation_matrix = mat2(0.707, 0.707, -0.707, 0.707);
	vec2 st2 = mul(rotation_matrix , vTexCoord);
	vec2 nearest = 2.0 * fract(frequency * st2) - 1.0;
	float dist = length(nearest);
	vec3 texcolor = COMPAT_TEXTURE(Source, vTexCoord).rgb; // Unrotated coords
	vec3 black = texcolor; // kinda cheating, but it makes the colors look much better

	// Perform a rough RGB-to-CMYK conversion
	vec4 cmyk;
	cmyk.xyz = 1.0 - texcolor;
	cmyk.w = min(cmyk.x, min(cmyk.y, cmyk.z)); // Create K

	mat2 k_matrix = mat2(0.707, 0.707, -0.707, 0.707);
	vec2 Kst = frequency * (TextureSize / InputSize) * mul(k_matrix , vTexCoord);
	vec2 Kuv = 2.0 * fract(Kst) - 1.0;
	float k = step(0.0, sqrt(cmyk.w) - length(Kuv));
	mat2 c_matrix = mat2(0.966, 0.259, -0.259, 0.966);
	vec2 Cst = frequency * (TextureSize / InputSize) * mul(c_matrix , vTexCoord);
	vec2 Cuv = 2.0 * fract(Cst) - 1.0;
	float c = step(0.0, sqrt(cmyk.x) - length(Cuv));
	mat2 m_matrix = mat2(0.966, -0.259, 0.259, 0.966);
	vec2 Mst = frequency * (TextureSize / InputSize) * mul(m_matrix , vTexCoord);
	vec2 Muv = 2.0 * fract(Mst) - 1.0;
	float m = step(0.0, sqrt(cmyk.y) - length(Muv));
	vec2 Yst = frequency * (TextureSize / InputSize) * vTexCoord; // 0 deg
	vec2 Yuv = 2.0 * fract(Yst) - 1.0;
	float y = step(0.0, sqrt(cmyk.z) - length(Yuv));

	vec3 rgbscreen = 1.0 - vec3(c,m,y);
	rgbscreen = mix(rgbscreen, black, k);

	float afwidth = 2.0 * frequency * length(OutSize.zw);
	float blend = smoothstep(0.0, 1.0, afwidth);
	
	vec4 color = vec4(mix(rgbscreen , texcolor, blend), 1.0);
	color = (max(texcolor.r, max(texcolor.g, texcolor.b)) < 0.01) ? vec4(0.,0.,0.,0.) : color; // make blacks actually black

	FragColor = color;
} 
#endif
