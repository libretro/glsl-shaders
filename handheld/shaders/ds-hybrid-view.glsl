//	DS Hybrid View
//	by hunterk
//	license: public domain
//
//	This shader requires 16:9 aspect ratio
//	and integer scaling OFF

#pragma parameter screen_toggle "Screen Toggle" 0.0 0.0 0.5 0.5
#pragma parameter aspect_correction "Aspect Correction" 1.0 0.5 5.0 0.01
#pragma parameter filter_small "Filter Small Screen" 1.0 0.0 1.0 1.0

#ifndef PARAMETER_UNIFORM
#define screen_toggle 0.0
#define aspect_correction 1.0
#define filter_small 1.0
#endif

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
// out variables go here as COMPAT_VARYING whatever

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
uniform COMPAT_PRECISION float screen_toggle, aspect_correction, filter_small;
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
	vec2 video_scale = floor(OutSize.xy / TextureSize.xy);
	vec2 integer_scale = video_scale * SourceSize.xy;
	vTexCoord = TexCoord.xy * 1.00001 * vec2(1.445 * aspect_correction,0.5);
	vTexCoord *=  InputSize / TextureSize;
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
uniform sampler2D OrigTexture;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define Ref Texture

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float screen_toggle, aspect_correction, filter_small;
#endif

void main()
{
	vec2 coord = vTexCoord * TextureSize / InputSize;
	vec2 bigCoord = coord + vec2(0.0, 0.0 + (screen_toggle * InputSize.y / TextureSize.y));
	vec2 smallCoord;
	// TODO/FIXME: I don't like this but without it the small screens get weird when the filtered scale factor is odd/even
	if (filter_small > 0.5)
	{
		smallCoord = coord * vec2(2.25) + (vec2(-2.25, 0.) * InputSize.xy / TextureSize.xy);
		FragColor = COMPAT_TEXTURE(Ref, smallCoord);
	}
	else
	{
		smallCoord = (coord * vec2(2.25) + (vec2(-2.25, 0.)) * OrigInputSize / OrigTextureSize);
		FragColor = COMPAT_TEXTURE(OrigTexture, smallCoord);
	}
	FragColor += COMPAT_TEXTURE(Ref, bigCoord);
} 
#endif
