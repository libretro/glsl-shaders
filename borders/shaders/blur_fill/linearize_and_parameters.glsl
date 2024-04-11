#version 130

// clang-format off
#pragma parameter BLUR_FILL_SETTINGS "=== Blur fill v1.10 settings ===" 0.0 0.0 1.0 1.0

#pragma parameter SCALING_SETTINGS "= Scaling parameters =" 0.0 0.0 1.0 1.0
#pragma parameter FORCE_ASPECT_RATIO "Force aspect ratio" 1.0 0.0 1.0 1.0
#pragma parameter ASPECT_H "Horizontal aspect ratio before crop (0 = unchanged)" 0.0 0.0 256.0 1.0
#pragma parameter ASPECT_V "Vertical aspect ratio before crop (0 = unchanged)" 0.0 0.0 256.0 1.0
#pragma parameter FORCE_INTEGER_SCALING_H "Force integer scaling horizontally" 0.0 0.0 1.0 1.0
#pragma parameter FORCE_INTEGER_SCALING_V "Force integer scaling vertically" 0.0 0.0 1.0 1.0

#pragma parameter OVERSCALE "Overscale (0 = full image, 1 = full screen)" 0.0 0.0 1.0 0.01

#pragma parameter CROPPING_SETTINGS "= Cropping parameters =" 0.0 0.0 1.0 1.0
#pragma parameter OS_CROP_TOP "Overscan crop top" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_BOTTOM "Overscan crop bottom" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_LEFT "Overscan crop left" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_RIGHT "Overscan crop right" 0.0 0.0 1024.0 1.0

#pragma parameter MOVING_SETTINGS "= Moving parameters =" 0.0 0.0 1.0 1.0
#pragma parameter SHIFT_H "Horizontal shift" 0.0 -1024.0 1024.0 0.5
#pragma parameter SHIFT_V "Vertical shift" 0.0 -1024.0 1024.0 0.5
#pragma parameter CENTER_AFTER_CROPPING "Center cropped area" 1.0 0.0 1.0 1.0

#pragma parameter OTHER_SETTINGS "= Other parameters =" 0.0 0.0 1.0 1.0
#pragma parameter EXTEND_H "Extend the fill horizontally" 0.0 0.0 1.0 1.0
#pragma parameter EXTEND_V "Extend the fill vertically" 0.0 0.0 1.0 1.0

#pragma parameter MIRROR_BLUR "Mirror the blur" 0.0 0.0 1.0 1.0

#pragma parameter FILL_GAMMA "Background fill gamma adjustment" 1.4 0.5 2.0 0.1

#pragma parameter SAMPLE_SIZE "No. of lines for rendering the blur" 16.0 1.0 1024.0 1.0
// clang-format on

// clang-format off
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.5 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SHARP "Pixel AA sharpening amount" 1.5 0.0 2.0 0.05
// #pragma parameter PIX_AA_GAMMA "Enable gamma-correct blending" 1.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX "Enable subpixel AA" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX_ORIENTATION "Subpixel layout (0=RGB, 1=RGB vert., 2=BGR, 3=BGR vert.)" 0.0 0.0 3.0 1.0
// clang-format on

// clang-format off
#pragma parameter DUAL_FILTER_SETTINGS "=== Dual Filter Blur & Bloom v1.2 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter BLUR_RADIUS "Blur radius" 1.0 0.0 7.5 0.1
// clang-format on

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

void main() {
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

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

void main() {
    FragColor = vec4(pow(COMPAT_TEXTURE(Texture, TEX0.xy).rgb, vec3(2.2)), 1.0);
}

#endif
