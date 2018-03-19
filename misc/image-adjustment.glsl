//   Image Adjustment
//   Author: hunterk
//   License: Public domain

#pragma parameter ia_target_gamma "Target Gamma" 2.2 0.1 5.0 0.1
#pragma parameter ia_monitor_gamma "Monitor Gamma" 2.2 0.1 5.0 0.1
#pragma parameter ia_overscan_percent_x "Horizontal Overscan %" 0.0 -25.0 25.0 1.0
#pragma parameter ia_overscan_percent_y "Vertical Overscan %" 0.0 -25.0 25.0 1.0
#pragma parameter ia_saturation "Saturation" 1.0 0.0 5.0 0.1
#pragma parameter ia_contrast "Contrast" 1.0 0.0 10.0 0.05
#pragma parameter ia_luminance "Luminance" 1.0 0.0 2.0 0.1
#pragma parameter ia_black_level "Black Level" 0.00 -0.30 0.30 0.01
#pragma parameter ia_bright_boost "Brightness Boost" 0.0 -1.0 1.0 0.05
#pragma parameter ia_R "Red Channel" 1.0 0.0 2.0 0.05
#pragma parameter ia_G "Green Channel" 1.0 0.0 2.0 0.05
#pragma parameter ia_B "Blue Channel" 1.0 0.0 2.0 0.05
#pragma parameter ia_ZOOM "Zoom Factor" 1.0 0.0 4.0 0.01
#pragma parameter ia_XPOS "X Modifier" 0.0 -2.0 2.0 0.005
#pragma parameter ia_YPOS "Y Modifier" 0.0 -2.0 2.0 0.005
#pragma parameter ia_TOPMASK "Overscan Mask Top" 0.0 0.0 1.0 0.0025
#pragma parameter ia_BOTMASK "Overscan Mask Bottom" 0.0 0.0 1.0 0.0025
#pragma parameter ia_LMASK "Overscan Mask Left" 0.0 0.0 1.0 0.0025
#pragma parameter ia_RMASK "Overscan Mask Right" 0.0 0.0 1.0 0.0025
#pragma parameter ia_GRAIN_STR "Film Grain" 0.0 0.0 72.0 6.0
#pragma parameter ia_SHARPEN "Sharpen" 0.0 0.0 1.0 0.05
#pragma parameter ia_FLIP_HORZ "Flip Horiz Axis" 0.0 0.0 1.0 1.0
#pragma parameter ia_FLIP_VERT "Flip Vert Axis" 0.0 0.0 1.0 1.0

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ia_overscan_percent_x;
uniform COMPAT_PRECISION float ia_overscan_percent_y;
uniform COMPAT_PRECISION float ia_ZOOM;
uniform COMPAT_PRECISION float ia_XPOS;
uniform COMPAT_PRECISION float ia_YPOS;
uniform COMPAT_PRECISION float ia_FLIP_HORZ;
uniform COMPAT_PRECISION float ia_FLIP_VERT;
#else
#define ia_overscan_percent_x 0.0  // crop width of image by X%; default is 0.0
#define ia_overscan_percent_y 0.0  // crop height of image by X%; default is 0.0
#define ia_ZOOM 0.0                // zoom factor; default is 0.0
#define ia_XPOS 0.0                // horizontal position modifier; default is 0.0
#define ia_YPOS 0.0                // vertical position modifier; default is 0.0
#define ia_FLIP_HORZ 0.0           // horizontal flip toggle; default is 0.0
#define ia_FLIP_VERT 0.0           // vertical flip toggle; default is 0.0
#endif

