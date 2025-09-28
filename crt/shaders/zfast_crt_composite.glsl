#version 110

/*
    zfast_crt_composite, A simple CRT shader by metallic 77.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
    
*/

#pragma parameter WARP "Curvature" 0.08 0.0 0.3 0.01
#pragma parameter BORDER "Border Smooth" 0.02 0.0 0.1 0.005
#pragma parameter U_CONVERG "Convergence" 0.8 0.0 3.0 0.05
#pragma parameter SCANLINE "Scanline Brightness" 0.25 0.0 0.5 0.05
#pragma parameter MASK "Mask Brightness" 0.35 0.0 0.5 0.05
#pragma parameter MASK_WID "Mask: CGWG, Slot2, Slot3" 1.0 1.0 3.0 1.0
#pragma parameter U_NOISE "Glass Dust/Noise" 0.15 0.0 1.0 0.05
#pragma parameter U_SAT "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter NTSC_J "NTSC-J colors" 1.0 0.0 1.0 1.0

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
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;


void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    ogl2pos = TEX0.xy*TextureSize;
    invdims = 1.0/TextureSize*1.0001;
    scale = TextureSize/InputSize;
    maskpos = TEX0.xy*scale*OutputSize.xy;
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


uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;

#define Source Texture
#define vTexCoord TEX0.xy

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WARP;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float MASK;
uniform COMPAT_PRECISION float MASK_WID;
uniform COMPAT_PRECISION float BORDER;
uniform COMPAT_PRECISION float U_NOISE;
uniform COMPAT_PRECISION float U_CONVERG;
uniform COMPAT_PRECISION float NTSC_J;
uniform COMPAT_PRECISION float U_SAT;
#else
#define WARP 0.12
#define SCANLINE  0.25
#define MASK  0.15
#define MASK_WID  2.0
#define BORDER  0.02
#define U_NOISE  0.3
#define U_CONVERG  0.3
#define NTSC_J  1.0
#define U_SAT  1.0
#endif

#define GAMMAIN(color) color*color 
#define PI 3.14159265358979323846 
#define TAU 6.2831852
#define u_time float(FrameCount)/60.0
#define pix 1.0/OutputSize.xy

#if defined GL_ES

mat3 hue = mat3(                
0.60722     ,0.25198 ,   0.27164,
-0.10833    ,0.98873 ,   0.19229,
-0.02558    ,0.12980 ,   1.10027);

#else
mat3 hue = mat3(                    
0.9501  ,   -0.0431 ,   0.0857  ,
0.0265  ,   0.9278  ,   0.0432  ,
0.0011  ,   -0.0206 ,   1.3153  );

#endif

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
// 0.0 to 1.0 range
vec2 pos = vTexCoord*scale*(1.0-WARP*0.12) + WARP*vec2(0.06,0.); 

// curve horizontally & vertically
float cx = pos.x - 0.5; // -0.5 to 0.5
float cy = pos.y - 0.5; // -0.5 to 0.5
    pos.x = pos.x + (cy * cy * WARP * cx);
    pos.y = pos.y + (cx * cx * WARP*2.0 * cy);
vec2 cpos = pos;

    pos /= scale; 
float spos = pos.y*TextureSize.y;    

    pos = pos*TextureSize + 0.5;
vec2 i = floor(pos);
vec2 f = pos - i;        // -0.5 to 0.5
float s1 = f.y;
float s2 = 1.0-f.y;
    f = f*f*(3.0-2.0*f);
    f.y *= f.y*f.y*f.y;
    pos = (i + f - 0.5)*invdims;

vec3 rgb = COMPAT_TEXTURE(Source,pos).rgb;

// shift red and blue sideways (simulate chroma smear)
float shift = U_CONVERG * 1.5; // adjustable bleed amount in pixels
// optional blur on chroma to get softer smear
if (U_CONVERG > 0.01) {
    vec3 r_blur = COMPAT_TEXTURE(Source, pos + vec2(pix.x * shift * 0.5, 0.0)).rgb;
    vec3 g_blur = COMPAT_TEXTURE(Source, pos - vec2(pix.x * shift * 0.5, 0.0)).rgb;
    vec3 b_blur = COMPAT_TEXTURE(Source, pos + vec2(pix.x * shift * 0.5, 0.0)).rgb;
        rgb.r = mix(rgb.r, r_blur.r, 0.5 * U_CONVERG);
        rgb.g = mix(rgb.g, g_blur.g, 0.5 * U_CONVERG);
        rgb.b = mix(rgb.b, b_blur.b, 0.5 * U_CONVERG);
    }

 // Subtle noise/dust
if (U_NOISE > 0.001) {
    float nval = rand(vec2(0.0, pos.y * TextureSize.y + u_time));
    float dust = smoothstep(0.9 - U_NOISE * 0.2, 1.0, nval) * 0.08 * U_NOISE;
        rgb += dust;
    } 

if (NTSC_J == 1.0) {rgb *= hue;}
// calc scanlines
vec3 lumS = SCANLINE*rgb;
vec3 scan = 0.5-lumS;
    rgb *= scan*sin((spos+0.5)*TAU)+0.5+lumS;

// calc mask
vec3 lumM = MASK*rgb;
vec3 mask = 0.5-lumM;
float slot = MASK_WID > 1.0? floor(maskpos.y): 0.0;
float mpos = mod(floor(maskpos.x/MASK_WID) + slot ,2.0) ;
    rgb *= mix(vec3(1.0),0.5+lumM,mpos);


float l = dot(vec3(0.3,0.6,0.1),rgb);
rgb = mix(vec3(l),rgb, U_SAT);
 
// fade screen edges (linear falloff)
float fade_x = smoothstep(0.0, BORDER, cpos.x) *
               smoothstep(0.0, BORDER, 1.0 - cpos.x);
float fade_y = smoothstep(0.0, BORDER*1.5, cpos.y) *
               smoothstep(0.0, BORDER*1.5, 1.0 - cpos.y);
// combine fades
float fade = fade_x * fade_y; 

    FragColor.rgb = sqrt(rgb)*fade;
}
#endif
