#version 110
 
/*
DariusG presents

'crt-Cyclon' @2023
This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

*/

#pragma parameter sharpx "Sharpness X" 2.0 1.0 5.0 0.1
#pragma parameter sharpy "Sharpness Y" 3.0 1.0 5.0 0.1

#pragma parameter bogus_geom " [ GEOMETRY SETTINGS ] " 0.0 0.0 0.0 0.0
#pragma parameter WarpX "Curvature Horiz." 0.03 0.0 0.25 0.01
#pragma parameter WarpY "Curvature Vert." 0.04 0.0 0.25 0.01
#pragma parameter corner "Corner Round" 0.02 0.0 0.25 0.01
#pragma parameter b_smooth "Border Smoothness" 300.0 100.0 1000.0 25.0

#pragma parameter bogus_sc " [ SCANLINES/MASK ] " 0.0 0.0 0.0 0.0
#pragma parameter interlace "Interlacing On/Off" 1.0 0.0 1.0 1.0
#pragma parameter scanl "Scanlines Low" 0.5 0.0 1.0 0.05
#pragma parameter scanh "Scanlines High" 0.25 0.0 1.0 0.05
#pragma parameter M_TYPE "Mask Type: -1:None, 0:CGWG, 1:RGB" 0.0 -1.0 1.0 1.0
#pragma parameter MSIZE "Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter BGR "Subpixels BGR/RGB" 0.0 0.0 1.0 1.0
#pragma parameter mask "Mask Brightness" 0.5 0.0 1.0 0.05
#pragma parameter SLOT "Slot Mask On/Off" 0.0 0.0 1.0 1.0
#pragma parameter SLOTW "Slot Mask Width" 2.0 2.0 3.0 1.0

#pragma parameter bogus_col " [ COLOR SETTINGS ] " 0.0 0.0 0.0 0.0

#pragma parameter CSPACEI "Color Space (In): RGB, NTSC, PAL, P22D93" 0.0 0.0 3.0 1.0
#pragma parameter CSPACEO "Color Space (Out): RGB, WideRGB" 0.0 0.0 1.0 1.0
#pragma parameter gammain "Gamma In" 2.4 1.0 4.0 0.05
#pragma parameter gammaout "Gamma Out" 2.25 1.0 4.0 0.05
#pragma parameter sat "Saturation" 1.0 0.0 2.0 0.01
#pragma parameter brightness "Brightness, Sega fix:1.06" 1.0 0.0 2.0 0.01
#pragma parameter black_lvl  "Black Level" 0.0 -0.20 0.20 0.01 
#pragma parameter boostl "Boost Dark Colors" 1.3 1.0 2.0 0.05
#pragma parameter boosth "Boost Bright Colors" 1.35 1.0 2.0 0.05
#pragma parameter RG "Green <-to-> Red Hue" 0.0 -0.25 0.25 0.01
#pragma parameter RB "Blue <-to-> Red Hue"  0.0 -0.25 0.25 0.01
#pragma parameter GB "Blue <-to-> Green Hue" 0.0 -0.25 0.25 0.01

#define pi 3.1415926535897932384626433
#define gamma_out 1.0/gammaout
#define blck 1.0/(1.0-black_lvl)

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
COMPAT_VARYING vec2 ps;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float maskpos;

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
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0      
   
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    ps = 1.0/TextureSize.xy;
    scale = TextureSize.xy/InputSize.xy;
    maskpos = TEX0.x*OutputSize.x*scale.x;
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
COMPAT_VARYING vec2 ps;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float maskpos;


// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float sharpx;
uniform COMPAT_PRECISION float sharpy;
uniform COMPAT_PRECISION float interlace;
uniform COMPAT_PRECISION float scanl;
uniform COMPAT_PRECISION float scanh;
uniform COMPAT_PRECISION float M_TYPE;
uniform COMPAT_PRECISION float MSIZE;
uniform COMPAT_PRECISION float BGR;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float SLOT;
uniform COMPAT_PRECISION float SLOTW;
uniform COMPAT_PRECISION float WarpX;
uniform COMPAT_PRECISION float WarpY;
uniform COMPAT_PRECISION float corner;
uniform COMPAT_PRECISION float b_smooth;
uniform COMPAT_PRECISION float CSPACEI;
uniform COMPAT_PRECISION float CSPACEO;
uniform COMPAT_PRECISION float gammain;
uniform COMPAT_PRECISION float gammaout;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float brightness;
uniform COMPAT_PRECISION float black_lvl; 
uniform COMPAT_PRECISION float RG;
uniform COMPAT_PRECISION float RB;
uniform COMPAT_PRECISION float GB;
uniform COMPAT_PRECISION float boostl;
uniform COMPAT_PRECISION float boosth;

#else
#define sharpx     2.0      
#define sharpy     3.0 
#define interlace 1.0     
#define scanl     0.4      
#define scanh     0.2  
#define M_TYPE 0.0
#define MSIZE 1.0
#define BGR 0.0    
#define mask     0.15
#define SLOT 0.0    
#define SLOTW 2.0       
#define WarpX     0.03     
#define WarpY     0.04 
#define corner 0.02   
#define b_smooth 200.0  
#define CSPACEI 0.0
#define CSPACEO 0.0    
#define gammain 2.5
#define gammaout 2.2
#define sat 1.0
#define brightness 1.0   
#define black_lvl 0.0
#define RG 0.0   
#define RB 0.0   
#define GB 0.0  
#define boostl 1.3
#define boosth 1.1
    
