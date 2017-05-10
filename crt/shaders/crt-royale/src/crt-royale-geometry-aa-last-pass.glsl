#version 130

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter crt_gamma "crt_gamma" 2.5 1.0 5.0 0.025
#pragma parameter lcd_gamma "lcd_gamma" 2.2 1.0 5.0 0.025
#pragma parameter levels_contrast "levels_contrast" 1.0 0.0 4.0 0.015625
#pragma parameter halation_weight "halation_weight" 0.0 0.0 1.0 0.005
#pragma parameter diffusion_weight "diffusion_weight" 0.075 0.0 1.0 0.005
#pragma parameter bloom_underestimate_levels "bloom_underestimate_levels" 0.8 0.0 5.0 0.01
#pragma parameter bloom_excess "bloom_excess" 0.0 0.0 1.0 0.005
#pragma parameter beam_min_sigma "beam_min_sigma" 0.02 0.005 1.0 0.005
#pragma parameter beam_max_sigma "beam_max_sigma" 0.3 0.005 1.0 0.005
#pragma parameter beam_spot_power "beam_spot_power" 0.33 0.01 16.0 0.01
#pragma parameter beam_min_shape "beam_min_shape" 2.0 2.0 32.0 0.1
#pragma parameter beam_max_shape "beam_max_shape" 4.0 2.0 32.0 0.1
#pragma parameter beam_shape_power "beam_shape_power" 0.25 0.01 16.0 0.01
#pragma parameter beam_horiz_filter "beam_horiz_filter" 0.0 0.0 2.0 1.0
#pragma parameter beam_horiz_sigma "beam_horiz_sigma" 0.35 0.0 0.67 0.005
#pragma parameter beam_horiz_linear_rgb_weight "beam_horiz_linear_rgb_weight" 1.0 0.0 1.0 0.01
#pragma parameter convergence_offset_x_r "convergence_offset_x_r" 0.0 -4.0 4.0 0.05
#pragma parameter convergence_offset_x_g "convergence_offset_x_g" 0.0 -4.0 4.0 0.05
#pragma parameter convergence_offset_x_b "convergence_offset_x_b" 0.0 -4.0 4.0 0.05
#pragma parameter convergence_offset_y_r "convergence_offset_y_r" 0.0 -2.0 2.0 0.05
#pragma parameter convergence_offset_y_g "convergence_offset_y_g" 0.0 -2.0 2.0 0.05
#pragma parameter convergence_offset_y_b "convergence_offset_y_b" 0.0 -2.0 2.0 0.05
#pragma parameter mask_type "mask_type" 1.0 0.0 2.0 1.0
#pragma parameter mask_sample_mode_desired "mask_sample_mode" 1.0 0.0 2.0 1.0   //  Consider blocking mode 2.
#pragma parameter mask_specify_num_triads "mask_specify_num_triads" 0.0 0.0 1.0 1.0
#pragma parameter mask_triad_size_desired "mask_triad_size_desired" 3.0 1.0 18.0 0.125
#pragma parameter mask_num_triads_desired "mask_num_triads_desired" 480.0 342.0 1920.0 1.0
#pragma parameter aa_subpixel_r_offset_x_runtime "aa_subpixel_r_offset_x" -0.333333333 -0.333333333 0.333333333 0.333333333
#pragma parameter aa_subpixel_r_offset_y_runtime "aa_subpixel_r_offset_y" 0.0 -0.333333333 0.333333333 0.333333333
#pragma parameter aa_cubic_c "antialias_cubic_sharpness" 0.5 0.0 4.0 0.015625
#pragma parameter aa_gauss_sigma "antialias_gauss_sigma" 0.5 0.0625 1.0 0.015625
//#pragma parameter geom_mode_runtime "geom_mode" 0.0 0.0 3.0 1.0  //  commented out because it's broken :(
#pragma parameter geom_radius "geom_radius" 2.0 0.16 1024.0 0.1
#pragma parameter geom_view_dist "geom_view_dist" 2.0 0.5 1024.0 0.25
#pragma parameter geom_tilt_angle_x "geom_tilt_angle_x" 0.0 -3.14159265 3.14159265 0.017453292519943295
#pragma parameter geom_tilt_angle_y "geom_tilt_angle_y" 0.0 -3.14159265 3.14159265 0.017453292519943295
#pragma parameter geom_aspect_ratio_x "geom_aspect_ratio_x" 432.0 1.0 512.0 1.0
#pragma parameter geom_aspect_ratio_y "geom_aspect_ratio_y" 329.0 1.0 512.0 1.0
#pragma parameter geom_overscan_x "geom_overscan_x" 1.0 0.00390625 4.0 0.00390625
#pragma parameter geom_overscan_y "geom_overscan_y" 1.0 0.00390625 4.0 0.00390625
#pragma parameter border_size "border_size" 0.015 0.0000001 0.5 0.005
#pragma parameter border_darkness "border_darkness" 2.0 0.0 16.0 0.0625
#pragma parameter border_compress "border_compress" 2.5 1.0 64.0 0.0625
#pragma parameter interlace_bff "interlace_bff" 0.0 0.0 1.0 1.0
#pragma parameter interlace_1080i "interlace_1080i" 0.0 0.0 1.0 1.0
//  Disable runtime shader params if the user doesn't explicitly want them.
//  Static constants will be defined in place of uniforms of the same name.
//#ifndef RUNTIME_SHADER_PARAMS_ENABLE
//    #undef PARAMETER_UNIFORM
//#endif

//  Bind option names to shader parameter uniforms or static constants.
#ifdef PARAMETER_UNIFORM
    uniform float crt_gamma;
    uniform float lcd_gamma;
    uniform float levels_contrast;
    uniform float halation_weight;
    uniform float diffusion_weight;
    uniform float bloom_underestimate_levels;
    uniform float bloom_excess;
    uniform float beam_min_sigma;
    uniform float beam_max_sigma;
    uniform float beam_spot_power;
    uniform float beam_min_shape;
    uniform float beam_max_shape;
    uniform float beam_shape_power;
    uniform float beam_horiz_sigma;
//    #ifdef RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE
        uniform float beam_horiz_filter;
        uniform float beam_horiz_linear_rgb_weight;
//    #else
//        float beam_horiz_filter = clamp(beam_horiz_filter_static, 0.0, 2.0);
//        float beam_horiz_linear_rgb_weight = clamp(beam_horiz_linear_rgb_weight_static, 0.0, 1.0);
//    #endif
    uniform float convergence_offset_x_r;
    uniform float convergence_offset_x_g;
    uniform float convergence_offset_x_b;
    uniform float convergence_offset_y_r;
    uniform float convergence_offset_y_g;
    uniform float convergence_offset_y_b;
//    #ifdef RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
        uniform float mask_type;
//    #else
//        float mask_type = clamp(mask_type_static, 0.0, 2.0);
//    #endif
    uniform float mask_sample_mode_desired;
    uniform float mask_specify_num_triads;
    uniform float mask_triad_size_desired;
    uniform float mask_num_triads_desired;
    uniform float aa_subpixel_r_offset_x_runtime;
    uniform float aa_subpixel_r_offset_y_runtime;
//    #ifdef RUNTIME_ANTIALIAS_WEIGHTS
        uniform float aa_cubic_c;
        uniform float aa_gauss_sigma;
//    #else
//        float aa_cubic_c = aa_cubic_c_static;                              //  Clamp to [0, 4]?
//        float aa_gauss_sigma = max(FIX_ZERO(0.0), aa_gauss_sigma_static);  //  Clamp to [FIXZERO(0), 1]?
//    #endif
    uniform float geom_mode_runtime;
    uniform float geom_radius;
    uniform float geom_view_dist;
    uniform float geom_tilt_angle_x;
    uniform float geom_tilt_angle_y;
    uniform float geom_aspect_ratio_x;
    uniform float geom_aspect_ratio_y;
    uniform float geom_overscan_x;
    uniform float geom_overscan_y;
    uniform float border_size;
    uniform float border_darkness;
    uniform float border_compress;
    uniform float interlace_bff;
    uniform float interlace_1080i;
#else
    //  Use constants from user-settings.h, and limit ranges appropriately:
    #define crt_gamma max(0.0, crt_gamma_static);
    #define lcd_gamma max(0.0, lcd_gamma_static);
    #define levels_contrast clamp(levels_contrast_static, 0.0, 4.0);
    #define halation_weight clamp(halation_weight_static, 0.0, 1.0);
    #define diffusion_weight clamp(diffusion_weight_static, 0.0, 1.0);
    #define bloom_underestimate_levels max(FIX_ZERO(0.0), bloom_underestimate_levels_static);
    #define bloom_excess clamp(bloom_excess_static, 0.0, 1.0);
    #define beam_min_sigma max(FIX_ZERO(0.0), beam_min_sigma_static);
    #define beam_max_sigma max(beam_min_sigma, beam_max_sigma_static);
    #define beam_spot_power max(beam_spot_power_static, 0.0);
    #define beam_min_shape max(2.0, beam_min_shape_static);
    #define beam_max_shape max(beam_min_shape, beam_max_shape_static);
    #define beam_shape_power max(0.0, beam_shape_power_static);
    #define beam_horiz_filter clamp(beam_horiz_filter_static, 0.0, 2.0);
    #define beam_horiz_sigma max(FIX_ZERO(0.0), beam_horiz_sigma_static);
    #define beam_horiz_linear_rgb_weight clamp(beam_horiz_linear_rgb_weight_static, 0.0, 1.0);
    //  Unpack vector elements to match scalar uniforms:
    #define convergence_offset_x_r clamp(convergence_offsets_r_static.x, -4.0, 4.0);
    #define convergence_offset_x_g clamp(convergence_offsets_g_static.x, -4.0, 4.0);
    #define convergence_offset_x_b clamp(convergence_offsets_b_static.x, -4.0, 4.0);
    #define convergence_offset_y_r clamp(convergence_offsets_r_static.y, -4.0, 4.0);
    #define convergence_offset_y_g clamp(convergence_offsets_g_static.y, -4.0, 4.0);
    #define convergence_offset_y_b clamp(convergence_offsets_b_static.y, -4.0, 4.0);
    #define mask_type clamp(mask_type_static, 0.0, 2.0);
    #define mask_sample_mode_desired clamp(mask_sample_mode_static, 0.0, 2.0);
    #define mask_specify_num_triads clamp(mask_specify_num_triads_static, 0.0, 1.0);
    #define mask_triad_size_desired clamp(mask_triad_size_desired_static, 1.0, 18.0);
    #define mask_num_triads_desired clamp(mask_num_triads_desired_static, 342.0, 1920.0);
    #define aa_subpixel_r_offset_x_runtime clamp(aa_subpixel_r_offset_static.x, -0.5, 0.5);
    #define aa_subpixel_r_offset_y_runtime clamp(aa_subpixel_r_offset_static.y, -0.5, 0.5);
    #define aa_cubic_c aa_cubic_c_static;                              //  Clamp to [0, 4]?
    #define aa_gauss_sigma max(FIX_ZERO(0.0), aa_gauss_sigma_static);  //  Clamp to [FIXZERO(0), 1]?
    #define geom_mode_runtime clamp(geom_mode_static, 0.0, 3.0);
    #define geom_radius max(1.0/(2.0*pi), geom_radius_static);         //  Clamp to [1/(2*pi), 1024]?
    #define geom_view_dist max(0.5, geom_view_dist_static);            //  Clamp to [0.5, 1024]?
    #define geom_tilt_angle_x clamp(geom_tilt_angle_static.x, -pi, pi);
    #define geom_tilt_angle_y clamp(geom_tilt_angle_static.y, -pi, pi);
    #define geom_aspect_ratio_x geom_aspect_ratio_static;              //  Force >= 1?
    #define geom_aspect_ratio_y 1.0;
    #define geom_overscan_x max(FIX_ZERO(0.0), geom_overscan_static.x);
    #define geom_overscan_y max(FIX_ZERO(0.0), geom_overscan_static.y);
    #define border_size clamp(border_size_static, 0.0, 0.5);           //  0.5 reaches to image center
    #define border_darkness max(0.0, border_darkness_static);
    #define border_compress max(1.0, border_compress_static);          //  < 1.0 darkens whole image
    #define interlace_bff float(interlace_bff_static);
    #define interlace_1080i float(interlace_1080i_static);
#endif

/////////////////////////////  SETTINGS MANAGEMENT  ////////////////////////////

//  PASS SETTINGS:
//  gamma-management.h needs to know what kind of pipeline we're using and
//  what pass this is in that pipeline.  This will become obsolete if/when we
//  can #define things like this in the preset file.
#define LAST_PASS
#define SIMULATE_CRT_ON_LCD

//////////////////////////////////  INCLUDES  //////////////////////////////////

#ifndef USER_SETTINGS_H
#define USER_SETTINGS_H

/////////////////////////////  DRIVER CAPABILITIES  ////////////////////////////

//  The Cg compiler uses different "profiles" with different capabilities.
//  This shader requires a Cg compilation profile >= arbfp1, but a few options
//  require higher profiles like fp30 or fp40.  The shader can't detect profile
//  or driver capabilities, so instead you must comment or uncomment the lines
//  below with "//" before "#define."  Disable an option if you get compilation
//  errors resembling those listed.  Generally speaking, all of these options
//  will run on nVidia cards, but only DRIVERS_ALLOW_TEX2DBIAS (if that) is
//  likely to run on ATI/AMD, due to the Cg compiler's profile limitations.

//  Derivatives: Unsupported on fp20, ps_1_1, ps_1_2, ps_1_3, and arbfp1.
//  Among other things, derivatives help us fix anisotropic filtering artifacts
//  with curved manually tiled phosphor mask coords.  Related errors:
//  error C3004: function "vec2 ddx(vec2);" not supported in this profile
//  error C3004: function "vec2 ddy(vec2);" not supported in this profile
    //#define DRIVERS_ALLOW_DERIVATIVES

//  Fine derivatives: Unsupported on older ATI cards.
//  Fine derivatives enable 2x2 fragment block communication, letting us perform
//  fast single-pass blur operations.  If your card uses coarse derivatives and
//  these are enabled, blurs could look broken.  Derivatives are a prerequisite.
    #ifdef DRIVERS_ALLOW_DERIVATIVES
        #define DRIVERS_ALLOW_FINE_DERIVATIVES
    #endif

//  Dynamic looping: Requires an fp30 or newer profile.
//  This makes phosphor mask resampling faster in some cases.  Related errors:
//  error C5013: profile does not support "for" statements and "for" could not
//  be unrolled
    //#define DRIVERS_ALLOW_DYNAMIC_BRANCHES

//  Without DRIVERS_ALLOW_DYNAMIC_BRANCHES, we need to use unrollable loops.
//  Using one static loop avoids overhead if the user is right, but if the user
//  is wrong (loops are allowed), breaking a loop into if-blocked pieces with a
//  binary search can potentially save some iterations.  However, it may fail:
//  error C6001: Temporary register limit of 32 exceeded; 35 registers
//  needed to compile program
    //#define ACCOMODATE_POSSIBLE_DYNAMIC_LOOPS

//  tex2Dlod: Requires an fp40 or newer profile.  This can be used to disable
//  anisotropic filtering, thereby fixing related artifacts.  Related errors:
//  error C3004: function "vec4 tex2Dlod(sampler2D, vec4);" not supported in
//  this profile
    //#define DRIVERS_ALLOW_TEX2DLOD

//  tex2Dbias: Requires an fp30 or newer profile.  This can be used to alleviate
//  artifacts from anisotropic filtering and mipmapping.  Related errors:
//  error C3004: function "vec4 tex2Dbias(sampler2D, vec4);" not supported
//  in this profile
    //#define DRIVERS_ALLOW_TEX2DBIAS

//  Integrated graphics compatibility: Integrated graphics like Intel HD 4000
//  impose stricter limitations on register counts and instructions.  Enable
//  INTEGRATED_GRAPHICS_COMPATIBILITY_MODE if you still see error C6001 or:
//  error C6002: Instruction limit of 1024 exceeded: 1523 instructions needed
//  to compile program.
//  Enabling integrated graphics compatibility mode will automatically disable:
//  1.) PHOSPHOR_MASK_MANUALLY_RESIZE: The phosphor mask will be softer.
//      (This may be reenabled in a later release.)
//  2.) RUNTIME_GEOMETRY_MODE
//  3.) The high-quality 4x4 Gaussian resize for the bloom approximation
    //#define INTEGRATED_GRAPHICS_COMPATIBILITY_MODE


////////////////////////////  USER CODEPATH OPTIONS  ///////////////////////////

//  To disable a #define option, turn its line into a comment with "//."

//  RUNTIME VS. COMPILE-TIME OPTIONS (Major Performance Implications):
//  Enable runtime shader parameters in the Retroarch (etc.) GUI?  They override
//  many of the options in this file and allow real-time tuning, but many of
//  them are slower.  Disabling them and using this text file will boost FPS.
#define RUNTIME_SHADER_PARAMS_ENABLE
//  Specify the phosphor bloom sigma at runtime?  This option is 10% slower, but
//  it's the only way to do a wide-enough full bloom with a runtime dot pitch.
#define RUNTIME_PHOSPHOR_BLOOM_SIGMA
//  Specify antialiasing weight parameters at runtime?  (Costs ~20% with cubics)
//#define RUNTIME_ANTIALIAS_WEIGHTS
//  Specify subpixel offsets at runtime? (WARNING: EXTREMELY EXPENSIVE!)
//#define RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
//  Make beam_horiz_filter and beam_horiz_linear_rgb_weight into runtime shader
//  parameters?  This will require more math or dynamic branching.
#define RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE
//  Specify the tilt at runtime?  This makes things about 3% slower.
#define RUNTIME_GEOMETRY_TILT
//  Specify the geometry mode at runtime?
#define RUNTIME_GEOMETRY_MODE
//  Specify the phosphor mask type (aperture grille, slot mask, shadow mask) and
//  mode (Lanczos-resize, hardware resize, or tile 1:1) at runtime, even without
//  dynamic branches?  This is cheap if mask_resize_viewport_scale is small.
#define FORCE_RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT

//  PHOSPHOR MASK:
//  Manually resize the phosphor mask for best results (slower)?  Disabling this
//  removes the option to do so, but it may be faster without dynamic branches.
    #define PHOSPHOR_MASK_MANUALLY_RESIZE
//  If we sinc-resize the mask, should we Lanczos-window it (slower but better)?
    #define PHOSPHOR_MASK_RESIZE_LANCZOS_WINDOW
//  Larger blurs are expensive, but we need them to blur larger triads.  We can
//  detect the right blur if the triad size is static or our profile allows
//  dynamic branches, but otherwise we use the largest blur the user indicates
//  they might need:
    #define PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS
    //#define PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_6_PIXELS
    //#define PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_9_PIXELS
    //#define PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_12_PIXELS
    //  Here's a helpful chart:
    //  MaxTriadSize    BlurSize    MinTriadCountsByResolution
    //  3.0             9.0         480/640/960/1920 triads at 1080p/1440p/2160p/4320p, 4:3 aspect
    //  6.0             17.0        240/320/480/960 triads at 1080p/1440p/2160p/4320p, 4:3 aspect
    //  9.0             25.0        160/213/320/640 triads at 1080p/1440p/2160p/4320p, 4:3 aspect
    //  12.0            31.0        120/160/240/480 triads at 1080p/1440p/2160p/4320p, 4:3 aspect
    //  18.0            43.0        80/107/160/320 triads at 1080p/1440p/2160p/4320p, 4:3 aspect


///////////////////////////////  USER PARAMETERS  //////////////////////////////

//  Note: Many of these static parameters are overridden by runtime shader
//  parameters when those are enabled.  However, many others are static codepath
//  options that were cleaner or more convert to code as static constants.

//  GAMMA:
    float crt_gamma_static = 2.5;                  //  range [1, 5]
    float lcd_gamma_static = 2.2;                  //  range [1, 5]

//  LEVELS MANAGEMENT:
    //  Control the final multiplicative image contrast:
    float levels_contrast_static = 1.0;            //  range [0, 4)
    //  We auto-dim to avoid clipping between passes and restore brightness
    //  later.  Control the dim factor here: Lower values clip less but crush
    //  blacks more (static only for now).
    float levels_autodim_temp = 0.5;               //  range (0, 1]

