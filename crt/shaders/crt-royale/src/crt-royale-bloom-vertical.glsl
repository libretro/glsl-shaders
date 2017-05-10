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

//////////   BEGIN #include phosphor-mask-resizing.h   ////////////////

#ifndef PHOSPHOR_MASK_RESIZING_H
#define PHOSPHOR_MASK_RESIZING_H

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


//////////////////////////////////  INCLUDES  //////////////////////////////////

//#include "../user-settings.h"
//#include "derived-settings-and-constants.h"

/////////////////////////////  CODEPATH SELECTION  /////////////////////////////

//  Choose a looping strategy based on what's allowed:
//  Dynamic loops not allowed: Use a flat static loop.
//  Dynamic loops accomodated: Coarsely branch around static loops.
//  Dynamic loops assumed allowed: Use a flat dynamic loop.
#ifndef DRIVERS_ALLOW_DYNAMIC_BRANCHES
    #ifdef ACCOMODATE_POSSIBLE_DYNAMIC_LOOPS
        #define BREAK_LOOPS_INTO_PIECES
    #else
        #define USE_SINGLE_STATIC_LOOP
    #endif
#endif  //  No else needed: Dynamic loops assumed.


    #define CALCULATE_R_COORD_FOR_4_SAMPLES                                    \
        vec4 true_i = vec4(i_base + i) + vec4(0.0, 1.0, 2.0, 3.0); \
        vec4 tile_uv_r = fract(                                         \
            first_texel_tile_uv_rrrr + true_i * tile_dr);                      \
        vec4 tex_uv_r = tile_uv_r * tile_size_uv_r;

    #define VERTICAL_SINC_RESAMPLE_LOOP_BODY                                   \
        CALCULATE_R_COORD_FOR_4_SAMPLES;                                       \
        vec3 new_sample0 = tex2Dlod0try(texture,                       \
            vec2(tex_uv.x, tex_uv_r.x)).rgb;                                 \
        vec3 new_sample1 = tex2Dlod0try(texture,                       \
            vec2(tex_uv.x, tex_uv_r.y)).rgb;                                 \
        vec3 new_sample2 = tex2Dlod0try(texture,                       \
            vec2(tex_uv.x, tex_uv_r.z)).rgb;                                 \
        vec3 new_sample3 = tex2Dlod0try(texture,                       \
            vec2(tex_uv.x, tex_uv_r.w)).rgb;                                 \
        UPDATE_COLOR_AND_WEIGHT_SUMS;
		
	#define UPDATE_COLOR_AND_WEIGHT_SUMS                                       \
        vec4 dist = magnification_scale *                              \
            abs(first_dist_unscaled - true_i);                                 \
        vec4 pi_dist = pi * dist;                                      \
        CALCULATE_SINC_RESAMPLE_WEIGHTS;                                       \
        pixel_color += new_sample0 * weights.xxx;                              \
        pixel_color += new_sample1 * weights.yyy;                              \
        pixel_color += new_sample2 * weights.zzz;                              \
        pixel_color += new_sample3 * weights.www;                              \
        weight_sum += weights;
		
	#ifdef PHOSPHOR_MASK_RESIZE_LANCZOS_WINDOW
        #define CALCULATE_SINC_RESAMPLE_WEIGHTS                                \
            vec4 pi_dist_over_lobes = pi_over_lobes * dist;            \
            vec4 weights = min(sin(pi_dist) * sin(pi_dist_over_lobes) /\
                (pi_dist*pi_dist_over_lobes), vec4(1.0));
    #else
        #define CALCULATE_SINC_RESAMPLE_WEIGHTS                                \
            vec4 weights = min(sin(pi_dist)/pi_dist, vec4(1.0));
    #endif
	
	#define HORIZONTAL_SINC_RESAMPLE_LOOP_BODY                                 \
        CALCULATE_R_COORD_FOR_4_SAMPLES;                                       \
        vec3 new_sample0 = tex2Dlod0try(texture,                       \
            vec2(tex_uv_r.x, tex_uv.y)).rgb;                                 \
        vec3 new_sample1 = tex2Dlod0try(texture,                       \
            vec2(tex_uv_r.y, tex_uv.y)).rgb;                                 \
        vec3 new_sample2 = tex2Dlod0try(texture,                       \
            vec2(tex_uv_r.z, tex_uv.y)).rgb;                                 \
        vec3 new_sample3 = tex2Dlod0try(texture,                       \
            vec2(tex_uv_r.w, tex_uv.y)).rgb;                                 \
        UPDATE_COLOR_AND_WEIGHT_SUMS;

