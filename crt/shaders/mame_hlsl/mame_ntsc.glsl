// version directive if necessary

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// NTSC Effect
//-----------------------------------------------------------------------------

// Effect Toggles and Settings Used In Multiple Passes
#pragma parameter ntscsignal "NTSC Signal Mode" 0.0 0.0 1.0 1.01.0
#pragma parameter scanlinetoggle "Scanline Toggle" 1.0 0.0 1.0 1.0
#pragma parameter bloomtoggle "Bloom Enable" 0.0 0.0 1.0 1.0
#pragma parameter chromatoggle "Chromaticity Toggle" 0.0 0.0 1.0 1.0
#pragma parameter distortiontoggle "Distortion Toggle" 0.0 0.0 1.0 1.0
#pragma parameter phosphortoggle "Phosphor Toggle" 0.0 0.0 1.0 1.0
#pragma parameter screenscale_x "Screen Scale X" 1.0 0.5 3.0 0.01
#pragma parameter screenscale_y "Screen Scale Y" 1.0 0.5 3.0 0.01
//#pragma parameter vectorscreen "Vector Screen Mode" 0.0 0.0 1.0 1.0 // TODO/FIXME

#pragma parameter screenoffset_x "Screen Offset X" 0.0 -1.0 1.0 0.005
#pragma parameter screenoffset_y "Screen Offset Y" 0.0 -1.0 1.0 0.005
#pragma parameter swapxy "Swap X and Y" 0.0 0.0 1.0 1.0

// Bloom Pass
#pragma parameter bloomtoggle "Bloom Enable" 0.0 0.0 1.0 1.0
#pragma parameter bloomblendmode "Bloom Blend Mode" 0.0 0.0 1.0 1.0
#pragma parameter bloomscale "Bloom Scale" 0.06 0.0 1.0 0.01
#pragma parameter bloomoverdrive_r "Bloom Overdrive R" 1.0 0.0 1.0 0.01
#pragma parameter bloomoverdrive_g "Bloom Overdrive G" 1.0 0.0 1.0 0.01
#pragma parameter bloomoverdrive_b "Bloom Overdrive B" 1.0 0.0 1.0 0.01
#pragma parameter level0weight "Bloom Level 0 Weight" 1.0 0.0 1.0 0.01
#pragma parameter level1weight "Bloom Level 1 Weight" 0.64 0.0 1.0 0.01
#pragma parameter level2weight "Bloom Level 2 Weight" 0.32 0.0 1.0 0.01
#pragma parameter level3weight "Bloom Level 3 Weight" 0.16 0.0 1.0 0.01
#pragma parameter level4weight "Bloom Level 4 Weight" 0.08 0.0 1.0 0.01
#pragma parameter level5weight "Bloom Level 5 Weight" 0.06 0.0 1.0 0.01
#pragma parameter level6weight "Bloom Level 6 Weight" 0.04 0.0 1.0 0.01
#pragma parameter level7weight "Bloom Level 7 Weight" 0.02 0.0 1.0 0.01
#pragma parameter level8weight "Bloom Level 8 Weight" 0.01 0.0 1.0 0.01

