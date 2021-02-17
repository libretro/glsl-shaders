#version 120

// Parameter lines go here:
#pragma parameter BLOOM_STRENGTH "Glow Strength" 0.45 0.0 0.8 0.05
#pragma parameter OUTPUT_GAMMA "Monitor Gamma" 2.2 1.8 2.6 0.02
#pragma parameter PHOSPHOR_LAYOUT "PHOSPHOR LAYOUT" 4.0 0.0 19.0 1.0
#pragma parameter MASK_INTENSITY "MASK INTENSITY" 0.5 0.0 1.0 0.1

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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
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
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D PassPrev4Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float BLOOM_STRENGTH;
uniform COMPAT_PRECISION float OUTPUT_GAMMA;
uniform COMPAT_PRECISION float PHOSPHOR_LAYOUT;
uniform COMPAT_PRECISION float MASK_INTENSITY;
#else
#define BLOOM_STRENGTH 0.45
#define OUTPUT_GAMMA 2.2
#define PHOSPHOR_LAYOUT 4.0
#define MASK_INTENSITY 0.5
#endif


/*
A collection of CRT mask effects that work with LCD subpixel structures for
small details

author: hunterk
license: public domain

How to use it:

Multiply your image by the vec3 output:
FragColor.rgb *= mask_weights(gl_FragCoord.xy, 1.0, 1);

The function needs to be tiled across the screen using the physical pixels, e.g.
gl_FragCoord (the "vec2 coord" input). In the case of slang shaders, we use
(vTexCoord.st * OutputSize.xy).

The "mask_intensity" (float value between 0.0 and 1.0) is how strong the mask
effect should be. Full-strength red, green and blue subpixels on a white pixel
are the ideal, and are achieved with an intensity of 1.0, though this darkens
the image significantly and may not always be desirable.

The "phosphor_layout" (int value between 0 and 19) determines which phophor
layout to apply. 0 is no mask/passthru.

Many of these mask arrays are adapted from cgwg's crt-geom-deluxe LUTs, and
those have their filenames included for easy identification
*/