//////////////////////////////////  CONSTANTS  /////////////////////////////////

//  The larger the resized tile, the fewer samples we'll need for downsizing.
//  See if we can get a static min tile size > mask_min_allowed_tile_size:
float mask_min_allowed_tile_size = ceil(
    mask_min_allowed_triad_size * mask_triads_per_tile);
float mask_min_expected_tile_size = 
        mask_min_allowed_tile_size;
//  Limit the number of sinc resize taps by the maximum minification factor:
float pi_over_lobes = pi/mask_sinc_lobes;
float max_sinc_resize_samples_float = 2.0 * mask_sinc_lobes *
    mask_resize_src_lut_size.x/mask_min_expected_tile_size;
//  Vectorized loops sample in multiples of 4.  Round up to be safe:
float max_sinc_resize_samples_m4 = ceil(
    max_sinc_resize_samples_float * 0.25) * 4.0;
	
	/////////////////////////  RESAMPLING FUNCTION HELPERS  ////////////////////////

float get_dynamic_loop_size(float magnification_scale)
{
    //  Requires:   The following global constants must be defined:
    //              1.) mask_sinc_lobes
    //              2.) max_sinc_resize_samples_m4
    //  Returns:    The minimum number of texture samples for a correct downsize
    //              at magnification_scale.
    //  We're downsizing, so the filter is sized across 2*lobes output pixels
    //  (not 2*lobes input texels).  This impacts distance measurements and the
    //  minimum number of input samples needed.
    float min_samples_float = 2.0 * mask_sinc_lobes / magnification_scale;
    float min_samples_m4 = ceil(min_samples_float * 0.25) * 4.0;
    #ifdef DRIVERS_ALLOW_DYNAMIC_BRANCHES
        float max_samples_m4 = max_sinc_resize_samples_m4;
    #else   // ifdef BREAK_LOOPS_INTO_PIECES
        //  Simulating loops with branches imposes a 128-sample limit.
        float max_samples_m4 = min(128.0, max_sinc_resize_samples_m4);
    #endif
    return min(min_samples_m4, max_samples_m4);
}