// Post Pass
#pragma parameter humbaralpha "Hum Bar Alpha" 0.0 0.0 1.0 0.01
#pragma parameter backcolor_r "Back Color R" 0.0 0.0 1.0 0.01
#pragma parameter backcolor_g "Back Color G" 0.0 0.0 1.0 0.01
#pragma parameter backcolor_b "Back Color B" 0.0 0.0 1.0 0.01
#pragma parameter shadowtilemode "Mask Tiling Mode" 0.0 0.0 1.0 1.0
#pragma parameter shadowalpha "Mask Alpha" 0.3 0.0 1.0 0.01
#pragma parameter shadowcount_x "Mask Tile Size X" 6.0 1.0 32.0 1.0
#pragma parameter shadowcount_y "Mask Tile Size Y" 6.0 1.0 32.0 1.0
#pragma parameter shadowuv_x "Mask UV X" 0.25 0.0 1.0 0.01
#pragma parameter shadowuv_y "Mask UV Y" 0.25 0.0 1.0 0.01
#pragma parameter mask_width "Mask Texture Width" 32.0 0.0 256.0 16.0
#pragma parameter mask_height "Mask Texture Height" 32.0 0.0 256.0 16.0
#pragma parameter mask_offset_x "Mask Offset X" 0.0 -10.0 10.0 0.1
#pragma parameter mask_offset_y "Mask Offset Y" 0.0 -10.0 10.0 0.1
#pragma parameter chromamode "Chroma Mode" 3.0 1.0 3.0 1.0
#pragma parameter conversiongain_x "Conversion Gain X" 0.0 -5.0 5.0 0.5
#pragma parameter conversiongain_y "Conversion Gain Y" 0.0 -5.0 5.0 0.5
#pragma parameter conversiongain_z "Conversion Gain Z" 0.0 -5.0 5.0 0.5
#pragma parameter power_r "Color Power R" 1.0 1.0 10.0 1.0
#pragma parameter power_g "Color Power G" 1.0 1.0 10.0 1.0
#pragma parameter power_b "Color Power B" 1.0 1.0 10.0 1.0
#pragma parameter floor_r "Color Floor R" 0.0 0.0 1.0 0.01
#pragma parameter floor_g "Color Floor G" 0.0 0.0 1.0 0.01
#pragma parameter floor_b "Color Floor B" 0.0 0.0 1.0 0.01
#pragma parameter preparebloom "Prepare Bloom" 0.0 0.0 1.0 1.0

// NTSC Pass
#pragma parameter avalue "A Value" 0.5 0.0 1.0 0.01
#pragma parameter bvalue "B Value" 0.5 0.0 1.0 0.01
#pragma parameter ccvalue "CC Value" 3.5795454 0.0 5.0 0.1
#pragma parameter ovalue "O Value" 0.0 -2.0 2.0 0.1
#pragma parameter pvalue "P Value" 1.0 -2.0 3.0 0.1
#pragma parameter scantime "Scan Time" 52.6 0.0 100.0 1.0
#pragma parameter notchhalfwidth "Notch Half Width" 1.0 0.0 5.0 0.5
#pragma parameter yfreqresponse "Y Freq Response" 6.0 0.0 10.0 0.1
#pragma parameter ifreqresponse "I Freq Response" 1.2 0.0 10.0 0.1
#pragma parameter qfreqresponse "Q Freq Response" 0.6 0.0 10.0 0.1
#pragma parameter signaloffset "Signal Offset" 0.0 -5.0 5.0 0.01

// Color Pass
#pragma parameter col_red "Red Shift" 1.0 0.0 1.0 0.01
#pragma parameter col_grn "Green Shift" 1.0 0.0 1.0 0.01
#pragma parameter col_blu "Blue Shift" 1.0 0.0 1.0 0.01
#pragma parameter col_offset_x "Offset X" 0.0 0.0 1.0 0.01
#pragma parameter col_offset_y "Offset Y" 0.0 0.0 1.0 0.01
#pragma parameter col_offset_z "Offset Z" 0.0 0.0 1.0 0.01
#pragma parameter col_scale_x "Scale X" 1.0 0.0 1.0 0.01
#pragma parameter col_scale_y "Scale Y" 1.0 0.0 1.0 0.01
#pragma parameter col_scale_z "Scale Z" 1.0 0.0 1.0 0.01
#pragma parameter col_saturation "Saturation" 1.0 0.0 0.01

// Deconverge Pass
#pragma parameter converge_x_r "Convergence X Red" 0.0 -100.0 100.0 0.5
#pragma parameter converge_x_g "Convergence X Green" 0.0 -100.0 100.0 0.5
#pragma parameter converge_x_b "Convergence X Blue" 0.0 -100.0 100.0 0.5
#pragma parameter converge_y_r "Convergence Y Red" 0.0 -100.0 100.0 0.5
#pragma parameter converge_y_g "Convergence Y Green" 0.0 -100.0 100.0 0.5
#pragma parameter converge_y_b "Convergence Y Blue" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_x_r "Radial Conv X Red" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_x_g "Radial Conv X Green" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_x_b "Radial Conv X Blue" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_y_r "Radial Conv Y Red" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_y_g "Radial Conv Y Green" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_y_b "Radial Conv Y Blue" 0.0 -100.0 100.0 0.5

