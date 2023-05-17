/*
    crt-1tap v1.0 by fishku
    Copyright (C) 2023
    Ported by dariusg to GLSL
    Public domain license (CC0)

    Extremely fast and lightweight dynamic scanline shader.
    Contrasty and sharp output. Easy to configure.
    Can be combined with other shaders.

    How it works: Uses a single texture "tap" per pixel, hence the name.
    Exploits bilinear interpolation plus local coordinate distortion to shape
    the scanline. A pseudo-sigmoid function with a configurable slope at the
    inflection point is used to control horizontal smoothness.
    Uses a clamped linear function to anti-alias the edge of the scanline while
    avoiding further branching. The final thickness is shaped with a gamma-like
    operation to control overall image contrast.
    The scanline subpixel position can be controlled to achieve the best
    sharpness and uniformity of the output given different input sizes, e.g.,
    for even and odd integer scaling.

    Changelog:
    v1.2: Better scanline sharpness; Minor cleanups.
    v1.1: Update license; Better defaults; Don't compute alpha.
    v1.0: Initial release.
*/

// clang-format off
#pragma parameter CRT1TAP_SETTINGS "=== CRT-1tap v1.2 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter MIN_THICK "Scanline thickness of dark pixels" 0.3 0.0 1.4 0.05
#pragma parameter MAX_THICK "Scanline thickness of bright pixels" 0.9 0.0 1.4 0.05
#pragma parameter V_SHARP "Vertical sharpness of the scanline" 0.5 0.0 1.0 0.05
#pragma parameter H_SHARP "Horizontal sharpness of pixel transitions" 0.15 0.0 1.0 0.05
#pragma parameter SUBPX_POS "Scanline subpixel position" 0.3 -0.5 0.5 0.01
#pragma parameter THICK_FALLOFF "Reduction / increase of thinner scanlines" 0.65 0.2 2.0 0.05


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
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

uniform sampler2D Texture;

void main()
{
      gl_Position = MVPMatrix * VertexCoord;
      COL0 = COLOR;
      TEX0.xy = TexCoord.xy*1.0001;
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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)


#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float MIN_THICK;
uniform COMPAT_PRECISION float MAX_THICK;
uniform COMPAT_PRECISION float V_SHARP;
uniform COMPAT_PRECISION float H_SHARP;
uniform COMPAT_PRECISION float SUBPX_POS;
uniform COMPAT_PRECISION float THICK_FALLOFF;
#else
#define MIN_THICK 0.3
#define MAX_THICK 0.9
#define V_SHARP 0.5
#define H_SHARP 0.15
#define SUBPX_POS 0.3
#define THICK_FALLOFF 0.65
#endif


void main() {

    vec2 cent = vTexCoord*SourceSize.xy;
    float src_x_fract = fract(cent.x - 0.5);
    float src_x_int = floor(cent.x-0.5);

    float src_y_fract = fract(cent.y - SUBPX_POS) -0.5;
    float src_y_int = floor (cent.y - SUBPX_POS);

// Function similar to smoothstep and sigmoid.
    float s = sign(src_x_fract - 0.5);
    float o = (1.0 + s) * 0.5;
    float src_x = src_x_int + o - 0.5 * s * pow(2.0 * (o - s * src_x_fract), mix(1.0, 6.0, H_SHARP));

    vec3 signal = COMPAT_TEXTURE(Source, vec2((src_x + 0.5) * SourceSize.z, (src_y_int + 0.5) * SourceSize.w)).rgb;

// Vectorize operations for speed.
    float eff_v_sharp = 3.0 + 50.0 * V_SHARP * V_SHARP;
    vec3 thickmin = vec3(MIN_THICK); vec3 thickmax = vec3(MAX_THICK); vec3 thickfall = vec3(THICK_FALLOFF);
    vec3 radius = pow(mix(thickmin, thickmax, signal), thickfall) * 0.5;
   
    FragColor.rgb = signal * clamp(0.25 - eff_v_sharp * (src_y_fract * src_y_fract - radius * radius),0.0, 1.0);
}
#endif
