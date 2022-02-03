

// Parameter lines go here:

#pragma parameter WARP "Curvature" 0.0 0.0 0.12 0.01
#pragma parameter CONVX "Convergence X" 0.0 -1.0 1.0 0.05
#pragma parameter CONVY "Convergence Y" 0.0 -1.0 1.0 0.05
#pragma parameter SCANLINE "Scanline Strength" 0.3 0.0 1.0 0.02
#pragma parameter BRIGHTBOOST1 "Bright boost dark pixels" 1.1 0.0 3.0 0.05
#pragma parameter BRIGHTBOOST2 "Bright boost bright pixels" 1.05 0.0 3.0 0.05
#pragma parameter Shadowmask "Mask Type" 0.0 -1.0 4.0 1.0
#pragma parameter masksize "Mask Size" 1.0 0.0 2.0 1.0
#pragma parameter MaskDark "Mask Dark" 0.5 0.0 1.0 0.1
#pragma parameter MaskLight "Mask Light" 1.5 0.0 1.0 0.1
#pragma parameter GAMMA_IN "Gamma In" 2.5 0.0 4.0 0.1
#pragma parameter GAMMA_OUT "Gamma Out" 2.2 0.0 4.0 0.1
#pragma parameter SATURATION "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter intensity "Glow Strength, 0.0 for speedup" 0.0 0.0 0.5 0.01
#pragma parameter FALLOFF "Glow Fall off" 0.5 0.1 10.0 0.05
#pragma parameter GlowSize "Glow Size" 1.5 0.0 8.0 0.25
#pragma parameter SAMPLES "Glow Samples" 2.0 1.0 8.0 1.0


#define PI 3.14159


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
COMPAT_ATTRIBUTE vec4 TexCoord;
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
   TEX0.xy = TexCoord.xy*1.0001;
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
out lowfp vec4 FragColor;
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
#define iChannel0 Texture
#define iTime (float(FrameCount) / 60.0)

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float WARP;
uniform COMPAT_PRECISION float CONVX;
uniform COMPAT_PRECISION float CONVY;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float SATURATION;
uniform COMPAT_PRECISION float GAMMA_IN;
uniform COMPAT_PRECISION float GAMMA_OUT;
uniform COMPAT_PRECISION float BRIGHTBOOST1;
uniform COMPAT_PRECISION float BRIGHTBOOST2;
uniform COMPAT_PRECISION float Shadowmask;
uniform COMPAT_PRECISION float MaskDark;
uniform COMPAT_PRECISION float MaskLight;
uniform COMPAT_PRECISION float masksize;
uniform COMPAT_PRECISION float intensity;
uniform COMPAT_PRECISION float FALLOFF;
uniform COMPAT_PRECISION float GlowSize;
uniform COMPAT_PRECISION float SAMPLES;



#else
#define WARP 0.06
#define CONVX 0.1
#define CONVY 0.2
#define SCANLINE 0.3
#define SATURATION 1.0 
#define BRIGHTBOOST1 1.5 
#define BRIGHTBOOST2 1.1 
#define GAMMA_IN 2.5
#define GAMMA_OUT 2.2
#define Shadowmask 0.0
#define MaskDark 0.5
#define MaskLight 1.5
#define masksize 1.0
#define intensity 0.2
#define FALLOFF 0.3
#define GlowSize 1.0
#define GlowSize 3.0

#endif




// Slight fish eye effect, bulge in the middle
vec2 Warp(vec2 uv) 
{
    float yMul = 1.0+WARP - WARP * sin(uv.x *PI);
            
    if(uv.y >= 0.5)
    {
        return vec2(uv.x, yMul*(uv.y-0.5)+0.5 );
    }
    else
    {
        return vec2(uv.x, 0.5+yMul*(uv.y-0.5));
    }
}

vec4 scanLine(vec4 c, float y ) 
{
    float lum=length(c)*0.5775;
    lum=1.8*pow(lum,0.45)-0.8; lum=clamp(lum,0.0,1.0);

    float intensity = 1.0*lum+(SCANLINE *sin(y*InputSize.y*PI*(2.0*TextureSize.y/InputSize.y)));

    vec4 result = vec4(intensity * c.rgb, 1.0);
    return result;
}

