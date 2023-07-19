/*
   Grade - CRT emulation and color manipulation shader

   Copyright (C) 2020-2023 Dogway (Jose Linares)

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/


/*
   Grade (17-07-2023)
   > See settings decriptions at: https://forums.libretro.com/t/dogways-grading-shader-slang/27148/442

   > Ubershader grouping some monolithic color related shaders:
    ::color-mangler (hunterk), ntsc color tuning knobs (Doriphor), white_point (hunterk, Dogway), RA Reshade LUT.
   > and the addition of:
    ::analogue color emulation, phosphor gamut, color space + TRC support, vibrance, HUE vs SAT, vignette (shared by Syh), black level, rolled gain and sigmoidal contrast.

   **Thanks to those that helped me out keep motivated by continuous feedback and bug reports:
   **Syh, Nesguy, hunterk, and the libretro forum members.


    #####################################...STANDARDS...######################################
    ##########################################################################################
    ###                                                                                    ###
    ###    PAL                                                                             ###
    ###        Phosphor: 470BG (#3)                                                        ###
    ###        WP: D65 (6504K)               (in practice more like 7000K-7500K range)     ###
    ###        Saturation: -0.02                                                           ###
    ###                                                                                    ###
    ###    NTSC-U                                                                          ###
    ###        Phosphor: P22/SMPTE-C (#1 #-3)(or a SMPTE-C based CRT phosphor gamut)       ###
    ###        WP: D65 (6504K)               (in practice more like 7000K-7500K range)     ###
    ###                                                                                    ###
    ###    NTSC-J (Default)                                                                ###
    ###        Phosphor: NTSC-J (#2)         (or a NTSC-J based CRT phosphor gamut)        ###
    ###        WP: 9300K+27MPCD (8945K)      (CCT from x:0.281 y:0.311)(in practice ~8500K)###
    ###                                                                                    ###
    ###                                                                                    ###
    ##########################################################################################
    ##########################################################################################
*/


#pragma parameter g_signal_type  "Signal Type (0:RGB 1:Composite)"                            0.0  0.0 1.0 1.0
#pragma parameter g_crtgamut     "Phosphor (-2:CRT-95s -1:P22-80s 1:P22-90s 2:NTSC-J 3:PAL)"  0.0 -3.0 3.0 1.0
#pragma parameter g_space_out    "Diplay Color Space (-1:709 0:sRGB 1:P3-D65 2:2020 3:Adobe)" 0.0 -1.0 3.0 1.0
#pragma parameter g_Dark_to_Dim  "Dark to Dim adaptation"                                     1.0  0.0 1.0 1.0
#pragma parameter g_GCompress    "Gamut Compression"                                          0.0  0.0 1.0 1.0

// Analogue controls
#pragma parameter g_analog       "// ANALOG CONTROLS //"      0.0    0.0   1.0  1.0
#pragma parameter wp_temperature "White Point"                6504.0 5004.0 12004.0 100.0
#pragma parameter g_hue_degrees  "CRT Hue"                    0.0 -180.0 180.0  1.0
#pragma parameter g_U_SHIFT      "CRT U Shift"                0.0   -0.2   0.2  0.01
#pragma parameter g_V_SHIFT      "CRT V Shift"                0.0   -0.2   0.2  0.01
#pragma parameter g_U_MUL        "CRT U Multiplier"           1.0    0.0   2.0  0.01
#pragma parameter g_V_MUL        "CRT V Multiplier"           1.0    0.0   2.0  0.01
#pragma parameter g_CRT_l        "CRT Gamma"                  2.50   2.30  2.60 0.01
#pragma parameter g_CRT_b        "CRT Brightness"            50.0    0.0 100.0  1.0
#pragma parameter g_CRT_c        "CRT Contrast"              50.0    0.0 100.0  1.0
#pragma parameter g_CRT_br       "CRT Beam Red"               1.0    0.0   1.2  0.01
#pragma parameter g_CRT_bg       "CRT Beam Green"             1.0    0.0   1.2  0.01
#pragma parameter g_CRT_bb       "CRT Beam Blue"              1.0    0.0   1.2  0.01
#pragma parameter g_CRT_rf       "CRT Lambert Refl. in %"     5.0    2.0   5.0  0.1
#pragma parameter g_CRT_sl       "Surround Luminance -nits-"  0.0    0.0 100.0  1.0
#pragma parameter g_vignette     "Vignette Toggle"            0.0    0.0   1.0  1.0
#pragma parameter g_vstr         "Vignette Strength"         40.0    0.0  50.0  1.0
#pragma parameter g_vpower       "Vignette Power"             0.20   0.0   0.5  0.01

