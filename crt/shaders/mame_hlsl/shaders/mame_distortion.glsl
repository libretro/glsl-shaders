#version 130

// license:BSD-3-Clause
// copyright-holders:ImJezze
//-----------------------------------------------------------------------------
// Distortion Effect
//-----------------------------------------------------------------------------

#define saturate(c) clamp(c, 0.0, 1.0)
#define mul(a,b) (b*a)
const int ScreenCount = 1;

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

const float Epsilon = 1.0e-7;
const float PI = 3.1415927;
const float E = 2.7182817;
const float Gelfond = 23.140692; // e^pi (Gelfond constant)
const float GelfondSchneider = 2.6651442; // 2^sqrt(2) (Gelfond-Schneider constant)

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

// www.dinodini.wordpress.com/2010/04/05/normalized-tunable-sigmoid-functions/
float normalizedSigmoid(float n, float k)
{
	// valid for n and k in range of -1.0 and 1.0
	return (n - n * k) / (k - abs(n) * 2.0 * k + 1);
}

// www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float roundBox(vec2 p, vec2 b, float r)
{
	return length(max(abs(p * InputSize / TextureSize) - b + r, 0.0)) - r;

}

#define DiffuseSampler Source

float DistortionAmount = distortion_amount;      // k     - quartic distortion coefficient
float CubicDistortionAmount = cubic_distortion_amount; // kcube - cubic distortion modifier
float DistortCornerAmount = distort_corner_amount;
float RoundCornerAmount = round_corner_amount;
float SmoothBorderAmount = smooth_border_amount;
float VignettingAmount = vignette_amount;
float ReflectionAmount = reflection_amount;
vec3 LightReflectionColor = vec3(reflection_col_r, reflection_col_g, reflection_col_b); // color temperature 5.000 Kelvin

vec2 QuadDims = OutputSize.xy * InputSize / TextureSize;
vec2 TargetDims = OutputSize.xy;
float TargetScale = 1.0;

vec2 ScreenScale = vec2(screenscale_x, screenscale_y);
vec2 ScreenOffset = vec2(screenoffset_x, screenoffset_y);
bool SwapXY = bool(swapxy);
const float vectorscreen = 0.0;
bool VectorScreen = bool(vectorscreen);

bool Distortion = bool(distortiontoggle);

float GetNoiseFactor(vec3 n, float random)
{
	// smaller n become more noisy
	return 1.0 + random * max(0.0, 0.25 * pow(E, -8 * n.x));
}

float GetVignetteFactor(vec2 coord, float amount)
{
	vec2 VignetteCoord = coord;

	float VignetteLength = length(VignetteCoord);
	float VignetteBlur = (amount * 0.75) + 0.25;

	// 0.5 full screen fitting circle
	float VignetteRadius = 1.0 - (amount * 0.25);
	float Vignette = smoothstep(VignetteRadius, VignetteRadius - VignetteBlur, VignetteLength);

	return saturate(Vignette);
}

float GetSpotAddend(vec2 coord, float amount)
{
	vec2 SpotCoord = coord;

	// upper right quadrant
	vec2 spotOffset = vec2(-0.25, 0.25);

	// normalized screen canvas ratio
	vec2 CanvasRatio = SwapXY 
		? vec2(1.0, QuadDims.x / QuadDims.y)
		: vec2(1.0, QuadDims.y / QuadDims.x);

	SpotCoord += spotOffset;
	SpotCoord *= CanvasRatio;

	float SpotBlur = amount;

	// 0.5 full screen fitting circle
	float SpotRadius = amount * 0.75;
	float Spot = smoothstep(SpotRadius, SpotRadius - SpotBlur, length(SpotCoord));

	float SigmoidSpot = amount * normalizedSigmoid(Spot, 0.75);

	// increase strength by 100%
	SigmoidSpot = SigmoidSpot * 2.0;

	return saturate(SigmoidSpot);
}

float GetBoundsFactor(vec2 coord, vec2 bounds, float radiusAmount, float smoothAmount)
{
coord = coord * TextureSize / InputSize;
	// reduce smooth amount down to radius amount
	smoothAmount = min(smoothAmount, radiusAmount);

	float range = min(bounds.x, bounds.y);
	float amountMinimum = 1.0 / range;
	float radius = range * max(radiusAmount, amountMinimum);
	float smooth_ = 1.0 / (range * max(smoothAmount, amountMinimum * 2.0));

	// compute box
	float box = roundBox(bounds * (coord * 2.0), bounds, radius);

	// apply smooth
	box *= smooth_;
	box += 1.0 - pow(smooth_ * 0.5, 0.5);

	float border = smoothstep(1.0, 0.0, box);

	return saturate(border);
}