vec4 mask(vec2 x)
{
    x = floor(x/masksize);        
  

    if (Shadowmask == 0.0)
    {
    float m =fract(x.x*0.4999);

    if (m<0.4999) return vec4(MaskLight,MaskDark,MaskLight,1.0);
    else return vec4(MaskDark,MaskLight,MaskDark,1.0);
    }
   
    else if (Shadowmask == 1.0)
    {
        vec4 Mask = vec4(MaskDark,MaskDark,MaskDark,1.0);

        float line = MaskLight;
        float odd  = 0.0;

        if (fract(x.x/6.0) < 0.5)
            odd = 1.0;
        if (fract((x.y + odd)/2.0) < 0.5)
            line = MaskDark;

        float m = fract(x.x/3.0);
    
        if      (m< 0.333)  Mask.r = MaskLight;
        else if (m < 0.666) Mask.g = MaskLight;
        else                Mask.b = MaskLight;
        
        Mask*=line; 
        return Mask; 
    } 
    

    else if (Shadowmask == 2.0)
    {
    float m =fract(x.x*0.3333);

    if (m<0.3333) return vec4(MaskLight,MaskDark,MaskDark,1.0);
    if (m<0.6666) return vec4(MaskDark,MaskLight,MaskDark,1.0);
    else return vec4(MaskDark,MaskDark,MaskLight,1.0);
    }

    if (Shadowmask == 3.0)
    {
    float m =fract(x.x*0.5);

    if (m<0.5) return vec4(MaskLight,MaskLight,MaskLight,1.0);
    else return vec4(MaskDark,MaskDark,MaskDark,1.0);
    }
   

    else if (Shadowmask == 4.0)
    {   
        vec4 Mask = vec4(MaskDark,MaskDark,MaskDark,1.0);
        float line = MaskLight;
        float odd  = 0.0;

        if (fract(x.x/4.0) < 0.5)
            odd = 1.0;
        if (fract((x.y + odd)/2.0) < 0.5)
            line = MaskDark;

        float m = fract(x.x/2.0);
    
        if  (m < 0.5) {Mask.r = MaskLight; Mask.b = MaskLight;}
                else  Mask.g = MaskLight;   

        Mask*=line;  
        return Mask;
    } 
    else return vec4(1.0);
}


vec4 saturation (vec4 textureColor)
{
    float lum=length(textureColor.rgb)*0.5775;

    vec3 luminanceWeighting = vec3(0.4,0.5,0.1);
    if (lum<0.5) luminanceWeighting.rgb=(luminanceWeighting.rgb*luminanceWeighting.rgb)+(luminanceWeighting.rgb*luminanceWeighting.rgb);

    float luminance = dot(textureColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);

    vec4 res = vec4(mix(greyScaleColor, textureColor.rgb, SATURATION),1.0);
    return res;
}


vec4 glow (vec2 texcoord,vec4 col)
{
    vec4 sum = vec4(0.0);
    float dx = GlowSize * SourceSize.z;
    float dy = GlowSize *SourceSize.w;
    float k=0.0;
    float k_total=0.0;

    for (float i = -SAMPLES; i <= SAMPLES; i++) 
    {
    float x=i;
    k = exp(-FALLOFF * (x) * (x));
    k_total += k;
        

   // blur in x (horiz)
   // take nine samples, with the distance blurSize between them
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - i*dx, texcoord.y)) * k;
    
    // blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x, texcoord.y - i*dy)) * k;
  
    }
    sum=vec4((sum.rgb/k_total),1.0);
   //increase blur with intensity!
   return sum*intensity; 
 
}


void main()
{
    vec2 pos = TEX0.xy;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = Warp(pos.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
    
    // Take multiple samples to displace different color channels
    vec3 sample1 = COMPAT_TEXTURE(iChannel0, vec2(uv.x-CONVX/1000.0,uv.y-CONVY/1000.0)).rgb; 
    vec3 sample2 = COMPAT_TEXTURE(iChannel0, uv).rgb;
    vec3 sample3 = COMPAT_TEXTURE(iChannel0, vec2(uv.x+CONVX/1000.0,uv.y+CONVY/1000.0)).rgb;
 
    
    vec4 color = vec4(0.5*sample1.r+0.5*sample2.r, 0.25*sample1.g+0.5*sample2.g+0.25*sample3.g, 0.5*sample2.b+0.5*sample3.b, 1.0);
    
    
    color=pow(color,vec4(GAMMA_IN, GAMMA_IN,GAMMA_IN,1.0));
    
    color*=mix(BRIGHTBOOST1, BRIGHTBOOST2, max(max(color.r,color.g),color.b));    

    color=scanLine(color,uv.y);
    color*=mask(gl_FragCoord.xy);

    color=pow(color,vec4(1.0/GAMMA_OUT,1.0/GAMMA_OUT,1.0/GAMMA_OUT,1.0)); 

    if (intensity !=0.0) color+=glow(uv,color);
    if (SATURATION != 1.0) color = saturation(color);

    FragColor = color;
} 
#endif