//  HALATION/DIFFUSION/BLOOM:
    //  Halation weight: How much energy should be lost to electrons bounding
    //  around under the CRT glass and exciting random phosphors?
    float halation_weight_static = 0.0;            //  range [0, 1]
    //  Refractive diffusion weight: How much light should spread/diffuse from
    //  refracting through the CRT glass?
    float diffusion_weight_static = 0.075;         //  range [0, 1]
    //  Underestimate brightness: Bright areas bloom more, but we can base the
    //  bloom brightpass on a lower brightness to sharpen phosphors, or a higher
    //  brightness to soften them.  Low values clip, but >= 0.8 looks okay.
    float bloom_underestimate_levels_static = 0.8; //  range [0, 5]
    //  Blur all colors more than necessary for a softer phosphor bloom?
    float bloom_excess_static = 0.0;               //  range [0, 1]
    //  The BLOOM_APPROX pass approximates a phosphor blur early on with a small
    //  blurred resize of the input (convergence offsets are applied as well).
    //  There are three filter options (static option only for now):
    //  0.) Bilinear resize: A fast, close approximation to a 4x4 resize
    //      if min_allowed_viewport_triads and the BLOOM_APPROX resolution are sane
    //      and beam_max_sigma is low.
    //  1.) 3x3 resize blur: Medium speed, soft/smeared from bilinear blurring,
    //      always uses a static sigma regardless of beam_max_sigma or
    //      mask_num_triads_desired.
    //  2.) True 4x4 Gaussian resize: Slowest, technically correct.
    //  These options are more pronounced for the fast, unbloomed shader version.
    float bloom_approx_filter_static = 2.0;

//  ELECTRON BEAM SCANLINE DISTRIBUTION:
    //  How many scanlines should contribute light to each pixel?  Using more
    //  scanlines is slower (especially for a generalized Gaussian) but less
    //  distorted with larger beam sigmas (especially for a pure Gaussian).  The
    //  max_beam_sigma at which the closest unused weight is guaranteed <
    //  1.0/255.0 (for a 3x antialiased pure Gaussian) is:
    //      2 scanlines: max_beam_sigma = 0.2089; distortions begin ~0.34; 141.7 FPS pure, 131.9 FPS generalized
    //      3 scanlines, max_beam_sigma = 0.3879; distortions begin ~0.52; 137.5 FPS pure; 123.8 FPS generalized
    //      4 scanlines, max_beam_sigma = 0.5723; distortions begin ~0.70; 134.7 FPS pure; 117.2 FPS generalized
    //      5 scanlines, max_beam_sigma = 0.7591; distortions begin ~0.89; 131.6 FPS pure; 112.1 FPS generalized
    //      6 scanlines, max_beam_sigma = 0.9483; distortions begin ~1.08; 127.9 FPS pure; 105.6 FPS generalized
    float beam_num_scanlines = 3.0;                //  range [2, 6]
    //  A generalized Gaussian beam varies shape with color too, now just width.
    //  It's slower but more flexible (static option only for now).
    bool beam_generalized_gaussian = true;
    //  What kind of scanline antialiasing do you want?
    //  0: Sample weights at 1x; 1: Sample weights at 3x; 2: Compute an integral
    //  Integrals are slow (especially for generalized Gaussians) and rarely any
    //  better than 3x antialiasing (static option only for now).
    float beam_antialias_level = 1.0;              //  range [0, 2]
    //  Min/max standard deviations for scanline beams: Higher values widen and
    //  soften scanlines.  Depending on other options, low min sigmas can alias.
    float beam_min_sigma_static = 0.02;            //  range (0, 1]
    float beam_max_sigma_static = 0.3;             //  range (0, 1]
    //  Beam width varies as a function of color: A power function (0) is more
    //  configurable, but a spherical function (1) gives the widest beam
    //  variability without aliasing (static option only for now).
    float beam_spot_shape_function = 0.0;
    //  Spot shape power: Powers <= 1 give smoother spot shapes but lower
    //  sharpness.  Powers >= 1.0 are awful unless mix/max sigmas are close.
    float beam_spot_power_static = 1.0/3.0;    //  range (0, 16]
    //  Generalized Gaussian max shape parameters: Higher values give flatter
    //  scanline plateaus and steeper dropoffs, simultaneously widening and
    //  sharpening scanlines at the cost of aliasing.  2.0 is pure Gaussian, and
    //  values > ~40.0 cause artifacts with integrals.
    float beam_min_shape_static = 2.0;         //  range [2, 32]
    float beam_max_shape_static = 4.0;         //  range [2, 32]
    //  Generalized Gaussian shape power: Affects how quickly the distribution
    //  changes shape from Gaussian to steep/plateaued as color increases from 0
    //  to 1.0.  Higher powers appear softer for most colors, and lower powers
    //  appear sharper for most colors.
    float beam_shape_power_static = 1.0/4.0;   //  range (0, 16]
    //  What filter should be used to sample scanlines horizontally?
    //  0: Quilez (fast), 1: Gaussian (configurable), 2: Lanczos2 (sharp)
    float beam_horiz_filter_static = 0.0;
    //  Standard deviation for horizontal Gaussian resampling:
    float beam_horiz_sigma_static = 0.35;      //  range (0, 2/3]
    //  Do horizontal scanline sampling in linear RGB (correct light mixing),
    //  gamma-encoded RGB (darker, hard spot shape, may better match bandwidth-
    //  limiting circuitry in some CRT's), or a weighted avg.?
    float beam_horiz_linear_rgb_weight_static = 1.0;   //  range [0, 1]
    //  Simulate scanline misconvergence?  This needs 3x horizontal texture
    //  samples and 3x texture samples of BLOOM_APPROX and HALATION_BLUR in
    //  later passes (static option only for now).
    bool beam_misconvergence = true;
    //  Convergence offsets in x/y directions for R/G/B scanline beams in units
    //  of scanlines.  Positive offsets go right/down; ranges [-2, 2]
    vec2 convergence_offsets_r_static = vec2(0.0, 0.0);
    vec2 convergence_offsets_g_static = vec2(0.0, 0.0);
    vec2 convergence_offsets_b_static = vec2(0.0, 0.0);
    //  Detect interlacing (static option only for now)?
    bool interlace_detect = true;
    //  Assume 1080-line sources are interlaced?
    bool interlace_1080i_static = false;
    //  For interlaced sources, assume TFF (top-field first) or BFF order?
    //  (Whether this matters depends on the nature of the interlaced input.)
    bool interlace_bff_static = false;

//  ANTIALIASING:
    //  What AA level do you want for curvature/overscan/subpixels?  Options:
    //  0x (none), 1x (sample subpixels), 4x, 5x, 6x, 7x, 8x, 12x, 16x, 20x, 24x
    //  (Static option only for now)
    float aa_level = 12.0;                     //  range [0, 24]
    //  What antialiasing filter do you want (static option only)?  Options:
    //  0: Box (separable), 1: Box (cylindrical),
    //  2: Tent (separable), 3: Tent (cylindrical),
    //  4: Gaussian (separable), 5: Gaussian (cylindrical),
    //  6: Cubic* (separable), 7: Cubic* (cylindrical, poor)
    //  8: Lanczos Sinc (separable), 9: Lanczos Jinc (cylindrical, poor)
    //      * = Especially slow with RUNTIME_ANTIALIAS_WEIGHTS
    float aa_filter = 6.0;                     //  range [0, 9]
    //  Flip the sample grid on odd/even frames (static option only for now)?
    bool aa_temporal = false;
    //  Use RGB subpixel offsets for antialiasing?  The pixel is at green, and
    //  the blue offset is the negative r offset; range [0, 0.5]
    vec2 aa_subpixel_r_offset_static = vec2(-1.0/3.0, 0.0);//vec2(0.0);
    //  Cubics: See http://www.imagemagick.org/Usage/filter/#mitchell
    //  1.) "Keys cubics" with B = 1 - 2C are considered the highest quality.
    //  2.) C = 0.5 (default) is Catmull-Rom; higher C's apply sharpening.
    //  3.) C = 1.0/3.0 is the Mitchell-Netravali filter.
    //  4.) C = 0.0 is a soft spline filter.
    float aa_cubic_c_static = 0.5;             //  range [0, 4]
    //  Standard deviation for Gaussian antialiasing: Try 0.5/aa_pixel_diameter.
    float aa_gauss_sigma_static = 0.5;     //  range [0.0625, 1.0]

//  PHOSPHOR MASK:
    //  Mask type: 0 = aperture grille, 1 = slot mask, 2 = EDP shadow mask
    float mask_type_static = 1.0;                  //  range [0, 2]
    //  We can sample the mask three ways.  Pick 2/3 from: Pretty/Fast/Flexible.
    //  0.) Sinc-resize to the desired dot pitch manually (pretty/slow/flexible).
    //      This requires PHOSPHOR_MASK_MANUALLY_RESIZE to be #defined.
    //  1.) Hardware-resize to the desired dot pitch (ugly/fast/flexible).  This
    //      is halfway decent with LUT mipmapping but atrocious without it.
    //  2.) Tile it without resizing at a 1:1 texel:pixel ratio for flat coords
    //      (pretty/fast/inflexible).  Each input LUT has a fixed dot pitch.
    //      This mode reuses the same masks, so triads will be enormous unless
    //      you change the mask LUT filenames in your .cgp file.
    float mask_sample_mode_static = 0.0;           //  range [0, 2]
    //  Prefer setting the triad size (0.0) or number on the screen (1.0)?
    //  If RUNTIME_PHOSPHOR_BLOOM_SIGMA isn't #defined, the specified triad size
    //  will always be used to calculate the full bloom sigma statically.
    float mask_specify_num_triads_static = 0.0;    //  range [0, 1]
    //  Specify the phosphor triad size, in pixels.  Each tile (usually with 8
    //  triads) will be rounded to the nearest integer tile size and clamped to
    //  obey minimum size constraints (imposed to reduce downsize taps) and
    //  maximum size constraints (imposed to have a sane MASK_RESIZE FBO size).
    //  To increase the size limit, double the viewport-relative scales for the
    //  two MASK_RESIZE passes in crt-royale.cgp and user-cgp-contants.h.
    //      range [1, mask_texture_small_size/mask_triads_per_tile]
//    float mask_triad_size_desired_static = 24.0 / 8.0;
    //  If mask_specify_num_triads is 1.0/true, we'll go by this instead (the
    //  final size will be rounded and constrained as above); default 480.0
    float mask_num_triads_desired_static = 480.0;
    //  How many lobes should the sinc/Lanczos resizer use?  More lobes require
    //  more samples and avoid moire a bit better, but some is unavoidable
    //  depending on the destination size (static option for now).
    float mask_sinc_lobes = 3.0;                   //  range [2, 4]
    //  The mask is resized using a variable number of taps in each dimension,
    //  but some Cg profiles always fetch a constant number of taps no matter
    //  what (no dynamic branching).  We can limit the maximum number of taps if
    //  we statically limit the minimum phosphor triad size.  Larger values are
    //  faster, but the limit IS enforced (static option only, forever);
    //      range [1, mask_texture_small_size/mask_triads_per_tile]
    //  TODO: Make this 1.0 and compensate with smarter sampling!
    float mask_min_allowed_triad_size = 2.0;

//  GEOMETRY:
    //  Geometry mode:
    //  0: Off (default), 1: Spherical mapping (like cgwg's),
    //  2: Alt. spherical mapping (more bulbous), 3: Cylindrical/Trinitron
    float geom_mode_static = 0.0;      //  range [0, 3]
    //  Radius of curvature: Measured in units of your viewport's diagonal size.
    float geom_radius_static = 2.0;    //  range [1/(2*pi), 1024]
    //  View dist is the distance from the player to their physical screen, in
    //  units of the viewport's diagonal size.  It controls the field of view.
    float geom_view_dist_static = 2.0; //  range [0.5, 1024]
    //  Tilt angle in radians (clockwise around up and right vectors):
    vec2 geom_tilt_angle_static = vec2(0.0, 0.0);  //  range [-pi, pi]
    //  Aspect ratio: When the true viewport size is unknown, this value is used
    //  to help convert between the phosphor triad size and count, along with
    //  the mask_resize_viewport_scale constant from user-cgp-constants.h.  Set
    //  this equal to Retroarch's display aspect ratio (DAR) for best results;
    //  range [1, geom_max_aspect_ratio from user-cgp-constants.h];
    //  default (256/224)*(54/47) = 1.313069909 (see below)
    float geom_aspect_ratio_static = 1.313069909;
    //  Before getting into overscan, here's some general aspect ratio info:
    //  - DAR = display aspect ratio = SAR * PAR; as in your Retroarch setting
    //  - SAR = storage aspect ratio = DAR / PAR; square pixel emulator frame AR
    //  - PAR = pixel aspect ratio   = DAR / SAR; holds regardless of cropping
    //  Geometry processing has to "undo" the screen-space 2D DAR to calculate
    //  3D view vectors, then reapplies the aspect ratio to the simulated CRT in
    //  uv-space.  To ensure the source SAR is intended for a ~4:3 DAR, either:
    //  a.) Enable Retroarch's "Crop Overscan"
    //  b.) Readd horizontal padding: Set overscan to e.g. N*(1.0, 240.0/224.0)
    //  Real consoles use horizontal black padding in the signal, but emulators
    //  often crop this without cropping the vertical padding; a 256x224 [S]NES
    //  frame (8:7 SAR) is intended for a ~4:3 DAR, but a 256x240 frame is not.
    //  The correct [S]NES PAR is 54:47, found by blargg and NewRisingSun:
    //      http://board.zsnes.com/phpBB3/viewtopic.php?f=22&t=11928&start=50
    //      http://forums.nesdev.com/viewtopic.php?p=24815#p24815
    //  For flat output, it's okay to set DAR = [existing] SAR * [correct] PAR
    //  without doing a. or b., but horizontal image borders will be tighter
    //  than vertical ones, messing up curvature and overscan.  Fixing the
    //  padding first corrects this.
    //  Overscan: Amount to "zoom in" before cropping.  You can zoom uniformly
    //  or adjust x/y independently to e.g. readd horizontal padding, as noted
    //  above: Values < 1.0 zoom out; range (0, inf)
    vec2 geom_overscan_static = vec2(1.0, 1.0);// * 1.005 * (1.0, 240/224.0)
    //  Compute a proper pixel-space to texture-space matrix even without ddx()/
    //  ddy()?  This is ~8.5% slower but improves antialiasing/subpixel filtering
    //  with strong curvature (static option only for now).
    bool geom_force_correct_tangent_matrix = true;

//  BORDERS:
    //  Rounded border size in texture uv coords:
    float border_size_static = 0.015;           //  range [0, 0.5]
    //  Border darkness: Moderate values darken the border smoothly, and high
    //  values make the image very dark just inside the border:
    float border_darkness_static = 2.0;        //  range [0, inf)
    //  Border compression: High numbers compress border transitions, narrowing
    //  the dark border area.
    float border_compress_static = 2.5;        //  range [1, inf)


#endif  //  USER_SETTINGS_H

#ifndef BIND_SHADER_PARAMS_H
#define BIND_SHADER_PARAMS_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


/////////////////////////////  SETTINGS MANAGEMENT  ////////////////////////////

//#include "../user-settings.h"
////////////////   BEGIN #include "derived-settings-and-constants.h"   /////////
#ifndef DERIVED_SETTINGS_AND_CONSTANTS_H
#define DERIVED_SETTINGS_AND_CONSTANTS_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


/////////////////////////////////  DESCRIPTION  ////////////////////////////////

//  These macros and constants can be used across the whole codebase.
//  Unlike the values in user-settings.cgh, end users shouldn't modify these.


//////////////////////////////////  INCLUDES  //////////////////////////////////

//#include "../user-settings.h"
/////////////////////   BEGIN #include "user-preset-constants.h"   /////////////
#ifndef USER_CGP_CONSTANTS_H
#define USER_CGP_CONSTANTS_H

//  IMPORTANT:
//  These constants MUST be set appropriately for the settings in crt-royale.cgp
//  (or whatever related .cgp file you're using).  If they aren't, you're likely
//  to get artifacts, the wrong phosphor mask size, etc.  I wish these could be
//  set directly in the .cgp file to make things easier, but...they can't.

//  PASS SCALES AND RELATED CONSTANTS:
//  Copy the absolute scale_x for BLOOM_APPROX.  There are two major versions of
//  this shader: One does a viewport-scale bloom, and the other skips it.  The
//  latter benefits from a higher bloom_approx_scale_x, so save both separately:
float bloom_approx_size_x = 320.0;
float bloom_approx_scale_x = 320.0; //dunno why this is necessary
float bloom_approx_size_x_for_fake = 400.0;
//  Copy the viewport-relative scales of the phosphor mask resize passes
//  (MASK_RESIZE and the pass immediately preceding it):
vec2 mask_resize_viewport_scale = vec2(0.0625, 0.0625);
//  Copy the geom_max_aspect_ratio used to calculate the MASK_RESIZE scales, etc.:
float geom_max_aspect_ratio = 4.0/3.0;

//  PHOSPHOR MASK TEXTURE CONSTANTS:
//  Set the following constants to reflect the properties of the phosphor mask
//  texture named in crt-royale.cgp.  The shader optionally resizes a mask tile
//  based on user settings, then repeats a single tile until filling the screen.
//  The shader must know the input texture size (default 64x64), and to manually
//  resize, it must also know the horizontal triads per tile (default 8).
vec2 mask_texture_small_size = vec2(64.0);
vec2 mask_texture_large_size = vec2(512.0);
float mask_triads_per_tile = 8.0;
//  We need the average brightness of the phosphor mask to compensate for the
//  dimming it causes.  The following four values are roughly correct for the
//  masks included with the shader.  Update the value for any LUT texture you
//  change.  [Un]comment "#define PHOSPHOR_MASK_GRILLE14" depending on whether
//  the loaded aperture grille uses 14-pixel or 15-pixel stripes (default 15).
//#define PHOSPHOR_MASK_GRILLE14
float mask_grille14_avg_color = 50.6666666/255.0;
    //  TileableLinearApertureGrille14Wide7d33Spacing*.png
    //  TileableLinearApertureGrille14Wide10And6Spacing*.png
float mask_grille15_avg_color = 53.0/255.0;
    //  TileableLinearApertureGrille15Wide6d33Spacing*.png
    //  TileableLinearApertureGrille15Wide8And5d5Spacing*.png
float mask_slot_avg_color = 46.0/255.0;
    //  TileableLinearSlotMask15Wide9And4d5Horizontal8VerticalSpacing*.png
    //  TileableLinearSlotMaskTall15Wide9And4d5Horizontal9d14VerticalSpacing*.png
float mask_shadow_avg_color = 41.0/255.0;
    //  TileableLinearShadowMask*.png
    //  TileableLinearShadowMaskEDP*.png

#ifdef PHOSPHOR_MASK_GRILLE14
    float mask_grille_avg_color = mask_grille14_avg_color;
#else
    float mask_grille_avg_color = mask_grille15_avg_color;
#endif


#endif  //  USER_CGP_CONSTANTS_H


/////////////////////   END #include "user-preset-constants.h"   ///////////////


///////////////////////////////  FIXED SETTINGS  ///////////////////////////////

//  Avoid dividing by zero; using a macro overloads for float, vec2, etc.:
#define FIX_ZERO(c) (max(abs(c), 0.0000152587890625))   //  2^-16

//  Ensure the first pass decodes CRT gamma and the last encodes LCD gamma.
#ifndef SIMULATE_CRT_ON_LCD
    #define SIMULATE_CRT_ON_LCD
#endif

//  Manually tiling a manually resized texture creates texture coord derivative
//  discontinuities and confuses anisotropic filtering, causing discolored tile
//  seams in the phosphor mask.  Workarounds:
//  a.) Using tex2Dlod disables anisotropic filtering for tiled masks.  It's
//      downgraded to tex2Dbias without DRIVERS_ALLOW_TEX2DLOD #defined and
//      disabled without DRIVERS_ALLOW_TEX2DBIAS #defined either.
//  b.) "Tile flat twice" requires drawing two full tiles without border padding
//      to the resized mask FBO, and it's incompatible with same-pass curvature.
//      (Same-pass curvature isn't used but could be in the future...maybe.)
//  c.) "Fix discontinuities" requires derivatives and drawing one tile with
//      border padding to the resized mask FBO, but it works with same-pass
//      curvature.  It's disabled without DRIVERS_ALLOW_DERIVATIVES #defined.
//  Precedence: a, then, b, then c (if multiple strategies are #defined).
    #define ANISOTROPIC_TILING_COMPAT_TEX2DLOD              //  129.7 FPS, 4x, flat; 101.8 at fullscreen
    #define ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE       //  128.1 FPS, 4x, flat; 101.5 at fullscreen
    #define ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES   //  124.4 FPS, 4x, flat; 97.4 at fullscreen
//  Also, manually resampling the phosphor mask is slightly blurrier with
//  anisotropic filtering.  (Resampling with mipmapping is even worse: It
//  creates artifacts, but only with the fully bloomed shader.)  The difference
//  is subtle with small triads, but you can fix it for a small cost.
    //#define ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD


//////////////////////////////  DERIVED SETTINGS  //////////////////////////////

