#version 110

/* 
  work by DariusG 2023, some ideas borrowed from Dogway's zfast_crt_geo

  v1.4b added some system specific tweaks
  v1.4 removed junk, optimized white point a bit
  v1.3 added more color options and Color Temp switch
  v1.2b: Lanczos4 --> Lanczos2 for performance. mask 0 improved
  v1.2: improved mask/scanlines
  v1.1: switched to lanczos4 taps filter
*/

#pragma parameter SHARPNESS "LANCZOS SHARPNESS" 1.66 0.7 2.4 0.01 
#pragma parameter curv "Curvature"  1.0 0.0 1.0 1.0
#pragma parameter ssize "Scanline Size" 1.0 1.0 2.0 1.0
#pragma parameter scanL "Scanline Weight" 0.8 0.0 1.0 0.05
#pragma parameter Shadowmask "  Mask Type " 0.0 -1.0 2.0 1.0
#pragma parameter slotx "  Slot Size x" 3.0 2.0 3.0 1.0
#pragma parameter width "  Mask Width 3.0/2.0 " 0.6666 0.6666 1.0 0.3333
#pragma parameter mask "  Mask Strength" 0.4 0.0 1.0 0.05
#pragma parameter sat "Saturation" 1.0 0.0 2.0 0.01
#pragma parameter colors "Colors: 0.0 SMPTE-C, 1.0 Sony P22, 2.0:NTSC" 1.0 -1.0 2.0 1.0
#pragma parameter wp "White Point Adjust" 0.0 -0.25 0.25 0.01
#pragma parameter bogus " [ System Tweaks ] " 0.0 0.0 0.0 0.0
#pragma parameter push_r "PAL Push Red" 0.0 0.0 0.15 0.01
#pragma parameter NTSC_asp "Amiga NTSC Aspect, eg Monkey Island" 0.0 0.0 01.0 1.0
#pragma parameter sega "Luminance Fix: Sega, Amiga dark ST colors" 0.0 0.0 2.0 1.0

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
uniform COMPAT_PRECISION float SHARPNESS;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float slotx;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float Shadowmask;
uniform COMPAT_PRECISION float ssize;
uniform COMPAT_PRECISION float scanL;
uniform COMPAT_PRECISION float curv;
uniform COMPAT_PRECISION float thresh;
uniform COMPAT_PRECISION float colors;
uniform COMPAT_PRECISION float push_r;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float wp;
uniform COMPAT_PRECISION float NTSC_asp;
uniform COMPAT_PRECISION float sega;

#else
#define width 1.0
#define slotx 1.0
#define Shadowmask 0.0
#define mask 0.5
#define ssize 1.0
#define scanL 0.6
#define curv 1.0
#define thresh 0.2
#define colors 0.0
#define push_r 0.0
#define sat 1.0
#define wp 0.0
#define SHARPNESS 1.66
#define NTSC_asp 0.0
#define sega 0.0

#endif

#define PI 3.1415926    
#define FIX(c) max(abs(c), 0.000001);
#define back 1.0-mask

vec2 weight2(float x)
        {
            float radius = 3.0-SHARPNESS;
            vec2 smpl = FIX(PI * vec2(1.0 - x, x));

            // Lanczos2. Note: we normalize below, so no point in multiplying by radius.
            vec2 ret = sin(smpl) * sin(smpl / radius) / (smpl * smpl);

            // Normalize
            return ret / dot(ret, vec2(1.0));
        }

vec3 pixel(float xpos, float ypos)
        {

            return COMPAT_TEXTURE(Source, vec2(xpos, ypos)).rgb;
        }

vec3 line(float ypos, vec2 xpos, vec2 linetaps)
        {
            return (pixel(xpos.x, ypos) * linetaps.x +
                    pixel(xpos.y, ypos) * linetaps.y) ;
        }