// Scanline Pass
#pragma parameter scanlinealpha "Scanline Alpha" 0.5 0.0 1.0 0.01
#pragma parameter scanlinescale "Scanline Scale" 5.0 1.0 5.0 1.0
#pragma parameter scanlineheight "Scanline Height" 1.0 0.0 2.0 0.1
#pragma parameter scanlinevariation "Scanline Variation" 1.0 0.0 5.0 0.5
#pragma parameter scanlineoffset "Scanline Offset" 1.0 -1.5 3.0 0.1
#pragma parameter scanlinebrightscale "Scanline Bright Scale" 1.0 0.0 2.0 0.1
#pragma parameter scanlinebrightoffset "Scanline Bright Offset" 1.0 -1.5 3.0 0.1

// Defocus Pass
#pragma parameter defocus_x "Defocus X Axis" 0.0 0.0 10.0 0.1
#pragma parameter defocus_y "Defocus Y Axis" 0.0 0.0 10.0 0.1

// Phosphor Pass
#pragma parameter deltatime "Delta Time" 1.0 0.0 2.0 0.1
#pragma parameter phosphor_r "Phosphor Red" 0.8 0.0 0.99 0.1
#pragma parameter phosphor_g "Phosphor Green" 0.0 0.0 0.99 0.1
#pragma parameter phosphor_b "Phosphor Blue" 0.0 0.0 0.99 0.1

// Chroma Pass
#pragma parameter ygain_r "Y Gain R Channel" 0.2126 0.0 1.0 0.01
#pragma parameter ygain_g "Y Gain G Channel" 0.7152 0.0 1.0 0.01
#pragma parameter ygain_b "Y Gain B Channel" 0.0722 0.0 1.0 0.01
#pragma parameter chromaa_x "Chroma A X" 0.630 0.0 1.0 0.01
#pragma parameter chromaa_y "Chroma A Y" 0.340 0.0 1.0 0.01
#pragma parameter chromab_x "Chroma B X" 0.310 0.0 1.0 0.01
#pragma parameter chromab_y "Chroma B Y" 0.595 0.0 1.0 0.01
#pragma parameter chromac_x "Chroma C X" 0.155 0.0 1.0 0.01
#pragma parameter chromac_y "Chroma C Y" 0.070 0.0 1.0 0.01

// Distortion Pass
#pragma parameter distortion_amount "Distortion Amount" 0.0 0.0 1.0 0.01
#pragma parameter cubic_distortion_amount "Cubic Dist. Amt" 0.0 0.0 1.0 0.01
#pragma parameter distort_corner_amount "Corner Dist. Amt" 0.0 0.0 1.0 0.01
#pragma parameter round_corner_amount "Corner Rounding" 0.0 0.0 1.0 0.01
#pragma parameter smooth_border_amount "Border Smoothing" 0.0 0.0 1.0 0.01
#pragma parameter vignette_amount "Vignetting Amount" 0.0 0.0 1.0 0.01
#pragma parameter reflection_amount "Reflection Amount" 0.0 0.0 1.0 0.01
#pragma parameter reflection_col_r "Reflection Color R" 1.0 0.0 1.0 0.01
#pragma parameter reflection_col_g "Reflection Color G" 0.9 0.0 1.0 0.01
#pragma parameter reflection_col_b "Reflection Color B" 0.8 0.0 1.0 0.01

// Vector Pass
//#pragma parameter timeratio "Time Ratio" 1.0 0.0 2.0 0.01
//#pragma parameter timescale "Time Scale" 1.0 1.0 10.0 1.0
//#pragma parameter lengthratio "Length Ratio" 1.0 1.0 10.0 1.0
//#pragma parameter lengthscale "Length Scale" 1.0 1.0 10.0 1.0
//#pragma parameter beamsmooth "Beam Smooth Amt" 0.5 0.1 1.0 0.1

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
// out variables go here as COMPAT_VARYING whatever

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float // effect toggles and multi
 bloomtoggle,
 ntscsignal,
 scanlinetoggle,
 chromatoggle,
 distortiontoggle,
 screenscale_x,
 screenscale_y,
 screenoffset_x,
 screenoffset_y,
 swapxy,
// bloom params
 bloomblendmode,
//	float vectorscreen,
 bloomscale,
 bloomoverdrive_r,
 bloomoverdrive_g,
 bloomoverdrive_b,
 level0weight,
 level1weight,
 level2weight,
 level3weight,
 level4weight,
 level5weight,
 level6weight,
 level7weight,
 level8weight,
