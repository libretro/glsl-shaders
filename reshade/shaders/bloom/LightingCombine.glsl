#version 130

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
   TEX0.xy = TexCoord.xy * 1.0001 * TextureSize / InputSize;
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
out COMPAT_PRECISION vec4 FragColor;
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
uniform sampler2D Dirt;
uniform sampler2D Sprite;
uniform sampler2D PassPrev6Texture;
uniform sampler2D PassPrev4Texture;
COMPAT_VARYING vec4 TEX0;

#define SamplerBloom3 PassPrev6Texture
#define SamplerBloom5 PassPrev4Texture
#define LensFlare1 Texture

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define saturate(b) clamp(b, 0.0, 1.0)

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#define FIX (InputSize / TextureSize)

// If 1, only pixels with depth = 1 get lens flares
// This prevents white objects from getting lens flares sources, which would normally happen in LDR
#ifndef LENZ_DEPTH_CHECK
   #define LENZ_DEPTH_CHECK 0
#endif
#ifndef CHAPMAN_DEPTH_CHECK
   #define CHAPMAN_DEPTH_CHECK 0
#endif
#ifndef GODRAY_DEPTH_CHECK
   #define GODRAY_DEPTH_CHECK 0
#endif
#ifndef FLARE_DEPTH_CHECK
   #define FLARE_DEPTH_CHECK 0
#endif

uniform sampler2D OrigTexture;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float iBloomMixmode, fBloomThreshold, fBloomAmount, fBloomSaturation, fBloomTint_r,
   fBloomTint_g, fBloomTint_b, bLensdirtEnable_toggle, iLensdirtMixmode,
   fLensdirtIntensity, fLensdirtSaturation, fLensdirtTint_r, fLensdirtTint_g,
   fLensdirtTint_b, bAnamFlareEnable_toggle, fAnamFlareThreshold, fAnamFlareWideness,
   fAnamFlareAmount, fAnamFlareCurve, fAnamFlareColor_r, fAnamFlareColor_g,
   fAnamFlareColor_b, bLenzEnable_toggle, fLenzIntensity, fLenzThreshold,
   bChapFlareEnable_toggle, fChapFlareThreshold, iChapFlareCount, fChapFlareDispersal,
   fChapFlareSize, fChapFlareCA_r, fChapFlareCA_g, fChapFlareCA_b, fChapFlareIntensity,
   bGodrayEnable_toggle, fGodrayDecay, fGodrayExposure, fGodrayWeight, fGodrayDensity,
   fGodrayThreshold, iGodraySamples, fFlareLuminance, fFlareBlur, fFlareIntensity,
   fFlareTint_r, fFlareTint_g, fFlareTint_b;
#endif

vec3 fFlareTint = vec3(fFlareTint_r, fFlareTint_g, fFlareTint_b);
vec3 fAnamFlareColor = vec3(fAnamFlareColor_r, fAnamFlareColor_g, fAnamFlareColor_b);
vec3 fLensdirtTint = vec3(fLensdirtTint_r, fLensdirtTint_g, fLensdirtTint_b);
vec3 fBloomTint = vec3(fBloomTint_r, fBloomTint_g, fBloomTint_b);
vec3 fChapFlareCA = vec3(fChapFlareCA_r, fChapFlareCA_g, fChapFlareCA_b);

bool bGodrayEnable = bool(bGodrayEnable_toggle);
bool bChapFlareEnable = bool(bChapFlareEnable_toggle);
bool bLenzEnable = bool(bLenzEnable_toggle);
bool bAnamFlareEnable = bool(bAnamFlareEnable_toggle);
bool bLensdirtEnable = bool(bLensdirtEnable_toggle);

#define PixelSize (1.0 / TextureSize.xy)
#define BackBuffer OrigTexture

uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;

void main()
{
   vec4 color = vec4(0.);
   color = COMPAT_TEXTURE(BackBuffer, vTexCoord.xy / (OrigTextureSize / OrigInputSize));

   // Bloom
   vec3 colorbloom = vec3(0.);
   colorbloom += COMPAT_TEXTURE(SamplerBloom3, vTexCoord.xy * FIX).rgb * 1.0;
   colorbloom += COMPAT_TEXTURE(SamplerBloom5, vTexCoord.xy * FIX).rgb * 9.0;
   colorbloom *= 0.1;
   colorbloom = saturate(colorbloom);
   float colorbloomgray = dot(colorbloom, vec3(0.333));
   colorbloom = mix(vec3(colorbloomgray), colorbloom, vec3(fBloomSaturation));
   colorbloom *= fBloomTint;

   if (iBloomMixmode == 0.)
      color.rgb += colorbloom;
   else if (iBloomMixmode == 1.)
      color.rgb = 1. - (1. - color.rgb) * (1. - colorbloom);
   else if (iBloomMixmode == 2.)
      color.rgb = max(vec3(0.0), max(color.rgb, mix(color.rgb, (1. - (1. - saturate(colorbloom)) * (1. - saturate(colorbloom))), 1.0)));
   else if (iBloomMixmode == 3.)
      color.rgb = max(color.rgb, colorbloom);

   // Anamorphic flare
   if (bAnamFlareEnable)
   {
      vec3 anamflare = COMPAT_TEXTURE(SamplerBloom5, vTexCoord.xy * FIX).w * 2. * fAnamFlareColor;
      anamflare = max(anamflare, 0.0);
      color.rgb += pow(anamflare, vec3(1.0 / fAnamFlareCurve));
   }

   // Lens dirt
   if (bLensdirtEnable)
   {
      float lensdirtmult = dot(COMPAT_TEXTURE(SamplerBloom5, vTexCoord * FIX).rgb, vec3(0.333));
      vec3 dirttex = COMPAT_TEXTURE(Dirt, vTexCoord * FIX).rgb;
      vec3 lensdirt = dirttex * lensdirtmult * fLensdirtIntensity;

      lensdirt = mix(vec3(dot(lensdirt.xyz, vec3(0.333))), lensdirt.xyz, vec3(fLensdirtSaturation));

      if (iLensdirtMixmode == 0.)
         color.rgb += lensdirt;
      else if (iLensdirtMixmode == 1.)
         color.rgb = 1. - (1. - color.rgb) * (1. - lensdirt);
      else if (iLensdirtMixmode == 2.)
         color.rgb = max(vec3(0.0), max(color.rgb, mix(color.rgb, (1. - (1. - saturate(lensdirt)) * (1. - saturate(lensdirt))), 1.0)));
      else if (iLensdirtMixmode == 3.)
         color.rgb = max(color.rgb, lensdirt);
   }

   // Lens flares
   if (bAnamFlareEnable || bLenzEnable || bGodrayEnable || bChapFlareEnable)
   {
      vec3 lensflareSample = COMPAT_TEXTURE(LensFlare1, vTexCoord.xy * FIX).rgb, lensflareMask;
      lensflareMask  = COMPAT_TEXTURE(Sprite, vTexCoord + vec2( 0.5,  0.5) * PixelSize * FIX).rgb;
      lensflareMask += COMPAT_TEXTURE(Sprite, vTexCoord + vec2(-0.5,  0.5) * PixelSize * FIX).rgb;
      lensflareMask += COMPAT_TEXTURE(Sprite, vTexCoord + vec2( 0.5, -0.5) * PixelSize * FIX).rgb;
      lensflareMask += COMPAT_TEXTURE(Sprite, vTexCoord + vec2(-0.5, -0.5) * PixelSize * FIX).rgb;

      color.rgb += lensflareMask * 0.25 * lensflareSample;
   }
   FragColor = color;
} 
#endif
