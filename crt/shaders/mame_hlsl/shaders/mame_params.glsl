#version 130

// Parameters-setup and stock passthru pass for MAME HLSL

// Effect Toggles and Settings Used In Multiple Passes
//#pragma parameter ntscsignal "NTSC Signal Mode" 0.0 0.0 1.0 1.01.0
//bool NTSCSignal = bool(global.ntscsignal);
#pragma parameter scanlinetoggle "Scanline Toggle" 1.0 0.0 1.0 1.0
//bool ScanlineToggle = bool(global.scanlinetoggle); // move to scanline pass
#pragma parameter bloomtoggle "Bloom Enable" 0.0 0.0 1.0 1.0
//bool BloomToggle = bool(global.bloomtoggle); // move to bloom pass
#pragma parameter chromatoggle "Chromaticity Toggle" 0.0 0.0 1.0 1.0
//bool Chromaticity = bool(global.chromatoggle); // move to chromaticity pass
#pragma parameter distortiontoggle "Distortion Toggle" 0.0 0.0 1.0 1.0
//bool Distortion = bool(global.distortiontoggle); // move to distortion pass
#pragma parameter phosphortoggle "Phosphor Persistence Toggle" 0.0 0.0 1.0 1.0
//bool Passthrough = !bool(global.phosphortoggle); // move to phosphor pass
#pragma parameter screenscale_x "Screen Scale X" 1.0 0.5 3.0 0.01
#pragma parameter screenscale_y "Screen Scale Y" 1.0 0.5 3.0 0.01
//vec2 ScreenScale = vec2(global.screenscale_x, global.screenscale_y); // move to any pass that uses it
//#pragma parameter vectorscreen "Vector Screen Mode" 0.0 0.0 1.0 1.0 // TODO/FIXME
//const float vectorscreen = 0.0;
//bool VectorScreen = bool(vectorscreen); // move to any pass that uses it

#pragma parameter screenoffset_x "Screen Offset X" 0.0 -1.0 1.0 0.005
#pragma parameter screenoffset_y "Screen Offset Y" 0.0 -1.0 1.0 0.005
// vec2 ScreenOffset = vec2(global.screenoffset_x, global.screenoffset_y); // move to any pass that uses it
#pragma parameter swapxy "Swap X and Y" 0.0 0.0 1.0 1.0
//bool SwapXY = bool(global.swapxy); // move to any pass that uses it

// Bloom Pass
#pragma parameter bloomblendmode "Bloom Blend Mode" 0.0 0.0 1.0 1.0
#pragma parameter bloomscale "Bloom Scale" 0.33 0.0 1.0 0.01
#pragma parameter bloomoverdrive_r "Bloom Overdrive R" 1.0 0.0 2.0 0.01
#pragma parameter bloomoverdrive_g "Bloom Overdrive G" 1.0 0.0 2.0 0.01
#pragma parameter bloomoverdrive_b "Bloom Overdrive B" 1.0 0.0 2.0 0.01
#pragma parameter level0weight "Bloom Level 0 Weight" 0.64 0.0 1.0 0.01
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
/*
// NTSC Pass
#pragma parameter avalue "A Value" 0.5 -1.0 1.0 0.01
#pragma parameter bvalue "B Value" 0.5 -1.0 1.0 0.01
#pragma parameter ccvalue "CC Value" 3.5795454 0.0 6.0 0.0005
#pragma parameter ovalue "O Value" 0.0 -3.0 3.0 0.1
#pragma parameter pvalue "P Value" 1.0 -3.0 3.0 0.1
#pragma parameter scantime "Scan Time" 52.6 0.0 100.0 0.1
#pragma parameter notchhalfwidth "Notch Half Width" 1.0 0.0 6.0 0.05
#pragma parameter yfreqresponse "Y Freq Response" 6.0 0.0 6.0 0.05
#pragma parameter ifreqresponse "I Freq Response" 1.2 0.0 6.0 0.05
#pragma parameter qfreqresponse "Q Freq Response" 0.6 0.0 6.0 0.05
#pragma parameter signaloffset "Signal Offset" 1.0 0.0 1.0 0.01
*/
// Color Pass
#pragma parameter col_red "Red Shift" 1.0 0.0 2.0 0.01
#pragma parameter col_grn "Green Shift" 1.0 0.0 2.0 0.01
#pragma parameter col_blu "Blue Shift" 1.0 0.0 2.0 0.01
#pragma parameter col_offset_x "Offset X" 0.0 -1.0 1.0 0.01
#pragma parameter col_offset_y "Offset Y" 0.0 -1.0 1.0 0.01
#pragma parameter col_offset_z "Offset Z" 0.0 -1.0 1.0 0.01
#pragma parameter col_scale_x "Scale X" 1.0 0.0 2.0 0.01
#pragma parameter col_scale_y "Scale Y" 1.0 0.0 2.0 0.01
#pragma parameter col_scale_z "Scale Z" 1.0 0.0 2.0 0.01
#pragma parameter col_saturation "Saturation" 1.0 0.0 5.0 0.01

// Deconverge Pass
#pragma parameter converge_x_r "Convergence X Red" 0.0 -10.0 10.0 0.05
#pragma parameter converge_x_g "Convergence X Green" 0.0 -10.0 10.0 0.05
#pragma parameter converge_x_b "Convergence X Blue" 0.0 -10.0 10.0 0.05
#pragma parameter converge_y_r "Convergence Y Red" 0.0 -10.0 10.0 0.05
#pragma parameter converge_y_g "Convergence Y Green" 0.0 -10.0 10.0 0.05
#pragma parameter converge_y_b "Convergence Y Blue" 0.0 -10.0 10.0 0.05
#pragma parameter radial_conv_x_r "Radial Conv X Red" 0.0 -10.0 10.0 0.05
#pragma parameter radial_conv_x_g "Radial Conv X Green" 0.0 -10.0 10.0 0.05
#pragma parameter radial_conv_x_b "Radial Conv X Blue" 0.0 -10.0 10.0 0.05
#pragma parameter radial_conv_y_r "Radial Conv Y Red" 0.0 -10.0 10.0 0.05
#pragma parameter radial_conv_y_g "Radial Conv Y Green" 0.0 -10.0 10.0 0.05
#pragma parameter radial_conv_y_b "Radial Conv Y Blue" 0.0 -10.0 10.0 0.05

// Scanline Pass
#pragma parameter scanlinealpha "Scanline Alpha" 0.5 0.0 1.0 0.01
#pragma parameter scanlinescale "Scanline Scale" 5.0 1.0 5.0 1.0
#pragma parameter scanlineheight "Scanline Height" 1.0 0.0 2.0 0.1
#pragma parameter scanlinevariation "Scanline Variation" 1.0 0.0 5.0 0.5
#pragma parameter scanlineoffset "Scanline Offset" 0.0 -1.5 3.0 0.1
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
#pragma parameter distortion_amount "Distortion Amount" 0.01 0.0 1.0 0.01
#pragma parameter cubic_distortion_amount "Cubic Dist. Amt" 0.0 0.0 1.0 0.01
#pragma parameter distort_corner_amount "Corner Dist. Amt" 0.0 0.0 1.0 0.01
#pragma parameter round_corner_amount "Corner Rounding" 0.03 0.0 1.0 0.01
#pragma parameter smooth_border_amount "Border Smoothing" 0.02 0.0 1.0 0.01
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

void main()
{
    FragColor = COMPAT_TEXTURE(Source, vTexCoord);
} 
#endif
