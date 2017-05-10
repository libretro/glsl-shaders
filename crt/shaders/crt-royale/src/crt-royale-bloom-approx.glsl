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
#define RUNTIME_ANTIALIAS_WEIGHTS
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

///////////   BEGIN #include scanline-functions.h     /////////////////
#ifndef SCANLINE_FUNCTIONS_H
#define SCANLINE_FUNCTIONS_H

//////////////////////////////////  INCLUDES  //////////////////////////////////

//#include "../user-settings.h"
//#include "derived-settings-and-constants.h"
/////////   BEGIN #include "../../../../include/special-functions.h"   /////////
#ifndef SPECIAL_FUNCTIONS_H
#define SPECIAL_FUNCTIONS_H


/////////////////////////////////  MIT LICENSE  ////////////////////////////////

//  Copyright (C) 2014 TroggleMonkey
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.


/////////////////////////////////  DESCRIPTION  ////////////////////////////////

//  This file implements the following mathematical special functions:
//  1.) erf() = 2/sqrt(pi) * indefinite_integral(e**(-x**2))
//  2.) gamma(s), a real-numbered extension of the integer factorial function
//  It also implements normalized_ligamma(s, z), a normalized lower incomplete
//  gamma function for s < 0.5 only.  Both gamma() and normalized_ligamma() can
//  be called with an _impl suffix to use an implementation version with a few
//  extra precomputed parameters (which may be useful for the caller to reuse).
//  See below for details.
//
//  Design Rationale:
//  Pretty much every line of code in this file is duplicated four times for
//  different input types (vec4/vec3/vec2/float).  This is unfortunate,
//  but Cg doesn't allow function templates.  Macros would be far less verbose,
//  but they would make the code harder to document and read.  I don't expect
//  these functions will require a whole lot of maintenance changes unless
//  someone ever has need for more robust incomplete gamma functions, so code
//  duplication seems to be the lesser evil in this case.


///////////////////////////  GAUSSIAN ERROR FUNCTION  //////////////////////////

vec4 erf6(vec4 x)
{
    //  Requires:   x is the standard parameter to erf().
    //  Returns:    Return an Abramowitz/Stegun approximation of erf(), where:
    //                  erf(x) = 2/sqrt(pi) * integral(e**(-x**2))
    //              This approximation has a max absolute error of 2.5*10**-5
    //              with solid numerical robustness and efficiency.  See:
	//                  https://en.wikipedia.org/wiki/Error_function#Approximation_with_elementary_functions
	vec4 one = vec4(1.0);
	vec4 sign_x = sign(x);
	vec4 t = one/(one + 0.47047*abs(x));
	vec4 result = one - t*(0.3480242 + t*(-0.0958798 + t*0.7478556))*
		exp(-(x*x));
	return result * sign_x;
}

vec3 erf6(vec3 x)
{
    //  vec3 version:
	vec3 one = vec3(1.0);
	vec3 sign_x = sign(x);
	vec3 t = one/(one + 0.47047*abs(x));
	vec3 result = one - t*(0.3480242 + t*(-0.0958798 + t*0.7478556))*
		exp(-(x*x));
	return result * sign_x;
}

vec2 erf6(vec2 x)
{
    //  vec2 version:
	vec2 one = vec2(1.0);
	vec2 sign_x = sign(x);
	vec2 t = one/(one + 0.47047*abs(x));
	vec2 result = one - t*(0.3480242 + t*(-0.0958798 + t*0.7478556))*
		exp(-(x*x));
	return result * sign_x;
}

float erf6(float x)
{
    //  Float version:
	float sign_x = sign(x);
	float t = 1.0/(1.0 + 0.47047*abs(x));
	float result = 1.0 - t*(0.3480242 + t*(-0.0958798 + t*0.7478556))*
		exp(-(x*x));
	return result * sign_x;
}

vec4 erft(vec4 x)
{
    //  Requires:   x is the standard parameter to erf().
    //  Returns:    Approximate erf() with the hyperbolic tangent.  The error is
    //              visually noticeable, but it's blazing fast and perceptually
    //              close...at least on ATI hardware.  See:
    //                  http://www.maplesoft.com/applications/view.aspx?SID=5525&view=html
    //  Warning:    Only use this if your hardware drivers correctly implement
    //              tanh(): My nVidia 8800GTS returns garbage output.
	return tanh(1.202760580 * x);
}

vec3 erft(vec3 x)
{
    //  vec3 version:
	return tanh(1.202760580 * x);
}

vec2 erft(vec2 x)
{
    //  vec2 version:
	return tanh(1.202760580 * x);
}

float erft(float x)
{
    //  Float version:
	return tanh(1.202760580 * x);
}

vec4 erf(vec4 x)
{
    //  Requires:   x is the standard parameter to erf().
    //  Returns:    Some approximation of erf(x), depending on user settings.
	#ifdef ERF_FAST_APPROXIMATION
		return erft(x);
	#else
		return erf6(x);
	#endif
}

vec3 erf(vec3 x)
{
    //  vec3 version:
	#ifdef ERF_FAST_APPROXIMATION
		return erft(x);
	#else
		return erf6(x);
	#endif
}

vec2 erf(vec2 x)
{
    //  vec2 version:
	#ifdef ERF_FAST_APPROXIMATION
		return erft(x);
	#else
		return erf6(x);
	#endif
}

float erf(float x)
{
    //  Float version:
	#ifdef ERF_FAST_APPROXIMATION
		return erft(x);
	#else
		return erf6(x);
	#endif
}

///////////////////////////  COMPLETE GAMMA FUNCTION  //////////////////////////

vec4 gamma_impl(vec4 s, vec4 s_inv)
{
    //  Requires:   1.) s is the standard parameter to the gamma function, and
    //                  it should lie in the [0, 36] range.
    //              2.) s_inv = 1.0/s.  This implementation function requires
    //                  the caller to precompute this value, giving users the
    //                  opportunity to reuse it.
    //  Returns:    Return approximate gamma function (real-numbered factorial)
    //              output using the Lanczos approximation with two coefficients
    //              calculated using Paul Godfrey's method here:
    //                  http://my.fit.edu/~gabdo/gamma.txt
    //              An optimal g value for s in [0, 36] is ~1.12906830989, with
    //              a maximum relative error of 0.000463 for 2**16 equally
    //              evals.  We could use three coeffs (0.0000346 error) without
    //              hurting latency, but this allows more parallelism with
    //              outside instructions.
	vec4 g = vec4(1.12906830989);
	vec4 c0 = vec4(0.8109119309638332633713423362694399653724431);
	vec4 c1 = vec4(0.4808354605142681877121661197951496120000040);
	vec4 e = vec4(2.71828182845904523536028747135266249775724709);
	vec4 sph = s + vec4(0.5);
	vec4 lanczos_sum = c0 + c1/(s + vec4(1.0));
	vec4 base = (sph + g)/e;  //  or (s + g + vec4(0.5))/e
	//  gamma(s + 1) = base**sph * lanczos_sum; divide by s for gamma(s).
	//  This has less error for small s's than (s -= 1.0) at the beginning.
	return (pow(base, sph) * lanczos_sum) * s_inv;
}

vec3 gamma_impl(vec3 s, vec3 s_inv)
{
    //  vec3 version:
	vec3 g = vec3(1.12906830989);
	vec3 c0 = vec3(0.8109119309638332633713423362694399653724431);
	vec3 c1 = vec3(0.4808354605142681877121661197951496120000040);
	vec3 e = vec3(2.71828182845904523536028747135266249775724709);
	vec3 sph = s + vec3(0.5);
	vec3 lanczos_sum = c0 + c1/(s + vec3(1.0));
	vec3 base = (sph + g)/e;
	return (pow(base, sph) * lanczos_sum) * s_inv;
}

vec2 gamma_impl(vec2 s, vec2 s_inv)
{
    //  vec2 version:
	vec2 g = vec2(1.12906830989);
	vec2 c0 = vec2(0.8109119309638332633713423362694399653724431);
	vec2 c1 = vec2(0.4808354605142681877121661197951496120000040);
	vec2 e = vec2(2.71828182845904523536028747135266249775724709);
	vec2 sph = s + vec2(0.5);
	vec2 lanczos_sum = c0 + c1/(s + vec2(1.0));
	vec2 base = (sph + g)/e;
	return (pow(base, sph) * lanczos_sum) * s_inv;
}

float gamma_impl(float s, float s_inv)
{
    //  Float version:
	float g = 1.12906830989;
	float c0 = 0.8109119309638332633713423362694399653724431;
	float c1 = 0.4808354605142681877121661197951496120000040;
	float e = 2.71828182845904523536028747135266249775724709;
	float sph = s + 0.5;
	float lanczos_sum = c0 + c1/(s + 1.0);
	float base = (sph + g)/e;
	return (pow(base, sph) * lanczos_sum) * s_inv;
}

vec4 gamma(vec4 s)
{
    //  Requires:   s is the standard parameter to the gamma function, and it
    //              should lie in the [0, 36] range.
    //  Returns:    Return approximate gamma function output with a maximum
    //              relative error of 0.000463.  See gamma_impl for details.
	return gamma_impl(s, vec4(1.0)/s);
}

vec3 gamma(vec3 s)
{
    //  vec3 version:
	return gamma_impl(s, vec3(1.0)/s);
}

vec2 gamma(vec2 s)
{
    //  vec2 version:
	return gamma_impl(s, vec2(1.0)/s);
}

float gamma(float s)
{
    //  Float version:
	return gamma_impl(s, 1.0/s);
}

////////////////  INCOMPLETE GAMMA FUNCTIONS (RESTRICTED INPUT)  ///////////////

//  Lower incomplete gamma function for small s and z (implementation):
vec4 ligamma_small_z_impl(vec4 s, vec4 z, vec4 s_inv)
{
    //  Requires:   1.) s < ~0.5
    //              2.) z <= ~0.775075
    //              3.) s_inv = 1.0/s (precomputed for outside reuse)
    //  Returns:    A series representation for the lower incomplete gamma
    //              function for small s and small z (4 terms).
    //  The actual "rolled up" summation looks like:
	//      last_sign = 1.0; last_pow = 1.0; last_factorial = 1.0;
	//      sum = last_sign * last_pow / ((s + k) * last_factorial)
	//      for(int i = 0; i < 4; ++i)
	//      {
	//          last_sign *= -1.0; last_pow *= z; last_factorial *= i;
	//          sum += last_sign * last_pow / ((s + k) * last_factorial);
	//      }
	//  Unrolled, constant-unfolded and arranged for madds and parallelism:
	vec4 scale = pow(z, s);
	vec4 sum = s_inv;  //  Summation iteration 0 result
	//  Summation iterations 1, 2, and 3:
	vec4 z_sq = z*z;
	vec4 denom1 = s + vec4(1.0);
	vec4 denom2 = 2.0*s + vec4(4.0);
	vec4 denom3 = 6.0*s + vec4(18.0);
	//vec4 denom4 = 24.0*s + vec4(96.0);
	sum -= z/denom1;
	sum += z_sq/denom2;
	sum -= z * z_sq/denom3;
	//sum += z_sq * z_sq / denom4;
	//  Scale and return:
	return scale * sum;
}

vec3 ligamma_small_z_impl(vec3 s, vec3 z, vec3 s_inv)
{
    //  vec3 version:
	vec3 scale = pow(z, s);
	vec3 sum = s_inv;
	vec3 z_sq = z*z;
	vec3 denom1 = s + vec3(1.0);
	vec3 denom2 = 2.0*s + vec3(4.0);
	vec3 denom3 = 6.0*s + vec3(18.0);
	sum -= z/denom1;
	sum += z_sq/denom2;
	sum -= z * z_sq/denom3;
	return scale * sum;
}

vec2 ligamma_small_z_impl(vec2 s, vec2 z, vec2 s_inv)
{
    //  vec2 version:
	vec2 scale = pow(z, s);
	vec2 sum = s_inv;
	vec2 z_sq = z*z;
	vec2 denom1 = s + vec2(1.0);
	vec2 denom2 = 2.0*s + vec2(4.0);
	vec2 denom3 = 6.0*s + vec2(18.0);
	sum -= z/denom1;
	sum += z_sq/denom2;
	sum -= z * z_sq/denom3;
	return scale * sum;
}

float ligamma_small_z_impl(float s, float z, float s_inv)
{
    //  Float version:
	float scale = pow(z, s);
	float sum = s_inv;
	float z_sq = z*z;
	float denom1 = s + 1.0;
	float denom2 = 2.0*s + 4.0;
	float denom3 = 6.0*s + 18.0;
	sum -= z/denom1;
	sum += z_sq/denom2;
	sum -= z * z_sq/denom3;
	return scale * sum;
}

//  Upper incomplete gamma function for small s and large z (implementation):
vec4 uigamma_large_z_impl(vec4 s, vec4 z)
{
    //  Requires:   1.) s < ~0.5
    //              2.) z > ~0.775075
    //  Returns:    Gauss's continued fraction representation for the upper
    //              incomplete gamma function (4 terms).
	//  The "rolled up" continued fraction looks like this.  The denominator
    //  is truncated, and it's calculated "from the bottom up:"
	//      denom = vec4('inf');
	//      vec4 one = vec4(1.0);
	//      for(int i = 4; i > 0; --i)
	//      {
	//          denom = ((i * 2.0) - one) + z - s + (i * (s - i))/denom;
	//      }
	//  Unrolled and constant-unfolded for madds and parallelism:
	vec4 numerator = pow(z, s) * exp(-z);
	vec4 denom = vec4(7.0) + z - s;
	denom = vec4(5.0) + z - s + (3.0*s - vec4(9.0))/denom;
	denom = vec4(3.0) + z - s + (2.0*s - vec4(4.0))/denom;
	denom = vec4(1.0) + z - s + (s - vec4(1.0))/denom;
	return numerator / denom;
}

vec3 uigamma_large_z_impl(vec3 s, vec3 z)
{
    //  vec3 version:
	vec3 numerator = pow(z, s) * exp(-z);
	vec3 denom = vec3(7.0) + z - s;
	denom = vec3(5.0) + z - s + (3.0*s - vec3(9.0))/denom;
	denom = vec3(3.0) + z - s + (2.0*s - vec3(4.0))/denom;
	denom = vec3(1.0) + z - s + (s - vec3(1.0))/denom;
	return numerator / denom;
}

vec2 uigamma_large_z_impl(vec2 s, vec2 z)
{
    //  vec2 version:
	vec2 numerator = pow(z, s) * exp(-z);
	vec2 denom = vec2(7.0) + z - s;
	denom = vec2(5.0) + z - s + (3.0*s - vec2(9.0))/denom;
	denom = vec2(3.0) + z - s + (2.0*s - vec2(4.0))/denom;
	denom = vec2(1.0) + z - s + (s - vec2(1.0))/denom;
	return numerator / denom;
}

float uigamma_large_z_impl(float s, float z)
{
    //  Float version:
	float numerator = pow(z, s) * exp(-z);
	float denom = 7.0 + z - s;
	denom = 5.0 + z - s + (3.0*s - 9.0)/denom;
	denom = 3.0 + z - s + (2.0*s - 4.0)/denom;
	denom = 1.0 + z - s + (s - 1.0)/denom;
	return numerator / denom;
}

//  Normalized lower incomplete gamma function for small s (implementation):
vec4 normalized_ligamma_impl(vec4 s, vec4 z,
    vec4 s_inv, vec4 gamma_s_inv)
{
    //  Requires:   1.) s < ~0.5
    //              2.) s_inv = 1/s (precomputed for outside reuse)
    //              3.) gamma_s_inv = 1/gamma(s) (precomputed for outside reuse)
    //  Returns:    Approximate the normalized lower incomplete gamma function
    //              for s < 0.5.  Since we only care about s < 0.5, we only need
    //              to evaluate two branches (not four) based on z.  Each branch
    //              uses four terms, with a max relative error of ~0.00182.  The
    //              branch threshold and specifics were adapted for fewer terms
    //              from Gil/Segura/Temme's paper here:
    //                  http://oai.cwi.nl/oai/asset/20433/20433B.pdf
	//  Evaluate both branches: Real branches test slower even when available.
	vec4 thresh = vec4(0.775075);
	bvec4 z_is_large = greaterThan(z , thresh);
	vec4 z_size_check = vec4(z_is_large.x ? 1.0 : 0.0, z_is_large.y ? 1.0 : 0.0, z_is_large.z ? 1.0 : 0.0, z_is_large.w ? 1.0 : 0.0);
	vec4 large_z = vec4(1.0) - uigamma_large_z_impl(s, z) * gamma_s_inv;
	vec4 small_z = ligamma_small_z_impl(s, z, s_inv) * gamma_s_inv;
	//  Combine the results from both branches:
	return large_z * vec4(z_size_check) + small_z * vec4(z_size_check);
}

vec3 normalized_ligamma_impl(vec3 s, vec3 z,
    vec3 s_inv, vec3 gamma_s_inv)
{
    //  vec3 version:
	vec3 thresh = vec3(0.775075);
	bvec3 z_is_large = greaterThan(z , thresh);
	vec3 z_size_check = vec3(z_is_large.x ? 1.0 : 0.0, z_is_large.y ? 1.0 : 0.0, z_is_large.z ? 1.0 : 0.0);
	vec3 large_z = vec3(1.0) - uigamma_large_z_impl(s, z) * gamma_s_inv;
	vec3 small_z = ligamma_small_z_impl(s, z, s_inv) * gamma_s_inv;
	return large_z * vec3(z_size_check) + small_z * vec3(z_size_check);
}