vec3 mask_weights(vec2 coord, float mask_intensity, int phosphor_layout){
   vec3 weights = vec3(1.,1.,1.);
   float on = 1.;
   float off = 1.-mask_intensity;
   vec3 red     = vec3(on,  off, off);
   vec3 green   = vec3(off, on,  off);
   vec3 blue    = vec3(off, off, on );
   vec3 magenta = vec3(on,  off, on );
   vec3 yellow  = vec3(on,  on,  off);
   vec3 cyan    = vec3(off, on,  on );
   vec3 black   = vec3(off, off, off);
   vec3 white   = vec3(on,  on,  on );
   int w, z = 0;
   
   // This pattern is used by a few layouts, so we'll define it here
   vec3 aperture_weights = mix(magenta, green, floor(mod(coord.x, 2.0)));
   
   if(phosphor_layout == 0) return weights;

   else if(phosphor_layout == 1){
      // classic aperture for RGB panels; good for 1080p, too small for 4K+
      // aka aperture_1_2_bgr
      weights  = aperture_weights;
      return weights;
   }

   else if(phosphor_layout == 2){
      // 2x2 shadow mask for RGB panels; good for 1080p, too small for 4K+
      // aka delta_1_2x1_bgr
      vec3 inverse_aperture = mix(green, magenta, floor(mod(coord.x, 2.0)));
      weights               = mix(aperture_weights, inverse_aperture, floor(mod(coord.y, 2.0)));
      return weights;
   }

   else if(phosphor_layout == 3){
      // slot mask for RGB panels; looks okay at 1080p, looks better at 4K
      // {magenta, green, black,   black},
      // {magenta, green, magenta, green},
      // {black,   black, magenta, green}

      // GLSL can't do 2D arrays until version 430, so do this stupid thing instead for compatibility's sake:
      // First lay out the horizontal pixels in arrays
      vec3 slotmask_x1[4] = vec3[](magenta, green, black,   black);
      vec3 slotmask_x2[4] = vec3[](magenta, green, magenta, green);
      vec3 slotmask_x3[4] = vec3[](black,   black, magenta, green);
      
      // find the vertical index
      w = int(floor(mod(coord.y, 3.0)));
      
      // find the horizontal index
      z = int(floor(mod(coord.x, 4.0)));

      // do a big, dumb comparison in place of a 2D array
      weights = (w == 1) ? slotmask_x1[z] : (w == 2) ? slotmask_x2[z] :  slotmask_x3[z];
    }

   if(phosphor_layout == 4){
      // classic aperture for RBG panels; good for 1080p, too small for 4K+
      weights  = mix(yellow, blue, floor(mod(coord.x, 2.0)));
      return weights;
   }

   else if(phosphor_layout == 5){
      // 2x2 shadow mask for RBG panels; good for 1080p, too small for 4K+
      vec3 inverse_aperture = mix(blue, yellow, floor(mod(coord.x, 2.0)));
      weights               = mix(mix(yellow, blue, floor(mod(coord.x, 2.0))), inverse_aperture, floor(mod(coord.y, 2.0)));
      return weights;
   }
   
   else if(phosphor_layout == 6){
      // aperture_1_4_rgb; good for simulating lower 
      vec3 ap4[4] = vec3[](red, green, blue, black);
      
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = ap4[z];
      return weights;
   }
   
   else if(phosphor_layout == 7){
      // aperture_2_5_bgr
      vec3 ap3[5] = vec3[](red, magenta, blue, green, green);
      
      z = int(floor(mod(coord.x, 5.0)));
      
      weights = ap3[z];
      return weights;
   }
   
   else if(phosphor_layout == 8){
      // aperture_3_6_rgb
      
      vec3 big_ap[7] = vec3[](red, red, yellow, green, cyan, blue, blue);
      
      w = int(floor(mod(coord.x, 7.)));
      
      weights = big_ap[w];
      return weights;
   }
   
   else if(phosphor_layout == 9){
      // reduced TVL aperture for RGB panels
      // aperture_2_4_rgb
      
      vec3 big_ap_rgb[4] = vec3[](red, yellow, cyan, blue);
      
      w = int(floor(mod(coord.x, 4.)));
      
      weights = big_ap_rgb[w];
      return weights;
   }
   
   else if(phosphor_layout == 10){
      // reduced TVL aperture for RBG panels
      
      vec3 big_ap_rbg[4] = vec3[](red, magenta, cyan, green);
      
      w = int(floor(mod(coord.x, 4.)));
      
      weights = big_ap_rbg[w];
      return weights;
   }
   
   else if(phosphor_layout == 11){
      // delta_1_4x1_rgb; dunno why this is called 4x1 when it's obviously 4x2 /shrug
      vec3 delta_1_1[4] = vec3[](red, green, blue, black);
      vec3 delta_1_2[4] = vec3[](blue, black, red, green);
      
      w = int(floor(mod(coord.y, 2.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = (w == 1) ? delta_1_1[z] : delta_1_2[z];
      return weights;
   }
   
   else if(phosphor_layout == 12){
      // delta_2_4x1_rgb
      vec3 delta_2_1[4] = vec3[](red, yellow, cyan, blue);
      vec3 delta_2_2[4] = vec3[](cyan, blue, red, yellow);
      
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = (w == 1) ? delta_2_1[z] : delta_2_2[z];
      return weights;
   }
   
   else if(phosphor_layout == 13){
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
   
   else if(phosphor_layout == 14){
      // slot mask for RGB panels; too low-pitch for 1080p, looks okay at 4K, but wants 8K+
      // {magenta, green, black, black,   black, black},
      // {magenta, green, black, magenta, green, black},
      // {black,   black, black, magenta, green, black}
      vec3 slot2_1[6] = vec3[](magenta, green, black, black,   black, black);
      vec3 slot2_2[6] = vec3[](magenta, green, black, magenta, green, black);
      vec3 slot2_3[6] = vec3[](black,   black, black, magenta, green, black);
   
      w = int(floor(mod(coord.y, 3.0)));
      z = int(floor(mod(coord.x, 6.0)));
      
      weights = (w == 1) ? slot2_1[z] : (w == 2) ? slot2_2[z] : slot2_3[z];
      return weights;
   }

   else if(phosphor_layout == 15){
      // slot_2_4x4_rgb
      // {red,   yellow, cyan,  blue,  red,   yellow, cyan,  blue },
      // {red,   yellow, cyan,  blue,  black, black,  black, black},
      // {red,   yellow, cyan,  blue,  red,   yellow, cyan,  blue },
      // {black, black,  black, black, red,   yellow, cyan,  blue }
      vec3 slotmask_RBG_x1[8] = vec3[](red,   yellow, cyan,  blue,  red,   yellow, cyan,  blue );
      vec3 slotmask_RBG_x2[8] = vec3[](red,   yellow, cyan,  blue,  black, black,  black, black);
      vec3 slotmask_RBG_x3[8] = vec3[](red,   yellow, cyan,  blue,  red,   yellow, cyan,  blue );
      vec3 slotmask_RBG_x4[8] = vec3[](black, black,  black, black, red,   yellow, cyan,  blue );
      
      // find the vertical index
      w = int(floor(mod(coord.y, 4.0)));
      
      // find the horizontal index
      z = int(floor(mod(coord.x, 8.0)));

      weights = (w == 1) ? slotmask_RBG_x1[z] : (w == 2) ? slotmask_RBG_x2[z] : (w == 3) ? slotmask_RBG_x3[z] : slotmask_RBG_x4[z];
      return weights;
    }
   
   else if(phosphor_layout == 16){
      // slot mask for RBG panels; too low-pitch for 1080p, looks okay at 4K, but wants 8K+
      // {yellow, blue,  black,  black},
      // {yellow, blue,  yellow, blue},
      // {black,  black, yellow, blue}
      vec3 slot2_1[4] = vec3[](yellow, blue,  black,  black);
      vec3 slot2_2[4] = vec3[](yellow, blue,  yellow, blue);
      vec3 slot2_3[4] = vec3[](black,  black, yellow, blue);
   
      w = int(floor(mod(coord.y, 3.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = (w == 1) ? slot2_1[z] : (w == 2) ? slot2_2[z] : slot2_3[z];
      return weights;
   }
   
   else if(phosphor_layout == 17){
      // slot_2_5x4_bgr
      // {red,   magenta, blue,  green, green, red,   magenta, blue,  green, green},
      // {black, blue,    blue,  green, green, red,   red,     black, black, black},
      // {red,   magenta, blue,  green, green, red,   magenta, blue,  green, green},
      // {red,   red,     black, black, black, black, blue,    blue,  green, green}
      vec3 slot_1[10] = vec3[](red,   magenta, blue,  green, green, red,   magenta, blue,  green, green);
      vec3 slot_2[10] = vec3[](black, blue,    blue,  green, green, red,   red,     black, black, black);
      vec3 slot_3[10] = vec3[](red,   magenta, blue,  green, green, red,   magenta, blue,  green, green);
      vec3 slot_4[10] = vec3[](red,   red,     black, black, black, black, blue,    blue,  green, green);
      
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 10.0)));
      
      weights = (w == 1) ? slot_1[z] : (w == 2) ? slot_2[z] : (w == 3) ? slot_3[z] : slot_4[z];
      return weights;
   }
   
   else if(phosphor_layout == 18){
      // same as above but for RBG panels
      // {red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue },
      // {black, green,  green, blue,  blue,  red,   red,    black, black, black},
      // {red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue },
      // {red,   red,    black, black, black, black, green,  green, blue,  blue }
      vec3 slot_1[10] = vec3[](red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue );
      vec3 slot_2[10] = vec3[](black, green,  green, blue,  blue,  red,   red,    black, black, black);
      vec3 slot_3[10] = vec3[](red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue );
      vec3 slot_4[10] = vec3[](red,   red,    black, black, black, black, green,  green, blue,  blue );
      
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 10.0)));
      
      weights = (w == 1) ? slot_1[z] : (w == 2) ? slot_2[z] : (w == 3) ? slot_3[z] : slot_4[z];
      return weights;
   }
   
   else if(phosphor_layout == 19){
      // slot_3_7x6_rgb
      // {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
      // {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
      // {red,   red,   yellow, green, cyan,  blue,  blue,  black, black, black,  black,  black, black, black},
      // {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
      // {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
      // {black, black, black,  black, black, black, black, black, red,   red,    yellow, green, cyan,  blue}
      
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


// For debugging
#define BLOOM_ONLY 0

void main()
{
#if BLOOM_ONLY
    vec3 source = BLOOM_STRENGTH * COMPAT_TEXTURE(Source, vTexCoord).rgb;
#else

    vec3 source = 1.15 * COMPAT_TEXTURE(PassPrev4Texture, vTexCoord).rgb;
    vec3 bloom  = COMPAT_TEXTURE(Source, vTexCoord).rgb;
    source     += BLOOM_STRENGTH * bloom;

    vec2 mask_coords = gl_FragCoord.xy; //texCoord.xy * OutputSize.xy;
//    vec2 mask_coords = (vTexCoord.xy * OutputSize.xy) * TextureSize.xy / InputSize.xy;

    source.rgb*=mask_weights(mask_coords, MASK_INTENSITY, int(PHOSPHOR_LAYOUT));
#endif
    FragColor = vec4(pow(clamp(source, 0.0, 1.0), vec3(1.0 / OUTPUT_GAMMA)), 1.0);
} 
#endif