vec2 get_first_texel_tile_uv_and_dist(vec2 tex_uv, 
    vec2 texture_size, float dr, 
    float input_tiles_per_texture_r, float samples,
    bool vertical)
{
    //  Requires:   1.) dr == du == 1.0/texture_size.x or
    //                  dr == dv == 1.0/texture_size.y
    //                  (whichever direction we're resampling in).
    //                  It's a scalar to save register space.
    //              2.) input_tiles_per_texture_r is the number of input tiles
    //                  that can fit in the input texture in the direction we're
    //                  resampling this pass.
    //              3.) vertical indicates whether we're resampling vertically
    //                  this pass (or horizontally).
    //  Returns:    Pack and return the first sample's tile_uv coord in [0, 1]
    //              and its texel distance from the destination pixel, in the
    //              resized dimension only.
    //  We'll start with the topmost or leftmost sample and work down or right,
    //  so get the first sample location and distance.  Modify both dimensions
    //  as if we're doing a one-pass 2D resize; we'll throw away the unneeded
    //  (and incorrect) dimension at the end.
    vec2 curr_texel = tex_uv * texture_size;
    vec2 prev_texel =
        floor(curr_texel - vec2(under_half)) + vec2(0.5);
    vec2 first_texel = prev_texel - vec2(samples/2.0 - 1.0);
    vec2 first_texel_uv_wrap_2D = first_texel * dr;
    vec2 first_texel_dist_2D = curr_texel - first_texel;
    //  Convert from tex_uv to tile_uv coords so we can sub fracts for fmods.
    vec2 first_texel_tile_uv_wrap_2D =
        first_texel_uv_wrap_2D * input_tiles_per_texture_r;
    //  Project wrapped coordinates to the [0, 1] range.  We'll do this with all
    //  samples,but the first texel is special, since it might be negative.
    vec2 coord_negative = vec2(0.0);
        if(first_texel_tile_uv_wrap_2D.x < 0.0) coord_negative.x = first_texel_tile_uv_wrap_2D.x;
		if(first_texel_tile_uv_wrap_2D.x < 0.0) coord_negative.y = first_texel_tile_uv_wrap_2D.y;
    vec2 first_texel_tile_uv_2D =
        fract(first_texel_tile_uv_wrap_2D) + coord_negative;
    //  Pack the first texel's tile_uv coord and texel distance in 1D:
    vec2 tile_u_and_dist =
        vec2(first_texel_tile_uv_2D.x, first_texel_dist_2D.x);
    vec2 tile_v_and_dist =
        vec2(first_texel_tile_uv_2D.y, first_texel_dist_2D.y);
    return vertical ? tile_v_and_dist : tile_u_and_dist;
    //return mix(tile_u_and_dist, tile_v_and_dist, float(vertical));
}

vec4 tex2Dlod0try(sampler2D tex, vec2 tex_uv)
{
    //  Mipmapping and anisotropic filtering get confused by sinc-resampling.
    //  One [slow] workaround is to select the lowest mip level:
    #ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DLOD
        return tex2Dlod(tex, vec4(tex_uv, 0.0, 0.0));
    #else
        #ifdef ANISOTROPIC_RESAMPLING_COMPAT_TEX2DBIAS
            return tex2Dbias(tex, vec4(tex_uv, 0.0, -16.0));
        #else
            return texture(tex, tex_uv);
        #endif
    #endif
}
	
////////////////////////////  TILE SIZE CALCULATION  ///////////////////////////

