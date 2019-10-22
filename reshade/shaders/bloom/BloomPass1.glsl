#version 150

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

#define SamplerBloom1 Texture
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

#define PixelSize (1.0 / TextureSize.xy)
#define BackBuffer OrigTexture

void main()
{
   vec4 bloom = vec4(0.0);

   const vec2 offset[8] = vec2[8](
      vec2(1.0, 1.0),
      vec2(0.0, -1.0),
      vec2(-1.0, 1.0),
      vec2(-1.0, -1.0),
      vec2(0.0, 1.0),
      vec2(0.0, -1.0),
      vec2(1.0, 0.0),
      vec2(-1.0, 0.0)
   );

   for (int i = 0; i < 8; i++)
   {
      vec2 bloomuv = offset[i] * PixelSize * 4.;
      bloomuv += vTexCoord;
      bloom += textureLod(SamplerBloom1, vec2(bloomuv), 0);
   }

   bloom *= 0.125;
   FragColor = bloom;
} 
#endif
