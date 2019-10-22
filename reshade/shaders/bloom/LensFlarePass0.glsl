#version 130

#define FIX (InputSize / TextureSize)

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
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;
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

vec3 GetDnB(sampler2D tex, vec2 coords)
{
   vec3 color = vec3(max(0., dot(textureLod(tex, vec2(coords.xy), 4.).rgb, vec3(0.333)) - fChapFlareThreshold) * fChapFlareIntensity);
/* This isn't something RA has, so just comment it out
#if CHAPMAN_DEPTH_CHECK
   if (textureLod(ReShade::DepthBuffer, vec4(coords.xy, 0, 3)).x < 0.99999)
      color = 0;
#endif
*/
   return color;
}
vec3 GetDistortedTex(sampler2D tex, vec2 sample_center, vec2 sample_vector, vec3 distortion)
{
   vec2 final_vector = sample_center * (OrigTextureSize / OrigInputSize) + sample_vector * min(min(distortion.r, distortion.g), distortion.b);

   if (final_vector.x > 1.0 || final_vector.y > 1.0 || final_vector.x < -1.0 || final_vector.y < -1.0)
      return vec3(0., 0., 0.);
   else
      return vec3(
         GetDnB(tex, sample_center * (OrigTextureSize / OrigInputSize) + sample_vector * distortion.r).r,
         GetDnB(tex, sample_center * (OrigTextureSize / OrigInputSize) + sample_vector * distortion.g).g,
         GetDnB(tex, sample_center * (OrigTextureSize / OrigInputSize) + sample_vector * distortion.b).b);
}

vec3 GetBrightPass(vec2 coords)
{
   vec3 c = COMPAT_TEXTURE(BackBuffer, coords).rgb;
   vec3 bC = max(c - vec3(fFlareLuminance, fFlareLuminance, fFlareLuminance), 0.0);
   float bright = dot(bC, vec3(1.0));
   bright = smoothstep(0.0, 0.5, bright);
   vec3 result = mix(vec3(0.0), c, vec3(bright));
/* This isn't something RA has, so just comment it out
#if FLARE_DEPTH_CHECK
   float checkdepth = tex2D(ReShade::DepthBuffer, coords).x;
   if (checkdepth < 0.99999)
      result = 0;
#endif
*/
   return result;
}
vec3 GetAnamorphicSample(int axis, vec2 coords, float blur)
{
   coords = 2.0 * coords - 1.0;
   coords.x /= -blur;
   coords = 0.5 * coords + 0.5;
   return GetBrightPass(coords);
}

