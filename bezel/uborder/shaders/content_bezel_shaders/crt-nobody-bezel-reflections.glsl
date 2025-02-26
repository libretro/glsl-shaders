/*
   Uborder-bezels-reflections shader - Hyllian 2025.

   Bezels code is a modified version of this shadertoy: https://www.shadertoy.com/view/XdtfzX
*/

/*
   Hyllian's crt-nobody Shader
   
   Copyright (C) 2011-2025 Hyllian

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/

#version 120


#pragma parameter ubo_nonono           "[ UBORDER USER PARAMS ]"               1.0  0.0   1.0 1.0

#pragma parameter frame_nonono         "FRAME:"                               0.0    0.0   1.0 1.0
#pragma parameter fr_aspect_x          "    Set Aspect Ratio Numerator"       8.0    1.0  32.0 0.02
#pragma parameter fr_aspect_y          "    Set Aspect Ratio Denominator"     6.0    1.0  32.0 0.02
#pragma parameter fr_zoom              "    Zoom %"                          50.0    2.0 200.0 0.2
#pragma parameter fr_i_scaling         "    Use Integer Scaling for Y"        0.0    0.0   1.0 1.0
#pragma parameter fr_i_scaling_fac     "    Integer Scaling Factor [ - / + ]" 0.0  -20.0   1.0 1.0
#pragma parameter fr_center_x          "    Center X"                         0.0 -200.0 200.0 0.1
#pragma parameter fr_center_y          "    Center Y"                         0.0 -200.0 200.0 0.1

#pragma parameter all_nonono           "ALL:"                                0.0    0.0   1.0 1.0
#pragma parameter all_zoom             "    Zoom %"                        100.0   20.0 200.0 1.0

#pragma parameter bz_nonono            "BEZEL:"                              0.0   0.0   1.0  1.0
#pragma parameter bz_lights            "    Lights  [ OUT | ON ]"            1.0   0.0   1.0  1.0
#pragma parameter bz_shine_enable      "    Shine   [ OFF | ON ]"            1.0   0.0   1.0  1.0
#pragma parameter bz_ambient_enable    "    Ambient [ OFF | ON ]"            1.0   0.0   1.0  1.0
#pragma parameter bz_blur_iter         "    Reflection Quality/Performance"  5.0   5.0  32.0  1.0
#pragma parameter bz_ref_str           "    Reflection Strength"             0.25  0.0   1.0  0.01
#pragma parameter bz_inner_bezel_x     "    Bezel Inner Width"               0.1   0.0   1.0  0.001
#pragma parameter bz_inner_bezel_y     "    Bezel Inner Height"              0.1   0.0   1.0  0.001
#pragma parameter bz_middle_bezel_x    "    Bezel Middle Width"              0.2   0.0   1.0  0.001
#pragma parameter bz_middle_bezel_y    "    Bezel Middle Height"             0.2   0.0   1.0  0.001
#pragma parameter bz_outer_bezel_x     "    Bezel Outer Width"               0.3   0.0   1.0  0.001
#pragma parameter bz_outer_bezel_y     "    Bezel Outer Height"              0.3   0.0   1.0  0.001
#pragma parameter bz_transparent       "    Bezel Transparent [ OFF | ON ]"  0.0   0.0   1.0  1.0
#pragma parameter bz_outer_curve       "    Bezel Curvature   [ OFF | ON ]"  0.0   0.0   1.0  1.0
#pragma parameter bz_radius            "    Bezel Corner Radius"             0.05  0.005 1.0  0.01
#pragma parameter bz_center_x          "    Bezel Center X"                  0.0 -200.0 200.0 0.1
#pragma parameter bz_center_y          "    Bezel Center Y"                  0.0 -200.0 200.0 0.1
#pragma parameter bz_red               "    Bezel Color - Red"             128.0   0.0 255.0  1.0
#pragma parameter bz_green             "    Bezel Color - Green"           128.0   0.0 255.0  1.0
#pragma parameter bz_blue              "    Bezel Color - Blue"            128.0   0.0 255.0  1.0
#pragma parameter bz_ref_dist          "    Reflection Distance"             0.0  -0.6   0.6  0.01
#pragma parameter bz_shine             "    Shine Intensity"                 0.25  0.0   1.0  0.01
#pragma parameter bz_shine_size        "    Shine Size"                      0.75  0.0   1.0  0.01
#pragma parameter bz_ambient           "    Ambient Intensity"               0.15  0.0   1.0  0.01
#pragma parameter bz_ambient_size      "    Ambient Size"                    0.85  0.0   1.0  0.01
#pragma parameter bz_ang               "    Inflec. Point Angle"             1.0   0.0  20.0  0.01
#pragma parameter bz_pos               "    Inflec. Point Position"          0.0 -20.0  20.0  0.002

#pragma parameter border_nonono        "BORDER:"                             0.0  0.0 1.0 1.0
#pragma parameter ub_border_top        "    On top: [ Frame | Border ]"      0.0  0.0 1.0 1.0
#pragma parameter border_scale         "    Border Scale"                    1.0  0.5 5.0 0.002
#pragma parameter border_center_x      "    Border Center X"                 0.0 -0.5 0.5 0.001
#pragma parameter border_center_y      "    Border Center Y"                 0.0 -0.5 0.5 0.001
#pragma parameter border_mirror_y      "    Border Mirrored"                 0.0  0.0 1.0 1.0
#pragma parameter border_allow_rot     "    Border Rotation [ 0 <--> 270 ]"  0.0  0.0 3.0 1.0
#pragma parameter border_alpha         "    Border Alpha Over Content (BAOC)"0.0  0.0 1.0 0.01
#pragma parameter black_baoc           "    (BAOC) Emphasis on Content"      0.0  0.0 1.0 1.0
#pragma parameter border_weight        "    Border to Ambient-Light Weight"  0.5  0.0 1.0 0.05
#pragma parameter border_dimming       "    Border Dimming (Lights OUT)"     0.5  0.0 1.0 0.05
//#pragma parameter layer2_dimming       "    Layer2 Dimming (Lights OUT)"     0.5  0.0 1.0 0.05

#pragma parameter h_nonono             "HYLLIAN'S CURVATURE:"                1.0  0.0   1.0 1.0
#pragma parameter h_curvature          "    Curvature Toggle"                1.0  0.0   1.0 1.0
#pragma parameter h_shape              "    Shape [ Sphere | Cylinder ]"     0.0  0.0   1.0 1.0
#pragma parameter h_radius             "    Curvature Radius"                4.0  1.8  10.0 0.1
#pragma parameter h_cornersize         "    Corner Size"                     0.05 0.01  1.0 0.01
#pragma parameter h_cornersmooth       "    Corner Smoothness"               0.5  0.1   1.0 0.1
#pragma parameter h_x_tilt             "    Horizontal Tilt"                 0.0 -0.5 0.5 0.01
#pragma parameter h_y_tilt             "    Vertical Tilt"                   0.0 -0.5 0.5 0.01
#pragma parameter h_angle_x            "    Position X"                      0.0 -1.0   1.0 0.001
#pragma parameter h_angle_y            "    Position Y"                      0.0 -1.0   1.0 0.001
#pragma parameter h_overscan_x         "    Overscan X%"                   100.0 20.0 200.0 0.2
#pragma parameter h_overscan_y         "    Overscan Y%"                   100.0 20.0 200.0 0.2

#pragma parameter CN_NONONO            "CRT-NOBODY:"                     0.0  0.0   1.0 1.0
#pragma parameter CN_BEAM_MIN_WIDTH    "    Min Beam Width"              0.80 0.0   1.0 0.01
#pragma parameter CN_BEAM_MAX_WIDTH    "    Max Beam Width"              1.0  0.0   1.0 0.01
#pragma parameter CN_SCAN_SIZE         "    Scanlines Thickness"         0.86 0.0   1.0 0.01
#pragma parameter CN_BRIGHTBOOST       "    Brightness Boost"            1.2  0.5   1.5 0.01
#pragma parameter CN_PHOSPHOR_LAYOUT   "    Mask [1..6 Aperture, 7..10 Shadow, 11..14 Slot]" 1.0 0.0 15.0 1.0
#pragma parameter CN_MASK_STRENGTH     "    Mask Strength"               0.64 0.0   1.0 0.02
#pragma parameter CN_MONITOR_SUBPIXELS "    Monitor Subpixels Layout [ RGB | BGR ]" 0.0 0.0 1.0 1.0
#pragma parameter CN_VSCANLINES        "    Vertical Scanlines"          0.0  0.0   1.0 1.0
#pragma parameter CN_VIG_TOGGLE        "    Vignette Toggle"             0.0  0.0   1.0 1.0
#pragma parameter CN_VIG_BASE          "    Vignette Range"             16.0  2.0 100.0 2.0
#pragma parameter CN_VIG_EXP           "    Vignette Strength"           0.16 0.0   2.0 0.02
#pragma parameter CN_InputGamma        "    Input Gamma"                 2.4  0.0   4.0 0.1
#pragma parameter CN_OutputGamma       "    Output Gamma"                2.2  0.0   3.0 0.1

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
uniform COMPAT_PRECISION int Rotation;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;

COMPAT_VARYING vec2 uv;
COMPAT_VARYING vec2 border_uv;
COMPAT_VARYING vec2 bezel_uv;
COMPAT_VARYING vec4 intl_profile;
COMPAT_VARYING vec2 mask_size;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define OrigTexSize vec4(OrigTextureSize, 1.0 / OrigTextureSize)

#define ub_OutputSize     OutSize
#define ub_OriginalSize   OrigTexSize
#define ub_Rotation       Rotation

#define InputToTextureSizeRatio  (InputSize.xy / TextureSize.xy)


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float all_zoom;
uniform COMPAT_PRECISION float fr_aspect_x;
uniform COMPAT_PRECISION float fr_aspect_y;
uniform COMPAT_PRECISION float fr_zoom;
uniform COMPAT_PRECISION float fr_i_scaling;
uniform COMPAT_PRECISION float fr_i_scaling_fac;
uniform COMPAT_PRECISION float fr_center_x;
uniform COMPAT_PRECISION float fr_center_y;
uniform COMPAT_PRECISION float bz_center_x;
uniform COMPAT_PRECISION float bz_center_y;
uniform COMPAT_PRECISION float border_scale;
uniform COMPAT_PRECISION float border_center_x;
uniform COMPAT_PRECISION float border_center_y;
uniform COMPAT_PRECISION float border_mirror_y;
uniform COMPAT_PRECISION float border_allow_rot;
uniform COMPAT_PRECISION float h_curvature;
#endif

#define CN_OFFSET      0.5
#define CN_SCAN_OFFSET 0.0

vec2 get_rotated_size(vec2 x, int rotation) {
    if      (rotation == 0 || rotation == 2) return x;
    else                                     return x.yx;
}


vec2 get_rotated_vector(vec2 x, int rotation) {
    if      (rotation == 0) return x;
    else if (rotation == 1) return vec2(-x.y, x.x);
    else if (rotation == 2) return -x;
    else                    return vec2(x.y, -x.x);
}

// Use to unrotate coordinates.
// It expects coordinates centered at (0.5,0.5).
vec2 get_unrotated_coords(vec2 x, int rotation) {
    if      (rotation == 0) return x;
    else if (rotation == 1) return vec2(x.y, 1.0-x.x);
    else if (rotation == 2) return 1.0-x;
    else                    return vec2(1.0-x.y, x.x);
}

const vec2  middle         = vec2(0.5);

float is_rotated  = mod(float(ub_Rotation), 2.);

vec2  fr_center   = get_rotated_vector(vec2(fr_center_x, fr_center_y)/100.0, ub_Rotation);
float allzoom     = all_zoom/100.0;

vec2 OutputRotSize      = get_rotated_size(  ub_OutputSize.xy, ub_Rotation);
vec2 OriginalRotInvSize = get_rotated_size(ub_OriginalSize.zw, ub_Rotation);

vec2  int_ar            = vec2(fr_aspect_y / fr_aspect_x, 1.0);
vec2  rot_ar            = mix(int_ar, 1.0 / int_ar.yx, is_rotated);
float int_scale_factor  = max(floor(OutputRotSize.y * OriginalRotInvSize.y) + fr_i_scaling_fac-is_rotated, 1.0);
vec2  int_scale         = OutputRotSize.xy * OriginalRotInvSize.y * rot_ar / int_scale_factor;

vec2  float_scale       = OutputRotSize.x * fr_zoom * allzoom / (OutputRotSize.xy  * 100.0
                          * rot_ar);

vec2 fr_scale = get_rotated_size(mix(float_scale, 1.0/int_scale, fr_i_scaling), ub_Rotation);

vec2  border_pos = vec2(border_center_x, border_center_y);

vec2  bz_center   = get_rotated_vector(vec2(bz_center_x, bz_center_y)/100.0, ub_Rotation);



vec4 get_interlace_profile()
{
    vec4 int_p = vec4(SourceSize.y, SourceSize.w, CN_OFFSET, CN_SCAN_OFFSET);

    if ((InputSize.y > 288.5) && (InputSize.y < 576.5))
    {
        float field_offset = mod(FrameCount, 2.0);

        int_p.xy *= vec2(0.5, 2.0);
        int_p.zw += vec2(0.5)*vec2(field_offset - 0.5, field_offset);
    }

    return int_p;
}


void main()
{
    gl_Position = MVPMatrix * VertexCoord;

    vec2 Tex = TexCoord.xy / InputToTextureSizeRatio;

    vec2 diff    = Tex.xy * vec2(1.000001)  - middle;
    vTexCoord    = middle + diff/fr_scale  - fr_center;

    uv           = 2.0*vTexCoord - vec2(1.0);
    bezel_uv     = uv - 2.0*bz_center;

    intl_profile = get_interlace_profile();

    border_uv = get_unrotated_coords(get_unrotated_coords(Tex.xy, ub_Rotation), int(border_allow_rot));

    border_uv.y = mix(border_uv.y, 1.0-border_uv.y, border_mirror_y);
    border_uv = middle + (border_uv.xy - middle - border_pos) / (border_scale*allzoom);
    border_uv = border_uv.xy * vec2(1.000001);

    mask_size  = ub_OutputSize.xy * fr_scale * (1.0 - 0.5*h_curvature);
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
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
uniform COMPAT_PRECISION int Rotation;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform sampler2D Texture;
uniform sampler2D BORDER;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 uv;
COMPAT_VARYING vec2 border_uv;
COMPAT_VARYING vec2 bezel_uv;
COMPAT_VARYING vec4 intl_profile;
COMPAT_VARYING vec2 mask_size;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float all_zoom;
uniform COMPAT_PRECISION float fr_aspect_x;
uniform COMPAT_PRECISION float fr_aspect_y;
uniform COMPAT_PRECISION float fr_zoom;
uniform COMPAT_PRECISION float fr_i_scaling;
uniform COMPAT_PRECISION float fr_i_scaling_fac;
uniform COMPAT_PRECISION float fr_center_x;
uniform COMPAT_PRECISION float fr_center_y;
uniform COMPAT_PRECISION float bz_lights;
uniform COMPAT_PRECISION float bz_shine_enable;
uniform COMPAT_PRECISION float bz_shine;
uniform COMPAT_PRECISION float bz_shine_size;
uniform COMPAT_PRECISION float bz_ambient_enable;
uniform COMPAT_PRECISION float bz_blur_iter;
uniform COMPAT_PRECISION float bz_ambient;
uniform COMPAT_PRECISION float bz_ambient_size;
uniform COMPAT_PRECISION float bz_ref_str;
uniform COMPAT_PRECISION float bz_inner_bezel_x;
uniform COMPAT_PRECISION float bz_inner_bezel_y;
uniform COMPAT_PRECISION float bz_middle_bezel_x;
uniform COMPAT_PRECISION float bz_middle_bezel_y;
uniform COMPAT_PRECISION float bz_outer_bezel_x;
uniform COMPAT_PRECISION float bz_outer_bezel_y;
uniform COMPAT_PRECISION float bz_transparent;
uniform COMPAT_PRECISION float bz_outer_curve;
uniform COMPAT_PRECISION float bz_radius;
uniform COMPAT_PRECISION float bz_center_x;
uniform COMPAT_PRECISION float bz_center_y;
uniform COMPAT_PRECISION float bz_red;
uniform COMPAT_PRECISION float bz_green;
uniform COMPAT_PRECISION float bz_blue;
uniform COMPAT_PRECISION float bz_ref_dist;
uniform COMPAT_PRECISION float bz_ang;
uniform COMPAT_PRECISION float bz_pos;
uniform COMPAT_PRECISION float ub_border_top;
uniform COMPAT_PRECISION float border_scale;
uniform COMPAT_PRECISION float border_center_x;
uniform COMPAT_PRECISION float border_center_y;
uniform COMPAT_PRECISION float border_mirror_y;
uniform COMPAT_PRECISION float border_allow_rot;
uniform COMPAT_PRECISION float border_alpha;
uniform COMPAT_PRECISION float black_baoc;
uniform COMPAT_PRECISION float border_weight;
uniform COMPAT_PRECISION float border_dimming;
uniform COMPAT_PRECISION float h_curvature;
uniform COMPAT_PRECISION float h_shape;
uniform COMPAT_PRECISION float h_radius;
uniform COMPAT_PRECISION float h_cornersize;
uniform COMPAT_PRECISION float h_cornersmooth;
uniform COMPAT_PRECISION float h_x_tilt;
uniform COMPAT_PRECISION float h_y_tilt;
uniform COMPAT_PRECISION float h_angle_x;
uniform COMPAT_PRECISION float h_angle_y;
uniform COMPAT_PRECISION float h_overscan_x;
uniform COMPAT_PRECISION float h_overscan_y;
uniform COMPAT_PRECISION float CN_BEAM_MIN_WIDTH;
uniform COMPAT_PRECISION float CN_BEAM_MAX_WIDTH;
uniform COMPAT_PRECISION float CN_SCAN_SIZE;
uniform COMPAT_PRECISION float CN_BRIGHTBOOST;
uniform COMPAT_PRECISION float CN_PHOSPHOR_LAYOUT;
uniform COMPAT_PRECISION float CN_MASK_STRENGTH;
uniform COMPAT_PRECISION float CN_MONITOR_SUBPIXELS;
uniform COMPAT_PRECISION float CN_VSCANLINES;
uniform COMPAT_PRECISION float CN_VIG_TOGGLE;
uniform COMPAT_PRECISION float CN_VIG_BASE;
uniform COMPAT_PRECISION float CN_VIG_EXP;
uniform COMPAT_PRECISION float CN_InputGamma;
uniform COMPAT_PRECISION float CN_OutputGamma;
#else
#define all_zoom               100.0
#define fr_aspect_x              8.0  
#define fr_aspect_y              6.0  
#define fr_zoom                 50.0
#define fr_center_x              0.0
#define fr_center_y              0.0
#define bz_lights                1.0  
#define bz_shine_enable          1.0
#define bz_ambient_enable        1.0  
#define bz_blur_iter             5.0  
#define bz_ref_str               0.25  
#define bz_inner_bezel_x         0.1   
#define bz_inner_bezel_y         0.1   
#define bz_middle_bezel_x        0.2   
#define bz_middle_bezel_y        0.2   
#define bz_outer_bezel_x         0.3   
#define bz_outer_bezel_y         0.3   
#define bz_outer_curve           0.0 
#define bz_transparent           0.0 
#define bz_radius                0.05  
#define bz_red                  128.0  
#define bz_green                128.0  
#define bz_blue                 128.0  
#define bz_ref_dist               0.0
#define bz_shine                  0.25  
#define bz_shine_size             0.75  
#define bz_ambient                0.15  
#define bz_ambient_size           0.85  
#define bz_ang                    1.0   
#define bz_pos                    0.0
#define ub_border_top             0.0
#define border_scale              1.0
#define border_center_x           0.0
#define border_center_y           0.0
#define border_mirror_y           0.0
#define border_alpha              0.0
#define black_baoc                0.0
#define border_weight             0.5
#define border_dimming            0.5
#define h_curvature               1.0
#define h_shape                   0.0
#define h_radius                  4.0
#define h_cornersize              0.05
#define h_cornersmooth            0.5
#define h_angle_x                 0.0
#define h_angle_y                 0.0
#define h_overscan_x            100.0
#define h_overscan_y            100.0
#define CN_BEAM_MIN_WIDTH         0.80
#define CN_BEAM_MAX_WIDTH         1.0 
#define CN_SCAN_SIZE              0.86
#define CN_BRIGHTBOOST            1.2 
#define CN_PHOSPHOR_LAYOUT        1.0
#define CN_MASK_STRENGTH          0.64
#define CN_MONITOR_SUBPIXELS      0.0
#define CN_VSCANLINES             0.0
#define CN_VIG_TOGGLE             0.0
#define CN_VIG_BASE              16.0
#define CN_VIG_EXP                0.16
#define CN_InputGamma             2.4
#define CN_OutputGamma            2.2
#endif

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
//#define SourceSize vec4(InputSize, 1.0 / TextureSize) //It works this way only!
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define OrigTexSize vec4(OrigTextureSize, 1.0 / OrigTextureSize)

#define ub_OutputSize     OutSize
#define ub_OriginalSize   OrigTexSize
#define ub_Rotation       Rotation


#define InputToTextureSizeRatio (InputSize.xy / TextureSize.xy)

vec2 get_rotated_size(vec2 x, int rotation) {
    if      (rotation == 0 || rotation == 2) return x;
    else                                     return x.yx;
}


vec2 get_rotated_vector(vec2 x, int rotation) {
    if      (rotation == 0) return x;
    else if (rotation == 1) return vec2(-x.y, x.x);
    else if (rotation == 2) return -x;
    else                    return vec2(x.y, -x.x);
}


#define GAMMA_IN(color)     CN_BRIGHTBOOST*pow(color, vec3(CN_InputGamma))
#define GAMMA_OUT(color)    pow(color, vec3(1.0 / CN_OutputGamma))


#define PIX_SIZE    1.111111
#define CN_OFFSET      0.5
#define CN_SCAN_OFFSET 0.0

// Macros.
#define FIX(c) max(abs(c), 1e-5);
#define PI 3.141592653589


//#define R_BLUR_ITER 5
#define R_BLUR_SIZE 0.02

const float on  = 1.;
const float off = 0.;

const vec2  middle         = vec2(0.5);

vec2 OutputRotSize      = get_rotated_size(  ub_OutputSize.xy, ub_Rotation);
vec2 OriginalRotInvSize = get_rotated_size(ub_OriginalSize.zw, ub_Rotation);

vec2 overscan         = 100.0/(get_rotated_size(vec2(h_overscan_x, h_overscan_y), ub_Rotation));
vec2 content_position = 2.0*get_rotated_vector(vec2(h_angle_x, h_angle_y), ub_Rotation);

float r2           = h_radius * h_radius;
vec2  max_size     = vec2(sqrt( (r2 - 2.0) / (r2 - 1.0) ), 1.0);
vec2  aspect       = vec2(1.0, OutputRotSize.y/OutputRotSize.x);
float cornersize   = h_cornersize * min(aspect.x, aspect.y);
float cornersmooth = h_cornersmooth/100.0;
vec2  tilt         = h_radius*sin(get_rotated_vector(vec2(h_x_tilt, h_y_tilt), ub_Rotation));


float shine_size = (1.0 - bz_shine_size  );
float amb_size   = (1.0 - bz_ambient_size);

vec2  shine_position = get_rotated_vector(vec2(0.0, 1.0), ub_Rotation);
const float SMTH     = 0.004;
vec2  bz_shadow      = get_rotated_vector(vec2(0.0, -0.06), ub_Rotation);


vec3 BZ_COLOR = vec3(bz_red, bz_green, bz_blue)/255.0;

vec2 INN_BZ = get_rotated_size(vec2(bz_inner_bezel_x, bz_inner_bezel_y), ub_Rotation) + vec2(1.0);
vec2 MID_BZ = get_rotated_size(vec2(bz_middle_bezel_x, bz_middle_bezel_y), ub_Rotation) + INN_BZ;
vec2 OUT_BZ = get_rotated_size(vec2(bz_outer_bezel_x, bz_outer_bezel_y), ub_Rotation) + MID_BZ;

float cyl_shape = (1.0-bz_outer_curve)*h_shape*h_curvature;

float mb_aspect = (MID_BZ.y-INN_BZ.y)/(MID_BZ.x-INN_BZ.x);

float pix_sizex  = mix(PIX_SIZE, CN_SCAN_SIZE, CN_VSCANLINES);
float scan_sizey = mix(CN_SCAN_SIZE, PIX_SIZE, CN_VSCANLINES);

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


/* Mask code pasted from subpixel_masks.h. Masks 3 and 4 added. */
vec3 mask_weights(vec2 coord, float phosphor_layout){
   vec3 weights = vec3(1.,1.,1.);

   vec3 red     = vec3(off, off, on );
   vec3 green   = vec3(off, on,  off);
   vec3 blue    = vec3(on,  off, off);
   vec3 magenta = vec3(on,  off, on );
   vec3 yellow  = vec3(off, on,  on );
   vec3 cyan    = vec3(on,  on,  off);
   vec3 black   = vec3(off, off, off);
   vec3 white   = vec3(on,  on,  on );

   int w, z = 0;
   
   // This pattern is used by a few layouts, so we'll define it here
   vec3 aperture_classic = mix(magenta, green, floor(mod(coord.x, 2.0)));
   
   if(phosphor_layout == 0.) return weights;

   else if(phosphor_layout == 1.){
      // classic aperture for RGB panels; good for 1080p, too small for 4K+
      // aka aperture_1_2_bgr
      weights  = aperture_classic;
      return weights;
   }

   else if(phosphor_layout == 2.){
      // Classic RGB layout; good for 1080p and lower
      vec3 aperture1[3] = vec3[](red, green, blue);
//      vec3 bw3[3] = vec3[](black, yellow, blue);
      
      z = int(floor(mod(coord.x, 3.0)));
      
      weights = aperture1[z];
      return weights;
   }

   else if(phosphor_layout == 3.){
      // black and white aperture; good for weird subpixel layouts and low brightness; good for 1080p and lower
      vec3 aperture2[3] = vec3[](black, white, white);
      
      z = int(floor(mod(coord.x, 3.0)));
      
      weights = aperture2[z];
      return weights;
   }

   else if(phosphor_layout == 4.){
      // reduced TVL aperture for RGB panels. Good for 4k.
      // aperture_2_4_rgb
      
      vec3 aperture3[4] = vec3[](red, yellow, cyan, blue);
      
      w = int(floor(mod(coord.x, 4.0)));
      
      weights = aperture3[w];
      return weights;
   }
   

   else if(phosphor_layout == 5.){
      // black and white aperture; good for weird subpixel layouts and low brightness; good for 4k 
      vec3 aperture4[4] = vec3[](black, black, white, white);
      
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = aperture4[z];
      return weights;
   }


   else if(phosphor_layout == 6.){
      // aperture_1_4_rgb; good for simulating lower 
      vec3 aperture5[4] = vec3[](red, green, blue, black);
      
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = aperture5[z];
      return weights;
   }

   else if(phosphor_layout == 7.){
      // 2x2 shadow mask for RGB panels; good for 1080p, too small for 4K+
      // aka delta_1_2x1_bgr
      vec3 inverse_aperture = mix(green, magenta, floor(mod(coord.x, 2.0)));
      weights               = mix(aperture_classic, inverse_aperture, floor(mod(coord.y, 2.0)));
      return weights;
   }

   else if(phosphor_layout == 8.){
      // delta_2_4x1_rgb
      vec3 delta_2_1[4] = vec3[](red, yellow, cyan, blue);
      vec3 delta_2_2[4] = vec3[](cyan, blue, red, yellow);
      
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = (w == 1) ? delta_2_1[z] : delta_2_2[z];
      return weights;
   }

   else if(phosphor_layout == 9.){
      // delta_1_4x1_rgb; dunno why this is called 4x1 when it's obviously 4x2 /shrug
      vec3 delta_1_1[4] = vec3[](red, green, blue, black);
      vec3 delta_1_2[4] = vec3[](blue, black, red, green);
      
      w = int(floor(mod(coord.y, 2.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = (w == 1) ? delta_1_1[z] : delta_1_2[z];
      return weights;
   }
   
   else if(phosphor_layout == 10.){
      // delta_2_4x2_rgb
      vec3 delta_1[4] = vec3[](red, yellow, cyan, blue);
      vec3 delta_2[4] = vec3[](red, yellow, cyan, blue);
      vec3 delta_3[4] = vec3[](cyan, blue, red, yellow);
      vec3 delta_4[4] = vec3[](cyan, blue, red, yellow);
     
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = (w == 1) ? delta_1[z] : (w == 2) ? delta_2[z] : (w == 3) ? delta_3[z] : delta_4[z];
      return weights;
   }

   else if(phosphor_layout == 11.){
      // slot mask for RGB panels; looks okay at 1080p, looks better at 4K
      vec3 slotmask_RBG_x1[6] = vec3[](red, green, blue,    red, green, blue);
      vec3 slotmask_RBG_x2[6] = vec3[](red, green, blue,  black, black, black);
      vec3 slotmask_RBG_x3[6] = vec3[](red, green, blue,    red, green, blue);
      vec3 slotmask_RBG_x4[6] = vec3[](black, black, black, red, green, blue);
      
      // find the vertical index
      w = int(floor(mod(coord.y, 4.0)));
      
      // find the horizontal index
      z = int(floor(mod(coord.x, 6.0)));

      weights = (w == 1) ? slotmask_RBG_x1[z] : (w == 2) ? slotmask_RBG_x2[z] : (w == 3) ? slotmask_RBG_x3[z] : slotmask_RBG_x4[z];
      return weights;
   }

   else if(phosphor_layout == 12.){
      // slot mask for RGB panels; looks okay at 1080p, looks better at 4K
      vec3 slotmask_RBG_x1[6] = vec3[](black,  white, black,   black,  white, black);
      vec3 slotmask_RBG_x2[6] = vec3[](black,  white, black,  black, black, black);
      vec3 slotmask_RBG_x3[6] = vec3[](black,  white, black,  black,  white, black);
      vec3 slotmask_RBG_x4[6] = vec3[](black, black, black,  black,  white, black);
      
      // find the vertical index
      w = int(floor(mod(coord.y, 4.0)));
      
      // find the horizontal index
      z = int(floor(mod(coord.x, 6.0)));

      weights = (w == 1) ? slotmask_RBG_x1[z] : (w == 2) ? slotmask_RBG_x2[z] : (w == 3) ? slotmask_RBG_x3[z] : slotmask_RBG_x4[z];
      return weights;
   }

   else if(phosphor_layout == 13.){
      // based on MajorPainInTheCactus' HDR slot mask
      vec3 slotmask_RBG_x1[8] = vec3[](red,   green, blue,  black, red,   green, blue,  black);
      vec3 slotmask_RBG_x2[8] = vec3[](red,   green, blue,  black, black, black, black, black);
      vec3 slotmask_RBG_x3[8] = vec3[](red,   green, blue,  black, red,   green, blue,  black);
      vec3 slotmask_RBG_x4[8] = vec3[](black, black, black, black, red,   green, blue,  black);
      
      // find the vertical index
      w = int(floor(mod(coord.y, 4.0)));
      
      // find the horizontal index
      z = int(floor(mod(coord.x, 8.0)));

      weights = (w == 1) ? slotmask_RBG_x1[z] : (w == 2) ? slotmask_RBG_x2[z] : (w == 3) ? slotmask_RBG_x3[z] : slotmask_RBG_x4[z];
      return weights;
   }

   else if(phosphor_layout == 14.){
      // same as above but for RGB panels
      vec3 slot_1[10] = vec3[](red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue );
      vec3 slot_2[10] = vec3[](black, green,  green, blue,  blue,  red,   red,    black, black, black);
      vec3 slot_3[10] = vec3[](red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue );
      vec3 slot_4[10] = vec3[](red,   red,    black, black, black, black, green,  green, blue,  blue );
      
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 10.0)));
      
      weights = (w == 1) ? slot_1[z] : (w == 2) ? slot_2[z] : (w == 3) ? slot_3[z] : slot_4[z];
      return weights;
   }
   
   else if(phosphor_layout == 15.){
      // slot_3_7x6_rgb
      vec3 slot_1[14] = vec3[](red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue);
      vec3 slot_2[14] = vec3[](red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue);
      vec3 slot_3[14] = vec3[](red,   red,   yellow, green, cyan,  blue,  blue,  black, black, black,  black,  black, black, black);
      vec3 slot_4[14] = vec3[](red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue);
      vec3 slot_5[14] = vec3[](red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue);
      vec3 slot_6[14] = vec3[](black, black, black,  black, black, black, black, black, red,   red,    yellow, green, cyan,  blue);
      
      w = int(floor(mod(coord.y, 6.0)));
      z = int(floor(mod(coord.x, 14.0)));
      
      weights = (w == 1) ? slot_1[z] : (w == 2) ? slot_2[z] : (w == 3) ? slot_3[z] : (w == 4) ? slot_4[z] : (w == 5) ? slot_5[z] : slot_6[z];
      return weights;
   }

   else return weights;
}

