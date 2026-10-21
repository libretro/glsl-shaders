// xBRZ freescale, multipass: xBRZ at any scale factor, in two passes.
//
// Two optional rules, both off by default (plain xBRZ); the xbrz-crisp preset turns them on:
// - XBRZ_MINC (crisp: 16) leaves a corner square when its two colors differ by less than this
//   (x/255, YCbCr distance), so soft shading and textures keep their pixels.
// - XBRZ_DIAG (crisp: 100) leaves a corner square when the two colors its cut would join differ
//   by more than this, so a junction of three colors is not pulled into a fake diagonal (an idea
//   from torcado's cleanEdge, MIT license). Antialiasing ramps use 92, shallow and steep lines are
//   never blocked, a blocked corner is still cut when a neighbour on the same diagonal is cut,
//   and where 1-pixel stripes end flush (gauges, health bars) the end corners stay square.
//
// The first pass makes every blend decision once per input pixel (blend type, line type, blend
// color and the minimum contrast), so the second pass, which runs once per output pixel, only
// reads two textures where no corner is cut. Blend color ties and the order of the four corners
// follow the reference C++ xBRZ, and the second pass reads the image from the pass before xBRZ,
// so it also works after other shaders in a preset.
// Defaults: equal color tolerance 15, dominant direction 3.8, steep/shallow line 3.2
// (reference xBRZ: 30, 3.6 and 2.2).
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

// Pass 0 of xbrz-freescale-multipass (OpenGL / GLES)
#pragma parameter XBRZ_TOL "xBRZ: equal color tolerance (x/255)" 15 1 80 1
#pragma parameter XBRZ_DOM "xBRZ: dominant direction threshold" 3.8 1 8 0.05
#pragma parameter XBRZ_STEEP "xBRZ: steep/shallow line threshold" 3.2 1 6 0.1
#pragma parameter XBRZ_MINC "xBRZ: minimum contrast to round a corner (x/255, 0 = off)" 0 0 80 2
#pragma parameter XBRZ_DIAG "xBRZ: max color distance on the diagonal (0 = off)" 0 0 160 4

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

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
#define vTexCoord TEX0.xy
#define FRAG_OUT FragColor
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float XBRZ_TOL;
uniform COMPAT_PRECISION float XBRZ_DOM;
uniform COMPAT_PRECISION float XBRZ_STEEP;
uniform COMPAT_PRECISION float XBRZ_MINC;
uniform COMPAT_PRECISION float XBRZ_DIAG;
#else
#define XBRZ_TOL 15.0
#define XBRZ_DOM 3.8
#define XBRZ_STEEP 3.2
#define XBRZ_MINC 0.0
#define XBRZ_DIAG 0.0
#endif

#define SRC_SIZE vec4(TextureSize, 1.0 / TextureSize)
#define P(x,y) COMPAT_TEXTURE(Texture, coord + SRC_SIZE.zw * vec2(x, y)).rgb

#define BLEND_NONE 0
#define BLEND_NORMAL 1
#define BLEND_DOMINANT 2
#ifndef TOL_E
#define TOL_E XBRZ_TOL
#endif
#ifndef DOM_E
#define DOM_E XBRZ_DOM
#endif
#ifndef STEEP_E
#define STEEP_E XBRZ_STEEP
#endif
#define EQUAL_COLOR_TOLERANCE (TOL_E / 255.0)

float DistYCbCr(vec3 pixA, vec3 pixB)
{
  const vec3 w = vec3(0.2627, 0.6780, 0.0593);
  const float scaleB = 0.5 / (1.0 - 0.0593);
  const float scaleR = 0.5 / (1.0 - 0.2627);
  vec3 diff = pixA - pixB;
  float Y = dot(diff.rgb, w);
  float Cb = scaleB * (diff.b - Y);
  float Cr = scaleR * (diff.r - Y);
  return sqrt((Y * Y) + (Cb * Cb) + (Cr * Cr));
}

bool IsPixEqual(vec3 pixA, vec3 pixB)
{
  return (DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE);
}

#define eq(a,b)  (a == b)
#define neq(a,b) (a != b)

// ---- diagonal rules (XBRZ_DIAG) ----
#define XBRZ_DIAG_AA 92.0   // diagonal limit for antialiasing ramps
#define XBRZ_TIP 64.0       // stripe ends stay square above this diagonal distance
#define alike(a,b) (DistYCbCr(a, b) * 255.0 <= 20.0)