//  Intel HD 4000 GPU's can't handle manual mask resizing (for now), setting the
//  geometry mode at runtime, or a 4x4 true Gaussian resize.  Disable
//  incompatible settings ASAP.  (INTEGRATED_GRAPHICS_COMPATIBILITY_MODE may be
//  #defined by either user-settings.h or a wrapper .cg that #includes the
//  current .cg pass.)
#ifdef INTEGRATED_GRAPHICS_COMPATIBILITY_MODE
    #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
        #undef PHOSPHOR_MASK_MANUALLY_RESIZE
    #endif
    #ifdef RUNTIME_GEOMETRY_MODE
        #undef RUNTIME_GEOMETRY_MODE
    #endif
    //  Mode 2 (4x4 Gaussian resize) won't work, and mode 1 (3x3 blur) is
    //  inferior in most cases, so replace 2.0 with 0.0:
     float bloom_approx_filter =
        bloom_approx_filter_static > 1.5 ? 0.0 : bloom_approx_filter_static;
#else
     float bloom_approx_filter = bloom_approx_filter_static;
#endif

//  Disable slow runtime paths if static parameters are used.  Most of these
//  won't be a problem anyway once the params are disabled, but some will.
#ifndef RUNTIME_SHADER_PARAMS_ENABLE
    #ifdef RUNTIME_PHOSPHOR_BLOOM_SIGMA
        #undef RUNTIME_PHOSPHOR_BLOOM_SIGMA
    #endif
    #ifdef RUNTIME_ANTIALIAS_WEIGHTS
        #undef RUNTIME_ANTIALIAS_WEIGHTS
    #endif
    #ifdef RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
        #undef RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
    #endif
    #ifdef RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE
        #undef RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE
    #endif
    #ifdef RUNTIME_GEOMETRY_TILT
        #undef RUNTIME_GEOMETRY_TILT
    #endif
    #ifdef RUNTIME_GEOMETRY_MODE
        #undef RUNTIME_GEOMETRY_MODE
    #endif
    #ifdef FORCE_RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
        #undef FORCE_RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
    #endif
#endif

//  Make tex2Dbias a backup for tex2Dlod for wider compatibility.
#ifdef ANISOTROPIC_TILING_COMPAT_TEX2DLOD
    #define ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
#endif
#ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD
    #define ANISOTROPIC_RESAMPLING_COMPAT_TEX2DBIAS
#endif
//  Rule out unavailable anisotropic compatibility strategies:
#ifndef DRIVERS_ALLOW_DERIVATIVES
    #ifdef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
        #undef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
    #endif
#endif
#ifndef DRIVERS_ALLOW_TEX2DLOD
    #ifdef ANISOTROPIC_TILING_COMPAT_TEX2DLOD
        #undef ANISOTROPIC_TILING_COMPAT_TEX2DLOD
    #endif
    #ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD
        #undef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD
    #endif
    #ifdef ANTIALIAS_DISABLE_ANISOTROPIC
        #undef ANTIALIAS_DISABLE_ANISOTROPIC
    #endif
#endif
#ifndef DRIVERS_ALLOW_TEX2DBIAS
    #ifdef ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
        #undef ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
    #endif
    #ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DBIAS
        #undef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DBIAS
    #endif
#endif
//  Prioritize anisotropic tiling compatibility strategies by performance and
//  disable unused strategies.  This concentrates all the nesting in one place.
#ifdef ANISOTROPIC_TILING_COMPAT_TEX2DLOD
    #ifdef ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
        #undef ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
    #endif
    #ifdef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
        #undef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
    #endif
    #ifdef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
        #undef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
    #endif
#else
    #ifdef ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
        #ifdef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
            #undef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
        #endif
        #ifdef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
            #undef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
        #endif
    #else
        //  ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE is only compatible with
        //  flat texture coords in the same pass, but that's all we use.
        #ifdef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
            #ifdef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
                #undef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
            #endif
        #endif
    #endif
#endif
//  The tex2Dlod and tex2Dbias strategies share a lot in common, and we can
//  reduce some #ifdef nesting in the next section by essentially OR'ing them:
#ifdef ANISOTROPIC_TILING_COMPAT_TEX2DLOD
    #define ANISOTROPIC_TILING_COMPAT_TEX2DLOD_FAMILY
#endif
#ifdef ANISOTROPIC_TILING_COMPAT_TEX2DBIAS
    #define ANISOTROPIC_TILING_COMPAT_TEX2DLOD_FAMILY
#endif
//  Prioritize anisotropic resampling compatibility strategies the same way:
#ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD
    #ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DBIAS
        #undef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DBIAS
    #endif
#endif


///////////////////////  DERIVED PHOSPHOR MASK CONSTANTS  //////////////////////

//  If we can use the large mipmapped LUT without mipmapping artifacts, we
//  should: It gives us more options for using fewer samples.
#ifdef DRIVERS_ALLOW_TEX2DLOD
    #ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD
        //  TODO: Take advantage of this!
        #define PHOSPHOR_MASK_RESIZE_MIPMAPPED_LUT
         vec2 mask_resize_src_lut_size = mask_texture_large_size;
    #else
         vec2 mask_resize_src_lut_size = mask_texture_small_size;
    #endif
#else
     vec2 mask_resize_src_lut_size = mask_texture_small_size;
#endif


//  tex2D's sampler2D parameter MUST be a uniform global, a uniform input to
//  main_fragment, or a static alias of one of the above.  This makes it hard
//  to select the phosphor mask at runtime: We can't even assign to a uniform
//  global in the vertex shader or select a sampler2D in the vertex shader and
//  pass it to the fragment shader (even with explicit TEXUNIT# bindings),
//  because it just gives us the input texture or a black screen.  However, we
//  can get around these limitations by calling tex2D three times with different
//  uniform samplers (or resizing the phosphor mask three times altogether).
//  With dynamic branches, we can process only one of these branches on top of
//  quickly discarding fragments we don't need (cgc seems able to overcome
//  limigations around dependent texture fetches inside of branches).  Without
//  dynamic branches, we have to process every branch for every fragment...which
//  is slower.  Runtime sampling mode selection is slower without dynamic
//  branches as well.  Let the user's static #defines decide if it's worth it.
#ifdef DRIVERS_ALLOW_DYNAMIC_BRANCHES
    #define RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
#else
    #ifdef FORCE_RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
        #define RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
    #endif
#endif

//  We need to render some minimum number of tiles in the resize passes.
//  We need at least 1.0 just to repeat a single tile, and we need extra
//  padding beyond that for anisotropic filtering, discontinuitity fixing,
//  antialiasing, same-pass curvature (not currently used), etc.  First
//  determine how many border texels and tiles we need, based on how the result
//  will be sampled:
#ifdef GEOMETRY_EARLY
         float max_subpixel_offset = aa_subpixel_r_offset_static.x;
        //  Most antialiasing filters have a base radius of 4.0 pixels:
         float max_aa_base_pixel_border = 4.0 +
            max_subpixel_offset;
#else
     float max_aa_base_pixel_border = 0.0;
#endif
//  Anisotropic filtering adds about 0.5 to the pixel border:
#ifndef ANISOTROPIC_TILING_COMPAT_TEX2DLOD_FAMILY
     float max_aniso_pixel_border = max_aa_base_pixel_border + 0.5;
#else
     float max_aniso_pixel_border = max_aa_base_pixel_border;
#endif
//  Fixing discontinuities adds 1.0 more to the pixel border:
#ifdef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
     float max_tiled_pixel_border = max_aniso_pixel_border + 1.0;
#else
     float max_tiled_pixel_border = max_aniso_pixel_border;
#endif
//  Convert the pixel border to an integer texel border.  Assume same-pass
//  curvature about triples the texel frequency:
#ifdef GEOMETRY_EARLY
     float max_mask_texel_border =
        ceil(max_tiled_pixel_border * 3.0);
#else
     float max_mask_texel_border = ceil(max_tiled_pixel_border);
#endif
//  Convert the texel border to a tile border using worst-case assumptions:
 float max_mask_tile_border = max_mask_texel_border/
    (mask_min_allowed_triad_size * mask_triads_per_tile);

//  Finally, set the number of resized tiles to render to MASK_RESIZE, and set
//  the starting texel (inside borders) for sampling it.
#ifndef GEOMETRY_EARLY
    #ifdef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
        //  Special case: Render two tiles without borders.  Anisotropic
        //  filtering doesn't seem to be a problem here.
         float mask_resize_num_tiles = 1.0 + 1.0;
         float mask_start_texels = 0.0;
    #else
         float mask_resize_num_tiles = 1.0 +
            2.0 * max_mask_tile_border;
         float mask_start_texels = max_mask_texel_border;
    #endif
#else
     float mask_resize_num_tiles = 1.0 + 2.0*max_mask_tile_border;
     float mask_start_texels = max_mask_texel_border;
#endif

//  We have to fit mask_resize_num_tiles into an FBO with a viewport scale of
//  mask_resize_viewport_scale.  This limits the maximum final triad size.
//  Estimate the minimum number of triads we can split the screen into in each
//  dimension (we'll be as correct as mask_resize_viewport_scale is):
 float mask_resize_num_triads =
    mask_resize_num_tiles * mask_triads_per_tile;
 vec2 min_allowed_viewport_triads =
    vec2(mask_resize_num_triads) / mask_resize_viewport_scale;


////////////////////////  COMMON MATHEMATICAL CONSTANTS  ///////////////////////

 float pi = 3.141592653589;
//  We often want to find the location of the previous texel, e.g.:
//      vec2 curr_texel = uv * texture_size;
//      vec2 prev_texel = floor(curr_texel - vec2(0.5)) + vec2(0.5);
//      vec2 prev_texel_uv = prev_texel / texture_size;
//  However, many GPU drivers round incorrectly around exact texel locations.
//  We need to subtract a little less than 0.5 before flooring, and some GPU's
//  require this value to be farther from 0.5 than others; define it here.
//      vec2 prev_texel =
//          floor(curr_texel - vec2(under_half)) + vec2(0.5);
 float under_half = 0.4995;


#endif  //  DERIVED_SETTINGS_AND_CONSTANTS_H


////////////////   END #include "derived-settings-and-constants.h"   ///////////

//  Override some parameters for gamma-management.h and tex2Dantialias.h:
#define OVERRIDE_DEVICE_GAMMA
float gba_gamma = 3.5; //  Irrelevant but necessary to define.
#define ANTIALIAS_OVERRIDE_BASICS
#define ANTIALIAS_OVERRIDE_PARAMETERS

//  Provide accessors for vector constants that pack scalar uniforms:
vec2 get_aspect_vector(float geom_aspect_ratio)
{
    //  Get an aspect ratio vector.  Enforce geom_max_aspect_ratio, and prevent
    //  the absolute scale from affecting the uv-mapping for curvature:
    float geom_clamped_aspect_ratio =
        min(geom_aspect_ratio, geom_max_aspect_ratio);
    vec2 geom_aspect =
        normalize(vec2(geom_clamped_aspect_ratio, 1.0));
    return geom_aspect;
}

vec2 get_geom_overscan_vector()
{
    return vec2(geom_overscan_x, geom_overscan_y);
}

vec2 get_geom_tilt_angle_vector()
{
    return vec2(geom_tilt_angle_x, geom_tilt_angle_y);
}

vec3 get_convergence_offsets_x_vector()
{
    return vec3(convergence_offset_x_r, convergence_offset_x_g,
        convergence_offset_x_b);
}

vec3 get_convergence_offsets_y_vector()
{
    return vec3(convergence_offset_y_r, convergence_offset_y_g,
        convergence_offset_y_b);
}

vec2 get_convergence_offsets_r_vector()
{
    return vec2(convergence_offset_x_r, convergence_offset_y_r);
}

vec2 get_convergence_offsets_g_vector()
{
    return vec2(convergence_offset_x_g, convergence_offset_y_g);
}

vec2 get_convergence_offsets_b_vector()
{
    return vec2(convergence_offset_x_b, convergence_offset_y_b);
}

vec2 get_aa_subpixel_r_offset()
{
    #ifdef RUNTIME_ANTIALIAS_WEIGHTS
        #ifdef RUNTIME_ANTIALIAS_SUBPIXEL_OFFSETS
            //  WARNING: THIS IS EXTREMELY EXPENSIVE.
            return vec2(aa_subpixel_r_offset_x_runtime,
                aa_subpixel_r_offset_y_runtime);
        #else
            return aa_subpixel_r_offset_static;
        #endif
    #else
        return aa_subpixel_r_offset_static;
    #endif
}

//  Provide accessors settings which still need "cooking:"
float get_mask_amplify()
{
    float mask_grille_amplify = 1.0/mask_grille_avg_color;
    float mask_slot_amplify = 1.0/mask_slot_avg_color;
    float mask_shadow_amplify = 1.0/mask_shadow_avg_color;
    return mask_type < 0.5 ? mask_grille_amplify :
        mask_type < 1.5 ? mask_slot_amplify :
        mask_shadow_amplify;
}

float get_mask_sample_mode()
{
    #ifdef RUNTIME_PHOSPHOR_MASK_MODE_TYPE_SELECT
        #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
            return mask_sample_mode_desired;
        #else
            return clamp(mask_sample_mode_desired, 1.0, 2.0);
        #endif
    #else
        #ifdef PHOSPHOR_MASK_MANUALLY_RESIZE
            return mask_sample_mode_static;
        #else
            return clamp(mask_sample_mode_static, 1.0, 2.0);
        #endif
    #endif
}


#endif  //  BIND_SHADER_PARAMS_H

/////////////   BEGIN #include gamma-management.h   ///////////////////
#ifndef GAMMA_MANAGEMENT_H
#define GAMMA_MANAGEMENT_H

///////////////////////////////  BASE CONSTANTS  ///////////////////////////////

//  Set standard gamma constants, but allow users to override them:
#ifndef OVERRIDE_STANDARD_GAMMA
    //  Standard encoding gammas:
    float ntsc_gamma = 2.2;    //  Best to use NTSC for PAL too?
    float pal_gamma = 2.8;     //  Never actually 2.8 in practice
    //  Typical device decoding gammas (only use for emulating devices):
    //  CRT/LCD reference gammas are higher than NTSC and Rec.709 video standard
    //  gammas: The standards purposely undercorrected for an analog CRT's
    //  assumed 2.5 reference display gamma to maintain contrast in assumed
    //  [dark] viewing conditions: http://www.poynton.com/PDFs/GammaFAQ.pdf
    //  These unstated assumptions about display gamma and perceptual rendering
    //  intent caused a lot of confusion, and more modern CRT's seemed to target
    //  NTSC 2.2 gamma with circuitry.  LCD displays seem to have followed suit
    //  (they struggle near black with 2.5 gamma anyway), especially PC/laptop
    //  displays designed to view sRGB in bright environments.  (Standards are
    //  also in flux again with BT.1886, but it's underspecified for displays.)
    float crt_reference_gamma_high = 2.5;  //  In (2.35, 2.55)
    float crt_reference_gamma_low = 2.35;  //  In (2.35, 2.55)
    float lcd_reference_gamma = 2.5;       //  To match CRT
    float crt_office_gamma = 2.2;  //  Circuitry-adjusted for NTSC
    float lcd_office_gamma = 2.2;  //  Approximates sRGB
#endif  //  OVERRIDE_STANDARD_GAMMA

//  Assuming alpha == 1.0 might make it easier for users to avoid some bugs,
//  but only if they're aware of it.
#ifndef OVERRIDE_ALPHA_ASSUMPTIONS
    bool assume_opaque_alpha = false;
#endif


///////////////////////  DERIVED CONSTANTS AS FUNCTIONS  ///////////////////////

//  gamma-management.h should be compatible with overriding gamma values with
//  runtime user parameters, but we can only define other global constants in
//  terms of static constants, not uniform user parameters.  To get around this
//  limitation, we need to define derived constants using functions.

//  Set device gamma constants, but allow users to override them:
#ifdef OVERRIDE_DEVICE_GAMMA
    //  The user promises to globally define the appropriate constants:
    float get_crt_gamma()    {   return crt_gamma;   }
    float get_gba_gamma()    {   return gba_gamma;   }
    float get_lcd_gamma()    {   return lcd_gamma;   }
#else
    float get_crt_gamma()    {   return crt_reference_gamma_high;    }
    float get_gba_gamma()    {   return 3.5; }   //  Game Boy Advance; in (3.0, 4.0)
    float get_lcd_gamma()    {   return lcd_office_gamma;            }
#endif  //  OVERRIDE_DEVICE_GAMMA

//  Set decoding/encoding gammas for the first/lass passes, but allow overrides:
#ifdef OVERRIDE_FINAL_GAMMA
    //  The user promises to globally define the appropriate constants:
    float get_intermediate_gamma()   {   return intermediate_gamma;  }
    float get_input_gamma()          {   return input_gamma;         }
    float get_output_gamma()         {   return output_gamma;        }
#else
    //  If we gamma-correct every pass, always use ntsc_gamma between passes to
    //  ensure middle passes don't need to care if anything is being simulated:
    float get_intermediate_gamma()   {   return ntsc_gamma;          }
    #ifdef SIMULATE_CRT_ON_LCD
        float get_input_gamma()      {   return get_crt_gamma();     }
        float get_output_gamma()     {   return get_lcd_gamma();     }
    #else
    #ifdef SIMULATE_GBA_ON_LCD
        float get_input_gamma()      {   return get_gba_gamma();     }
        float get_output_gamma()     {   return get_lcd_gamma();     }
    #else
    #ifdef SIMULATE_LCD_ON_CRT
        float get_input_gamma()      {   return get_lcd_gamma();     }
        float get_output_gamma()     {   return get_crt_gamma();     }
    #else
    #ifdef SIMULATE_GBA_ON_CRT
        float get_input_gamma()      {   return get_gba_gamma();     }
        float get_output_gamma()     {   return get_crt_gamma();     }
    #else   //  Don't simulate anything:
        float get_input_gamma()      {   return ntsc_gamma;          }
        float get_output_gamma()     {   return ntsc_gamma;          }
    #endif  //  SIMULATE_GBA_ON_CRT
    #endif  //  SIMULATE_LCD_ON_CRT
    #endif  //  SIMULATE_GBA_ON_LCD
    #endif  //  SIMULATE_CRT_ON_LCD
#endif  //  OVERRIDE_FINAL_GAMMA

#ifndef GAMMA_ENCODE_EVERY_FBO
    #ifdef FIRST_PASS
        bool linearize_input = true;
        float get_pass_input_gamma()     {   return get_input_gamma();   }
    #else
        bool linearize_input = false;
        float get_pass_input_gamma()     {   return 1.0;                 }
    #endif
    #ifdef LAST_PASS
        bool gamma_encode_output = true;
        float get_pass_output_gamma()    {   return get_output_gamma();  }
    #else
        bool gamma_encode_output = false;
        float get_pass_output_gamma()    {   return 1.0;                 }
    #endif
#else
    bool linearize_input = true;
    bool gamma_encode_output = true;
    #ifdef FIRST_PASS
        float get_pass_input_gamma()     {   return get_input_gamma();   }
    #else
        float get_pass_input_gamma()     {   return get_intermediate_gamma();    }
    #endif
    #ifdef LAST_PASS
        float get_pass_output_gamma()    {   return get_output_gamma();  }
    #else
        float get_pass_output_gamma()    {   return get_intermediate_gamma();    }
    #endif
#endif

vec4 decode_input(vec4 color)
{
    if(linearize_input = true)
    {
        if(assume_opaque_alpha = true)
        {
            return vec4(pow(color.rgb, vec3(get_pass_input_gamma())), 1.0);
        }
        else
        {
            return vec4(pow(color.rgb, vec3(get_pass_input_gamma())), color.a);
        }
    }
    else
    {
        return color;
    }
}

vec4 encode_output(vec4 color)
{
    if(gamma_encode_output = true)
    {
        if(assume_opaque_alpha = true)
        {
            return vec4(pow(color.rgb, vec3(1.0/get_pass_output_gamma())), 1.0);
        }
        else
        {
            return vec4(pow(color.rgb, vec3(1.0/get_pass_output_gamma())), color.a);
        }
    }
    else
    {
        return color;
    }
}

#define tex2D_linearize(C, D) decode_input(vec4(texture(C, D)))
//vec4 tex2D_linearize(sampler2D tex, vec2 tex_coords)
//{   return decode_input(vec4(texture(tex, tex_coords)));   }

//#define tex2D_linearize(C, D, E) decode_input(vec4(texture(C, D, E)))
//vec4 tex2D_linearize(sampler2D tex, vec2 tex_coords, int texel_off)
//{   return decode_input(vec4(texture(tex, tex_coords, texel_off)));    }

#endif  //  GAMMA_MANAGEMENT_H
/////////////   END #include gamma-management.h     ///////////////////

///////////   BEGIN tex2Dantialias.h //////////////////

#ifndef TEX2DANTIALIAS_H
#define TEX2DANTIALIAS_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