vec2 normalized_ligamma_impl(vec2 s, vec2 z,
    vec2 s_inv, vec2 gamma_s_inv)
{
    //  vec2 version:
	vec2 thresh = vec2(0.775075);
	bvec2 z_is_large = greaterThan(z , thresh);
	vec2 z_size_check = vec2(z_is_large.x ? 1.0 : 0.0, z_is_large.y ? 1.0 : 0.0);
	vec2 large_z = vec2(1.0) - uigamma_large_z_impl(s, z) * gamma_s_inv;
	vec2 small_z = ligamma_small_z_impl(s, z, s_inv) * gamma_s_inv;
	return large_z * vec2(z_size_check) + small_z * vec2(z_size_check);
}

float normalized_ligamma_impl(float s, float z,
    float s_inv, float gamma_s_inv)
{
    //  Float version:
	float thresh = 0.775075;
	float z_size_check = 0.0;
	if (z > thresh) z_size_check = 1.0;
	float large_z = 1.0 - uigamma_large_z_impl(s, z) * gamma_s_inv;
	float small_z = ligamma_small_z_impl(s, z, s_inv) * gamma_s_inv;
	return large_z * float(z_size_check) + small_z * float(z_size_check);
}

//  Normalized lower incomplete gamma function for small s:
vec4 normalized_ligamma(vec4 s, vec4 z)
{
    //  Requires:   s < ~0.5
    //  Returns:    Approximate the normalized lower incomplete gamma function
    //              for s < 0.5.  See normalized_ligamma_impl() for details.
	vec4 s_inv = vec4(1.0)/s;
	vec4 gamma_s_inv = vec4(1.0)/gamma_impl(s, s_inv);
	return normalized_ligamma_impl(s, z, s_inv, gamma_s_inv);
}

vec3 normalized_ligamma(vec3 s, vec3 z)
{
    //  vec3 version:
	vec3 s_inv = vec3(1.0)/s;
	vec3 gamma_s_inv = vec3(1.0)/gamma_impl(s, s_inv);
	return normalized_ligamma_impl(s, z, s_inv, gamma_s_inv);
}

vec2 normalized_ligamma(vec2 s, vec2 z)
{
    //  vec2 version:
	vec2 s_inv = vec2(1.0)/s;
	vec2 gamma_s_inv = vec2(1.0)/gamma_impl(s, s_inv);
	return normalized_ligamma_impl(s, z, s_inv, gamma_s_inv);
}

float normalized_ligamma(float s, float z)
{
    //  Float version:
	float s_inv = 1.0/s;
	float gamma_s_inv = 1.0/gamma_impl(s, s_inv);
	return normalized_ligamma_impl(s, z, s_inv, gamma_s_inv);
}

#endif  //  SPECIAL_FUNCTIONS_H
/////////   END #include "../../../../include/special-functions.h"   /////////
//#include "../../../../include/gamma-management.h"

/////////////////////////////  SCANLINE FUNCTIONS  /////////////////////////////

vec3 get_raw_interpolated_color(vec3 color0,
    vec3 color1, vec3 color2, vec3 color3,
    vec4 weights)
{
    //  Use max to avoid bizarre artifacts from negative colors:
    return max(mat4x3(color0, color1, color2, color3) * weights, 0.0);
}

vec3 get_interpolated_linear_color(vec3 color0, vec3 color1,
    vec3 color2, vec3 color3, vec4 weights)
{
    //  Requires:   1.) Requirements of include/gamma-management.h must be met:
    //                  intermediate_gamma must be globally defined, and input
    //                  colors are interpreted as linear RGB unless you #define
    //                  GAMMA_ENCODE_EVERY_FBO (in which case they are
    //                  interpreted as gamma-encoded with intermediate_gamma).
    //              2.) color0-3 are colors sampled from a texture with tex2D().
    //                  They are interpreted as defined in requirement 1.
    //              3.) weights contains weights for each color, summing to 1.0.
    //              4.) beam_horiz_linear_rgb_weight must be defined as a global
    //                  float in [0.0, 1.0] describing how much blending should
    //                  be done in linear RGB (rest is gamma-corrected RGB).
    //              5.) RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE must be #defined
    //                  if beam_horiz_linear_rgb_weight is anything other than a
    //                  static constant, or we may try branching at runtime
    //                  without dynamic branches allowed (slow).
    //  Returns:    Return an interpolated color lookup between the four input
    //              colors based on the weights in weights.  The final color will
    //              be a linear RGB value, but the blending will be done as
    //              indicated above.
    float intermediate_gamma = get_intermediate_gamma();
    //  Branch if beam_horiz_linear_rgb_weight is static (for free) or if the
    //  profile allows dynamic branches (faster than computing extra pows):
    #ifndef RUNTIME_SCANLINES_HORIZ_FILTER_COLORSPACE
        #define SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
    #else
        #ifdef DRIVERS_ALLOW_DYNAMIC_BRANCHES
            #define SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
        #endif
    #endif
    #ifdef SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
        //  beam_horiz_linear_rgb_weight is static, so we can branch:
        #ifdef GAMMA_ENCODE_EVERY_FBO
            vec3 gamma_mixed_color = pow(get_raw_interpolated_color(
                color0, color1, color2, color3, weights), vec3(intermediate_gamma));
            if(beam_horiz_linear_rgb_weight > 0.0)
            {
                vec3 linear_mixed_color = get_raw_interpolated_color(
                    pow(color0, vec3(intermediate_gamma)),
                    pow(color1, vec3(intermediate_gamma)),
                    pow(color2, vec3(intermediate_gamma)),
                    pow(color3, vec3(intermediate_gamma)),
                    weights);
                return mix(gamma_mixed_color, linear_mixed_color,
                    beam_horiz_linear_rgb_weight);
            }
            else
            {
                return gamma_mixed_color;
            }
        #else
            vec3 linear_mixed_color = get_raw_interpolated_color(
                color0, color1, color2, color3, weights);
            if(beam_horiz_linear_rgb_weight < 1.0)
            {
                vec3 gamma_mixed_color = get_raw_interpolated_color(
                    pow(color0, vec3(1.0/intermediate_gamma)),
                    pow(color1, vec3(1.0/intermediate_gamma)),
                    pow(color2, vec3(1.0/intermediate_gamma)),
                    pow(color3, vec3(1.0/intermediate_gamma)),
                    weights);
                return mix(gamma_mixed_color, linear_mixed_color,
                    beam_horiz_linear_rgb_weight);
            }
            else
            {
                return linear_mixed_color;
            }
        #endif  //  GAMMA_ENCODE_EVERY_FBO
    #else
        #ifdef GAMMA_ENCODE_EVERY_FBO
            //  Inputs: color0-3 are colors in gamma-encoded RGB.
            vec3 gamma_mixed_color = pow(get_raw_interpolated_color(
                color0, color1, color2, color3, weights), vec3(intermediate_gamma));
            vec3 linear_mixed_color = get_raw_interpolated_color(
                pow(color0, vec3(intermediate_gamma)),
                pow(color1, vec3(intermediate_gamma)),
                pow(color2, vec3(intermediate_gamma)),
                pow(color3, vec3(intermediate_gamma)),
                weights);
            return mix(gamma_mixed_color, linear_mixed_color,
                beam_horiz_linear_rgb_weight);
        #else
            //  Inputs: color0-3 are colors in linear RGB.
            vec3 linear_mixed_color = get_raw_interpolated_color(
                color0, color1, color2, color3, weights);
            vec3 gamma_mixed_color = get_raw_interpolated_color(
                    pow(color0, vec3(1.0/intermediate_gamma)),
                    pow(color1, vec3(1.0/intermediate_gamma)),
                    pow(color2, vec3(1.0/intermediate_gamma)),
                    pow(color3, vec3(1.0/intermediate_gamma)),
                    weights);
            return mix(gamma_mixed_color, linear_mixed_color,
                beam_horiz_linear_rgb_weight);
        #endif  //  GAMMA_ENCODE_EVERY_FBO
    #endif  //  SCANLINES_BRANCH_FOR_LINEAR_RGB_WEIGHT
}

vec3 get_scanline_color(sampler2D tex, vec2 scanline_uv,
    vec2 uv_step_x, vec4 weights)
{
    //  Requires:   1.) scanline_uv must be vertically snapped to the caller's
    //                  desired line or scanline and horizontally snapped to the
    //                  texel just left of the output pixel (color1)
    //              2.) uv_step_x must contain the horizontal uv distance
    //                  between texels.
    //              3.) weights must contain interpolation filter weights for
    //                  color0, color1, color2, and color3, where color1 is just
    //                  left of the output pixel.
    //  Returns:    Return a horizontally interpolated texture lookup using 2-4
    //              nearby texels, according to weights and the conventions of
    //              get_interpolated_linear_color().
    //  We can ignore the outside texture lookups for Quilez resampling.
    vec3 color1 = texture(tex, scanline_uv).rgb;
    vec3 color2 = texture(tex, scanline_uv + uv_step_x).rgb;
    vec3 color0 = vec3(0.0);
    vec3 color3 = vec3(0.0);
    if(beam_horiz_filter > 0.5)
    {
        color0 = texture(tex, scanline_uv - uv_step_x).rgb;
        color3 = texture(tex, scanline_uv + 2.0 * uv_step_x).rgb;
    }
    //  Sample the texture as-is, whether it's linear or gamma-encoded:
    //  get_interpolated_linear_color() will handle the difference.
    return get_interpolated_linear_color(color0, color1, color2, color3, weights);
}

vec3 sample_single_scanline_horizontal(sampler2D texture,
    vec2 tex_uv, vec2 texture_size,
    vec2 texture_size_inv)
{
    //  TODO: Add function requirements.
    //  Snap to the previous texel and get sample dists from 2/4 nearby texels:
    vec2 curr_texel = tex_uv * texture_size;
    //  Use under_half to fix a rounding bug right around exact texel locations.
    vec2 prev_texel =
        floor(curr_texel - vec2(under_half)) + vec2(0.5);
    vec2 prev_texel_hor = vec2(prev_texel.x, curr_texel.y);
    vec2 prev_texel_hor_uv = prev_texel_hor * texture_size_inv;
    float prev_dist = curr_texel.x - prev_texel_hor.x;
    vec4 sample_dists = vec4(1.0 + prev_dist, prev_dist,
        1.0 - prev_dist, 2.0 - prev_dist);
    //  Get Quilez, Lanczos2, or Gaussian resize weights for 2/4 nearby texels:
    vec4 weights;
    if(beam_horiz_filter < 0.5)
    {
        //  Quilez:
        float x = sample_dists.y;
        float w2 = x*x*x*(x*(x*6.0 - 15.0) + 10.0);
        weights = vec4(0.0, 1.0 - w2, w2, 0.0);
    }
    else if(beam_horiz_filter < 1.5)
    {
        //  Gaussian:
        float inner_denom_inv = 1.0/(2.0*beam_horiz_sigma*beam_horiz_sigma);
        weights = exp(-(sample_dists*sample_dists)*inner_denom_inv);
    }
    else
    {
        //  Lanczos2:
        vec4 pi_dists = FIX_ZERO(sample_dists * pi);
        weights = 2.0 * sin(pi_dists) * sin(pi_dists * 0.5) /
            (pi_dists * pi_dists);
    }
    //  Ensure the weight sum == 1.0:
    vec4 final_weights = weights/dot(weights, vec4(1.0));
    //  Get the interpolated horizontal scanline color:
    vec2 uv_step_x = vec2(texture_size_inv.x, 0.0);
    return get_scanline_color(
        texture, prev_texel_hor_uv, uv_step_x, final_weights);
}

bool is_interlaced(float num_lines)
{
    //  Detect interlacing based on the number of lines in the source.
    if(interlace_detect == true)
    {
        //  NTSC: 525 lines, 262.5/field; 486 active (2 half-lines), 243/field
        //  NTSC Emulators: Typically 224 or 240 lines
        //  PAL: 625 lines, 312.5/field; 576 active (typical), 288/field
        //  PAL Emulators: ?
        //  ATSC: 720p, 1080i, 1080p
        //  Where do we place our cutoffs?  Assumptions:
        //  1.) We only need to care about active lines.
        //  2.) Anything > 288 and <= 576 lines is probably interlaced.
        //  3.) Anything > 576 lines is probably not interlaced...
        //  4.) ...except 1080 lines, which is a crapshoot (user decision).
        //  5.) Just in case the main program uses calculated video sizes,
        //      we should nudge the float thresholds a bit.
        bool sd_interlace;
		if (num_lines > 288.5 && num_lines < 576.5)
			{sd_interlace = true;}
		else
			{sd_interlace = false;}
        bool hd_interlace;
        if (num_lines > 1079.5 && num_lines < 1080.5)
			{hd_interlace = true;}
		else
			{hd_interlace = false;}
		return (sd_interlace || hd_interlace);
    }
    else
    {
        return false;
    }
}

vec3 sample_rgb_scanline_horizontal(sampler2D tex,
    vec2 tex_uv, vec2 texture_size,
    vec2 texture_size_inv)
{
    //  TODO: Add function requirements.
    //  Rely on a helper to make convergence easier.
    if(beam_misconvergence == true)
    {
        vec3 convergence_offsets_rgb =
            get_convergence_offsets_x_vector();
        vec3 offset_u_rgb =
            convergence_offsets_rgb * texture_size_inv.xxx;
        vec2 scanline_uv_r = tex_uv - vec2(offset_u_rgb.r, 0.0);
        vec2 scanline_uv_g = tex_uv - vec2(offset_u_rgb.g, 0.0);
        vec2 scanline_uv_b = tex_uv - vec2(offset_u_rgb.b, 0.0);
        vec3 sample_r = sample_single_scanline_horizontal(
            tex, scanline_uv_r, texture_size, texture_size_inv);
        vec3 sample_g = sample_single_scanline_horizontal(
            tex, scanline_uv_g, texture_size, texture_size_inv);
        vec3 sample_b = sample_single_scanline_horizontal(
            tex, scanline_uv_b, texture_size, texture_size_inv);
        return vec3(sample_r.r, sample_g.g, sample_b.b);
    }
    else
    {
        return sample_single_scanline_horizontal(tex, tex_uv, texture_size,
            texture_size_inv);
    }
}

vec2 get_last_scanline_uv(vec2 tex_uv, vec2 texture_size,
    vec2 texture_size_inv, vec2 il_step_multiple,
    float frame_count, out float dist)
{
    //  Compute texture coords for the last/upper scanline, accounting for
    //  interlacing: With interlacing, only consider even/odd scanlines every
    //  other frame.  Top-field first (TFF) order puts even scanlines on even
    //  frames, and BFF order puts them on odd frames.  Texels are centered at:
    //      frac(tex_uv * texture_size) == x.5
    //  Caution: If these coordinates ever seem incorrect, first make sure it's
    //  not because anisotropic filtering is blurring across field boundaries.
    //  Note: TFF/BFF won't matter for sources that double-weave or similar.
    float field_offset = floor(il_step_multiple.y * 0.75) *
        mod(frame_count + float(interlace_bff), 2.0);
    vec2 curr_texel = tex_uv * texture_size;
    //  Use under_half to fix a rounding bug right around exact texel locations.
    vec2 prev_texel_num = floor(curr_texel - vec2(under_half));
    float wrong_field = mod(
        prev_texel_num.y + field_offset, il_step_multiple.y);
    vec2 scanline_texel_num = prev_texel_num - vec2(0.0, wrong_field);
    //  Snap to the center of the previous scanline in the current field:
    vec2 scanline_texel = scanline_texel_num + vec2(0.5);
    vec2 scanline_uv = scanline_texel * texture_size_inv;
    //  Save the sample's distance from the scanline, in units of scanlines:
    dist = (curr_texel.y - scanline_texel.y)/il_step_multiple.y;
    return scanline_uv;
}

vec3 get_gaussian_sigma(vec3 color, float sigma_range)
{
    //  Requires:   Globals:
    //              1.) beam_min_sigma and beam_max_sigma are global floats
    //                  containing the desired minimum and maximum beam standard
    //                  deviations, for dim and bright colors respectively.
    //              2.) beam_max_sigma must be > 0.0
    //              3.) beam_min_sigma must be in (0.0, beam_max_sigma]
    //              4.) beam_spot_power must be defined as a global float.
    //              Parameters:
    //              1.) color is the underlying source color along a scanline
    //              2.) sigma_range = beam_max_sigma - beam_min_sigma; we take
    //                  sigma_range as a parameter to avoid repeated computation
    //                  when beam_{min, max}_sigma are runtime shader parameters
    //  Optional:   Users may set beam_spot_shape_function to 1 to define the
    //              inner f(color) subfunction (see below) as:
    //                  f(color) = sqrt(1.0 - (color - 1.0)*(color - 1.0))
    //              Otherwise (technically, if beam_spot_shape_function < 0.5):
    //                  f(color) = pow(color, beam_spot_power)
    //  Returns:    The standard deviation of the Gaussian beam for "color:"
    //                  sigma = beam_min_sigma + sigma_range * f(color)
    //  Details/Discussion:
    //  The beam's spot shape vaguely resembles an aspect-corrected f() in the
    //  range [0, 1] (not quite, but it's related).  f(color) = color makes
    //  spots look like diamonds, and a spherical function or cube balances
    //  between variable width and a soft/realistic shape.   A beam_spot_power
    //  > 1.0 can produce an ugly spot shape and more initial clipping, but the
    //  final shape also differs based on the horizontal resampling filter and
    //  the phosphor bloom.  For instance, resampling horizontally in nonlinear
    //  light and/or with a sharp (e.g. Lanczos) filter will sharpen the spot
    //  shape, but a sixth root is still quite soft.  A power function (default
    //  1.0/3.0 beam_spot_power) is most flexible, but a fixed spherical curve
    //  has the highest variability without an awful spot shape.
    //
    //  beam_min_sigma affects scanline sharpness/aliasing in dim areas, and its
    //  difference from beam_max_sigma affects beam width variability.  It only
    //  affects clipping [for pure Gaussians] if beam_spot_power > 1.0 (which is
    //  a conservative estimate for a more complex constraint).
    //
    //  beam_max_sigma affects clipping and increasing scanline width/softness
    //  as color increases.  The wider this is, the more scanlines need to be
    //  evaluated to avoid distortion.  For a pure Gaussian, the max_beam_sigma
    //  at which the first unused scanline always has a weight < 1.0/255.0 is:
    //      num scanlines = 2, max_beam_sigma = 0.2089; distortions begin ~0.34
    //      num scanlines = 3, max_beam_sigma = 0.3879; distortions begin ~0.52
    //      num scanlines = 4, max_beam_sigma = 0.5723; distortions begin ~0.70
    //      num scanlines = 5, max_beam_sigma = 0.7591; distortions begin ~0.89
    //      num scanlines = 6, max_beam_sigma = 0.9483; distortions begin ~1.08
    //  Generalized Gaussians permit more leeway here as steepness increases.
    if(beam_spot_shape_function < 0.5)
    {
        //  Use a power function:
        return vec3(beam_min_sigma) + sigma_range *
            pow(color, vec3(beam_spot_power));
    }
    else
    {
        //  Use a spherical function:
        vec3 color_minus_1 = color - vec3(1.0);
        return vec3(beam_min_sigma) + sigma_range *
            sqrt(vec3(1.0) - color_minus_1*color_minus_1);
    }
}