// post params
 mask_width,
 mask_height,
 mask_offset_x,
 mask_offset_y,
 preparebloom,
 shadowtilemode,
 power_r,
 power_g,
 power_b,
 floor_r,
 floor_g,
 floor_b,
 chromamode,
 conversiongain_x,
 conversiongain_y,
 conversiongain_z,
 humbaralpha,
 backcolor_r,
 backcolor_g,
 backcolor_b,
 shadowalpha,
 shadowcount_x,
 shadowcount_y,
 shadowuv_x,
 shadowuv_y,
// ntsc params
 avalue,
 bvalue,
 ccvalue,
 ovalue,
 pvalue,
 scantime,
 notchhalfwidth,
 yfreqresponse,
 ifreqresponse,
 qfreqresponse,
 signaloffset,
// color params
 col_red,
 col_grn,
 col_blu,
 col_offset_x,
 col_offset_y,
 col_offset_z,
 col_scale_x,
 col_scale_y,
 col_scale_z,
 col_saturation,
// deconverge params
 converge_x_r,
 converge_x_g,
 converge_x_b,
 converge_y_r,
 converge_y_g,
 converge_y_b,
 radial_conv_x_r,
 radial_conv_x_g,
 radial_conv_x_b,
 radial_conv_y_r,
 radial_conv_y_g,
 radial_conv_y_b,
// scanline params
 scanlinealpha,
 scanlinescale,
 scanlineheight,
 scanlinevariation,
 scanlineoffset,
 scanlinebrightscale,
 scanlinebrightoffset,
// defocus params
 defocus_x,
 defocus_y,
// phosphor params
 deltatime,
 phosphor_r,
 phosphor_g,
 phosphor_b,
 phosphortoggle,
// chroma params
 ygain_r,
 ygain_g,
 ygain_b,
 chromaa_x,
 chromaa_y,
 chromab_x,
 chromab_y,
 chromac_x,
 chromac_y,
// distortion params
 distortion_amount,
 cubic_distortion_amount,
 distort_corner_amount,
 round_corner_amount,
 smooth_border_amount,
 vignette_amount,
 reflection_amount,
 reflection_col_r,
 reflection_col_g,
 reflection_col_b;
#else
#define WHATEVER 0.0
#endif

#define DiffuseSampler Texture
#define SourceDims OrigTextureSize.xy

bool NTSCSignal = bool(ntscsignal);
bool ScanlineToggle = bool(scanlinetoggle);
bool BloomToggle = bool(bloomtoggle);
bool Chromaticity = bool(chromatoggle);
bool Distortion = bool(distortiontoggle);
bool Passthrough = !bool(phosphortoggle);
vec2 ScreenScale = vec2(screenscale_x, screenscale_y);
const float vectorscreen = 0.0;
bool VectorScreen = bool(vectorscreen);
vec2 ScreenOffset = vec2(screenoffset_x, screenoffset_y);
bool SwapXY = bool(swapxy);

float AValue = avalue;
float BValue = bvalue;
float CCValue = ccvalue;
float OValue = ovalue;
float PValue = pvalue;
float ScanTime = scantime;

float NotchHalfWidth = notchhalfwidth;
float YFreqResponse = yfreqresponse;
float IFreqResponse = ifreqresponse;
float QFreqResponse = qfreqresponse;

float SignalOffset = signaloffset;

const float PI = 3.1415927;
const float PI2 = PI * 2.0;

const vec4 YDot = vec4(0.299, 0.587, 0.114, 0.0);
const vec4 IDot = vec4(0.595716, -0.274453, -0.321263, 0.0);
const vec4 QDot = vec4(0.211456, -0.522591, 0.311135, 0.0);

const vec3 RDot = vec3(1.0, 0.956, 0.621);
const vec3 GDot = vec3(1.0, -0.272, -0.647);
const vec3 BDot = vec3(1.0, -1.106, 1.703);

const vec4 OffsetX = vec4(0.0, 0.25, 0.50, 0.75);
const vec4 NotchOffset = vec4(0.0, 1.0, 2.0, 3.0);

const int SampleCount = 64;
const int HalfSampleCount = SampleCount / 2;