vec2 get_resized_mask_tile_size(vec2 estimated_viewport_size,
    vec2 estimated_mask_resize_output_size,
    bool solemnly_swear_same_inputs_for_every_pass)
{
    //  Requires:   The following global constants must be defined according to
    //              certain constraints:
    //              1.) mask_resize_num_triads: Must be high enough that our
    //                  mask sampling method won't have artifacts later
    //                  (long story; see derived-settings-and-constants.h)
    //              2.) mask_resize_src_lut_size: Texel size of our mask LUT
    //              3.) mask_triads_per_tile: Num horizontal triads in our LUT
    //              4.) mask_min_allowed_triad_size: User setting (the more
    //                  restrictive it is, the faster the resize will go)
    //              5.) mask_min_allowed_tile_size_x < mask_resize_src_lut_size.x
    //              6.) mask_triad_size_desired_{runtime, static}
    //              7.) mask_num_triads_desired_{runtime, static}
    //              8.) mask_specify_num_triads must be 0.0/1.0 (false/true)
    //              The function parameters must be defined as follows:
    //              1.) estimated_viewport_size == (final viewport size);
    //                  If mask_specify_num_triads is 1.0/true and the viewport
    //                  estimate is wrong, the number of triads will differ from
    //                  the user's preference by about the same factor.
    //              2.) estimated_mask_resize_output_size: Must equal the
    //                  output size of the MASK_RESIZE pass.
    //                  Exception: The x component may be estimated garbage if
    //                  and only if the caller throws away the x result.
    //              3.) solemnly_swear_same_inputs_for_every_pass: Set to false,
    //                  unless you can guarantee that every call across every
    //                  pass will use the same sizes for the other parameters.
    //              When calling this across multiple passes, always use the
    //              same y viewport size/scale, and always use the same x
    //              viewport size/scale when using the x result.
    //  Returns:    Return the final size of a manually resized mask tile, after
    //              constraining the desired size to avoid artifacts.  Under
    //              unusual circumstances, tiles may become stretched vertically
    //              (see wall of text below).
    //  Stated tile properties must be correct:
    float tile_aspect_ratio_inv =
        mask_resize_src_lut_size.y/mask_resize_src_lut_size.x;
    float tile_aspect_ratio = 1.0/tile_aspect_ratio_inv;
    vec2 tile_aspect = vec2(1.0, tile_aspect_ratio_inv);
    //  If mask_specify_num_triads is 1.0/true and estimated_viewport_size.x is
    //  wrong, the user preference will be misinterpreted:
    float desired_tile_size_x = mask_triads_per_tile * mix(
        mask_triad_size_desired,
        estimated_viewport_size.x / mask_num_triads_desired,
        mask_specify_num_triads);
    if(mask_sample_mode_desired > 0.5)
    {
        //  We don't need constraints unless we're sampling MASK_RESIZE.
        return desired_tile_size_x * tile_aspect;
    }
    //  Make sure we're not upsizing:
    float temp_tile_size_x =
        min(desired_tile_size_x, mask_resize_src_lut_size.x);
    //  Enforce min_tile_size and max_tile_size in both dimensions:
    vec2 temp_tile_size = temp_tile_size_x * tile_aspect;
    vec2 min_tile_size =
        mask_min_allowed_tile_size * tile_aspect;
    vec2 max_tile_size =
        estimated_mask_resize_output_size / mask_resize_num_tiles;
    vec2 clamped_tile_size =
        clamp(temp_tile_size, min_tile_size, max_tile_size);
    //  Try to maintain tile_aspect_ratio.  This is the tricky part:
    //  If we're currently resizing in the y dimension, the x components
    //  could be MEANINGLESS.  (If estimated_mask_resize_output_size.x is
    //  bogus, then so is max_tile_size.x and clamped_tile_size.x.)
    //  We can't adjust the y size based on clamped_tile_size.x.  If it
    //  clamps when it shouldn't, it won't clamp again when later passes
    //  call this function with the correct sizes, and the discrepancy will
    //  break the sampling coords in MASKED_SCANLINES.  Instead, we'll limit
    //  the x size based on the y size, but not vice versa, unless the
    //  caller swears the parameters were the same (correct) in every pass.
    //  As a result, triads could appear vertically stretched if:
    //  a.) mask_resize_src_lut_size.x > mask_resize_src_lut_size.y: Wide
    //      LUT's might clamp x more than y (all provided LUT's are square)
    //  b.) true_viewport_size.x < true_viewport_size.y: The user is playing
    //      with a vertically oriented screen (not accounted for anyway)
    //  c.) mask_resize_viewport_scale.x < masked_resize_viewport_scale.y:
    //      Viewport scales are equal by default.
    //  If any of these are the case, you can fix the stretching by setting:
    //      mask_resize_viewport_scale.x = mask_resize_viewport_scale.y *
    //          (1.0 / min_expected_aspect_ratio) *
    //          (mask_resize_src_lut_size.x / mask_resize_src_lut_size.y)
    float x_tile_size_from_y =
        clamped_tile_size.y * tile_aspect_ratio;
    float y_tile_size_from_x = mix(clamped_tile_size.y,
        clamped_tile_size.x * tile_aspect_ratio_inv,
        float(solemnly_swear_same_inputs_for_every_pass));
    vec2 reclamped_tile_size = vec2(
        min(clamped_tile_size.x, x_tile_size_from_y),
        min(clamped_tile_size.y, y_tile_size_from_x));
    //  We need integer tile sizes in both directions for tiled sampling to
    //  work correctly.  Use floor (to make sure we don't round up), but be
    //  careful to avoid a rounding bug where floor decreases whole numbers:
    vec2 final_resized_tile_size =
        floor(reclamped_tile_size + vec2(FIX_ZERO(0.0)));
    return final_resized_tile_size;
}

