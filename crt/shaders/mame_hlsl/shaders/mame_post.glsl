#version 130

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Shadowmask Effect
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
uniform sampler2D MaskTexture;
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

vec2 ScreenScale = vec2(screenscale_x, screenscale_y);
vec2 ScreenOffset = vec2(screenoffset_x, screenoffset_y);
bool SwapXY = bool(swapxy);
const float vectorscreen = 0.0;
bool VectorScreen = bool(vectorscreen);

#define DiffuseSampler Source
#define ShadowSampler MaskTexture

#define TargetDims OutputSize.xy
#define SourceDims OrigTextureSize.xy
float TargetScale = 1.0;//max(TargetDims.x / SourceDims.x, TargetDims.y / SourceDims.y);

float HumBarAlpha = humbaralpha;
float TimeMilliseconds = float(mod(FrameCount, 1000)) * 3.; // multiplier used to get humbar up to speed
vec3 BackColor = vec3(backcolor_r, backcolor_g, backcolor_b);
int ShadowTileMode = int(shadowtilemode); // 0 based on screen (quad) dimension, 1 based on source dimension
float ShadowAlpha = shadowalpha;
vec2 ShadowCount = vec2(shadowcount_x, shadowcount_y);
vec2 ShadowUV = vec2(shadowuv_x, shadowuv_y);
vec2 ShadowDims = vec2(mask_width, mask_height);
vec2 ShadowUVOffset = vec2(mask_offset_x, mask_offset_y);
int ChromaMode = int(chromamode);
vec3 ConversionGain = vec3(conversiongain_x, conversiongain_y, conversiongain_z);
vec3 Power = vec3(power_r, power_g, power_b);
vec3 Floor = vec3(floor_r, floor_g, floor_b);
bool PrepareBloom = bool(preparebloom);

#define MONOCHROME 1
#define DICHROME 2
#define TRICHROME 3

//-----------------------------------------------------------------------------
// Constants
//-----------------------------------------------------------------------------

const float PI = 3.1415927;
const float HalfPI = PI * 0.5;

float HumBarDesync = 60.0 / 59.94 - 1.0; // difference between the 59.94 Hz field rate and 60 Hz line frequency (NTSC)

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

vec2 GetShadowCoord(vec2 TargetCoord, vec2 SourceCoord)
{
	// base-target dimensions (without oversampling)
	vec2 BaseTargetDims = TargetDims / TargetScale;
	BaseTargetDims = SwapXY
		? BaseTargetDims.yx
		: BaseTargetDims.xy;

	vec2 canvasCoord = ShadowTileMode == 0
		? TargetCoord + ShadowUVOffset / BaseTargetDims
		: SourceCoord + ShadowUVOffset / SourceDims;
	vec2 canvasTexelDims = ShadowTileMode == 0
		? 1.0 / BaseTargetDims
		: 1.0 / SourceDims;

	vec2 shadowDims = ShadowDims;
	vec2 shadowUV = ShadowUV;
	vec2 shadowCount = ShadowCount;

	// swap x/y in screen mode (not source mode)
	canvasCoord = ShadowTileMode == 0 && SwapXY
		? canvasCoord.yx
		: canvasCoord.xy;

	// swap x/y in screen mode (not source mode)
	shadowCount = ShadowTileMode == 0 && SwapXY
		? shadowCount.yx
		: shadowCount.xy;

	vec2 shadowTile = canvasTexelDims * shadowCount;

	vec2 shadowFrac = fract(canvasCoord / shadowTile);

	// swap x/y in screen mode (not source mode)
	shadowFrac = ShadowTileMode == 0 && SwapXY
		? shadowFrac.yx
		: shadowFrac.xy;

	vec2 shadowCoord = (shadowFrac * shadowUV);
	shadowCoord += ShadowTileMode == 0
		? vec2(0.5) * (vec2(1.0) / shadowDims) // fix half texel offset (DX9)
		: vec2(0.0);

	return shadowCoord;
}

void main()
{
	vec2 ScreenCoord = vTexCoord;
	vec2 BaseCoord = GetAdjustedCoords(ScreenCoord);

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
	// Color Compression (may not affect bloom)
	if (!PrepareBloom)
	{
		// increasing the floor of the signal without affecting the ceiling
		BaseColor.rgb = Floor + (1.0f - Floor) * BaseColor.rgb;
	}

	// Color Power (may affect bloom)
	BaseColor.r = pow(BaseColor.r, Power.r);
	BaseColor.g = pow(BaseColor.g, Power.g);
	BaseColor.b = pow(BaseColor.b, Power.b);

	// Hum Bar Simulation (may not affect vector screen)
	if (!PrepareBloom && !VectorScreen && HumBarAlpha > 0.0)
	{
		float HumBarStep = fract(TimeMilliseconds * HumBarDesync);
		float HumBarBrightness = 1.0 - fract((BaseCoord.y * TextureSize.y / InputSize.y) + HumBarStep) * HumBarAlpha;
		BaseColor.rgb *= HumBarBrightness;
	}

	// Mask Simulation (may not affect bloom)
	if (!PrepareBloom && ShadowAlpha > 0.0)
	{
		vec2 ShadowCoord = GetShadowCoord(ScreenCoord * TextureSize / InputSize, BaseCoord * TextureSize / InputSize) * TextureSize / InputSize;

		vec4 ShadowColor = COMPAT_TEXTURE(ShadowSampler, ShadowCoord);
		vec3 ShadowMaskColor = mix(vec3(1.0), ShadowColor.rgb, ShadowAlpha);
		float ShadowMaskClear = (1.0 - ShadowColor.a) * ShadowAlpha;

		// apply shadow mask color
		BaseColor.rgb *= ShadowMaskColor;
		// clear shadow mask by background color
		BaseColor.rgb = mix(BaseColor.rgb, BackColor, ShadowMaskClear);
	}

	// Preparation for phosphor color conversion
	if (ChromaMode == MONOCHROME) {
		BaseColor.r = dot(ConversionGain, BaseColor.rgb);
		BaseColor.gb = vec2(BaseColor.r, BaseColor.r);
	} else if (ChromaMode == DICHROME) {
		BaseColor.r = dot(ConversionGain.rg, BaseColor.rg);
		BaseColor.g = BaseColor.r;
	}

   FragColor = BaseColor;
} 
#endif