vec4 GetCompositeYIQ(vec2 coord)
{
	vec2 PValueSourceTexel = vec2(PValue / SourceDims.x, 0.0);

	vec2 C0 = coord + PValueSourceTexel * OffsetX.x;
	vec2 C1 = coord + PValueSourceTexel * OffsetX.y;
	vec2 C2 = coord + PValueSourceTexel * OffsetX.z;
	vec2 C3 = coord + PValueSourceTexel * OffsetX.w;
	vec4 Cx = vec4(C0.x, C1.x, C2.x, C3.x);
	vec4 Cy = vec4(C0.y, C1.y, C2.y, C3.y);
	vec4 Texel0 = COMPAT_TEXTURE(DiffuseSampler, C0);
	vec4 Texel1 = COMPAT_TEXTURE(DiffuseSampler, C1);
	vec4 Texel2 = COMPAT_TEXTURE(DiffuseSampler, C2);
	vec4 Texel3 = COMPAT_TEXTURE(DiffuseSampler, C3);

	vec4 HPosition = Cx;
	vec4 VPosition = Cy;

	vec4 Y = vec4(dot(Texel0, YDot), dot(Texel1, YDot), dot(Texel2, YDot), dot(Texel3, YDot));
	vec4 I = vec4(dot(Texel0, IDot), dot(Texel1, IDot), dot(Texel2, IDot), dot(Texel3, IDot));
	vec4 Q = vec4(dot(Texel0, QDot), dot(Texel1, QDot), dot(Texel2, QDot), dot(Texel3, QDot));

	float W = PI2 * CCValue * ScanTime;
	float WoPI = W / PI;

	float HOffset = (BValue + SignalOffset) / WoPI;
	float VScale = (AValue * SourceDims.y) / WoPI;

	vec4 T = HPosition + HOffset + VPosition * VScale;
	vec4 TW = T * W;

	vec4 CompositeYIQ = Y + I * cos(TW) + Q * sin(TW);

	return CompositeYIQ;
}