// Digital controls
#pragma parameter g_digital      "// DIGITAL CONTROLS //"     0.0  0.0 1.0 1.0
#pragma parameter g_lum_fix      "Sega Luma Fix"              0.0  0.0 1.0 1.0
#pragma parameter g_lum          "Brightness"                 0.0 -0.5 1.0 0.01
#pragma parameter g_cntrst       "Contrast"                   0.0 -1.0 1.0 0.05
#pragma parameter g_mid          "Contrast Pivot"             0.5  0.0 1.0 0.01
#pragma parameter g_sat          "Saturation"                 0.0 -1.0 1.0 0.01
#pragma parameter g_vibr         "Dullness/Vibrance"          0.0 -1.0 1.0 0.05
#pragma parameter g_satr         "Hue vs Sat Red"             0.0 -1.0 1.0 0.01
#pragma parameter g_satg         "Hue vs Sat Green"           0.0 -1.0 1.0 0.01
#pragma parameter g_satb         "Hue vs Sat Blue"            0.0 -1.0 1.0 0.01
#pragma parameter g_lift         "Black Level"                0.0 -0.5 0.5 0.01
#pragma parameter blr            "Black-Red Tint"             0.0  0.0 1.0 0.01
#pragma parameter blg            "Black-Green Tint"           0.0  0.0 1.0 0.01
#pragma parameter blb            "Black-Blue Tint"            0.0  0.0 1.0 0.01
#pragma parameter wlr            "White-Red Tint"             1.0  0.0 2.0 0.01
#pragma parameter wlg            "White-Green Tint"           1.0  0.0 2.0 0.01
#pragma parameter wlb            "White-Blue Tint"            1.0  0.0 2.0 0.01
#pragma parameter rg             "Red-Green Tint"             0.0 -1.0 1.0 0.005
#pragma parameter rb             "Red-Blue Tint"              0.0 -1.0 1.0 0.005
#pragma parameter gr             "Green-Red Tint"             0.0 -1.0 1.0 0.005
#pragma parameter gb             "Green-Blue Tint"            0.0 -1.0 1.0 0.005
#pragma parameter br             "Blue-Red Tint"              0.0 -1.0 1.0 0.005
#pragma parameter bg             "Blue-Green Tint"            0.0 -1.0 1.0 0.005



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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

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

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float g_signal_type, g_crtgamut, g_space_out, g_Dark_to_Dim, g_GCompress, g_hue_degrees, g_U_SHIFT, g_V_SHIFT, g_U_MUL, g_V_MUL, g_CRT_l, g_CRT_b, g_CRT_c, g_CRT_br, g_CRT_bg, g_CRT_bb, g_CRT_rf, g_CRT_sl, g_vignette, g_vstr, g_vpower, g_lum_fix, g_lum, g_cntrst, g_mid, wp_temperature, g_sat, g_vibr, g_satr, g_satg, g_satb, g_lift, blr, blg, blb, wlr, wlg, wlb, rg, rb, gr, gb, br, bg;
#else
#define g_signal_type 0.0
#define g_crtgamut 0.0
#define g_space_out 0.0
#define g_Dark_to_Dim 1.0
#define g_GCompress 0.0
#define g_hue_degrees 0.0
#define g_U_SHIFT 0.0
#define g_V_SHIFT 0.0
#define g_U_MUL 1.0
#define g_V_MUL 1.0
#define g_CRT_l 2.50
#define g_CRT_b 50.0
#define g_CRT_c 50.0
#define g_CRT_br 1.0
#define g_CRT_bg 1.0
#define g_CRT_bb 1.0
#define g_CRT_rf 5.0
#define g_CRT_sl 0.0
#define g_vignette 0.0
#define g_vstr 40.0
#define g_vpower 0.20
#define g_lum_fix 0.0
#define g_lum 0.0
#define g_cntrst 0.0
#define g_mid 0.5
#define wp_temperature 6504.0
#define g_sat 0.0
#define g_vibr 0.0
#define g_satr 0.0
#define g_satg 0.0
#define g_satb 0.0
#define g_lift 0.0
#define blr 0.0
#define blg 0.0
#define blb 0.0
#define wlr 1.0
#define wlg 1.0
#define wlb 1.0
#define rg 0.0
#define rb 0.0
#define gr 0.0
#define gb 0.0
#define br 0.0
#define bg 0.0
#endif

#define RW vec3(0.950457397565471, 1.0, 1.089436035930324)
#define M_PI 3.1415926535897932384626433832795/180.0
#define g_bl -(100000.*log((72981.-500000./(3.*max(2.3,g_CRT_l)))/9058.))/945461.




///////////////////////// Color Space Transformations //////////////////////////

// 'D65' based
mat3 RGB_to_XYZ_mat(mat3 primaries) {

    vec3 T  = RW * inverse(primaries);

    mat3 TB = mat3(
                T.x, 0.0, 0.0,
                0.0, T.y, 0.0,
                0.0, 0.0, T.z);

    return TB * primaries;
 }


vec3 RGB_to_XYZ(vec3 RGB, mat3 primaries) {

    return RGB *         RGB_to_XYZ_mat(primaries);
 }

