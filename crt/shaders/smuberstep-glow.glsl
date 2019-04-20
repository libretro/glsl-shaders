//SmuberStep - Like SmoothestStep but even Smoothester
//with cheap glow-like effect and dotmask on top
//by torridgristle

#pragma parameter AMPLITUDE  "Scanlines Depth"  1.0000  0.000 4.000 0.05
#pragma parameter LINES_BLACK  "Lines Blacks"   0.9000 -1.000 1.000 0.05
#pragma parameter LINES_WHITE  "Lines Whites"   1.5000  0.000 2.000 0.05
#pragma parameter PHASE        "Phase"          1.0000 -2.000 2.000 0.5

#pragma parameter shadowMask "Mask Style" 3.0 -1.0 4.0 1.0
#pragma parameter DOTMASK_STRENGTH "CGWG Dot Mask Strength" 0.3 0.0 1.0 0.01
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.1
#pragma parameter maskLight "Lottes maskLight" 1.5 0.0 2.0 0.1
 
#define freq             1.000000
#define PI               3.141592654

#ifndef PARAMETER_UNIFORM
#define amp              1.250000
#define phase            0.500000
#define lines_black      0.000000
#define lines_white      1.000000
#endif

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
COMPAT_VARYING float angle;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PHASE;
#endif

const float omega = 2.0 * PI * freq;        // Angular frequency

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy * 1.0001;
    angle = TEX0.y * TextureSize.y * omega - PHASE;
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
COMPAT_VARYING float angle;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float AMPLITUDE;
uniform COMPAT_PRECISION float LINES_BLACK;
uniform COMPAT_PRECISION float LINES_WHITE;
uniform COMPAT_PRECISION float PHASE;
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float DOTMASK_STRENGTH;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
#else
#define AMPLITUDE        1.000000
#define LINES_BLACK      1.000000
#define LINES_WHITE      1.500000
#define PHASE            0.500000
#define shadowMask 3.0
#define DOTMASK_STRENGTH 0.3
#define maskDark 0.5
#define maskLight 1.5
#endif

#define mod_factor vTexCoord.x * SourceSize.x * outsize.x / SourceSize.x

// Shadow mask.
vec3 Mask(vec2 pos)
{
   vec3 mask = vec3(maskDark, maskDark, maskDark);
   
   // Very compressed TV style shadow mask.
   if (shadowMask == 1.0)
   {
      float line = maskLight;
      float odd  = 0.0;

      if (fract(pos.x/6.0) < 0.5)
         odd = 1.0;
      if (fract((pos.y + odd)/2.0) < 0.5)
         line = maskDark;

      pos.x = fract(pos.x/3.0);
    
      if      (pos.x < 0.333) mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    mask.b = maskLight;
      mask*=line;  
   } 

   // Aperture-grille.
   else if (shadowMask == 2.0)
   {
      pos.x = fract(pos.x/3.0);

      if      (pos.x < 0.333) mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    mask.b = maskLight;
   } 

   // Stretched VGA style shadow mask (same as prior shaders).
   else if (shadowMask == 3.0)
   {
      pos.x += pos.y*3.0;
      pos.x  = fract(pos.x/6.0);

      if      (pos.x < 0.333) mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    mask.b = maskLight;
   }

   // VGA style shadow mask.
   else if (shadowMask == 4.0)
   {
      pos.xy = floor(pos.xy*vec2(1.0, 0.5));
      pos.x += pos.y*3.0;
      pos.x  = fract(pos.x/6.0);

      if      (pos.x < 0.333) mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    mask.b = maskLight;
   }

   return mask;
}

// torridgristle's shadowmask code
const float Pi = 3.1415926536;

vec3 SinPhosphor(vec3 image)
{
    float MaskR = sin(OutputSize.x*vTexCoord.x*Pi*1.0+Pi*0.00000+vTexCoord.y*OutputSize.y*Pi*0.5)*0.5+0.5;
    float MaskG = sin(OutputSize.x*vTexCoord.x*Pi*1.0+Pi*1.33333+vTexCoord.y*OutputSize.y*Pi*0.5)*0.5+0.5;
    float MaskB = sin(OutputSize.x*vTexCoord.x*Pi*1.0+Pi*0.66667+vTexCoord.y*OutputSize.y*Pi*0.5)*0.5+0.5;

    vec3 Mask = vec3(MaskR,MaskG,MaskB);
    
    Mask = min(Mask*2.0,1.0);
    
    return vec3(Mask * image);
}

void main()
{
    vec2 SStep = vTexCoord * SourceSize.xy + 0.4999;
	vec2 SStepInt = floor(SStep);
	vec2 SStepFra = SStep - SStepInt;

    SStep = ((924.*pow(SStepFra,vec2(13)) - 6006.*pow(SStepFra,vec2(12)) + 16380.*pow(SStepFra,vec2(11)) - 24024.*pow(SStepFra,vec2(10)) + 20020.*pow(SStepFra,vec2(9)) - 9009.*pow(SStepFra,vec2(8)) + 1716.*pow(SStepFra,vec2(7))) + SStepInt - 0.5) * SourceSize.zw;

        vec3 Picture = COMPAT_TEXTURE(Source,SStep).xyz;
   
    float Lum = ((0.299*Picture.x) + (0.587*Picture.y) + (0.114*Picture.z));
          Lum = 1.-Lum;
          Lum = Lum * 0.5;
   
    vec3 PictureBlur = pow(COMPAT_TEXTURE(Source,SStep+SourceSize.zw*vec2( Lum, Lum)).xyz, vec3(2.2));
        PictureBlur += pow(COMPAT_TEXTURE(Source,SStep+SourceSize.zw*vec2(-Lum, Lum)).xyz, vec3(2.2));
        PictureBlur += pow(COMPAT_TEXTURE(Source,SStep+SourceSize.zw*vec2( Lum,-Lum)).xyz, vec3(2.2));
        PictureBlur += pow(COMPAT_TEXTURE(Source,SStep+SourceSize.zw*vec2(-Lum,-Lum)).xyz, vec3(2.2));
        PictureBlur *= 0.25;
        float grid;
 
    float lines;
    lines = sin(angle);
	lines *= AMPLITUDE;
    lines = clamp(lines, 0.0, 1.0);
    lines *= LINES_WHITE - LINES_BLACK;
    lines += LINES_BLACK;

	PictureBlur *= lines;
    
       float mask = 1.0 - DOTMASK_STRENGTH;

   //cgwg's dotmask emulation:
   //Output pixels are alternately tinted green and magenta
   vec3 dotMaskWeights = mix(vec3(1.0, mask, 1.0),
                             vec3(mask, 1.0, mask),
                             floor(mod(mod_factor, 2.0)));
   if (shadowMask > 0.5) 
   {
      PictureBlur *= Mask(floor(1.000001 * gl_FragCoord.xy + vec2(0.5,0.5)));
      FragColor = vec4(pow(PictureBlur, vec3(1.0/2.2)),1.0);

      return;
   }
   else if (shadowMask == 0.)
   {
      PictureBlur = pow(PictureBlur, vec3(1.0/2.2));
      PictureBlur *= dotMaskWeights;
      FragColor = vec4(PictureBlur,1.0);
      return;
   }
   else 
   {
      PictureBlur = pow(PictureBlur, vec3(1.0/2.2));
      PictureBlur = pow(PictureBlur, vec3(1.0/2.2)); //dunno why this needed double delinearization but whatever
      PictureBlur *= SinPhosphor(PictureBlur);
      FragColor = vec4(PictureBlur,1.0);
   }
} 
#endif
