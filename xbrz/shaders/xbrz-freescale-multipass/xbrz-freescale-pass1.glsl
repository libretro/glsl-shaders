/*
   Hyllian's xBR-vertex code and texel mapping
   
   Copyright (C) 2011/2016 Hyllian - sergiogdb@gmail.com

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

// This shader also uses code and/or concepts from xBRZ as it appears
// in the Desmume source code. The license for which is as follows:

// ****************************************************************************
// * This file is part of the HqMAME project. It is distributed under         *
// * GNU General Public License: http://www.gnu.org/licenses/gpl-3.0          *
// * Copyright (C) Zenju (zenju AT gmx DOT de) - All Rights Reserved          *
// *                                                                          *
// * Additionally and as a special exception, the author gives permission     *
// * to link the code of this program with the MAME library (or with modified *
// * versions of MAME that use the same license as MAME), and distribute      *
// * linked combinations including the two. You must obey the GNU General     *
// * Public License in all respects for all of the code used other than MAME. *
// * If you modify this file, you may extend this exception to your version   *
// * of the file, but you are not obligated to do so. If you do not wish to   *
// * do so, delete this exception statement from your version.                *
// ****************************************************************************

#pragma parameter XBRZ_MINC "xBRZ: minimum contrast to round a corner (x/255, 0 = off)" 0.0 0.0 80.0 2.0
#pragma parameter XBRZ_MINC_RAMP "xBRZ: minimum contrast soft transition (0 = hard cut)" 0.0 0.0 64.0 2.0

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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy * 1.0001;
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

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D PassPrev2Texture;
uniform COMPAT_PRECISION vec2 PassPrev2TextureSize;
uniform COMPAT_PRECISION vec2 PassPrev2InputSize;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define OriginalSize vec4(PassPrev2TextureSize, 1.0 / PassPrev2TextureSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float XBRZ_MINC;
uniform COMPAT_PRECISION float XBRZ_MINC_RAMP;
#else
#define XBRZ_MINC 0.0
#define XBRZ_MINC_RAMP 0.0
#endif

#define BLEND_NONE 0.
#define BLEND_NORMAL 1.
#define BLEND_DOMINANT 2.
#define LUMINANCE_WEIGHT 1.0
#define EQUAL_COLOR_TOLERANCE 30.0/255.0
#define STEEP_DIRECTION_THRESHOLD 2.2
#define DOMINANT_DIRECTION_THRESHOLD 3.6

float DistYCbCr(vec3 pixA, vec3 pixB)
{
  const vec3 w = vec3(0.2627, 0.6780, 0.0593);
  const float scaleB = 0.5 / (1.0 - w.b);
  const float scaleR = 0.5 / (1.0 - w.r);
  vec3 diff = pixA - pixB;
  float Y = dot(diff.rgb, w);
  float Cb = scaleB * (diff.b - Y);
  float Cr = scaleR * (diff.r - Y);

  return sqrt(((LUMINANCE_WEIGHT * Y) * (LUMINANCE_WEIGHT * Y)) + (Cb * Cb) + (Cr * Cr));
}

bool IsPixEqual(const vec3 pixA, const vec3 pixB)
{
  return (DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE);
}

// Minimum contrast: how much of the corner cut a blend keeps, from the contrast between
// the pixel and the blend colour (0 = none, 1 = all). With XBRZ_MINC = 0 every cut is kept.
float mincKeep(float d)
{
  if (XBRZ_MINC_RAMP < 0.5) return d * 255.0 >= XBRZ_MINC ? 1.0 : 0.0;
  return clamp((d * 255.0 - (XBRZ_MINC - 0.5 * XBRZ_MINC_RAMP)) / XBRZ_MINC_RAMP, 0.0, 1.0);
}

// moves the blend line towards the pixel corner cp, so that only the fraction k of the cut remains
vec2 shrinkOrigin(vec2 origin, vec2 direction, vec2 cp, float k)
{
  vec2 n = normalize(vec2(-direction.y, direction.x));
  return origin + n * ((1.0 - k) * dot(cp - origin, n));
}

float get_left_ratio(vec2 center, vec2 origin, vec2 direction, vec2 scale)
{
  vec2 P0 = center - origin;
  vec2 proj = direction * (dot(P0, direction) / dot(direction, direction));
  vec2 distv = P0 - proj;
  vec2 orth = vec2(-direction.y, direction.x);
  float side = sign(dot(P0, orth));
  float v = side * length(distv * scale);

//  return step(0, v);
  return smoothstep(-sqrt(2.0)/2.0, sqrt(2.0)/2.0, v);
}

#define eq(a,b)  (a == b)
#define neq(a,b) (a != b)

#define P(x,y) COMPAT_TEXTURE(PassPrev2Texture, coord + OriginalSize.zw * vec2(x, y)).rgb

void main()
{
  //---------------------------------------
  // Input Pixel Mapping: -|B|-
  //                      D|E|F
  //                      -|H|-

  // output pixels per input pixel; the texture can be larger than the image, so use the image size
  vec2 scale = OutputSize.xy / PassPrev2InputSize.xy;
  vec2 pos = fract(vTexCoord * OriginalSize.xy) - vec2(0.5, 0.5);
  vec2 coord = vTexCoord - pos * OriginalSize.zw;

  vec3 B = P( 0.,-1.);
  vec3 D = P(-1., 0.);
  vec3 E = P( 0., 0.);
  vec3 F = P( 1., 0.);
  vec3 H = P( 0., 1.);

  vec4 info = floor(COMPAT_TEXTURE(Source, coord) * 255.0 + 0.5);

  // info Mapping: x|y|
  //               w|z|

  vec4 blendResult = floor(mod(info, 4.0));
  vec4 doLineBlend = floor(mod(info / 4.0, 4.0));
  vec4 haveShallowLine = floor(mod(info / 16.0, 4.0));
  vec4 haveSteepLine = floor(mod(info / 64.0, 4.0));

  vec3 res = E;

  // The corners are applied in the order of the reference xBRZ (z, y, x, w), and blend colour
  // ties go to the same neighbour as there ("dist(E,F) <= dist(E,H) ? F : H").

  // Pixel Tap Mapping: -|-|-
  //                    -|E|F
  //                    -|H|-
  if(blendResult.z > BLEND_NONE)
  {
    vec2 origin = vec2(0.0, 1.0 / sqrt(2.0));
    vec2 direction = vec2(1.0, -1.0);
    if(doLineBlend.z > 0.0)
    {
      origin = haveShallowLine.z > 0.0? vec2(0.0, 0.25) : vec2(0.0, 0.5);
      direction.x += haveShallowLine.z;
      direction.y -= haveSteepLine.z;
    }

    vec3 blendPix = (DistYCbCr(E, F) <= DistYCbCr(E, H)) ? F : H;
    float keep = mincKeep(DistYCbCr(E, blendPix));
    if (keep > 0.0)
      res = mix(res, blendPix, get_left_ratio(pos, shrinkOrigin(origin, direction, vec2(0.5, 0.5), keep), direction, scale));
  }

  // Pixel Tap Mapping: -|B|-
  //                    -|E|F
  //                    -|-|-
  if(blendResult.y > BLEND_NONE)
  {
    vec2 origin = vec2(1.0 / sqrt(2.0), 0.0);
    vec2 direction = vec2(-1.0, -1.0);

    if(doLineBlend.y > 0.0)
    {
      origin = haveShallowLine.y > 0.0? vec2(0.25, 0.0) : vec2(0.5, 0.0);
      direction.y -= haveShallowLine.y;
      direction.x -= haveSteepLine.y;
    }

    vec3 blendPix = (DistYCbCr(E, B) <= DistYCbCr(E, F)) ? B : F;
    float keep = mincKeep(DistYCbCr(E, blendPix));
    if (keep > 0.0)
      res = mix(res, blendPix, get_left_ratio(pos, shrinkOrigin(origin, direction, vec2(0.5, -0.5), keep), direction, scale));
  }

  // Pixel Tap Mapping: -|B|-
  //                    D|E|-
  //                    -|-|-
  if(blendResult.x > BLEND_NONE)
  {
    vec2 origin = vec2(0.0, -1.0 / sqrt(2.0));
    vec2 direction = vec2(-1.0, 1.0);
    if(doLineBlend.x > 0.0)
    {
      origin = haveShallowLine.x > 0.0? vec2(0.0, -0.25) : vec2(0.0, -0.5);
      direction.x -= haveShallowLine.x;
      direction.y += haveSteepLine.x;
    }

    vec3 blendPix = (DistYCbCr(E, D) <= DistYCbCr(E, B)) ? D : B;
    float keep = mincKeep(DistYCbCr(E, blendPix));
    if (keep > 0.0)
      res = mix(res, blendPix, get_left_ratio(pos, shrinkOrigin(origin, direction, vec2(-0.5, -0.5), keep), direction, scale));
  }

  // Pixel Tap Mapping: -|-|-
  //                    D|E|-
  //                    -|H|-
  if(blendResult.w > BLEND_NONE)
  {
    vec2 origin = vec2(-1.0 / sqrt(2.0), 0.0);
    vec2 direction = vec2(1.0, 1.0);
    if(doLineBlend.w > 0.0)
    {
      origin = haveShallowLine.w > 0.0? vec2(-0.25, 0.0) : vec2(-0.5, 0.0);
      direction.y += haveShallowLine.w;
      direction.x += haveSteepLine.w;
    }

    vec3 blendPix = (DistYCbCr(E, H) <= DistYCbCr(E, D)) ? H : D;
    float keep = mincKeep(DistYCbCr(E, blendPix));
    if (keep > 0.0)
      res = mix(res, blendPix, get_left_ratio(pos, shrinkOrigin(origin, direction, vec2(-0.5, 0.5), keep), direction, scale));
  }

  FragColor = vec4(res, 1.0);
} 
#endif
