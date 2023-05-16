/* 
 * gizmo98 bayer 4x4 dithering shader
 * Copyright (C) 2023 gizmo98
 *
 *   This program is free software; you can redistribute it and/or modify it
 *   under the terms of the GNU General Public License as published by the Free
 *   Software Foundation; either version 2 of the License, or (at your option)
 *   any later version.
 *
 * version 0.1, 16.05.2023
 * ---------------------------------------------------------------------------------------
 * - initial commit
 * 
 * https://github.com/gizmo98/gizmo-crt-shader
 *
 * uses parts of texture anti-aliasing shader from Ikaros https://www.shadertoy.com/view/ldsSRX
 */

#pragma parameter COLOR_DEPTH "Color depth in Bits"            2.0 1.0 8.0 1.0
#pragma parameter DITHER_TUNE "Tune dithering"                 0.0 -64.0 64.0 1.0
#pragma parameter EGA_PALETTE "EGA palette"                    0.0 0.0 1.0 1.0

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float COLOR_DEPTH;
uniform COMPAT_PRECISION float DITHER_TUNE;
uniform COMPAT_PRECISION float EGA_PALETTE;
#else
#define COLOR_DEPTH 7.0
#define DITHER_TUNE 0.0
#define EGA_PALETTE 0.0
#endif

