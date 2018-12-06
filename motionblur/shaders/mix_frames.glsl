/*
	mix_frames - performs 50:50 blending between the current and previous
	frames.
	
	Author: jdgleaver
	
	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2 of the License, or (at your option)
	any later version.
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
COMPAT_VARYING COMPAT_PRECISION vec4 TEX0;

void main()
{
	// Get colour of current pixel
	COMPAT_PRECISION vec3 colour = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
	
	// Get colour of previous pixel
	COMPAT_PRECISION vec3 colourPrev = COMPAT_TEXTURE(PrevTexture, TEX0.xy).rgb;
	
	// Mix colours
	colour.rgb = mix(colour.rgb, colourPrev.rgb, 0.5);
	
	gl_FragColor = vec4(colour.rgb, 1.0);
}
#endif
