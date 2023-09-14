#version 110
 
/*

DariusG presents

'crt-Cyclon' 

Why? Because it's speedy!

A super-fast shader based on the magnificent crt-Geom, optimized for full speed 
on a Xiaomi Note 3 Pro cellphone (around 170(?) gflops gpu or so)

This shader uses parts from:
crt-Geom (scanlines)
Quillez (main filter)
Grade (some primaries)
Dogway's inverse Gamma
Masks-slot-color handling, tricks etc are mine.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

*/


#pragma parameter SCANLINE "Scanline Weight" 0.25 0.15 0.6 0.05
#pragma parameter INTERLACE "Interlacing On/Off" 1.0 0.0 1.0 1.0
#pragma parameter bogus_msk " [ MASK SETTINGS ] " 0.0 0.0 0.0 0.0
#pragma parameter M_TYPE "Mask Type: -1:None, 0:CGWG, 1:RGB" 0.0 -1.0 1.0 1.0
#pragma parameter MSIZE "Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter SLOT "Slot Mask On/Off" 0.0 0.0 1.0 1.0
#pragma parameter SLOTW "Slot Mask Width" 2.0 2.0 3.0 1.0
#pragma parameter BGR "Subpixels BGR/RGB" 0.0 0.0 1.0 1.0
#pragma parameter Maskl "Mask Brightness Dark" 0.3 0.0 1.0 0.05
#pragma parameter Maskh "Mask Brightness Bright" 0.75 0.0 1.0 0.05
#pragma parameter bogus_con " [ CONVERGENCE SETTINGS ] " 0.0 0.0 0.0 0.0
#pragma parameter C_STR "Convergence Overall Strength" 0.0 0.0 1.0 0.05
#pragma parameter CONV_R "Convergence Red X-Axis" 0.0 -1.0 1.0 0.05
#pragma parameter CONV_G "Convergence Green Y-axis" 0.0 -1.0 1.0 0.05
#pragma parameter CONV_B "Convergence Blue X-Axis" 0.0 -1.0 1.0 0.05
#pragma parameter bogus_geom " [ GEOMETRY SETTINGS ] " 0.0 0.0 0.0 0.0
#pragma parameter WARPX "Curvature Horizontal" 0.032 0.00 0.25 0.01
#pragma parameter WARPY "Curvature Vertical" 0.042 0.00 0.25 0.01
#pragma parameter CORNER "Corner Round" 0.02 0.0 0.25 0.01
#pragma parameter B_SMOOTH "Border Smoothness" 300.0 100.0 1000.0 25.0
#pragma parameter PAL_NTSC "PAL-NTSC Aspect: Amiga,MD-SNES" 0.0 0.0 2.0 1.0
#pragma parameter bogus_col " [ COLOR SETTINGS ] " 0.0 0.0 0.0 0.0
#pragma parameter BR_DEP "Scan/Mask Brightness Dependence" 0.266 0.0 0.333 0.01
#pragma parameter c_space "Color Space: sRGB,PAL,NTSC-U,NTSC-J" 0.0 0.0 3.0 1.0
#pragma parameter EXT_GAMMA "External Gamma In (Glow etc)" 0.0 0.0 1.0 1.0
#pragma parameter SATURATION "Saturation" 1.0 0.0 2.0 0.01
#pragma parameter BRIGHTNESS "Brightness, Sega fix:1.06" 1.0 0.0 2.0 0.01
#pragma parameter BLACK  "Black Level" 0.0 -0.20 0.20 0.01 
#pragma parameter RG "Green <-to-> Red Hue" 0.0 -0.25 0.25 0.01
#pragma parameter RB "Blue <-to-> Red Hue"  0.0 -0.25 0.25 0.01
#pragma parameter GB "Blue <-to-> Green Hue" 0.0 -0.25 0.25 0.01
#pragma parameter POTATO "Potato Boost(Simple Gamma, adjust Mask)" 0.0 0.0 1.0 1.0

#define pi 3.1415926535897932384626433

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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float one;

#else
#define one 0.0      
   
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    scale = TextureSize.xy/InputSize.xy;
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
COMPAT_VARYING vec2 scale;


// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float M_TYPE;
uniform COMPAT_PRECISION float BGR;
uniform COMPAT_PRECISION float Maskl;
uniform COMPAT_PRECISION float Maskh;
uniform COMPAT_PRECISION float MSIZE;
uniform COMPAT_PRECISION float P_GLOW;
uniform COMPAT_PRECISION float C_STR;
uniform COMPAT_PRECISION float CONV_R;
uniform COMPAT_PRECISION float CONV_G;
uniform COMPAT_PRECISION float CONV_B;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float INTERLACE;
uniform COMPAT_PRECISION float WARPX;
uniform COMPAT_PRECISION float WARPY;
uniform COMPAT_PRECISION float SLOT;
uniform COMPAT_PRECISION float SLOTW;
uniform COMPAT_PRECISION float c_space;
uniform COMPAT_PRECISION float SATURATION;
uniform COMPAT_PRECISION float CORNER;
uniform COMPAT_PRECISION float B_SMOOTH;
uniform COMPAT_PRECISION float BRIGHTNESS;
uniform COMPAT_PRECISION float RG;
uniform COMPAT_PRECISION float RB;
uniform COMPAT_PRECISION float GB;
uniform COMPAT_PRECISION float BLACK; 
uniform COMPAT_PRECISION float BR_DEP; 
uniform COMPAT_PRECISION float POTATO; 
uniform COMPAT_PRECISION float EXT_GAMMA; 
uniform COMPAT_PRECISION float PAL_NTSC; 

#else
#define M_TYPE 0.0
#define BGR 0.0
#define MSIZE 1.0
#define Maskl 0.4     
#define Maskh 0.7     
#define P_GLOW 0.5     
#define BLUR 0.5     
#define C_STR 0.25     
#define CONV_R 0.0     
#define CONV_G 0.0     
#define CONV_B 0.0      
#define SCANLINE 0.3   
#define INTERLACE 1.0   
#define WARPX 0.032   
#define WARPY 0.042   
#define SLOT 0.0    
#define SLOTW 2.0    
#define c_space 0.0    
#define SATURATION 1.0    
#define CORNER 0.02   
#define B_SMOOTH 200.0   
#define BRIGHTNESS 1.0   
#define RG 0.0   
#define RB 0.0   
#define GB 0.0   
#define BLACK 0.0
#define BR_DEP 0.266   
#define POTATO 0.0   
#define EXT_GAMMA 0.0   
#define PAL_NTSC 0.0   
#endif

vec3 Mask(vec2 pos, float CGWG)
{
    vec3 mask = vec3(CGWG);
    
    
if (M_TYPE == 0.0){

    if (POTATO == 1.0)  return vec3( (1.0-CGWG)*sin(pos.x*pi)+CGWG) ;
    else{
    float m = fract(pos.x*0.5);

    if (m<0.5) mask.rb = vec2(1.0);
    else mask.g = 1.0;

    return mask;}
    }

if (M_TYPE == 1.0){

    if (POTATO == 1.0)  return vec3( (1.0-CGWG)*sin(pos.x*pi*0.6667)+CGWG) ;
    else{
    float m = fract(pos.x*0.3333);

    if (m<0.3333) BGR == 0.0 ? mask.b = 1.0 : mask.r = 1.0;
    else if (m<0.6666)         mask.g = 1.0;
    else          BGR == 0.0 ? mask.r = 1.0 : mask.b = 1.0;
    return mask;
    }
}

    else return vec3(1.0);

}



vec3 scanlineWeights(float distance, vec3 color)
    {
    // "wid" controls the width of the scanline beam, for each RGB
    // channel The "weights" lines basically specify the formula
    // that gives you the profile of the beam, i.e. the intensity as
    // a function of distance from the vertical center of the
    // scanline. In this case, it is gaussian if width=2, and
    // becomes nongaussian for larger widths. Ideally this should
    // be normalized so that the integral across the beam is
    // independent of its width. That is, for a narrower beam
    // "weights" should have a higher peak at the center of the
    // scanline than for a wider beam.
    vec3 wid = SCANLINE + 0.15 * pow(color, vec3(3.0));
    vec3 weights = vec3(distance / wid);
    return 0.4 * exp(-weights * weights ) / wid;

    }

#define pwr vec3(1.0/((-0.8*SCANLINE+1.0)*(-0.8*CGWG+1.0))-1.2)
// Returns gamma corrected output, compensated for scanline+mask embedded gamma
vec3 inv_gamma(vec3 col, vec3 power)
{
    vec3 cir  = col-1.0;
         cir *= cir;
         col  = mix(sqrt(col),sqrt(1.0-cir),power);
    return col;
}

// standard 6774k
mat3 PAL = mat3(
1.1515,  -0.1099, -0.0033,
0.0914,  0.9177,  -0.0043,
0.0039,  -0.0071, 1.0901
);

// standard 6774k
mat3 NTSC = mat3(
0.8870,  0.0451,  0.0566,
-0.0800, 1.0368,  0.0361,
0.0053,  -0.1196, 1.2320
);

