#version 110

#pragma parameter LOT_SHARP "SHARPNESS (RGB: ~0.9)" 0.5 0.0 1.0 0.05
#pragma parameter LOT_CURV "CURVATURE OFF/ON/TRINITRON " 1.0 0.0 2.0 1.0
#pragma parameter LOT_SCAN "SCANLINES STRENGTH" 0.3 0.0 0.5 0.05
#pragma parameter shadowMask "SHADOWMASK" 2.0 0.0 4.0 1.0
#pragma parameter maskDark "LOTTES MASK DARK" 0.5 0.0 2.0 0.05
#pragma parameter maskLight "LOTTES MASK LIGHT" 1.5 0.0 2.0 0.05

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
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    scale = SourceSize.xy/InputSize.xy;
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
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float LOT_SHARP;
uniform COMPAT_PRECISION float LOT_CURV;
uniform COMPAT_PRECISION float LOT_SCAN;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
uniform COMPAT_PRECISION float shadowMask;

#else
#define LOT_SHARP 0.5
#define LOT_CURV 1.0
#define LOT_SCAN 0.3
#define maskDark 0.5
#define maskLight 1.5
#define shadowMask 0.0


#endif

#define PI   3.14159265358979323846


vec4 Mask(vec2 pos)
    {
        vec3 mask = vec3(maskDark, maskDark, maskDark);
      
        // Very compressed TV style shadow mask.
        if (shadowMask == 1.0) 
        {
            float line = maskLight;
            float odd = 0.0;
            
            if (fract(pos.x*0.166666666) < 0.5) odd = 1.0;
            if (fract((pos.y + odd) * 0.5) < 0.5) line = maskDark;  
            
            pos.x = fract(pos.x*0.333333333);

            if      (pos.x < 0.333) mask.b = maskLight;
            else if (pos.x < 0.666) mask.g = maskLight;
            else                    mask.r = maskLight;
            mask*=line;  
        } 

        // Aperture-grille.
        else if (shadowMask == 2.0) 
        {
            pos.x = fract(pos.x*0.333333333);

            if      (pos.x < 0.333) mask.b= maskLight;
            else if (pos.x < 0.666) mask.g = maskLight;
            else                    mask.r = maskLight;
        } 
   
        // These can cause moire with curvature and scanlines
        // so they're an easy target for freeing up registers
        
        // Stretched VGA style shadow mask (same as prior shaders).
        else if (shadowMask == 3.0) 
        {
            pos.x += pos.y*3.0;
            pos.x  = fract(pos.x*0.166666666);

            if      (pos.x < 0.333) mask.b = maskLight;
            else if (pos.x < 0.666) mask.g = maskLight;
            else                    mask.r = maskLight;
        }

        // VGA style shadow mask.
        else if (shadowMask == 4.0) 
        {
            pos.xy  = floor(pos.xy*vec2(1.0, 0.5));
            pos.x  += pos.y*3.0;
            pos.x   = fract(pos.x*0.166666666);

            if      (pos.x < 0.333) mask.b = maskLight;
            else if (pos.x < 0.666) mask.g = maskLight;
            else                    mask.r = maskLight;
        }
  
        
        else mask = vec3(1.,1.,1.);

        return vec4(mask, 1.0);
    }



// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    float warpx,warpy;
    if (LOT_CURV == 1.0){warpx = 0.03; warpy = 0.02;}
    else if (LOT_CURV == 2.0){warpx = 0.0; warpy = 0.05;}
    else {warpx = 0.0; warpy=0.0;}

    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpx, 1.0 + (pos.x*pos.x)*warpy);
    
    return pos*0.5 + 0.5;
}

void main() {
//This is just like "Quilez Scaling" but sharper
    vec2 pos = Warp(vTexCoord*scale);
    vec2 corn = min(pos, 1.0-pos);    // This is used to mask the rounded
    corn.x = 0.0001/corn.x;         // corners later on
    pos /= scale;
    
    vec2 p = pos * TextureSize;
    vec2 i = floor(p) + 0.5;
    vec2 f = p - i;
    p = (i + 4.0*f*f*f)*SourceSize.zw;
    p.x = pos.x;
    vec4 final = COMPAT_TEXTURE(Source,p);

    vec2 ps = vec2(SourceSize.z*0.5,0.0);
    float sum = 1.0;
    for (int a=-2; a<2; a++)
    {
        float n = float(a);
        float w = exp(-LOT_SHARP*n*n);
        final += COMPAT_TEXTURE(Source,p+ps*n)*w;
        sum += w;
    }
final /= sum;
final = sqrt(final);

vec4 clean = final;
float l = dot(vec3(0.2),final.rgb);
final *= LOT_SCAN*sin((pos.y*SourceSize.y-0.25)*PI*2.0)+1.0-LOT_SCAN;
final *= Mask(vTexCoord*OutputSize.xy*scale);
final = mix(final,clean,l);

//corners cut
if (LOT_CURV != 0.0){
if (corn.y <= corn.x || corn.x < 0.0001 )final = vec4(0.0);
}

FragColor = final;
}
#endif
