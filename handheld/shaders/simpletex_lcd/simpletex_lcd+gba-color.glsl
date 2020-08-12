/*
	simpletex_lcd+gba-color - a simple, textured LCD shader intended for non-backlit
	systems - includes GBA colour correction
	
	- Makes use of the 'line weighting' equation from zfast_lcd_standard
	  [original zfast_lcd_standard code copyright (C) 2017 Greg Hogan (SoltanGris42)]
	
	- Colour correction code taken from 'gba-color', written by hunterk, modified by Pokefan531
	  and realeased into the public domain
	
	Other code by jdgleaver
	
	Usage notes:
	
	- Background texture size is hard-coded (I can't find a way to get this
	  automatically...). User must ensure that 'BG_TEXTURE_SIZE' define is
	  set appropriately.
	
	- Adjustable parameters:
	
	  > GRID_INTENSITY: Sets overall visibility of grid effect
	                    - 1.0: Grid is shown
	                    - 0.0: Grid is invisible (same colour as pixels)
	  > GRID_WIDTH: Sets effective with of grid lines
	                - 1.0: Normal full width
	                - 0.0: Minimum width
	                       (Note - this does not mean zero width! Instead, this
	                        is the minimum 'sane' width, below which the grid
	                        becomes pointless...)
	  > GRID_BIAS: Dynamically adjusts the grid intensity based on pixel luminosity
	               - 0.0: Grid intensity is uniform
	               - 1.0: Grid intensity scales linearly with pixel luminosity
	                      > i.e. the darker the pixel, the less the grid effect
	                        is apparent - black pixels exhibit no grid effect at all
	  > DARKEN_GRID: Darkens grid (duh...)
	                 - 0.0: Grid is white
	                 - 1.0: Grid is black
	  > DARKEN_COLOUR: Simply darkens pixel colours (effectively lowers gamma level of pixels)
	                   - 0.0: Colours are normal
	                   - 2.0: Colours are too dark...
	
	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2 of the License, or (at your option)
	any later version.
*/

// Background texture size
// > 2048 x 2048 textures are suitable for screen resolutions up to
//   1200p (or 1440p if running 'square' aspect ratio systems)
#define BG_TEXTURE_SIZE 2048.0
// > 4096 x 4096 textures are suitable for screen resolutions up to 4k
//#define BG_TEXTURE_SIZE 4096.0

#pragma parameter GRID_INTENSITY "Grid Intensity" 1.0 0.0 1.0 0.05
#pragma parameter GRID_WIDTH "Grid Width" 1.0 0.0 1.0 0.05
#pragma parameter GRID_BIAS "Grid Bias" 0.0 0.0 1.0 0.05
#pragma parameter DARKEN_GRID "Darken Grid" 0.0 0.0 1.0 0.05
#pragma parameter DARKEN_COLOUR "Darken Colours" 0.0 0.0 2.0 0.05

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
COMPAT_VARYING COMPAT_PRECISION vec2 InvInputSize;
COMPAT_VARYING COMPAT_PRECISION vec2 InvTextureSize;

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
	// Cache divisions here for efficiency...
	// (Assuming it is more efficient...?)
	InvInputSize = 1.0 / InputSize;
	InvTextureSize = 1.0 / TextureSize;
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
uniform sampler2D BACKGROUND;
COMPAT_VARYING COMPAT_PRECISION vec4 TEX0;
COMPAT_VARYING COMPAT_PRECISION vec2 InvInputSize;
COMPAT_VARYING COMPAT_PRECISION vec2 InvTextureSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float GRID_INTENSITY;
uniform COMPAT_PRECISION float GRID_WIDTH;
uniform COMPAT_PRECISION float GRID_BIAS;
uniform COMPAT_PRECISION float DARKEN_GRID;
uniform COMPAT_PRECISION float DARKEN_COLOUR;
#else
#define GRID_INTENSITY 1.0
#define GRID_WIDTH 1.0
#define GRID_BIAS 0.0
#define DARKEN_GRID 0.0
#define DARKEN_COLOUR 0.0
#endif

// ### Magic Numbers...

// Grid pattern
// > Line weighting equation:
//   y = a * (x^4 - b * x^6)
const COMPAT_PRECISION float LINE_WEIGHT_A = 48.0;
const COMPAT_PRECISION float LINE_WEIGHT_B = 8.0 / 3.0;

// RGB -> Luminosity conversion
// > Photometric/digital ITU BT.709
#define LUMA_R 0.2126
#define LUMA_G 0.7152
#define LUMA_B 0.0722
// > Digital ITU BT.601
//#define LUMA_R 0.299
//#define LUMA_G 0.587
//#define LUMA_B 0.114

// Background texture size
const COMPAT_PRECISION float INV_BG_TEXTURE_SIZE = 1.0 / BG_TEXTURE_SIZE;

