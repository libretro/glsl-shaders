/*
   lcd1x_nds shader

   A slightly tweaked version of lcd3x:

   - Original lcd3x code written by Gigaherz and released into the public domain

   - Original 'nds_color' code written by hunterk, modified by Pokefan531 and
     released into the public domain

   Notes:

   > Omits LCD 'colour seperation' effect

   > Has 'properly' aligned scanlines

   > Includes NDS colour correction

   > Supports any NDS internal resolution setting

   Edited by jdgleaver

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter BRIGHTEN_SCANLINES "Brighten Scanlines" 16.0 1.0 32.0 0.5
#pragma parameter BRIGHTEN_LCD "Brighten LCD" 4.0 1.0 12.0 0.1

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
#define COMPAT_PRECISION highp
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
varying COMPAT_PRECISION float InvInputHeight;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;

/*
   VERTEX_SHADER
*/
void main()
{
   TEX0 = TexCoord * 1.0001;
   gl_Position = MVPMatrix * VertexCoord;
   // Cache divisions here for efficiency...
   // (Assuming it is more efficient...?)
   InvInputHeight = 1.0 / OrigInputSize.y;
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
precision highp float;
precision highp int;
#define COMPAT_PRECISION highp
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OrigInputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
varying COMPAT_PRECISION float InvInputHeight;

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float BRIGHTEN_SCANLINES;
uniform COMPAT_PRECISION float BRIGHTEN_LCD;
#else
#define BRIGHTEN_SCANLINES 16.0
#define BRIGHTEN_LCD 4.0
#endif

// Magic Numbers
#define PI 3.141592654

#define NDS_SCREEN_HEIGHT 192.0

#define TARGET_GAMMA 1.91
const float INV_DISPLAY_GAMMA = 1.0 / 1.91;
#define CC_LUM 0.89
#define CC_R 0.87
#define CC_G 0.645
#define CC_B 0.73
#define CC_RG 0.10
#define CC_RB 0.10
#define CC_GR 0.255
#define CC_GB 0.17
#define CC_BR -0.125
#define CC_BG 0.255

/*
   FRAGMENT SHADER
*/
void main()
{
   // Generate LCD grid effect
   // > Note the 0.25 pixel offset -> required to ensure that
   //   scanlines occur *between* pixels
   // > Divide pixel coordinate by current scale factor
   //   (input_video_height / nds_screen_height)
   COMPAT_PRECISION vec2 angle = 2.0 * PI *
                              (((TEX0.xy * OrigInputSize * TextureSize / InputSize) *
                                NDS_SCREEN_HEIGHT * InvInputHeight) -
                               0.25);

   COMPAT_PRECISION float yfactor = (BRIGHTEN_SCANLINES + sin(angle.y)) / (BRIGHTEN_SCANLINES + 1.0);
   COMPAT_PRECISION float xfactor = (BRIGHTEN_LCD + sin(angle.x)) / (BRIGHTEN_LCD + 1.0);

   // Get colour sample
   COMPAT_PRECISION vec3 colour = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;

   // Apply colour correction
   colour.rgb = pow(colour.rgb, vec3(TARGET_GAMMA));
   colour.rgb = mat3(CC_R,  CC_RG, CC_RB,
                     CC_GR, CC_G,  CC_GB,
                     CC_BR, CC_BG, CC_B) * (colour.rgb * CC_LUM);
   colour.rgb = clamp(pow(colour.rgb, vec3(INV_DISPLAY_GAMMA)), 0.0, 1.0);

   // Apply LCD grid effect
   colour.rgb = yfactor * xfactor * colour.rgb;

   FragColor = vec4(colour.rgb, 1.0);
} 
#endif
