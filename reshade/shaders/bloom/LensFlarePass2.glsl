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
   TEX0.xy = TexCoord.xy * 1.0001;
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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

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

vec4 GaussBlur22(vec2 coord, sampler2D tex, float mult, float lodlevel, bool isBlurVert)
{
   vec4 sum = vec4(0.);
   vec2 axis = isBlurVert ? vec2(0., 1.) : vec2(1., 0.);

   const float weight[11] = float[11](
      0.082607,
      0.080977,
      0.076276,
      0.069041,
      0.060049,
      0.050187,
      0.040306,
      0.031105,
      0.023066,
      0.016436,
      0.011254
   );

   for (int i = -10; i < 11; i++)
   {
      float currweight = weight[abs(i)];
      sum += textureLod(tex, vec2(coord.xy + axis.xy * float(i) * PixelSize * mult), lodlevel) * currweight;
   }

   return sum;
}

void main()
{
   FragColor = GaussBlur22(vTexCoord, Source, 2., 0., false);
} 
#endif