void main()
{
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float COLOR_DEPTH;
uniform COMPAT_PRECISION float DITHER_TUNE;
uniform COMPAT_PRECISION float EGA_PALETTE;
#endif

vec4 DitherPattern(vec4 col, vec2 coord)
{
    mat4 bayerMatrix; 
    bayerMatrix[0] = vec4(0.0, 8.0, 2.0, 10.0);
    bayerMatrix[1] = vec4(12.0, 4.0, 14.0, 6.0);
    bayerMatrix[2] = vec4(3.0, 11.0, 1.0, 9.0);
    bayerMatrix[3] = vec4(15.0, 7.0, 13.0, 5.0);
    
    ivec2 st = ivec2(fract(coord.xy / 4.0) * 4.0);
    float threshold = bayerMatrix[st.x][st.y];
    float multiplier = pow(2.0,8.0 - COLOR_DEPTH) - 1.0;
    
    threshold = (threshold / 15.0) - 0.5;
    threshold *= ((multiplier + DITHER_TUNE) / 255.0);
        
    col.rgb += threshold; 				           
    return col;
}

vec2 saturateA(in vec2 x)
{
    return clamp(x, 0.0, 1.0);
}

vec2 magnify(in vec2 uv, in vec2 res)
{
    uv *= res; 
    return (saturateA(fract(uv) / saturateA(fwidth(uv))) + floor(uv) - 0.5) / res.xy;
}
vec4 textureAA(in vec2 uv){
    uv = magnify(uv,TextureSize.xy);
    vec2 uv1 = uv*TextureSize.xy;

    COMPAT_PRECISION vec2 iuv = floor(uv1);
    //COMPAT_PRECISION vec2 fuv = uv - iuv;  
      
    //uv = (uv - 0.5) / TextureSize.xy;
    vec4 col = COMPAT_TEXTURE( Texture, uv );
    
    col = DitherPattern( col , iuv - 0.5);
    return col;
}

vec4 ColorDepthReduction(vec4 col)
{
    float divider = pow(2.0,COLOR_DEPTH) - 1.0; 
    col.rgb *= divider;
    col.rgb = floor(col.rgb) + step(0.5, fract(col.rgb));
    col.rgb /= divider;
    return col;
}

vec4 EGAPalette(vec4 col)
{    
    float divider = 3.0;
    vec3 c = floor(col.rgb * divider) + step(0.5, fract(col.rgb * divider));
    if (c.rgb == vec3(0.0,0.0,0.0) ||
        c.rgb == vec3(1.0,1.0,1.0) || 
        c.rgb == vec3(2.0,2.0,2.0) ||
        c.rgb == vec3(3.0,3.0,3.0) ||
        c.rgb == vec3(2.0,1.0,0.0))
        col.rgb = col.rgb;
    // bright green
    else if (c.rgb == vec3(0.0,3.0,0.0)||
             c.rgb == vec3(0.0,3.0,2.0)||
             c.rgb == vec3(2.0,3.0,0.0)||
             c.rgb == vec3(0.0,3.0,1.0)||
             c.rgb == vec3(1.0,3.0,1.0)||
             c.rgb == vec3(1.0,3.0,0.0)||
             c.rgb == vec3(2.0,3.0,1.0)||
             c.rgb == vec3(2.0,3.0,2.0))
        col.rgb = vec3(1.0,3.0,1.0) / divider;
    // green  
    else if (c.rgb == vec3(0.0,2.0,0.0)||
             c.rgb == vec3(0.0,2.0,1.0)||
             c.rgb == vec3(0.0,1.0,0.0)||
             c.rgb == vec3(0.0,1.0,1.0)||
             c.rgb == vec3(1.0,2.0,1.0)||
             c.rgb == vec3(1.0,2.0,0.0)||
             c.rgb == vec3(0.0,1.0,1.0))
        col.rgb = vec3(0.0,2.0,0.0) / divider; 
    // bright red
    else if (c.rgb == vec3(3.0,0.0,0.0)||
             c.rgb == vec3(3.0,0.0,1.0)||
             c.rgb == vec3(3.0,1.0,0.0)||
             c.rgb == vec3(3.0,1.0,1.0))
        col.rgb = vec3(3.0,1.0,1.0) / divider;
    // red  
    else if (c.rgb == vec3(2.0,0.0,0.0)||
             c.rgb == vec3(2.0,0.0,1.0)||
             c.rgb == vec3(1.0,0.0,0.0))
        col.rgb = vec3(2.0,0.0,0.0) / divider; 
    // bright cyan
    else if (c.rgb == vec3(0.0,3.0,3.0)||
             c.rgb == vec3(1.0,3.0,3.0)||
             c.rgb == vec3(2.0,3.0,3.0))
        col.rgb = vec3(1.0,3.0,3.0) / divider;
    // cyan
    else if (c.rgb == vec3(0.0,2.0,2.0)||
             c.rgb == vec3(1.0,2.0,2.0))
        col.rgb = vec3(0.0,2.0,2.0) / divider;
    // bright blue
    else if (c.rgb == vec3(0.0,2.0,3.0)||
             c.rgb == vec3(1.0,2.0,3.0)||
             c.rgb == vec3(0.0,0.0,3.0))
        col.rgb = vec3(1.0,1.0,3.0) / divider;
    // blue  
    else if (c.rgb == vec3(0.0,0.0,2.0)||
             c.rgb == vec3(0.0,0.0,1.0)||
             c.rgb == vec3(0.0,1.0,2.0)||
             c.rgb == vec3(1.0,1.0,3.0)||
             c.rgb == vec3(0.0,1.0,3.0))
        col.rgb = vec3(0.0,0.0,2.0) / divider; 
    // brown  
    else if (c.rgb == vec3(2.0,1.0,0.0)||
             c.rgb == vec3(2.0,1.0,1.0)||
             c.rgb == vec3(1.0,1.0,0.0))
        col.rgb = vec3(2.0,1.0,0.0) / divider; 
    // bright yellow  
    else if (c.rgb == vec3(3.0,3.0,0.0)||
             c.rgb == vec3(3.0,3.0,1.0)||
             c.rgb == vec3(3.0,3.0,2.0)||
             c.rgb == vec3(2.0,2.0,0.0)||
             c.rgb == vec3(2.0,2.0,1.0))
        col.rgb = vec3(3.0,3.0,1.0) / divider; 
    // magenta  
    else if (c.rgb == vec3(2.0,0.0,2.0)||
             c.rgb == vec3(2.0,0.0,3.0)||
             c.rgb == vec3(2.0,1.0,2.0)||
             c.rgb == vec3(2.0,1.0,3.0))
        col.rgb = vec3(2.0,0.0,2.0) / divider;     
    // bright magenta  
    else if (c.rgb == vec3(3.0,0.0,2.0)||
             c.rgb == vec3(3.0,0.0,3.0)||
             c.rgb == vec3(3.0,2.0,3.0)||
             c.rgb == vec3(3.0,1.0,3.0)||
             c.rgb == vec3(3.0,1.0,2.0))
        col.rgb = vec3(3.0,1.0,3.0) / divider; 
    else if (c.r == 0.0)
        col.gb = step(2.0,c.gb) * 2.0 / divider;
    else if (c.g == 0.0)
        col.rb = step(2.0,c.rb) * 2.0 / divider;
    else if (c.b == 0.0)
        col.rg = step(2.0,c.rg) * 2.0 / divider;
    else if (c.r == 3.0)
        col.gb = step(1.0,c.gb) / divider;
    else if (c.g == 3.0)
        col.rb = step(1.0,c.rb) / divider;
    else if (c.b == 3.0)
        col.rg = step(1.0,c.rg) / divider;
    return col;
}

void main()
{
    vec2 texcoord = TEX0.xy;
    FragColor = textureAA(texcoord);
    FragColor = ColorDepthReduction(FragColor);
    if (EGA_PALETTE == 1.0)
        FragColor = EGAPalette(FragColor);
}
#endif