vec3 get_generalized_gaussian_beta(vec3 color,
    float shape_range)
{
    //  Requires:   Globals:
    //              1.) beam_min_shape and beam_max_shape are global floats
    //                  containing the desired min/max generalized Gaussian
    //                  beta parameters, for dim and bright colors respectively.
    //              2.) beam_max_shape must be >= 2.0
    //              3.) beam_min_shape must be in [2.0, beam_max_shape]
    //              4.) beam_shape_power must be defined as a global float.
    //              Parameters:
    //              1.) color is the underlying source color along a scanline
    //              2.) shape_range = beam_max_shape - beam_min_shape; we take
    //                  shape_range as a parameter to avoid repeated computation
    //                  when beam_{min, max}_shape are runtime shader parameters
    //  Returns:    The type-I generalized Gaussian "shape" parameter beta for
    //              the given color.
    //  Details/Discussion:
    //  Beta affects the scanline distribution as follows:
    //  a.) beta < 2.0 narrows the peak to a spike with a discontinuous slope
    //  b.) beta == 2.0 just degenerates to a Gaussian
    //  c.) beta > 2.0 flattens and widens the peak, then drops off more steeply
    //      than a Gaussian.  Whereas high sigmas widen and soften peaks, high
    //      beta widen and sharpen peaks at the risk of aliasing.
    //  Unlike high beam_spot_powers, high beam_shape_powers actually soften shape
    //  transitions, whereas lower ones sharpen them (at the risk of aliasing).
    return beam_min_shape + shape_range * pow(color, vec3(beam_shape_power));
}

vec3 scanline_gaussian_integral_contrib(vec3 dist,
    vec3 color, float pixel_height, float sigma_range)
{
    //  Requires:   1.) dist is the distance of the [potentially separate R/G/B]
    //                  point(s) from a scanline in units of scanlines, where
    //                  1.0 means the sample point straddles the next scanline.
    //              2.) color is the underlying source color along a scanline.
    //              3.) pixel_height is the output pixel height in scanlines.
    //              4.) Requirements of get_gaussian_sigma() must be met.
    //  Returns:    Return a scanline's light output over a given pixel.
    //  Details:
    //  The CRT beam profile follows a roughly Gaussian distribution which is
    //  wider for bright colors than dark ones.  The integral over the full
    //  range of a Gaussian function is always 1.0, so we can vary the beam
    //  with a standard deviation without affecting brightness.  'x' = distance:
    //      gaussian sample = 1/(sigma*sqrt(2*pi)) * e**(-(x**2)/(2*sigma**2))
    //      gaussian integral = 0.5 (1.0 + erf(x/(sigma * sqrt(2))))
    //  Use a numerical approximation of the "error function" (the Gaussian
    //  indefinite integral) to find the definite integral of the scanline's
    //  average brightness over a given pixel area.  Even if curved coords were
    //  used in this pass, a flat scalar pixel height works almost as well as a
    //  pixel height computed from a full pixel-space to scanline-space matrix.
    vec3 sigma = get_gaussian_sigma(color, sigma_range);
    vec3 ph_offset = vec3(pixel_height * 0.5);
    vec3 denom_inv = 1.0/(sigma*sqrt(2.0));
    vec3 integral_high = erf((dist + ph_offset)*denom_inv);
    vec3 integral_low = erf((dist - ph_offset)*denom_inv);
    return color * 0.5*(integral_high - integral_low)/pixel_height;
}

vec3 scanline_generalized_gaussian_integral_contrib(vec3 dist,
    vec3 color, float pixel_height, float sigma_range,
    float shape_range)
{
    //  Requires:   1.) Requirements of scanline_gaussian_integral_contrib()
    //                  must be met.
    //              2.) Requirements of get_gaussian_sigma() must be met.
    //              3.) Requirements of get_generalized_gaussian_beta() must be
    //                  met.
    //  Returns:    Return a scanline's light output over a given pixel.
    //  A generalized Gaussian distribution allows the shape (beta) to vary
    //  as well as the width (alpha).  "gamma" refers to the gamma function:
    //      generalized sample =
    //          beta/(2*alpha*gamma(1/beta)) * e**(-(|x|/alpha)**beta)
    //  ligamma(s, z) is the lower incomplete gamma function, for which we only
    //  implement two of four branches (because we keep 1/beta <= 0.5):
    //      generalized integral = 0.5 + 0.5* sign(x) *
    //          ligamma(1/beta, (|x|/alpha)**beta)/gamma(1/beta)
    //  See get_generalized_gaussian_beta() for a discussion of beta.
    //  We base alpha on the intended Gaussian sigma, but it only strictly
    //  models models standard deviation at beta == 2, because the standard
    //  deviation depends on both alpha and beta (keeping alpha independent is
    //  faster and preserves intuitive behavior and a full spectrum of results).
    vec3 alpha = sqrt(2.0) * get_gaussian_sigma(color, sigma_range);
    vec3 beta = get_generalized_gaussian_beta(color, shape_range);
    vec3 alpha_inv = vec3(1.0)/alpha;
    vec3 s = vec3(1.0)/beta;
    vec3 ph_offset = vec3(pixel_height * 0.5);
    //  Pass beta to gamma_impl to avoid repeated divides.  Similarly pass
    //  beta (i.e. 1/s) and 1/gamma(s) to normalized_ligamma_impl.
    vec3 gamma_s_inv = vec3(1.0)/gamma_impl(s, beta);
    vec3 dist1 = dist + ph_offset;
    vec3 dist0 = dist - ph_offset;
    vec3 integral_high = sign(dist1) * normalized_ligamma_impl(
        s, pow(abs(dist1)*alpha_inv, beta), beta, gamma_s_inv);
    vec3 integral_low = sign(dist0) * normalized_ligamma_impl(
        s, pow(abs(dist0)*alpha_inv, beta), beta, gamma_s_inv);
    return color * 0.5*(integral_high - integral_low)/pixel_height;
}

vec3 scanline_gaussian_sampled_contrib(vec3 dist, vec3 color,
    float pixel_height, float sigma_range)
{
    //  See scanline_gaussian integral_contrib() for detailed comments!
    //  gaussian sample = 1/(sigma*sqrt(2*pi)) * e**(-(x**2)/(2*sigma**2))
    vec3 sigma = get_gaussian_sigma(color, sigma_range);
    //  Avoid repeated divides:
    vec3 sigma_inv = vec3(1.0)/sigma;
    vec3 inner_denom_inv = 0.5 * sigma_inv * sigma_inv;
    vec3 outer_denom_inv = sigma_inv/sqrt(2.0*pi);
    if(beam_antialias_level > 0.5)
    {
        //  Sample 1/3 pixel away in each direction as well:
        vec3 sample_offset = vec3(pixel_height/3.0);
        vec3 dist2 = dist + sample_offset;
        vec3 dist3 = abs(dist - sample_offset);
        //  Average three pure Gaussian samples:
        vec3 scale = color/3.0 * outer_denom_inv;
        vec3 weight1 = exp(-(dist*dist)*inner_denom_inv);
        vec3 weight2 = exp(-(dist2*dist2)*inner_denom_inv);
        vec3 weight3 = exp(-(dist3*dist3)*inner_denom_inv);
        return scale * (weight1 + weight2 + weight3);
    }
    else
    {
        return color*exp(-(dist*dist)*inner_denom_inv)*outer_denom_inv;
    }
}

vec3 scanline_generalized_gaussian_sampled_contrib(vec3 dist,
    vec3 color, float pixel_height, float sigma_range,
    float shape_range)
{
    //  See scanline_generalized_gaussian_integral_contrib() for details!
    //  generalized sample =
    //      beta/(2*alpha*gamma(1/beta)) * e**(-(|x|/alpha)**beta)
    vec3 alpha = sqrt(2.0) * get_gaussian_sigma(color, sigma_range);
    vec3 beta = get_generalized_gaussian_beta(color, shape_range);
    //  Avoid repeated divides:
    vec3 alpha_inv = vec3(1.0)/alpha;
    vec3 beta_inv = vec3(1.0)/beta;
    vec3 scale = color * beta * 0.5 * alpha_inv /
        gamma_impl(beta_inv, beta);
    if(beam_antialias_level > 0.5)
    {
        //  Sample 1/3 pixel closer to and farther from the scanline too.
        vec3 sample_offset = vec3(pixel_height/3.0);
        vec3 dist2 = dist + sample_offset;
        vec3 dist3 = abs(dist - sample_offset);
        //  Average three generalized Gaussian samples:
        vec3 weight1 = exp(-pow(abs(dist*alpha_inv), beta));
        vec3 weight2 = exp(-pow(abs(dist2*alpha_inv), beta));
        vec3 weight3 = exp(-pow(abs(dist3*alpha_inv), beta));
        return scale/3.0 * (weight1 + weight2 + weight3);
    }
    else
    {
        return scale * exp(-pow(abs(dist*alpha_inv), beta));
    }
}

vec3 scanline_contrib(vec3 dist, vec3 color,
    float pixel_height, float sigma_range, float shape_range)
{
    //  Requires:   1.) Requirements of scanline_gaussian_integral_contrib()
    //                  must be met.
    //              2.) Requirements of get_gaussian_sigma() must be met.
    //              3.) Requirements of get_generalized_gaussian_beta() must be
    //                  met.
    //  Returns:    Return a scanline's light output over a given pixel, using
    //              a generalized or pure Gaussian distribution and sampling or
    //              integrals as desired by user codepath choices.
    if(beam_generalized_gaussian == true)
    {
        if(beam_antialias_level > 1.5)
        {
            return scanline_generalized_gaussian_integral_contrib(
                dist, color, pixel_height, sigma_range, shape_range);
        }
        else
        {
            return scanline_generalized_gaussian_sampled_contrib(
                dist, color, pixel_height, sigma_range, shape_range);
        }
    }
    else
    {
        if(beam_antialias_level > 1.5)
        {
            return scanline_gaussian_integral_contrib(
                dist, color, pixel_height, sigma_range);
        }
        else
        {
            return scanline_gaussian_sampled_contrib(
                dist, color, pixel_height, sigma_range);
        }
    }
}

#endif  //  SCANLINE_FUNCTIONS_H
////////////   END #include scanline-functions.h     //////////////////

/////////////   BEGIN #include blur-functions.h     ///////////////////
#ifndef BLUR_FUNCTIONS_H
#define BLUR_FUNCTIONS_H

/////////////////////////////////  MIT LICENSE  ////////////////////////////////

//  Copyright (C) 2014 TroggleMonkey
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

/////////////////////////////////  DESCRIPTION  ////////////////////////////////

//  This file provides reusable one-pass and separable (two-pass) blurs.
//  Requires:   All blurs share these requirements (dxdy requirement is split):
//              1.) All requirements of gamma-management.h must be satisfied!
//              2.) filter_linearN must == "true" in your .cgp preset unless
//                  you're using tex2DblurNresize at 1x scale.
//              3.) mipmap_inputN must == "true" in your .cgp preset if
//                  IN.output_size < IN.video_size.
//              4.) IN.output_size == IN.video_size / pow(2, M), where M is some
//                  positive integer.  tex2Dblur*resize can resize arbitrarily
//                  (and the blur will be done after resizing), but arbitrary
//                  resizes "fail" with other blurs due to the way they mix
//                  static weights with bilinear sample exploitation.
//              5.) In general, dxdy should contain the uv pixel spacing:
//                      dxdy = (IN.video_size/IN.output_size)/IN.texture_size
//              6.) For separable blurs (tex2DblurNresize and tex2DblurNfast),
//                  zero out the dxdy component in the unblurred dimension:
//                      dxdy = vec2(dxdy.x, 0.0) or vec2(0.0, dxdy.y)
//              Many blurs share these requirements:
//              1.) One-pass blurs require scale_xN == scale_yN or scales > 1.0,
//                  or they will blur more in the lower-scaled dimension.
//              2.) One-pass shared sample blurs require ddx(), ddy(), and
//                  tex2Dlod() to be supported by the current Cg profile, and
//                  the drivers must support high-quality derivatives.
//              3.) One-pass shared sample blurs require:
//                      tex_uv.w == log2(IN.video_size/IN.output_size).y;
//              Non-wrapper blurs share this requirement:
//              1.) sigma is the intended standard deviation of the blur
//              Wrapper blurs share this requirement, which is automatically
//              met (unless OVERRIDE_BLUR_STD_DEVS is #defined; see below):
//              1.) blurN_std_dev must be global static float values
//                  specifying standard deviations for Nx blurs in units
//                  of destination pixels
//  Optional:   1.) The including file (or an earlier included file) may
//                  optionally #define USE_BINOMIAL_BLUR_STD_DEVS to replace
//                  default standard deviations with those matching a binomial
//                  distribution.  (See below for details/properties.)
//              2.) The including file (or an earlier included file) may
//                  optionally #define OVERRIDE_BLUR_STD_DEVS and override:
//                      static float blur3_std_dev
//                      static float blur4_std_dev
//                      static float blur5_std_dev
//                      static float blur6_std_dev
//                      static float blur7_std_dev
//                      static float blur8_std_dev
//                      static float blur9_std_dev
//                      static float blur10_std_dev
//                      static float blur11_std_dev
//                      static float blur12_std_dev
//                      static float blur17_std_dev
//                      static float blur25_std_dev
//                      static float blur31_std_dev
//                      static float blur43_std_dev
//              3.) The including file (or an earlier included file) may
//                  optionally #define OVERRIDE_ERROR_BLURRING and override:
//                      static float error_blurring
//                  This tuning value helps mitigate weighting errors from one-
//                  pass shared-sample blurs sharing bilinear samples between
//                  fragments.  Values closer to 0.0 have "correct" blurriness
//                  but allow more artifacts, and values closer to 1.0 blur away
//                  artifacts by sampling closer to halfway between texels.
//              UPDATE 6/21/14: The above static constants may now be overridden
//              by non-static uniform constants.  This permits exposing blur
//              standard deviations as runtime GUI shader parameters.  However,
//              using them keeps weights from being statically computed, and the
//              speed hit depends on the blur: On my machine, uniforms kill over
//              53% of the framerate with tex2Dblur12x12shared, but they only
//              drop the framerate by about 18% with tex2Dblur11fast.
//  Quality and Performance Comparisons:
//  For the purposes of the following discussion, "no sRGB" means
//  GAMMA_ENCODE_EVERY_FBO is #defined, and "sRGB" means it isn't.
//  1.) tex2DblurNfast is always faster than tex2DblurNresize.
//  2.) tex2DblurNresize functions are the only ones that can arbitrarily resize
//      well, because they're the only ones that don't exploit bilinear samples.
//      This also means they're the only functions which can be truly gamma-
//      correct without linear (or sRGB FBO) input, but only at 1x scale.
//  3.) One-pass shared sample blurs only have a speed advantage without sRGB.
//      They also have some inaccuracies due to their shared-[bilinear-]sample
//      design, which grow increasingly bothersome for smaller blurs and higher-
//      frequency source images (relative to their resolution).  I had high
//      hopes for them, but their most realistic use case is limited to quickly
//      reblurring an already blurred input at full resolution.  Otherwise:
//      a.) If you're blurring a low-resolution source, you want a better blur.
//      b.) If you're blurring a lower mipmap, you want a better blur.
//      c.) If you're blurring a high-resolution, high-frequency source, you
//          want a better blur.
//  4.) The one-pass blurs without shared samples grow slower for larger blurs,
//      but they're competitive with separable blurs at 5x5 and smaller, and
//      even tex2Dblur7x7 isn't bad if you're wanting to conserve passes.
//  Here are some framerates from a GeForce 8800GTS.  The first pass resizes to
//  viewport size (4x in this test) and linearizes for sRGB codepaths, and the
//  remaining passes perform 6 full blurs.  Mipmapped tests are performed at the
//  same scale, so they just measure the cost of mipmapping each FBO (only every
//  other FBO is mipmapped for separable blurs, to mimic realistic usage).
//  Mipmap      Neither     sRGB+Mipmap sRGB        Function
//  76.0        92.3        131.3       193.7       tex2Dblur3fast
//  63.2        74.4        122.4       175.5       tex2Dblur3resize
//  93.7        121.2       159.3       263.2       tex2Dblur3x3
//  59.7        68.7        115.4       162.1       tex2Dblur3x3resize
//  63.2        74.4        122.4       175.5       tex2Dblur5fast
//  49.3        54.8        100.0       132.7       tex2Dblur5resize
//  59.7        68.7        115.4       162.1       tex2Dblur5x5
//  64.9        77.2        99.1        137.2       tex2Dblur6x6shared
//  55.8        63.7        110.4       151.8       tex2Dblur7fast
//  39.8        43.9        83.9        105.8       tex2Dblur7resize
//  40.0        44.2        83.2        104.9       tex2Dblur7x7
//  56.4        65.5        71.9        87.9        tex2Dblur8x8shared
//  49.3        55.1        99.9        132.5       tex2Dblur9fast
//  33.3        36.2        72.4        88.0        tex2Dblur9resize
//  27.8        29.7        61.3        72.2        tex2Dblur9x9
//  37.2        41.1        52.6        60.2        tex2Dblur10x10shared
//  44.4        49.5        91.3        117.8       tex2Dblur11fast
//  28.8        30.8        63.6        75.4        tex2Dblur11resize
//  33.6        36.5        40.9        45.5        tex2Dblur12x12shared
//  TODO: Fill in benchmarks for new untested blurs.
//                                                  tex2Dblur17fast
//                                                  tex2Dblur25fast
//                                                  tex2Dblur31fast
//                                                  tex2Dblur43fast
//                                                  tex2Dblur3x3resize