float Mask (vec2 pos)
{
    if (Shadowmask == 0.0)
    {
        return mask*(0.5*sin(fragpos.x*PI)+0.5)+back;
    }

    else if (Shadowmask == 1.0)
    {
        float oddx = mod(fragpos.x,slotx*2.0) < slotx ? 1.0 : 0.0;

        return        (0.5*mask*sin(fragpos.x*width*PI)+0.5) 
                    + (0.5*mask*sin((fragpos.y+oddx)*PI)+0.5) ;
    }

    else if (Shadowmask == 2.0)
    {
        return mask*(0.5*sin(fragpos.x*PI*0.666)+0.5)+1.0-mask*1.0001;
    }

 else return 1.0;
}


const mat3 SonyP22 = mat3(
1.10544112,  -0.09467967, -0.00547813,
0.12322469,  0.88445481,  -0.00151429,
0.02295649,  -0.00169611, 0.98164123);

// NTSC to sRGB matrix, used in linear space
const mat3 NTSC = mat3(1.5073,  -0.3725, -0.0832, 
                    -0.0275, 0.9350,  0.0670,
                     -0.0272, -0.0401, 1.1677);

const mat3 SMPTE_C = mat3(
0.93202665669,   0.04110980761,   0.02156250279,
0.01362929932 ,  0.97099824432 ,  0.01473191244,
0.005551435508 , -0.01431194472 , 1.00829538798
);

vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;
    pos *= vec2(1.0 + (pos.y*pos.y)/32.0, 1.0 + (pos.x*pos.x)/24.0);
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
    if(NTSC_asp == 1.0) { pos.y *= 200.0/240.0; pos.y += 0.004;}

// LANCZOS 2 taps
            vec2 one_pix = SourceSize.zw;
            pos = pos + one_pix*2.5;
            vec2 f = fract(pos * SourceSize.xy);

            vec2 linetaps   = weight2(f.x);
            vec2 columntaps = weight2(f.y);

            vec2 xystart = pos - one_pix*(f + 1.5);
            vec2 xpos = vec2(
                xystart.x,
                xystart.x - one_pix.x 
              );

        vec3 res = 
                line(xystart.y                  , xpos, linetaps)* columntaps.x +
                line(xystart.y - one_pix.y      , xpos, linetaps)* columntaps.y
                 ;
               
                              
       
   
    float OGL2Pos = fract((pos.y*SourceSize.y)/ssize);
    float lum = 2.0+dot(vec3(0.666), res);

    float scan = pow(scanL, lum);
    

// Some color tweaks    
    if (colors == 2.0) res.rgb *= NTSC;  else 
    if (colors == 1.0) res.rgb *= SonyP22; else
    if (colors == 0.0) res.rgb *= SMPTE_C; else
    res.rgb; res = clamp(res, 0.0,1.0);

    if (lum>2.0)  res.rb += vec2(push_r,push_r/3.0);
    if (sega == 1.0) res *= 1.06;
    if (sega == 2.0) res *= 2.0;
    res *= res;

// That 0.4 plus and divide, on a raised luminance dependent 'scanline', removes moire, in crt-Geom style.
    float scanline = 0.4+(scan*sin(OGL2Pos*PI*2.0)+1.0-scan)/(0.8+0.15*lum);
    res *= scanline;
    res *= Mask(vTexCoord);
    res = sqrt(res);
    //CHEAP TEMPERATURE CONTROL     
    if (wp != 0.0) { res.rgb *= vec3(1.0 + 0.08*wp,1.0,1.0-0.8*wp);
                   if(wp > 0.0)  res.rgb += vec3(0.15*wp,0.0,0.0);
                   if(wp < 0.0)  res.rgb += vec3(0.0,0.0,-0.15*wp);
    
    }
    
    //SATURATION
    vec3 lumweight = vec3(0.29,0.6,0.11);
    vec3 grays = vec3(dot(lumweight, res.rgb));
    res.rgb = mix(grays, res.rgb, sat);
    // CORNERS
    vec2 c = warpos;
    corn   = min(c, 1.0-c);    // This is used to mask the rounded
    corn.x = 0.00038/corn.x; // corners later on

    if (corn.y <= corn.x && curv == 1.0 || corn.x < 0.0001 && curv ==1.0 )
    res = vec3(0.0);

// GLES FIX
#if defined GL_ES
    vec2 bordertest = pos;
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec3(0.0);
#endif

    FragColor = vec4(res,1.0);
}

#endif
