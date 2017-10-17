#version 430

// 8x8 Bayer matrix dithering
// by Martins Upitis
// license: "All the content here is and will be free to use for everyone, but a donation is always nice."
// url: http://devlog-martinsh.blogspot.com/2011/03/glsl-8x8-bayer-matrix-dithering.html
// adapted for RetroArch by hunterk

// Parameter lines go here:
#pragma parameter animate "Dithering Animation" 0.0 0.0 1.0 1.0
#pragma parameter dither_size "Dither Size" 0.0 0.0 0.95 0.05

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
precision mediump int;
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
uniform COMPAT_PRECISION float animate;
uniform COMPAT_PRECISION float dither_size;
#else
#define animate 0.0
#define dither_size 0.0
#endif

float find_closest(int x, int y, float c0)
{
int dither[8][8] = {
{ 0, 32, 8, 40, 2, 34, 10, 42}, /* 8x8 Bayer ordered dithering */
{48, 16, 56, 24, 50, 18, 58, 26}, /* pattern. Each input pixel */
{12, 44, 4, 36, 14, 46, 6, 38}, /* is scaled to the 0..63 range */
{60, 28, 52, 20, 62, 30, 54, 22}, /* before looking in this table */
{ 3, 35, 11, 43, 1, 33, 9, 41}, /* to determine the action. */
{51, 19, 59, 27, 49, 17, 57, 25},
{15, 47, 7, 39, 13, 45, 5, 37},
{63, 31, 55, 23, 61, 29, 53, 21} }; 

float limit = 0.0;
if(x < 8)
{
limit = (dither[x][y]+1)/64.0;
}

if(c0 < limit)
return 0.0;
return 1.0;
}

void main()
{
float Scale = 3.0 + mod(2.0 * FrameCount, 32.0) * animate + dither_size;
vec4 lum = vec4(0.299, 0.587, 0.114, 0);
float grayscale = dot(COMPAT_TEXTURE(Source, vTexCoord), lum);
vec3 rgb = COMPAT_TEXTURE(Source, vTexCoord).rgb;

vec2 xy = (vTexCoord * outsize.xy) * Scale;
int x = int(mod(xy.x, 8));
int y = int(mod(xy.y, 8));

vec3 finalRGB;
finalRGB.r = find_closest(x, y, rgb.r);
finalRGB.g = find_closest(x, y, rgb.g);
finalRGB.b = find_closest(x, y, rgb.b);

float final = find_closest(x, y, grayscale);

   FragColor = vec4(finalRGB, 1.0);
} 
#endif