/////////////////////////////  SETTINGS MANAGEMENT  ////////////////////////////

//  Set static standard deviations, but allow users to override them with their
//  own constants (even non-static uniforms if they're okay with the speed hit):
#ifndef OVERRIDE_BLUR_STD_DEVS
    //  blurN_std_dev values are specified in terms of dxdy strides.
    #ifdef USE_BINOMIAL_BLUR_STD_DEVS
        //  By request, we can define standard deviations corresponding to a
        //  binomial distribution with p = 0.5 (related to Pascal's triangle).
        //  This distribution works such that blurring multiple times should
        //  have the same result as a single larger blur.  These values are
        //  larger than default for blurs up to 6x and smaller thereafter.
        float blur3_std_dev = 0.84931640625;
        float blur4_std_dev = 0.84931640625;
        float blur5_std_dev = 1.0595703125;
        float blur6_std_dev = 1.06591796875;
        float blur7_std_dev = 1.17041015625;
        float blur8_std_dev = 1.1720703125;
        float blur9_std_dev = 1.2259765625;
        float blur10_std_dev = 1.21982421875;
        float blur11_std_dev = 1.25361328125;
        float blur12_std_dev = 1.2423828125;
        float blur17_std_dev = 1.27783203125;
        float blur25_std_dev = 1.2810546875;
        float blur31_std_dev = 1.28125;
        float blur43_std_dev = 1.28125;
    #else
        //  The defaults are the largest values that keep the largest unused
        //  blur term on each side <= 1.0/256.0.  (We could get away with more
        //  or be more conservative, but this compromise is pretty reasonable.)
        float blur3_std_dev = 0.62666015625;
        float blur4_std_dev = 0.66171875;
        float blur5_std_dev = 0.9845703125;
        float blur6_std_dev = 1.02626953125;
        float blur7_std_dev = 1.36103515625;
        float blur8_std_dev = 1.4080078125;
        float blur9_std_dev = 1.7533203125;
        float blur10_std_dev = 1.80478515625;
        float blur11_std_dev = 2.15986328125;
        float blur12_std_dev = 2.215234375;
        float blur17_std_dev = 3.45535583496;
        float blur25_std_dev = 5.3409576416;
        float blur31_std_dev = 6.86488037109;
        float blur43_std_dev = 10.1852050781;
    #endif  //  USE_BINOMIAL_BLUR_STD_DEVS
#endif  //  OVERRIDE_BLUR_STD_DEVS

#ifndef OVERRIDE_ERROR_BLURRING
    //  error_blurring should be in [0.0, 1.0].  Higher values reduce ringing
    //  in shared-sample blurs but increase blurring and feature shifting.
    float error_blurring = 0.5;
#endif

//  Make a length squared helper macro (for usage with static constants):
#define LENGTH_SQ(vec) (dot(vec, vec))

//////////////////////////////////  INCLUDES  //////////////////////////////////

//  gamma-management.h relies on pass-specific settings to guide its behavior:
//  FIRST_PASS, LAST_PASS, GAMMA_ENCODE_EVERY_FBO, etc.  See it for details.
//#include "gamma-management.h"
//#include "quad-pixel-communication.h"
//#include "special-functions.h"

///////////////////////////////////  HELPERS  //////////////////////////////////

vec4 uv2_to_uv4(vec2 tex_uv)
{
    //  Make a vec2 uv offset safe for adding to vec4 tex2Dlod coords:
    return vec4(tex_uv, 0.0, 0.0);
}

//  Make a length squared helper macro (for usage with static constants):
#define LENGTH_SQ(vec) (dot(vec, vec))

float get_fast_gaussian_weight_sum_inv(float sigma)
{
    //  We can use the Gaussian integral to calculate the asymptotic weight for
    //  the center pixel.  Since the unnormalized center pixel weight is 1.0,
    //  the normalized weight is the same as the weight sum inverse.  Given a
    //  large enough blur (9+), the asymptotic weight sum is close and faster:
    //      center_weight = 0.5 *
    //          (erf(0.5/(sigma*sqrt(2.0))) - erf(-0.5/(sigma*sqrt(2.0))))
    //      erf(-x) == -erf(x), so we get 0.5 * (2.0 * erf(blah blah)):
    //  However, we can get even faster results with curve-fitting.  These are
    //  also closer than the asymptotic results, because they were constructed
    //  from 64 blurs sizes from [3, 131) and 255 equally-spaced sigmas from
    //  (0, blurN_std_dev), so the results for smaller sigmas are biased toward
    //  smaller blurs.  The max error is 0.0031793913.
    //  Relative FPS: 134.3 with erf, 135.8 with curve-fitting.
    //static float temp = 0.5/sqrt(2.0);
    //return erf(temp/sigma);
    return min(exp(exp(0.348348412457428/
        (sigma - 0.0860587260734721))), 0.399334576340352/sigma);
}

////////////////////  ARBITRARILY RESIZABLE SEPARABLE BLURS  ///////////////////