// res holds the xBRZ decisions of the four corners (blend type +4 line +8 second color +16 shallow +64 steep)
vec4 diagonalRules(vec4 res, vec2 coord, vec3 A, vec3 B, vec3 C, vec3 D, vec3 E, vec3 F, vec3 G, vec3 H, vec3 I,
                   float dEB, float dED, float dEF, float dEH)
{
  // only pixels that still have a corner to cut
  vec4 cut = vec4(greaterThan(mod(res, 4.0), vec4(0.0)));
  if (XBRZ_DIAG <= 0.0 || dot(cut, vec4(1.0)) <= 0.0)
    return res;

  // the two colors on each corner's diagonal: top-left D-B, top-right B-F, bottom-right F-H, bottom-left H-D
  vec4 pair = vec4(DistYCbCr(D, B), DistYCbCr(B, F), DistYCbCr(F, H), DistYCbCr(H, D));

  // similar diagonal
  vec4 dEP = vec4(dED, dEB, dEF, dEH);
  vec4 dEQ = vec4(dEB, dEF, dEH, dED);
  // a ramp: one diagonal color lies (almost) on the way from E to the other one
  vec4 ramp = min((dEP + pair) / max(dEQ, vec4(1e-5)), (dEQ + pair) / max(dEP, vec4(1e-5)));
  vec4 limit = mix(vec4(XBRZ_DIAG), vec4(XBRZ_DIAG_AA), vec4(lessThanEqual(ramp, vec4(1.15))));
  // shallow and steep lines (+16, +64) are never blocked
  vec4 keep = max(vec4(lessThanEqual(pair * 255.0, limit)), vec4(greaterThanEqual(res, vec4(16.0))));
  // a blocked corner is flagged (+128); the output pass keeps it only when it continues a cut line
  res += 128.0 * (1.0 - keep) * cut;

  // stripe ends: E ends a 1-pixel horizontal line (left or right end) or vertical line (top or bottom end)
  bool eB = eq(E, B), eD = eq(E, D), eF = eq(E, F), eH = eq(E, H);
  // the stripes on both sides differ from each other too, so outlines (same color on both sides) are left alone
  bool thinH = !eB && !eH && !eq(B, H), thinV = !eD && !eF && !eq(D, F);
  if (thinH || thinV)
  {
    // the stripes only need to keep a similar color (within 20/255) along their length, so a background
    // with a slight gradient still counts as one stripe
    bool nB = alike(E, B), nD = alike(E, D), nF = alike(E, F), nH = alike(E, H);
    // only inside a stack of parallel stripes: the rows (or columns) on both sides run along the line too
    // and they all end flush at the same column (or row), like the stripes of a gauge
    // all three stripes run at least 3 pixels back from the end
    float endL = (thinH && nF && !eD && alike(B, C) && alike(H, I) && !eq(B, A) && !eq(H, G) && alike(E, P(2., 0.)) && alike(C, P(2., -1.)) && alike(I, P(2., 1.))) ? 1.0 : 0.0;
    float endR = (thinH && nD && !eF && alike(B, A) && alike(H, G) && !eq(B, C) && !eq(H, I) && alike(E, P(-2., 0.)) && alike(A, P(-2., -1.)) && alike(G, P(-2., 1.))) ? 1.0 : 0.0;
    float endT = (thinV && nH && !eB && alike(D, G) && alike(F, I) && !eq(D, A) && !eq(F, C) && alike(E, P(0., 2.)) && alike(G, P(-1., 2.)) && alike(I, P(1., 2.))) ? 1.0 : 0.0;
    float endB = (thinV && nB && !eH && alike(D, A) && alike(F, C) && !eq(D, G) && !eq(F, I) && alike(E, P(0., -2.)) && alike(A, P(-1., -2.)) && alike(C, P(1., -2.))) ? 1.0 : 0.0;
    vec4 tip = vec4(max(endL, endT), max(endR, endT), max(endR, endB), max(endL, endB));
    tip *= vec4(greaterThan(pair * 255.0, vec4(XBRZ_TIP)));
    res *= 1.0 - tip;
  }
  return res;
}