vec2 wgt(vec2 size)
{
   size = clamp(size, -1.0, 1.0);
   size = vec2(1.0) - size * size;
   return size * size * size;
}

float vignette(vec2 uv)
{
    float vignette = uv.x * uv.y * ( 1.0 - uv.x ) * ( 1.0 - uv.y );

    return clamp( pow( CN_VIG_BASE * vignette, CN_VIG_EXP ), 0.0, 1.0 );
}

// Fast when two first are constants.
float fsmoothstep(float a, float b, float x) {
    return clamp(x*(1.0/(b - a)) - (a/(b - a)), 0.0, 1.0);
}

vec2 fsmoothstep(vec2 a, vec2 b, vec2 x) {
    return clamp(x*(1.0/(b - a)) - (a/(b - a)), 0.0, 1.0);
}

float h_corner(vec2 uv)
{
    vec2  d          = abs((2.0*uv - vec2(1.0)) * aspect) - (aspect - vec2(cornersize));
    float borderline = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - cornersize;

    return fsmoothstep(cornersmooth, -cornersmooth, borderline);
}


vec2 h_warp(vec2 uv)
{
    vec2 uvt = uv + tilt;

    vec2 cylinder = sqrt( (r2 - uvt.x*uvt.x) / (r2 - 2.0*uvt.x*uvt.x) )*max_size;
    float sphere   =  sqrt( (r2 - 1.0) / ( r2 - dot(uvt, uvt) ) );

    uv *= mix(vec2(sphere), cylinder, h_shape);

    return uv;
}