vec3 tex2Dblur11resize(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Global requirements must be met (see file description).
    //  Returns:    A 1D 11x Gaussian blurred texture lookup using a 11-tap blur.
    //              It may be mipmapped depending on settings and dxdy.
    //  Calculate Gaussian blur kernel weights and a normalization factor for
    //  distances of 0-4, ignoring constant factors (since we're normalizing).
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float w5 = exp(-25.0 * denom_inv);
    float weight_sum_inv = 1.0 /
        (w0 + 2.0 * (w1 + w2 + w3 + w4 + w5));
    //  Statically normalize weights, sum weighted samples, and return.  Blurs are
    //  currently optimized for dynamic weights.
    vec3 sum = vec3(0.0);
    sum += w5 * tex2D_linearize(tex, tex_uv - 5.0 * dxdy).rgb;
    sum += w4 * tex2D_linearize(tex, tex_uv - 4.0 * dxdy).rgb;
    sum += w3 * tex2D_linearize(tex, tex_uv - 3.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv - 2.0 * dxdy).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv - 1.0 * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv + 1.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv + 2.0 * dxdy).rgb;
    sum += w3 * tex2D_linearize(tex, tex_uv + 3.0 * dxdy).rgb;
    sum += w4 * tex2D_linearize(tex, tex_uv + 4.0 * dxdy).rgb;
    sum += w5 * tex2D_linearize(tex, tex_uv + 5.0 * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur9resize(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Global requirements must be met (see file description).
    //  Returns:    A 1D 9x Gaussian blurred texture lookup using a 9-tap blur.
    //              It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2 + w3 + w4));
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w4 * tex2D_linearize(tex, tex_uv - 4.0 * dxdy).rgb;
    sum += w3 * tex2D_linearize(tex, tex_uv - 3.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv - 2.0 * dxdy).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv - 1.0 * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv + 1.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv + 2.0 * dxdy).rgb;
    sum += w3 * tex2D_linearize(tex, tex_uv + 3.0 * dxdy).rgb;
    sum += w4 * tex2D_linearize(tex, tex_uv + 4.0 * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur7resize(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Global requirements must be met (see file description).
    //  Returns:    A 1D 7x Gaussian blurred texture lookup using a 7-tap blur.
    //              It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2 + w3));
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w3 * tex2D_linearize(tex, tex_uv - 3.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv - 2.0 * dxdy).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv - 1.0 * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv + 1.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv + 2.0 * dxdy).rgb;
    sum += w3 * tex2D_linearize(tex, tex_uv + 3.0 * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur5resize(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Global requirements must be met (see file description).
    //  Returns:    A 1D 5x Gaussian blurred texture lookup using a 5-tap blur.
    //              It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2));
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w2 * tex2D_linearize(tex, tex_uv - 2.0 * dxdy).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv - 1.0 * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv + 1.0 * dxdy).rgb;
    sum += w2 * tex2D_linearize(tex, tex_uv + 2.0 * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur3resize(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Global requirements must be met (see file description).
    //  Returns:    A 1D 3x Gaussian blurred texture lookup using a 3-tap blur.
    //              It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * w1);
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w1 * tex2D_linearize(tex, tex_uv - 1.0 * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1 * tex2D_linearize(tex, tex_uv + 1.0 * dxdy).rgb;
    return sum * weight_sum_inv;
}

///////////////////////////  FAST SEPARABLE BLURS  ///////////////////////////

vec3 tex2Dblur11fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   1.) Global requirements must be met (see file description).
    //              2.) filter_linearN must = "true" in your .cgp file.
    //              3.) For gamma-correct bilinear filtering, global
    //                  gamma_aware_bilinear == true (from gamma-management.h)
    //  Returns:    A 1D 11x Gaussian blurred texture lookup using 6 linear
    //              taps.  It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float w5 = exp(-25.0 * denom_inv);
    float weight_sum_inv = 1.0 /
        (w0 + 2.0 * (w1 + w2 + w3 + w4 + w5));
    //  Calculate combined weights and linear sample ratios between texel pairs.
    //  The center texel (with weight w0) is used twice, so halve its weight.
    float w01 = w0 * 0.5 + w1;
    float w23 = w2 + w3;
    float w45 = w4 + w5;
    float w01_ratio = w1/w01;
    float w23_ratio = w3/w23;
    float w45_ratio = w5/w45;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w45 * tex2D_linearize(tex, tex_uv - (4.0 + w45_ratio) * dxdy).rgb;
    sum += w23 * tex2D_linearize(tex, tex_uv - (2.0 + w23_ratio) * dxdy).rgb;
    sum += w01 * tex2D_linearize(tex, tex_uv - w01_ratio * dxdy).rgb;
    sum += w01 * tex2D_linearize(tex, tex_uv + w01_ratio * dxdy).rgb;
    sum += w23 * tex2D_linearize(tex, tex_uv + (2.0 + w23_ratio) * dxdy).rgb;
    sum += w45 * tex2D_linearize(tex, tex_uv + (4.0 + w45_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur17fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 17x Gaussian blurred texture lookup using 1 nearest
    //              neighbor and 8 linear taps.  It may be mipmapped depending
    //              on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float w5 = exp(-25.0 * denom_inv);
    float w6 = exp(-36.0 * denom_inv);
    float w7 = exp(-49.0 * denom_inv);
    float w8 = exp(-64.0 * denom_inv);
    //float weight_sum_inv = 1.0 / (w0 + 2.0 * (
    //    w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8));
    float weight_sum_inv = get_fast_gaussian_weight_sum_inv(sigma);
    //  Calculate combined weights and linear sample ratios between texel pairs.
    float w1_2 = w1 + w2;
    float w3_4 = w3 + w4;
    float w5_6 = w5 + w6;
    float w7_8 = w7 + w8;
    float w1_2_ratio = w2/w1_2;
    float w3_4_ratio = w4/w3_4;
    float w5_6_ratio = w6/w5_6;
    float w7_8_ratio = w8/w7_8;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w7_8 * tex2D_linearize(tex, tex_uv - (7.0 + w7_8_ratio) * dxdy).rgb;
    sum += w5_6 * tex2D_linearize(tex, tex_uv - (5.0 + w5_6_ratio) * dxdy).rgb;
    sum += w3_4 * tex2D_linearize(tex, tex_uv - (3.0 + w3_4_ratio) * dxdy).rgb;
    sum += w1_2 * tex2D_linearize(tex, tex_uv - (1.0 + w1_2_ratio) * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1_2 * tex2D_linearize(tex, tex_uv + (1.0 + w1_2_ratio) * dxdy).rgb;
    sum += w3_4 * tex2D_linearize(tex, tex_uv + (3.0 + w3_4_ratio) * dxdy).rgb;
    sum += w5_6 * tex2D_linearize(tex, tex_uv + (5.0 + w5_6_ratio) * dxdy).rgb;
    sum += w7_8 * tex2D_linearize(tex, tex_uv + (7.0 + w7_8_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur25fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 25x Gaussian blurred texture lookup using 1 nearest
    //              neighbor and 12 linear taps.  It may be mipmapped depending
    //              on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float w5 = exp(-25.0 * denom_inv);
    float w6 = exp(-36.0 * denom_inv);
    float w7 = exp(-49.0 * denom_inv);
    float w8 = exp(-64.0 * denom_inv);
    float w9 = exp(-81.0 * denom_inv);
    float w10 = exp(-100.0 * denom_inv);
    float w11 = exp(-121.0 * denom_inv);
    float w12 = exp(-144.0 * denom_inv);
    //float weight_sum_inv = 1.0 / (w0 + 2.0 * (
    //    w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 + w12));
    float weight_sum_inv = get_fast_gaussian_weight_sum_inv(sigma);
    //  Calculate combined weights and linear sample ratios between texel pairs.
    float w1_2 = w1 + w2;
    float w3_4 = w3 + w4;
    float w5_6 = w5 + w6;
    float w7_8 = w7 + w8;
    float w9_10 = w9 + w10;
    float w11_12 = w11 + w12;
    float w1_2_ratio = w2/w1_2;
    float w3_4_ratio = w4/w3_4;
    float w5_6_ratio = w6/w5_6;
    float w7_8_ratio = w8/w7_8;
    float w9_10_ratio = w10/w9_10;
    float w11_12_ratio = w12/w11_12;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w11_12 * tex2D_linearize(tex, tex_uv - (11.0 + w11_12_ratio) * dxdy).rgb;
    sum += w9_10 * tex2D_linearize(tex, tex_uv - (9.0 + w9_10_ratio) * dxdy).rgb;
    sum += w7_8 * tex2D_linearize(tex, tex_uv - (7.0 + w7_8_ratio) * dxdy).rgb;
    sum += w5_6 * tex2D_linearize(tex, tex_uv - (5.0 + w5_6_ratio) * dxdy).rgb;
    sum += w3_4 * tex2D_linearize(tex, tex_uv - (3.0 + w3_4_ratio) * dxdy).rgb;
    sum += w1_2 * tex2D_linearize(tex, tex_uv - (1.0 + w1_2_ratio) * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w1_2 * tex2D_linearize(tex, tex_uv + (1.0 + w1_2_ratio) * dxdy).rgb;
    sum += w3_4 * tex2D_linearize(tex, tex_uv + (3.0 + w3_4_ratio) * dxdy).rgb;
    sum += w5_6 * tex2D_linearize(tex, tex_uv + (5.0 + w5_6_ratio) * dxdy).rgb;
    sum += w7_8 * tex2D_linearize(tex, tex_uv + (7.0 + w7_8_ratio) * dxdy).rgb;
    sum += w9_10 * tex2D_linearize(tex, tex_uv + (9.0 + w9_10_ratio) * dxdy).rgb;
    sum += w11_12 * tex2D_linearize(tex, tex_uv + (11.0 + w11_12_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur31fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 31x Gaussian blurred texture lookup using 16 linear
    //              taps.  It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float w5 = exp(-25.0 * denom_inv);
    float w6 = exp(-36.0 * denom_inv);
    float w7 = exp(-49.0 * denom_inv);
    float w8 = exp(-64.0 * denom_inv);
    float w9 = exp(-81.0 * denom_inv);
    float w10 = exp(-100.0 * denom_inv);
    float w11 = exp(-121.0 * denom_inv);
    float w12 = exp(-144.0 * denom_inv);
    float w13 = exp(-169.0 * denom_inv);
    float w14 = exp(-196.0 * denom_inv);
    float w15 = exp(-225.0 * denom_inv);
    //float weight_sum_inv = 1.0 /
    //    (w0 + 2.0 * (w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 +
    //        w9 + w10 + w11 + w12 + w13 + w14 + w15));
    float weight_sum_inv = get_fast_gaussian_weight_sum_inv(sigma);
    //  Calculate combined weights and linear sample ratios between texel pairs.
    //  The center texel (with weight w0) is used twice, so halve its weight.
    float w0_1 = w0 * 0.5 + w1;
    float w2_3 = w2 + w3;
    float w4_5 = w4 + w5;
    float w6_7 = w6 + w7;
    float w8_9 = w8 + w9;
    float w10_11 = w10 + w11;
    float w12_13 = w12 + w13;
    float w14_15 = w14 + w15;
    float w0_1_ratio = w1/w0_1;
    float w2_3_ratio = w3/w2_3;
    float w4_5_ratio = w5/w4_5;
    float w6_7_ratio = w7/w6_7;
    float w8_9_ratio = w9/w8_9;
    float w10_11_ratio = w11/w10_11;
    float w12_13_ratio = w13/w12_13;
    float w14_15_ratio = w15/w14_15;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w14_15 * tex2D_linearize(tex, tex_uv - (14.0 + w14_15_ratio) * dxdy).rgb;
    sum += w12_13 * tex2D_linearize(tex, tex_uv - (12.0 + w12_13_ratio) * dxdy).rgb;
    sum += w10_11 * tex2D_linearize(tex, tex_uv - (10.0 + w10_11_ratio) * dxdy).rgb;
    sum += w8_9 * tex2D_linearize(tex, tex_uv - (8.0 + w8_9_ratio) * dxdy).rgb;
    sum += w6_7 * tex2D_linearize(tex, tex_uv - (6.0 + w6_7_ratio) * dxdy).rgb;
    sum += w4_5 * tex2D_linearize(tex, tex_uv - (4.0 + w4_5_ratio) * dxdy).rgb;
    sum += w2_3 * tex2D_linearize(tex, tex_uv - (2.0 + w2_3_ratio) * dxdy).rgb;
    sum += w0_1 * tex2D_linearize(tex, tex_uv - w0_1_ratio * dxdy).rgb;
    sum += w0_1 * tex2D_linearize(tex, tex_uv + w0_1_ratio * dxdy).rgb;
    sum += w2_3 * tex2D_linearize(tex, tex_uv + (2.0 + w2_3_ratio) * dxdy).rgb;
    sum += w4_5 * tex2D_linearize(tex, tex_uv + (4.0 + w4_5_ratio) * dxdy).rgb;
    sum += w6_7 * tex2D_linearize(tex, tex_uv + (6.0 + w6_7_ratio) * dxdy).rgb;
    sum += w8_9 * tex2D_linearize(tex, tex_uv + (8.0 + w8_9_ratio) * dxdy).rgb;
    sum += w10_11 * tex2D_linearize(tex, tex_uv + (10.0 + w10_11_ratio) * dxdy).rgb;
    sum += w12_13 * tex2D_linearize(tex, tex_uv + (12.0 + w12_13_ratio) * dxdy).rgb;
    sum += w14_15 * tex2D_linearize(tex, tex_uv + (14.0 + w14_15_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur43fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 43x Gaussian blurred texture lookup using 22 linear
    //              taps.  It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float w5 = exp(-25.0 * denom_inv);
    float w6 = exp(-36.0 * denom_inv);
    float w7 = exp(-49.0 * denom_inv);
    float w8 = exp(-64.0 * denom_inv);
    float w9 = exp(-81.0 * denom_inv);
    float w10 = exp(-100.0 * denom_inv);
    float w11 = exp(-121.0 * denom_inv);
    float w12 = exp(-144.0 * denom_inv);
    float w13 = exp(-169.0 * denom_inv);
    float w14 = exp(-196.0 * denom_inv);
    float w15 = exp(-225.0 * denom_inv);
    float w16 = exp(-256.0 * denom_inv);
    float w17 = exp(-289.0 * denom_inv);
    float w18 = exp(-324.0 * denom_inv);
    float w19 = exp(-361.0 * denom_inv);
    float w20 = exp(-400.0 * denom_inv);
    float w21 = exp(-441.0 * denom_inv);
    //float weight_sum_inv = 1.0 /
    //    (w0 + 2.0 * (w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 +
    //        w12 + w13 + w14 + w15 + w16 + w17 + w18 + w19 + w20 + w21));
    float weight_sum_inv = get_fast_gaussian_weight_sum_inv(sigma);
    //  Calculate combined weights and linear sample ratios between texel pairs.
    //  The center texel (with weight w0) is used twice, so halve its weight.
    float w0_1 = w0 * 0.5 + w1;
    float w2_3 = w2 + w3;
    float w4_5 = w4 + w5;
    float w6_7 = w6 + w7;
    float w8_9 = w8 + w9;
    float w10_11 = w10 + w11;
    float w12_13 = w12 + w13;
    float w14_15 = w14 + w15;
    float w16_17 = w16 + w17;
    float w18_19 = w18 + w19;
    float w20_21 = w20 + w21;
    float w0_1_ratio = w1/w0_1;
    float w2_3_ratio = w3/w2_3;
    float w4_5_ratio = w5/w4_5;
    float w6_7_ratio = w7/w6_7;
    float w8_9_ratio = w9/w8_9;
    float w10_11_ratio = w11/w10_11;
    float w12_13_ratio = w13/w12_13;
    float w14_15_ratio = w15/w14_15;
    float w16_17_ratio = w17/w16_17;
    float w18_19_ratio = w19/w18_19;
    float w20_21_ratio = w21/w20_21;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w20_21 * tex2D_linearize(tex, tex_uv - (20.0 + w20_21_ratio) * dxdy).rgb;
    sum += w18_19 * tex2D_linearize(tex, tex_uv - (18.0 + w18_19_ratio) * dxdy).rgb;
    sum += w16_17 * tex2D_linearize(tex, tex_uv - (16.0 + w16_17_ratio) * dxdy).rgb;
    sum += w14_15 * tex2D_linearize(tex, tex_uv - (14.0 + w14_15_ratio) * dxdy).rgb;
    sum += w12_13 * tex2D_linearize(tex, tex_uv - (12.0 + w12_13_ratio) * dxdy).rgb;
    sum += w10_11 * tex2D_linearize(tex, tex_uv - (10.0 + w10_11_ratio) * dxdy).rgb;
    sum += w8_9 * tex2D_linearize(tex, tex_uv - (8.0 + w8_9_ratio) * dxdy).rgb;
    sum += w6_7 * tex2D_linearize(tex, tex_uv - (6.0 + w6_7_ratio) * dxdy).rgb;
    sum += w4_5 * tex2D_linearize(tex, tex_uv - (4.0 + w4_5_ratio) * dxdy).rgb;
    sum += w2_3 * tex2D_linearize(tex, tex_uv - (2.0 + w2_3_ratio) * dxdy).rgb;
    sum += w0_1 * tex2D_linearize(tex, tex_uv - w0_1_ratio * dxdy).rgb;
    sum += w0_1 * tex2D_linearize(tex, tex_uv + w0_1_ratio * dxdy).rgb;
    sum += w2_3 * tex2D_linearize(tex, tex_uv + (2.0 + w2_3_ratio) * dxdy).rgb;
    sum += w4_5 * tex2D_linearize(tex, tex_uv + (4.0 + w4_5_ratio) * dxdy).rgb;
    sum += w6_7 * tex2D_linearize(tex, tex_uv + (6.0 + w6_7_ratio) * dxdy).rgb;
    sum += w8_9 * tex2D_linearize(tex, tex_uv + (8.0 + w8_9_ratio) * dxdy).rgb;
    sum += w10_11 * tex2D_linearize(tex, tex_uv + (10.0 + w10_11_ratio) * dxdy).rgb;
    sum += w12_13 * tex2D_linearize(tex, tex_uv + (12.0 + w12_13_ratio) * dxdy).rgb;
    sum += w14_15 * tex2D_linearize(tex, tex_uv + (14.0 + w14_15_ratio) * dxdy).rgb;
    sum += w16_17 * tex2D_linearize(tex, tex_uv + (16.0 + w16_17_ratio) * dxdy).rgb;
    sum += w18_19 * tex2D_linearize(tex, tex_uv + (18.0 + w18_19_ratio) * dxdy).rgb;
    sum += w20_21 * tex2D_linearize(tex, tex_uv + (20.0 + w20_21_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur3fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 3x Gaussian blurred texture lookup using 2 linear
    //              taps.  It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * w1);
    //  Calculate combined weights and linear sample ratios between texel pairs.
    //  The center texel (with weight w0) is used twice, so halve its weight.
    float w01 = w0 * 0.5 + w1;
    float w01_ratio = w1/w01;
    //  Weights for all samples are the same, so just average them:
    return 0.5 * (
        tex2D_linearize(tex, tex_uv - w01_ratio * dxdy).rgb +
        tex2D_linearize(tex, tex_uv + w01_ratio * dxdy).rgb);
}

vec3 tex2Dblur5fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 5x Gaussian blurred texture lookup using 1 nearest
    //              neighbor and 2 linear taps.  It may be mipmapped depending
    //              on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2));
    //  Calculate combined weights and linear sample ratios between texel pairs.
    float w12 = w1 + w2;
    float w12_ratio = w2/w12;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w12 * tex2D_linearize(tex, tex_uv - (1.0 + w12_ratio) * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w12 * tex2D_linearize(tex, tex_uv + (1.0 + w12_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur7fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 7x Gaussian blurred texture lookup using 4 linear
    //              taps.  It may be mipmapped depending on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2 + w3));
    //  Calculate combined weights and linear sample ratios between texel pairs.
    //  The center texel (with weight w0) is used twice, so halve its weight.
    float w01 = w0 * 0.5 + w1;
    float w23 = w2 + w3;
    float w01_ratio = w1/w01;
    float w23_ratio = w3/w23;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w23 * tex2D_linearize(tex, tex_uv - (2.0 + w23_ratio) * dxdy).rgb;
    sum += w01 * tex2D_linearize(tex, tex_uv - w01_ratio * dxdy).rgb;
    sum += w01 * tex2D_linearize(tex, tex_uv + w01_ratio * dxdy).rgb;
    sum += w23 * tex2D_linearize(tex, tex_uv + (2.0 + w23_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

////////////////////  ARBITRARILY RESIZABLE ONE-PASS BLURS  ////////////////////

vec3 tex2Dblur3x3resize(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Global requirements must be met (see file description).
    //  Returns:    A 3x3 Gaussian blurred mipmapped texture lookup of the
    //              resized input.
    //  Description:
    //  This is the only arbitrarily resizable one-pass blur; tex2Dblur5x5resize
    //  would perform like tex2Dblur9x9, MUCH slower than tex2Dblur5resize.
    float denom_inv = 0.5/(sigma*sigma);
    //  Load each sample.  We need all 3x3 samples.  Quad-pixel communication
    //  won't help either: This should perform like tex2Dblur5x5, but sharing a
    //  4x4 sample field would perform more like tex2Dblur8x8shared (worse).
    vec2 sample4_uv = tex_uv;
    vec2 dx = vec2(dxdy.x, 0.0);
    vec2 dy = vec2(0.0, dxdy.y);
    vec2 sample1_uv = sample4_uv - dy;
    vec2 sample7_uv = sample4_uv + dy;
    vec3 sample0 = tex2D_linearize(tex, sample1_uv - dx).rgb;
    vec3 sample1 = tex2D_linearize(tex, sample1_uv).rgb;
    vec3 sample2 = tex2D_linearize(tex, sample1_uv + dx).rgb;
    vec3 sample3 = tex2D_linearize(tex, sample4_uv - dx).rgb;
    vec3 sample4 = tex2D_linearize(tex, sample4_uv).rgb;
    vec3 sample5 = tex2D_linearize(tex, sample4_uv + dx).rgb;
    vec3 sample6 = tex2D_linearize(tex, sample7_uv - dx).rgb;
    vec3 sample7 = tex2D_linearize(tex, sample7_uv).rgb;
    vec3 sample8 = tex2D_linearize(tex, sample7_uv + dx).rgb;
    //  Statically compute Gaussian sample weights:
    float w4 = 1.0;
    float w1_3_5_7 = exp(-LENGTH_SQ(vec2(1.0, 0.0)) * denom_inv);
    float w0_2_6_8 = exp(-LENGTH_SQ(vec2(1.0, 1.0)) * denom_inv);
    float weight_sum_inv = 1.0/(w4 + 4.0 * (w1_3_5_7 + w0_2_6_8));
    //  Weight and sum the samples:
    vec3 sum = w4 * sample4 +
        w1_3_5_7 * (sample1 + sample3 + sample5 + sample7) +
        w0_2_6_8 * (sample0 + sample2 + sample6 + sample8);
    return sum * weight_sum_inv;
}

//  Resizable one-pass blurs:
vec3 tex2Dblur3x3resize(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur3x3resize(texture, tex_uv, dxdy, blur3_std_dev);
}

vec3 tex2Dblur9fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Requires:   Same as tex2Dblur11()
    //  Returns:    A 1D 9x Gaussian blurred texture lookup using 1 nearest
    //              neighbor and 4 linear taps.  It may be mipmapped depending
    //              on settings and dxdy.
    //  First get the texel weights and normalization factor as above.
    float denom_inv = 0.5/(sigma*sigma);
    float w0 = 1.0;
    float w1 = exp(-1.0 * denom_inv);
    float w2 = exp(-4.0 * denom_inv);
    float w3 = exp(-9.0 * denom_inv);
    float w4 = exp(-16.0 * denom_inv);
    float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2 + w3 + w4));
    //  Calculate combined weights and linear sample ratios between texel pairs.
    float w12 = w1 + w2;
    float w34 = w3 + w4;
    float w12_ratio = w2/w12;
    float w34_ratio = w4/w34;
    //  Statically normalize weights, sum weighted samples, and return:
    vec3 sum = vec3(0.0);
    sum += w34 * tex2D_linearize(tex, tex_uv - (3.0 + w34_ratio) * dxdy).rgb;
    sum += w12 * tex2D_linearize(tex, tex_uv - (1.0 + w12_ratio) * dxdy).rgb;
    sum += w0 * tex2D_linearize(tex, tex_uv).rgb;
    sum += w12 * tex2D_linearize(tex, tex_uv + (1.0 + w12_ratio) * dxdy).rgb;
    sum += w34 * tex2D_linearize(tex, tex_uv + (3.0 + w34_ratio) * dxdy).rgb;
    return sum * weight_sum_inv;
}

vec3 tex2Dblur9x9(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Perform a 1-pass 9x9 blur with 5x5 bilinear samples.
    //  Requires:   Same as tex2Dblur9()
    //  Returns:    A 9x9 Gaussian blurred mipmapped texture lookup composed of
    //              5x5 carefully selected bilinear samples.
    //  Description:
    //  Perform a 1-pass 9x9 blur with 5x5 bilinear samples.  Adjust the
    //  bilinear sample location to reflect the true Gaussian weights for each
    //  underlying texel.  The following diagram illustrates the relative
    //  locations of bilinear samples.  Each sample with the same number has the
    //  same weight (notice the symmetry).  The letters a, b, c, d distinguish
    //  quadrants, and the letters U, D, L, R, C (up, down, left, right, center)
    //  distinguish 1D directions along the line containing the pixel center:
    //      6a 5a 2U 5b 6b
    //      4a 3a 1U 3b 4b
    //      2L 1L 0C 1R 2R
    //      4c 3c 1D 3d 4d
    //      6c 5c 2D 5d 6d
    //  The following diagram illustrates the underlying equally spaced texels,
    //  named after the sample that accesses them and subnamed by their location
    //  within their 2x2, 2x1, 1x2, or 1x1 texel block:
    //      6a4 6a3 5a4 5a3 2U2 5b3 5b4 6b3 6b4
    //      6a2 6a1 5a2 5a1 2U1 5b1 5b2 6b1 6b2
    //      4a4 4a3 3a4 3a3 1U2 3b3 3b4 4b3 4b4
    //      4a2 4a1 3a2 3a1 1U1 3b1 3b2 4b1 4b2
    //      2L2 2L1 1L2 1L1 0C1 1R1 1R2 2R1 2R2
    //      4c2 4c1 3c2 3c1 1D1 3d1 3d2 4d1 4d2
    //      4c4 4c3 3c4 3c3 1D2 3d3 3d4 4d3 4d4
    //      6c2 6c1 5c2 5c1 2D1 5d1 5d2 6d1 6d2
    //      6c4 6c3 5c4 5c3 2D2 5d3 5d4 6d3 6d4
    //  Note there is only one C texel and only two texels for each U, D, L, or
    //  R sample.  The center sample is effectively a nearest neighbor sample,
    //  and the U/D/L/R samples use 1D linear filtering.  All other texels are
    //  read with bilinear samples somewhere within their 2x2 texel blocks.

    //  COMPUTE TEXTURE COORDS:
    //  Statically compute sampling offsets within each 2x2 texel block, based
    //  on 1D sampling ratios between texels [1, 2] and [3, 4] texels away from
    //  the center, and reuse them independently for both dimensions.  Compute
    //  these offsets based on the relative 1D Gaussian weights of the texels
    //  in question.  (w1off means "Gaussian weight for the texel 1.0 texels
    //  away from the pixel center," etc.).
    float denom_inv = 0.5/(sigma*sigma);
    float w1off = exp(-1.0 * denom_inv);
    float w2off = exp(-4.0 * denom_inv);
    float w3off = exp(-9.0 * denom_inv);
    float w4off = exp(-16.0 * denom_inv);
    float texel1to2ratio = w2off/(w1off + w2off);
    float texel3to4ratio = w4off/(w3off + w4off);
    //  Statically compute texel offsets from the fragment center to each
    //  bilinear sample in the bottom-right quadrant, including x-axis-aligned:
    vec2 sample1R_texel_offset = vec2(1.0, 0.0) + vec2(texel1to2ratio, 0.0);
    vec2 sample2R_texel_offset = vec2(3.0, 0.0) + vec2(texel3to4ratio, 0.0);
    vec2 sample3d_texel_offset = vec2(1.0, 1.0) + vec2(texel1to2ratio, texel1to2ratio);
    vec2 sample4d_texel_offset = vec2(3.0, 1.0) + vec2(texel3to4ratio, texel1to2ratio);
    vec2 sample5d_texel_offset = vec2(1.0, 3.0) + vec2(texel1to2ratio, texel3to4ratio);
    vec2 sample6d_texel_offset = vec2(3.0, 3.0) + vec2(texel3to4ratio, texel3to4ratio);

    //  CALCULATE KERNEL WEIGHTS FOR ALL SAMPLES:
    //  Statically compute Gaussian texel weights for the bottom-right quadrant.
    //  Read underscores as "and."
    float w1R1 = w1off;
    float w1R2 = w2off;
    float w2R1 = w3off;
    float w2R2 = w4off;
    float w3d1 =     exp(-LENGTH_SQ(vec2(1.0, 1.0)) * denom_inv);
    float w3d2_3d3 = exp(-LENGTH_SQ(vec2(2.0, 1.0)) * denom_inv);
    float w3d4 =     exp(-LENGTH_SQ(vec2(2.0, 2.0)) * denom_inv);
    float w4d1_5d1 = exp(-LENGTH_SQ(vec2(3.0, 1.0)) * denom_inv);
    float w4d2_5d3 = exp(-LENGTH_SQ(vec2(4.0, 1.0)) * denom_inv);
    float w4d3_5d2 = exp(-LENGTH_SQ(vec2(3.0, 2.0)) * denom_inv);
    float w4d4_5d4 = exp(-LENGTH_SQ(vec2(4.0, 2.0)) * denom_inv);
    float w6d1 =     exp(-LENGTH_SQ(vec2(3.0, 3.0)) * denom_inv);
    float w6d2_6d3 = exp(-LENGTH_SQ(vec2(4.0, 3.0)) * denom_inv);
    float w6d4 =     exp(-LENGTH_SQ(vec2(4.0, 4.0)) * denom_inv);
    //  Statically add texel weights in each sample to get sample weights:
    float w0 = 1.0;
    float w1 = w1R1 + w1R2;
    float w2 = w2R1 + w2R2;
    float w3 = w3d1 + 2.0 * w3d2_3d3 + w3d4;
    float w4 = w4d1_5d1 + w4d2_5d3 + w4d3_5d2 + w4d4_5d4;
    float w5 = w4;
    float w6 = w6d1 + 2.0 * w6d2_6d3 + w6d4;
    //  Get the weight sum inverse (normalization factor):
    float weight_sum_inv =
        1.0/(w0 + 4.0 * (w1 + w2 + w3 + w4 + w5 + w6));

    //  LOAD TEXTURE SAMPLES:
    //  Load all 25 samples (1 nearest, 8 linear, 16 bilinear) using symmetry:
    vec2 mirror_x = vec2(-1.0, 1.0);
    vec2 mirror_y = vec2(1.0, -1.0);
    vec2 mirror_xy = vec2(-1.0, -1.0);
    vec2 dxdy_mirror_x = dxdy * mirror_x;
    vec2 dxdy_mirror_y = dxdy * mirror_y;
    vec2 dxdy_mirror_xy = dxdy * mirror_xy;
    //  Sampling order doesn't seem to affect performance, so just be clear:
    vec3 sample0C = tex2D_linearize(tex, tex_uv).rgb;
    vec3 sample1R = tex2D_linearize(tex, tex_uv + dxdy * sample1R_texel_offset).rgb;
    vec3 sample1D = tex2D_linearize(tex, tex_uv + dxdy * sample1R_texel_offset.yx).rgb;
    vec3 sample1L = tex2D_linearize(tex, tex_uv - dxdy * sample1R_texel_offset).rgb;
    vec3 sample1U = tex2D_linearize(tex, tex_uv - dxdy * sample1R_texel_offset.yx).rgb;
    vec3 sample2R = tex2D_linearize(tex, tex_uv + dxdy * sample2R_texel_offset).rgb;
    vec3 sample2D = tex2D_linearize(tex, tex_uv + dxdy * sample2R_texel_offset.yx).rgb;
    vec3 sample2L = tex2D_linearize(tex, tex_uv - dxdy * sample2R_texel_offset).rgb;
    vec3 sample2U = tex2D_linearize(tex, tex_uv - dxdy * sample2R_texel_offset.yx).rgb;
    vec3 sample3d = tex2D_linearize(tex, tex_uv + dxdy * sample3d_texel_offset).rgb;
    vec3 sample3c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample3d_texel_offset).rgb;
    vec3 sample3b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample3d_texel_offset).rgb;
    vec3 sample3a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample3d_texel_offset).rgb;
    vec3 sample4d = tex2D_linearize(tex, tex_uv + dxdy * sample4d_texel_offset).rgb;
    vec3 sample4c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample4d_texel_offset).rgb;
    vec3 sample4b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample4d_texel_offset).rgb;
    vec3 sample4a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample4d_texel_offset).rgb;
    vec3 sample5d = tex2D_linearize(tex, tex_uv + dxdy * sample5d_texel_offset).rgb;
    vec3 sample5c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample5d_texel_offset).rgb;
    vec3 sample5b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample5d_texel_offset).rgb;
    vec3 sample5a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample5d_texel_offset).rgb;
    vec3 sample6d = tex2D_linearize(tex, tex_uv + dxdy * sample6d_texel_offset).rgb;
    vec3 sample6c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample6d_texel_offset).rgb;
    vec3 sample6b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample6d_texel_offset).rgb;
    vec3 sample6a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample6d_texel_offset).rgb;

    //  SUM WEIGHTED SAMPLES:
    //  Statically normalize weights (so total = 1.0), and sum weighted samples.
    vec3 sum = w0 * sample0C;
    sum += w1 * (sample1R + sample1D + sample1L + sample1U);
    sum += w2 * (sample2R + sample2D + sample2L + sample2U);
    sum += w3 * (sample3d + sample3c + sample3b + sample3a);
    sum += w4 * (sample4d + sample4c + sample4b + sample4a);
    sum += w5 * (sample5d + sample5c + sample5b + sample5a);
    sum += w6 * (sample6d + sample6c + sample6b + sample6a);
    return sum * weight_sum_inv;
}

vec3 tex2Dblur7x7(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Perform a 1-pass 7x7 blur with 5x5 bilinear samples.
    //  Requires:   Same as tex2Dblur9()
    //  Returns:    A 7x7 Gaussian blurred mipmapped texture lookup composed of
    //              4x4 carefully selected bilinear samples.
    //  Description:
    //  First see the descriptions for tex2Dblur9x9() and tex2Dblur7().  This
    //  blur mixes concepts from both.  The sample layout is as follows:
    //      4a 3a 3b 4b
    //      2a 1a 1b 2b
    //      2c 1c 1d 2d
    //      4c 3c 3d 4d
    //  The texel layout is as follows.  Note that samples 3a/3b, 1a/1b, 1c/1d,
    //  and 3c/3d share a vertical column of texels, and samples 2a/2c, 1a/1c,
    //  1b/1d, and 2b/2d share a horizontal row of texels (all sample1's share
    //  the center texel):
    //      4a4  4a3  3a4  3ab3 3b4  4b3  4b4
    //      4a2  4a1  3a2  3ab1 3b2  4b1  4b2
    //      2a4  2a3  1a4  1ab3 1b4  2b3  2b4
    //      2ac2 2ac1 1ac2 1*   1bd2 2bd1 2bd2
    //      2c4  2c3  1c4  1cd3 1d4  2d3  2d4
    //      4c2  4c1  3c2  3cd1 3d2  4d1  4d2
    //      4c4  4c3  3c4  3cd3 3d4  4d3  4d4

    //  COMPUTE TEXTURE COORDS:
    //  Statically compute bilinear sampling offsets (details in tex2Dblur9x9).
    float denom_inv = 0.5/(sigma*sigma);
    float w0off = 1.0;
    float w1off = exp(-1.0 * denom_inv);
    float w2off = exp(-4.0 * denom_inv);
    float w3off = exp(-9.0 * denom_inv);
    float texel0to1ratio = w1off/(w0off * 0.5 + w1off);
    float texel2to3ratio = w3off/(w2off + w3off);
    //  Statically compute texel offsets from the fragment center to each
    //  bilinear sample in the bottom-right quadrant, including axis-aligned:
    vec2 sample1d_texel_offset = vec2(texel0to1ratio, texel0to1ratio);
    vec2 sample2d_texel_offset = vec2(2.0, 0.0) + vec2(texel2to3ratio, texel0to1ratio);
    vec2 sample3d_texel_offset = vec2(0.0, 2.0) + vec2(texel0to1ratio, texel2to3ratio);
    vec2 sample4d_texel_offset = vec2(2.0, 2.0) + vec2(texel2to3ratio, texel2to3ratio);

    //  CALCULATE KERNEL WEIGHTS FOR ALL SAMPLES:
    //  Statically compute Gaussian texel weights for the bottom-right quadrant.
    //  Read underscores as "and."
    float w1abcd = 1.0;
    float w1bd2_1cd3 = exp(-LENGTH_SQ(vec2(1.0, 0.0)) * denom_inv);
    float w2bd1_3cd1 = exp(-LENGTH_SQ(vec2(2.0, 0.0)) * denom_inv);
    float w2bd2_3cd2 = exp(-LENGTH_SQ(vec2(3.0, 0.0)) * denom_inv);
    float w1d4 =       exp(-LENGTH_SQ(vec2(1.0, 1.0)) * denom_inv);
    float w2d3_3d2 =   exp(-LENGTH_SQ(vec2(2.0, 1.0)) * denom_inv);
    float w2d4_3d4 =   exp(-LENGTH_SQ(vec2(3.0, 1.0)) * denom_inv);
    float w4d1 =       exp(-LENGTH_SQ(vec2(2.0, 2.0)) * denom_inv);
    float w4d2_4d3 =   exp(-LENGTH_SQ(vec2(3.0, 2.0)) * denom_inv);
    float w4d4 =       exp(-LENGTH_SQ(vec2(3.0, 3.0)) * denom_inv);
    //  Statically add texel weights in each sample to get sample weights.
    //  Split weights for shared texels between samples sharing them:
    float w1 = w1abcd * 0.25 + w1bd2_1cd3 + w1d4;
    float w2_3 = (w2bd1_3cd1 + w2bd2_3cd2) * 0.5 + w2d3_3d2 + w2d4_3d4;
    float w4 = w4d1 + 2.0 * w4d2_4d3 + w4d4;
    //  Get the weight sum inverse (normalization factor):
    float weight_sum_inv =
        1.0/(4.0 * (w1 + 2.0 * w2_3 + w4));

    //  LOAD TEXTURE SAMPLES:
    //  Load all 16 samples using symmetry:
    vec2 mirror_x = vec2(-1.0, 1.0);
    vec2 mirror_y = vec2(1.0, -1.0);
    vec2 mirror_xy = vec2(-1.0, -1.0);
    vec2 dxdy_mirror_x = dxdy * mirror_x;
    vec2 dxdy_mirror_y = dxdy * mirror_y;
    vec2 dxdy_mirror_xy = dxdy * mirror_xy;
    vec3 sample1a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample1d_texel_offset).rgb;
    vec3 sample2a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample2d_texel_offset).rgb;
    vec3 sample3a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample3d_texel_offset).rgb;
    vec3 sample4a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample4d_texel_offset).rgb;
    vec3 sample1b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample1d_texel_offset).rgb;
    vec3 sample2b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample2d_texel_offset).rgb;
    vec3 sample3b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample3d_texel_offset).rgb;
    vec3 sample4b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample4d_texel_offset).rgb;
    vec3 sample1c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample1d_texel_offset).rgb;
    vec3 sample2c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample2d_texel_offset).rgb;
    vec3 sample3c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample3d_texel_offset).rgb;
    vec3 sample4c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample4d_texel_offset).rgb;
    vec3 sample1d = tex2D_linearize(tex, tex_uv + dxdy * sample1d_texel_offset).rgb;
    vec3 sample2d = tex2D_linearize(tex, tex_uv + dxdy * sample2d_texel_offset).rgb;
    vec3 sample3d = tex2D_linearize(tex, tex_uv + dxdy * sample3d_texel_offset).rgb;
    vec3 sample4d = tex2D_linearize(tex, tex_uv + dxdy * sample4d_texel_offset).rgb;

    //  SUM WEIGHTED SAMPLES:
    //  Statically normalize weights (so total = 1.0), and sum weighted samples.
    vec3 sum = vec3(0.0);
    sum += w1 * (sample1a + sample1b + sample1c + sample1d);
    sum += w2_3 * (sample2a + sample2b + sample2c + sample2d);
    sum += w2_3 * (sample3a + sample3b + sample3c + sample3d);
    sum += w4 * (sample4a + sample4b + sample4c + sample4d);
    return sum * weight_sum_inv;
}