// www.francois-tarlier.com/blog/cubic-lens-distortion-shader/
vec2 GetDistortedCoords(vec2 centerCoord, float amount, float amountCube)
{
centerCoord = centerCoord * TextureSize / InputSize;
	// lens distortion coefficient
	float k = amount;

	// cubic distortion value
	float kcube = amountCube;

	// compute cubic distortion factor
	float r2 = centerCoord.x * centerCoord.x + centerCoord.y * centerCoord.y;
	float f = kcube == 0.0
		? 1.0 + r2 * k
		: 1.0 + r2 * (k + kcube * sqrt(r2));

   	// fit screen bounds
	f /= 1.0 + amount * 0.25 + amountCube * 0.125;

	// apply cubic distortion factor
   	centerCoord *= f;

	return centerCoord * InputSize / TextureSize;
}

vec2 GetTextureCoords(vec2 coord, float distortionAmount, float cubicDistortionAmount)
{
coord = coord * TextureSize / InputSize;
	// center coordinates
	coord -= 0.5;

	// distort coordinates
	coord = GetDistortedCoords(coord, distortionAmount, cubicDistortionAmount);

	// un-center coordinates
	coord += 0.5;

	return coord * InputSize / TextureSize;
}

vec2 GetQuadCoords(vec2 coord, vec2 scale, float distortionAmount, float cubicDistortionAmount)
{
coord = coord * TextureSize / InputSize;
	// center coordinates
	coord -= 0.5;

	// apply scale
	coord *= scale;

	// distort coordinates
	coord = GetDistortedCoords(coord, distortionAmount, cubicDistortionAmount);

	return coord * InputSize / TextureSize;
}


void main()
{
vec2 vTexCoord = TEX0.xy;// * TextureSize / InputSize;
   if(!Distortion)
   {
      FragColor = texture(Source, vTexCoord);
      return;
   }
   else
   {
      // image distortion
      float distortionAmount = DistortionAmount;
      float cubicDistortionAmount = CubicDistortionAmount > 0.0
         ? CubicDistortionAmount * 1.1  // cubic distortion need to be a little higher to compensate the quartic distortion
         : CubicDistortionAmount * 1.2; // negativ values even more

      // corner distortion at least by the amount of the image distorition
      float distortCornerAmount = max(DistortCornerAmount, DistortionAmount + CubicDistortionAmount);

      float roundCornerAmount = RoundCornerAmount * 0.5;
      float smoothBorderAmount = SmoothBorderAmount * 0.5;

      vec2 TexelDims = 1.0 / TargetDims;

      // base-target dimensions (without oversampling)
      vec2 BaseTargetDims = TargetDims / TargetScale;
      BaseTargetDims = SwapXY
         ? BaseTargetDims.yx
         : BaseTargetDims.xy;

      // base-target/quad difference scale
      vec2 BaseTargetQuadScale = (ScreenCount == 1)
         ? BaseTargetDims / QuadDims // keeps the coords inside of the quad bounds of a single screen
         : vec2(1.0);

      // Screen Texture Curvature
      vec2 BaseCoord = GetTextureCoords(vTexCoord, distortionAmount, cubicDistortionAmount);

      // Screen Quad Curvature
      vec2 QuadCoord = GetQuadCoords(vTexCoord, BaseTargetQuadScale, distortCornerAmount, 0.0);
   /*
      // clip border
      if (BaseCoord.x < 0.0 - TexelDims.x || BaseCoord.y < 0.0 - TexelDims.y ||
         BaseCoord.x > 1.0 + TexelDims.x || BaseCoord.y > 1.0 + TexelDims.y)
      {
         // we don't use the clip function, because we don't clear the render target before
         return vec4(0.0, 0.0, 0.0, 1.0);
      }
   */

      // Color
      vec4 BaseColor = COMPAT_TEXTURE(DiffuseSampler, BaseCoord);
      BaseColor.a = 1.0;

      // Vignetting Simulation
      vec2 VignetteCoord = QuadCoord;

      float VignetteFactor = GetVignetteFactor(VignetteCoord, VignettingAmount);
      BaseColor.rgb *= VignetteFactor;

      // Light Reflection Simulation
      vec2 SpotCoord = QuadCoord;

      vec3 SpotAddend = GetSpotAddend(SpotCoord, ReflectionAmount) * LightReflectionColor;
      BaseColor.rgb += SpotAddend * GetNoiseFactor(SpotAddend, random(SpotCoord));

      // Round Corners Simulation
      vec2 RoundCornerCoord = QuadCoord;
      vec2 RoundCornerBounds = (ScreenCount == 1)
         ? QuadDims // align corners to quad bounds of a single screen
         : BaseTargetDims; // align corners to target bounds of multiple screens
      RoundCornerBounds = SwapXY
         ? RoundCornerBounds.yx
         : RoundCornerBounds.xy;

      float roundCornerFactor = GetBoundsFactor(RoundCornerCoord, RoundCornerBounds, roundCornerAmount, smoothBorderAmount);
      BaseColor.rgb *= roundCornerFactor;

      FragColor = BaseColor;
   }
} 
#endif