// uv must be in the interval (-1.0, 1.0)
float RoundedRect(vec2 uv, vec2 size, float radius, vec2 blur)
{
    radius = radius * min(size.x, size.y);
    vec2 d = (abs(uv) - (size - vec2(radius)));
    float shape = length(max(d, vec2(0.0))) + min(max(d.x, d.y),  0.0) - radius;

    return fsmoothstep(-blur.x, blur.y, shape);
}

// uv must be in the interval (-1.0, 1.0)
vec2 RoundedRectVec(vec4 uv, vec4 size, vec2 radius, vec2 blur)
{
    radius = radius * min(size.xz, size.yw);
    vec4 d = (abs(uv) - (size-radius.xxyy));
    vec4 d4 = max(d, vec4(0.0));

    vec2 shape = vec2(length(d4.xy), length(d4.zw)) + min(max(d.xz, d.yw),  vec2(0.0)) - radius;

    return fsmoothstep(-blur, blur, shape);
}


// Calculate distance to get reflection coords
vec2 ReflectionCoords(vec2 uv, float r)
{
    vec2 ref_coord;
    vec2 size = vec2(1.0-r);

    vec2 maxs = uv - max(vec2(0.0), 2.0*(uv - size));
    vec2 mins = uv - min(vec2(0.0), 2.0*(uv + size));

    ref_coord.x = (uv.x >= 0.0) ? maxs.x : mins.x;
    ref_coord.y = (uv.y >= 0.0) ? maxs.y : mins.y;

    return 0.5*ref_coord + vec2(0.5);
}