vec3 tex2Dblur5x5(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Perform a 1-pass 5x5 blur with 3x3 bilinear samples.
    //  Requires:   Same as tex2Dblur9()
    //  Returns:    A 5x5 Gaussian blurred mipmapped texture lookup composed of
    //              3x3 carefully selected bilinear samples.
    //  Description:
    //  First see the description for tex2Dblur9x9().  This blur uses the same
    //  concept and sample/texel locations except on a smaller scale.  Samples:
    //      2a 1U 2b
    //      1L 0C 1R
    //      2c 1D 2d
    //  Texels:
    //      2a4 2a3 1U2 2b3 2b4
    //      2a2 2a1 1U1 2b1 2b2
    //      1L2 1L1 0C1 1R1 1R2
    //      2c2 2c1 1D1 2d1 2d2
    //      2c4 2c3 1D2 2d3 2d4

    //  COMPUTE TEXTURE COORDS:
    //  Statically compute bilinear sampling offsets (details in tex2Dblur9x9).
    float denom_inv = 0.5/(sigma*sigma);
    float w1off = exp(-1.0 * denom_inv);
    float w2off = exp(-4.0 * denom_inv);
    float texel1to2ratio = w2off/(w1off + w2off);
    //  Statically compute texel offsets from the fragment center to each
    //  bilinear sample in the bottom-right quadrant, including x-axis-aligned:
    vec2 sample1R_texel_offset = vec2(1.0, 0.0) + vec2(texel1to2ratio, 0.0);
    vec2 sample2d_texel_offset = vec2(1.0, 1.0) + vec2(texel1to2ratio, texel1to2ratio);

    //  CALCULATE KERNEL WEIGHTS FOR ALL SAMPLES:
    //  Statically compute Gaussian texel weights for the bottom-right quadrant.
    //  Read underscores as "and."
    float w1R1 = w1off;
    float w1R2 = w2off;
    float w2d1 =   exp(-LENGTH_SQ(vec2(1.0, 1.0)) * denom_inv);
    float w2d2_3 = exp(-LENGTH_SQ(vec2(2.0, 1.0)) * denom_inv);
    float w2d4 =   exp(-LENGTH_SQ(vec2(2.0, 2.0)) * denom_inv);
    //  Statically add texel weights in each sample to get sample weights:
    float w0 = 1.0;
    float w1 = w1R1 + w1R2;
    float w2 = w2d1 + 2.0 * w2d2_3 + w2d4;
    //  Get the weight sum inverse (normalization factor):
    float weight_sum_inv = 1.0/(w0 + 4.0 * (w1 + w2));

    //  LOAD TEXTURE SAMPLES:
    //  Load all 9 samples (1 nearest, 4 linear, 4 bilinear) using symmetry:
    vec2 mirror_x = vec2(-1.0, 1.0);
    vec2 mirror_y = vec2(1.0, -1.0);
    vec2 mirror_xy = vec2(-1.0, -1.0);
    vec2 dxdy_mirror_x = dxdy * mirror_x;
    vec2 dxdy_mirror_y = dxdy * mirror_y;
    vec2 dxdy_mirror_xy = dxdy * mirror_xy;
    vec3 sample0C = tex2D_linearize(tex, tex_uv).rgb;
    vec3 sample1R = tex2D_linearize(tex, tex_uv + dxdy * sample1R_texel_offset).rgb;
    vec3 sample1D = tex2D_linearize(tex, tex_uv + dxdy * sample1R_texel_offset.yx).rgb;
    vec3 sample1L = tex2D_linearize(tex, tex_uv - dxdy * sample1R_texel_offset).rgb;
    vec3 sample1U = tex2D_linearize(tex, tex_uv - dxdy * sample1R_texel_offset.yx).rgb;
    vec3 sample2d = tex2D_linearize(tex, tex_uv + dxdy * sample2d_texel_offset).rgb;
    vec3 sample2c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample2d_texel_offset).rgb;
    vec3 sample2b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample2d_texel_offset).rgb;
    vec3 sample2a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample2d_texel_offset).rgb;

    //  SUM WEIGHTED SAMPLES:
    //  Statically normalize weights (so total = 1.0), and sum weighted samples.
    vec3 sum = w0 * sample0C;
    sum += w1 * (sample1R + sample1D + sample1L + sample1U);
    sum += w2 * (sample2a + sample2b + sample2c + sample2d);
    return sum * weight_sum_inv;
}

vec3 tex2Dblur3x3(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  Perform a 1-pass 3x3 blur with 5x5 bilinear samples.
    //  Requires:   Same as tex2Dblur9()
    //  Returns:    A 3x3 Gaussian blurred mipmapped texture lookup composed of
    //              2x2 carefully selected bilinear samples.
    //  Description:
    //  First see the descriptions for tex2Dblur9x9() and tex2Dblur7().  This
    //  blur mixes concepts from both.  The sample layout is as follows:
    //      0a 0b
    //      0c 0d
    //  The texel layout is as follows.  Note that samples 0a/0b and 0c/0d share
    //  a vertical column of texels, and samples 0a/0c and 0b/0d share a
    //  horizontal row of texels (all samples share the center texel):
    //      0a3  0ab2 0b3
    //      0ac1 0*0  0bd1
    //      0c3  0cd2 0d3

    //  COMPUTE TEXTURE COORDS:
    //  Statically compute bilinear sampling offsets (details in tex2Dblur9x9).
    float denom_inv = 0.5/(sigma*sigma);
    float w0off = 1.0;
    float w1off = exp(-1.0 * denom_inv);
    float texel0to1ratio = w1off/(w0off * 0.5 + w1off);
    //  Statically compute texel offsets from the fragment center to each
    //  bilinear sample in the bottom-right quadrant, including axis-aligned:
    vec2 sample0d_texel_offset = vec2(texel0to1ratio, texel0to1ratio);

    //  LOAD TEXTURE SAMPLES:
    //  Load all 4 samples using symmetry:
    vec2 mirror_x = vec2(-1.0, 1.0);
    vec2 mirror_y = vec2(1.0, -1.0);
    vec2 mirror_xy = vec2(-1.0, -1.0);
    vec2 dxdy_mirror_x = dxdy * mirror_x;
    vec2 dxdy_mirror_y = dxdy * mirror_y;
    vec2 dxdy_mirror_xy = dxdy * mirror_xy;
    vec3 sample0a = tex2D_linearize(tex, tex_uv + dxdy_mirror_xy * sample0d_texel_offset).rgb;
    vec3 sample0b = tex2D_linearize(tex, tex_uv + dxdy_mirror_y * sample0d_texel_offset).rgb;
    vec3 sample0c = tex2D_linearize(tex, tex_uv + dxdy_mirror_x * sample0d_texel_offset).rgb;
    vec3 sample0d = tex2D_linearize(tex, tex_uv + dxdy * sample0d_texel_offset).rgb;

    //  SUM WEIGHTED SAMPLES:
    //  Weights for all samples are the same, so just average them:
    return 0.25 * (sample0a + sample0b + sample0c + sample0d);
}