void main()
{
   if(!NTSCSignal)
   {
      FragColor = COMPAT_TEXTURE(DiffuseSampler, vTexCoord);
      return;
   }
   else
   {
	vec2 coord = vTexCoord * InputSize / TextureSize;
      vec4 BaseTexel = COMPAT_TEXTURE(DiffuseSampler, coord);

      float TimePerSample = ScanTime / (SourceDims.x * 4.0);

      float Fc_y1 = (CCValue - NotchHalfWidth) * TimePerSample;
      float Fc_y2 = (CCValue + NotchHalfWidth) * TimePerSample;
      float Fc_y3 = YFreqResponse * TimePerSample;
      float Fc_i = IFreqResponse * TimePerSample;
      float Fc_q = QFreqResponse * TimePerSample;
      float Fc_i_2 = Fc_i * 2.0;
      float Fc_q_2 = Fc_q * 2.0;
      float Fc_y1_2 = Fc_y1 * 2.0;
      float Fc_y2_2 = Fc_y2 * 2.0;
      float Fc_y3_2 = Fc_y3 * 2.0;
      float Fc_i_pi2 = Fc_i * PI2;
      float Fc_q_pi2 = Fc_q * PI2;
      float Fc_y1_pi2 = Fc_y1 * PI2;
      float Fc_y2_pi2 = Fc_y2 * PI2;
      float Fc_y3_pi2 = Fc_y3 * PI2;
      float PI2Length = (3.1415927 * 2.0) / 64.;//PI2 / SampleCount;

      float W = PI2 * CCValue * ScanTime;
      float WoPI = W / PI;

      float HOffset = (BValue + SignalOffset) / WoPI;
      float VScale = (AValue * SourceDims.y) / WoPI;

      vec4 YAccum = vec4(0.0);
      vec4 IAccum = vec4(0.0);
      vec4 QAccum = vec4(0.0);
      vec4 n4 = vec4(0.0);
      float n = 0.0;

      vec4 Cy = vTexCoord.yyyy;
      vec4 VPosition = Cy;

//      for (float i = 0.; i < SampleCount; i += 4.0)
      for (float i = 0.; i < 64.0; i += 4.0)
      {
         n = i - 32.0;//HalfSampleCount;
         n4 = n + NotchOffset;

         vec4 Cx = vTexCoord.x + (n4 * 0.25) / SourceDims.x;
         vec4 HPosition = Cx;

         vec4 C = GetCompositeYIQ(vec2(Cx.r, Cy.r));

         vec4 T = HPosition + HOffset + VPosition * VScale;
         vec4 WT = W * T + OValue;

         vec4 SincKernel = 0.54 + 0.46 * cos(PI2Length * n4);

         vec4 SincYIn1 = Fc_y1_pi2 * n4;
         vec4 SincYIn2 = Fc_y2_pi2 * n4;
         vec4 SincYIn3 = Fc_y3_pi2 * n4;
         vec4 SincIIn = Fc_i_pi2 * n4;
         vec4 SincQIn = Fc_q_pi2 * n4;
      
         vec4 SincY1, SincY2, SincY3;

         SincY1.x = (SincYIn1.x != 0.0) ? sin(SincYIn1.x) / SincYIn1.x : 1.0;
         SincY1.y = (SincYIn1.y != 0.0) ? sin(SincYIn1.y) / SincYIn1.y : 1.0;
         SincY1.z = (SincYIn1.z != 0.0) ? sin(SincYIn1.z) / SincYIn1.z : 1.0;
         SincY1.w = (SincYIn1.w != 0.0) ? sin(SincYIn1.w) / SincYIn1.w : 1.0;
         SincY2.x = (SincYIn2.x != 0.0) ? sin(SincYIn2.x) / SincYIn2.x : 1.0;
         SincY2.y = (SincYIn2.y != 0.0) ? sin(SincYIn2.y) / SincYIn2.y : 1.0;
         SincY2.z = (SincYIn2.z != 0.0) ? sin(SincYIn2.z) / SincYIn2.z : 1.0;
         SincY2.w = (SincYIn2.w != 0.0) ? sin(SincYIn2.w) / SincYIn2.w : 1.0;
         SincY3.x = (SincYIn3.x != 0.0) ? sin(SincYIn3.x) / SincYIn3.x : 1.0;
         SincY3.y = (SincYIn3.y != 0.0) ? sin(SincYIn3.y) / SincYIn3.y : 1.0;
         SincY3.z = (SincYIn3.z != 0.0) ? sin(SincYIn3.z) / SincYIn3.z : 1.0;
         SincY3.w = (SincYIn3.w != 0.0) ? sin(SincYIn3.w) / SincYIn3.w : 1.0;
      
         vec4 IdealY, IdealI, IdealQ;

         IdealY = (Fc_y1_2 * SincY1 - Fc_y2_2 * SincY2) + Fc_y3_2 * SincY3;
         IdealI.x = Fc_i_2 * (SincIIn.x != 0.0 ? sin(SincIIn.x) / SincIIn.x : 1.0);
         IdealI.y = Fc_i_2 * (SincIIn.y != 0.0 ? sin(SincIIn.y) / SincIIn.y : 1.0);
         IdealI.z = Fc_i_2 * (SincIIn.z != 0.0 ? sin(SincIIn.z) / SincIIn.z : 1.0);
         IdealI.w = Fc_i_2 * (SincIIn.w != 0.0 ? sin(SincIIn.w) / SincIIn.w : 1.0);
         IdealQ.x = Fc_q_2 * (SincQIn.x != 0.0 ? sin(SincQIn.x) / SincQIn.x : 1.0);
         IdealQ.y = Fc_q_2 * (SincQIn.y != 0.0 ? sin(SincQIn.y) / SincQIn.y : 1.0);
         IdealQ.z = Fc_q_2 * (SincQIn.z != 0.0 ? sin(SincQIn.z) / SincQIn.z : 1.0);
         IdealQ.w = Fc_q_2 * (SincQIn.w != 0.0 ? sin(SincQIn.w) / SincQIn.w : 1.0);

         vec4 FilterY = SincKernel * IdealY;
         vec4 FilterI = SincKernel * IdealI;
         vec4 FilterQ = SincKernel * IdealQ;

         YAccum = YAccum + C * FilterY;
         IAccum = IAccum + C * cos(WT) * FilterI;
         QAccum = QAccum + C * sin(WT) * FilterQ;
      }

      vec3 YIQ = vec3(
         (YAccum.r + YAccum.g + YAccum.b + YAccum.a),
         (IAccum.r + IAccum.g + IAccum.b + IAccum.a) * 2.0,
         (QAccum.r + QAccum.g + QAccum.b + QAccum.a) * 2.0);

      vec3 RGB = vec3(
         dot(YIQ, RDot),
         dot(YIQ, GDot),
         dot(YIQ, BDot));

      FragColor = vec4(RGB, BaseTexel.a);
   }
} 
#endif