vec3 get_content(vec2 vTex, vec2 uv)
{
    vec4  TexSize     = vec4(SourceSize.x, intl_profile.x, SourceSize.z, intl_profile.y);
    vec2  cn_offset   = vec2(CN_OFFSET     , intl_profile.z);
    vec2  scan_off    = vec2(CN_SCAN_OFFSET, intl_profile.w);

    vec2 pix_coord = vTex * TexSize.xy - scan_off;
    vec2 tc        = (floor(pix_coord)   + cn_offset) * TexSize.zw; // tc  = texel coord
    vec2 pos       =  fract(pix_coord)   - cn_offset; // pos = pixel position
    vec2 dir       =  sign(pos); // dir = pixel direction
    pos            =   abs(pos);

    vec2 g1 = dir * vec2(TexSize.z,  0);
    vec2 g2 = dir * vec2( 0, TexSize.w);

    vec3 A = clamp(GAMMA_IN(COMPAT_TEXTURE(Source, tc       ).xyz), 0.0, 1.0);
    vec3 B = clamp(GAMMA_IN(COMPAT_TEXTURE(Source, tc +g1   ).xyz), 0.0, 1.0);
    vec3 C = clamp(GAMMA_IN(COMPAT_TEXTURE(Source, tc +g2   ).xyz), 0.0, 1.0);
    vec3 D = clamp(GAMMA_IN(COMPAT_TEXTURE(Source, tc +g1+g2).xyz), 0.0, 1.0);

    vec2 wx = wgt(vec2(pos.x, 1.0-pos.x) / pix_sizex);

    vec3 cc0 = (A*wx.x + B*wx.y);
    vec3 cc1 = (C*wx.x + D*wx.y);

    float c0max = max(cc0.r, max(cc0.g, cc0.b));
    float c1max = max(cc1.r, max(cc1.g, cc1.b));

    float lum0  = mix(CN_BEAM_MIN_WIDTH, CN_BEAM_MAX_WIDTH, c0max);
    float lum1  = mix(CN_BEAM_MIN_WIDTH, CN_BEAM_MAX_WIDTH, c1max);

     vec2  ssy = vec2(scan_sizey);
     ssy.x *= (CN_VSCANLINES > 0.5 ? 1.0 : lum0);
     ssy.y *= (CN_VSCANLINES > 0.5 ? 1.0 : lum1);

    float vig = (CN_VIG_TOGGLE > 0.5) ? vignette(vTex) : 1.0;

    vec2 wy = wgt(vec2(pos.y, 1.0-pos.y) / ssy);

    vec3  content = vig * (cc0 * wy.x + cc1 * wy.y);

// Mask

//    vec2 mask_coords = mix(vTexCoord, uv, global.h_curvature) * mask_size;
    vec2 mask_coords = mix(vTex, uv, h_curvature) * mask_size;

    mask_coords = mix(mask_coords.xy, mask_coords.yx, CN_VSCANLINES);
    vec3 mask_wgts = mask_weights(mask_coords, CN_PHOSPHOR_LAYOUT);
    mask_wgts = clamp(mask_wgts + vec3(1.0-CN_MASK_STRENGTH), 0.0, 1.0);
    mask_wgts = (CN_MONITOR_SUBPIXELS > 0.5) ? mask_wgts.bgr : mask_wgts;

    return GAMMA_OUT(content) * GAMMA_OUT(mask_wgts);
}