// Colour correction
#define TARGET_GAMMA 2.2
const COMPAT_PRECISION float INV_DISPLAY_GAMMA = 1.0 / 2.2;
#define CC_LUM 0.94
#define CC_R 0.82
#define CC_G 0.665
#define CC_B 0.73
#define CC_RG 0.125
#define CC_RB 0.195
#define CC_GR 0.24
#define CC_GB 0.075
#define CC_BR -0.06
#define CC_BG 0.21

void main()
{
	// Get current texture coordinate
	COMPAT_PRECISION vec2 imgPixelCoord = TEX0.xy * TextureSize.xy;
	COMPAT_PRECISION vec2 imgCenterCoord = floor(imgPixelCoord.xy) + vec2(0.5, 0.5);
	
	// Get colour of current pixel
	COMPAT_PRECISION vec3 colour = COMPAT_TEXTURE(Texture, InvTextureSize.xy * imgCenterCoord.xy).rgb;
	
	// Darken colours (if required...) and apply colour correction
	colour.rgb = pow(colour.rgb, vec3(TARGET_GAMMA + 1.0 + DARKEN_COLOUR));
	colour.rgb = mat3(CC_R,  CC_RG, CC_RB,
							CC_GR, CC_G,  CC_GB,
							CC_BR, CC_BG, CC_B) * (colour.rgb * CC_LUM);
	colour.rgb = clamp(pow(colour.rgb, vec3(INV_DISPLAY_GAMMA)), 0.0, 1.0);
	
	// Generate grid pattern...
	COMPAT_PRECISION vec2 distFromCenter = abs(imgCenterCoord.xy - imgPixelCoord.xy);
	
	COMPAT_PRECISION float xSquared = max(distFromCenter.x, distFromCenter.y);
	xSquared = xSquared * xSquared;
	
	COMPAT_PRECISION float xQuarted = xSquared * xSquared;
	
	// > Line weighting equation:
	//   y = 48 * (x^4 - (8/3) * x^6)
	COMPAT_PRECISION float lineWeight = LINE_WEIGHT_A * (xQuarted - (LINE_WEIGHT_B * xQuarted * xSquared));
	
	// > Apply grid adjustments (phase 1)
	//   - GRID_WIDTH:
	//        1.0: Use raw lineWeight value
	//        0.0: Use lineWeight ^ 2 (makes lines thinner - realistically, this is
	//                                 the thinnest we can go before the grid effect
	//                                 becomes pointless, particularly with 'high resolution'
	//                                 systems like the GBA)
	//   - GRID_INTENSITY:
	//        1.0: Grid lines are white
	//        0.0: Grid lines are invisible
	lineWeight = lineWeight * (lineWeight + ((1.0 - lineWeight) * GRID_WIDTH)) * GRID_INTENSITY;
	
	// > Apply grid adjustments (phase 2)
	//   - GRID_BIAS:
	//        0.0: Use 'unbiased' lineWeight value calculated above
	//        1.0: Scale lineWeight by current pixel luminosity
	//             > i.e. the darker the pixel, the lower the intensity of the grid
	COMPAT_PRECISION float luma = (LUMA_R * colour.r) + (LUMA_G * colour.g) + (LUMA_B * colour.b);
	lineWeight = lineWeight * (luma + ((1.0 - luma) * (1.0 - GRID_BIAS)));
	
	// Apply grid pattern
	// (lineWeight == 1 -> set colour to value specified by DARKEN_GRID)
	colour.rgb = mix(colour.rgb, vec3(1.0 - DARKEN_GRID), lineWeight);
	
	// Get background sample point
	COMPAT_PRECISION vec2 bgPixelCoord = TEX0.xy * (OutputSize.xy * InvInputSize.xy) * TextureSize.xy;
	bgPixelCoord = floor(bgPixelCoord.xy) + vec2(0.5, 0.5);
	
	// Sample background texture and 'colourise' according to current pixel colour
	// (NB: the 'colourisation' here is lame, but the proper method is slow...)
	COMPAT_PRECISION vec3 bgTexture = COMPAT_TEXTURE(BACKGROUND, bgPixelCoord.xy * INV_BG_TEXTURE_SIZE).rgb * colour.rgb;
	
	// Blend current pixel with background according to luminosity
	// (lighter colour == more transparent, more visible background)
	// Note: Have to calculate luminosity a second time... tiresome, but
	// it's not a particulary expensive operation...
	luma = (LUMA_R * colour.r) + (LUMA_G * colour.g) + (LUMA_B * colour.b);
	colour.rgb = mix(colour.rgb, bgTexture.rgb, luma);
	
	gl_FragColor = vec4(colour.rgb, 1.0);
}
#endif