vec3 XYZ_to_RGB(vec3 XYZ, mat3 primaries) {

    return XYZ * inverse(RGB_to_XYZ_mat(primaries));
 }


vec3 XYZtoYxy(vec3 XYZ) {

    float XYZrgb =  XYZ.r+XYZ.g+XYZ.b;
    float Yxyg   = (XYZrgb <= 0.0) ? 0.3805 : XYZ.r / XYZrgb;
    float Yxyb   = (XYZrgb <= 0.0) ? 0.3769 : XYZ.g / XYZrgb;
    return vec3(XYZ.g, Yxyg, Yxyb);
 }

vec3 YxytoXYZ(vec3 Yxy) {

    float Xs  =  Yxy.r * (Yxy.g/Yxy.b);
    float Xsz = (Yxy.r <= 0.0) ? 0.0 : 1.0;
    vec3 XYZ  = vec3(Xsz,Xsz,Xsz) * vec3(Xs, Yxy.r, (Xs/Yxy.g)-Xs-Yxy.r);
    return XYZ;
 }


///////////////////////// White Point Mapping /////////////////////////
//
//
// PAL: D65        NTSC-U: D65       NTSC-J: CCT 9300K+27MPCD
// PAL: 6503.512K  NTSC-U: 6503.512K NTSC-J: ~8945.436K
// [x:0.31266142   y:0.3289589]      [x:0.281 y:0.311]

// For NTSC-J there's not a common agreed value, measured consumer units span from 8229.87K to 8945.623K with accounts for 8800K as well.
// Recently it's been standardized to 9300K which is closer to what master monitors (and not consumer units) were (x=0.2838 y=0.2984) (~9177.98K)

// "RGB to XYZ -> Temperature -> XYZ to RGB" joint matrix
vec3 wp_adjust(vec3 RGB, float temperature, mat3 primaries, mat3 display) {

    float temp3 = 1000.       /     temperature;
    float temp6 = 1000000.    / pow(temperature, 2.0);
    float temp9 = 1000000000. / pow(temperature, 3.0);

    vec3 wp = vec3(1.0);

    wp.x = (temperature < 5500.) ? 0.244058 + 0.0989971 * temp3 + 2.96545 * temp6 - 4.59673 * temp9 : \
           (temperature < 8000.) ? 0.200033 + 0.9545630 * temp3 - 2.53169 * temp6 + 7.08578 * temp9 : \
                                   0.237045 + 0.2437440 * temp3 + 1.94062 * temp6 - 2.11004 * temp9 ;

    wp.y = -0.275275 + 2.87396 * wp.x - 3.02034 * pow(wp.x,2.0) + 0.0297408 * pow(wp.x,3.0);
    wp.z =  1.0 - wp.x - wp.y;

    const mat3 CAT16 = mat3(
     0.401288,-0.250268, -0.002079,
     0.650173, 1.204414,  0.048952,
    -0.051461, 0.045854,  0.953127);

    vec3 VKV = (vec3(wp.x/wp.y,1.,wp.z/wp.y) * CAT16) / (RW * CAT16);

    mat3 VK = mat3(
                VKV.x, 0.0, 0.0,
                0.0, VKV.y, 0.0,
                0.0, 0.0, VKV.z);

    mat3 CAM  = CAT16 * (VK * inverse(CAT16));

    mat3 mata = RGB_to_XYZ_mat(primaries);
    mat3 matb = RGB_to_XYZ_mat(display);

    return RGB.rgb * ((mata * CAM) * inverse(matb));
 }


////////////////////////////////////////////////////////////////////////////////


// CRT EOTF Function
//----------------------------------------------------------------------

float EOTF_1886a(float color, float bl, float brightness, float contrast) {

    // Defaults:
    //  Black Level = 0.1
    //  Brightness  = 0
    //  Contrast    = 100

    const float wl = 100.0;
          float b  = pow(bl, 1./2.4);
          float a  = pow(wl, 1./2.4)-b;
                b  = (brightness-50.) / 250. + b/a;                   // -0.20 to +0.20
                a  = contrast!=50. ? pow(2.,(contrast-50.)/50.) : 1.; //  0.50 to +2.00

    const float Vc = 0.35;                           // Offset
          float Lw = wl/100. * a;                    // White level
          float Lb = min( b  * a,Vc);                // Black level
    const float a1 = 2.6;                            // Shoulder gamma
    const float a2 = 3.0;                            // Knee gamma
          float k  = Lw /pow(1. + Lb,    a1);
          float sl = k * pow(Vc + Lb, a1-a2);        // Slope for knee gamma

    color = color >= Vc ? k * pow(color + Lb, a1 ) : sl * pow(color + Lb, a2 );
    return color;
 }

vec3 EOTF_1886a_f3( vec3 color, float BlackLevel, float brightness, float contrast) {

    color.r = EOTF_1886a( color.r, BlackLevel, brightness, contrast);
    color.g = EOTF_1886a( color.g, BlackLevel, brightness, contrast);
    color.b = EOTF_1886a( color.b, BlackLevel, brightness, contrast);
    return color.rgb;
 }



