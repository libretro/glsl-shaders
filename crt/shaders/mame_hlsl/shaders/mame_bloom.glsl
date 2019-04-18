#version 130

// needs version 130 for textureLod

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Bloom Effect
//-----------------------------------------------------------------------------

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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
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

// effect toggles and multi
uniform COMPAT_PRECISION float bloomtoggle, ntscsignal, scanlinetoggle, chromatoggle,
   distortiontoggle, screenscale_x, screenscale_y, screenoffset_x, screenoffset_y, swapxy;
// bloom params
uniform COMPAT_PRECISION float bloomblendmode, bloomscale, bloomoverdrive_r, bloomoverdrive_g, bloomoverdrive_b,
   level0weight, level1weight, level2weight, level3weight, level4weight, level5weight, level6weight, level7weight, level8weight;
//	uniform COMPAT_PRECISION float vectorscreen; // unused
// post params
uniform COMPAT_PRECISION float mask_width, mask_height, mask_offset_x, mask_offset_y, preparebloom, shadowtilemode,
   power_r, power_g, power_b, floor_r, floor_g, floor_b, chromamode, conversiongain_x, conversiongain_y, conversiongain_z,
   humbaralpha, backcolor_r, backcolor_g, backcolor_b, shadowalpha, shadowcount_x, shadowcount_y, shadowuv_x, shadowuv_y;
// ntsc params // doesn't work here, so commenting all of them.
// uniform COMPAT_PRECISION float avalue, bvalue, ccvalue, ovalue, pvalue, scantime, notchhalfwidth, yfreqresponse, ifreqresponse, qfreqresponse, signaloffset;
// color params
uniform COMPAT_PRECISION float col_red, col_grn, col_blu, col_offset_x, col_offset_y, col_offset_z, col_scale_x,
   col_scale_y, col_scale_z, col_saturation;
// deconverge params
uniform COMPAT_PRECISION float converge_x_r, converge_x_g, converge_x_b, converge_y_r, converge_y_g, converge_y_b,
   radial_conv_x_r, radial_conv_x_g, radial_conv_x_b, radial_conv_y_r, radial_conv_y_g, radial_conv_y_b;
// scanline params
uniform COMPAT_PRECISION float scanlinealpha, scanlinescale, scanlineheight, scanlinevariation, scanlineoffset,
   scanlinebrightscale, scanlinebrightoffset;
// defocus params
uniform COMPAT_PRECISION float defocus_x, defocus_y;
// phosphor params
uniform COMPAT_PRECISION float deltatime, phosphor_r, phosphor_g, phosphor_b, phosphortoggle;
// chroma params
uniform COMPAT_PRECISION float ygain_r, ygain_g, ygain_b, chromaa_x, chromaa_y, chromab_x, chromab_y, chromac_x, chromac_y;
// distortion params
uniform COMPAT_PRECISION float distortion_amount, cubic_distortion_amount, distort_corner_amount, round_corner_amount,
   smooth_border_amount, vignette_amount, reflection_amount, reflection_col_r, reflection_col_g, reflection_col_b;
// vector params //doesn't work here, so commenting all of them.
// uniform COMPAT_PRECISION float timeratio, timescale, lengthratio, lengthscale, beamsmooth;
// I'm not going to bother supporting implementations without runtime parameters.

const float vectorscreen = 0.0;
bool VectorScreen = bool(vectorscreen);

bool BloomToggle = bool(bloomtoggle);

float Level0Weight = level0weight;
float Level1Weight = level1weight;
float Level2Weight = level2weight;
float Level3Weight = level3weight;
float Level4Weight = level4weight;
float Level5Weight = level5weight;
float Level6Weight = level6weight;
float Level7Weight = level7weight;
float Level8Weight = level8weight;

int BloomBlendMode = int(bloomblendmode); // 0 brighten, 1 darken
float BloomScale = bloomscale;
vec3 BloomOverdrive = vec3(bloomoverdrive_r, bloomoverdrive_g, bloomoverdrive_b);