vec3 tex2Dblur9fast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur9fast(tex, tex_uv, dxdy, blur9_std_dev);
}

vec3 tex2Dblur17fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur17fast(texture, tex_uv, dxdy, blur17_std_dev);
}

vec3 tex2Dblur25fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur25fast(texture, tex_uv, dxdy, blur25_std_dev);
}

vec3 tex2Dblur43fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur43fast(texture, tex_uv, dxdy, blur43_std_dev);
}
vec3 tex2Dblur31fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur31fast(texture, tex_uv, dxdy, blur31_std_dev);
}

vec3 tex2Dblur3fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur3fast(texture, tex_uv, dxdy, blur3_std_dev);
}

vec3 tex2Dblur3x3(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur3x3(texture, tex_uv, dxdy, blur3_std_dev);
}

vec3 tex2Dblur5fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur5fast(texture, tex_uv, dxdy, blur5_std_dev);
}

vec3 tex2Dblur5resize(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur5resize(texture, tex_uv, dxdy, blur5_std_dev);
}
vec3 tex2Dblur3resize(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur3resize(texture, tex_uv, dxdy, blur3_std_dev);
}

vec3 tex2Dblur5x5(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur5x5(texture, tex_uv, dxdy, blur5_std_dev);
}

vec3 tex2Dblur7resize(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur7resize(texture, tex_uv, dxdy, blur7_std_dev);
}

vec3 tex2Dblur7fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur7fast(texture, tex_uv, dxdy, blur7_std_dev);
}

vec3 tex2Dblur7x7(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur7x7(texture, tex_uv, dxdy, blur7_std_dev);
}

vec3 tex2Dblur9resize(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur9resize(texture, tex_uv, dxdy, blur9_std_dev);
}

vec3 tex2Dblur9x9(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur9x9(texture, tex_uv, dxdy, blur9_std_dev);
}

vec3 tex2Dblur11resize(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur11resize(texture, tex_uv, dxdy, blur11_std_dev);
}

vec3 tex2Dblur11fast(sampler2D texture, vec2 tex_uv,
    vec2 dxdy)
{
    return tex2Dblur11fast(texture, tex_uv, dxdy, blur11_std_dev);
}

#endif  //  BLUR_FUNCTIONS_H
//////////////   END #include blur-functions.h     ////////////////////

/////////////   BEGIN #include bloom-functions.h     ///////////////////
#ifndef BLOOM_FUNCTIONS_H
#define BLOOM_FUNCTIONS_H

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

//  These utility functions and constants help several passes determine the
//  size and center texel weight of the phosphor bloom in a uniform manner.


//////////////////////////////////  INCLUDES  //////////////////////////////////

//  We need to calculate the correct blur sigma using some .cgp constants:
//#include "../user-settings.h"
//#include "derived-settings-and-constants.h"
//#include "../../../../include/blur-functions.h"


///////////////////////////////  BLOOM CONSTANTS  //////////////////////////////

//  Compute constants with manual inlines of the functions below:
float bloom_diff_thresh = 1.0/256.0;

//  Assume an extremely large viewport size for asymptotic results:
float max_viewport_size_x = 1080.0*1024.0*(4.0/3.0);

///////////////////////////////////  HELPERS  //////////////////////////////////

float get_min_sigma_to_blur_triad(float triad_size,
    float thresh)
{
    //  Requires:   1.) triad_size is the final phosphor triad size in pixels
    //              2.) thresh is the max desired pixel difference in the
    //                  blurred triad (e.g. 1.0/256.0).
    //  Returns:    Return the minimum sigma that will fully blur a phosphor
    //              triad on the screen to an even color, within thresh.
    //              This closed-form function was found by curve-fitting data.
    //  Estimate: max error = ~0.086036, mean sq. error = ~0.0013387:
    return -0.05168 + 0.6113*triad_size -
        1.122*triad_size*sqrt(0.000416 + thresh);
    //  Estimate: max error = ~0.16486, mean sq. error = ~0.0041041:
    //return 0.5985*triad_size - triad_size*sqrt(thresh)
}

float get_absolute_scale_blur_sigma(float thresh)
{
    //  Requires:   1.) min_expected_triads must be a global float.  The number
    //                  of horizontal phosphor triads in the final image must be
    //                  >= min_allowed_viewport_triads.x for realistic results.
    //              2.) bloom_approx_scale_x must be a global float equal to the
    //                  absolute horizontal scale of BLOOM_APPROX.
    //              3.) bloom_approx_scale_x/min_allowed_viewport_triads.x
    //                  should be <= 1.1658025090 to keep the final result <
    //                  0.62666015625 (the largest sigma ensuring the largest
    //                  unused texel weight stays < 1.0/256.0 for a 3x3 blur).
    //              4.) thresh is the max desired pixel difference in the
    //                  blurred triad (e.g. 1.0/256.0).
    //  Returns:    Return the minimum Gaussian sigma that will blur the pass
    //              output as much as it would have taken to blur away
    //              bloom_approx_scale_x horizontal phosphor triads.
    //  Description:
    //  BLOOM_APPROX should look like a downscaled phosphor blur.  Ideally, we'd
    //  use the same blur sigma as the actual phosphor bloom and scale it down
    //  to the current resolution with (bloom_approx_scale_x/viewport_size_x), but
    //  we don't know the viewport size in this pass.  Instead, we'll blur as
    //  much as it would take to blur away min_allowed_viewport_triads.x.  This
    //  will blur "more than necessary" if the user actually uses more triads,
    //  but that's not terrible either, because blurring a constant fraction of
    //  the viewport may better resemble a true optical bloom anyway (since the
    //  viewport will generally be about the same fraction of each player's
    //  field of view, regardless of screen size and resolution).
    //  Assume an extremely large viewport size for asymptotic results.
    return bloom_approx_scale_x/max_viewport_size_x *
        get_min_sigma_to_blur_triad(
            max_viewport_size_x/min_allowed_viewport_triads.x, thresh);
}

float get_center_weight(float sigma)
{
    //  Given a Gaussian blur sigma, get the blur weight for the center texel.
    #ifdef RUNTIME_PHOSPHOR_BLOOM_SIGMA
        return get_fast_gaussian_weight_sum_inv(sigma);
    #else
        float denom_inv = 0.5/(sigma*sigma);
        float w0 = 1.0;
        float w1 = exp(-1.0 * denom_inv);
        float w2 = exp(-4.0 * denom_inv);
        float w3 = exp(-9.0 * denom_inv);
        float w4 = exp(-16.0 * denom_inv);
        float w5 = exp(-25.0 * denom_inv);
        float w6 = exp(-36.0 * denom_inv);
        float w7 = exp(-49.0 * denom_inv);
        float w8 = exp(-64.0 * denom_inv);
        float w9 = exp(-81.0 * denom_inv);
        float w10 = exp(-100.0 * denom_inv);
        float w11 = exp(-121.0 * denom_inv);
        float w12 = exp(-144.0 * denom_inv);
        float w13 = exp(-169.0 * denom_inv);
        float w14 = exp(-196.0 * denom_inv);
        float w15 = exp(-225.0 * denom_inv);
        float w16 = exp(-256.0 * denom_inv);
        float w17 = exp(-289.0 * denom_inv);
        float w18 = exp(-324.0 * denom_inv);
        float w19 = exp(-361.0 * denom_inv);
        float w20 = exp(-400.0 * denom_inv);
        float w21 = exp(-441.0 * denom_inv);
        //  Note: If the implementation uses a smaller blur than the max allowed,
        //  the worst case scenario is that the center weight will be overestimated,
        //  so we'll put a bit more energy into the brightpass...no huge deal.
        //  Then again, if the implementation uses a larger blur than the max
        //  "allowed" because of dynamic branching, the center weight could be
        //  underestimated, which is more of a problem...consider always using
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_12_PIXELS
            //  43x blur:
            float weight_sum_inv = 1.0 /
                (w0 + 2.0 * (w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 +
                w11 + w12 + w13 + w14 + w15 + w16 + w17 + w18 + w19 + w20 + w21));
        #else
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_9_PIXELS
            //  31x blur:
            float weight_sum_inv = 1.0 /
                (w0 + 2.0 * (w1 + w2 + w3 + w4 + w5 + w6 + w7 +
                w8 + w9 + w10 + w11 + w12 + w13 + w14 + w15));
        #else
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_6_PIXELS
            //  25x blur:
            float weight_sum_inv = 1.0 / (w0 + 2.0 * (
                w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9 + w10 + w11 + w12));
        #else
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS
            //  17x blur:
            float weight_sum_inv = 1.0 / (w0 + 2.0 * (
                w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8));
        #else
            //  9x blur:
            float weight_sum_inv = 1.0 / (w0 + 2.0 * (w1 + w2 + w3 + w4));
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_6_PIXELS
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_9_PIXELS
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_12_PIXELS
        float center_weight = weight_sum_inv * weight_sum_inv;
        return center_weight;
    #endif
}

vec3 tex2DblurNfast(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, float sigma)
{
    //  If sigma is static, we can safely branch and use the smallest blur
    //  that's big enough.  Ignore #define hints, because we'll only use a
    //  large blur if we actually need it, and the branches cost nothing.
    #ifndef RUNTIME_PHOSPHOR_BLOOM_SIGMA
        #define PHOSPHOR_BLOOM_BRANCH_FOR_BLUR_SIZE
    #else
        //  It's still worth branching if the profile supports dynamic branches:
        //  It's much faster than using a hugely excessive blur, but each branch
        //  eats ~1% FPS.
        #ifdef DRIVERS_ALLOW_DYNAMIC_BRANCHES
            #define PHOSPHOR_BLOOM_BRANCH_FOR_BLUR_SIZE
        #endif
    #endif
    //  Failed optimization notes:
    //  I originally created a same-size mipmapped 5-tap separable blur10 that
    //  could handle any sigma by reaching into lower mip levels.  It was
    //  as fast as blur25fast for runtime sigmas and a tad faster than
    //  blur31fast for static sigmas, but mipmapping two viewport-size passes
    //  ate 10% of FPS across all codepaths, so it wasn't worth it.
    #ifdef PHOSPHOR_BLOOM_BRANCH_FOR_BLUR_SIZE
        if(sigma <= blur9_std_dev)
        {
            return tex2Dblur9fast(tex, tex_uv, dxdy, sigma);
        }
        else if(sigma <= blur17_std_dev)
        {
            return tex2Dblur17fast(tex, tex_uv, dxdy, sigma);
        }
        else if(sigma <= blur25_std_dev)
        {
            return tex2Dblur25fast(tex, tex_uv, dxdy, sigma);
        }
        else if(sigma <= blur31_std_dev)
        {
            return tex2Dblur31fast(tex, tex_uv, dxdy, sigma);
        }
        else
        {
            return tex2Dblur43fast(tex, tex_uv, dxdy, sigma);
        }
    #else
        //  If we can't afford to branch, we can only guess at what blur
        //  size we need.  Therefore, use the largest blur allowed.
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_12_PIXELS
            return tex2Dblur43fast(tex, tex_uv, dxdy, sigma);
        #else
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_9_PIXELS
            return tex2Dblur31fast(tex, tex_uv, dxdy, sigma);
        #else
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_6_PIXELS
            return tex2Dblur25fast(tex, tex_uv, dxdy, sigma);
        #else
        #ifdef PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS
            return tex2Dblur17fast(tex, tex_uv, dxdy, sigma);
        #else
            return tex2Dblur9fast(tex, tex_uv, dxdy, sigma);
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_3_PIXELS
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_6_PIXELS
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_9_PIXELS
        #endif  //  PHOSPHOR_BLOOM_TRIADS_LARGER_THAN_12_PIXELS
    #endif  //  PHOSPHOR_BLOOM_BRANCH_FOR_BLUR_SIZE
}

float get_bloom_approx_sigma(float output_size_x_runtime,
    float estimated_viewport_size_x)
{
    //  Requires:   1.) output_size_x_runtime == BLOOM_APPROX.output_size.x.
    //                  This is included for dynamic codepaths just in case the
    //                  following two globals are incorrect:
    //              2.) bloom_approx_size_x_for_skip should == the same
    //                  if PHOSPHOR_BLOOM_FAKE is #defined
    //              3.) bloom_approx_size_x should == the same otherwise
    //  Returns:    For gaussian4x4, return a dynamic small bloom sigma that's
    //              as close to optimal as possible given available information.
    //              For blur3x3, return the a static small bloom sigma that
    //              works well for typical cases.  Otherwise, we're using simple
    //              bilinear filtering, so use static calculations.
    //  Assume the default static value.  This is a compromise that ensures
    //  typical triads are blurred, even if unusually large ones aren't.
    float mask_num_triads_static =
        max(min_allowed_viewport_triads.x, mask_num_triads_desired_static);
    float mask_num_triads_from_size =
        estimated_viewport_size_x/mask_triad_size_desired;
    float mask_num_triads_runtime = max(min_allowed_viewport_triads.x,
        mix(mask_num_triads_from_size, mask_num_triads_desired,
            mask_specify_num_triads));
    //  Assume an extremely large viewport size for asymptotic results:
     float max_viewport_size_x = 1080.0*1024.0*(4.0/3.0);
    if(bloom_approx_filter > 1.5)   //  4x4 true Gaussian resize
    {
        //  Use the runtime num triads and output size:
        float asymptotic_triad_size =
            max_viewport_size_x/mask_num_triads_runtime;
        float asymptotic_sigma = get_min_sigma_to_blur_triad(
            asymptotic_triad_size, bloom_diff_thresh);
        float bloom_approx_sigma =
            asymptotic_sigma * output_size_x_runtime/max_viewport_size_x;
        //  The BLOOM_APPROX input has to be ORIG_LINEARIZED to avoid moire, but
        //  account for the Gaussian scanline sigma from the last pass too.
        //  The bloom will be too wide horizontally but tall enough vertically.
        return length(vec2(bloom_approx_sigma, beam_max_sigma));
    }
    else    //  3x3 blur resize (the bilinear resize doesn't need a sigma)
    {
        //  We're either using blur3x3 or bilinear filtering.  The biggest
        //  reason to choose blur3x3 is to avoid dynamic weights, so use a
        //  static calculation.
        #ifdef PHOSPHOR_BLOOM_FAKE
            float output_size_x_static =
                bloom_approx_size_x_for_fake;
        #else
            float output_size_x_static = bloom_approx_size_x;
        #endif
        float asymptotic_triad_size =
            max_viewport_size_x/mask_num_triads_static;
        float asymptotic_sigma = get_min_sigma_to_blur_triad(
            asymptotic_triad_size, bloom_diff_thresh);
        float bloom_approx_sigma =
            asymptotic_sigma * output_size_x_static/max_viewport_size_x;
        //  The BLOOM_APPROX input has to be ORIG_LINEARIZED to avoid moire, but
        //  try accounting for the Gaussian scanline sigma from the last pass
        //  too; use the static default value:
        return length(vec2(bloom_approx_sigma, beam_max_sigma_static));
    }
}

float get_final_bloom_sigma(float bloom_sigma_runtime)
{
    //  Requires:   1.) bloom_sigma_runtime is a precalculated sigma that's
    //                  optimal for the [known] triad size.
    //              2.) Call this from a fragment shader (not a vertex shader),
    //                  or blurring with static sigmas won't be constant-folded.
    //  Returns:    Return the optimistic static sigma if the triad size is
    //              known at compile time.  Otherwise return the optimal runtime
    //              sigma (10% slower) or an implementation-specific compromise
    //              between an optimistic or pessimistic static sigma.
    //  Notes:      Call this from the fragment shader, NOT the vertex shader,
    //              so static sigmas can be constant-folded!
    float bloom_sigma_optimistic = get_min_sigma_to_blur_triad(
        mask_triad_size_desired, bloom_diff_thresh);
    #ifdef RUNTIME_PHOSPHOR_BLOOM_SIGMA
        return bloom_sigma_runtime;
    #else
        //  Overblurring looks as bad as underblurring, so assume average-size
        //  triads, not worst-case huge triads:
        return bloom_sigma_optimistic;
    #endif
}

#endif  //  BLOOM_FUNCTIONS_H
//////////////   END #include bloom-functions.h     ////////////////////

///////////////////////////////////  HELPERS  //////////////////////////////////