// Monitor Curve Functions: https://github.com/ampas/aces-dev
//----------------------------------------------------------------------


float moncurve_f( float color, float gamma, float offs) {

    // Forward monitor curve
    color    = clamp(color, 0.0, 1.0);
    float fs = (( gamma - 1.0) / offs) * pow( offs * gamma / ( ( gamma - 1.0) * ( 1.0 + offs)), gamma);
    float xb = offs / ( gamma - 1.0);

    color = ( color > xb) ? pow( ( color + offs) / ( 1.0 + offs), gamma) : color * fs;
    return color;
 }


vec3 moncurve_f_f3( vec3 color, float gamma, float offs) {

    color.r = moncurve_f( color.r, gamma, offs);
    color.g = moncurve_f( color.g, gamma, offs);
    color.b = moncurve_f( color.b, gamma, offs);
    return color.rgb;
 }


float moncurve_r( float color, float gamma, float offs) {

    // Reverse monitor curve
    color = clamp(color, 0.0, 1.0);
    float yb = pow( offs * gamma / ( ( gamma - 1.0) * ( 1.0 + offs)), gamma);
    float rs = pow( ( gamma - 1.0) / offs, gamma - 1.0) * pow( ( 1.0 + offs) / gamma, gamma);

    color = ( color > yb) ? ( 1.0 + offs) * pow( color, 1.0 / gamma) - offs : color * rs;
    return color;
 }


vec3 moncurve_r_f3( vec3 color, float gamma, float offs) {

    color.r = moncurve_r( color.r, gamma, offs);
    color.g = moncurve_r( color.g, gamma, offs);
    color.b = moncurve_r( color.b, gamma, offs);
    return color.rgb;
 }


//-------------------------- Luma Functions ----------------------------


//  Performs better in gamma encoded space
float contrast_sigmoid(float color, float cont, float pivot) {

    cont = pow(cont + 1., 3.);

    float knee  = 1. / (1. + exp(cont *  pivot));
    float shldr = 1. / (1. + exp(cont * (pivot - 1.)));

    color       =(1. / (1. + exp(cont * (pivot - color))) - knee) / (shldr - knee);

    return color;
 }


//  Performs better in gamma encoded space
float contrast_sigmoid_inv(float color, float cont, float pivot) {

    cont = pow(cont - 1., 3.);

    float knee  = 1. / (1. + exp (cont *  pivot));
    float shldr = 1. / (1. + exp (cont * (pivot - 1.)));

    color = pivot - log(1. / (color * (shldr - knee) + knee) - 1.) / cont;

    return color;
 }


float rolled_gain(float color, float gain) {

    float gx   = abs(gain) + 0.001;
    float anch = (gain > 0.0) ? 0.5 / (gx / 2.0) : 0.5 / gx;
    color      = (gain > 0.0) ? color * ((color - anch) / (1.0 - anch)) : color * ((1.0 - anch) / (color - anch)) * (1.0 - gain);

    return color;
 }


vec3 rolled_gain_v3(vec3 color, float gain) {

    color.r = rolled_gain(color.r, gain);
    color.g = rolled_gain(color.g, gain);
    color.b = rolled_gain(color.b, gain);

    return color.rgb;
 }


float SatMask(float color_r, float color_g, float color_b) {

    float max_rgb = max(color_r, max(color_g, color_b));
    float min_rgb = min(color_r, min(color_g, color_b));
    float msk = clamp((max_rgb - min_rgb) / (max_rgb + min_rgb), 0.0, 1.0);
    return msk;
 }



//---------------------- Gamut Compression -------------------