void main()
{
   vec4 flip_pos = VertexCoord;
   if (ia_FLIP_HORZ > 0.5) flip_pos.x = 1.0 - flip_pos.x;
   if (ia_FLIP_VERT > 0.5) flip_pos.y = 1.0 - flip_pos.y;
   gl_Position = MVPMatrix * flip_pos;
   vec2 shift = (vec2(0.5) * InputSize) / TextureSize;
   vec2 overscan_coord = ((TexCoord.xy - shift) / ia_ZOOM) * (1.0 - vec2(ia_overscan_percent_x / 100.0, ia_overscan_percent_y / 100.0)) + shift;
   TEX0.xy = overscan_coord + vec2(ia_XPOS, ia_YPOS);
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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ia_target_gamma;
uniform COMPAT_PRECISION float ia_monitor_gamma;
uniform COMPAT_PRECISION float ia_saturation;
uniform COMPAT_PRECISION float ia_contrast;
uniform COMPAT_PRECISION float ia_luminance;
uniform COMPAT_PRECISION float ia_black_level;
uniform COMPAT_PRECISION float ia_bright_boost;
uniform COMPAT_PRECISION float ia_R;
uniform COMPAT_PRECISION float ia_G;
uniform COMPAT_PRECISION float ia_B;
uniform COMPAT_PRECISION float ia_TOPMASK;
uniform COMPAT_PRECISION float ia_BOTMASK;
uniform COMPAT_PRECISION float ia_LMASK;
uniform COMPAT_PRECISION float ia_RMASK;
uniform COMPAT_PRECISION float ia_GRAIN_STR;
uniform COMPAT_PRECISION float ia_SHARPEN;
#else
#define ia_target_gamma 2.2    // the gamma you want the image to have; CRT TVs typically have a gamma of 2.4
#define ia_monitor_gamma 2.2   // gamma setting of your current display; LCD monitors typically have a gamma of 2.2
#define ia_saturation 1.0      // color saturation; default 1.0
#define ia_contrast 1.0        // image contrast; default 1.0
#define ia_luminance 1.0       // image luminance; default 1.0
#define ia_black_level 0.0     // black level; default 0.0
#define ia_bright_boost 0.0    // adds to the total brightness. Negative values decrease it; Use values between 1.0 (totally white) and -1.0 (totally black); default is 0.0
#define ia_R 1.0               // red level; default 1.0
#define ia_G 1.0               // green level; default 1.0
#define ia_B 1.0               // red level; default 1.0
#define ia_TOPMASK 0.0         // mask top of image by X%; default is 0.0
#define ia_BOTMASK 0.0         // mask bottom of image by X%; default is 0.0
#define ia_LMASK 0.0           // mask left of image by X%; default is 0.0
#define ia_RMASK 0.0           // mask right of image by X%; default is 0.0
#define ia_GRAIN_STR 0.0       // grain filter strength; default is 0.0
#define ia_SHARPEN 0.0         // sharpen filter strength; default is 0.0
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// texture(a, b) with COMPAT_TEXTURE(a, b) <-can't macro unfortunately

vec3 rgb2hsv(vec3 c)
{
   vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
   vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
   vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

   float d = q.x - min(q.w, q.y);
   float e = 1.0e-10;
   return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
   vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
   vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
   return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//https://www.shadertoy.com/view/4sXSWs strength= 16.0
vec3 filmGrain(vec2 uv, float strength )
{
   float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * ((mod(vec2(FrameCount, FrameCount).x, 800.0) + 10.0) * 10.0);
   return  vec3(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
}

// based on "Improved texture interpolation" by Iñigo Quílez
// Original description: http://www.iquilezles.org/www/articles/texture/texture.htm
vec3 sharp(sampler2D tex, vec2 texCoord)
{
   vec2 p = texCoord.xy;
   p = p * SourceSize.xy + vec2(0.5, 0.5);
   vec2 i = floor(p);
   vec2 f = p - i;
   f = f * f * f * (f * (f * 6.0 - vec2(15.0, 15.0)) + vec2(10.0, 10.0));
   p = i + f;
   p = (p - vec2(0.5, 0.5)) * SourceSize.zw;
   return COMPAT_TEXTURE(tex, p).rgb;
}


void main()
{
   vec3 film_grain = filmGrain(vTexCoord, ia_GRAIN_STR);
   vec3 res = COMPAT_TEXTURE(Source, vTexCoord).rgb; // sample the texture
   res = mix(res, sharp(Source, vTexCoord), ia_SHARPEN) + film_grain; // add film grain and sharpness
   vec3 gamma = vec3(ia_monitor_gamma / ia_target_gamma); // set up ratio of display's gamma vs desired gamma

//saturation and luminance
   vec3 satColor = clamp(hsv2rgb(rgb2hsv(res) * vec3(1.0, ia_saturation, ia_luminance)), 0.0, 1.0);

//contrast and brightness
   vec3 conColor = clamp((satColor - 0.5) * ia_contrast + 0.5 + ia_bright_boost, 0.0, 1.0);

   conColor -= vec3(ia_black_level); // apply black level
   conColor *= (vec3(1.0) / vec3(1.0-ia_black_level));
   conColor = pow(conColor, 1.0 / vec3(gamma)); // Apply gamma correction
   conColor *= vec3(ia_R, ia_G, ia_B);

//overscan mask

   vec2 FragCoord = (vTexCoord * TextureSize.xy / InputSize.xy); //needed for overscan mask to work properly

   if (FragCoord.y > ia_TOPMASK && FragCoord.y < (1.0 - ia_BOTMASK))
      conColor = conColor;
   else
      conColor = vec3(0.0);

   if (FragCoord.x > ia_LMASK && FragCoord.x < (1.0 - ia_RMASK))
      conColor = conColor;
   else
      conColor = vec3(0.0);

   FragColor = vec4(conColor, 1.0);
}
#endif