//-----------------------------------------------------------------------------
// Constants
//-----------------------------------------------------------------------------

const float E = 2.7182817f;
const float Gelfond = 23.140692f; // e^pi (Gelfond constant)
const float GelfondSchneider = 2.6651442f; // 2^sqrt(2) (Gelfond-Schneider constant)

//-----------------------------------------------------------------------------
// Functions
//-----------------------------------------------------------------------------

// www.stackoverflow.com/questions/5149544/can-i-generate-a-random-number-inside-a-pixel-shader/
float random(vec2 seed)
{
	// irrationals for pseudo randomness
	vec2 i = vec2(Gelfond, GelfondSchneider);

	return fract(cos(dot(seed, i)) * 123456.0);
}

//-----------------------------------------------------------------------------
// Bloom Vertex Shader
//-----------------------------------------------------------------------------

#define DiffuseSampler Source
#define BloomCoord vTexCoord

#define BloomSamplerA Source
#define BloomSamplerB Source
#define BloomSamplerC Source
#define BloomSamplerD Source
#define BloomSamplerE Source
#define BloomSamplerF Source
#define BloomSamplerG Source
#define BloomSamplerH Source

// vector screen uses twice -1 as many bloom levels
#define BloomSamplerI Source
#define BloomSamplerJ Source
#define BloomSamplerK Source
#define BloomSamplerL Source
#define BloomSamplerM Source
#define BloomSamplerN Source
#define BloomSamplerO Source

vec3 GetNoiseFactor(vec3 n, float random)
{
	// smaller n become more noisy
	vec3 NoiseFactor;
	NoiseFactor.x = 1.0 + random * max(0.0, 0.25 * pow(E, -8. * n.x));
	NoiseFactor.y = 1.0 + random * max(0.0, 0.25 * pow(E, -8. * n.y));
	NoiseFactor.z = 1.0 + random * max(0.0, 0.25 * pow(E, -8. * n.z));
	return NoiseFactor;
}

