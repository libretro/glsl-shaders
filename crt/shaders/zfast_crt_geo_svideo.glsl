#version 110

/*
    zfast_crt_geo_svideo - A simple, fast CRT shader.

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

Dogway: I modified zfast_crt.glsl shader to include screen curvature,
        vignetting, round corners, S-Video like blur, phosphor*temperature and some desaturation.
        The scanlines and mask are also now performed in the recommended linear light.
        For this to run smoothly on GPU deprived platforms like the Chromecast and
        older consoles, I had to remove several parameters and hardcode them into the shader.
        Another POV is to run the shader on handhelds like the Switch or SteamDeck so they consume less battery.

*/

//For testing compilation
//#define FRAGMENT
//#define VERTEX

// Parameter lines go here:
#pragma parameter SCANLINE_WEIGHT "Scanline Amount"     7.0 0.0 15.0 0.5
#pragma parameter MASK_DARK       "Mask Effect Amount"  0.5 0.0 1.0 0.05
#pragma parameter g_vstr          "Vignette Strength"   20.0 0.0 50.0 1.0
#pragma parameter g_vpower        "Vignette Power"      0.40 0.0 0.5 0.01
#pragma parameter blurx           "Convergence X-Axis"  0.50 -2.0 2.0 0.05
#pragma parameter blury           "Convergence Y-Axis" -0.20 -2.0 2.0 0.05

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
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
#else
#define SCANLINE_WEIGHT 7.0
#define MASK_DARK 0.5
#define g_vstr 20.0
#define g_vpower 0.40
#define blurx 0.50
#define blury -0.20
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy     = TexCoord.xy*1.00001;
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define scale vec2(TextureSize.xy/InputSize.xy)
#define blur_y blury/(TextureSize.y*2.0)
#define blur_x blurx/(TextureSize.x*2.0)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SCANLINE_WEIGHT;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float g_vstr;
uniform COMPAT_PRECISION float g_vpower;
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
#else
#define SCANLINE_WEIGHT 7.0
#define MASK_DARK 0.5
#define g_vstr 20.0
#define g_vpower 0.40
#define blurx 0.50
#define blury -0.20
#endif


/*
// NTSC-J (D93) -> Rec709 D65 Joint Matrix (with D93 simulation)
// This is compensated for a linearization hack (RGB*RGB and then sqrt())
const mat3 P22D93 = mat3(
     1.00000, 0.00000, -0.06173,
     0.07111, 0.96887, -0.01136,
     0.00000, 0.08197,  1.07280);

// SAT 0.95;0.9
const mat3 SAT95 = mat3(
     0.921259999275207500, 0.07151728868484497, 0.007221288979053497,
     0.022333506494760513, 0.97512906789779660, 0.002537854015827179,
     0.010629460215568542, 0.03575950860977173, 0.953611016273498500);
*/


// P22D93 * SAT95
const mat3 P22D93SAT95 = mat3(
     0.920603871345520000, 0.06930985301733017, -0.051645118743181230,
     0.087028317153453830, 0.94945263862609860, -0.007860664278268814,
     0.013233962468802929, 0.11829412728548050,  1.023241996765136700);



vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;
    pos *= vec2(1.0 + (pos.y*pos.y)*0.0276, 1.0 + (pos.x*pos.x)*0.0414);
    return pos*0.5 + 0.5;
}


void main()
{
    vec2 vpos   = vTexCoord*scale;
    vec2 xy     = Warp(vpos);

    vec2 corn   = min(xy,vec2(1.0)-xy); // This is used to mask the rounded
         corn.x = 0.0001/corn.x;        // corners later on

         xy    /= scale;

    COMPAT_PRECISION vec2 sample1 =       COMPAT_TEXTURE(Source,vec2(xy.x + blur_x, xy.y - blur_y)).rg;
    COMPAT_PRECISION vec3 sample2 = 0.5 * COMPAT_TEXTURE(Source,     xy).rgb;
    COMPAT_PRECISION vec2 sample3 =       COMPAT_TEXTURE(Source,vec2(xy.x - blur_x, xy.y + blur_y)).gb;

    vec3 colour =    vec3(sample1.r*0.50 + sample2.r,
                          sample1.g*0.25 + sample2.g + sample3.r*0.25,
                                           sample2.b + sample3.g*0.50);

    vpos  *= (1.0 - vpos.xy);
    float vig = vpos.x * vpos.y * max(10.0,-1.8*g_vstr+100.0);
    vig = min(pow(vig, g_vpower), 1.0);
    vig = vig >= 0.5 ? smoothstep(0.0,1.0,vig) : vig;


    // Of all the pixels that are mapped onto the texel we are
    // currently rendering, which pixel are we currently rendering?
    float ratio_scale = xy.y * TextureSize.y - 0.5;
    // Snap to the center of the underlying texel.
    float i = floor(ratio_scale) + 0.5;

    // This is just like "Quilez Scaling" but sharper
    float f = ratio_scale - i;
    COMPAT_PRECISION float Y = f*f;

    vec2 MSCL = OutputSize.y > 1499.0 ? vec2(0.30) : vec2(0.5);

    COMPAT_PRECISION float whichmask = floor(vTexCoord.x*4.0*OutputSize.x)*-MSCL.x;
    COMPAT_PRECISION float mask = 1.0 + float(fract(whichmask) < MSCL.y) * -MASK_DARK;

    vec3 P22 = ((colour*colour) * P22D93SAT95) * vig;
    colour = max(vec3(0.0),P22);

    COMPAT_PRECISION float scanLineWeight = (1.5 - SCANLINE_WEIGHT*(Y - Y*Y));

    if (corn.y <= corn.x || corn.x < 0.0001)
    colour = vec3(0.0);

    FragColor.rgba = vec4(sqrt(colour.rgb*(mix(scanLineWeight*mask, 1.0, dot(colour.rgb,vec3(0.26667))))),1.0);

}
#endif