/////////////////////////////////  DESCRIPTION  ////////////////////////////////

//  This file provides antialiased and subpixel-aware tex2D lookups.
//  Requires:   All functions share these requirements:
//              1.) All requirements of gamma-management.h must be satisfied!
//              2.) pixel_to_tex_uv must be a 2x2 matrix that transforms pixe-
//                  space offsets to texture uv offsets.  You can get this with:
//                      vec2 duv_dx = ddx(tex_uv);
//                      vec2 duv_dy = ddy(tex_uv);
//                      mat2x2 pixel_to_tex_uv = mat2x2(
//                          duv_dx.x, duv_dy.x,
//                          duv_dx.y, duv_dy.y);
//                  This is left to the user in case the current Cg profile
//                  doesn't support ddx()/ddy().  Ideally, the user could find
//                  calculate a distorted tangent-space mapping analytically.
//                  If not, a simple flat mapping can be obtained with:
//                      vec2 xy_to_uv_scale = IN.output_size *
//                          IN.video_size/IN.texture_size;
//                      mat2x2 pixel_to_tex_uv = mat2x2(
//                          xy_to_uv_scale.x, 0.0,
//                          0.0, xy_to_uv_scale.y);
//  Optional:   To set basic AA settings, #define ANTIALIAS_OVERRIDE_BASICS and:
//              1.) Set an antialiasing level:
//                      static float aa_level = {0 (none),
//                          1 (sample subpixels), 4, 5, 6, 7, 8, 12, 16, 20, 24}
//              2.) Set a filter type:
//                      static float aa_filter = {
//                          0 (Box, Separable), 1 (Box, Cylindrical),
//                          2 (Tent, Separable), 3 (Tent, Cylindrical)
//                          4 (Gaussian, Separable), 5 (Gaussian, Cylindrical)
//                          6 (Cubic, Separable), 7 (Cubic, Cylindrical)
//                          8 (Lanczos Sinc, Separable),
//                          9 (Lanczos Jinc, Cylindrical)}
//                  If the input is unknown, a separable box filter is used.
//                  Note: Lanczos Jinc is terrible for sparse sampling, and
//                  using aa_axis_importance (see below) defeats the purpose.
//              3.) Mirror the sample pattern on odd frames?
//                      static bool aa_temporal = {true, false]
//                  This helps rotational invariance but can look "fluttery."
//              The user may #define ANTIALIAS_OVERRIDE_PARAMETERS to override
//              (all of) the following default parameters with static or uniform
//              constants (or an accessor function for subpixel offsets):
//              1.) Cubic parameters:
//                      static float aa_cubic_c = 0.5;
//                  See http://www.imagemagick.org/Usage/filter/#mitchell
//              2.) Gaussian parameters:
//                      static float aa_gauss_sigma =
//                          0.5/aa_pixel_diameter;
//              3.) Set subpixel offsets.  This requires an accessor function
//                  for compatibility with scalar runtime shader   Return
//                  a vec2 pixel offset in [-0.5, 0.5] for the red subpixel:
//                      vec2 get_aa_subpixel_r_offset()
//              The user may also #define ANTIALIAS_OVERRIDE_STATIC_CONSTANTS to
//              override (all of) the following default static values.  However,
//              the file's structure requires them to be declared static const:
//              1.) static float aa_lanczos_lobes = 3.0;
//              2.) static float aa_gauss_support = 1.0/aa_pixel_diameter;
//                  Note the default tent/Gaussian support radii may appear
//                  arbitrary, but extensive testing found them nearly optimal
//                  for tough cases like strong distortion at low AA levels.
//                  (The Gaussian default is only best for practical gauss_sigma
//                  values; much larger gauss_sigmas ironically prefer slightly
//                  smaller support given sparse sampling, and vice versa.)
//              3.) static float aa_tent_support = 1.0 / aa_pixel_diameter;
//              4.) static vec2 aa_xy_axis_importance:
//                  The sparse N-queens sampling grid interacts poorly with
//                  negative-lobed 2D filters.  However, if aliasing is much
//                  stronger in one direction (e.g. horizontally with a phosphor
//                  mask), it can be useful to downplay sample offsets along the
//                  other axis.  The support radius in each direction scales with
//                  aa_xy_axis_importance down to a minimum of 0.5 (box support),
//                  after which point only the offsets used for calculating
//                  weights continue to scale downward.  This works as follows:
//                  If aa_xy_axis_importance = vec2(1.0, 1.0/support_radius),
//                  the vertical support radius will drop to 1.0, and we'll just
//                  filter vertical offsets with the first filter lobe, while
//                  horizontal offsets go through the full multi-lobe filter.
//                  If aa_xy_axis_importance = vec2(1.0, 0.0), the vertical
//                  support radius will drop to box support, and the vertical
//                  offsets will be ignored entirely (essentially giving us a
//                  box filter vertically).  The former is potentially smoother
//                  (but less predictable) and the default behavior of Lanczos
//                  jinc, whereas the latter is sharper and the default behavior
//                  of cubics and Lanczos sinc.
//              5.) static float aa_pixel_diameter: You can expand the
//                  pixel diameter to e.g. sqrt(2.0), which may be a better
//                  support range for cylindrical filters (they don't
//                  currently discard out-of-circle samples though).
//              Finally, there are two miscellaneous options:
//              1.) If you want to antialias a manually tiled texture, you can
//                  #define ANTIALIAS_DISABLE_ANISOTROPIC to use tex2Dlod() to
//                  fix incompatibilities with anisotropic filtering.  This is
//                  slower, and the Cg profile must support tex2Dlod().
//              2.) If aa_cubic_c is a runtime uniform, you can #define
//                  RUNTIME_ANTIALIAS_WEIGHTS to evaluate cubic weights once per
//                  fragment instead of at the usage site (which is used by
//                  default, because it enables static evaluation).
//  Description:
//  Each antialiased lookup follows these steps:
//  1.) Define a sample pattern of pixel offsets in the range of [-0.5, 0.5]
//      pixels, spanning the diameter of a rectangular box filter.
//  2.) Scale these offsets by the support diameter of the user's chosen filter.
//  3.) Using these pixel offsets from the pixel center, compute the offsets to
//      predefined subpixel locations.
//  4.) Compute filter weights based on subpixel offsets.
//  Much of that can often be done at compile-time.  At runtime:
//  1.) Project pixel-space offsets into uv-space with a matrix multiplication
//      to get the uv offsets for each sample.  Rectangular pixels have a
//      diameter of 1.0.  Circular pixels are not currently supported, but they
//      might be better with a diameter of sqrt(2.0) to ensure there are no gaps
//      between them.
//  2.) Load, weight, and sum samples.
//  We use a sparse bilinear sampling grid, so there are two major implications:
//  1.) We can directly project the pixel-space support box into uv-space even
//      if we're upsizing.  This wouldn't be the case for nearest neighbor,
//      where we'd have to expand the uv-space diameter to at least the support
//      size to ensure sufficient filter support.  In our case, this allows us
//      to treat upsizing the same as downsizing and use static weighting. :)
//  2.) For decent results, negative-lobed filters must be computed based on
//      separable weights, not radial distances, because the sparse sampling
//      makes no guarantees about radial distributions.  Even then, it's much
//      better to set aa_xy_axis_importance to e.g. vec2(1.0, 0.0) to use e.g.
//      Lanczos2 horizontally and a box filter vertically.  This is mainly due
//      to the sparse N-queens sampling and a statistically enormous positive or
//      negative covariance between horizontal and vertical weights.
//
//  Design Decision Comments:
//  "aa_temporal" mirrors the sample pattern on odd frames along the axis that
//  keeps subpixel weights constant.  This helps with rotational invariance, but
//  it can cause distracting fluctuations, and horizontal and vertical edges
//  will look the same.  Using a different pattern on a shifted grid would
//  exploit temporal AA better, but it would require a dynamic branch or a lot
//  of conditional moves, so it's prohibitively slow for the minor benefit.

/////////////////////////////  SETTINGS MANAGEMENT  ////////////////////////////

#ifndef ANTIALIAS_OVERRIDE_BASICS
    //  The following settings must be static constants:
    float aa_level = 12.0;
    float aa_filter = 0.0;
    bool aa_temporal = false;
#endif

#ifndef ANTIALIAS_OVERRIDE_STATIC_CONSTANTS
    //  Users may override these parameters, but the file structure requires
    //  them to be static constants; see the descriptions above.
    float aa_pixel_diameter = 1.0;
    float aa_lanczos_lobes = 3.0;
    float aa_gauss_support = 1.0 / aa_pixel_diameter;
    float aa_tent_support = 1.0 / aa_pixel_diameter;
    
    //  If we're using a negative-lobed filter, default to using it horizontally
    //  only, and use only the first lobe vertically or a box filter, over a
    //  correspondingly smaller range.  This compensates for the sparse sampling
    //  grid's typically large positive/negative x/y covariance.
    vec2 aa_xy_axis_importance =
        aa_filter < 5.5 ? vec2(1.0) :         //  Box, tent, Gaussian
        aa_filter < 8.5 ? vec2(1.0, 0.0) :    //  Cubic and Lanczos sinc
        aa_filter < 9.5 ? vec2(1.0, 1.0/aa_lanczos_lobes) :   //  Lanczos jinc
        vec2(1.0);                            //  Default to box
#endif

#ifndef ANTIALIAS_OVERRIDE_PARAMETERS
    //  Users may override these values with their own uniform or static consts.
    //  Cubics: See http://www.imagemagick.org/Usage/filter/#mitchell
    //  1.) "Keys cubics" with B = 1 - 2C are considered the highest quality.
    //  2.) C = 0.5 (default) is Catmull-Rom; higher C's apply sharpening.
    //  3.) C = 1.0/3.0 is the Mitchell-Netravali filter.
    //  4.) C = 0.0 is a soft spline filter.
//    float aa_cubic_c = 0.5;
//    float aa_gauss_sigma = 0.5 / aa_pixel_diameter;
    //  Users may override the subpixel offset accessor function with their own.
    //  A function is used for compatibility with scalar runtime shader 
    vec2 get_aa_subpixel_r_offset()
    {
        return vec2(0.0, 0.0);
    }
#endif

//////////////////////////////////  CONSTANTS  /////////////////////////////////

float aa_box_support = 0.5;
float aa_cubic_support = 2.0;


////////////////////////////  GLOBAL NON-CONSTANTS  ////////////////////////////

//  We'll want to define these only once per fragment at most.
#ifdef RUNTIME_ANTIALIAS_WEIGHTS
     float aa_cubic_b;
     float cubic_branch1_x3_coeff;
     float cubic_branch1_x2_coeff;
     float cubic_branch1_x0_coeff;
     float cubic_branch2_x3_coeff;
     float cubic_branch2_x2_coeff;
     float cubic_branch2_x1_coeff;
     float cubic_branch2_x0_coeff;
#endif


///////////////////////////////////  HELPERS  //////////////////////////////////

void assign_aa_cubic_constants()
{
    //  Compute cubic coefficients on demand at runtime, and save them to global
    //  uniforms.  The B parameter is computed from C, because "Keys cubics"
    //  with B = 1 - 2C are considered the highest quality.
    #ifdef RUNTIME_ANTIALIAS_WEIGHTS
        if(aa_filter > 5.5 && aa_filter < 7.5)
        {
            aa_cubic_b = 1.0 - 2.0*aa_cubic_c;
            cubic_branch1_x3_coeff = 12.0 - 9.0*aa_cubic_b - 6.0*aa_cubic_c;
            cubic_branch1_x2_coeff = -18.0 + 12.0*aa_cubic_b + 6.0*aa_cubic_c;
            cubic_branch1_x0_coeff = 6.0 - 2.0 * aa_cubic_b;
            cubic_branch2_x3_coeff = -aa_cubic_b - 6.0 * aa_cubic_c;
            cubic_branch2_x2_coeff = 6.0*aa_cubic_b + 30.0*aa_cubic_c;
            cubic_branch2_x1_coeff = -12.0*aa_cubic_b - 48.0*aa_cubic_c;
            cubic_branch2_x0_coeff = 8.0*aa_cubic_b + 24.0*aa_cubic_c;
        }
    #endif
}

vec4 get_subpixel_support_diam_and_final_axis_importance()
{
    //  Statically select the base support radius:
    float base_support_radius;	
        if(aa_filter < 1.5) base_support_radius = aa_box_support;
        else if(aa_filter < 3.5) base_support_radius = aa_tent_support;
        else if(aa_filter < 5.5) base_support_radius = aa_gauss_support;
        else if(aa_filter < 7.5) base_support_radius = aa_cubic_support;
        else if(aa_filter < 9.5) base_support_radius = aa_lanczos_lobes;
        else base_support_radius = aa_box_support; //  Default to box
    //  Expand the filter support for subpixel filtering.
    vec2 subpixel_support_radius_raw =
        vec2(base_support_radius) + abs(get_aa_subpixel_r_offset());
    if(aa_filter < 1.5)
    {
        //  Ignore aa_xy_axis_importance for box filtering.
        vec2 subpixel_support_diam =
            2.0 * subpixel_support_radius_raw;
        vec2 final_axis_importance = vec2(1.0);
        return vec4(subpixel_support_diam, final_axis_importance);
    }
    else
    {
        //  Scale the support window by aa_xy_axis_importance, but don't narrow
        //  it further than box support.  This allows decent vertical AA without
        //  messing up horizontal weights or using something silly like Lanczos4
        //  horizontally with a huge vertical average over an 8-pixel radius.
        vec2 subpixel_support_radius = max(vec2(aa_box_support),
            subpixel_support_radius_raw * aa_xy_axis_importance);
        //  Adjust aa_xy_axis_importance to compensate for what's already done:
        vec2 final_axis_importance = aa_xy_axis_importance *
            subpixel_support_radius_raw/subpixel_support_radius;
        vec2 subpixel_support_diam = 2.0 * subpixel_support_radius;
        return vec4(subpixel_support_diam, final_axis_importance);
    }
}

///////////////////////////  FILTER WEIGHT FUNCTIONS  //////////////////////////

float eval_box_filter(float dist)
{
if(abs(dist) <= aa_box_support) return 1.0;//abs(dist);
else return 0.0;
}

float eval_separable_box_filter(vec2 offset)
{
	if(all(lessThanEqual(abs(offset) , vec2(aa_box_support)))) return 1.0;//float(abs(offset));
	else return 0.0;
}

float eval_tent_filter(float dist)
{
    return clamp((aa_tent_support - dist)/
        aa_tent_support, 0.0, 1.0);
}

float eval_gaussian_filter(float dist)
{
    return exp(-(dist*dist) / (2.0*aa_gauss_sigma*aa_gauss_sigma));
}

float eval_cubic_filter(float dist)
{
    //  Compute coefficients like assign_aa_cubic_constants(), but statically.
    #ifndef RUNTIME_ANTIALIAS_WEIGHTS
        //  When runtime weights are used, these values are instead written to
        //  global uniforms at the beginning of each tex2Daa* call.
        float aa_cubic_b = 1.0 - 2.0*aa_cubic_c;
        float cubic_branch1_x3_coeff = 12.0 - 9.0*aa_cubic_b - 6.0*aa_cubic_c;
        float cubic_branch1_x2_coeff = -18.0 + 12.0*aa_cubic_b + 6.0*aa_cubic_c;
        float cubic_branch1_x0_coeff = 6.0 - 2.0 * aa_cubic_b;
        float cubic_branch2_x3_coeff = -aa_cubic_b - 6.0 * aa_cubic_c;
        float cubic_branch2_x2_coeff = 6.0*aa_cubic_b + 30.0*aa_cubic_c;
        float cubic_branch2_x1_coeff = -12.0*aa_cubic_b - 48.0*aa_cubic_c;
        float cubic_branch2_x0_coeff = 8.0*aa_cubic_b + 24.0*aa_cubic_c;
    #endif
    float abs_dist = abs(dist);
    //  Compute the cubic based on the Horner's method formula in:
    //  http://www.cs.utexas.edu/users/fussell/courses/cs384g/lectures/mitchell/Mitchell.pdf
    return (abs_dist < 1.0 ?
        (cubic_branch1_x3_coeff*abs_dist +
            cubic_branch1_x2_coeff)*abs_dist*abs_dist +
            cubic_branch1_x0_coeff :
        abs_dist < 2.0 ?
            ((cubic_branch2_x3_coeff*abs_dist +
                cubic_branch2_x2_coeff)*abs_dist +
                cubic_branch2_x1_coeff)*abs_dist + cubic_branch2_x0_coeff :
            0.0)/6.0;
}

float eval_separable_cubic_filter(vec2 offset)
{
    //  This is faster than using a specific vec2 version:
    return eval_cubic_filter(offset.x) *
        eval_cubic_filter(offset.y);
}

vec2 eval_sinc_filter(vec2 offset)
{
    //  It's faster to let the caller handle the zero case, or at least it
    //  was when I used macros and the shader preset took a full minute to load.
    vec2 pi_offset = pi * offset;
    return sin(pi_offset)/pi_offset;
}

float eval_separable_lanczos_sinc_filter(vec2 offset_unsafe)
{
    //  Note: For sparse sampling, you really need to pick an axis to use
    //  Lanczos along (e.g. set aa_xy_axis_importance = vec2(1.0, 0.0)).
    vec2 offset = FIX_ZERO(offset_unsafe);
    vec2 xy_weights = eval_sinc_filter(offset) *
        eval_sinc_filter(offset/aa_lanczos_lobes);
    return xy_weights.x * xy_weights.y;
}

float eval_jinc_filter_unorm(float x)
{
    //  This is a Jinc approximation for x in [0, 45).  We'll use x in range
    //  [0, 4*pi) or so.  There are faster/closer approximations based on
    //  piecewise cubics from [0, 45) and asymptotic approximations beyond that,
    //  but this has a maximum absolute error < 1/512, and it's simpler/faster
    //  for shaders...not that it's all that useful for sparse sampling anyway.
    float point3845_x = 0.38448566093564*x;
    float exp_term = exp(-(point3845_x*point3845_x));
    float point8154_plus_x = 0.815362332840791 + x;
    float cos_term = cos(point8154_plus_x);
    return (
        0.0264727330997042*min(x, 6.83134964622778) +
        0.680823557250528*exp_term +
        -0.0597255978950933*min(7.41043194481873, x)*cos_term /
            (point8154_plus_x + 0.0646074538634482*(x*x) +
            cos(x)*max(exp_term, cos(x) + cos_term)) -
        0.180837503591406);
}

float eval_jinc_filter(float dist)
{
    return eval_jinc_filter_unorm(pi * dist);
}

float eval_lanczos_jinc_filter(float dist)
{
    return eval_jinc_filter(dist) * eval_jinc_filter(dist/aa_lanczos_lobes);
}


vec3 eval_unorm_rgb_weights(vec2 offset,
    vec2 final_axis_importance)
{
    //  Requires:   1.) final_axis_impportance must be computed according to
    //                  get_subpixel_support_diam_and_final_axis_importance().
    //              2.) aa_filter must be a global constant.
    //              3.) offset must be an xy pixel offset in the range:
    //                      ([-subpixel_support_diameter.x/2,
    //                      subpixel_support_diameter.x/2],
    //                      [-subpixel_support_diameter.y/2,
    //                      subpixel_support_diameter.y/2])
    //  Returns:    Sample weights at R/G/B destination subpixels for the
    //              given xy pixel offset.
    vec2 offset_g = offset * final_axis_importance;
    vec2 aa_r_offset = get_aa_subpixel_r_offset();
    vec2 offset_r = offset_g - aa_r_offset * final_axis_importance;
    vec2 offset_b = offset_g + aa_r_offset * final_axis_importance;
    //  Statically select a filter:
    if(aa_filter < 0.5)
    {
        return vec3(eval_separable_box_filter(offset_r),
            eval_separable_box_filter(offset_g),
            eval_separable_box_filter(offset_b));
    }
    else if(aa_filter < 1.5)
    {
        return vec3(eval_box_filter(length(offset_r)),
            eval_box_filter(length(offset_g)),
            eval_box_filter(length(offset_b)));
    }
    else if(aa_filter < 2.5)
    {
        return vec3(
            eval_tent_filter(offset_r.x) * eval_tent_filter(offset_r.y),
            eval_tent_filter(offset_g.x) * eval_tent_filter(offset_g.y),
            eval_tent_filter(offset_b.x) * eval_tent_filter(offset_b.y));
    }
    else if(aa_filter < 3.5)
    {
        return vec3(eval_tent_filter(length(offset_r)),
            eval_tent_filter(length(offset_g)),
            eval_tent_filter(length(offset_b)));
    }
    else if(aa_filter < 4.5)
    {
        return vec3(
            eval_gaussian_filter(offset_r.x) * eval_gaussian_filter(offset_r.y),
            eval_gaussian_filter(offset_g.x) * eval_gaussian_filter(offset_g.y),
            eval_gaussian_filter(offset_b.x) * eval_gaussian_filter(offset_b.y));
    }
    else if(aa_filter < 5.5)
    {
        return vec3(eval_gaussian_filter(length(offset_r)),
            eval_gaussian_filter(length(offset_g)),
            eval_gaussian_filter(length(offset_b)));
    }
    else if(aa_filter < 6.5)
    {
        return vec3(
            eval_cubic_filter(offset_r.x) * eval_cubic_filter(offset_r.y),
            eval_cubic_filter(offset_g.x) * eval_cubic_filter(offset_g.y),
            eval_cubic_filter(offset_b.x) * eval_cubic_filter(offset_b.y));
    }
    else if(aa_filter < 7.5)
    {
        return vec3(eval_cubic_filter(length(offset_r)),
            eval_cubic_filter(length(offset_g)),
            eval_cubic_filter(length(offset_b)));
    }
    else if(aa_filter < 8.5)
    {
        return vec3(eval_separable_lanczos_sinc_filter(offset_r),
            eval_separable_lanczos_sinc_filter(offset_g),
            eval_separable_lanczos_sinc_filter(offset_b));
    }
    else if(aa_filter < 9.5)
    {
        return vec3(eval_lanczos_jinc_filter(length(offset_r)),
            eval_lanczos_jinc_filter(length(offset_g)),
            eval_lanczos_jinc_filter(length(offset_b)));
    }
    else
    {
        //  Default to a box, because Lanczos Jinc is so bad. ;)
        return vec3(eval_separable_box_filter(offset_r),
            eval_separable_box_filter(offset_g),
            eval_separable_box_filter(offset_b));
    }
}

