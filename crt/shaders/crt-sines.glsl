#version 110

/* 
  work by DariusG 2023, some ideas borrowed from Dogway's zfast_crt_geo
  v1.1: switched to lanczos4 taps filter
*/

#pragma parameter curv "Curvature"  1.0 0.0 1.0 1.0
#pragma parameter Shadowmask "  Mask Type " 0.0 -1.0 2.0 1.0
#pragma parameter slotx "  Slot Size x" 3.0 2.0 3.0 1.0
#pragma parameter width "  Mask Width 3.0/2.0 " 0.67 0.67 1.0 0.333
#pragma parameter mask "  Mask Strength" 0.25 0.0 1.0 0.05
#pragma parameter ssize "Scanline Size" 1.0 1.0 2.0 1.0
#pragma parameter scan "Scanline Strength" 0.8 0.0 1.0 0.05
#pragma parameter thresh "Effect Threshold on brights" 0.12 0.0 0.33 0.01
#pragma parameter colors "  Colors: 0.0 RGB, 1.0 P22D93, 2.0:NTSC" 0.0 0.0 2.0 1.0
#pragma parameter sat "  Saturation" 1.15 0.0 2.0 0.01
#pragma parameter wp "  White Point" -0.05 -0.2 0.2 0.01

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
COMPAT_VARYING vec2 fragpos;

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
    fragpos = TEX0.xy*OutputSize.xy*scaleS;
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
COMPAT_VARYING vec2 fragpos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float slotx;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float Shadowmask;
uniform COMPAT_PRECISION float ssize;
uniform COMPAT_PRECISION float scan;
uniform COMPAT_PRECISION float curv;
uniform COMPAT_PRECISION float thresh;
uniform COMPAT_PRECISION float colors;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float wp;

#else
#define width 1.0
#define slotx 1.0
#define Shadowmask 0.0
#define mask 0.5
#define ssize 1.0
#define scan 1.0
#define curv 1.0
#define thresh 0.2
#define colors 0.0
#define sat 1.0
#define wp 0.0
#endif

#define PI 3.1415926    
#define FIX(c) max(abs(c), 0.000001);

vec4 weight4(float x)
        {
            const float radius = 2.0;
            vec4 smpl = FIX(PI * vec4(1.0 + x, x, 1.0 - x, 2.0 - x));

            // Lanczos2. Note: we normalize below, so no point in multiplying by radius.
            vec4 ret = /*radius **/ sin(smpl) * sin(smpl / radius) / (smpl * smpl);

            // Normalize
            return ret / dot(ret, vec4(1.0));
        }

vec4 pixel(float xpos, float ypos)
        {

            return COMPAT_TEXTURE(Source, vec2(xpos, ypos));
        }

vec4 line(float ypos, vec4 xpos, vec4 linetaps)
        {
            return mat4(
                pixel(xpos.x, ypos),
                pixel(xpos.y, ypos),
                pixel(xpos.z, ypos),
                pixel(xpos.w, ypos)) * linetaps;
        }


float Mask (vec2 pos)
{
    if (Shadowmask == 0.0)
    {
        return mask*sin(fragpos.x*PI)+1.0-mask;
    }

    if (Shadowmask == 1.0)
    {
        float oddx = mod(fragpos.x,slotx*2.0) < slotx ? 1.0 : 0.0;

        return        mask*sin(fragpos.x*width*PI) 
                    + mask*sin((fragpos.y+oddx)*PI)+1.0-mask ;
    }

    if (Shadowmask == 2.0)
    {
        return mask*sin(fract(fragpos.x*0.333)*PI)+1.0-mask;
    }

 else return 1.0;
}


const mat3 P22D93 = mat3(
     1.00000, 0.00000, -0.06173,
     0.07111, 0.96887, -0.01136,
     0.00000, 0.08197,  1.07280);

// NTSC to sRGB matrix, used in linear space
const mat3 NTSC = mat3(1.5073,  -0.3725, -0.0832, 
                    -0.0275, 0.9350,  0.0670,
                     -0.0272, -0.0401, 1.1677);

vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;
    pos *= vec2(1.0 + (pos.y*pos.y)*0.0276, 1.0 + (pos.x*pos.x)*0.0414);
    return pos*0.5 + 0.5;
}

void main()
{

    vec2 pos,corn;
    if (curv == 1.0) { 
        pos = Warp(warpos); 
        pos /= scaleS;
        } 
    else pos = vTexCoord;
    
// LANCZOS 4 taps
            vec2 one_pix = SourceSize.zw;
            pos = pos + one_pix*0.5;
            vec2 f = fract(pos * SourceSize.xy);

            vec4 linetaps   = weight4(f.x);
            vec4 columntaps = weight4(f.y);

            vec2 xystart = pos - one_pix*(f + 1.5);
            vec4 xpos = vec4(
                xystart.x,
                xystart.x + one_pix.x,
                xystart.x + one_pix.x * 2.0,
                xystart.x + one_pix.x * 3.0);


        vec4 res = mat4(
                line(xystart.y                  , xpos, linetaps),
                line(xystart.y + one_pix.y      , xpos, linetaps),
                line(xystart.y + one_pix.y * 2.0, xpos, linetaps),
                line(xystart.y + one_pix.y * 3.0, xpos, linetaps)) * columntaps;
               
    if (colors == 2.0) res.rgb *= NTSC;  else 
    if (colors == 1.0) res.rgb *= P22D93; else
    res.rgb;

    res = clamp(res,0.0,1.0);
    
    pos.y -= 0.01 ;
    float OGL2Pos = fract((pos.y*SourceSize.y)/ssize);
    float lum = dot(vec3(thresh), res.rgb);
    
    //res.rgb *= res.rgb;
    float scanline = scan*sin(OGL2Pos*PI)+1.0-scan;
    res *= mix(scanline*Mask(vTexCoord),1.0, lum);
    //res.rgb = sqrt(res.rgb);

        vec2 c = warpos;
        corn   = min(c, 1.0-c);    // This is used to mask the rounded
        corn.x = 0.0003333/corn.x; // corners later on

    //CHEAP TEMPERATURE CONTROL     
    if (wp != 0.0) { res.rgb *= vec3(1.0+wp,1.0,1.0-wp);}
     //saturation
    vec3 lumweight = vec3(0.29,0.6,0.11);
    vec3 grays = vec3(dot(lumweight, res.rgb));
    res.rgb = mix(grays, res.rgb, sat);
    res.rgb *= mix(1.25,1.35, grays.x);
    if (corn.y <= corn.x && curv == 1.0 || corn.x < 0.0001 && curv ==1.0 )
    res = vec4(0.0);

#if defined GL_ES
    // hacky clamp fix for GLES
    vec2 bordertest = pos;
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec4(0.0);
#endif

    FragColor = res;
}

#endif