#endif


mat3 NTSC = mat3 (
 0.6068909,  0.1735011,  0.2003480,
 0.2989164,  0.5865990,  0.1144845,
 0.0000000,  0.0660957,  1.1162243);

mat3 PAL = mat3(
0.4306190,  0.3415419,  0.1783091,
 0.2220379,  0.7066384,  0.0713236,
 0.0201853, 0.1295504,  0.9390944
);

mat3 P22 = mat3(
0.3844,  0.3191,  0.2497,
0.2091,  0.6781,  0.1128,
0.0215,  0.1425,  1.2487
);

mat3 toRGB = mat3(
3.5053960, -1.7394894, -0.5439640,
-1.0690722,  1.9778245,  0.0351722,
 0.0563200, -0.1970226,  1.0502026
);

mat3 WideRGB = mat3(
1.4628067, -0.1840623, -0.2743606,
-0.5217933,  1.4472381,  0.0677227,
 0.0349342, -0.0968930,  1.2884099
);


vec3 Mask(vec2 pos, float CGWG)
{
    vec3 mask = vec3(CGWG);
    
    
if (M_TYPE == 0.0){

    float m = fract(pos.x*0.5);

    if (m<0.5) mask.rb = vec2(1.0);
    else mask.g = 1.0;

    return mask;
    }

if (M_TYPE == 1.0){

    float m = fract(pos.x*0.3333);

    if (m<0.3333) BGR == 0.0 ? mask.b = 1.0 : mask.r = 1.0;
    else if (m<0.6666)         mask.g = 1.0;
    else          BGR == 0.0 ? mask.r = 1.0 : mask.b = 1.0;
    return mask;
    
}

    else return vec3(1.0);

}

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
    pos *= vec2(1.0+pos.y*pos.y*WarpX, 1.0+pos.x*pos.x*WarpY);
    pos = pos*0.5+0.5;
    return pos;
}

float corners(vec2 coord)
{
        coord = min(coord, vec2(1.0)-coord) * vec2(1.0, 0.75);
        vec2 cdist = vec2(corner);
             coord = cdist - min(coord,cdist);
        float dist = sqrt(dot(coord,coord));
        
        return clamp((cdist.x-dist)*b_smooth,0.0, 1.0);
}  

void main()
{

mat3 hue = mat3(
    1.0, -RG, -RB,
    RG, 1.0, -GB,
    RB, GB, 1.0
);    
vec2 pos = Warp(vTexCoord*scale);
vec2 cpos=pos;
pos /= scale;
vec2 dx = vec2(ps.x,0.0);
vec2 dy = vec2(0.0,ps.y);

vec2 fp = fract(pos*SourceSize.xy);
fp.x = pow(fp.x,sharpx);
fp.y = pow(fp.y,sharpy);

vec3 c11 = COMPAT_TEXTURE(Source,pos).rgb;
vec3 c12 = COMPAT_TEXTURE(Source,pos+dx).rgb;

vec3 c21 = COMPAT_TEXTURE(Source,pos+dy).rgb;
vec3 c22 = COMPAT_TEXTURE(Source,pos+dx+dy).rgb;
    
vec3 up = mix(c11,c12,fp.x);    
vec3 dw = mix(c21,c22,fp.x);
vec3 final = mix(up,dw,fp.y); 

float l = max(max(final.r,final.g),final.b);
float gray = dot(vec3(0.3,0.6,0.1),final);
float scan = mix(scanl,scanh,l);
float s = (pos.y*SourceSize.y-(sharpy/24.0))*2.0;
if (InputSize.y>400.0) 
{
s = pos.y*SourceSize.y-(sharpy/24.0);
    if (interlace == 1.0)
    s = mod(float(FrameCount),2.0) < 1.0 ? s: s-1.0;
}

float scn = scan*sin((s)*pi)+1.0-scan;  

vec2 xy = vTexCoord*OutputSize.xy*scale/MSIZE;

final = pow(final,vec3(gammain));

if (CSPACEI == 1.0) final *= NTSC;
else if (CSPACEI == 2.0) final *= PAL;
else if (CSPACEI == 3.0) final *= P22;
if (CSPACEI != 0.0 && CSPACEO == 0.0) final *= toRGB;
else if (CSPACEI != 0.0 && CSPACEO == 1.0) final *= WideRGB;
final = clamp(final, 0.0, 1.0);


final *= scn*Mask(xy, mask);
if (SLOT == 1.0) final *= mix(slot(xy/2.0),vec3(1.0),mask);


final = pow(final, vec3(gamma_out));

final *= brightness;
final *= hue;

final -= vec3(black_lvl);
final *= vec3(blck);
final *= mix(boostl,boosth, gray);
final = mix(vec3(gray),final,sat);
if (corner !=0.0) final *= corners(cpos);

FragColor.rgb = final;
}
#endif
