/*
   Color Mangler
   Author: hunterk
   License: Public domain
*/

#pragma parameter gamma_boost_r "Gamma Mod Red Channel" 0.0 -5.0 5.0 0.1
#pragma parameter gamma_boost_g "Gamma Mod Green Channel" 0.0 -5.0 5.0 0.1
#pragma parameter gamma_boost_b "Gamma Mod Blue Channel" 0.0 -5.0 5.0 0.1
#pragma parameter sat "Saturation" 1.0 0.0 3.0 0.01
#pragma parameter lum "Luminance" 1.0 0.0 5.0 0.01
#pragma parameter cntrst "Contrast" 1.0 0.0 2.0 0.01
#pragma parameter r "Red" 1.0 0.0 2.0 0.01
#pragma parameter g "Green" 1.0 0.0 2.0 0.01
#pragma parameter b "Blue" 1.0 0.0 2.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter blr "Black-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter blg "Black-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter blb "Black-Blue Tint" 0.0 0.0 1.0 0.005

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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
   gl_Position = MVPMatrix * VertexCoord;
   TEX0.xy = TexCoord.xy;
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

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float gamma_boost_r, gamma_boost_g, gamma_boost_b, sat, lum, cntrst, blr, blg, blb, r, g, b, rg, rb, gr, gb, br, bg;
#else
#define gamma_boost_r 0.0
#define gamma_boost_g 0.0
#define gamma_boost_b 0.0
#define sat 1.0
#define lum 1.0
#define cntrst 1.0
#define blr 0.0
#define blg 0.0
#define blb 0.0
#define r 1.0
#define g 1.0
#define b 1.0
#define rg 0.0
#define rb 0.0
#define gr 0.0
#define gb 0.0
#define br 0.0
#define bg 0.0
#endif

void main()
{
   vec4 screen = pow(COMPAT_TEXTURE(Source, vTexCoord), vec4(2.2)).rgba;
   vec4 avglum = vec4(0.5);
   screen = mix(screen, avglum, (1.0 - cntrst));

                   //  r    g    b  alpha ; alpha does nothing for our purposes
   mat4 color = mat4(  r,  rg,  rb, 0.0,  //red tint
                      gr,   g,  gb, 0.0,  //green tint
                      br,  bg,   b, 0.0,  //blue tint
                     blr, blg, blb, 0.0); //black tint

   mat4 adjust = mat4((1.0 - sat) * 0.2126 + sat, (1.0 - sat) * 0.2126, (1.0 - sat) * 0.2126, 1.0,
                      (1.0 - sat) * 0.7152, (1.0 - sat) * 0.7152 + sat, (1.0 - sat) * 0.7152, 1.0,
                      (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722 + sat, 1.0,
                      0.0, 0.0, 0.0, 1.0);
   color *= adjust;
   screen = clamp(screen * lum, 0.0, 1.0);
   screen = color * screen;
	vec3 out_gamma = vec3(1.) / (vec3(2.2) - vec3(gamma_boost_r, gamma_boost_g, gamma_boost_b));
	FragColor = pow(screen, vec4(out_gamma, 1.0));
}
#endif
