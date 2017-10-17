///////////////////////////////////////////////////////////////////////////
//                                                                       //
// Gameboy Classic Shader v0.2.2                                         //
//                                                                       //
// Copyright (C) 2013 Harlequin : unknown92835@gmail.com                 //
//                                                                       //
// This program is free software: you can redistribute it and/or modify  //
// it under the terms of the GNU General Public License as published by  //
// the Free Software Foundation, either version 3 of the License, or     //
// (at your option) any later version.                                   //
//                                                                       //
// This program is distributed in the hope that it will be useful,       //
// but WITHOUT ANY WARRANTY; without even the implied warranty of        //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         //
// GNU General Public License for more details.                          //
//                                                                       //
// You should have received a copy of the GNU General Public License     //
// along with this program.  If not, see <http://www.gnu.org/licenses/>. //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Config                                                                     //
////////////////////////////////////////////////////////////////////////////////

// 0 - only the space between dots is blending
// 1 - all texels are blended
#pragma parameter blending_mode "Blending Mode" 0.0 0.0 1.0 1.0            

// The amount of alpha swapped between neighboring texels
#pragma parameter adjacent_texel_alpha_blending "Neighbor Blending" 0.38 0.0 1.0 0.05

#if defined(VERTEX)
////////////////////////////////////////////////////////////////////////////////
// Vertex shader                                                              //
////////////////////////////////////////////////////////////////////////////////

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
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 blur_coords_up;
COMPAT_VARYING vec2 blur_coords_down;
COMPAT_VARYING vec2 blur_coords_right;
COMPAT_VARYING vec2 blur_coords_left;
COMPAT_VARYING vec2 blur_coords_lower_bound;
COMPAT_VARYING vec2 blur_coords_upper_bound;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;

    texel = SourceSize.zw;
    blur_coords_down  = vTexCoord + vec2(0.0, texel.y);
    blur_coords_up    = vTexCoord + vec2(0.0, -texel.y);
    blur_coords_right = vTexCoord + vec2(texel.x,  0.0);
    blur_coords_left  = vTexCoord + vec2(-texel.x, 0.0);
    blur_coords_lower_bound = vec2(0.0);
    blur_coords_upper_bound = texel * (outsize.xy - vec2(2.0));
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
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 blur_coords_up;
COMPAT_VARYING vec2 blur_coords_down;
COMPAT_VARYING vec2 blur_coords_right;
COMPAT_VARYING vec2 blur_coords_left;
COMPAT_VARYING vec2 blur_coords_lower_bound;
COMPAT_VARYING vec2 blur_coords_upper_bound;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float blending_mode;
uniform COMPAT_PRECISION float adjacent_texel_alpha_blending;
#else
#define blending_mode 1.0
#define adjacent_texel_alpha_blending 0.1755
#endif

////////////////////////////////////////////////////////////////////////////////
// Fragment definitions                                                       //
////////////////////////////////////////////////////////////////////////////////

#define blending_modifier(color) clamp(float(color.a == 0.) + blending_mode, 0.0, 1.0)

void main()
{
    // A simple blur technique that softens harsh color transitions
    // Specialized to only blur alpha values and limited to only blurring texels
    // lying in the spaces between two or more texels

    // Sample the input textures
    vec4 out_color = COMPAT_TEXTURE(Source, vTexCoord).rgba;

    // Clamp the blur coords to the input texture size so it doesn't attempt to sample off the texture (it'll retrieve float4(0.0) and darken the edges otherwise)
    vec2 blur_coords_up_clamped    = clamp(blur_coords_up, blur_coords_lower_bound, blur_coords_upper_bound);
    vec2 blur_coords_down_clamped  = clamp(blur_coords_down, blur_coords_lower_bound, blur_coords_upper_bound);
    vec2 blur_coords_right_clamped = clamp(blur_coords_right, blur_coords_lower_bound, blur_coords_upper_bound);
    vec2 blur_coords_left_clamped  = clamp(blur_coords_left, blur_coords_lower_bound, blur_coords_upper_bound);

    //Sample adjacent texels based on the coordinates above
    vec4 adjacent_texel_1 = COMPAT_TEXTURE(Source, blur_coords_up_clamped).rgba;
    vec4 adjacent_texel_2 = COMPAT_TEXTURE(Source, blur_coords_down_clamped).rgba;
    vec4 adjacent_texel_3 = COMPAT_TEXTURE(Source, blur_coords_right_clamped).rgba;
    vec4 adjacent_texel_4 = COMPAT_TEXTURE(Source, blur_coords_left_clamped).rgba;

    // Sum the alpha differences between neighboring texels, apply modifiers, then subtract the result from the current fragment alpha value
    out_color.a -=  
    ( 
        (out_color.a - adjacent_texel_1.a) + 
        (out_color.a - adjacent_texel_2.a) + 
        (out_color.a - adjacent_texel_3.a) + 
        (out_color.a - adjacent_texel_4.a) 
    ) * adjacent_texel_alpha_blending * blending_modifier(out_color);

    FragColor = out_color;
} 
#endif