// RGB 'Desaturate' Gamut Compression (by Jed Smith: https://github.com/jedypod/gamut-compress)
vec3 GamutCompression (vec3 rgb, float grey) {

    // Limit/Thres order is Cyan, Magenta, Yellow
    vec3  beam = max(vec3(0.0),vec3(g_CRT_bg,(g_CRT_bb+g_CRT_br)/2.,(g_CRT_br+g_CRT_bg)/2.));
    vec3  sat  = max(vec3(0.0),vec3(g_satg,  (g_satb  +g_satr  )/2.,(g_satr  +g_satg)  /2.)+1.);   // center at 1
    float temp = max(0.0,abs(wp_temperature-7000.)-1000.)/825.+1.;                                 // center at 1
    vec3  WPD  = wp_temperature < 7000. ? vec3(1.,temp,(temp-1.)/2.+1.) : vec3((temp-1.)/2.+1.,temp,1.);
          sat  = max(0.0,g_sat+1.0)*(sat*beam) * WPD;

    mat2x3 LimThres =      mat2x3( 0.100000,0.100000,0.100000,
                                   0.125000,0.125000,0.125000);
    if (g_space_out < 1.0) {

       LimThres = \
       g_crtgamut == 3.0 ? mat2x3( 0.000000,0.044065,0.000000,
                                   0.000000,0.095638,0.000000) : \
       g_crtgamut == 2.0 ? mat2x3( 0.006910,0.092133,0.000000,
                                   0.039836,0.121390,0.000000) : \
       g_crtgamut == 1.0 ? mat2x3( 0.018083,0.059489,0.017911,
                                   0.066570,0.105996,0.066276) : \
       g_crtgamut ==-1.0 ? mat2x3( 0.014947,0.098571,0.017911,
                                   0.060803,0.123793,0.066276) : \
       g_crtgamut ==-2.0 ? mat2x3( 0.004073,0.030307,0.012697,
                                   0.028222,0.083075,0.056029) : \
       g_crtgamut ==-3.0 ? mat2x3( 0.018424,0.053469,0.016841,
                                   0.067146,0.102294,0.064393) : LimThres;
    } else if (g_space_out==1.0) {

       LimThres = \
       g_crtgamut == 3.0 ? mat2x3( 0.000000,0.234229,0.007680,
                                   0.000000,0.154983,0.042446) : \
       g_crtgamut == 2.0 ? mat2x3( 0.078526,0.108432,0.006143,
                                   0.115731,0.127194,0.037039) : \
       g_crtgamut == 1.0 ? mat2x3( 0.021531,0.237184,0.013466,
                                   0.072018,0.155438,0.057731) : \
       g_crtgamut ==-1.0 ? mat2x3( 0.051640,0.103332,0.013550,
                                   0.101092,0.125474,0.057912) : \
       g_crtgamut ==-2.0 ? mat2x3( 0.032717,0.525361,0.023928,
                                   0.085609,0.184491,0.075381) : \
       g_crtgamut ==-3.0 ? mat2x3( 0.000000,0.377522,0.043076,
                                   0.000000,0.172390,0.094873) : LimThres;
    }

    // Amount of outer gamut to affect
    vec3 th = 1.0-vec3(LimThres[1])*(0.4*sat+0.3);

    // Distance limit: How far beyond the gamut boundary to compress
    vec3 dl = 1.0+vec3(LimThres[0])*sat;

    // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
    vec3 s = (vec3(1.0)-th)/sqrt(max(vec3(1.001), dl)-1.0);

    // Achromatic axis
    float ac = max(rgb.x, max(rgb.y, rgb.z));

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac==0.0?vec3(0.0):(ac-rgb)/abs(ac);

    // Compressed distance. Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
    vec3 cd;
    vec3 sf = s*sqrt(d-th+s*s/4.0)-s*sqrt(s*s/4.0)+th;
    cd.x = (d.x < th.x) ? d.x : sf.x;
    cd.y = (d.y < th.y) ? d.y : sf.y;
    cd.z = (d.z < th.z) ? d.z : sf.z;

    // Inverse RGB Ratios to RGB
    // and Mask with "luma"
    return mix(rgb, ac-cd.xyz*abs(ac), pow(grey,1.0/g_CRT_l));
    }



//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/



// Matrices in column-major


//----------------------- Y'UV color model -----------------------


//  0-235 YUV PAL
//  0-235 YUV NTSC-J
// 16-235 YUV NTSC


// Bymax 0.885515
// Rymax 0.701088
// R'G'B' full range to Decorrelated Intermediate (Y,B-Y,R-Y)
// Rows should sum to 0, except first one which sums 1
const mat3 YByRy = mat3(
    0.298912, 0.586603, 0.114485,
   -0.298912,-0.586603, 0.885515,
    0.701088,-0.586603,-0.114485);


// Umax 0.435812284313725
// Vmax 0.615857694117647
// R'G'B' full to Y'UV limited
// YUV is defined with headroom and footroom (TV range),
// UV excursion is limited to Umax and Vmax
// Y  excursion is limited to 16-235 for NTSC-U and 0-235 for PAL and NTSC-J
vec3 r601_YUV(vec3 RGB, float NTSC_U) {

    const float sclU = ((0.5*(235.-16.)+16.)/255.); // This yields Luma   grey  at around 0.49216 or 125.5 in 8-bit
    const float sclV =       (240.-16.)     /255. ; // This yields Chroma range at around 0.87843 or 224   in 8-bit

    mat3 conv_mat = mat3(
                 vec3(YByRy[0]),
    vec3(sclU) * vec3(YByRy[1]),
    vec3(sclV) * vec3(YByRy[2]));

// -0.147111592156863  -0.288700692156863   0.435812284313725
//  0.615857694117647  -0.515290478431373  -0.100567215686275

    vec3 YUV   = RGB.rgb * conv_mat;
         YUV.x = NTSC_U==1.0 ? YUV.x * 219.0 + 16.0 : YUV.x * 235.0;
    return vec3(YUV.x/255.0,YUV.yz);
 }