//////////////////////////////  HELPER FUNCTIONS  //////////////////////////////

vec4 tex2Daa_tiled_linearize(sampler2D samp, vec2 s)
{
    //  If we're manually tiling a texture, anisotropic filtering can get
    //  confused.  This is one workaround:
    #ifdef ANTIALIAS_DISABLE_ANISOTROPIC
        //  TODO: Use tex2Dlod_linearize with a calculated mip level.
        return tex2Dlod_linearize(samp, vec4(s, 0.0, 0.0));
    #else
        return tex2D_linearize(samp, s);
    #endif
}

vec2 get_frame_sign(float frame)
{
    if(aa_temporal == true)
    {
        //  Mirror the sampling pattern for odd frames in a direction that
        //  lets us keep the same subpixel sample weights:
        float frame_odd = float(mod(frame, 2.0) > 0.5);
        vec2 aa_r_offset = get_aa_subpixel_r_offset();
        vec2 mirror = vec2(FIX_ZERO(0.0));
		if ( abs(aa_r_offset.x) < FIX_ZERO(0.0)) mirror.x = abs(aa_r_offset.x);
		if ( abs(aa_r_offset.y) < FIX_ZERO(0.0)) mirror.y = abs(aa_r_offset.y);
        return vec2(-1.0) * mirror;
    }
    else
    {
        return vec2(1.0);
    }
}

/////////////////////////  ANTIALIASED TEXTURE LOOKUPS  ////////////////////////

vec3 tex2Daa_subpixel_weights_only(sampler2D tex, 
    vec2 coord, mat2x2 pixel_to_tex_uv)
{
    //  This function is unlike the others: Just perform a single independent
    //  lookup for each subpixel.  It may be very aliased.
    vec2 aa_r_offset = get_aa_subpixel_r_offset();
    vec2 aa_r_offset_uv_offset = (aa_r_offset * pixel_to_tex_uv);
    float color_g = tex2D_linearize(tex, coord).g;
    float color_r = tex2D_linearize(tex, coord + aa_r_offset_uv_offset).r;
    float color_b = tex2D_linearize(tex, coord - aa_r_offset_uv_offset).b;
    return vec3(color_r, color_g, color_b);
}

//  The tex2Daa* functions compile very slowly due to all the macros and
//  compile-time math, so only include the ones we'll actually use!
vec3 tex2Daa4x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use an RGMS4 pattern (4-queens):
    //  . . Q .  : off =(-1.5, -1.5)/4 + (2.0, 0.0)/4
    //  Q . . .  : off =(-1.5, -1.5)/4 + (0.0, 1.0)/4
    //  . . . Q  : off =(-1.5, -1.5)/4 + (3.0, 2.0)/4
    //  . Q . .  : off =(-1.5, -1.5)/4 + (1.0, 3.0)/4
    //  Static screenspace sample offsets (compute some implicitly):
    float grid_size = 4.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(2.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(0.0, 1.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = w1.bgr;
    vec3 w3 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (w0 * sample0 + w1 * sample1 +
        w2 * sample2 + w3 * sample3);
}

vec3 tex2Daa5x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 5-queens pattern:
    //  . Q . . .  : off =(-2.0, -2.0)/5 + (1.0, 0.0)/5
    //  . . . . Q  : off =(-2.0, -2.0)/5 + (4.0, 1.0)/5
    //  . . Q . .  : off =(-2.0, -2.0)/5 + (2.0, 2.0)/5
    //  Q . . . .  : off =(-2.0, -2.0)/5 + (0.0, 3.0)/5
    //  . . . Q .  : off =(-2.0, -2.0)/5 + (3.0, 4.0)/5
    //  Static screenspace sample offsets (compute some implicitly):
    float grid_size = 5.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(1.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(4.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(2.0, 2.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = w1.bgr;
    vec3 w4 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 w_sum_inv = vec3(1.0)/(w0 + w1 + w2 + w3 + w4);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (w0 * sample0 + w1 * sample1 +
        w2 * sample2 + w3 * sample3 + w4 * sample4);
}

vec3 tex2Daa6x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 6-queens pattern with a stronger horizontal
    //  than vertical slant:
    //  . . . . Q .  : off =(-2.5, -2.5)/6 + (4.0, 0.0)/6
    //  . . Q . . .  : off =(-2.5, -2.5)/6 + (2.0, 1.0)/6
    //  Q . . . . .  : off =(-2.5, -2.5)/6 + (0.0, 2.0)/6
    //  . . . . . Q  : off =(-2.5, -2.5)/6 + (5.0, 3.0)/6
    //  . . . Q . .  : off =(-2.5, -2.5)/6 + (3.0, 4.0)/6
    //  . Q . . . .  : off =(-2.5, -2.5)/6 + (1.0, 5.0)/6
    //  Static screenspace sample offsets (compute some implicitly):
    float grid_size = 6.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(4.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(2.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(0.0, 2.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = w2.bgr;
    vec3 w4 = w1.bgr;
    vec3 w5 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (w0 * sample0 + w1 * sample1 + w2 * sample2 +
        w3 * sample3 + w4 * sample4 + w5 * sample5);
}

vec3 tex2Daa7x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 7-queens pattern with a queen in the center:
    //  . Q . . . . .  : off =(-3.0, -3.0)/7 + (1.0, 0.0)/7
    //  . . . . Q . .  : off =(-3.0, -3.0)/7 + (4.0, 1.0)/7
    //  Q . . . . . .  : off =(-3.0, -3.0)/7 + (0.0, 2.0)/7
    //  . . . Q . . .  : off =(-3.0, -3.0)/7 + (3.0, 3.0)/7
    //  . . . . . . Q  : off =(-3.0, -3.0)/7 + (6.0, 4.0)/7
    //  . . Q . . . .  : off =(-3.0, -3.0)/7 + (2.0, 5.0)/7
    //  . . . . . Q .  : off =(-3.0, -3.0)/7 + (5.0, 6.0)/7
    float grid_size = 7.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(1.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(4.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(0.0, 2.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(3.0, 3.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = w2.bgr;
    vec3 w5 = w1.bgr;
    vec3 w6 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2;
    vec3 w_sum = half_sum + half_sum.bgr + w3;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6);
}

vec3 tex2Daa8x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 8-queens pattern.
    //  . . Q . . . . .  : off =(-3.5, -3.5)/8 + (2.0, 0.0)/8
    //  . . . . Q . . .  : off =(-3.5, -3.5)/8 + (4.0, 1.0)/8
    //  . Q . . . . . .  : off =(-3.5, -3.5)/8 + (1.0, 2.0)/8
    //  . . . . . . . Q  : off =(-3.5, -3.5)/8 + (7.0, 3.0)/8
    //  Q . . . . . . .  : off =(-3.5, -3.5)/8 + (0.0, 4.0)/8
    //  . . . . . . Q .  : off =(-3.5, -3.5)/8 + (6.0, 5.0)/8
    //  . . . Q . . . .  : off =(-3.5, -3.5)/8 + (3.0, 6.0)/8
    //  . . . . . Q . .  : off =(-3.5, -3.5)/8 + (5.0, 7.0)/8
    float grid_size = 8.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(2.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(4.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(1.0, 2.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(7.0, 3.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = w3.bgr;
    vec3 w5 = w2.bgr;
    vec3 w6 = w1.bgr;
    vec3 w7 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2 + w3;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, and mirror on odd frames if directed:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset3 = (xy_offset3 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset3).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset3).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample7 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7);
}

vec3 tex2Daa12x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 12-superqueens pattern where no 3 points are
    //  exactly collinear.
    //  . . . Q . . . . . . . .  : off =(-5.5, -5.5)/12 + (3.0, 0.0)/12
    //  . . . . . . . . . Q . .  : off =(-5.5, -5.5)/12 + (9.0, 1.0)/12
    //  . . . . . . Q . . . . .  : off =(-5.5, -5.5)/12 + (6.0, 2.0)/12
    //  . Q . . . . . . . . . .  : off =(-5.5, -5.5)/12 + (1.0, 3.0)/12
    //  . . . . . . . . . . . Q  : off =(-5.5, -5.5)/12 + (11.0, 4.0)/12
    //  . . . . Q . . . . . . .  : off =(-5.5, -5.5)/12 + (4.0, 5.0)/12
    //  . . . . . . . Q . . . .  : off =(-5.5, -5.5)/12 + (7.0, 6.0)/12
    //  Q . . . . . . . . . . .  : off =(-5.5, -5.5)/12 + (0.0, 7.0)/12
    //  . . . . . . . . . . Q .  : off =(-5.5, -5.5)/12 + (10.0, 8.0)/12
    //  . . . . . Q . . . . . .  : off =(-5.5, -5.5)/12 + (5.0, 9.0)/12
    //  . . Q . . . . . . . . .  : off =(-5.5, -5.5)/12 + (2.0, 10.0)/12
    //  . . . . . . . . Q . . .  : off =(-5.5, -5.5)/12 + (8.0, 11.0)/12
    float grid_size = 12.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(3.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(9.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(6.0, 2.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(1.0, 3.0) * xy_step;
    vec2 xy_offset4 = xy_start_offset + vec2(11.0, 4.0) * xy_step;
    vec2 xy_offset5 = xy_start_offset + vec2(4.0, 5.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = eval_unorm_rgb_weights(xy_offset4, final_axis_importance);
    vec3 w5 = eval_unorm_rgb_weights(xy_offset5, final_axis_importance);
    vec3 w6 = w5.bgr;
    vec3 w7 = w4.bgr;
    vec3 w8 = w3.bgr;
    vec3 w9 = w2.bgr;
    vec3 w10 = w1.bgr;
    vec3 w11 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2 + w3 + w4 + w5;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/w_sum;
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset3 = (xy_offset3 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset4 = (xy_offset4 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset5 = (xy_offset5 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset3).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset4).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset5).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset5).rgb;
    vec3 sample7 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset4).rgb;
    vec3 sample8 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset3).rgb;
    vec3 sample9 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample10 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample11 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7 +
        w8 * sample8 + w9 * sample9 + w10 * sample10 + w11 * sample11);
}

vec3 tex2Daa16x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 16-superqueens pattern where no 3 points are
    //  exactly collinear.
    //  . . Q . . . . . . . . . . . . .  : off =(-7.5, -7.5)/16 + (2.0, 0.0)/16
    //  . . . . . . . . . Q . . . . . .  : off =(-7.5, -7.5)/16 + (9.0, 1.0)/16
    //  . . . . . . . . . . . . Q . . .  : off =(-7.5, -7.5)/16 + (12.0, 2.0)/16
    //  . . . . Q . . . . . . . . . . .  : off =(-7.5, -7.5)/16 + (4.0, 3.0)/16
    //  . . . . . . . . Q . . . . . . .  : off =(-7.5, -7.5)/16 + (8.0, 4.0)/16
    //  . . . . . . . . . . . . . . Q .  : off =(-7.5, -7.5)/16 + (14.0, 5.0)/16
    //  Q . . . . . . . . . . . . . . .  : off =(-7.5, -7.5)/16 + (0.0, 6.0)/16
    //  . . . . . . . . . . Q . . . . .  : off =(-7.5, -7.5)/16 + (10.0, 7.0)/16
    //  . . . . . Q . . . . . . . . . .  : off =(-7.5, -7.5)/16 + (5.0, 8.0)/16
    //  . . . . . . . . . . . . . . . Q  : off =(-7.5, -7.5)/16 + (15.0, 9.0)/16
    //  . Q . . . . . . . . . . . . . .  : off =(-7.5, -7.5)/16 + (1.0, 10.0)/16
    //  . . . . . . . Q . . . . . . . .  : off =(-7.5, -7.5)/16 + (7.0, 11.0)/16
    //  . . . . . . . . . . . Q . . . .  : off =(-7.5, -7.5)/16 + (11.0, 12.0)/16
    //  . . . Q . . . . . . . . . . . .  : off =(-7.5, -7.5)/16 + (3.0, 13.0)/16
    //  . . . . . . Q . . . . . . . . .  : off =(-7.5, -7.5)/16 + (6.0, 14.0)/16
    //  . . . . . . . . . . . . . Q . .  : off =(-7.5, -7.5)/16 + (13.0, 15.0)/16
    float grid_size = 16.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(2.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(9.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(12.0, 2.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(4.0, 3.0) * xy_step;
    vec2 xy_offset4 = xy_start_offset + vec2(8.0, 4.0) * xy_step;
    vec2 xy_offset5 = xy_start_offset + vec2(14.0, 5.0) * xy_step;
    vec2 xy_offset6 = xy_start_offset + vec2(0.0, 6.0) * xy_step;
    vec2 xy_offset7 = xy_start_offset + vec2(10.0, 7.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = eval_unorm_rgb_weights(xy_offset4, final_axis_importance);
    vec3 w5 = eval_unorm_rgb_weights(xy_offset5, final_axis_importance);
    vec3 w6 = eval_unorm_rgb_weights(xy_offset6, final_axis_importance);
    vec3 w7 = eval_unorm_rgb_weights(xy_offset7, final_axis_importance);
    vec3 w8 = w7.bgr;
    vec3 w9 = w6.bgr;
    vec3 w10 = w5.bgr;
    vec3 w11 = w4.bgr;
    vec3 w12 = w3.bgr;
    vec3 w13 = w2.bgr;
    vec3 w14 = w1.bgr;
    vec3 w15 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset3 = (xy_offset3 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset4 = (xy_offset4 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset5 = (xy_offset5 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset6 = (xy_offset6 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset7 = (xy_offset7 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset3).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset4).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset5).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset6).rgb;
    vec3 sample7 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset7).rgb;
    vec3 sample8 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset7).rgb;
    vec3 sample9 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset6).rgb;
    vec3 sample10 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset5).rgb;
    vec3 sample11 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset4).rgb;
    vec3 sample12 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset3).rgb;
    vec3 sample13 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample14 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample15 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7 +
        w8 * sample8 + w9 * sample9 + w10 * sample10 + w11 * sample11 +
        w12 * sample12 + w13 * sample13 + w14 * sample14 + w15 * sample15);
}

vec3 tex2Daa20x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 20-superqueens pattern where no 3 points are
    //  exactly collinear and superqueens have a squared attack radius of 13.
    //  . . . . . . . Q . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (7.0, 0.0)/20
    //  . . . . . . . . . . . . . . . . Q . . .  : off =(-9.5, -9.5)/20 + (16.0, 1.0)/20
    //  . . . . . . . . . . . Q . . . . . . . .  : off =(-9.5, -9.5)/20 + (11.0, 2.0)/20
    //  . Q . . . . . . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (1.0, 3.0)/20
    //  . . . . . Q . . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (5.0, 4.0)/20
    //  . . . . . . . . . . . . . . . Q . . . .  : off =(-9.5, -9.5)/20 + (15.0, 5.0)/20
    //  . . . . . . . . . . Q . . . . . . . . .  : off =(-9.5, -9.5)/20 + (10.0, 6.0)/20
    //  . . . . . . . . . . . . . . . . . . . Q  : off =(-9.5, -9.5)/20 + (19.0, 7.0)/20
    //  . . Q . . . . . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (2.0, 8.0)/20
    //  . . . . . . Q . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (6.0, 9.0)/20
    //  . . . . . . . . . . . . . Q . . . . . .  : off =(-9.5, -9.5)/20 + (13.0, 10.0)/20
    //  . . . . . . . . . . . . . . . . . Q . .  : off =(-9.5, -9.5)/20 + (17.0, 11.0)/20
    //  Q . . . . . . . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (0.0, 12.0)/20
    //  . . . . . . . . . Q . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (9.0, 13.0)/20
    //  . . . . Q . . . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (4.0, 14.0)/20
    //  . . . . . . . . . . . . . . Q . . . . .  : off =(-9.5, -9.5)/20 + (14.0, 15.0)/20
    //  . . . . . . . . . . . . . . . . . . Q .  : off =(-9.5, -9.5)/20 + (18.0, 16.0)/20
    //  . . . . . . . . Q . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (8.0, 17.0)/20
    //  . . . Q . . . . . . . . . . . . . . . .  : off =(-9.5, -9.5)/20 + (3.0, 18.0)/20
    //  . . . . . . . . . . . . Q . . . . . . .  : off =(-9.5, -9.5)/20 + (12.0, 19.0)/20
    float grid_size = 20.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(7.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(16.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(11.0, 2.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(1.0, 3.0) * xy_step;
    vec2 xy_offset4 = xy_start_offset + vec2(5.0, 4.0) * xy_step;
    vec2 xy_offset5 = xy_start_offset + vec2(15.0, 5.0) * xy_step;
    vec2 xy_offset6 = xy_start_offset + vec2(10.0, 6.0) * xy_step;
    vec2 xy_offset7 = xy_start_offset + vec2(19.0, 7.0) * xy_step;
    vec2 xy_offset8 = xy_start_offset + vec2(2.0, 8.0) * xy_step;
    vec2 xy_offset9 = xy_start_offset + vec2(6.0, 9.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = eval_unorm_rgb_weights(xy_offset4, final_axis_importance);
    vec3 w5 = eval_unorm_rgb_weights(xy_offset5, final_axis_importance);
    vec3 w6 = eval_unorm_rgb_weights(xy_offset6, final_axis_importance);
    vec3 w7 = eval_unorm_rgb_weights(xy_offset7, final_axis_importance);
    vec3 w8 = eval_unorm_rgb_weights(xy_offset8, final_axis_importance);
    vec3 w9 = eval_unorm_rgb_weights(xy_offset9, final_axis_importance);
    vec3 w10 = w9.bgr;
    vec3 w11 = w8.bgr;
    vec3 w12 = w7.bgr;
    vec3 w13 = w6.bgr;
    vec3 w14 = w5.bgr;
    vec3 w15 = w4.bgr;
    vec3 w16 = w3.bgr;
    vec3 w17 = w2.bgr;
    vec3 w18 = w1.bgr;
    vec3 w19 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset3 = (xy_offset3 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset4 = (xy_offset4 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset5 = (xy_offset5 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset6 = (xy_offset6 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset7 = (xy_offset7 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset8 = (xy_offset8 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset9 = (xy_offset9 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset3).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset4).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset5).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset6).rgb;
    vec3 sample7 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset7).rgb;
    vec3 sample8 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset8).rgb;
    vec3 sample9 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset9).rgb;
    vec3 sample10 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset9).rgb;
    vec3 sample11 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset8).rgb;
    vec3 sample12 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset7).rgb;
    vec3 sample13 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset6).rgb;
    vec3 sample14 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset5).rgb;
    vec3 sample15 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset4).rgb;
    vec3 sample16 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset3).rgb;
    vec3 sample17 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample18 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample19 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7 +
        w8 * sample8 + w9 * sample9 + w10 * sample10 + w11 * sample11 +
        w12 * sample12 + w13 * sample13 + w14 * sample14 + w15 * sample15 +
        w16 * sample16 + w17 * sample17 + w18 * sample18 + w19 * sample19);
}