void main()
{
   if(!BloomToggle)
   {
      FragColor = COMPAT_TEXTURE(Source, vTexCoord);
      return;
   }
   else
   {
      vec3 texel = COMPAT_TEXTURE(DiffuseSampler, vTexCoord).rgb;
      // use mipmapping for cheap bloom
      vec3 texelA = textureLod(BloomSamplerA, BloomCoord.xy, 1.0).rgb;
      vec3 texelB = textureLod(BloomSamplerB, BloomCoord.xy, 2.0).rgb;
      vec3 texelC = textureLod(BloomSamplerC, BloomCoord.xy, 3.0).rgb;
      vec3 texelD = textureLod(BloomSamplerD, BloomCoord.xy, 4.0).rgb;
      vec3 texelE = textureLod(BloomSamplerE, BloomCoord.xy, 5.0).rgb;
      vec3 texelF = textureLod(BloomSamplerF, BloomCoord.xy, 6.0).rgb;
      vec3 texelG = textureLod(BloomSamplerG, BloomCoord.xy, 7.0).rgb;
      vec3 texelH = textureLod(BloomSamplerH, BloomCoord.xy, 8.0).rgb;

      vec3 texelI = vec3(0.0, 0.0, 0.0);
      vec3 texelJ = vec3(0.0, 0.0, 0.0);
      vec3 texelK = vec3(0.0, 0.0, 0.0);
      vec3 texelL = vec3(0.0, 0.0, 0.0);
      vec3 texelM = vec3(0.0, 0.0, 0.0);
      vec3 texelN = vec3(0.0, 0.0, 0.0);
      vec3 texelO = vec3(0.0, 0.0, 0.0);


      // vector screen uses twice -1 as many bloom levels
      if (VectorScreen)
      {
         texelI = COMPAT_TEXTURE(BloomSamplerI, BloomCoord.xy).rgb;
         texelJ = COMPAT_TEXTURE(BloomSamplerJ, BloomCoord.xy).rgb;
         texelK = COMPAT_TEXTURE(BloomSamplerK, BloomCoord.xy).rgb;
         texelL = COMPAT_TEXTURE(BloomSamplerL, BloomCoord.xy).rgb;
         texelM = COMPAT_TEXTURE(BloomSamplerM, BloomCoord.xy).rgb;
         texelN = COMPAT_TEXTURE(BloomSamplerN, BloomCoord.xy).rgb;
         texelO = COMPAT_TEXTURE(BloomSamplerO, BloomCoord.xy).rgb;
      }

      vec3 blend;

      // brighten
      if (BloomBlendMode < 0.5)
      {
         vec3 bloom = vec3(0.0, 0.0, 0.0);

         texel *= Level0Weight;

         if (VectorScreen)
         {
            bloom += texelA * Level1Weight;
            bloom += texelB * Level2Weight;
            bloom += texelC * Level3Weight;
            bloom += texelD * Level4Weight;
            bloom += texelE * Level5Weight;
            bloom += texelF * Level6Weight;
            bloom += texelG * Level7Weight;
            bloom += texelH * Level8Weight;
         }
         // vector screen uses twice -1 as many bloom levels
         else
         {
            bloom += texelA * (Level1Weight);
            bloom += texelB * (Level1Weight + Level2Weight) * 0.5;
            bloom += texelC * (Level2Weight);
            bloom += texelD * (Level2Weight + Level3Weight) * 0.5;
            bloom += texelE * (Level3Weight);
            bloom += texelF * (Level3Weight + Level4Weight) * 0.5;
            bloom += texelG * (Level4Weight);
            bloom += texelH * (Level4Weight + Level5Weight) * 0.5;
            bloom += texelI * (Level5Weight);
            bloom += texelJ * (Level5Weight + Level6Weight) * 0.5;
            bloom += texelK * (Level6Weight);
            bloom += texelL * (Level6Weight + Level7Weight) * 0.5;
            bloom += texelM * (Level7Weight);
            bloom += texelN * (Level7Weight + Level8Weight) * 0.5;
            bloom += texelO * (Level8Weight);
         }

         bloom *= BloomScale;

         vec3 bloomOverdrive;
         bloomOverdrive.r = max(0.0, texel.r + bloom.r - 1.0) * BloomOverdrive.r;
         bloomOverdrive.g = max(0.0, texel.g + bloom.g - 1.0) * BloomOverdrive.g;
         bloomOverdrive.b = max(0.0, texel.b + bloom.b - 1.0) * BloomOverdrive.b;

         bloom.r += bloomOverdrive.g * 0.5;
         bloom.r += bloomOverdrive.b * 0.5;
         bloom.g += bloomOverdrive.r * 0.5;
         bloom.g += bloomOverdrive.b * 0.5;
         bloom.b += bloomOverdrive.r * 0.5;
         bloom.b += bloomOverdrive.g * 0.5;

         vec2 NoiseCoord = vTexCoord;
         vec3 NoiseFactor = GetNoiseFactor(bloom, random(NoiseCoord));

         blend = texel + bloom * NoiseFactor;
      }

      // darken
      else
      {
         texelA = min(texel, texelA);
         texelB = min(texel, texelB);
         texelC = min(texel, texelC);
         texelD = min(texel, texelD);
         texelE = min(texel, texelE);
         texelF = min(texel, texelF);
         texelG = min(texel, texelG);
         texelH = min(texel, texelH);

         blend = texel * Level0Weight;
         blend = mix(blend, texelA, Level1Weight * BloomScale);
         blend = mix(blend, texelB, Level2Weight * BloomScale);
         blend = mix(blend, texelC, Level3Weight * BloomScale);
         blend = mix(blend, texelD, Level4Weight * BloomScale);
         blend = mix(blend, texelE, Level5Weight * BloomScale);
         blend = mix(blend, texelF, Level6Weight * BloomScale);
         blend = mix(blend, texelG, Level7Weight * BloomScale);
         blend = mix(blend, texelH, Level8Weight * BloomScale);
      }

       FragColor = vec4(blend, 1.0);
   }
} 
#endif