void main()
{

// Bezels and border begins...

    vec2 uvFC = mix(uv, h_warp(uv), h_curvature); // Frame content area
    vec2 uvIB = uvFC;                                    // Inner bezel area
    vec2 uvMB = mix(bezel_uv, h_warp(bezel_uv), bz_outer_curve);    // In Between bezel area
    vec2 uvOB = bezel_uv;                                    // Outer bezel area

    uvFC = uvFC*overscan - content_position;

    vec2 area_out = RoundedRectVec(vec4(uvMB, uvOB), vec4(MID_BZ, OUT_BZ), vec2(bz_radius), vec2(SMTH, -SMTH));

    vec4 border = COMPAT_TEXTURE(BORDER, border_uv);

    if (bz_lights < 0.5){
	border.rgb *= border_dimming;
    }

    if (area_out.y < 1.0) {FragColor = vec4(border.rgb, 1.0); return;}

// Bezels pause...

// Content frame begins... (put content shader code here)

    vec2 fcTex = (0.5*uvFC + vec2(0.5)) * InputToTextureSizeRatio;

    float cval = h_corner(fcTex)  *  step(0.0, fract(fcTex.y));  // Discard off limit pixels

// Call to content shader here.
    vec3 content = get_content(fcTex, uv) * vec3(cval);

// Bezels continue...

    vec2 area_inn = RoundedRectVec(vec4(uvIB, uvMB), vec4(INN_BZ, MID_BZ), vec2(bz_radius), vec2(SMTH, -SMTH));

    content = mix(content, mix(content.rgb, border.rgb, border.a), ub_border_top);

    float ambient = bz_ambient;
    float ambient_out = 1.4*bz_ambient;
    vec3 shine_content = vec3(0.0);
    vec3 ambient_content = vec3(0.0);

    if (bz_lights == 1.0)
    {
        vec2 rct = RoundedRectVec(vec4(uvIB + bz_shadow, uvIB), INN_BZ.xyxy, vec2(bz_radius), vec2(-SMTH/2.0, -SMTH));
    	shine_content += max(0.0, bz_shine - shine_size*length(uvIB + shine_position)) * rct.x; // Glass Shine
	ambient_content += max(0.0, ambient - amb_size*length(uvIB)) * rct.y; // Ambient Light
    }
    else
    {
        // Ambient Light
	ambient_content += max(0.0, ambient - amb_size*length(uvIB)) * RoundedRect(uvIB, INN_BZ, bz_radius, -vec2(SMTH));
    }

    vec3  frame_content = content + (bz_ambient_enable*ambient_content + bz_shine_enable*shine_content);

   if (area_inn.x < 0.5)
    {
        vec3 content_emphasis = clamp(border.rgb*border.a * border_alpha + frame_content, 0.0, 1.0);

        vec3 baoc = mix(frame_content, border.rgb, border_alpha);

        FragColor = vec4(mix(baoc, content_emphasis, black_baoc), 1.0);

        return;
    }

    float bezel_inner_area = area_inn.x * area_inn.y;
    float bezel_outer_area = area_out.x * area_out.y;

    vec3 bezels = vec3(0.0);

    // Inner Bezel Reflection Coords
    vec2 uvR = ReflectionCoords(uvFC, bz_ref_dist) * InputToTextureSizeRatio;

    vec3 Blur = vec3(0.0);

    for(int i = 0; i < clamp(bz_blur_iter, 5.0, 32.0); i++) // clamp needed to fix D3D compatibility
        Blur += COMPAT_TEXTURE(Source, uvR + (vec2(rand(uvR+float(i)),rand(uvR+float(i)+0.00625))-vec2(0.5))*R_BLUR_SIZE).rgb;

    Blur /= bz_blur_iter;

    // Blur in cheap linear gamma (2.0)
    Blur = sqrt(Blur);

    Blur *= ((1.0 - fsmoothstep(0.8, 1.0, abs(uvFC.x))*fsmoothstep(0.8, 1.0, abs(uvFC.y))) * bz_ref_str );

    // This is a hack. Still needs analytical solution.
    vec2 IB = abs(uvIB);
    IB = vec2(IB.x*mb_aspect, IB.y - MID_BZ.y + mb_aspect*MID_BZ.x);
    float corner = fsmoothstep(-bz_radius, bz_radius, IB.y - mix(IB.x, bz_ang*IB.x + bz_pos, cyl_shape));

    if (bz_transparent > 0.5) BZ_COLOR = border.rgb;

    if (bz_lights == 1.0)
    {
        // Bezel texture 
        vec3 bz_color = clamp(BZ_COLOR + rand(uvIB)*0.0125-0.00625, 0.0, 1.0) + 
                                         rand(uvIB+vec2(1.0))*0.0625 * cos(0.75*PI*uvIB.x);
        // Inner Bezel and Reflections
        bezels += (bz_color + Blur) * bezel_inner_area * (0.25*(1.0 + corner));

    	// Outer Bezel
   	bezels +=  mix(bz_color, BZ_COLOR, bz_transparent) * bezel_outer_area;

    }
    else
    {
        // Middle Bezel
        bezels -= (BZ_COLOR ) * RoundedRect(uvOB, MID_BZ, bz_radius, vec2(SMTH*2.0, -SMTH*10.0)) * 
                                RoundedRect(uvOB, MID_BZ, bz_radius, vec2(SMTH*2.0, -SMTH* 2.0));

        // Inner Bezel and Reflections
        bezels += (BZ_COLOR + Blur) * bezel_inner_area * (ambient_out * (0.7 + 0.35*(1.0 - corner)) + Blur);

        // Outer Bezel
        bezels += BZ_COLOR * bezel_outer_area * mix(ambient_out, 1.0, bz_transparent);

    }

    bezels = mix(bezels+border.rgb*bezel_inner_area*bz_transparent, mix(bezels, border.rgb, border.a), ub_border_top);

    FragColor = vec4(bezels, 1.0);
} 
#endif