vec3 tex2Daa24x(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Use a diagonally symmetric 24-superqueens pattern where no 3 points are
    //  exactly collinear and superqueens have a squared attack radius of 13.
    //  . . . . . . Q . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (6.0, 0.0)/24
    //  . . . . . . . . . . . . . . . . Q . . . . . . .  : off =(-11.5, -11.5)/24 + (16.0, 1.0)/24
    //  . . . . . . . . . . Q . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (10.0, 2.0)/24
    //  . . . . . . . . . . . . . . . . . . . . . Q . .  : off =(-11.5, -11.5)/24 + (21.0, 3.0)/24
    //  . . . . . Q . . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (5.0, 4.0)/24
    //  . . . . . . . . . . . . . . . Q . . . . . . . .  : off =(-11.5, -11.5)/24 + (15.0, 5.0)/24
    //  . Q . . . . . . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (1.0, 6.0)/24
    //  . . . . . . . . . . . Q . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (11.0, 7.0)/24
    //  . . . . . . . . . . . . . . . . . . . Q . . . .  : off =(-11.5, -11.5)/24 + (19.0, 8.0)/24
    //  . . . . . . . . . . . . . . . . . . . . . . . Q  : off =(-11.5, -11.5)/24 + (23.0, 9.0)/24
    //  . . . Q . . . . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (3.0, 10.0)/24
    //  . . . . . . . . . . . . . . Q . . . . . . . . .  : off =(-11.5, -11.5)/24 + (14.0, 11.0)/24
    //  . . . . . . . . . Q . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (9.0, 12.0)/24
    //  . . . . . . . . . . . . . . . . . . . . Q . . .  : off =(-11.5, -11.5)/24 + (20.0, 13.0)/24
    //  Q . . . . . . . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (0.0, 14.0)/24
    //  . . . . Q . . . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (4.0, 15.0)/24
    //  . . . . . . . . . . . . Q . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (12.0, 16.0)/24
    //  . . . . . . . . . . . . . . . . . . . . . . Q .  : off =(-11.5, -11.5)/24 + (22.0, 17.0)/24
    //  . . . . . . . . Q . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (8.0, 18.0)/24
    //  . . . . . . . . . . . . . . . . . . Q . . . . .  : off =(-11.5, -11.5)/24 + (18.0, 19.0)/24
    //  . . Q . . . . . . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (2.0, 20.0)/24
    //  . . . . . . . . . . . . . Q . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (13.0, 21.0)/24
    //  . . . . . . . Q . . . . . . . . . . . . . . . .  : off =(-11.5, -11.5)/24 + (7.0, 22.0)/24
    //  . . . . . . . . . . . . . . . . . Q . . . . . .  : off =(-11.5, -11.5)/24 + (17.0, 23.0)/24
    float grid_size = 24.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample.  Exploit diagonal symmetry:
    vec2 xy_offset0 = xy_start_offset + vec2(6.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(16.0, 1.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(10.0, 2.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(21.0, 3.0) * xy_step;
    vec2 xy_offset4 = xy_start_offset + vec2(5.0, 4.0) * xy_step;
    vec2 xy_offset5 = xy_start_offset + vec2(15.0, 5.0) * xy_step;
    vec2 xy_offset6 = xy_start_offset + vec2(1.0, 6.0) * xy_step;
    vec2 xy_offset7 = xy_start_offset + vec2(11.0, 7.0) * xy_step;
    vec2 xy_offset8 = xy_start_offset + vec2(19.0, 8.0) * xy_step;
    vec2 xy_offset9 = xy_start_offset + vec2(23.0, 9.0) * xy_step;
    vec2 xy_offset10 = xy_start_offset + vec2(3.0, 10.0) * xy_step;
    vec2 xy_offset11 = xy_start_offset + vec2(14.0, 11.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = eval_unorm_rgb_weights(xy_offset4, final_axis_importance);
    vec3 w5 = eval_unorm_rgb_weights(xy_offset5, final_axis_importance);
    vec3 w6 = eval_unorm_rgb_weights(xy_offset6, final_axis_importance);
    vec3 w7 = eval_unorm_rgb_weights(xy_offset7, final_axis_importance);
    vec3 w8 = eval_unorm_rgb_weights(xy_offset8, final_axis_importance);
    vec3 w9 = eval_unorm_rgb_weights(xy_offset9, final_axis_importance);
    vec3 w10 = eval_unorm_rgb_weights(xy_offset10, final_axis_importance);
    vec3 w11 = eval_unorm_rgb_weights(xy_offset11, final_axis_importance);
    vec3 w12 = w11.bgr;
    vec3 w13 = w10.bgr;
    vec3 w14 = w9.bgr;
    vec3 w15 = w8.bgr;
    vec3 w16 = w7.bgr;
    vec3 w17 = w6.bgr;
    vec3 w18 = w5.bgr;
    vec3 w19 = w4.bgr;
    vec3 w20 = w3.bgr;
    vec3 w21 = w2.bgr;
    vec3 w22 = w1.bgr;
    vec3 w23 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2 + w3 + w4 +
        w5 + w6 + w7 + w8 + w9 + w10 + w11;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, mirror on odd frames if directed, and exploit
    //  diagonal symmetry:
    vec2 frame_sign = get_frame_sign(frame);
    vec2 uv_offset0 = (xy_offset0 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset1 = (xy_offset1 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset2 = (xy_offset2 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset3 = (xy_offset3 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset4 = (xy_offset4 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset5 = (xy_offset5 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset6 = (xy_offset6 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset7 = (xy_offset7 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset8 = (xy_offset8 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset9 = (xy_offset9 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset10 = (xy_offset10 * frame_sign * true_pixel_to_tex_uv);
    vec2 uv_offset11 = (xy_offset11 * frame_sign * true_pixel_to_tex_uv);
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset0).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset1).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset2).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset3).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset4).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset5).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset6).rgb;
    vec3 sample7 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset7).rgb;
    vec3 sample8 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset8).rgb;
    vec3 sample9 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset9).rgb;
    vec3 sample10 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset10).rgb;
    vec3 sample11 = tex2Daa_tiled_linearize(tex, tex_uv + uv_offset11).rgb;
    vec3 sample12 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset11).rgb;
    vec3 sample13 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset10).rgb;
    vec3 sample14 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset9).rgb;
    vec3 sample15 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset8).rgb;
    vec3 sample16 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset7).rgb;
    vec3 sample17 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset6).rgb;
    vec3 sample18 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset5).rgb;
    vec3 sample19 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset4).rgb;
    vec3 sample20 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset3).rgb;
    vec3 sample21 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset2).rgb;
    vec3 sample22 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset1).rgb;
    vec3 sample23 = tex2Daa_tiled_linearize(tex, tex_uv - uv_offset0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7 +
        w8 * sample8 + w9 * sample9 + w10 * sample10 + w11 * sample11 +
        w12 * sample12 + w13 * sample13 + w14 * sample14 + w15 * sample15 +
        w16 * sample16 + w17 * sample17 + w18 * sample18 + w19 * sample19 +
        w20 * sample20 + w21 * sample21 + w22 * sample22 + w23 * sample23);
}

vec3 tex2Daa_debug_16x_regular(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Sample on a regular 4x4 grid.  This is mainly for testing.
    float grid_size = 4.0;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    vec2 xy_step = vec2(1.0)/grid_size * subpixel_support_diameter;
    vec2 xy_start_offset = vec2(0.5 - grid_size*0.5) * xy_step;
    //  Get the xy offset of each sample:
    vec2 xy_offset0 = xy_start_offset + vec2(0.0, 0.0) * xy_step;
    vec2 xy_offset1 = xy_start_offset + vec2(1.0, 0.0) * xy_step;
    vec2 xy_offset2 = xy_start_offset + vec2(2.0, 0.0) * xy_step;
    vec2 xy_offset3 = xy_start_offset + vec2(3.0, 0.0) * xy_step;
    vec2 xy_offset4 = xy_start_offset + vec2(0.0, 1.0) * xy_step;
    vec2 xy_offset5 = xy_start_offset + vec2(1.0, 1.0) * xy_step;
    vec2 xy_offset6 = xy_start_offset + vec2(2.0, 1.0) * xy_step;
    vec2 xy_offset7 = xy_start_offset + vec2(3.0, 1.0) * xy_step;
    //  Compute subpixel weights, and exploit diagonal symmetry for speed.
    //  (We can't exploit vertical or horizontal symmetry due to uncertain
    //  subpixel offsets.  We could fix that by rotating xy offsets with the
    //  subpixel structure, but...no.)
    vec3 w0 = eval_unorm_rgb_weights(xy_offset0, final_axis_importance);
    vec3 w1 = eval_unorm_rgb_weights(xy_offset1, final_axis_importance);
    vec3 w2 = eval_unorm_rgb_weights(xy_offset2, final_axis_importance);
    vec3 w3 = eval_unorm_rgb_weights(xy_offset3, final_axis_importance);
    vec3 w4 = eval_unorm_rgb_weights(xy_offset4, final_axis_importance);
    vec3 w5 = eval_unorm_rgb_weights(xy_offset5, final_axis_importance);
    vec3 w6 = eval_unorm_rgb_weights(xy_offset6, final_axis_importance);
    vec3 w7 = eval_unorm_rgb_weights(xy_offset7, final_axis_importance);
    vec3 w8 = w7.bgr;
    vec3 w9 = w6.bgr;
    vec3 w10 = w5.bgr;
    vec3 w11 = w4.bgr;
    vec3 w12 = w3.bgr;
    vec3 w13 = w2.bgr;
    vec3 w14 = w1.bgr;
    vec3 w15 = w0.bgr;
    //  Get the weight sum to normalize the total to 1.0 later:
    vec3 half_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7;
    vec3 w_sum = half_sum + half_sum.bgr;
    vec3 w_sum_inv = vec3(1.0)/(w_sum);
    //  Scale the pixel-space to texture offset matrix by the pixel diameter.
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    //  Get uv sample offsets, taking advantage of row alignment:
    vec2 uv_step_x = (vec2(xy_step.x, 0.0) * true_pixel_to_tex_uv);
    vec2 uv_step_y = (vec2(0.0, xy_step.y) * true_pixel_to_tex_uv);
    vec2 uv_offset0 = -1.5 * (uv_step_x + uv_step_y);
    vec2 sample0_uv = tex_uv + uv_offset0;
    vec2 sample4_uv = sample0_uv + uv_step_y;
    vec2 sample8_uv = sample0_uv + uv_step_y * 2.0;
    vec2 sample12_uv = sample0_uv + uv_step_y * 3.0;
    //  Load samples, linearizing if necessary, etc.:
    vec3 sample0 = tex2Daa_tiled_linearize(tex, sample0_uv).rgb;
    vec3 sample1 = tex2Daa_tiled_linearize(tex, sample0_uv + uv_step_x).rgb;
    vec3 sample2 = tex2Daa_tiled_linearize(tex, sample0_uv + uv_step_x * 2.0).rgb;
    vec3 sample3 = tex2Daa_tiled_linearize(tex, sample0_uv + uv_step_x * 3.0).rgb;
    vec3 sample4 = tex2Daa_tiled_linearize(tex, sample4_uv).rgb;
    vec3 sample5 = tex2Daa_tiled_linearize(tex, sample4_uv + uv_step_x).rgb;
    vec3 sample6 = tex2Daa_tiled_linearize(tex, sample4_uv + uv_step_x * 2.0).rgb;
    vec3 sample7 = tex2Daa_tiled_linearize(tex, sample4_uv + uv_step_x * 3.0).rgb;
    vec3 sample8 = tex2Daa_tiled_linearize(tex, sample8_uv).rgb;
    vec3 sample9 = tex2Daa_tiled_linearize(tex, sample8_uv + uv_step_x).rgb;
    vec3 sample10 = tex2Daa_tiled_linearize(tex, sample8_uv + uv_step_x * 2.0).rgb;
    vec3 sample11 = tex2Daa_tiled_linearize(tex, sample8_uv + uv_step_x * 3.0).rgb;
    vec3 sample12 = tex2Daa_tiled_linearize(tex, sample12_uv).rgb;
    vec3 sample13 = tex2Daa_tiled_linearize(tex, sample12_uv + uv_step_x).rgb;
    vec3 sample14 = tex2Daa_tiled_linearize(tex, sample12_uv + uv_step_x * 2.0).rgb;
    vec3 sample15 = tex2Daa_tiled_linearize(tex, sample12_uv + uv_step_x * 3.0).rgb;
    //  Sum weighted samples (weight sum must equal 1.0 for each channel):
    return w_sum_inv * (
        w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7 +
        w8 * sample8 + w9 * sample9 + w10 * sample10 + w11 * sample11 +
        w12 * sample12 + w13 * sample13 + w14 * sample14 + w15 * sample15);
}

vec3 tex2Daa_debug_dynamic(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  This function is for testing only: Use an NxN grid with dynamic weights.
    int grid_size = 8;
    assign_aa_cubic_constants();
    vec4 ssd_fai = get_subpixel_support_diam_and_final_axis_importance();
    vec2 subpixel_support_diameter = ssd_fai.xy;
    vec2 final_axis_importance = ssd_fai.zw;
    float grid_radius_in_samples = (float(grid_size) - 1.0)/2.0;
    vec2 filter_space_offset_step =
        subpixel_support_diameter/vec2(grid_size);
    vec2 sample0_filter_space_offset =
        -grid_radius_in_samples * filter_space_offset_step;
    //  Compute xy sample offsets and subpixel weights:
    vec3 weights[64]; //[grid_size * grid_size]; <- GLSL requires a constant expression for array sizes
    vec3 weight_sum = vec3(0.0);
    for(int i = 0; i < grid_size; ++i)
    {
        for(int j = 0; j < grid_size; ++j)
        {
            //  Weights based on xy distances:
            vec2 offset = sample0_filter_space_offset +
                vec2(j, i) * filter_space_offset_step;
            vec3 weight = eval_unorm_rgb_weights(offset, final_axis_importance);
            weights[i*grid_size + j] = weight;
            weight_sum += weight;
        }
    }
    //  Get uv offset vectors along x and y directions:
    mat2x2 true_pixel_to_tex_uv =
        mat2x2(vec4(pixel_to_tex_uv * aa_pixel_diameter));
    vec2 uv_offset_step_x = (vec2(filter_space_offset_step.x, 0.0) * true_pixel_to_tex_uv);
    vec2 uv_offset_step_y = (vec2(0.0, filter_space_offset_step.y) * true_pixel_to_tex_uv);
    //  Get a starting sample location:
    vec2 sample0_uv_offset = -grid_radius_in_samples *
        (uv_offset_step_x + uv_offset_step_y);
    vec2 sample0_uv = tex_uv + sample0_uv_offset;
    //  Load, weight, and sum [linearized] samples:
    vec3 sum = vec3(0.0);
    vec3 weight_sum_inv = vec3(1.0)/vec3(weight_sum);
    for(int i = 0; i < grid_size; ++i)
    {
        vec2 row_i_first_sample_uv =
            sample0_uv + i * uv_offset_step_y;
        for(int j = 0; j < grid_size; ++j)
        {
            vec2 sample_uv =
                row_i_first_sample_uv + j * uv_offset_step_x;
            sum += weights[i*grid_size + j] *
                tex2Daa_tiled_linearize(tex, sample_uv).rgb;
        }
    }
    return sum * weight_sum_inv;
}

///////////////////////  ANTIALIASING CODEPATH SELECTION  //////////////////////

vec3 tex2Daa(sampler2D tex, vec2 tex_uv,
    mat2x2 pixel_to_tex_uv, float frame)
{
    //  Statically switch between antialiasing modes/levels:
	if (aa_level < 0.5) return tex2D_linearize(tex, tex_uv).rgb;
	else if (aa_level < 3.5) return tex2Daa_subpixel_weights_only(
            tex, tex_uv, pixel_to_tex_uv);
	else if (aa_level < 4.5)   return tex2Daa4x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 5.5)   return tex2Daa5x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 6.5)   return tex2Daa6x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 7.5)   return tex2Daa7x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 11.5)  return tex2Daa8x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 15.5)  return tex2Daa12x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 19.5)  return tex2Daa16x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 23.5)  return tex2Daa20x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 253.5) return tex2Daa24x(tex, tex_uv, pixel_to_tex_uv, frame);
	else if (aa_level < 254.5) return tex2Daa_debug_16x_regular(tex, tex_uv, pixel_to_tex_uv, frame);
		else return tex2Daa_debug_dynamic(tex, tex_uv, pixel_to_tex_uv, frame);
}

#endif  //  TEX2DANTIALIAS_H

///////////////   END tex2Dantialias.h   /////////////////////////////

//////////////   BEGIN geometry-functions.h   ////////////////////////
#ifndef GEOMETRY_FUNCTIONS_H
#define GEOMETRY_FUNCTIONS_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA

////////////////////////////  MACROS AND CONSTANTS  ////////////////////////////

//  Curvature-related constants:
#define MAX_POINT_CLOUD_SIZE 9

/////////////////////////////  CURVATURE FUNCTIONS /////////////////////////////

vec2 quadratic_solve(float a, float b_over_2, float c)
{
    //  Requires:   1.) a, b, and c are quadratic formula coefficients
    //              2.) b_over_2 = b/2.0 (simplifies terms to factor 2 out)
    //              3.) b_over_2 must be guaranteed < 0.0 (avoids a branch)
    //  Returns:    Returns vec2(first_solution, discriminant), so the caller
    //              can choose how to handle the "no intersection" case.  The
    //              Kahan or Citardauq formula is used for numerical robustness.
    float discriminant = b_over_2*b_over_2 - a*c;
    float solution0 = c/(-b_over_2 + sqrt(discriminant));
    return vec2(solution0, discriminant);
}

vec2 intersect_sphere(vec3 view_vec, vec3 eye_pos_vec)
{
    //  Requires:   1.) view_vec and eye_pos_vec are 3D vectors in the sphere's
    //                  local coordinate frame (eye_pos_vec is a position, i.e.
    //                  a vector from the origin to the eye/camera)
    //              2.) geom_radius is a global containing the sphere's radius
    //  Returns:    Cast a ray of direction view_vec from eye_pos_vec at a
    //              sphere of radius geom_radius, and return the distance to
    //              the first intersection in units of length(view_vec).
    //              http://wiki.cgsociety.org/index.php/Ray_Sphere_Intersection
    //  Quadratic formula coefficients (b_over_2 is guaranteed negative):
    float a = dot(view_vec, view_vec);
    float b_over_2 = dot(view_vec, eye_pos_vec);  //  * 2.0 factored out
    float c = dot(eye_pos_vec, eye_pos_vec) - geom_radius*geom_radius;
    return quadratic_solve(a, b_over_2, c);
}

vec2 intersect_cylinder(vec3 view_vec, vec3 eye_pos_vec)
{
    //  Requires:   1.) view_vec and eye_pos_vec are 3D vectors in the sphere's
    //                  local coordinate frame (eye_pos_vec is a position, i.e.
    //                  a vector from the origin to the eye/camera)
    //              2.) geom_radius is a global containing the cylinder's radius
    //  Returns:    Cast a ray of direction view_vec from eye_pos_vec at a
    //              cylinder of radius geom_radius, and return the distance to
    //              the first intersection in units of length(view_vec).  The
    //              derivation of the coefficients is in Christer Ericson's
    //              Real-Time Collision Detection, p. 195-196, and this version
    //              uses LaGrange's identity to reduce operations.
    //  Arbitrary "cylinder top" reference point for an infinite cylinder:
    vec3 cylinder_top_vec = vec3(0.0, geom_radius, 0.0);
    vec3 cylinder_axis_vec = vec3(0.0, 1.0, 0.0);//vec3(0.0, 2.0*geom_radius, 0.0);
    vec3 top_to_eye_vec = eye_pos_vec - cylinder_top_vec;
    vec3 axis_x_view = cross(cylinder_axis_vec, view_vec);
    vec3 axis_x_top_to_eye = cross(cylinder_axis_vec, top_to_eye_vec);
    //  Quadratic formula coefficients (b_over_2 is guaranteed negative):
    float a = dot(axis_x_view, axis_x_view);
    float b_over_2 = dot(axis_x_top_to_eye, axis_x_view);
    float c = dot(axis_x_top_to_eye, axis_x_top_to_eye) -
        geom_radius*geom_radius;//*dot(cylinder_axis_vec, cylinder_axis_vec);
    return quadratic_solve(a, b_over_2, c);
}

vec2 cylinder_xyz_to_uv(vec3 intersection_pos_local,
    vec2 geom_aspect)
{
    //  Requires:   An xyz intersection position on a cylinder.
    //  Returns:    video_uv coords mapped to range [-0.5, 0.5]
    //  Mapping:    Define square_uv.x to be the signed arc length in xz-space,
    //              and define square_uv.y = -intersection_pos_local.y (+v = -y).
    //  Start with a numerically robust arc length calculation.
    float angle_from_image_center = atan(intersection_pos_local.z,
		intersection_pos_local.x);
    float signed_arc_len = angle_from_image_center * geom_radius;
    //  Get a uv-mapping where [-0.5, 0.5] maps to a "square" area, then divide
    //  by the aspect ratio to stretch the mapping appropriately:
    vec2 square_uv = vec2(signed_arc_len, -intersection_pos_local.y);
    vec2 video_uv = square_uv / geom_aspect;
    return video_uv;
}

