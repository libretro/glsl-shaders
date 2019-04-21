#version 130

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Scanline Effect
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
uniform COMPAT_PRECISION vec2 OrigTextureSize;
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

//-----------------------------------------------------------------------------
// Constants
//-----------------------------------------------------------------------------

const float PI = 3.1415927;
const float HalfPI = PI * 0.5;

//-----------------------------------------------------------------------------
// Scanline Pixel Shader
//-----------------------------------------------------------------------------

float ScanlineAlpha = scanlinealpha;
float ScanlineScale = scanlinescale;
float ScanlineHeight = scanlineheight;
float ScanlineVariation = scanlinevariation;
float ScanlineOffset = scanlineoffset;
float ScanlineBrightScale = scanlinebrightscale;
float ScanlineBrightOffset = scanlinebrightoffset;

vec2 QuadDims = OutputSize.xy;
vec2 SourceDims = OrigTextureSize.xy;

vec2 ScreenScale = vec2(screenscale_x, screenscale_y);
vec2 ScreenOffset = vec2(screenoffset_x, screenoffset_y);
bool SwapXY = bool(swapxy);

bool ScanlineToggle = bool(scanlinetoggle);

vec2 GetAdjustedCoords(vec2 coord)
{
	// center coordinates
	coord -= 0.5;

	// apply screen scale
	coord *= ScreenScale;

	// un-center coordinates
	coord += 0.5;

	// apply screen offset
	coord += ScreenOffset;

	return coord;
}

#define DiffuseSampler Source

void main()
{
   if(!ScanlineToggle)
   {
      FragColor = COMPAT_TEXTURE(Source, vTexCoord);
      return;
   }
   else
   {
      vec2 BaseCoord = GetAdjustedCoords(vTexCoord);

      // Color
      vec4 BaseColor = COMPAT_TEXTURE(DiffuseSampler, BaseCoord);
      BaseColor.a = 1.0;
/*
      // clip border
      if (BaseCoord.x < 0.0 || BaseCoord.y < 0.0 ||
      BaseCoord.x > 1.0 || BaseCoord.y > 1.0)
      {
         // we don't use the clip function, because we don't clear the render target before
         return vec4(0.0, 0.0, 0.0, 1.0);
      }
*/
      float BrightnessOffset = (ScanlineBrightOffset * ScanlineAlpha);
      float BrightnessScale = (ScanlineBrightScale * ScanlineAlpha) + (1.0 - ScanlineAlpha);

      float ColorBrightness = 0.299 * BaseColor.r + 0.587 * BaseColor.g + 0.114 * BaseColor.b;

      float ScanlineCoord = BaseCoord.y;
      ScanlineCoord += (SwapXY)
         ? QuadDims.x <= SourceDims.x * 2.0
            ? 0.5 / QuadDims.x // uncenter scanlines if the quad is less than twice the size of the source
               : 0.0
               : QuadDims.y <= SourceDims.y * 2.0
            ? 0.5 / QuadDims.y // uncenter scanlines if the quad is less than twice the size of the source
               : 0.0;
      ScanlineCoord *= SourceDims.y * ScanlineScale * PI;

      float ScanlineCoordJitter = ScanlineOffset * HalfPI;
      float ScanlineSine = sin(ScanlineCoord + ScanlineCoordJitter);
      float ScanlineWide = ScanlineHeight + ScanlineVariation * max(1.0f, ScanlineHeight) * (1.0 - ColorBrightness);
      float ScanlineAmount = pow(ScanlineSine * ScanlineSine, ScanlineWide);
      float ScanlineBrightness = ScanlineAmount * BrightnessScale + BrightnessOffset * BrightnessScale;

      BaseColor.rgb *= mix(1.0, ScanlineBrightness, ScanlineAlpha);

      FragColor = BaseColor;
   }
} 
#endif
