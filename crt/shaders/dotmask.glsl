/*
    Dot Mask
    Authors: cgwg, Timothy Lottes
    License: GPL
    
    Note: This shader is just the dotmask functions from cgwg's CRT shader and crt-lottes.
*/

// Parameter lines go here:
#pragma parameter shadowMask "Mask Style" 3.0 0.0 4.0 1.0
#pragma parameter BGR "RGB/BGR subpixels" 0.0 0.0 1.0 1.0
#pragma parameter DOTMASK_STRENGTH "CGWG Dot Mask Strength" 0.3 0.0 1.0 0.01
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.1
#pragma parameter maskLight "Lottes maskLight" 1.5 0.0 2.0 0.1

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

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
      gl_Position = MVPMatrix * VertexCoord;
      COL0 = COLOR;
      TEX0.xy = TexCoord.xy;
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

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float BGR;
uniform COMPAT_PRECISION float DOTMASK_STRENGTH;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
#else
#define shadowMask 3.0
#define BGR 0.0
#define DOTMASK_STRENGTH 0.3
#define maskDark 0.5
#define maskLight 1.5
#endif

#define mod_factor vTexCoord.x * outsize.x/InputSize.x* SourceSize.x 

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
    
      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = maskLight : mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    (BGR == 1.0) ? mask.r = maskLight : mask.b = maskLight;
      mask*=line;  
   } 

   // Aperture-grille.
   else if (shadowMask == 2.0)
   {
      pos.x = fract(pos.x/3.0);

      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = maskLight : mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    (BGR == 1.0) ? mask.r = maskLight : mask.b = maskLight;
   } 

   // Stretched VGA style shadow mask (same as prior shaders).
   else if (shadowMask == 3.0)
   {
      pos.x += pos.y*3.0;
      pos.x  = fract(pos.x/6.0);

      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = maskLight : mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    (BGR == 1.0) ? mask.r = maskLight : mask.b = maskLight;
   }

   // VGA style shadow mask.
   else if (shadowMask == 4.0)
   {
      pos.xy = floor(pos.xy*vec2(1.0, 0.5));
      pos.x += pos.y*3.0;
      pos.x  = fract(pos.x/6.0);

      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = maskLight : mask.r = maskLight;
      else if (pos.x < 0.666) mask.g = maskLight;
      else                    (BGR == 1.0) ? mask.r = maskLight : mask.b = maskLight;
   }

   return mask;
}

void main()
{
   vec3 res = pow(COMPAT_TEXTURE(Source, vTexCoord).rgb, vec3(2.2,2.2,2.2));

   float mask = 1.0 - DOTMASK_STRENGTH;

   //cgwg's dotmask emulation:
   //Output pixels are alternately tinted green and magenta
   vec3 dotMaskWeights = mix(vec3(1.0, mask, 1.0),
                             vec3(mask, 1.0, mask),
                             floor(mod(mod_factor, 2.0)));
   if (shadowMask == 0.) 
   {
      res *= dotMaskWeights;
   }
   else 
   {
      res *= Mask(floor(1.000001 * gl_FragCoord.xy + vec2(0.5,0.5)));
   }
   
      FragColor = vec4(pow(res, vec3(1.0/2.2, 1.0/2.2, 1.0/2.2)), 1.0);
} 
#endif