vec3 cylinder_uv_to_xyz(vec2 video_uv, vec2 geom_aspect)
{
    //  Requires:   video_uv coords mapped to range [-0.5, 0.5]
    //  Returns:    An xyz intersection position on a cylinder.  This is the
    //              inverse of cylinder_xyz_to_uv().
    //  Expand video_uv by the aspect ratio to get proportionate x/y lengths,
    //  then calculate an xyz position for the cylindrical mapping above.
    vec2 square_uv = video_uv * geom_aspect;
    float arc_len = square_uv.x;
    float angle_from_image_center = arc_len / geom_radius;
    float x_pos = sin(angle_from_image_center) * geom_radius;
    float z_pos = cos(angle_from_image_center) * geom_radius;
    //  Or: z = sqrt(geom_radius**2 - x**2)
    //  Or: z = geom_radius/sqrt(1.0 + tan(angle)**2), x = z * tan(angle)
    vec3 intersection_pos_local = vec3(x_pos, -square_uv.y, z_pos);
    return intersection_pos_local;
}

vec2 sphere_xyz_to_uv(vec3 intersection_pos_local,
    vec2 geom_aspect)
{
    //  Requires:   An xyz intersection position on a sphere.
    //  Returns:    video_uv coords mapped to range [-0.5, 0.5]
    //  Mapping:    First define square_uv.x/square_uv.y ==
    //              intersection_pos_local.x/intersection_pos_local.y.  Then,
    //              length(square_uv) is the arc length from the image center
    //              at (0.0, 0.0, geom_radius) along the tangent great circle.
    //              Credit for this mapping goes to cgwg: I never managed to
    //              understand his code, but he told me his mapping was based on
    //              great circle distances when I asked him about it, which
    //              informed this very similar (almost identical) mapping.
    //  Start with a numerically robust arc length calculation between the ray-
    //  sphere intersection point and the image center using a method posted by
    //  Roger Stafford on comp.soft-sys.matlab:
    //  https://groups.google.com/d/msg/comp.soft-sys.matlab/zNbUui3bjcA/c0HV_bHSx9cJ
    vec3 image_center_pos_local = vec3(0.0, 0.0, geom_radius);
    float cp_len =
        length(cross(intersection_pos_local, image_center_pos_local));
    float dp = dot(intersection_pos_local, image_center_pos_local);
    float angle_from_image_center = atan(dp, cp_len);
    float arc_len = angle_from_image_center * geom_radius;
    //  Get a uv-mapping where [-0.5, 0.5] maps to a "square" area, then divide
    //  by the aspect ratio to stretch the mapping appropriately:
    vec2 square_uv_unit = normalize(vec2(intersection_pos_local.x,
        -intersection_pos_local.y));
    vec2 square_uv = arc_len * square_uv_unit;
    vec2 video_uv = square_uv / geom_aspect;
    return video_uv;
}

vec3 sphere_uv_to_xyz(vec2 video_uv, vec2 geom_aspect)
{
    //  Requires:   video_uv coords mapped to range [-0.5, 0.5]
    //  Returns:    An xyz intersection position on a sphere.  This is the
    //              inverse of sphere_xyz_to_uv().
    //  Expand video_uv by the aspect ratio to get proportionate x/y lengths,
    //  then calculate an xyz position for the spherical mapping above.
    vec2 square_uv = video_uv * geom_aspect;
    //  Using length or sqrt here butchers the framerate on my 8800GTS if
    //  this function is called too many times, and so does taking the max
    //  component of square_uv/square_uv_unit (program length threshold?).
    //float arc_len = length(square_uv);
    vec2 square_uv_unit = normalize(square_uv);
    float arc_len = square_uv.y/square_uv_unit.y;
    float angle_from_image_center = arc_len / geom_radius;
    float xy_dist_from_sphere_center =
        sin(angle_from_image_center) * geom_radius;
    //vec2 xy_pos = xy_dist_from_sphere_center * (square_uv/FIX_ZERO(arc_len));
    vec2 xy_pos = xy_dist_from_sphere_center * square_uv_unit;
    float z_pos = cos(angle_from_image_center) * geom_radius;
    vec3 intersection_pos_local = vec3(xy_pos.x, -xy_pos.y, z_pos);
    return intersection_pos_local;
}

vec2 sphere_alt_xyz_to_uv(vec3 intersection_pos_local,
    vec2 geom_aspect)
{
    //  Requires:   An xyz intersection position on a cylinder.
    //  Returns:    video_uv coords mapped to range [-0.5, 0.5]
    //  Mapping:    Define square_uv.x to be the signed arc length in xz-space,
    //              and define square_uv.y == signed arc length in yz-space.
    //  See cylinder_xyz_to_uv() for implementation details (very similar).
    vec2 angle_from_image_center = atan((intersection_pos_local.zz),
        vec2(intersection_pos_local.x, -intersection_pos_local.y));
    vec2 signed_arc_len = angle_from_image_center * geom_radius;
    vec2 video_uv = signed_arc_len / geom_aspect;
    return video_uv;
}

vec3 sphere_alt_uv_to_xyz(vec2 video_uv, vec2 geom_aspect)
{
    //  Requires:   video_uv coords mapped to range [-0.5, 0.5]
    //  Returns:    An xyz intersection position on a sphere.  This is the
    //              inverse of sphere_alt_xyz_to_uv().
    //  See cylinder_uv_to_xyz() for implementation details (very similar).
    vec2 square_uv = video_uv * geom_aspect;
    vec2 arc_len = square_uv;
    vec2 angle_from_image_center = arc_len / geom_radius;
    vec2 xy_pos = sin(angle_from_image_center) * geom_radius;
    float z_pos = sqrt(geom_radius*geom_radius - dot(xy_pos, xy_pos));
    return vec3(xy_pos.x, -xy_pos.y, z_pos);
}

vec2 intersect(vec3 view_vec_local, vec3 eye_pos_local,
    float geom_mode)
{
    if (geom_mode < 2.5) return intersect_sphere(view_vec_local, eye_pos_local);
	else return intersect_cylinder(view_vec_local, eye_pos_local);
}

vec2 xyz_to_uv(vec3 intersection_pos_local,
    vec2 geom_aspect, float geom_mode)
{
    if (geom_mode < 1.5) return sphere_xyz_to_uv(intersection_pos_local, geom_aspect);
	else if (geom_mode < 2.5) return sphere_alt_xyz_to_uv(intersection_pos_local, geom_aspect);
	else return cylinder_xyz_to_uv(intersection_pos_local, geom_aspect);
}

vec3 uv_to_xyz(vec2 uv, vec2 geom_aspect,
    float geom_mode)
{
	if (geom_mode < 1.5) return sphere_uv_to_xyz(uv, geom_aspect);
	else if (geom_mode < 2.5) return sphere_alt_uv_to_xyz(uv, geom_aspect);
	else return cylinder_uv_to_xyz(uv, geom_aspect);
}

vec2 view_vec_to_uv(vec3 view_vec_local, vec3 eye_pos_local,
    vec2 geom_aspect, float geom_mode, out vec3 intersection_pos)
{
    //  Get the intersection point on the primitive, given an eye position
    //  and view vector already in its local coordinate frame:
    vec2 intersect_dist_and_discriminant = intersect(view_vec_local,
        eye_pos_local, geom_mode);
    vec3 intersection_pos_local = eye_pos_local +
        view_vec_local * intersect_dist_and_discriminant.x;
    //  Save the intersection position to an output parameter:
    intersection_pos = intersection_pos_local;
    //  Transform into uv coords, but give out-of-range coords if the
    //  view ray doesn't intersect the primitive in the first place:
	if (intersect_dist_and_discriminant.y > 0.005) return xyz_to_uv(intersection_pos_local, geom_aspect, geom_mode);
	else return vec2(1.0);
}

vec3 get_ideal_global_eye_pos_for_points(vec3 eye_pos,
    vec2 geom_aspect, vec3 global_coords[MAX_POINT_CLOUD_SIZE],
    int num_points)
{
    //  Requires:   Parameters:
    //              1.) Starting eye_pos is a global 3D position at which the
    //                  camera contains all points in global_coords[] in its FOV
    //              2.) geom_aspect = get_aspect_vector(
    //                      IN.output_size.x / IN.output_size.y);
    //              3.) global_coords is a point cloud containing global xyz
    //                  coords of extreme points on the simulated CRT screen.
    //              Globals:
    //              1.) geom_view_dist must be > 0.0.  It controls the "near
    //                  plane" used to interpret flat_video_uv as a view
    //                  vector, which controls the field of view (FOV).
    //              Eyespace coordinate frame: +x = right, +y = up, +z = back
    //  Returns:    Return an eye position at which the point cloud spans as
    //              much of the screen as possible (given the FOV controlled by
    //              geom_view_dist) without being cropped or sheared.
    //  Algorithm:
    //  1.) Move the eye laterally to a point which attempts to maximize the
    //      the amount we can move forward without clipping the CRT screen.
    //  2.) Move forward by as much as possible without clipping the CRT.
    //  Get the allowed movement range by solving for the eye_pos offsets
    //  that result in each point being projected to a screen edge/corner in
    //  pseudo-normalized device coords (where xy ranges from [-0.5, 0.5]
    //  and z = eyespace z):
    //      pndc_coord = vec3(vec2(eyespace_xyz.x, -eyespace_xyz.y)*
    //      geom_view_dist / (geom_aspect * -eyespace_xyz.z), eyespace_xyz.z);
    //  Notes:
    //  The field of view is controlled by geom_view_dist's magnitude relative to
    //  the view vector's x and y components:
    //      view_vec.xy ranges from [-0.5, 0.5] * geom_aspect
    //      view_vec.z = -geom_view_dist
    //  But for the purposes of perspective divide, it should be considered:
    //      view_vec.xy ranges from [-0.5, 0.5] * geom_aspect / geom_view_dist
    //      view_vec.z = -1.0
    int max_centering_iters = 1;  //  Keep for easy testing.
    for(int iter = 0; iter < max_centering_iters; iter++)
    {
        //  0.) Get the eyespace coordinates of our point cloud:
        vec3 eyespace_coords[MAX_POINT_CLOUD_SIZE];
        for(int i = 0; i < num_points; i++)
        {
            eyespace_coords[i] = global_coords[i] - eye_pos;
        }
        //  1a.)For each point, find out how far we can move eye_pos in each
        //      lateral direction without the point clipping the frustum.
        //      Eyespace +y = up, screenspace +y = down, so flip y after
        //      applying the eyespace offset (on the way to "clip space").
        //  Solve for two offsets per point based on:
        //      (eyespace_xyz.xy - offset_dr) * vec2(1.0, -1.0) *
        //      geom_view_dist / (geom_aspect * -eyespace_xyz.z) = vec2(-0.5)
        //      (eyespace_xyz.xy - offset_dr) * vec2(1.0, -1.0) *
        //      geom_view_dist / (geom_aspect * -eyespace_xyz.z) = vec2(0.5)
        //  offset_ul and offset_dr represent the farthest we can move the
        //  eye_pos up-left and down-right.  Save the min of all offset_dr's
        //  and the max of all offset_ul's (since it's negative).
        float abs_radius = abs(geom_radius);  //  In case anyone gets ideas. ;)
        vec2 offset_dr_min = vec2(10.0 * abs_radius, 10.0 * abs_radius);
        vec2 offset_ul_max = vec2(-10.0 * abs_radius, -10.0 * abs_radius);
        for(int i = 0; i < num_points; i++)
        {
            vec2 flipy = vec2(1.0, -1.0);
            vec3 eyespace_xyz = eyespace_coords[i];
            vec2 offset_dr = eyespace_xyz.xy - vec2(-0.5) *
                (geom_aspect * -eyespace_xyz.z) / (geom_view_dist * flipy);
            vec2 offset_ul = eyespace_xyz.xy - vec2(0.5) *
                (geom_aspect * -eyespace_xyz.z) / (geom_view_dist * flipy);
            offset_dr_min = min(offset_dr_min, offset_dr);
            offset_ul_max = max(offset_ul_max, offset_ul);
        }
        //  1b.)Update eye_pos: Adding the average of offset_ul_max and
        //      offset_dr_min gives it equal leeway on the top vs. bottom
        //      and left vs. right.  Recalculate eyespace_coords accordingly.
        vec2 center_offset = 0.5 * (offset_ul_max + offset_dr_min);
        eye_pos.xy += center_offset;
        for(int i = 0; i < num_points; i++)
        {
            eyespace_coords[i] = global_coords[i] - eye_pos;
        }
        //  2a.)For each point, find out how far we can move eye_pos forward
        //      without the point clipping the frustum.  Flip the y
        //      direction in advance (matters for a later step, not here).
        //      Solve for four offsets per point based on:
        //      eyespace_xyz_flipy.x * geom_view_dist /
        //          (geom_aspect.x * (offset_z - eyespace_xyz_flipy.z)) =-0.5
        //      eyespace_xyz_flipy.y * geom_view_dist /
        //          (geom_aspect.y * (offset_z - eyespace_xyz_flipy.z)) =-0.5
        //      eyespace_xyz_flipy.x * geom_view_dist /
        //          (geom_aspect.x * (offset_z - eyespace_xyz_flipy.z)) = 0.5
        //      eyespace_xyz_flipy.y * geom_view_dist /
        //          (geom_aspect.y * (offset_z - eyespace_xyz_flipy.z)) = 0.5
        //      We'll vectorize the actual computation.  Take the maximum of
        //      these four for a single offset, and continue taking the max
        //      for every point (use max because offset.z is negative).
        float offset_z_max = -10.0 * geom_radius * geom_view_dist;
        for(int i = 0; i < num_points; i++)
        {
            vec3 eyespace_xyz_flipy = eyespace_coords[i] *
                vec3(1.0, -1.0, 1.0);
            vec4 offset_zzzz = eyespace_xyz_flipy.zzzz +
                (eyespace_xyz_flipy.xyxy * geom_view_dist) /
                (vec4(-0.5, -0.5, 0.5, 0.5) * vec4(geom_aspect, geom_aspect));
            //  Ignore offsets that push positive x/y values to opposite
            //  boundaries, and vice versa, and don't let the camera move
            //  past a point in the dead center of the screen:
            offset_z_max = (eyespace_xyz_flipy.x < 0.0) ?
                max(offset_z_max, offset_zzzz.x) : offset_z_max;
            offset_z_max = (eyespace_xyz_flipy.y < 0.0) ?
                max(offset_z_max, offset_zzzz.y) : offset_z_max;
            offset_z_max = (eyespace_xyz_flipy.x > 0.0) ?
                max(offset_z_max, offset_zzzz.z) : offset_z_max;
            offset_z_max = (eyespace_xyz_flipy.y > 0.0) ?
                max(offset_z_max, offset_zzzz.w) : offset_z_max;
            offset_z_max = max(offset_z_max, eyespace_xyz_flipy.z);
        }
        //  2b.)Update eye_pos: Add the maximum (smallest negative) z offset.
        eye_pos.z += offset_z_max;
    }
    return eye_pos;
}

vec3 get_ideal_global_eye_pos(mat3x3 local_to_global,
    vec2 geom_aspect, float geom_mode)
{
    //  Start with an initial eye_pos that includes the entire primitive
    //  (sphere or cylinder) in its field-of-view:
    vec3 high_view = vec3(0.0, geom_aspect.y, -geom_view_dist);
    vec3 low_view = high_view * vec3(1.0, -1.0, 1.0);
    float len_sq = dot(high_view, high_view);
    float fov = abs(acos(dot(high_view, low_view)/len_sq));
    //  Trigonometry/similar triangles say distance = geom_radius/sin(fov/2):
    float eye_z_spherical = geom_radius/sin(fov*0.5);
    vec3 eye_pos = vec3(0.0, 0.0, eye_z_spherical);
	if (geom_mode < 2.5) eye_pos = vec3(0.0, 0.0, max(geom_view_dist, eye_z_spherical));

    //  Get global xyz coords of extreme sample points on the simulated CRT
    //  screen.  Start with the center, edge centers, and corners of the
    //  video image.  We can't ignore backfacing points: They're occluded
    //  by closer points on the primitive, but they may NOT be occluded by
    //  the convex hull of the remaining samples (i.e. the remaining convex
    //  hull might not envelope points that do occlude a back-facing point.)
    int num_points = MAX_POINT_CLOUD_SIZE;
    vec3 global_coords[MAX_POINT_CLOUD_SIZE];
    global_coords[0] = (uv_to_xyz(vec2(0.0, 0.0), geom_aspect, geom_mode) * local_to_global);
    global_coords[1] = (uv_to_xyz(vec2(0.0, -0.5), geom_aspect, geom_mode) * local_to_global);
    global_coords[2] = (uv_to_xyz(vec2(0.0, 0.5), geom_aspect, geom_mode) * local_to_global);
    global_coords[3] = (uv_to_xyz(vec2(-0.5, 0.0), geom_aspect, geom_mode) * local_to_global);
    global_coords[4] = (uv_to_xyz(vec2(0.5, 0.0), geom_aspect, geom_mode) * local_to_global);
    global_coords[5] = (uv_to_xyz(vec2(-0.5, -0.5), geom_aspect, geom_mode) * local_to_global);
    global_coords[6] = (uv_to_xyz(vec2(0.5, -0.5), geom_aspect, geom_mode) * local_to_global);
    global_coords[7] = (uv_to_xyz(vec2(-0.5, 0.5), geom_aspect, geom_mode) * local_to_global);
    global_coords[8] = (uv_to_xyz(vec2(0.5, 0.5), geom_aspect, geom_mode) * local_to_global);
    //  Adding more inner image points could help in extreme cases, but too many
    //  points will kille the framerate.  For safety, default to the initial
    //  eye_pos if any z coords are negative:
    float num_negative_z_coords = 0.0;
    for(int i = 0; i < num_points; i++)
    {
		if (global_coords[0].z < 0.0)
        {num_negative_z_coords += float(global_coords[0].z);}
    }
    //  Outsource the optimized eye_pos calculation:
	if (num_negative_z_coords > 0.5)
		return eye_pos;
	else
        return get_ideal_global_eye_pos_for_points(eye_pos, geom_aspect, global_coords, num_points);
}

mat3x3 get_pixel_to_object_matrix(mat3x3 global_to_local,
    vec3 eye_pos_local, vec3 view_vec_global,
    vec3 intersection_pos_local, vec3 normal,
    vec2 output_size_inv)
{
    //  Requires:   See get_curved_video_uv_coords_and_tangent_matrix for
    //              descriptions of each parameter.
    //  Returns:    Return a transformation matrix from 2D pixel-space vectors
    //              (where (+1.0, +1.0) is a vector to one pixel down-right,
    //              i.e. same directionality as uv texels) to 3D object-space
    //              vectors in the CRT's local coordinate frame (right-handed)
    //              ***which are tangent to the CRT surface at the intersection
    //              position.***  (Basically, we want to convert pixel-space
    //              vectors to 3D vectors along the CRT's surface, for later
    //              conversion to uv vectors.)
    //  Shorthand inputs:
    vec3 pos = intersection_pos_local;
    vec3 eye_pos = eye_pos_local;
    //  Get a piecewise-linear matrix transforming from "pixelspace" offset
    //  vectors (1.0 = one pixel) to object space vectors in the tangent
    //  plane (faster than finding 3 view-object intersections).
    //  1.) Get the local view vecs for the pixels to the right and down:
    vec3 view_vec_right_global = view_vec_global +
        vec3(output_size_inv.x, 0.0, 0.0);
    vec3 view_vec_down_global = view_vec_global +
        vec3(0.0, -output_size_inv.y, 0.0);
    vec3 view_vec_right_local =
        (view_vec_right_global * global_to_local);
    vec3 view_vec_down_local =
        (view_vec_down_global * global_to_local);
    //  2.) Using the true intersection point, intersect the neighboring
    //      view vectors with the tangent plane:
    vec3 intersection_vec_dot_normal = vec3(dot(pos - eye_pos, normal));
    vec3 right_pos = eye_pos + (intersection_vec_dot_normal /
        dot(view_vec_right_local, normal))*view_vec_right_local;
    vec3 down_pos = eye_pos + (intersection_vec_dot_normal /
        dot(view_vec_down_local, normal))*view_vec_down_local;
    //  3.) Subtract the original intersection pos from its neighbors; the
    //      resulting vectors are object-space vectors tangent to the plane.
    //      These vectors are the object-space transformations of (1.0, 0.0)
    //      and (0.0, 1.0) pixel offsets, so they form the first two basis
    //      vectors of a pixelspace to object space transformation.  This
    //      transformation is 2D to 3D, so use (0, 0, 0) for the third vector.
    vec3 object_right_vec = right_pos - pos;
    vec3 object_down_vec = down_pos - pos;
    mat3x3 pixel_to_object = mat3x3(
        object_right_vec.x, object_down_vec.x, 0.0,
        object_right_vec.y, object_down_vec.y, 0.0,
        object_right_vec.z, object_down_vec.z, 0.0);
    return pixel_to_object;
}

