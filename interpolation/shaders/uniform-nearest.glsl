/* 
 * gizmo98 uniform-nearest shader
 * Copyright (C) 2023 gizmo98
 *
 *   This program is free software; you can redistribute it and/or modify it
 *   under the terms of the GNU General Public License as published by the Free
 *   Software Foundation; either version 2 of the License, or (at your option)
 *   any later version.
 *
 * version 0.1, 28.04.2023
 * ---------------------------------------------------------------------------------------
 * - initial commit
 * 
 * https://github.com/gizmo98/gizmo-crt-shader
 *
 * This shader texture AA shader code and subpixel scaling to produce a nearest neighbor
 * look with even placed pixels. If nearest neighbor is applied to fractional scaled output 
 * pixels look uneven and moving sprites change dimension which looks ugly.
 *
 * BGR_LCD_PATTERN most LCDs have a RGB pixel pattern. Enable BGR pattern with this switch
 *
 * uses parts of texture anti-aliasing shader from Ikaros https://www.shadertoy.com/view/ldsSRX
 */

#pragma parameter BGR_LCD_PATTERN "BGR output pattern"         0.0 0.0 1.0 1.0

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
uniform COMPAT_PRECISION float BGR_LCD_PATTERN;
#else
#define BGR_LCD_PATTERN 0.0
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
uniform COMPAT_PRECISION float BGR_LCD_PATTERN;
#endif

float Y(in float X)
{
    return 4.0 * (-X * X + X);
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
    uv = uv*TextureSize.xy + 0.5;

    COMPAT_PRECISION vec2 iuv = floor(uv);
    COMPAT_PRECISION vec2 fuv = uv - iuv;  
      
    uv = vec2(uv + vec2(-0.5,-0.5)) / TextureSize.xy;
    return COMPAT_TEXTURE( Texture, uv );
}

vec4 textureSubSample(in vec2 uvr, in vec2 uvg, in vec2 uvb ){
    return vec4(textureAA(uvr).r,textureAA(uvg).g, textureAA(uvb).b, 255);
}

vec3 XCoords(in float coord, in float factor){
    COMPAT_PRECISION float iGlobalTime = float(FrameCount)*0.025;
    COMPAT_PRECISION float spread = 0.333;
    COMPAT_PRECISION vec3 coords = vec3(coord);
    if(BGR_LCD_PATTERN == 1.0)
        coords.r += spread * 2.0;
    else
        coords.b += spread * 2.0;
    coords.g += spread;
    coords *= factor;
    return coords;
}

float YCoord(in float coord, in float factor){
    return coord * factor;
}

void main()
{
    vec2 texcoord = TEX0.xy;
    
    COMPAT_PRECISION vec2 fragCoord = texcoord.xy * OutputSize.xy;
    COMPAT_PRECISION vec2 factor = TextureSize.xy / OutputSize.xy ;
    COMPAT_PRECISION float yCoord = YCoord(fragCoord.y, factor.y) ;
    COMPAT_PRECISION vec3  xCoords = XCoords(fragCoord.x, factor.x);

    COMPAT_PRECISION vec2 coord_r = vec2(xCoords.r, yCoord) / TextureSize.xy;
    COMPAT_PRECISION vec2 coord_g = vec2(xCoords.g, yCoord) / TextureSize.xy;
    COMPAT_PRECISION vec2 coord_b = vec2(xCoords.b, yCoord) / TextureSize.xy;

    FragColor = textureSubSample(coord_r,coord_g,coord_b);
}
#endif
