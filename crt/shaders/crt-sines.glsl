#version 110

/* 
  work by DariusG 2023, some ideas borrowed from Dogway's zfast_crt_geo
*/

#pragma parameter curv "Curvature"  1.0 0.0 1.0 1.0
#pragma parameter blur "Interpolation: 0.0 nearest,0.25 bilinear" 0.15 0.05 0.25 0.01
#pragma parameter slotx "  Slot Size x" 3.0 2.0 3.0 1.0
#pragma parameter width "  Mask Width 3.0/2.0 " 0.67 0.67 1.0 0.333
#pragma parameter mask "  Mask Strength" 0.4 0.0 1.0 0.05
#pragma parameter ssize "Scanline Size" 1.0 1.0 2.0 1.0
#pragma parameter scan "Scanline Strength" 0.4 0.0 1.0 0.05
#pragma parameter thresh "Effect Threshold on brights" 0.2 0.0 0.33 0.01
#pragma parameter colors "  Colors: 0.0 RGB, 1.0 P22D93, 2.0:NTSC" 0.0 0.0 2.0 1.0
#pragma parameter sat "  Saturation" 1.0 0.0 2.0 0.01
#pragma parameter wp "  White Point" 0.0 -0.2 0.2 0.01
#pragma parameter potato "Potato Boost" 0.0 0.0 1.0 1.0

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
COMPAT_VARYING vec2 scaleS;
COMPAT_VARYING vec2 scaleO;
COMPAT_VARYING vec2 warpos;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    scaleS = TextureSize.xy/InputSize.xy;
    scaleO = OutputSize.xy/InputSize.xy;
    warpos = TEX0.xy*scaleS;
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
COMPAT_VARYING vec2 scaleS;
COMPAT_VARYING vec2 scaleO;
COMPAT_VARYING vec2 warpos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float blur;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float slotx;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float ssize;
uniform COMPAT_PRECISION float scan;
uniform COMPAT_PRECISION float curv;
uniform COMPAT_PRECISION float thresh;
uniform COMPAT_PRECISION float colors;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float wp;
uniform COMPAT_PRECISION float potato;

#else
#define blur 1.0
#define width 1.0
#define slotx 1.0
#define mask 0.5
#define ssize 1.0
#define scan 0.4
#define curv 1.0
#define thresh 0.2
#define colors 0.0
#define sat 1.0
#define wp 0.0
#define potato 0.0
#endif

#define PI 3.1415926    
#define pwr vec3(1.0/((-0.5*scan+1.0)*(-0.5*mask+1.0))-1.25)

vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;
    pos *= vec2(1.0 + (pos.y*pos.y)*0.0276, 1.0 + (pos.x*pos.x)*0.0414);
    return pos*0.5 + 0.5;
}

const mat3 P22D93 = mat3(
     1.00000, 0.00000, -0.06173,
     0.07111, 0.96887, -0.01136,
     0.00000, 0.08197,  1.07280);

// NTSC to sRGB matrix, used in linear space
const mat3 NTSC = mat3(1.5073,  -0.3725, -0.0832, 
                    -0.0275, 0.9350,  0.0670,
                     -0.0272, -0.0401, 1.1677);

// Returns gamma corrected output, compensated for scanline+mask embedded gamma
vec3 inv_gamma(vec3 col, vec3 power)
{
    vec3 cir  = col-1.0;
         cir *= cir;
         col  = mix(sqrt(col),sqrt(1.0-cir),power);
    return col;
}

float saturate(float v) { 
    return clamp(v, 0.0, 1.0);       
}


void main()
{
     vec2 pos,corn;
    if (curv == 1.0) { 
        pos = Warp(warpos); 
        pos /= scaleS;
        } 
    else pos = vTexCoord;

    vec2 textureCoords = pos*SourceSize.xy;
    vec2 screenCoords = vTexCoord*SourceSize.xy*scaleO;
    float scaley = scaleO.y*blur;
    vec2 tex_pos = fract(textureCoords);

 //Interpolation: https://colececil.io/blog/2017/scaling-pixel-art-without-destroying-it/
 //If blur is 0.5 on an axis, then the color will not be interpolated on that axis. 
 //If it’s 0 or 1, then it will have maximum interpolation, with 0 being on one side of the texel 
 //and 1 being on the other. Anything between those values will cause interpolation somewhere 
 //between the minimum and maximum. 

    vec2 blur = clamp(tex_pos / scaley, 0.0,0.5) + clamp((tex_pos - 1.0) / scaley + 0.5, 0.0, 0.5);

//At this point, our texture coordinates are still in the range [0, texture size], 
//but we need to get them back into the range [0, 1] before we can use them to grab the color. 
//To do so, we simply divide by the texture width and height

    vec2 coords = (floor(textureCoords) + blur) * SourceSize.zw;
    vec4 res;
     res = COMPAT_TEXTURE(Source,coords);

        vec2 c = warpos;
        corn   = min(c, 1.0-c);    // This is used to mask the rounded
        corn.x = 0.0003333/corn.x; // corners later on

    res *= res;
    // similar mask to Lottes 1, done with sins, option for wide 2.0
    float oddx = mod(screenCoords.x,slotx*2.0) < slotx ? 1.0 : 0.0;
    res *= mix(((1.0-mask+1.0-scan)/2.0  
                    + mask*sin(screenCoords.x*width*PI) 
                    + mask*sin((screenCoords.y+oddx)*PI) 
                    + scan*sin(textureCoords.y*2.0/ssize*PI)), 1.0,dot(res.rgb,vec3(thresh)));
    
    if (colors == 2.0) res.rgb *= NTSC;  else 
    if (colors == 1.0) res.rgb *= P22D93; else
    res.rgb;
    res = clamp(res,0.0,1.0);

    //CHEAP TEMPERATURE CONTROL     
       if (wp != 0.0) { res.rgb *= vec3(1.0+wp,1.0,1.0-wp);}
    
    if (potato == 1.0) res = sqrt(res);
    else res.rgb = inv_gamma(res.rgb,pwr);

    //saturation
    vec3 lumweight = vec3(0.29,0.6,0.11);
    vec3 grays = vec3(dot(lumweight, res.rgb));
    res.rgb = mix(grays, res.rgb, sat);

    if (corn.y <= corn.x && curv == 1.0 || corn.x < 0.0001 && curv ==1.0 )
    res = vec4(0.0);
    FragColor = res;
}

#endif
