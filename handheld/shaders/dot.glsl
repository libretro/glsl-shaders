/*
   Author: Themaister
   License: Public domain
*/

// Parameter lines go here:
#pragma parameter gamma "Dot Gamma" 2.4 0.0 5.0 0.05
#pragma parameter shine "Dot Shine" 0.05 0.0 0.5 0.01
#pragma parameter blend "Dot Blend" 0.65 0.0 1.0 0.01

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
COMPAT_VARYING vec4 c00_10;
COMPAT_VARYING vec4 c00_01;
COMPAT_VARYING vec4 c20_01;
COMPAT_VARYING vec4 c21_02;
COMPAT_VARYING vec4 c12_22;
COMPAT_VARYING vec2 c11;
COMPAT_VARYING vec2 pixel_no;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
   
   float dx = SourceSize.z;
   float dy = SourceSize.w;
   
   c00_10 = vec4(vTexCoord + vec2(-dx, -dy), vTexCoord + vec2(0, -dy));
   c20_01 = vec4(vTexCoord + vec2(dx, -dy), vTexCoord + vec2(-dx, 0));
   c21_02 = vec4(vTexCoord + vec2(dx, 0), vTexCoord + vec2(-dx, dy));
   c12_22 = vec4(vTexCoord + vec2(0, dy), vTexCoord + vec2(dx, dy));
   c11 = vTexCoord;
   pixel_no = vTexCoord * SourceSize.xy;
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
COMPAT_VARYING vec4 c00_10;
COMPAT_VARYING vec4 c00_01;
COMPAT_VARYING vec4 c20_01;
COMPAT_VARYING vec4 c21_02;
COMPAT_VARYING vec4 c12_22;
COMPAT_VARYING vec2 c11;
COMPAT_VARYING vec2 pixel_no;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float gamma;
uniform COMPAT_PRECISION float shine;
uniform COMPAT_PRECISION float blend;
#else
#define gamma 2.4
#define shine 0.05
#define blend 0.65
#endif

COMPAT_PRECISION float dist(vec2 coord, vec2 source)
{
   vec2 delta = coord - source;
   return sqrt(dot(delta, delta));
}

COMPAT_PRECISION float color_bloom(vec3 color)
{
   const vec3 gray_coeff = vec3(0.30, 0.59, 0.11);
   float bright = dot(color, gray_coeff);
   return mix(1.0 + shine, 1.0 - shine, bright);
}

vec3 lookup(vec2 pixel_no, float offset_x, float offset_y, vec3 color)
{
   vec2 offset = vec2(offset_x, offset_y);
   float delta = dist(fract(pixel_no), offset + vec2(0.5, 0.5));
   return color * exp(-gamma * delta * color_bloom(color));
}

#define TEX(coord) COMPAT_TEXTURE(Source, vTexCoord).rgb

void main()
{
   vec3 mid_color = lookup(pixel_no, 0.0, 0.0, TEX(c11));
   vec3 color = vec3(0.0, 0.0, 0.0);
   color += lookup(pixel_no, -1.0, -1.0, TEX(c00_10.xy));
   color += lookup(pixel_no,  0.0, -1.0, TEX(c00_10.zw));
   color += lookup(pixel_no,  1.0, -1.0, TEX(c20_01.xy));
   color += lookup(pixel_no, -1.0,  0.0, TEX(c20_01.zw));
   color += mid_color;
   color += lookup(pixel_no,  1.0,  0.0, TEX(c21_02.xy));
   color += lookup(pixel_no, -1.0,  1.0, TEX(c21_02.zw));
   color += lookup(pixel_no,  0.0,  1.0, TEX(c12_22.xy));
   color += lookup(pixel_no,  1.0,  1.0, TEX(c12_22.zw));
   vec3 out_color = mix(1.2 * mid_color, color, blend);
   
   FragColor = vec4(out_color, 1.0);
} 
#endif