void main()
{
  //---------------------------------------
  // Input Pixel Mapping:  -|x|x|x|-
  //                       x|A|B|C|x
  //                       x|D|E|F|x
  //                       x|G|H|I|x
  //                       -|x|x|x|-

  vec2 pos = fract(vTexCoord * SRC_SIZE.xy) - vec2(0.5, 0.5);
  vec2 coord = vTexCoord - pos * SRC_SIZE.zw;

  vec3 A = P(-1.,-1.);
  vec3 B = P( 0.,-1.);
  vec3 C = P( 1.,-1.);
  vec3 D = P(-1., 0.);
  vec3 E = P( 0., 0.);
  vec3 F = P( 1., 0.);
  vec3 G = P(-1., 1.);
  vec3 H = P( 0., 1.);
  vec3 I = P( 1., 1.);

  // blendResult Mapping: x|y|
  //                      w|z|
  ivec4 blendResult = ivec4(BLEND_NONE,BLEND_NONE,BLEND_NONE,BLEND_NONE);

  // Preprocess corners
  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|-|B|C|-
  //                    -|D|E|F|x
  //                    -|G|H|I|x
  //                    -|-|x|x|-
  if (!((eq(E,F) && eq(H,I)) || (eq(E,H) && eq(F,I))))
  {
    float dist_H_F = DistYCbCr(G, E) + DistYCbCr(E, C) + DistYCbCr(P(0.,2.), I) + DistYCbCr(I, P(2.,0.)) + (4.0 * DistYCbCr(H, F));
    float dist_E_I = DistYCbCr(D, H) + DistYCbCr(H, P(1.,2.)) + DistYCbCr(B, F) + DistYCbCr(F, P(2.,1.)) + (4.0 * DistYCbCr(E, I));
    bool dominantGradient = (DOM_E * dist_H_F) < dist_E_I;
    blendResult.z = ((dist_H_F < dist_E_I) && neq(E,F) && neq(E,H)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
  }

  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|A|B|-|-
  //                    x|D|E|F|-
  //                    x|G|H|I|-
  //                    -|x|x|-|-
  if (!((eq(D,E) && eq(G,H)) || (eq(D,G) && eq(E,H))))
  {
    float dist_G_E = DistYCbCr(P(-2.,1.)  , D) + DistYCbCr(D, B) + DistYCbCr(P(-1.,2.), H) + DistYCbCr(H, F) + (4.0 * DistYCbCr(G, E));
    float dist_D_H = DistYCbCr(P(-2.,0.)  , G) + DistYCbCr(G, P(0.,2.)) + DistYCbCr(A, E) + DistYCbCr(E, I) + (4.0 * DistYCbCr(D, H));
    bool dominantGradient = (DOM_E * dist_D_H) < dist_G_E;
    blendResult.w = ((dist_G_E > dist_D_H) && neq(E,D) && neq(E,H)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
  }

  // Pixel Tap Mapping: -|-|x|x|-
  //                    -|A|B|C|x
  //                    -|D|E|F|x
  //                    -|-|H|I|-
  //                    -|-|-|-|-
  if (!((eq(B,C) && eq(E,F)) || (eq(B,E) && eq(C,F))))
  {
    float dist_E_C = DistYCbCr(D, B) + DistYCbCr(B, P(1.,-2.)) + DistYCbCr(H, F) + DistYCbCr(F, P(2.,-1.)) + (4.0 * DistYCbCr(E, C));
    float dist_B_F = DistYCbCr(A, E) + DistYCbCr(E, I) + DistYCbCr(P(0.,-2.), C) + DistYCbCr(C, P(2.,0.)) + (4.0 * DistYCbCr(B, F));
    bool dominantGradient = (DOM_E * dist_B_F) < dist_E_C;
    blendResult.y = ((dist_E_C > dist_B_F) && neq(E,B) && neq(E,F)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
  }

  // Pixel Tap Mapping: -|x|x|-|-
  //                    x|A|B|C|-
  //                    x|D|E|F|-
  //                    -|G|H|-|-
  //                    -|-|-|-|-
  if (!((eq(A,B) && eq(D,E)) || (eq(A,D) && eq(B,E))))
  {
    float dist_D_B = DistYCbCr(P(-2.,0.), A) + DistYCbCr(A, P(0.,-2.)) + DistYCbCr(G, E) + DistYCbCr(E, C) + (4.0 * DistYCbCr(D, B));
    float dist_A_E = DistYCbCr(P(-2.,-1.), D) + DistYCbCr(D, H) + DistYCbCr(P(-1.,-2.), B) + DistYCbCr(B, F) + (4.0 * DistYCbCr(A, E));
    bool dominantGradient = (DOM_E * dist_D_B) < dist_A_E;
    blendResult.x = ((dist_D_B < dist_A_E) && neq(E,D) && neq(E,B)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
  }

  vec4 res = vec4(blendResult);

  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|-|B|C|-
  //                    -|D|E|F|x
  //                    -|G|H|I|x
  //                    -|-|x|x|-
  if(blendResult.z == BLEND_DOMINANT || (blendResult.z == BLEND_NORMAL &&
    !((blendResult.y != BLEND_NONE && !IsPixEqual(E, G)) || (blendResult.w != BLEND_NONE && !IsPixEqual(E, C)) ||
     (IsPixEqual(G, H) && IsPixEqual(H, I) && IsPixEqual(I, F) && IsPixEqual(F, C) && !IsPixEqual(E, I)))))
  {
    res.z += 4.0;
    float dist_F_G = DistYCbCr(F, G);
    float dist_H_C = DistYCbCr(H, C);
    if((STEEP_E * dist_F_G <= dist_H_C) && neq(E,G) && neq(D,G))
      res.z += 16.0;
    if((STEEP_E * dist_H_C <= dist_F_G) && neq(E,C) && neq(B,C))
      res.z += 64.0;
  }

  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|A|B|-|-
  //                    x|D|E|F|-
  //                    x|G|H|I|-
  //                    -|x|x|-|-
  if(blendResult.w == BLEND_DOMINANT || (blendResult.w == BLEND_NORMAL &&
    !((blendResult.z != BLEND_NONE && !IsPixEqual(E, A)) || (blendResult.x != BLEND_NONE && !IsPixEqual(E, I)) ||
     (IsPixEqual(A, D) && IsPixEqual(D, G) && IsPixEqual(G, H) && IsPixEqual(H, I) && !IsPixEqual(E, G)))))
  {
    res.w += 4.0;
    float dist_H_A = DistYCbCr(H, A);
    float dist_D_I = DistYCbCr(D, I);
    if((STEEP_E * dist_H_A <= dist_D_I) && neq(E,A) && neq(B,A))
      res.w += 16.0;
    if((STEEP_E * dist_D_I <= dist_H_A) && neq(E,I) && neq(F,I))
      res.w += 64.0;
  }

  // Pixel Tap Mapping: -|-|x|x|-
  //                    -|A|B|C|x
  //                    -|D|E|F|x
  //                    -|-|H|I|-
  //                    -|-|-|-|-
  if(blendResult.y == BLEND_DOMINANT || (blendResult.y == BLEND_NORMAL &&
    !((blendResult.x != BLEND_NONE && !IsPixEqual(E, I)) || (blendResult.z != BLEND_NONE && !IsPixEqual(E, A)) ||
     (IsPixEqual(I, F) && IsPixEqual(F, C) && IsPixEqual(C, B) && IsPixEqual(B, A) && !IsPixEqual(E, C)))))
  {
    res.y += 4.0;
    float dist_B_I = DistYCbCr(B, I);
    float dist_F_A = DistYCbCr(F, A);
    if((STEEP_E * dist_B_I <= dist_F_A) && neq(E,I) && neq(H,I))
      res.y += 16.0;
    if((STEEP_E * dist_F_A <= dist_B_I) && neq(E,A) && neq(D,A))
      res.y += 64.0;
  }

  // Pixel Tap Mapping: -|x|x|-|-
  //                    x|A|B|C|-
  //                    x|D|E|F|-
  //                    -|G|H|-|-
  //                    -|-|-|-|-
  if(blendResult.x == BLEND_DOMINANT || (blendResult.x == BLEND_NORMAL &&
    !((blendResult.w != BLEND_NONE && !IsPixEqual(E, C)) || (blendResult.y != BLEND_NONE && !IsPixEqual(E, G)) ||
     (IsPixEqual(C, B) && IsPixEqual(B, A) && IsPixEqual(A, D) && IsPixEqual(D, G) && !IsPixEqual(E, A)))))
  {
    res.x += 4.0;
    float dist_D_C = DistYCbCr(D, C);
    float dist_B_G = DistYCbCr(B, G);
    if((STEEP_E * dist_D_C <= dist_B_G) && neq(E,C) && neq(F,C))
      res.x += 16.0;
    if((STEEP_E * dist_B_G <= dist_D_C) && neq(E,G) && neq(H,G))
      res.x += 64.0;
  }

  // Decisions for the output pass, made once per input pixel instead of once per output pixel:
  // +8 when a corner blends with its second candidate colour (ties go to the first, as in xBRZ).
  float dEB = DistYCbCr(E, B);
  float dED = DistYCbCr(E, D);
  float dEF = DistYCbCr(E, F);
  float dEH = DistYCbCr(E, H);
  vec4 second = vec4(dED <= dEB ? 0.0 : 1.0, dEB <= dEF ? 0.0 : 1.0, dEF <= dEH ? 0.0 : 1.0, dEH <= dED ? 0.0 : 1.0);
  res += 8.0 * second;
  // minimum contrast: a corner whose two colors (the pixel and its closer blend candidate) differ by
  // less than XBRZ_MINC stays square
  if (XBRZ_MINC > 0.0)
  {
    vec4 contrast = vec4(min(dED, dEB), min(dEB, dEF), min(dEF, dEH), min(dEH, dED)) * 255.0;
    res *= vec4(greaterThanEqual(contrast, vec4(XBRZ_MINC)));
  }
  res = diagonalRules(res, coord, A, B, C, D, E, F, G, H, I, dEB, dED, dEF, dEH);

  FRAG_OUT = res / 255.0;
}

#endif
