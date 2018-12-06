/*
	mix_frames_smart - performs 50:50 blending between the current and 
	previous frames, but only if pixels repeatedly switch state on alternate
	frames (i.e. prevents flicker on games that use LCD ghosting for transparency,
	without blurring the entire screen). This is not 100% effective, but 'good
	enough' in many cases (e.g. it fixes map rendering issues in F-Zero GP on the GBA).
	Works best when flickering objects are in a fixed location.
	
	Author: jdgleaver
	
	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2 of the License, or (at your option)
	any later version.
*/

// User-specified fudge factor. Increasing this value loosens up the
// detection of repeated 'flicker' frames. This is required for
// games like Boktai on the GBA, where the character shadow flickers
// on and off between frames, but is sometimes overlaid with a screen
// shading effect (so checking for pixel RGB equality fails - need to
// check whether pixels are 'almost' equal)
#pragma parameter DEFLICKER_EMPHASIS "Deflicker Emphasis" 0.0 0.0 1.0 0.01

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
#ifdef GL_FRAGMENT_PRECISION_HIGH
#define COMPAT_PRECISION highp
#else
#define COMPAT_PRECISION mediump
#endif
#else
#define COMPAT_PRECISION
#endif

/* COMPATIBILITY
   - GLSL compilers
*/

COMPAT_ATTRIBUTE COMPAT_PRECISION vec4 VertexCoord;
COMPAT_ATTRIBUTE COMPAT_PRECISION vec4 COLOR;
COMPAT_ATTRIBUTE COMPAT_PRECISION vec4 TexCoord;
COMPAT_VARYING COMPAT_PRECISION vec4 COL0;
COMPAT_VARYING COMPAT_PRECISION vec4 TEX0;

COMPAT_PRECISION vec4 _oPosition1; 
uniform COMPAT_PRECISION mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
	TEX0 = TexCoord * 1.0001;
	gl_Position = MVPMatrix * VertexCoord;
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
#define COMPAT_PRECISION highp
#else
precision mediump float;
#define COMPAT_PRECISION mediump
#endif
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D PrevTexture;
uniform sampler2D Prev1Texture;
uniform sampler2D Prev2Texture;
uniform sampler2D Prev3Texture;
uniform sampler2D Prev4Texture;
COMPAT_VARYING COMPAT_PRECISION vec4 TEX0;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float DEFLICKER_EMPHASIS;
#else
#define DEFLICKER_EMPHASIS 0.0
#endif

#define EPSILON 0.000001

COMPAT_PRECISION float is_equal(COMPAT_PRECISION vec3 x, COMPAT_PRECISION vec3 y)
{
	COMPAT_PRECISION vec3 result = 1.0 - abs(sign(x - y));
	return min(min(result.r, result.g), result.b);
}

COMPAT_PRECISION float is_approx_equal(COMPAT_PRECISION vec3 x, COMPAT_PRECISION vec3 y)
{
	COMPAT_PRECISION vec3 result = 1.0 - step(EPSILON + DEFLICKER_EMPHASIS, abs(x - y));
	return min(min(result.r, result.g), result.b);
}

void main()
{
	// Get pixel colours of current + last 5 frames
	// NB: Using fewer frames results in too many false positives
	COMPAT_PRECISION vec3 colour0 = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
	COMPAT_PRECISION vec3 colour1 = COMPAT_TEXTURE(PrevTexture, TEX0.xy).rgb;
	COMPAT_PRECISION vec3 colour2 = COMPAT_TEXTURE(Prev1Texture, TEX0.xy).rgb;
	COMPAT_PRECISION vec3 colour3 = COMPAT_TEXTURE(Prev2Texture, TEX0.xy).rgb;
	COMPAT_PRECISION vec3 colour4 = COMPAT_TEXTURE(Prev3Texture, TEX0.xy).rgb;
	COMPAT_PRECISION vec3 colour5 = COMPAT_TEXTURE(Prev4Texture, TEX0.xy).rgb;
	
	// Determine whether mixing should occur
	// i.e. whether alternate frames have the same pixel colour, but
	// adjacent frames do not (don't need to check colour0 != colour1,
	// since if this is true the mixing will do nothing)
	COMPAT_PRECISION float doMix =   (1.0 - is_equal(colour0, colour3))
											 * (1.0 - is_equal(colour0, colour5))
											 * (1.0 - is_equal(colour1, colour2))
											 * (1.0 - is_equal(colour1, colour4))
											 * (1.0 - is_equal(colour2, colour3))
											 * (1.0 - is_equal(colour2, colour5))
											 * min(
													(is_approx_equal(colour0, colour2) * is_approx_equal(colour2, colour4)) +
													(is_approx_equal(colour1, colour3) * is_approx_equal(colour3, colour5)),
													1.0
												);
	
	// Mix colours
	colour0.rgb = mix(colour0.rgb, colour1.rgb, doMix * 0.5);
	
	gl_FragColor = vec4(colour0.rgb, 1.0);
}
#endif
