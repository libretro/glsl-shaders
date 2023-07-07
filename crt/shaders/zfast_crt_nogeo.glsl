#version 110

/*
    zfast_crt_nogeo - A simple, fast CRT shader.

    Copyright (C) 2017 Greg Hogan (SoltanGris42)
    Copyright (C) 2023 Jose Linares (Dogway)

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.


Notes:  This shader does scaling with a weighted linear filter
        based on the algorithm by Iñigo Quilez here:
        https://iquilezles.org/articles/texture/
        but modified to be somewhat sharper. Then a scanline effect that varies
        based on pixel brightness is applied along with a monochrome aperture mask.
        This shader runs at ~60fps on the Chromecast HD (10GFlops) on a 1080p display.
        (https://forums.libretro.com/t/android-googletv-compatible-shaders-nitpicky)

Dogway: This is the same as zfast_crt_geo but without the screen curvature for extra
        performance, specially for (320x240) "widescreen" games like Sega Genesis, NeoGeo, etc.

*/

//For testing compilation
//#define FRAGMENT
//#define VERTEX

// Parameter lines go here:
#pragma parameter SCANLINE_WEIGHT "Scanline Amount"     9.0 0.0 15.0 0.5
#pragma parameter MASK_DARK       "Mask Effect Amount"  0.1 0.0 1.0 0.05
#pragma parameter g_vstr          "Vignette Strength"   50.0 0.0 50.0 1.0
#pragma parameter g_vpower        "Vignette Power"      0.30 0.0 0.5 0.01

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
COMPAT_VARYING vec2 invDims;
COMPAT_VARYING vec2 scale;

vec4 _oPosition1;
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SCANLINE_WEIGHT;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float g_vstr;
uniform COMPAT_PRECISION float g_vpower;
#else
#define SCANLINE_WEIGHT 7.0
#define MASK_DARK 0.5
#define g_vstr 50.0
#define g_vpower 0.40
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;

    TEX0.xy = TexCoord.xy*1.00001;
    invDims = 1.0/TextureSize.xy;
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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 invDims;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define scale vec2(TextureSize.xy/InputSize.xy)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SCANLINE_WEIGHT;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float g_vstr;
uniform COMPAT_PRECISION float g_vpower;
#else
#define SCANLINE_WEIGHT 7.0
#define MASK_DARK 0.5
#define g_vstr 50.0
#define g_vpower 0.40
#endif


// NTSC-J (D93) -> Rec709 D65 Joint Matrix (with D93 simulation)
// This is compensated for a linearization hack (RGB*RGB and then sqrt())
const mat3 P22D93 = mat3(
     1.00000, 0.00000, -0.06173,
     0.07111, 0.96887, -0.01136,
     0.00000, 0.08197,  1.07280);


void main()
{
    vec2 vpos = vTexCoord*scale;

    vec2 corn = min(vpos,vec2(1.0)-vpos); // This is used to mask the rounded
    corn.x = 0.0001/corn.x;               // corners later on

    vpos *= (1.0 - vpos.xy);
    float vig = vpos.x * vpos.y * g_vstr;
    vig = min(pow(vig, g_vpower), 1.0);
    vig = vig >= 0.5 ? smoothstep(0.0,1.0,vig) : vig;

    // This is just like "Quilez Scaling" but sharper
    COMPAT_PRECISION float p = vTexCoord.y * TextureSize.y;
    // Snap to the center of the underlying texel.
    COMPAT_PRECISION float i = floor(p) + 0.5;
    COMPAT_PRECISION float f = p - i;
    COMPAT_PRECISION float Y = f*f;
    p = (i + 4.0*Y*f)*invDims.y;

    vec2 MSCL = OutputSize.y > 1499.0 ? vec2(0.30) : vec2(0.499999, 0.5);

    COMPAT_PRECISION float whichmask = floor(vTexCoord.x*4.0*OutputSize.x)*-MSCL.x;
    COMPAT_PRECISION float mask = 1.0 + float(fract(whichmask) < MSCL.y) * -MASK_DARK;
    COMPAT_PRECISION vec3 colour = COMPAT_TEXTURE(Source, vec2(vTexCoord.x,p)).rgb;

    vec3 P22 = ((colour*colour) * P22D93) * vig;
    colour = max(vec3(0.0),P22);

    COMPAT_PRECISION float scanLineWeight = (1.5 - SCANLINE_WEIGHT*(Y - Y*Y));

    if (corn.y <= corn.x)
    colour = vec3(0.0);

    FragColor.rgba = vec4(sqrt(colour.rgb*(mix(scanLineWeight*mask, 1.0, dot(colour.rgb,vec3(0.26667))))),1.0);

}
#endif