/////////////////////////  FINAL MASK SAMPLING HELPERS  ////////////////////////

vec4 get_mask_sampling_parameters(vec2 mask_resize_texture_size,
    vec2 mask_resize_video_size, vec2 true_viewport_size,
    out vec2 mask_tiles_per_screen)
{
    //  Requires:   1.) Requirements of get_resized_mask_tile_size() must be
    //                  met, particularly regarding global constants.
    //              The function parameters must be defined as follows:
    //              1.) mask_resize_texture_size == MASK_RESIZE.texture_size
    //                  if get_mask_sample_mode() is 0 (otherwise anything)
    //              2.) mask_resize_video_size == MASK_RESIZE.video_size
    //                  if get_mask_sample_mode() is 0 (otherwise anything)
    //              3.) true_viewport_size == IN.output_size for a pass set to
    //                  1.0 viewport scale (i.e. it must be correct)
    //  Returns:    Return a vec4 containing:
    //                  xy: tex_uv coords for the start of the mask tile
    //                  zw: tex_uv size of the mask tile from start to end
    //              mask_tiles_per_screen is an out parameter containing the
    //              number of mask tiles that will fit on the screen.
    //  First get the final resized tile size.  The viewport size and mask
    //  resize viewport scale must be correct, but don't solemnly swear they
    //  were correct in both mask resize passes unless you know it's true.
    //  (We can better ensure a correct tile aspect ratio if the parameters are
    //  guaranteed correct in all passes...but if we lie, we'll get inconsistent
    //  sizes across passes, resulting in broken texture coordinates.)
    float mask_sample_mode = mask_sample_mode_desired;//get_mask_sample_mode();
    vec2 mask_resize_tile_size = get_resized_mask_tile_size(
        true_viewport_size, mask_resize_video_size, false);
    if(mask_sample_mode < 0.5)
    {
        //  Sample MASK_RESIZE: The resized tile is a fracttion of the texture
        //  size and starts at a nonzero offset to allow for border texels:
        vec2 mask_tile_uv_size = mask_resize_tile_size /
            mask_resize_texture_size;
        vec2 skipped_tiles = mask_start_texels/mask_resize_tile_size;
        vec2 mask_tile_start_uv = skipped_tiles * mask_tile_uv_size;
        //  mask_tiles_per_screen must be based on the *true* viewport size:
        mask_tiles_per_screen = true_viewport_size / mask_resize_tile_size;
        return vec4(mask_tile_start_uv, mask_tile_uv_size);
    }
    else
    {
        //  If we're tiling at the original size (1:1 pixel:texel), redefine a
        //  "tile" to be the full texture containing many triads.  Otherwise,
        //  we're hardware-resampling an LUT, and the texture truly contains a
        //  single unresized phosphor mask tile anyway.
        vec2 mask_tile_uv_size = vec2(1.0);
        vec2 mask_tile_start_uv = vec2(0.0);
        if(mask_sample_mode > 1.5)
        {
            //  Repeat the full LUT at a 1:1 pixel:texel ratio without resizing:
            mask_tiles_per_screen = true_viewport_size/mask_texture_large_size;
        }
        else
        {
            //  Hardware-resize the original LUT:
            mask_tiles_per_screen = true_viewport_size / mask_resize_tile_size;
        }
        return vec4(mask_tile_start_uv, mask_tile_uv_size);
    }
}

////////////////////////////  RESAMPLING FUNCTIONS  ////////////////////////////