mat3x3 get_object_to_tangent_matrix(vec3 intersection_pos_local,
    vec3 normal, vec2 geom_aspect, float geom_mode)
{
    //  Requires:   See get_curved_video_uv_coords_and_tangent_matrix for
    //              descriptions of each parameter.
    //  Returns:    Return a transformation matrix from 3D object-space vectors
    //              in the CRT's local coordinate frame (right-handed, +y = up)
    //              to 2D video_uv vectors (+v = down).
    //  Description:
    //  The TBN matrix formed by the [tangent, bitangent, normal] basis
    //  vectors transforms ordinary vectors from tangent->object space.
    //  The cotangent matrix formed by the [cotangent, cobitangent, normal]
    //  basis vectors transforms normal vectors (covectors) from
    //  tangent->object space.  It's the inverse-transpose of the TBN matrix.
    //  We want the inverse of the TBN matrix (transpose of the cotangent
    //  matrix), which transforms ordinary vectors from object->tangent space.
    //  Start by calculating the relevant basis vectors in accordance with
    //  Christian Schüler's blog post "Followup: Normal Mapping Without
    //  Precomputed Tangents":  http://www.thetenthplanet.de/archives/1180
    //  With our particular uv mapping, the scale of the u and v directions
    //  is determined entirely by the aspect ratio for cylindrical and ordinary
    //  spherical mappings, and so tangent and bitangent lengths are also
    //  determined by it (the alternate mapping is more complex).  Therefore, we
    //  must ensure appropriate cotangent and cobitangent lengths as well.
    //  Base these off the uv<=>xyz mappings for each primitive.
    vec3 pos = intersection_pos_local;
    vec3 x_vec = vec3(1.0, 0.0, 0.0);
    vec3 y_vec = vec3(0.0, 1.0, 0.0);
    //  The tangent and bitangent vectors correspond with increasing u and v,
    //  respectively.  Mathematically we'd base the cotangent/cobitangent on
    //  those, but we'll compute the cotangent/cobitangent directly when we can.
    vec3 cotangent_unscaled, cobitangent_unscaled;
    //  geom_mode should be constant-folded without RUNTIME_GEOMETRY_MODE.
    if(geom_mode < 1.5)
    {
        //  Sphere:
        //  tangent = normalize(cross(normal, cross(x_vec, pos))) * geom_aspect.x
        //  bitangent = normalize(cross(cross(y_vec, pos), normal)) * geom_aspect.y
        //  inv_determinant = 1.0/length(cross(bitangent, tangent))
        //  cotangent = cross(normal, bitangent) * inv_determinant
        //            == normalize(cross(y_vec, pos)) * geom_aspect.y * inv_determinant
        //  cobitangent = cross(tangent, normal) * inv_determinant
        //            == normalize(cross(x_vec, pos)) * geom_aspect.x * inv_determinant
        //  Simplified (scale by inv_determinant below):
        cotangent_unscaled = normalize(cross(y_vec, pos)) * geom_aspect.y;
        cobitangent_unscaled = normalize(cross(x_vec, pos)) * geom_aspect.x;
    }
    else if(geom_mode < 2.5)
    {
        //  Sphere, alternate mapping:
        //  This mapping works a bit like the cylindrical mapping in two
        //  directions, which makes the lengths and directions more complex.
        //  Unfortunately, I can't find much of a shortcut:
        vec3 tangent = normalize(
            cross(y_vec, vec3(pos.x, 0.0, pos.z))) * geom_aspect.x;
        vec3 bitangent = normalize(
            cross(x_vec, vec3(0.0, pos.yz))) * geom_aspect.y;
        cotangent_unscaled = cross(normal, bitangent);
        cobitangent_unscaled = cross(tangent, normal);
    }
    else
    {
        //  Cylinder:
        //  tangent = normalize(cross(y_vec, normal)) * geom_aspect.x;
        //  bitangent = vec3(0.0, -geom_aspect.y, 0.0);
        //  inv_determinant = 1.0/length(cross(bitangent, tangent))
        //  cotangent = cross(normal, bitangent) * inv_determinant
        //            == normalize(cross(y_vec, pos)) * geom_aspect.y * inv_determinant
        //  cobitangent = cross(tangent, normal) * inv_determinant
        //            == vec3(0.0, -geom_aspect.x, 0.0) * inv_determinant
        cotangent_unscaled = cross(y_vec, normal) * geom_aspect.y;
        cobitangent_unscaled = vec3(0.0, -geom_aspect.x, 0.0);
    }
    vec3 computed_normal =
        cross(cobitangent_unscaled, cotangent_unscaled);
    float inv_determinant = inversesqrt(dot(computed_normal, computed_normal));
    vec3 cotangent = cotangent_unscaled * inv_determinant;
    vec3 cobitangent = cobitangent_unscaled * inv_determinant;
    //  The [cotangent, cobitangent, normal] column vecs form the cotangent
    //  frame, i.e. the inverse-transpose TBN matrix.  Get its transpose:
    mat3x3 object_to_tangent = mat3x3(cotangent, cobitangent, normal);
    return object_to_tangent;
}

float get_border_dim_factor(vec2 video_uv, vec2 geom_aspect)
{
    //  COPYRIGHT NOTE FOR THIS FUNCTION:
    //  Copyright (C) 2010-2012 cgwg, 2014 TroggleMonkey
    //  This function uses an algorithm first coded in several of cgwg's GPL-
    //  licensed lines in crt-geom-curved.cg and its ancestors.  The line
    //  between algorithm and code is nearly indistinguishable here, so it's
    //  unclear whether I could even release this project under a non-GPL
    //  license with this function included.

    //  Calculate border_dim_factor from the proximity to uv-space image
    //  borders; geom_aspect/border_size/border/darkness/border_compress are globals:
    vec2 edge_dists = min(video_uv, vec2(1.0) - video_uv) *
        geom_aspect;
    vec2 border_penetration =
        max(vec2(border_size) - edge_dists, vec2(0.0));
    float penetration_ratio = length(border_penetration)/border_size;
    float border_escape_ratio = max(1.0 - penetration_ratio, 0.0);
    float border_dim_factor =
        pow(border_escape_ratio, border_darkness) * max(1.0, border_compress);
    return min(border_dim_factor, 1.0);
}

#endif  //  GEOMETRY_FUNCTIONS_H

//////////////////   END geometry-functions.h   //////////////////////////////

///////////////////////////////////  HELPERS  //////////////////////////////////

mat2x2 mul_scale(vec2 scale, mat2x2 matrix)
{
    //mat2x2 scale_matrix = mat2x2(scale.x, 0.0, 0.0, scale.y);
    //return (matrix * scale_matrix);
    return mat2x2(vec4(matrix[0].xy, matrix[1].xy) * scale.xxyy);
}

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
COMPAT_VARYING vec4 video_and_texture_size_inv;
COMPAT_VARYING vec2 output_size_inv;
COMPAT_VARYING vec3 eye_pos_local;
COMPAT_VARYING vec4 geom_aspect_and_overscan;
#ifdef RUNTIME_GEOMETRY_TILT
COMPAT_VARYING vec3 global_to_local_row0;
COMPAT_VARYING vec3 global_to_local_row1;
COMPAT_VARYING vec3 global_to_local_row2;
#endif

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
//#define tex_uv TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    vec2 tex_uv = TEX0.xy;
   video_and_texture_size_inv = vec4(1.0) / vec4(InputSize.xy, TextureSize.xy);
    output_size_inv = vec2(1.0) / OutputSize.xy;

    //  Get aspect/overscan vectors from scalar parameters (likely uniforms):
    float viewport_aspect_ratio = OutputSize.x / OutputSize.y;
    vec2 geom_aspect = get_aspect_vector(viewport_aspect_ratio);
    vec2 geom_overscan = get_geom_overscan_vector();
    geom_aspect_and_overscan = vec4(geom_aspect, geom_overscan);
	
	#ifdef RUNTIME_GEOMETRY_TILT
        //  Create a local-to-global rotation matrix for the CRT's coordinate
        //  frame and its global-to-local inverse.  Rotate around the x axis
        //  first (pitch) and then the y axis (yaw) with yucky Euler angles.
        //  Positive angles go clockwise around the right-vec and up-vec.
        //  Runtime shader parameters prevent us from computing these globally,
        //  but we can still combine the pitch/yaw matrices by hand to cut a
        //  few instructions.  Note that cg matrices fill row1 first, then row2,
        //  etc. (row-major order).
        vec2 geom_tilt_angle = get_geom_tilt_angle_vector();
        vec2 sin_tilt = sin(geom_tilt_angle);
        vec2 cos_tilt = cos(geom_tilt_angle);
        //  Conceptual breakdown:
        //      mat3x3 rot_x_matrix = mat3x3(
        //          1.0, 0.0, 0.0,
        //          0.0, cos_tilt.y, -sin_tilt.y,
        //          0.0, sin_tilt.y, cos_tilt.y);
        //      mat3x3 rot_y_matrix = mat3x3(
        //          cos_tilt.x, 0.0, sin_tilt.x,
        //          0.0, 1.0, 0.0,
        //          -sin_tilt.x, 0.0, cos_tilt.x);
        //      mat3x3 local_to_global =
        //          rot_x_matrix * rot_y_matrix;
        //      mat3x3 global_to_local =
        //          transpose(local_to_global);
        mat3x3 local_to_global = mat3x3(
            cos_tilt.x, sin_tilt.y*sin_tilt.x, cos_tilt.y*sin_tilt.x,
            0.0, cos_tilt.y, -sin_tilt.y,
            -sin_tilt.x, sin_tilt.y*cos_tilt.x, cos_tilt.y*cos_tilt.x);
        //  This is a pure rotation, so transpose = inverse:
        mat3x3 global_to_local = transpose(local_to_global);
        //  Decompose the matrix into 3 vec3's for output:
        global_to_local_row0 = vec3(global_to_local[0].xyz);
        global_to_local_row1 = vec3(global_to_local[1].xyz);
        global_to_local_row2 = vec3(global_to_local[2].xyz);
    #else
        mat3x3 global_to_local = geom_global_to_local_static;
        mat3x3 local_to_global = geom_local_to_global_static;
    #endif
	
	//  Get an optimal eye position based on geom_view_dist, viewport_aspect,
    //  and CRT radius/rotation:
    #ifdef RUNTIME_GEOMETRY_MODE
        float geom_mode = geom_mode_runtime;
    #else
        float geom_mode = geom_mode_static;
    #endif
	
	vec3 eye_pos_global = get_ideal_global_eye_pos(local_to_global, geom_aspect, geom_mode);
    eye_pos_local = eye_pos_global, global_to_local;
}

#elif defined(FRAGMENT)
#pragma format R8G8B8A8_SRGB

// had to move this function from geometry-functions to the fragment
// because GLSL only allows derivatives in the fragment
vec2 get_curved_video_uv_coords_and_tangent_matrix(
    vec2 flat_video_uv, vec3 eye_pos_local,
    vec2 output_size_inv, vec2 geom_aspect,
    float geom_mode, mat3x3 global_to_local,
    out mat2x2 pixel_to_tangent_video_uv)
{
    //  Requires:   Parameters:
    //              1.) flat_video_uv coords are in range [0.0, 1.0], where
    //                  (0.0, 0.0) is the top-left corner of the screen and
    //                  (1.0, 1.0) is the bottom-right corner.
    //              2.) eye_pos_local is the 3D camera position in the simulated
    //                  CRT's local coordinate frame.  For best results, it must
    //                  be computed based on the same geom_view_dist used here.
    //              3.) output_size_inv = vec2(1.0)/IN.output_size
    //              4.) geom_aspect = get_aspect_vector(
    //                      IN.output_size.x / IN.output_size.y);
    //              5.) geom_mode is a static or runtime mode setting:
    //                  0 = off, 1 = sphere, 2 = sphere alt., 3 = cylinder
    //              6.) global_to_local is a 3x3 matrix transforming (ordinary)
    //                  worldspace vectors to the CRT's local coordinate frame
    //              Globals:
    //              1.) geom_view_dist must be > 0.0.  It controls the "near
    //                  plane" used to interpret flat_video_uv as a view
    //                  vector, which controls the field of view (FOV).
    //  Returns:    Return final uv coords in [0.0, 1.0], and return a pixel-
    //              space to video_uv tangent-space matrix in the out parameter.
    //              (This matrix assumes pixel-space +y = down, like +v = down.)
    //              We'll transform flat_video_uv into a view vector, project
    //              the view vector from the camera/eye, intersect with a sphere
    //              or cylinder representing the simulated CRT, and convert the
    //              intersection position into final uv coords and a local
    //              transformation matrix.
    //  First get the 3D view vector (geom_aspect and geom_view_dist are globals):
    //  1.) Center uv around (0.0, 0.0) and make (-0.5, -0.5) and (0.5, 0.5)
    //      correspond to the top-left/bottom-right output screen corners.
    //  2.) Multiply by geom_aspect to preemptively "undo" Retroarch's screen-
    //      space 2D aspect correction.  We'll reapply it in uv-space.
    //  3.) (x, y) = (u, -v), because +v is down in 2D screenspace, but +y
    //      is up in 3D worldspace (enforce a right-handed system).
    //  4.) The view vector z controls the "near plane" distance and FOV.
    //      For the effect of "looking through a window" at a CRT, it should be
    //      set equal to the user's distance from their physical screen, in
    //      units of the viewport's physical diagonal size.
    vec2 view_uv = (flat_video_uv - vec2(0.5)) * geom_aspect;
    vec3 view_vec_global =
        vec3(view_uv.x, -view_uv.y, -geom_view_dist);
    //  Transform the view vector into the CRT's local coordinate frame, convert
    //  to video_uv coords, and get the local 3D intersection position:
    vec3 view_vec_local = (view_vec_global * global_to_local);
    vec3 pos;
    vec2 centered_uv = view_vec_to_uv(
        view_vec_local, eye_pos_local, geom_aspect, geom_mode, pos);
    vec2 video_uv = centered_uv + vec2(0.5);
    //  Get a pixel-to-tangent-video-uv matrix.  The caller could deal with
    //  all but one of these cases, but that would be more complicated.
    #ifdef DRIVERS_ALLOW_DERIVATIVES
        //  Derivatives obtain a matrix very fast, but the direction of pixel-
        //  space +y seems to depend on the pass.  Enforce the correct direction
        //  on a best-effort basis (but it shouldn't matter for antialiasing).
        vec2 duv_dx = dFdx(video_uv);
        vec2 duv_dy = dFdy(video_uv);
        #ifdef LAST_PASS
            pixel_to_tangent_video_uv = mat2x2(
                duv_dx.x, duv_dy.x,
                -duv_dx.y, -duv_dy.y);
        #else
            pixel_to_tangent_video_uv = mat2x2(
                duv_dx.x, duv_dy.x,
                duv_dx.y, duv_dy.y);
        #endif
    #else
        //  Manually define a transformation matrix.  We'll assume pixel-space
        //  +y = down, just like +v = down.
        if(geom_force_correct_tangent_matrix == true)
        {
            //  Get the surface normal based on the local intersection position:
            vec3 normal_base = pos;
			if (geom_mode > 2.5) normal_base = vec3(pos.x, 0.0, pos.z);
            vec3 normal = normalize(normal_base);
            //  Get pixel-to-object and object-to-tangent matrices and combine
            //  them into a 2x2 pixel-to-tangent matrix for video_uv offsets:
            mat3x3 pixel_to_object = get_pixel_to_object_matrix(
                global_to_local, eye_pos_local, view_vec_global, pos, normal,
                output_size_inv);
            mat3x3 object_to_tangent = get_object_to_tangent_matrix(
                pos, normal, geom_aspect, geom_mode);
            mat3x3 pixel_to_tangent3x3 =
                (pixel_to_object * object_to_tangent);
            pixel_to_tangent_video_uv = mat2x2(
                pixel_to_tangent3x3[0].xyz, pixel_to_tangent3x3[1].x);
        }
        else
        {
            //  Ignore curvature, and just consider flat scaling.  The
            //  difference is only apparent with strong curvature:
            pixel_to_tangent_video_uv = mat2x2(
                output_size_inv.x, 0.0, 0.0, output_size_inv.y);
        }
    #endif
    return video_uv;
}

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

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 video_and_texture_size_inv;
COMPAT_VARYING vec2 output_size_inv;
COMPAT_VARYING vec3 eye_pos_local;
COMPAT_VARYING vec4 geom_aspect_and_overscan;
#ifdef RUNTIME_GEOMETRY_TILT
COMPAT_VARYING vec3 global_to_local_row0;
COMPAT_VARYING vec3 global_to_local_row1;
COMPAT_VARYING vec3 global_to_local_row2;
#endif

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    //  Localize some parameters:
    vec2 geom_aspect = geom_aspect_and_overscan.xy;
    vec2 geom_overscan = geom_aspect_and_overscan.zw;
    vec2 video_size_inv = video_and_texture_size_inv.xy;
    vec2 texture_size_inv = video_and_texture_size_inv.zw;
	float geom_mode;
	
	#ifdef RUNTIME_GEOMETRY_TILT
        mat3x3 global_to_local = mat3x3(global_to_local_row0,
            global_to_local_row1, global_to_local_row2);
    #else
        mat3x3 global_to_local = geom_global_to_local_static;
    #endif
    #ifdef RUNTIME_GEOMETRY_MODE
        geom_mode = geom_mode_runtime;
    #else
        geom_mode = geom_mode_static;
    #endif
	
	//  Get flat and curved texture coords for the current fragment point sample
    //  and a pixel_to_tangent_video_uv matrix for transforming pixel offsets:
    //  video_uv = relative position in video frame, mapped to [0.0, 1.0] range
    //  tex_uv = relative position in padded texture, mapped to [0.0, 1.0] range
    vec2 flat_video_uv = vTexCoord.xy * (SourceSize.xy * video_size_inv);
    mat2x2 pixel_to_video_uv;
    vec2 video_uv_no_geom_overscan;
    if(geom_mode > 0.5)
    {
        video_uv_no_geom_overscan =
            get_curved_video_uv_coords_and_tangent_matrix(flat_video_uv,
                eye_pos_local, output_size_inv, geom_aspect,
                geom_mode, global_to_local, pixel_to_video_uv);
    }
    else
    {
        video_uv_no_geom_overscan = flat_video_uv;
        pixel_to_video_uv = mat2x2(
            output_size_inv.x, 0.0, 0.0, output_size_inv.y);
    }
	
	//  Correct for overscan here (not in curvature code):
    vec2 video_uv = (video_uv_no_geom_overscan - vec2(0.5))/geom_overscan + vec2(0.5);
    vec2 tex_uv = video_uv * (InputSize * texture_size_inv);
	
	//  Get a matrix transforming pixel vectors to tex_uv vectors:
    mat2x2 pixel_to_tex_uv =
        mul_scale(SourceSize.xy * texture_size_inv /
            geom_aspect_and_overscan.zw, pixel_to_video_uv);
			
	//  Sample!  Skip antialiasing if aa_level < 0.5 or both of these hold:
    //  1.) Geometry/curvature isn't used
    //  2.) Overscan == vec2(1.0)
    //  Skipping AA is sharper, but it's only faster with dynamic branches.
    vec2 abs_aa_r_offset = abs(get_aa_subpixel_r_offset());
    bool need_subpixel_aa = true;
	if(abs_aa_r_offset.x + abs_aa_r_offset.y < 0.0) need_subpixel_aa = false;
    vec3 color;
    if(aa_level > 0.5 && (geom_mode > 0.5 || any(notEqual(geom_overscan , vec2(1.0)))))
    {
        //  Sample the input with antialiasing (due to sharp phosphors, etc.):
        color = tex2Daa(Source, tex_uv, pixel_to_tex_uv, FrameCount);
    }
    else if(aa_level > 0.5 && need_subpixel_aa == true)
    {
        //  Sample at each subpixel location:
        color = tex2Daa_subpixel_weights_only(
            Source, tex_uv, pixel_to_tex_uv);
    }
    else
    {
        color = tex2D_linearize(Source, tex_uv).rgb;
    }
	
	//  Dim borders and output the final result:
    float border_dim_factor = get_border_dim_factor(video_uv, geom_aspect);
    vec3 final_color = color * border_dim_factor;

   FragColor = encode_output(vec4(final_color, 1.0));
} 
#endif
