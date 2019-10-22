#version 130

// Bloom - from ReShade
// Copyright (c) 2009-2015 Gilcher Pascal aka Marty McFly
// ported by hunterk

#pragma parameter bLensdirtEnable_toggle "Lens Dirt Enable" 0.0 0.0 1.0 1.0
#pragma parameter bAnamFlareEnable_toggle "Anam Flare Enable" 0.0 0.0 1.0 1.0
#pragma parameter bLenzEnable_toggle "Lenz Enable" 0.0 0.0 1.0 1.0
#pragma parameter bChapFlareEnable_toggle "Chap Flare Enable" 0.0 0.0 1.0 1.0
#pragma parameter bGodrayEnable_toggle "Godray Enable" 0.0 0.0 1.0 1.0

#pragma parameter iBloomMixmode "Bloom Mix Mode" 0.0 0.0 2.0 1.0
//Linear add\0Screen add\0Screen/Lighten/Opacity\0Lighten\0
#pragma parameter fBloomThreshold "Bloom Threshold" 0.8 0.1 1.0 0.1
//Every pixel brighter than this value triggers bloom.
#pragma parameter fBloomAmount "Bloom Amount" 0.8 0.0 20.0 0.1
//Intensity of bloom.
#pragma parameter fBloomSaturation "Bloom Saturation" 0.8 0.0 2.0 0.1
//Bloom saturation. 0.0 means white bloom, 2.0 means very, very colorful bloom.
#pragma parameter fBloomTint_r "Bloom Tint R" 0.7 0.0 1.0 0.05
#pragma parameter fBloomTint_g "Bloom Tint G" 0.8 0.0 1.0 0.05
#pragma parameter fBloomTint_b "Bloom Tint B" 1.0 0.0 1.0 0.05
//R, G and B components of bloom tint the bloom color gets shifted to.
#pragma parameter iLensdirtMixmode "Lens Dirt Mix Mode" 0.0 0.0 3.0 1.0
//Linear add\0Screen add\0Screen/Lighten/Opacity\0Lighten\0
#pragma parameter fLensdirtIntensity "Lens Dirt Intensity" 0.4 0.0 2.0 0.1
//Intensity of lensdirt.
#pragma parameter fLensdirtSaturation "Lens Dirt Saturation" 2.0 0.0 2.0 0.1
//Color saturation of lensdirt.
#pragma parameter fLensdirtTint_r "Lens Dirt Tint R" 1.0 0.0 1.0 0.05
#pragma parameter fLensdirtTint_g "Lens Dirt Tint G" 1.0 0.0 1.0 0.05
#pragma parameter fLensdirtTint_b "Lens Dirt Tint B" 1.0 0.0 1.0 0.05
//R, G and B components of lensdirt tint the lensdirt color gets shifted to.
#pragma parameter fAnamFlareThreshold "Anam Flare Threshold" 0.9 0.1 1.0 0.1
//Every pixel brighter than this value gets a flare.
#pragma parameter fAnamFlareWideness "Anam Flare Width" 2.4 1.0 2.5 0.1
//Horizontal wideness of flare. Don't set too high, otherwise the single samples are visible.
#pragma parameter fAnamFlareAmount "Anam Flare Amt" 14.5 1.0 20.0 0.5
//Intensity of anamorphic flare.
#pragma parameter fAnamFlareCurve "Anam Flare Curve" 1.2 1.0 2.0 0.1
//Intensity curve of flare with distance from source.
#pragma parameter fAnamFlareColor_r "Anam Flare Col R" 0.012 0.0 1.0 0.01
#pragma parameter fAnamFlareColor_g "Anam Flare Col G" 0.313 0.0 1.0 0.01
#pragma parameter fAnamFlareColor_b "Anam Flare Col B" 0.588 0.0 1.0 0.01
//R, G and B components of anamorphic flare. Flare is always same color.
#pragma parameter fLenzIntensity "Lenz Intensity" 1.0 0.2 3.0 0.1
//Power of lens flare effect
#pragma parameter fLenzThreshold "Lenz Threshold" 0.8 0.6 1.0 0.1
//Minimum brightness an object must have to cast lensflare.
#pragma parameter fChapFlareThreshold "Chap Flare Threshold" 0.9 0.7 0.99 0.05
//Brightness threshold for lensflare generation. Everything brighter than this value gets a flare.
#pragma parameter iChapFlareCount "Chap Flare Count" 15.0 1.0 20.0 1.0
//Number of single halos to be generated. If set to 0, only the curved halo around is visible.
#pragma parameter fChapFlareDispersal "Chap Flare Dispersal" 0.25 0.25 1.0 0.05
//Distance from screen center (and from themselves) the flares are generated.
#pragma parameter fChapFlareSize "Chap Flare Size" 0.45 0.2 0.8 0.05
//Distance (from screen center) the halo and flares are generated.
#pragma parameter fChapFlareCA_r "Chap Flare CA R" 0.0 0.0 1.0 0.01
#pragma parameter fChapFlareCA_g "Chap Flare CA G" 0.01 0.0 1.0 0.01
#pragma parameter fChapFlareCA_b "Chap Flare CA B" 0.02 0.0 1.0 0.01
//Offset of RGB components of flares as modifier for Chromatic abberation. Same 3 values means no CA.
#pragma parameter fChapFlareIntensity "Chap Flare Intensity" 100.0 5.0 200.0 5.0
//Intensity of flares and halo, remember that higher threshold lowers intensity, you might play with both values to get desired result.
#pragma parameter fGodrayDecay "Godray Decay" 0.99 0.5 0.9999 0.05
//How fast they decay. It's logarithmic, 1.0 means infinite long rays which will cover whole screen
#pragma parameter fGodrayExposure "Godray Exposure" 1.0 0.7 1.5 0.05
//Upscales the godray's brightness
#pragma parameter fGodrayWeight "Godray Weight" 1.25 0.8 1.7 0.05
//weighting
#pragma parameter fGodrayDensity "Godray Density" 1.0 0.2 2.0 0.2
//Density of rays, higher means more and brighter rays
#pragma parameter fGodrayThreshold "Godray Threshold" 0.9 0.6 1.0 0.05
//Minimum brightness an object must have to cast godrays
#pragma parameter iGodraySamples "Godray Samples" 128.0 16.0 256.0 16.0
//2^x format values; How many samples the godrays get
#pragma parameter fFlareLuminance "Flare Luminance" 0.095 0.0 1.0 0.005
//bright pass luminance value
#pragma parameter fFlareBlur "Flare Blur" 200.0 1.0 10000.0 50.0
//manages the size of the flare
#pragma parameter fFlareIntensity "Flare Intensity" 2.07 0.2 5.0 0.1
//effect intensity
#pragma parameter fFlareTint_r "Flare Tint R" 0.137 0.0 1.0 0.05
#pragma parameter fFlareTint_g "Flare Tint G" 0.216 0.0 1.0 0.05
#pragma parameter fFlareTint_b "Flare Tint B" 1.0 0.0 1.0 0.05
//effect tint RGB

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
uniform sampler2D OrigTexture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

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

#define PixelSize (1.0 / TextureSize.xy)
#define BackBuffer Texture

void main()
{
   vec4 bloom = vec4(0.);
   vec4 tempbloom = vec4(0.);
   vec2 bloomuv = vec2(0.);

   const vec2 offset[4] = vec2[4](
      vec2(1.0, 1.0),
      vec2(1.0, 1.0),
      vec2(-1.0, 1.0),
      vec2(-1.0, -1.0)
   );

   for (int i = 0; i < 4; i++)
   {
      bloomuv = offset[i] * PixelSize * 2.;
      bloomuv += vTexCoord.xy;
      tempbloom = textureLod(BackBuffer, vec2(bloomuv.xy), 0.);
      tempbloom.w = max(0., dot(tempbloom.xyz, vec3(0.333)) - fAnamFlareThreshold);
      tempbloom.xyz = max(vec3(0.), tempbloom.xyz - vec3(fBloomThreshold)); 
      bloom += tempbloom;
   }

   bloom *= 0.25;
   FragColor = bloom;
} 
#endif