void main()
{
   vec4 lens = vec4(0.);

   // Lenz
   if (bLenzEnable)
   {
      const vec3 lfoffset[19] = vec3[19](
         vec3(0.9, 0.01, 4),
         vec3(0.7, 0.25, 25),
         vec3(0.3, 0.25, 15),
         vec3(1, 1.0, 5),
         vec3(-0.15, 20, 1),
         vec3(-0.3, 20, 1),
         vec3(6, 6, 6),
         vec3(7, 7, 7),
         vec3(8, 8, 8),
         vec3(9, 9, 9),
         vec3(0.24, 1, 10),
         vec3(0.32, 1, 10),
         vec3(0.4, 1, 10),
         vec3(0.5, -0.5, 2),
         vec3(2, 2, -5),
         vec3(-5, 0.2, 0.2),
         vec3(20, 0.5, 0),
         vec3(0.4, 1, 10),
         vec3(0.00001, 10, 20)
      );
      const vec3 lffactors[19] = vec3[19](
         vec3(1.5, 1.5, 0),
         vec3(0, 1.5, 0),
         vec3(0, 0, 1.5),
         vec3(0.2, 0.25, 0),
         vec3(0.15, 0, 0),
         vec3(0, 0, 0.15),
         vec3(1.4, 0, 0),
         vec3(1, 1, 0),
         vec3(0, 1, 0),
         vec3(0, 0, 1.4),
         vec3(1, 0.3, 0),
         vec3(1, 1, 0),
         vec3(0, 2, 4),
         vec3(0.2, 0.1, 0),
         vec3(0, 0, 1),
         vec3(1, 1, 0),
         vec3(1, 1, 0),
         vec3(0, 0, 0.2),
         vec3(0.012,0.313,0.588)
      );

      vec2 lfcoord = vec2(0.);
      vec3 lenstemp = vec3(0.);
      vec2 distfact = vTexCoord.xy - 0.5;
      distfact.x *= SourceSize.x / SourceSize.y;

      for (int i = 0; i < 19; i++)
      {
         lfcoord.xy = lfoffset[i].x * distfact;
         lfcoord.xy *= pow(2.0 * length(distfact), lfoffset[i].y * 3.5);
         lfcoord.xy *= lfoffset[i].z;
         lfcoord.xy = 0.5 - lfcoord.xy;
         vec2 tempfact = (lfcoord.xy - 0.5) * 2.;
         float templensmult = clamp(1.0 - dot(tempfact, tempfact), 0., 1.);
         vec3 lenstemp1 = vec3(dot(textureLod(BackBuffer, vec2(lfcoord.xy) / (OrigTextureSize / OrigInputSize), 1.0).rgb, vec3(0.333)));
/* Doesn't exist in RetroArch, so comment it out
#if LENZ_DEPTH_CHECK
         float templensdepth = COMPAT_TEXTURE(ReShade::DepthBuffer, lfcoord.xy).x;
         if (templensdepth < 0.99999)
            lenstemp1 = 0;
#endif
*/
         lenstemp1 = max(vec3(0.), lenstemp1.xyz - vec3(fLenzThreshold));
         lenstemp1 *= lffactors[i] * templensmult;

         lenstemp += lenstemp1;
      }

      lens.rgb += lenstemp * fLenzIntensity;
   }

   // Chapman Lens
   if (bChapFlareEnable)
   {
      vec2 sample_vector = (vec2(0.5, 0.5) / FIX - vTexCoord.xy) * fChapFlareDispersal * FIX;
      vec2 halo_vector = normalize(sample_vector) * fChapFlareSize;

      vec3 chaplens = GetDistortedTex(BackBuffer, vTexCoord.xy + halo_vector, halo_vector, fChapFlareCA * 2.5).rgb;

      for (int j = 0; j < int(iChapFlareCount); ++j)
      {
         vec2 foffset = sample_vector * float(j);
         chaplens += GetDistortedTex(BackBuffer, vTexCoord.xy + foffset, foffset, fChapFlareCA).rgb;
      }

      chaplens *= 1.0 / iChapFlareCount;
      lens.xyz += chaplens;
   }

   // Godrays
   if (bGodrayEnable)
   {
      vec2 ScreenLightPos = vec2(0.5, 0.5);
      vec2 texcoord2 = vTexCoord * FIX;
      vec2 deltaTexCoord = (texcoord2 - ScreenLightPos);
      deltaTexCoord *= 1.0 / iGodraySamples * fGodrayDensity;

      float illuminationDecay = 1.0;

      for (int g = 0; g < int(iGodraySamples); g++)
      {
         texcoord2 -= deltaTexCoord;
         vec4 sample2 = textureLod(BackBuffer, vec2(texcoord2), 0.);
//         float sampledepth = textureLod(BackBuffer, vec2(texcoord2), 0.).x; //no depth checking in RA so just comment it out
         sample2.w = clamp(dot(sample2.xyz, vec3(0.3333)) - fGodrayThreshold, 0., 1.);
         sample2.r *= 1.00;
         sample2.g *= 0.95;
         sample2.b *= 0.85;
         sample2 *= illuminationDecay * fGodrayWeight;
#if GODRAY_DEPTH_CHECK == 1
         if (sampledepth > 0.99999)
            lens.rgb += sample2.xyz * sample2.w;
#else
         lens.rgb += sample2.xyz * sample2.w;
#endif
         illuminationDecay *= fGodrayDecay;
      }
   }

   // Anamorphic flare
   if (bAnamFlareEnable)
   {
      vec3 anamFlare = vec3(0.);
      const float gaussweight[5] = float[5](0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162);

      for (int z = -4; z < 5; z++)
      {
         anamFlare += GetAnamorphicSample(0, vTexCoord.xy * FIX + vec2(0, z * PixelSize.y * 2.), fFlareBlur) * fFlareTint * gaussweight[abs(z)];
      }

      lens.xyz += anamFlare * fFlareIntensity;
   }
   FragColor = lens;
} 
#endif