vec3 tex2Dresize_gaussian4x4(sampler2D tex, vec2 tex_uv,
    vec2 dxdy, vec2 texture_size, vec2 texture_size_inv,
    vec2 tex_uv_to_pixel_scale, float sigma)
{
    //  Requires:   1.) All requirements of gamma-management.h must be satisfied!
    //              2.) filter_linearN must == "true" in your .cgp preset.
    //              3.) mipmap_inputN must == "true" in your .cgp preset if
    //                  IN.output_size << SRC.video_size.
    //              4.) dxdy should contain the uv pixel spacing:
    //                      dxdy = max(vec2(1.0),
    //                          SRC.video_size/IN.output_size)/SRC.texture_size;
    //              5.) texture_size == SRC.texture_size
    //              6.) texture_size_inv == vec2(1.0)/SRC.texture_size
    //              7.) tex_uv_to_pixel_scale == IN.output_size *
    //                      SRC.texture_size / SRC.video_size;
    //              8.) sigma is the desired Gaussian standard deviation, in
    //                  terms of output pixels.  It should be < ~0.66171875 to
    //                  ensure the first unused sample (outside the 4x4 box) has
    //                  a weight < 1.0/256.0.
    //  Returns:    A true 4x4 Gaussian resize of the input.
    //  Description:
    //  Given correct inputs, this Gaussian resizer samples 4 pixel locations
    //  along each downsized dimension and/or 4 texel locations along each
    //  upsized dimension.  It computes dynamic weights based on the pixel-space
    //  distance of each sample from the destination pixel.  It is arbitrarily
    //  resizable and higher quality than tex2Dblur3x3_resize, but it's slower.
    //  TODO: Move this to a more suitable file once there are others like it.
    float denom_inv = 0.5/(sigma*sigma);
    //  We're taking 4x4 samples, and we're snapping to texels for upsizing.
    //  Find texture coords for sample 5 (second row, second column):
    vec2 curr_texel = tex_uv * texture_size;
    vec2 prev_texel =
        floor(curr_texel - vec2(under_half)) + vec2(0.5);
    vec2 prev_texel_uv = prev_texel * texture_size_inv;
    bvec2 snap = lessThanEqual(dxdy , texture_size_inv);
    vec2 sample5_downsize_uv = tex_uv - 0.5 * dxdy;
    vec2 sample5_uv = mix(sample5_downsize_uv, prev_texel_uv, snap);
    //  Compute texture coords for other samples:
    vec2 dx = vec2(dxdy.x, 0.0);
    vec2 sample0_uv = sample5_uv - dxdy;
    vec2 sample10_uv = sample5_uv + dxdy;
    vec2 sample15_uv = sample5_uv + 2.0 * dxdy;
    vec2 sample1_uv = sample0_uv + dx;
    vec2 sample2_uv = sample0_uv + 2.0 * dx;
    vec2 sample3_uv = sample0_uv + 3.0 * dx;
    vec2 sample4_uv = sample5_uv - dx;
    vec2 sample6_uv = sample5_uv + dx;
    vec2 sample7_uv = sample5_uv + 2.0 * dx;
    vec2 sample8_uv = sample10_uv - 2.0 * dx;
    vec2 sample9_uv = sample10_uv - dx;
    vec2 sample11_uv = sample10_uv + dx;
    vec2 sample12_uv = sample15_uv - 3.0 * dx;
    vec2 sample13_uv = sample15_uv - 2.0 * dx;
    vec2 sample14_uv = sample15_uv - dx;
    //  Load each sample:
    vec3 sample0 = tex2D_linearize(tex, sample0_uv).rgb;
    vec3 sample1 = tex2D_linearize(tex, sample1_uv).rgb;
    vec3 sample2 = tex2D_linearize(tex, sample2_uv).rgb;
    vec3 sample3 = tex2D_linearize(tex, sample3_uv).rgb;
    vec3 sample4 = tex2D_linearize(tex, sample4_uv).rgb;
    vec3 sample5 = tex2D_linearize(tex, sample5_uv).rgb;
    vec3 sample6 = tex2D_linearize(tex, sample6_uv).rgb;
    vec3 sample7 = tex2D_linearize(tex, sample7_uv).rgb;
    vec3 sample8 = tex2D_linearize(tex, sample8_uv).rgb;
    vec3 sample9 = tex2D_linearize(tex, sample9_uv).rgb;
    vec3 sample10 = tex2D_linearize(tex, sample10_uv).rgb;
    vec3 sample11 = tex2D_linearize(tex, sample11_uv).rgb;
    vec3 sample12 = tex2D_linearize(tex, sample12_uv).rgb;
    vec3 sample13 = tex2D_linearize(tex, sample13_uv).rgb;
    vec3 sample14 = tex2D_linearize(tex, sample14_uv).rgb;
    vec3 sample15 = tex2D_linearize(tex, sample15_uv).rgb;
    //  Compute destination pixel offsets for each sample:
    vec2 dest_pixel = tex_uv * tex_uv_to_pixel_scale;
    vec2 sample0_offset = sample0_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample1_offset = sample1_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample2_offset = sample2_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample3_offset = sample3_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample4_offset = sample4_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample5_offset = sample5_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample6_offset = sample6_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample7_offset = sample7_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample8_offset = sample8_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample9_offset = sample9_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample10_offset = sample10_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample11_offset = sample11_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample12_offset = sample12_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample13_offset = sample13_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample14_offset = sample14_uv * tex_uv_to_pixel_scale - dest_pixel;
    vec2 sample15_offset = sample15_uv * tex_uv_to_pixel_scale - dest_pixel;
    //  Compute Gaussian sample weights:
    float w0 = exp(-LENGTH_SQ(sample0_offset) * denom_inv);
    float w1 = exp(-LENGTH_SQ(sample1_offset) * denom_inv);
    float w2 = exp(-LENGTH_SQ(sample2_offset) * denom_inv);
    float w3 = exp(-LENGTH_SQ(sample3_offset) * denom_inv);
    float w4 = exp(-LENGTH_SQ(sample4_offset) * denom_inv);
    float w5 = exp(-LENGTH_SQ(sample5_offset) * denom_inv);
    float w6 = exp(-LENGTH_SQ(sample6_offset) * denom_inv);
    float w7 = exp(-LENGTH_SQ(sample7_offset) * denom_inv);
    float w8 = exp(-LENGTH_SQ(sample8_offset) * denom_inv);
    float w9 = exp(-LENGTH_SQ(sample9_offset) * denom_inv);
    float w10 = exp(-LENGTH_SQ(sample10_offset) * denom_inv);
    float w11 = exp(-LENGTH_SQ(sample11_offset) * denom_inv);
    float w12 = exp(-LENGTH_SQ(sample12_offset) * denom_inv);
    float w13 = exp(-LENGTH_SQ(sample13_offset) * denom_inv);
    float w14 = exp(-LENGTH_SQ(sample14_offset) * denom_inv);
    float w15 = exp(-LENGTH_SQ(sample15_offset) * denom_inv);
    float weight_sum_inv = 1.0/(
        w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7 +
        w8 +w9 + w10 + w11 + w12 + w13 + w14 + w15);
    //  Weight and sum the samples:
    vec3 sum = w0 * sample0 + w1 * sample1 + w2 * sample2 + w3 * sample3 +
        w4 * sample4 + w5 * sample5 + w6 * sample6 + w7 * sample7 +
        w8 * sample8 + w9 * sample9 + w10 * sample10 + w11 * sample11 +
        w12 * sample12 + w13 * sample13 + w14 * sample14 + w15 * sample15;
    return sum * weight_sum_inv;
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
COMPAT_VARYING float estimated_viewport_size_x;
COMPAT_VARYING vec2 blur_dxdy;
COMPAT_VARYING vec2 uv_scanline_step;
COMPAT_VARYING vec2 texture_size_inv;
COMPAT_VARYING vec2 tex_uv_to_pixel_scale;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 Pass1TextureSize;
#define ORIG_LINEARIZEDSize vec4(Pass1TextureSize, 1.0 / Pass1TextureSize)
uniform COMPAT_PRECISION vec2 Pass1InputSize;

// compatibility #defines
#define tex_uv TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
	
    //  This vertex shader copies blurs/vertex-shader-blur-one-pass-resize.h,
    //  except we're using a different source image.
   vec2 video_uv = TexCoord.xy * SourceSize.xy / InputSize.xy;
   tex_uv = video_uv * Pass1InputSize / Pass1TextureSize;
    //  The last pass (vertical scanlines) had a viewport y scale, so we can
    //  use it to calculate a better runtime sigma:
	estimated_viewport_size_x = SourceSize.y * geom_aspect_ratio_x / geom_aspect_ratio_y;
   
    //  Get the uv sample distance between output pixels.  We're using a resize
    //  blur, so arbitrary upsizing will be acceptable if filter_linearN =
    //  "true," and arbitrary downsizing will be acceptable if mipmap_inputN =
    //  "true" too.  The blur will be much more accurate if a true 4x4 Gaussian
    //  resize is used instead of tex2Dblur3x3_resize (which samples between
    //  texels even for upsizing).
	vec2 dxdy_min_scale = Pass1InputSize.xy * OutSize.zw;
    texture_size_inv = ORIG_LINEARIZEDSize.zw;
    if(bloom_approx_filter > 1.5)   //  4x4 true Gaussian resize
    {
        //  For upsizing, we'll snap to texels and sample the nearest 4.
        vec2 dxdy_scale = max(dxdy_min_scale, vec2(1.0));
        blur_dxdy = dxdy_scale * texture_size_inv;
    }
    else
    {
        vec2 dxdy_scale = dxdy_min_scale;
        blur_dxdy = dxdy_scale * texture_size_inv;
	}
	
	tex_uv_to_pixel_scale = OutSize.xy * Pass1TextureSize.xy / Pass1InputSize.xy;
//  texture_size_inv = texture_size_inv; <- commented out because it's pointless in this admittedly sloppy port

    //  Detecting interlacing again here lets us apply convergence offsets in
    //  this pass.  il_step_multiple contains the (texel, scanline) step
    //  multiple: 1 for progressive, 2 for interlaced.
    vec2 orig_video_size = Pass1InputSize.xy;
	float interlace_check = 0.0;
	if (is_interlaced(orig_video_size.y) == true) interlace_check = 1.0;
    float y_step = 1.0 + interlace_check;
    vec2 il_step_multiple = vec2(1.0, y_step);
    //  Get the uv distance between (texels, same-field scanlines):
    uv_scanline_step = il_step_multiple * ORIG_LINEARIZEDSize.zw;
}

#elif defined(FRAGMENT)
#pragma format R8G8B8A8_SRGB

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
uniform sampler2D Pass1Texture;
#define ORIG_LINEARIZED Pass1Texture
uniform COMPAT_PRECISION vec2 Pass1TextureSize;
#define ORIG_LINEARIZEDSize vec4(Pass1TextureSize, 1.0 / Pass1TextureSize)
uniform COMPAT_PRECISION vec2 Pass1InputSize;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING float estimated_viewport_size_x;
COMPAT_VARYING vec2 blur_dxdy;
COMPAT_VARYING vec2 uv_scanline_step;
COMPAT_VARYING vec2 texture_size_inv;
COMPAT_VARYING vec2 tex_uv_to_pixel_scale;

// compatibility #defines
#define Source Texture
#define tex_uv TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    //  Would a viewport-relative size work better for this pass?  (No.)
    //  PROS:
    //  1.) Instead of writing an absolute size to user-cgp-constants.h, we'd
    //      write a viewport scale.  That number could be used to directly scale
    //      the viewport-resolution bloom sigma and/or triad size to a smaller
    //      scale.  This way, we could calculate an optimal dynamic sigma no
    //      matter how the dot pitch is specified.
    //  CONS:
    //  1.) Texel smearing would be much worse at small viewport sizes, but
    //      performance would be much worse at large viewport sizes, so there
    //      would be no easy way to calculate a decent scale.
    //  2.) Worse, we could no longer get away with using a constant-size blur!
    //      Instead, we'd have to face all the same difficulties as the real
    //      phosphor bloom, which requires static #ifdefs to decide the blur
    //      size based on the expected triad size...a dynamic value.
    //  3.) Like the phosphor bloom, we'd have less control over making the blur
    //      size correct for an optical blur.  That said, we likely overblur (to
    //      maintain brightness) more than the eye would do by itself: 20/20
    //      human vision distinguishes ~1 arc minute, or 1/60 of a degree.  The
    //      highest viewing angle recommendation I know of is THX's 40.04 degree
    //      recommendation, at which 20/20 vision can distinguish about 2402.4
    //      lines.  Assuming the "TV lines" definition, that means 1201.2
    //      distinct light lines and 1201.2 distinct dark lines can be told
    //      apart, i.e. 1201.2 pairs of lines.  This would correspond to 1201.2
    //      pairs of alternating lit/unlit phosphors, so 2402.4 phosphors total
    //      (if they're alternately lit).  That's a max of 800.8 triads.  Using
    //      a more popular 30 degree viewing angle recommendation, 20/20 vision
    //      can distinguish 1800 lines, or 600 triads of alternately lit
    //      phosphors.  In contrast, we currently blur phosphors all the way
    //      down to 341.3 triads to ensure full brightness.
    //  4.) Realistically speaking, we're usually just going to use bilinear
    //      filtering in this pass anyway, but it only works well to limit
    //      bandwidth if it's done at a small constant scale.
    
    //  Get the constants we need to sample:
	vec2 texture_size = ORIG_LINEARIZEDSize.xy;
	vec2 tex_uv_r, tex_uv_g, tex_uv_b;
	
	if(beam_misconvergence == true)
    {
        vec2 convergence_offsets_r = vec2(convergence_offset_x_r, convergence_offset_y_r);//get_convergence_offsets_r_vector();
        vec2 convergence_offsets_g = vec2(convergence_offset_x_g, convergence_offset_y_g);//get_convergence_offsets_g_vector();
        vec2 convergence_offsets_b = vec2(convergence_offset_x_b, convergence_offset_y_b);//get_convergence_offsets_b_vector();
        tex_uv_r = tex_uv - vec2(convergence_offset_x_r, convergence_offset_y_r) * uv_scanline_step;
        tex_uv_g = tex_uv - vec2(convergence_offset_x_g, convergence_offset_y_g) * uv_scanline_step;
        tex_uv_b = tex_uv - vec2(convergence_offset_x_b, convergence_offset_y_b) * uv_scanline_step;
    }
	//  Get the blur sigma:
    float bloom_approx_sigma = get_bloom_approx_sigma(OutputSize.x, estimated_viewport_size_x);
	
	//  Sample the resized and blurred texture, and apply convergence offsets if
    //  necessary.  Applying convergence offsets here triples our samples from
    //  16/9/1 to 48/27/3, but faster and easier than sampling BLOOM_APPROX and
    //  HALATION_BLUR 3 times at full resolution every time they're used.
    vec3 color_r, color_g, color_b, color;
	if(bloom_approx_filter > 1.5)
    {
        //  Use a 4x4 Gaussian resize.  This is slower but technically correct.
        if(beam_misconvergence == true)
        {
            color_r = tex2Dresize_gaussian4x4(ORIG_LINEARIZED, tex_uv_r,
                blur_dxdy, texture_size, texture_size_inv,
                tex_uv_to_pixel_scale, bloom_approx_sigma);
            color_g = tex2Dresize_gaussian4x4(ORIG_LINEARIZED, tex_uv_g,
                blur_dxdy, texture_size, texture_size_inv,
                tex_uv_to_pixel_scale, bloom_approx_sigma);
            color_b = tex2Dresize_gaussian4x4(ORIG_LINEARIZED, tex_uv_b,
                blur_dxdy, texture_size, texture_size_inv,
                tex_uv_to_pixel_scale, bloom_approx_sigma);
        }
        else
        {
            color = tex2Dresize_gaussian4x4(ORIG_LINEARIZED, tex_uv,
                blur_dxdy, texture_size, texture_size_inv,
                tex_uv_to_pixel_scale, bloom_approx_sigma);
        }
    }
    else if(bloom_approx_filter > 0.5)
    {
        //  Use a 3x3 resize blur.  This is the softest option, because we're
        //  blurring already blurry bilinear samples.  It doesn't play quite as
        //  nicely with convergence offsets, but it has its charms.
        if(beam_misconvergence == true)
        {
            color_r = tex2Dblur3x3resize(ORIG_LINEARIZED, tex_uv_r,
                blur_dxdy, bloom_approx_sigma);
            color_g = tex2Dblur3x3resize(ORIG_LINEARIZED, tex_uv_g,
                blur_dxdy, bloom_approx_sigma);
            color_b = tex2Dblur3x3resize(ORIG_LINEARIZED, tex_uv_b,
                blur_dxdy, bloom_approx_sigma);
        }
        else
        {
            color = tex2Dblur3x3resize(ORIG_LINEARIZED, tex_uv, blur_dxdy);
        }
    }
    else
    {
        //  Use bilinear sampling.  This approximates a 4x4 Gaussian resize MUCH
        //  better than tex2Dblur3x3_resize for the very small sigmas we're
        //  likely to use at small output resolutions.  (This estimate becomes
        //  too sharp above ~400x300, but the blurs break down above that
        //  resolution too, unless min_allowed_viewport_triads is high enough to
        //  keep bloom_approx_scale_x/min_allowed_viewport_triads < ~1.1658025.)
        if(beam_misconvergence == true)
        {
            color_r = tex2D_linearize(ORIG_LINEARIZED, tex_uv_r).rgb;
            color_g = tex2D_linearize(ORIG_LINEARIZED, tex_uv_g).rgb;
            color_b = tex2D_linearize(ORIG_LINEARIZED, tex_uv_b).rgb;
        }
        else
        {
            color = tex2D_linearize(ORIG_LINEARIZED, tex_uv).rgb;
        }
    }
	//  Pack the colors from the red/green/blue beams into a single vector:
    if(beam_misconvergence == true)
    {
        color = vec3(color_r.r, color_g.g, color_b.b);
    }
    //  Encode and output the blurred image:
   FragColor = vec4(color, 1.0);//vec4(texture(ORIG_LINEARIZED, tex_uv));//
} 
#endif