// Y'UV limited to R'G'B' full
vec3 YUV_r601(vec3 YUV, float NTSC_U) {

const mat3 conv_mat = mat3(
    1.0000000, -0.000000029378826483,  1.1383928060531616,
    1.0000000, -0.396552562713623050, -0.5800843834877014,
    1.0000000,  2.031872510910034000,  0.0000000000000000);

    YUV.x = (YUV.x - (NTSC_U == 1.0 ? 16.0/255.0 : 0.0 )) * (255.0/(NTSC_U == 1.0 ? 219.0 : 235.0));
    return YUV.xyz * conv_mat;
 }


// FP32 to 8-bit mid-tread uniform quantization
float Quantize8(float col) {
    col = min(255.0,floor(col * 255.0 + 0.5));
    return col;
 }

vec3 Quantize8_f3(vec3 col) {
    col.r = Quantize8(col.r);
    col.g = Quantize8(col.g);
    col.b = Quantize8(col.b);
    return col.rgb;
 }



//------------------------- LMS --------------------------


// Hunt-Pointer-Estevez D65 cone response
// modification for IPT model
const mat3 LMS = mat3(
 0.4002, 0.7075, -0.0807,
-0.2280, 1.1500,  0.0612,
 0.0000, 0.0000,  0.9184);

const mat3 IPT = mat3(
 0.4000,  0.4000, 0.2000,
 4.4550, -4.8510, 0.3960,
 0.8056, 0.3572, -1.1628);


//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/


//----------------------- Phosphor Gamuts -----------------------

////// STANDARDS ///////
// SMPTE RP 145-1994 (SMPTE-C), 170M-1999
// SMPTE-C - Standard Phosphor (Rec.601 NTSC)
// Standardized in 1982 (as CCIR Rec.601-1) after "Conrac Corp. & RCA" P22 phosphors (circa 1969) for consumer CRTs
// ILLUMINANT: D65->[0.31266142,0.3289589]
const mat3 SMPTE170M_ph = mat3(
     0.630, 0.310, 0.155,
     0.340, 0.595, 0.070,
     0.030, 0.095, 0.775);

// ITU-R BT.470/601 (B/G)
// EBU Tech.3213 PAL - Standard Phosphor for Studio Monitors (also used in Sony BVMs and Higher-end PVMs)
// ILLUMINANT: D65->[0.31266142,0.3289589]
const mat3 SMPTE470BG_ph = mat3(
     0.640, 0.290, 0.150,
     0.330, 0.600, 0.060,
     0.030, 0.110, 0.790);

// NTSC-J P22
// Mix between averaging KV-20M20, KDS VS19, Dell D93, 4-TR-B09v1_0.pdf and Phosphor Handbook 'P22'
// Phosphors based on 1975's EBU Tech.3123-E (formerly known as JEDEC-P22)
// Typical P22 phosphors used in Japanese consumer CRTs with 9300K+27MPCD white point
// ILLUMINANT: D93->[0.281000,0.311000] (CCT of 8945.436K)
// ILLUMINANT: D97->[0.285000,0.285000] (CCT of 9696K) for Nanao MS-2930s series (around 10000.0K for wp_adjust() daylight fit)
const mat3 P22_J_ph = mat3(
     0.625, 0.280, 0.152,
     0.350, 0.605, 0.062,
     0.025, 0.115, 0.786);



////// P22 ///////
// You can run any of these P22 primaries either through D65 or D93 indistinctly but typically these were D65 based.
// P22_80 is roughly the same as the old P22 gamut in Grade 2020. P22 1979-1994 meta measurement.
// ILLUMINANT: D65->[0.31266142,0.3289589]
const mat3 P22_80s_ph = mat3(
     0.6470, 0.2820, 0.1472,
     0.3430, 0.6200, 0.0642,
     0.0100, 0.0980, 0.7886);

// P22 improved with tinted phosphors (Use this for NTSC-U 16-bits, and above for 8-bits)
const mat3 P22_90s_ph = mat3(
     0.6661, 0.3134, 0.1472,
     0.3329, 0.6310, 0.0642,
     0.0010, 0.0556, 0.7886);

// RPTV (Rear Projection TV) for NTSC-U late 90s, early 00s
const mat3 RPTV_95s_ph = mat3(
     0.640, 0.341, 0.150,
     0.335, 0.586, 0.070,
     0.025, 0.073, 0.780);


//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/


//----------------------- Display Primaries -----------------------

// sRGB (IEC 61966-2-1) and ITU-R BT.709-6 (originally CCIR Rec.709)
const mat3 sRGB_prims = mat3(
     0.640, 0.300, 0.150,
     0.330, 0.600, 0.060,
     0.030, 0.100, 0.790);

// Adobe RGB (1998)
const mat3 Adobe_prims = mat3(
     0.640, 0.210, 0.150,
     0.330, 0.710, 0.060,
     0.030, 0.080, 0.790);