vec3 downsample_vertical_sinc_tiled(sampler2D texture,
    vec2 tex_uv, vec2 texture_size, float dr,
    float magnification_scale, float tile_size_uv_r)
{
    //  Requires:   1.) dr == du == 1.0/texture_size.x or
    //                  dr == dv == 1.0/texture_size.y
    //                  (whichever direction we're resampling in).
    //                  It's a scalar to save register space.
    //              2.) tile_size_uv_r is the number of texels an input tile
    //                  takes up in the input texture, in the direction we're
    //                  resampling this pass.
    //              3.) magnification_scale must be <= 1.0.
    //  Returns:    Return a [Lanczos] sinc-resampled pixel of a vertically
    //              downsized input tile embedded in an input texture.  (The
    //              vertical version is special-cased though: It assumes the
    //              tile size equals the [static] texture size, since it's used
    //              on an LUT texture input containing one tile.  For more
    //              generic use, eliminate the "static" in the parameters.)
    //  The "r" in "dr," "tile_size_uv_r," etc. refers to the dimension
    //  we're resizing along, e.g. "dy" in this case.
    #ifdef USE_SINGLE_STATIC_LOOP
        //  A static loop can be faster, but it might blur too much from using
        //  more samples than it should.
        int samples = int(max_sinc_resize_samples_m4);
    #else
        int samples = int(get_dynamic_loop_size(magnification_scale));
    #endif

    //  Get the first sample location (scalar tile uv coord along the resized
    //  dimension) and distance from the output location (in texels):
    float input_tiles_per_texture_r = 1.0/tile_size_uv_r;
    //  true = vertical resize:
    vec2 first_texel_tile_r_and_dist = get_first_texel_tile_uv_and_dist(
        tex_uv, texture_size, dr, input_tiles_per_texture_r, samples, true);
    vec4 first_texel_tile_uv_rrrr = first_texel_tile_r_and_dist.xxxx;
    vec4 first_dist_unscaled = first_texel_tile_r_and_dist.yyyy;
    //  Get the tile sample offset:
    float tile_dr = dr * input_tiles_per_texture_r;

    //  Sum up each weight and weighted sample color, varying the looping
    //  strategy based on our expected dynamic loop capabilities.  See the
    //  loop body macros above.
    int i_base = 0;
    vec4 weight_sum = vec4(0.0);
    vec3 pixel_color = vec3(0.0);
    int i_step = 4;
    #ifdef BREAK_LOOPS_INTO_PIECES
        if(samples - i_base >= 64)
        {
            for(int i = 0; i < 64; i += i_step)
            {
                VERTICAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 64;
        }
        if(samples - i_base >= 32)
        {
            for(int i = 0; i < 32; i += i_step)
            {
                VERTICAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 32;
        }
        if(samples - i_base >= 16)
        {
            for(int i = 0; i < 16; i += i_step)
            {
                VERTICAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 16;
        }
        if(samples - i_base >= 8)
        {
            for(int i = 0; i < 8; i += i_step)
            {
                VERTICAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 8;
        }
        if(samples - i_base >= 4)
        {
            for(int i = 0; i < 4; i += i_step)
            {
                VERTICAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 4;
        }
        //  Do another 4-sample block for a total of 128 max samples.
        if(samples - i_base > 0)
        {
            for(int i = 0; i < 4; i += i_step)
            {
                VERTICAL_SINC_RESAMPLE_LOOP_BODY;
            }
        }
    #else
        for(int i = 0; i < samples; i += i_step)
        {
            VERTICAL_SINC_RESAMPLE_LOOP_BODY;
        }
    #endif
    //  Normalize so the weight_sum == 1.0, and return:
    vec2 weight_sum_reduce = weight_sum.xy + weight_sum.zw;
    vec3 scalar_weight_sum = vec3(weight_sum_reduce.x + 
        weight_sum_reduce.y);
    return (pixel_color/scalar_weight_sum);
}

vec3 downsample_horizontal_sinc_tiled(sampler2D texture,
    vec2 tex_uv, vec2 texture_size, float dr,
    float magnification_scale, float tile_size_uv_r)
{
    //  Differences from downsample_horizontal_sinc_tiled:
    //  1.) The dr and tile_size_uv_r parameters are not static consts.
    //  2.) The "vertical" parameter to get_first_texel_tile_uv_and_dist is
    //      set to false instead of true.
    //  3.) The horizontal version of the loop body is used.
    //  TODO: If we can get guaranteed compile-time dead code elimination,
    //  we can combine the vertical/horizontal downsampling functions by:
    //  1.) Add an extra static bool parameter called "vertical."
    //  2.) Supply it with the result of get_first_texel_tile_uv_and_dist().
    //  3.) Use a conditional assignment in the loop body macro.  This is the
    //      tricky part: We DO NOT want to incur the extra conditional
    //      assignment in the inner loop at runtime!
    //  The "r" in "dr," "tile_size_uv_r," etc. refers to the dimension
    //  we're resizing along, e.g. "dx" in this case.
    #ifdef USE_SINGLE_STATIC_LOOP
        //  If we have to load all samples, we might as well use them.
        int samples = int(max_sinc_resize_samples_m4);
    #else
        int samples = int(get_dynamic_loop_size(magnification_scale));
    #endif

    //  Get the first sample location (scalar tile uv coord along resized
    //  dimension) and distance from the output location (in texels):
    float input_tiles_per_texture_r = 1.0/tile_size_uv_r;
    //  false = horizontal resize:
    vec2 first_texel_tile_r_and_dist = get_first_texel_tile_uv_and_dist(
        tex_uv, texture_size, dr, input_tiles_per_texture_r, samples, false);
    vec4 first_texel_tile_uv_rrrr = first_texel_tile_r_and_dist.xxxx;
    vec4 first_dist_unscaled = first_texel_tile_r_and_dist.yyyy;
    //  Get the tile sample offset:
    float tile_dr = dr * input_tiles_per_texture_r;

    //  Sum up each weight and weighted sample color, varying the looping
    //  strategy based on our expected dynamic loop capabilities.  See the
    //  loop body macros above.
    int i_base = 0;
    vec4 weight_sum = vec4(0.0);
    vec3 pixel_color = vec3(0.0);
    int i_step = 4;
    #ifdef BREAK_LOOPS_INTO_PIECES
        if(samples - i_base >= 64)
        {
            for(int i = 0; i < 64; i += i_step)
            {
                HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 64;
        }
        if(samples - i_base >= 32)
        {
            for(int i = 0; i < 32; i += i_step)
            {
                HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 32;
        }
        if(samples - i_base >= 16)
        {
            for(int i = 0; i < 16; i += i_step)
            {
                HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 16;
        }
        if(samples - i_base >= 8)
        {
            for(int i = 0; i < 8; i += i_step)
            {
                HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 8;
        }
        if(samples - i_base >= 4)
        {
            for(int i = 0; i < 4; i += i_step)
            {
                HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
            }
            i_base += 4;
        }
        //  Do another 4-sample block for a total of 128 max samples.
        if(samples - i_base > 0)
        {
            for(int i = 0; i < 4; i += i_step)
            {
                HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
            }
        }
    #else
        for(int i = 0; i < samples; i += i_step)
        {
            HORIZONTAL_SINC_RESAMPLE_LOOP_BODY;
        }
    #endif
    //  Normalize so the weight_sum == 1.0, and return:
    vec2 weight_sum_reduce = weight_sum.xy + weight_sum.zw;
    vec3 scalar_weight_sum = vec3(weight_sum_reduce.x +
        weight_sum_reduce.y);
    return (pixel_color/scalar_weight_sum);
}

vec2 convert_phosphor_tile_uv_wrap_to_tex_uv(vec2 tile_uv_wrap,
    vec4 mask_tile_start_uv_and_size)
{
    //  Requires:   1.) tile_uv_wrap contains tile-relative uv coords, where the
    //                  tile spans from [0, 1], such that (0.5, 0.5) is at the
    //                  tile center.  The input coords can range from [0, inf],
    //                  and their fracttional parts map to a repeated tile.
    //                  ("Tile" can mean texture, the video embedded in the
    //                  texture, or some other "tile" embedded in a texture.)
    //              2.) mask_tile_start_uv_and_size.xy contains tex_uv coords
    //                  for the start of the embedded tile in the full texture.
    //              3.) mask_tile_start_uv_and_size.zw contains the [fracttional]
    //                  tex_uv size of the embedded tile in the full texture.
    //  Returns:    Return tex_uv coords (used for texture sampling)
    //              corresponding to tile_uv_wrap.
    if(mask_sample_mode_desired < 0.5)
    {
        //  Manually repeat the resized mask tile to fill the screen:
        //  First get fracttional tile_uv coords.  Using fract/fmod on coords
        //  confuses anisotropic filtering; fix it as user options dictate.
        //  derived-settings-and-constants.h disables incompatible options.
        #ifdef ANISOTROPIC_TILING_COMPAT_TILE_FLAT_TWICE
            vec2 tile_uv = fract(tile_uv_wrap * 0.5) * 2.0;
        #else
            vec2 tile_uv = fract(tile_uv_wrap);
        #endif
        #ifdef ANISOTROPIC_TILING_COMPAT_FIX_DISCONTINUITIES
            vec2 tile_uv_dx = ddx(tile_uv);
            vec2 tile_uv_dy = ddy(tile_uv);
            tile_uv = fix_tiling_discontinuities_normalized(tile_uv,
                tile_uv_dx, tile_uv_dy);
        #endif
        //  The tile is embedded in a padded FBO, and it may start at a
        //  nonzero offset if border texels are used to avoid artifacts:
        vec2 mask_tex_uv = mask_tile_start_uv_and_size.xy +
            tile_uv * mask_tile_start_uv_and_size.zw;
        return mask_tex_uv;
    }
    else
    {
        //  Sample from the input phosphor mask texture with hardware tiling.
        //  If we're tiling at the original size (mode 2), the "tile" is the
        //  whole texture, and it contains a large number of triads mapped with
        //  a 1:1 pixel:texel ratio.  OTHERWISE, the texture contains a single
        //  unresized tile.  tile_uv_wrap already has correct coords for both!
        return tile_uv_wrap;
    }
}

#endif  //  PHOSPHOR_MASK_RESIZING_H
//////////////   END #include phosphor-mask-resizing.h   /////////////////////

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
//    #ifdef RUNTIME_PHOSPHOR_BLOOM_SIGMA
//        return get_fast_gaussian_weight_sum_inv(sigma);
//    #else
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
//    #endif
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
COMPAT_VARYING vec2 bloom_dxdy;
COMPAT_VARYING float bloom_sigma_runtime;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define tex_uv TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
	
    //  Get the uv sample distance between output pixels.  Calculate dxdy like
    //  blurs/vertex-shader-blur-fast-vertical.h.
    vec2 dxdy_scale = InputSize.xy / OutputSize.xy;
    vec2 dxdy = dxdy_scale / TextureSize.xy;
    //  This blur is vertical-only, so zero out the vertical offset:
    bloom_dxdy = vec2(0.0, dxdy.y);

    //  Calculate a runtime bloom_sigma in case it's needed:
    float mask_tile_size_x = get_resized_mask_tile_size(
        OutputSize.xy, OutputSize.xy * mask_resize_viewport_scale, false).x;
    bloom_sigma_runtime = get_min_sigma_to_blur_triad(
        mask_tile_size_x / mask_triads_per_tile, bloom_diff_thresh);
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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 bloom_dxdy;
COMPAT_VARYING float bloom_sigma_runtime;

// compatibility #defines
#define Source Texture
#define tex_uv TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    //  Blur the brightpass horizontally with a 9/17/25/43x blur:
    float bloom_sigma = get_final_bloom_sigma(bloom_sigma_runtime);
    vec3 color = tex2DblurNfast(Source, tex_uv,
        bloom_dxdy, bloom_sigma);
    //  Encode and output the blurred image:
   FragColor = encode_output(vec4(color, 1.0));
} 
#endif