// standard 9300k
mat3 NTSC_J = mat3(
0.8800,  0.0020,  0.1054,
-0.0071, 0.9351,  0.0658,
0.0198,  -0.0797, 1.3533
);


vec3 slot(vec2 pos)
{
    float h = fract(pos.x/SLOTW);
    float v = fract(pos.y);
    
    float odd;
    if (v<0.5) odd = 0.0; else odd = 1.0;

if (odd == 0.0)
    {if (h<0.5) return vec3(0.5); else return vec3(1.5);}

else if (odd == 1.0)
    {if (h<0.5) return vec3(1.5); else return vec3(0.5);}


}


vec2 Warp(vec2 pos)
{
    pos = pos*2.0-1.0;
    pos *= vec2(1.0+pos.y*pos.y*WARPX, 1.0+pos.x*pos.x*WARPY);
    pos = pos*0.5+0.5;

    return pos;
}

float corner(vec2 coord)
{
        coord = min(coord, vec2(1.0)-coord) * vec2(1.0, 0.75);
        vec2 cdist = vec2(CORNER);
             coord = cdist - min(coord,cdist);
        float dist = sqrt(dot(coord,coord));
        
        return clamp((cdist.x-dist)*B_SMOOTH,0.0, 1.0);
}  


void main()
{   

mat3 hue = mat3(
    1.0, -RG, -RB,
    RG, 1.0, -GB,
    RB, GB, 1.0
);

    vec2 pos = Warp(vTexCoord*scale); vec2 cpos=pos;
    pos /=scale; // blurry

if (PAL_NTSC != 0.0){
    if(PAL_NTSC == 1.0) pos.y /=1.2; // Amiga 256 to 200
    pos.y += 0.005; // re-center
    if(PAL_NTSC == 2.0) pos.y /=1.0714; // MD-SNES 240 to 224
    }
    vec2 bpos = pos;
    vec2 dx = vec2(SourceSize.z,0.0);
    vec2 dy = vec2(0.0,OutSize.w);

    vec2 ogl2 = pos*SourceSize.xy;
    vec2 i = floor(pos*SourceSize.xy) + 0.5;
    float f = ogl2.y - i.y;
    pos.y = (i.y + 4.0*f*f*f)*SourceSize.w; // smooth
    pos.x = mix(pos.x, i.x*SourceSize.z, 0.2);

    vec3 res0 = COMPAT_TEXTURE(Source,pos).rgb;
    vec3 resr = COMPAT_TEXTURE(Source,pos + dx*CONV_R).rgb;
    vec3 resb = COMPAT_TEXTURE(Source,pos + dx*CONV_B).rgb;
    vec3 resg = COMPAT_TEXTURE(Source,pos + dy*CONV_G).rgb;

    vec3 res = vec3(  res0.r*(1.0-C_STR) +  resr.r*C_STR,
                      res0.g*(1.0-C_STR) +  resg.g*C_STR,
                      res0.b*(1.0-C_STR) +  resb.b*C_STR 
                   );
    
    float l = dot(vec3(BR_DEP),res);
    
    if(EXT_GAMMA != 1.0) res *= res;
    if (c_space != 0.0) {
    if (c_space == 1.0) res *= PAL;
    if (c_space == 2.0) res *= NTSC;
    if (c_space == 3.0) res *= NTSC_J;
    res = clamp(res,0.0,1.0);
    }
    float s = fract(bpos.y*SourceSize.y-0.5);
// handle interlacing
    if (InputSize.y > 400.0) 
    {
        s = fract(bpos.y*SourceSize.y/2.0-0.5);
        if (INTERLACE == 1.0) s = mod(float(FrameCount),2.0) < 1.0 ? s: s+0.5;
    }

    vec3 weight  = scanlineWeights(s, res);
    vec3 weight2 = scanlineWeights(1.0-s, res);

    res *= weight + weight2;
    vec2 xy = vTexCoord*OutputSize.xy*scale/MSIZE;
    
    float CGWG = mix(Maskl, Maskh, l);
   
    res *= Mask(xy, CGWG);
    if (SLOT == 1.0) res *= mix(slot(xy/2.0),vec3(1.0),CGWG);
    if (POTATO == 0.0) res = inv_gamma(res,pwr);
    else res = sqrt(res);

    float lum = dot(vec3(0.29,0.60,0.11),res);
    res = mix(vec3(lum),res,SATURATION);
    res *= BRIGHTNESS;
    res *= hue;
    res -= vec3(BLACK);
    res *= vec3(1.0)/vec3(1.0-BLACK);
    if (CORNER !=0.0) res *= corner(cpos);
    FragColor = vec4(res,1.0);
}
#endif