// BT-2020/BT-2100 (from 630nm, 532nm and 467nm)
const mat3 rec2020_prims = mat3(
     0.707917792, 0.170237195, 0.131370635,
     0.292027109, 0.796518542, 0.045875976,
     0.000055099, 0.033244263, 0.822753389);

// SMPTE RP 432-2 (DCI-P3)
const mat3 DCIP3_prims = mat3(
     0.680, 0.265, 0.150,
     0.320, 0.690, 0.060,
     0.000, 0.045, 0.790);




//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/




void main()
{

// Retro Sega Systems: Genesis, 32x, CD and Saturn 2D had color palettes designed in TV levels to save on transformations.
    float lum_exp = (g_lum_fix == 1.0) ? (255.0/239.0) : 1.0;

    vec3 src = COMPAT_TEXTURE(Source, vTexCoord).rgb * lum_exp;

// Clipping Logic / Gamut Limiting
    bool NTSC_U = g_crtgamut < 2.0;

    vec2 UVmax  = vec2(Quantize8(0.435812284313725), Quantize8(0.615857694117647));
    vec2 Ymax   = NTSC_U ? vec2(16.0, 235.0) : vec2(0.0, 235.0);


// Assumes framebuffer in Rec.601 full range with baked gamma
// Quantize to 8-bit to replicate CRT's circuit board arithmetics
    vec3 col = clamp(Quantize8_f3(r601_YUV(src, NTSC_U ? 1.0 : 0.0)), vec3(Ymax.x,  -UVmax.x, -UVmax.y),      \
                                                                      vec3(Ymax.y,   UVmax.x,  UVmax.y))/255.0;

// YUV Analogue Color Controls (HUE + Color Shift + Color Burst)
    float hue_radians = g_hue_degrees * M_PI;
    float hue = atan(col.z, col.y) + hue_radians;
    float chroma = sqrt(col.z * col.z + col.y * col.y);  // Euclidean Distance

    col.y    = (mod((chroma * cos(hue) + 1.0) + g_U_SHIFT, 2.0) - 1.0) * g_U_MUL;
    col.z    = (mod((chroma * sin(hue) + 1.0) + g_V_SHIFT, 2.0) - 1.0) * g_V_MUL;

// Back to R'G'B' full
    col      = g_signal_type > 0.0 ? max(Quantize8_f3(YUV_r601(col.xyz, NTSC_U ? 1.0 : 0.0))/255.0, 0.0) : src;

// CRT EOTF. To Display Referred Linear: Undo developer baked CRT gamma (from 2.40 at default 0.1 CRT black level, to 2.60 at 0.0 CRT black level)
    col      = EOTF_1886a_f3(col, g_bl, g_CRT_b, g_CRT_c);


//_   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _
// \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \



// HUE vs HUE
    vec4 screen = vec4(max(col, 0.0), 1.0);

                   //  r    g    b  alpha ; alpha does nothing for our purposes
    mat4 color = mat4(wlr, rg,  rb,   0.0,              //red tint
                      gr,  wlg, gb,   0.0,              //green tint
                      br,  bg,  wlb,  0.0,              //blue tint
                      blr/20., blg/20., blb/20., 0.0);  //black tint

    screen *= transpose(color);


// CRT Phosphor Gamut (0.0 is sRGB/noop)
    mat3 m_in;

    if (g_crtgamut == -3.0) { m_in = SMPTE170M_ph;         } else
    if (g_crtgamut == -2.0) { m_in = RPTV_95s_ph;          } else
    if (g_crtgamut == -1.0) { m_in = P22_80s_ph;           } else
    if (g_crtgamut ==  1.0) { m_in = P22_90s_ph;           } else
    if (g_crtgamut ==  2.0) { m_in = P22_J_ph;             } else
    if (g_crtgamut ==  3.0) { m_in = SMPTE470BG_ph;        } else
                            { m_in = sRGB_prims;           }


// Display color space
    mat3 m_ou;

    if (g_space_out == 1.0) { m_ou = DCIP3_prims;          } else
    if (g_space_out == 2.0) { m_ou = rec2020_prims;        } else
    if (g_space_out == 3.0) { m_ou = Adobe_prims;          } else
                            { m_ou = sRGB_prims;           }


// White Point Mapping
    col = wp_adjust(screen.rgb, wp_temperature, m_in, m_ou);


//  SAT + HUE vs SAT (in IPT space)
    vec3 coeff = RGB_to_XYZ_mat(m_in)[1];

    vec3 src_h = RGB_to_XYZ(screen.rgb, m_in) * LMS;
    src_h.x = src_h.x >= 0.0 ? pow(src_h.x, 0.43) : -pow(-src_h.x, 0.43);
    src_h.y = src_h.y >= 0.0 ? pow(src_h.y, 0.43) : -pow(-src_h.y, 0.43);
    src_h.z = src_h.z >= 0.0 ? pow(src_h.z, 0.43) : -pow(-src_h.z, 0.43);

    src_h.xyz *= IPT;

    float hue_at = atan(src_h.z, src_h.y);
    chroma       = sqrt(src_h.z * src_h.z + src_h.y * src_h.y);

    //  red 320º green 220º blue 100º
    float hue_radians_r = 320.0 * M_PI;
    float hue_r = cos(hue_at + hue_radians_r);

    float hue_radians_g = 220.0 * M_PI;
    float hue_g = cos(hue_at + hue_radians_g);

    float hue_radians_b = 100.0 * M_PI;
    float hue_b = cos(hue_at + hue_radians_b);

    float msk = dot(clamp(vec3(hue_r, hue_g, hue_b) * chroma * 2.0, 0.0, 1.0), -vec3(g_satr, g_satg, g_satb));
    src_h = mix(col, vec3(dot(coeff, col)), msk);

    float sat_msk = (g_vibr < 0.0) ? 1.0 - abs(SatMask(src_h.x, src_h.y, src_h.z) - 1.0) * abs(g_vibr) : \
                                     1.0 -    (SatMask(src_h.x, src_h.y, src_h.z)        *     g_vibr) ;

    float sat   = g_sat + 1.0;
    float msat  = 1.0 - sat;
    float msatx = msat * coeff.x;
    float msaty = msat * coeff.y;
    float msatz = msat * coeff.z;

    mat3 adjust = mat3(msatx + sat, msatx      , msatx       ,
                       msaty      , msaty + sat, msaty       ,
                       msatz      , msatz      , msatz + sat);


    src_h  = mix(src_h, adjust * src_h, clamp(sat_msk, 0.0, 1.0));
    src_h *= vec3(g_CRT_br,g_CRT_bg,g_CRT_bb);


// RGB 'Desaturate' Gamut Compression (by Jed Smith: https://github.com/jedypod/gamut-compress)
    coeff = RGB_to_XYZ_mat(m_ou)[1];
    src_h = g_GCompress==1.0 ? clamp(GamutCompression(src_h, dot(coeff.xyz, src_h)), 0.0, 1.0) : clamp(src_h, 0.0, 1.0);


// Sigmoidal Luma Contrast under 'Yxy' decorrelated model (in gamma space)
    vec3 Yxy = XYZtoYxy(RGB_to_XYZ(src_h, m_ou));
    float toGamma = clamp(moncurve_r(Yxy.r, 2.40, 0.055), 0.0, 1.0);
    toGamma = (Yxy.r > 0.5) ? contrast_sigmoid_inv(toGamma, 2.3, 0.5) : toGamma;
    float sigmoid = (g_cntrst > 0.0) ? contrast_sigmoid(toGamma, g_cntrst, g_mid) : contrast_sigmoid_inv(toGamma, g_cntrst, g_mid);
    vec3 contrast = vec3(moncurve_f(sigmoid, 2.40, 0.055), Yxy.g, Yxy.b);
    vec3 XYZsrgb = XYZ_to_RGB(YxytoXYZ(contrast), m_ou);
    contrast = (g_cntrst == 0.0) ? src_h : XYZsrgb;


// Lift + Gain -PP Digital Controls- (Could do in Yxy but performance reasons)
    src_h = clamp(rolled_gain_v3(contrast, clamp(g_lum, -0.49, 0.99)), 0.0, 1.0);
    src_h += (g_lift / 20.0) * (1.0 - contrast);


// Vignetting (in linear space, so after EOTF^-1 it's power shaped; 0.5 thres converts to ~0.75)
    vec2 vpos = vTexCoord*(TextureSize.xy/InputSize.xy);

    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * g_vstr;
    vig = min(pow(vig, g_vpower), 1.0);
    vig = vig >= 0.5 ? smoothstep(0.0,1.0,vig) : vig;

    src_h *= (g_vignette == 1.0) ? vig : 1.0;


// Dark to Dim adaptation OOTF; for 709, P3-D65 and 2020
    float DtD = g_Dark_to_Dim > 0.0 ? 1.0/0.9811 : 1.0;

// EOTF^-1 - Inverted Electro-Optical Transfer Function
    vec3 TRC  = (g_space_out == 3.0) ?     clamp(pow(src_h, vec3(1./ (563./256.))),        0., 1.) : \
                (g_space_out == 0.0) ? moncurve_r_f3(src_h,           2.20 + 0.20,         0.0550) : \
                                       clamp(pow(    src_h, vec3(1./((2.20 + 0.20)*DtD))), 0., 1.) ;


// External Flare for Surround Illuminant 2700K (Soft White) at F0 (Lambertian reflectance); defines offset thus also black lift
    vec3 Flare = 0.01 * (g_CRT_rf/5.0)*(0.049433*g_CRT_sl - 0.188367) * vec3(0.459993/0.410702,1.0,0.129305/0.410702);
    TRC = g_CRT_sl > 0.0 ? min(TRC+Flare,1.0) : TRC;

    FragColor = vec4(TRC, 1.0);
}
#endif
