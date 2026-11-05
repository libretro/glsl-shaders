// xBRZ freescale, multipass: xBRZ at any scale factor, in three passes.
//
// Two optional rules, both off by default (plain xBRZ); the xbrz-crisp preset turns them on:
// - XBRZ_MINC (crisp: 20) leaves a corner square when its two colors differ by less than this
//   (x/255, YCbCr distance), so soft shading and textures keep their pixels.
// - XBRZ_DIAG (crisp: 100) leaves a corner square when the two colors its cut would join differ
//   by more than this, so a junction of three colors is not pulled into a fake diagonal (an idea
//   from torcado's cleanEdge, MIT license). Antialiasing ramps use 92, shallow and steep lines are
//   only blocked when they would cut a pixel with a lighter color, a blocked corner is still cut
//   when a neighbour on the same diagonal is cut or at the tip of a 1-pixel diagonal stripe, a cut
//   between two close inner tones runs up to a darker outline, a corner whose blend color runs
//   straight on stays square, two dark strokes meeting in an L around a light gap (an eye) are
//   not joined, and where 1-pixel stripes end flush (gauges, health bars) the end corners stay
//   square.
//   The shallow and steep line tests also weigh hue a little more than lightness (1.2x).
//   A pixel closed in a row between two near-black outline pixels is not pulled out of it.
//
// The first pass makes every blend decision once per input pixel (blend type, line type, blend
// color and the minimum contrast) and the resolve pass, also once per input pixel, settles the
// ones that depend on the neighbours' decisions, so the output pass, which runs once per output
// pixel, only reads two textures where no corner is cut. Blend color ties and the order of the
// four corners follow the reference C++ xBRZ, and the output pass reads the image from the pass
// before xBRZ, so it also works after other shaders in a preset.
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

// The decision of each corner of E (x top-left, y top-right, z bottom-right, w bottom-left), written
// to the info texture as a number from 0 to 255:
//   BLEND(r)       blend type: 0 none, 1 normal, 2 dominant, 3 weak (rule 1: the resolve pass decides)
//   FLAG(r, 4.0)   xBRZ's line blend (without it only the tip of the corner is cut)
//   FLAG(r, 8.0)   the corner blends with the second of its two candidate colors
//   FLAG(r, 16.0)  shallow line
//   FLAG(r, 32.0)  the line was found only because hue weighs more (rule 9)
//   FLAG(r, 64.0)  steep line
//   FLAG(r, 128.0) blocked by the diagonal limit (rule 2: the resolve pass decides)
// The candidate colors of the corners x, y, z and w are D or B, B or F, F or H and H or D. Below, the
// one a corner blends with is P and the other one Q.
#define BLEND(r) mod(r, 4.0)
#define FLAG(r, f) mod(floor((r) / (f)), 2.0)

// ---- crisp tunables (XBRZ_MINC and XBRZ_DIAG are in the menu) ----
#define XBRZ_HYST 4.0       // 1. a corner this close below XBRZ_MINC is weak
#define XBRZ_DIAG_AA 92.0   // 2. diagonal limit on antialiasing ramps
#define XBRZ_RAMP 1.15      // 2, 6. a ramp: (d(E,P) + d(P,Q)) / d(E,Q) up to this
#define XBRZ_STRIPE 64.0    // 2, 3. a diagonal stripe keeps a close color (within this) along its length
#define XBRZ_OUTLINE 0.15   // 2, 3. an outline is darker (in luma) than both inner tones by this much
#define XBRZ_TIP 36.0       // 7. stripe ends stay square above this diagonal distance
#define XBRZ_AA_LINE 1.01   // 8. E lies between the colors: d(P1,E) + d(E,P2) up to this times d(P1,P2)
#define XBRZ_AA_EDGE 40.0   // 8. the two colors differ by at least this
#define alike(a,b) (DistYCbCr(a, b) * 255.0 <= 20.0)
#define eq(a,b)  (a == b)
#define neq(a,b) (a != b)

// the ring of pixels two steps from E (the 5x5 window without its corners), read once in main
vec3 N_m1_m2, N_p0_m2, N_p1_m2, N_m2_m1, N_p2_m1, N_m2_p0, N_p2_p0, N_m2_p1, N_p2_p1, N_m1_p2, N_p0_p2, N_p1_p2;

const vec3 lumaW = vec3(0.2627, 0.6780, 0.0593);

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

// The distance is symmetric, and below the two pixels of each distance (and of alike and IsPixEqual) are
// written in one fixed order (A to I, then the ring of pixels two steps away), so the compiler computes
// each distance only once. The pixels two steps away are read once, at the start of main.
bool IsPixEqual(vec3 pixA, vec3 pixB)
{
  return (DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE);
}

// ============================================================================================
// 9. Line shapes
// ============================================================================================
// the extra distance for the shallow and steep line tests (a line passes with it or with xBRZ's):
// with the crisp rules on (XBRZ_DIAG > 0) hue weighs 1.2x more than lightness, scaled so that as
// many neighbour pairs pass the thresholds
float DistShape(vec3 pixA, vec3 pixB)
{
  const vec3 w = vec3(0.2627, 0.6780, 0.0593);
  const float scaleB = 0.5 / (1.0 - 0.0593);
  const float scaleR = 0.5 / (1.0 - 0.2627);
  vec2 k = XBRZ_DIAG > 0.0 ? vec2(0.937, 1.125) : vec2(1.0);
  vec3 diff = pixA - pixB;
  float y = dot(diff.rgb, w);
  float Y = k.x * y;
  float Cb = k.y * scaleB * (diff.b - y);
  float Cr = k.y * scaleR * (diff.r - y);
  return sqrt((Y * Y) + (Cb * Cb) + (Cr * Cr));
}

// a line xBRZ finds that the hue-weighted test does not is kept too, except where it would bring
// back a corner blocked by the diagonal limit (rule 2), or where the line's color runs on along a
// 45-degree diagonal in the same color while the line test pairs it with a different one (alt45)
bool plainLine(vec3 a, vec3 b, vec3 c, vec3 d, float pairD, bool alt45)
{
  return STEEP_E * DistYCbCr(a, b) <= DistYCbCr(c, d) && pairD * 255.0 <= XBRZ_DIAG && !alt45;
}

// a shallow or steep line found only because hue weighs more (DistShape) between two different
// colors is flagged +32, so the resolve pass can drop it where it runs into the neighbour's line
float toneLine(vec3 a, vec3 b, vec3 c, vec3 d)
{
  return float(!IsPixEqual(a, b) && STEEP_E * DistYCbCr(a, b) > DistYCbCr(c, d));
}

// a line found only because hue weighs more (+32) is dropped where the pixel at its far end is closer
// to E than to the line's color: that pixel belongs to E's side, so the line would cut into E's run.
// It is also dropped where its two colors clearly differ (more than 36) and the line's color runs on
// along a 45-degree diagonal in the same color (alt45, as for plainLine): the line would bend that
// diagonal toward another stroke (the tip of Goku's nose in Buu's Fury)
bool farTone(vec3 a, vec3 b, vec3 c, vec3 d, vec3 E, bool alt45)
{
  return !(toneLine(a, b, c, d) > 0.5 && (DistYCbCr(E, b) < DistYCbCr(a, b) || (alt45 && DistYCbCr(a, b) * 255.0 > 36.0)));
}

// ============================================================================================
// 1. Minimum contrast
// ============================================================================================
// a corner whose two colors (E and its closer candidate) differ by less than XBRZ_MINC stays square;
// one up to XBRZ_HYST below the limit is kept but marked weak afterwards (weakCorners)
vec4 minimumContrast(vec4 res, float dEB, float dED, float dEF, float dEH, out vec4 contrast, out vec4 weak)
{
  weak = vec4(0.0);
  contrast = vec4(0.0);
  if (XBRZ_MINC > 0.0)
  {
    contrast = vec4(min(dED, dEB), min(dEB, dEF), min(dEF, dEH), min(dEH, dED)) * 255.0;
    weak = vec4(greaterThanEqual(contrast, vec4(XBRZ_MINC - XBRZ_HYST))) * vec4(lessThan(contrast, vec4(XBRZ_MINC)));
    res *= max(vec4(greaterThanEqual(contrast, vec4(XBRZ_MINC))), weak);
  }
  return res;
}

// a weak corner that is still cut after rules 2 to 7 gets blend type 3: the resolve pass rounds it
// only where the same corner of both neighbours along the cut is rounded
vec4 weakCorners(vec4 res, vec4 weak)
{
  weak *= vec4(greaterThan(BLEND(res), vec4(0.0)));
  return res + weak * (3.0 - BLEND(res));
}

// ============================================================================================
// helpers for rules 3 and 4
// ============================================================================================
// P's stroke ends at its pixel o - side: no pixel of P's color right after it, straight on (o) or diagonally (o +- side)
float strokeEnds(vec3 p, vec2 coord, vec2 o, vec2 side)
{
  return float(!alike(p, P(o.x, o.y)) && !alike(p, P(o.x + side.x, o.y + side.y)) && !alike(p, P(o.x - side.x, o.y - side.y)));
}

// the pixel at t is part of a straight horizontal or vertical line of its color, 3 pixels or more (a wall)
float wallAt(vec2 coord, vec2 t)
{
  vec3 T = P(t.x, t.y);
  bool l = alike(T, P(t.x - 1., t.y)), r = alike(T, P(t.x + 1., t.y)), u = alike(T, P(t.x, t.y - 1.)), d = alike(T, P(t.x, t.y + 1.));
  return float((l && (r || alike(T, P(t.x - 2., t.y)))) || (r && alike(T, P(t.x + 2., t.y))) ||
               (u && (d || alike(T, P(t.x, t.y - 2.)))) || (d && alike(T, P(t.x, t.y + 2.))));
}

// E's color runs on along the diagonal d and the first pixel past the run (up to 3 pixels) is a wall
float runWall(vec3 E, vec2 coord, vec2 d)
{
  if (!alike(E, P(d.x, d.y))) return wallAt(coord, d);
  if (!alike(E, P(2. * d.x, 2. * d.y))) return wallAt(coord, 2. * d);
  if (!alike(E, P(3. * d.x, 3. * d.y))) return wallAt(coord, 3. * d);
  return 1.0;
}

// ============================================================================================
// Rules 2 to 7 (XBRZ_DIAG)
// ============================================================================================
vec4 diagonalRules(vec4 res, vec2 coord, vec3 A, vec3 B, vec3 C, vec3 D, vec3 E, vec3 F, vec3 G, vec3 H, vec3 I,
                   float dEB, float dED, float dEF, float dEH)
{
  // only pixels that still have a corner to cut
  vec4 cut = vec4(greaterThan(BLEND(res), vec4(0.0)));
  if (XBRZ_DIAG <= 0.0 || dot(cut, vec4(1.0)) <= 0.0)
    return res;
  // the decisions before rules 2 to 7: rules 4 to 6 bring corners back to them
  vec4 before = res;

  // ---- what the rules look at ----
  // the two colors on each corner's diagonal: top-left D-B, top-right B-F, bottom-right F-H, bottom-left H-D
  vec4 pair = vec4(DistYCbCr(B, D), DistYCbCr(B, F), DistYCbCr(F, H), DistYCbCr(D, H));
  // E's distance to the first and second candidate of each corner
  vec4 dEP = vec4(dED, dEB, dEF, dEH);
  vec4 dEQ = vec4(dEB, dEF, dEH, dED);
  // P and Q of each corner (FLAG 8: P is the second candidate)
  vec4 sec = FLAG(res, 8.0);
  vec3 Px = sec.x > 0.5 ? B : D, Py = sec.y > 0.5 ? F : B, Pz = sec.z > 0.5 ? H : F, Pw = sec.w > 0.5 ? D : H;
  vec3 Qx = sec.x > 0.5 ? D : B, Qy = sec.y > 0.5 ? B : F, Qz = sec.z > 0.5 ? F : H, Qw = sec.w > 0.5 ? H : D;
  float lE = dot(E, lumaW);
  vec4 lP = vec4(dot(Px, lumaW), dot(Py, lumaW), dot(Pz, lumaW), dot(Pw, lumaW));
  vec4 lQ = vec4(dot(Qx, lumaW), dot(Qy, lumaW), dot(Qz, lumaW), dot(Qw, lumaW));
  // dark keeps its pixel: P is not lighter than E
  vec4 notLighter = vec4(lessThanEqual(lP, vec4(lE + 4.0 / 255.0)));
  // P runs straight on away from the corner (a horizontal or vertical line or frame)
  vec4 straight = vec4(float(sec.x > 0.5 ? alike(B, C) : alike(D, G)), float(sec.y > 0.5 ? alike(F, I) : alike(A, B)),
                       float(sec.z > 0.5 ? alike(G, H) : alike(C, F)), float(sec.w > 0.5 ? alike(A, D) : alike(H, I)));
  // the pixel two steps from E through P (R), the pixel on the far side of P from Q (S), and the pixel
  // next to R on E's side (U)
  vec3 Rx = sec.x > 0.5 ? N_p0_m2 : N_m2_p0, Ry = sec.y > 0.5 ? N_p2_p0 : N_p0_m2;
  vec3 Rz = sec.z > 0.5 ? N_p0_p2 : N_p2_p0, Rw = sec.w > 0.5 ? N_m2_p0 : N_p0_p2;
  vec3 Sx = sec.x > 0.5 ? C : G, Sy = sec.y > 0.5 ? I : A, Sz = sec.z > 0.5 ? G : C, Sw = sec.w > 0.5 ? A : I;
  vec3 Ux = sec.x > 0.5 ? N_p1_m2 : N_m2_p1, Uy = sec.y > 0.5 ? N_p2_p1 : N_m1_m2;
  vec3 Uz = sec.z > 0.5 ? N_m1_p2 : N_p2_m1, Uw = sec.w > 0.5 ? N_m2_m1 : N_p1_p2;

  // ---- 2. Diagonal limit ----
  // a ramp: one diagonal color lies (almost) on the way from E to the other one
  vec4 ramp = min((dEP + pair) / max(dEQ, vec4(1e-5)), (dEQ + pair) / max(dEP, vec4(1e-5)));
  vec4 limit = mix(vec4(XBRZ_DIAG), vec4(XBRZ_DIAG_AA), vec4(lessThanEqual(ramp, vec4(XBRZ_RAMP))));
  // within the limit, or a shallow or steep line (+16, +64) that does not cut a pixel lighter than P
  vec4 keep = max(vec4(lessThanEqual(pair * 255.0, limit)), vec4(greaterThanEqual(res, vec4(16.0))) * notLighter);
  // diagonal stripe tips: P is a 1-pixel stripe that runs on along the cut (a close color two pixels
  // away from E) and E's color runs on along its other side, so the tip is drawn to the edge
  vec4 tipLine;
  tipLine.x = sec.x > 0.5 ? float(alike(C, E) && min(DistYCbCr(B, N_p0_m2), DistYCbCr(B, N_p1_m2)) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(E, G) && min(DistYCbCr(D, N_m2_p0), DistYCbCr(D, N_m2_p1)) * 255.0 <= XBRZ_STRIPE);
  tipLine.y = sec.y > 0.5 ? float(alike(E, I) && min(DistYCbCr(F, N_p2_p0), DistYCbCr(F, N_p2_p1)) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(A, E) && min(DistYCbCr(B, N_p0_m2), DistYCbCr(B, N_m1_m2)) * 255.0 <= XBRZ_STRIPE);
  tipLine.z = sec.z > 0.5 ? float(alike(E, G) && min(DistYCbCr(H, N_p0_p2), DistYCbCr(H, N_m1_p2)) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(C, E) && min(DistYCbCr(F, N_p2_p0), DistYCbCr(F, N_p2_m1)) * 255.0 <= XBRZ_STRIPE);
  tipLine.w = sec.w > 0.5 ? float(alike(A, E) && min(DistYCbCr(D, N_m2_p0), DistYCbCr(D, N_m2_m1)) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(E, I) && min(DistYCbCr(H, N_p0_p2), DistYCbCr(H, N_p1_p2)) * 255.0 <= XBRZ_STRIPE);
  keep = max(keep, tipLine);
  // inner line up to the outline: E and P are close tones (within XBRZ_DIAG) and Q is an outline darker
  // than both, so the cut runs between the inner tones and the outline stays whole. A straight P is
  // left straight, and the steps of a 1-pixel stripe along the outline (a gauge) stay square
  // E's color goes on past E away from Q, so E is wider than a 1-pixel stripe along Q
  vec4 wide = vec4(float(alike(E, sec.x > 0.5 ? F : H)), float(alike(E, sec.y > 0.5 ? H : D)),
                   float(alike(E, sec.z > 0.5 ? D : B)), float(alike(E, sec.w > 0.5 ? B : F)));
  // E is the corner of a solid block of its color (E's color goes on past E on both far sides and
  // between them), so a dot of another color next to it does not round the block's corner
  vec4 block = wide * vec4(float(alike(E, sec.x > 0.5 ? H : F) && alike(E, I)), float(alike(E, sec.y > 0.5 ? D : H) && alike(E, G)),
                           float(alike(E, sec.z > 0.5 ? B : D) && alike(A, E)), float(alike(E, sec.w > 0.5 ? F : B) && alike(C, E)));
  vec4 lR = vec4(dot(Rx, lumaW), dot(Ry, lumaW), dot(Rz, lumaW), dot(Rw, lumaW));
  vec4 lU = vec4(dot(Ux, lumaW), dot(Uy, lumaW), dot(Uz, lumaW), dot(Uw, lumaW));
  vec4 dEPc = mix(dEP, dEQ, sec);
  vec4 inner = vec4(lessThanEqual(dEPc * 255.0, vec4(XBRZ_DIAG))) * vec4(lessThan(lQ, min(lP, vec4(lE)) - XBRZ_OUTLINE))
             * notLighter * (1.0 - straight) * wide * (1.0 - block);
  // the artist's corner bevel: P is a single antialiasing pixel in a corner of the outline (E's color on
  // its far side, the outline beyond it and turning back along E's side), so the corner is already
  // rounded and the line does not round the pixel next to it again
  vec4 bevel = vec4(float(alike(E, Sx)), float(alike(E, Sy)), float(alike(E, Sz)), float(alike(E, Sw)))
             * vec4(lessThan(max(lR, lU), min(lP, vec4(lE)) - XBRZ_OUTLINE));
  inner *= 1.0 - bevel;
  keep = max(keep, inner);
  // a blocked corner is flagged (+128); the resolve pass cuts it only where it continues a cut line.
  // When P runs straight on, the corner is dropped instead, so a diagonal stops at a frame
  res += 128.0 * (1.0 - keep) * cut;
  res *= 1.0 - (1.0 - keep) * straight * cut;

  // ---- 3. Eye ----
  // two dark strokes of different colors meet in an L around a 1-pixel light gap E, like a pupil under
  // an eyebrow: Q passes the corner, P is a short 1-pixel line that ends against it. The corner is
  // dropped, so the two strokes are not joined into a diagonal
  vec4 eye = vec4(float(!alike(Px, Qx) && alike(Qx, A) && !alike(Px, A) && !alike(Px, Rx) && !alike(E, sec.x > 0.5 ? H : F)),
                  float(!alike(Py, Qy) && alike(Qy, C) && !alike(Py, C) && !alike(Py, Ry) && !alike(E, sec.y > 0.5 ? D : H)),
                  float(!alike(Pz, Qz) && alike(Qz, I) && !alike(Pz, I) && !alike(Pz, Rz) && !alike(E, sec.z > 0.5 ? B : D)),
                  float(!alike(Pw, Qw) && alike(Qw, G) && !alike(Pw, G) && !alike(Pw, Rw) && !alike(E, sec.w > 0.5 ? F : B)))
          * straight * cut * vec4(lessThan(max(lP, lQ), vec4(lE - XBRZ_OUTLINE)));
  // E is not part of a diagonal stripe along the cut
  float stripeCG = float(min(DistYCbCr(C, E), DistYCbCr(E, G)) * 255.0 <= XBRZ_STRIPE);
  float stripeAI = float(min(DistYCbCr(A, E), DistYCbCr(E, I)) * 255.0 <= XBRZ_STRIPE);
  eye *= 1.0 - vec4(stripeCG, stripeAI, stripeCG, stripeAI);
  if (dot(eye, vec4(1.0)) > 0.0)
  {
    eye *= vec4(sec.x > 0.5 ? strokeEnds(Px, coord, vec2(2.,-1.), vec2(0.,1.)) : strokeEnds(Px, coord, vec2(-1.,2.), vec2(1.,0.)),
                sec.y > 0.5 ? strokeEnds(Py, coord, vec2(1.,2.), vec2(1.,0.)) : strokeEnds(Py, coord, vec2(-2.,-1.), vec2(0.,1.)),
                sec.z > 0.5 ? strokeEnds(Pz, coord, vec2(-2.,1.), vec2(0.,1.)) : strokeEnds(Pz, coord, vec2(1.,-2.), vec2(1.,0.)),
                sec.w > 0.5 ? strokeEnds(Pw, coord, vec2(-1.,-2.), vec2(1.,0.)) : strokeEnds(Pw, coord, vec2(2.,1.), vec2(0.,1.)));
    res *= 1.0 - eye;
  }

  // ---- 4. Diagonal up to the wall ----
  // a corner changed by rules 2 and 3 goes back to its decision before them when E's color runs on as a
  // 45-degree diagonal parallel to the cut (C or G for the / corners, A or I for the \ ones) up to a wall
  // at one end, and the neighbour on that diagonal sits on the same 45-degree step (or E's color runs 3
  // pixels along it), like hair or the corner of a fence post
  vec4 kept = vec4(0.0), loneP = vec4(0.0), loneQ = vec4(0.0);
  if (any(notEqual(res, before)))
  {
    // not where P and Q are both lone pixels (no neighbour of their own color in a cross), like an eye.
    // B, D, F and H are each lone when none of their other three cross neighbours has their color; the
    // first and second blend candidates of the corners x y z w are D B F H and B F H D
    vec4 lone = vec4(float(!alike(A, B) && !alike(B, C) && !alike(B, N_p0_m2)), float(!alike(A, D) && !alike(D, G) && !alike(D, N_m2_p0)),
                     float(!alike(C, F) && !alike(F, I) && !alike(F, N_p2_p0)), float(!alike(G, H) && !alike(H, I) && !alike(H, N_p0_p2)));
    loneP = mix(lone.yxzw, lone.xzwy, sec);
    loneQ = mix(lone.xzwy, lone.yxzw, sec);
    // E's color runs on along a diagonal of a cut corner (the partner test below needs it): the rest only there
    vec4 diagE = vec4(float(alike(C, E) || alike(E, G)), float(alike(A, E) || alike(E, I)),
                      float(alike(C, E) || alike(E, G)), float(alike(A, E) || alike(E, I))) * cut;
    if (dot(diagE, vec4(1.0)) > 0.0)
    {
    // the neighbour of E's color on the diagonal differs from both pixels beside its own corner
    vec4 partner = vec4(
      float((alike(C, E) && !alike(B, C) && !alike(C, N_p1_m2)) || (alike(E, G) && !alike(G, N_m2_p1) && !alike(D, G))),
      float((alike(A, E) && !alike(A, N_m1_m2) && !alike(A, B)) || (alike(E, I) && !alike(F, I) && !alike(I, N_p2_p1))),
      float((alike(C, E) && !alike(C, N_p2_m1) && !alike(C, F)) || (alike(E, G) && !alike(G, H) && !alike(G, N_m1_p2))),
      float((alike(A, E) && !alike(A, D) && !alike(A, N_m2_m1)) || (alike(E, I) && !alike(I, N_p1_p2) && !alike(H, I))));
    float l3CG = float((alike(C, E) && alike(E, P(2., -2.))) || (alike(E, G) && alike(E, P(-2., 2.))));
    float l3AI = float((alike(A, E) && alike(E, P(-2., -2.))) || (alike(E, I) && alike(E, P(2., 2.))));
    partner = max(partner, vec4(l3CG, l3AI, l3CG, l3AI));
    // E ends a straight line of its color, 3 pixels or more, that runs away from the corner
    float lineR = float(alike(E, F) && alike(E, N_p2_p0)), lineL = float(alike(D, E) && alike(E, N_m2_p0));
    float lineD = float(alike(E, H) && alike(E, N_p0_p2)), lineU = float(alike(B, E) && alike(E, N_p0_m2));
    vec4 endLine = vec4(max(lineR, lineD), max(lineL, lineD), max(lineL, lineU), max(lineR, lineU));
    // Q runs straight on away from the corner, or passes through it for 2 pixels (straightQ0) or 3 (straightQ)
    vec4 straightQ = vec4(float(sec.x > 0.5 ? alike(D, G) : alike(B, C)), float(sec.y > 0.5 ? alike(A, B) : alike(F, I)),
                          float(sec.z > 0.5 ? alike(C, F) : alike(G, H)), float(sec.w > 0.5 ? alike(H, I) : alike(A, D)));
    vec4 straightQ0 = max(straightQ, vec4(float(alike(Qx, A)), float(alike(Qy, C)), float(alike(Qz, I)), float(alike(Qw, G))));
    straightQ = max(straightQ, vec4(float(alike(Qx, A) && alike(Qx, sec.x > 0.5 ? N_m1_m2 : N_m2_m1)),
                                    float(alike(Qy, C) && alike(Qy, sec.y > 0.5 ? N_p2_m1 : N_p1_m2)),
                                    float(alike(Qz, I) && alike(Qz, sec.z > 0.5 ? N_p1_p2 : N_p2_p1)),
                                    float(alike(Qw, G) && alike(Qw, sec.w > 0.5 ? N_m2_p1 : N_m1_p2))));
    // E is a 1-pixel stripe along P; there Q bends when it passes the corner for only 2 pixels
    float sH = float(!alike(B, E) && !alike(E, H) && !alike(B, H)), sV = float(!alike(D, E) && !alike(E, F) && !alike(D, F));
    vec4 stripeE = vec4(sec.x > 0.5 ? sH : sV, sec.y > 0.5 ? sV : sH, sec.z > 0.5 ? sH : sV, sec.w > 0.5 ? sV : sH);
    vec4 bendQ = straightQ0 * (1.0 - straightQ) * stripeE;
    vec4 sQ = mix(straightQ0, straightQ, stripeE);
    // Q runs on along the cut: the pixel after Q in the cut's direction has Q's color
    vec3 Qnx = sec.x > 0.5 ? N_m2_p1 : N_p1_m2, Qny = sec.y > 0.5 ? N_m1_m2 : N_p2_p1;
    vec3 Qnz = sec.z > 0.5 ? N_p2_m1 : N_m1_p2, Qnw = sec.w > 0.5 ? N_p1_p2 : N_m2_m1;
    vec4 qRun = vec4(float(alike(Qx, Qnx)), float(alike(Qy, Qny)), float(alike(Qz, Qnz)), float(alike(Qw, Qnw)));
    // not where P and Q both run straight (a right-angle junction), where a straight P is a darker line
    // or E ends a straight line beside it (unless Q bends), or where a straight P meets a Q that neither
    // runs straight nor along the cut
    vec4 run = partner * (1.0 - straight * sQ) * (1.0 - straight * vec4(lessThan(lP, vec4(lE))) * (1.0 - bendQ))
             * (1.0 - endLine * straight * (1.0 - bendQ)) * (1.0 - straight * (1.0 - straightQ0) * (1.0 - qRun)) * cut;
    run *= 1.0 - loneP * loneQ;
    // E's diagonal runs up to a wall (only where the rest passes: up to 24 reads)
    if (dot(run, vec4(1.0)) > 0.0)
    {
      float wCG = run.x + run.z > 0.0 ? max(runWall(E, coord, vec2(1., -1.)), runWall(E, coord, vec2(-1., 1.))) : 0.0;
      float wAI = run.y + run.w > 0.0 ? max(runWall(E, coord, vec2(1., 1.)), runWall(E, coord, vec2(-1., -1.))) : 0.0;
      run *= vec4(wCG, wAI, wCG, wAI);
    }
    res = mix(res, before, run);
    kept = run;
    }
  }

  // ---- 5. Thin light stroke ----
  // a blocked corner comes back where E is a 1-pixel stroke lighter than both diagonal colors that runs
  // on along the diagonal of the cut (E's color in C or G for the / corners, A or I for the \ ones, not
  // on E's far side), like the white strokes of letters or a ring with gray antialiasing
  // only a changed corner where E is lighter than both colors, and not between two lone pixels (like an eye)
  vec4 back = vec4(greaterThan(vec4(lE) - max(lP, lQ), vec4(0.15))) * cut * vec4(notEqual(res, before)) * (1.0 - loneP * loneQ);
  if (dot(back, vec4(1.0)) > 0.0)
  {
    // E's color, or a tone closer to E than the corner's two colors (an antialiasing step), goes on along the diagonal
    vec4 dPQmin = min(mix(dEP, dEQ, sec), mix(dEQ, dEP, sec));
    float eC = DistYCbCr(C, E), eG = DistYCbCr(E, G), eA = DistYCbCr(A, E), eI = DistYCbCr(E, I);
    // a diagonal neighbour counts only when the stroke really bends there: the cross neighbour beside it on E's far side
    // is not E's tone too (a peak on top of a straight line is not a diagonal stroke)
    vec4 tE = 0.6 * dPQmin;
    bvec4 aD = bvec4(alike(C, E), alike(E, G), alike(A, E), alike(E, I));
    bvec4 nD = bvec4(aD.x || eC < tE.x, aD.y || eG < tE.x, aD.z || eA < tE.y, aD.w || eI < tE.y);
    bvec4 nD2 = bvec4(aD.x || eC < tE.z, aD.y || eG < tE.z, aD.z || eA < tE.w, aD.w || eI < tE.w);
    float fB = DistYCbCr(B, E), fD = DistYCbCr(D, E), fF = DistYCbCr(E, F), fH = DistYCbCr(E, H);
    // x: C beside F, G beside H; y: A beside D, I beside H; z: C beside B, G beside D; w: A beside B, I beside F
    vec4 sideA = vec4(float(aD.x && !(fF < tE.x)) + float(aD.y && !(fH < tE.x)), float(aD.z && !(fD < tE.y)) + float(aD.w && !(fH < tE.y)),
                      float(aD.x && !(fB < tE.z)) + float(aD.y && !(fD < tE.z)), float(aD.z && !(fB < tE.w)) + float(aD.w && !(fF < tE.w)));
    vec4 sideN = vec4(float(nD.x && !(fF < tE.x)) + float(nD.y && !(fH < tE.x)), float(nD.z && !(fD < tE.y)) + float(nD.w && !(fH < tE.y)),
                      float(nD2.x && !(fB < tE.z)) + float(nD2.y && !(fD < tE.z)), float(nD2.z && !(fB < tE.w)) + float(nD2.w && !(fF < tE.w)));
    sideA = min(sideA, vec4(1.0)); sideN = min(sideN, vec4(1.0));
    vec4 farOff = vec4(float(!alike(E, I)), float(!alike(E, G)), float(!alike(A, E)), float(!alike(C, E)));
    vec4 along = sideA * farOff;
    along = max(along, sideA * vec4(lessThan(max(lP, lQ), vec4(0.45))));
    along = max(along, sideN * farOff);
    back *= along;
    res = mix(res, before, back);
    kept = max(kept, back);
  }

  // ---- 6. Antialiasing notch ----
  // a corner blocked on an antialiasing ramp comes back where P is a single antialiasing pixel between E
  // and Q (the ramp runs E, P, Q and the diagonal is within XBRZ_DIAG + 45), Q's tone wraps around P in
  // the outer corner (A, C, I, G) and E's tone runs on along the cut (C or G for the / corners, A or I
  // for the \ ones), like the shaded edges of a cape
  if (any(notEqual(res, before)))
  {
    vec4 dPc = mix(dEP, dEQ, sec), dQc = mix(dEQ, dEP, sec);
    vec4 notch = vec4(lessThanEqual((dPc + pair) / max(dQc, vec4(1e-5)), vec4(XBRZ_RAMP))) * vec4(lessThanEqual(pair * 255.0, vec4(XBRZ_DIAG + 45.0)))
               * loneP * cut * vec4(notEqual(res, before));
    // the color tests only where a notch can come back
    if (dot(notch, vec4(1.0)) > 0.0)
    {
      vec4 wrap = vec4(lessThan(vec4(DistYCbCr(A, Qx), DistYCbCr(C, Qy), DistYCbCr(I, Qz), DistYCbCr(G, Qw)), 0.6 * pair));
      // E's tone in a diagonal neighbour X: closer to E than to P and Q by 0.6
      float eA = DistYCbCr(A, E), eC = DistYCbCr(C, E), eG = DistYCbCr(E, G), eI = DistYCbCr(E, I);
      vec4 onC = vec4(lessThan(vec4(eC), 0.6 * min(vec4(DistYCbCr(Px, C), DistYCbCr(Py, C), DistYCbCr(Pz, C), DistYCbCr(Pw, C)),
                                                   vec4(DistYCbCr(Qx, C), DistYCbCr(Qy, C), DistYCbCr(Qz, C), DistYCbCr(Qw, C)))));
      vec4 onG = vec4(lessThan(vec4(eG), 0.6 * min(vec4(DistYCbCr(Px, G), DistYCbCr(Py, G), DistYCbCr(Pz, G), DistYCbCr(Pw, G)),
                                                   vec4(DistYCbCr(Qx, G), DistYCbCr(Qy, G), DistYCbCr(Qz, G), DistYCbCr(Qw, G)))));
      vec4 onA = vec4(lessThan(vec4(eA), 0.6 * min(vec4(DistYCbCr(Px, A), DistYCbCr(Py, A), DistYCbCr(Pz, A), DistYCbCr(Pw, A)),
                                                   vec4(DistYCbCr(Qx, A), DistYCbCr(Qy, A), DistYCbCr(Qz, A), DistYCbCr(Qw, A)))));
      vec4 onI = vec4(lessThan(vec4(eI), 0.6 * min(vec4(DistYCbCr(Px, I), DistYCbCr(Py, I), DistYCbCr(Pz, I), DistYCbCr(Pw, I)),
                                                   vec4(DistYCbCr(Qx, I), DistYCbCr(Qy, I), DistYCbCr(Qz, I), DistYCbCr(Qw, I)))));
      vec4 along = vec4(max(onC.x, onG.x), max(onA.y, onI.y), max(onC.z, onG.z), max(onA.w, onI.w));
      notch *= wrap * along;
      res = mix(res, before, notch);
      kept = max(kept, notch);
    }
  }

  // ---- 7. Stripe ends ----
  // E ends a 1-pixel horizontal line (left or right end) or vertical line (top or bottom end); a corner
  // brought back by rules 4 to 6 is left as it is
  bool eB = eq(E, B), eD = eq(E, D), eF = eq(E, F), eH = eq(E, H);
  // the stripes on both sides differ from each other too, so outlines (same color on both sides) are left alone;
  // E's stripe may also be 2 pixels wide (E's color on one side and not 2 pixels away)
  vec3 fB = eB ? N_p0_m2 : N_p0_p2, fD = eD ? N_m2_p0 : N_p2_p0;
  bool thinH = !eq(B, H) && ((!eB && !eH) || (eB != eH && !eq(fB, E)));
  bool thinV = !eq(D, F) && ((!eD && !eF) || (eD != eF && !eq(fD, E)));
  // only where a corner that is still cut, and not brought back by rules 4 to 6, could be squared
  vec4 open4 = vec4(greaterThan(BLEND(res), vec4(0.0))) * vec4(greaterThan(pair * 255.0, vec4(XBRZ_TIP))) * (1.0 - kept);
  if ((thinH || thinV) && dot(open4, vec4(1.0)) > 0.0)
  {
    // the stripes only need to keep a similar color (within 20/255) along their length, so a background
    // with a slight gradient still counts as one stripe
    bool nB = alike(B, E), nD = alike(D, E), nF = alike(E, F), nH = alike(E, H);
    // the cheap terms of each end first (the stripes beside E end where E ends); the rest only where one passes
    bool cL = thinH && nF && !eD && !eq(B, A) && !eq(H, G) && alike(B, C) && alike(H, I);
    bool cR = thinH && nD && !eF && !eq(B, C) && !eq(H, I) && alike(A, B) && alike(G, H);
    bool cT = thinV && nH && !eB && !eq(D, A) && !eq(F, C) && alike(D, G) && alike(F, I);
    bool cB = thinV && nB && !eH && !eq(D, G) && !eq(F, I) && alike(A, D) && alike(C, F);
    if (cL || cR || cT || cB)
    {
    // only inside a stack of parallel stripes: the rows (or columns) on both sides run along the line too
    // and they all end flush at the same column (or row), like the stripes of a gauge
    // all three stripes run at least 3 pixels back from the end, and E's 4 when the color past the
    // end runs straight on (a line meeting a short stripe, not a gauge); E is not an end when its
    // color runs on along a diagonal past the end (a line turning diagonal, like the bottom of a 3)
    float endL = 0.0;
    if (cL) endL = (thinH && nF && !eD && !(alike(A, E) && alike(E, P(-2., -2.)) && !alike(D, E) && !alike(B, E)) && !(alike(E, G) && alike(E, P(-2., 2.)) && !alike(D, E) && !alike(E, H)) && !(alike(A, E) && alike(B, D)) && !(alike(E, G) && alike(D, H)) && alike(B, C) && alike(H, I) && !eq(B, A) && !eq(H, G) && alike(E, N_p2_p0) && (alike(E, P(3., 0.)) || !eq(D, N_m2_p0)) && alike(C, N_p2_m1) && alike(I, N_p2_p1)) ? 1.0 : 0.0;
    float endR = 0.0;
    if (cR) endR = (thinH && nD && !eF && !(alike(C, E) && alike(E, P(2., -2.)) && !alike(E, F) && !alike(B, E)) && !(alike(E, I) && alike(E, P(2., 2.)) && !alike(E, F) && !alike(E, H)) && !(alike(C, E) && alike(B, F)) && !(alike(E, I) && alike(F, H)) && alike(A, B) && alike(G, H) && !eq(B, C) && !eq(H, I) && alike(E, N_m2_p0) && (alike(E, P(-3., 0.)) || !eq(F, N_p2_p0)) && alike(A, N_m2_m1) && alike(G, N_m2_p1)) ? 1.0 : 0.0;
    float endT = 0.0;
    if (cT) endT = (thinV && nH && !eB && !(alike(A, E) && alike(E, P(-2., -2.)) && !alike(B, E) && !alike(D, E)) && !(alike(C, E) && alike(E, P(2., -2.)) && !alike(B, E) && !alike(E, F)) && !(alike(A, E) && alike(B, D)) && !(alike(C, E) && alike(B, F)) && alike(D, G) && alike(F, I) && !eq(D, A) && !eq(F, C) && alike(E, N_p0_p2) && (alike(E, P(0., 3.)) || !eq(B, N_p0_m2)) && alike(G, N_m1_p2) && alike(I, N_p1_p2)) ? 1.0 : 0.0;
    float endB = 0.0;
    if (cB) endB = (thinV && nB && !eH && !(alike(E, G) && alike(E, P(-2., 2.)) && !alike(E, H) && !alike(D, E)) && !(alike(E, I) && alike(E, P(2., 2.)) && !alike(E, H) && !alike(E, F)) && !(alike(E, G) && alike(D, H)) && !(alike(E, I) && alike(F, H)) && alike(A, D) && alike(C, F) && !eq(D, G) && !eq(F, I) && alike(E, N_p0_m2) && (alike(E, P(0., -3.)) || !eq(H, N_p0_p2)) && alike(A, N_m1_m2) && alike(C, N_p1_m2)) ? 1.0 : 0.0;
    vec4 tip = vec4(max(endL, endT), max(endR, endT), max(endR, endB), max(endL, endB));
    tip *= vec4(greaterThan(pair * 255.0, vec4(XBRZ_TIP)));
    // E's stripe is not a stripe of its own where a side stripe is a close tone of it (an inner tone of a shaded
    // area): there a corner that xBRZ cuts with a line between two outline colors darker than E is not a stripe
    // end, so the outline goes on as a diagonal (the forehead under Gohan's hair in Buu's Fury)
    float aH = float((nB && !eB) || (nH && !eH)), aV = float((nD && !eD) || (nF && !eF));
    vec4 soft = vec4(max(endL * aH, endT * aV), max(endR * aH, endT * aV), max(endR * aH, endB * aV), max(endL * aH, endB * aV));
    soft *= vec4(lessThan(max(lP, lQ), vec4(lE - XBRZ_OUTLINE)));
    tip *= 1.0 - soft * min(FLAG(res, 16.0) + FLAG(res, 64.0), vec4(1.0));
    res *= 1.0 - tip * (1.0 - kept);
    }
  }
  return res;
}

// ============================================================================================
// 8. Line through an antialiasing pixel
// ============================================================================================
// when one corner is a cut line and the opposite corner is a line that rule 1 squared or left weak,
// and E lies between their two blend colors on a strong edge, the opposite corner goes back to its
// xBRZ decision, so a line through an antialiasing pixel cuts both halves of it, as in xBRZ
vec4 lineThroughAA(vec4 res, vec4 xbrz, vec4 contrast, vec3 B, vec3 D, vec3 E, vec3 F, vec3 H)
{
  if (XBRZ_MINC <= 0.0)
    return res;
  vec4 cut = vec4(greaterThan(BLEND(res), vec4(0.0))) * vec4(lessThan(BLEND(res), vec4(3.0))) * FLAG(res, 4.0);
  vec4 sq = vec4(lessThan(contrast, vec4(XBRZ_MINC))) * vec4(greaterThan(BLEND(xbrz), vec4(0.0))) * FLAG(xbrz, 4.0)
          * vec4(notEqual(BLEND(res), vec4(1.0))) * vec4(notEqual(BLEND(res), vec4(2.0)));
  vec4 pair = sq * cut.zwxy;
  if (dot(pair, vec4(1.0)) <= 0.0)
    return res;
  // the blend colors of the four corners
  vec4 sc = FLAG(xbrz, 8.0);
  vec3 Cx = sc.x > 0.5 ? B : D, Cy = sc.y > 0.5 ? F : B, Cz = sc.z > 0.5 ? H : F, Cw = sc.w > 0.5 ? D : H;
  float dXZ = DistYCbCr(Cx, Cz), dYW = DistYCbCr(Cy, Cw);
  float bxz = float(DistYCbCr(Cx, E) + DistYCbCr(E, Cz) <= XBRZ_AA_LINE * dXZ && dXZ * 255.0 >= XBRZ_AA_EDGE);
  float byw = float(DistYCbCr(Cy, E) + DistYCbCr(E, Cw) <= XBRZ_AA_LINE * dYW && dYW * 255.0 >= XBRZ_AA_EDGE);
  return mix(res, xbrz, pair * vec4(bxz, byw, bxz, byw));
}

// ============================================================================================
// 10. Pixel closed between outlines
// ============================================================================================
// the blend color P is a pixel closed in a straight row (or column) between two pixels of a dark
// outline color Q, and Q also takes the corner's other neighbour, in an L around P: a line test that
// reads Q on both sides of P as one line would pull P toward E, so the corner stays square
vec4 closedPixel(vec4 res, vec3 A, vec3 B, vec3 C, vec3 D, vec3 E, vec3 F, vec3 G, vec3 H, vec3 I)
{
  // only where xBRZ found a shallow or steep line
  vec4 line = min(FLAG(res, 16.0) + FLAG(res, 64.0), 1.0) * vec4(greaterThan(BLEND(res), vec4(0.0)));
  if (XBRZ_DIAG <= 0.0 || dot(line, vec4(1.0)) <= 0.0)
    return res;
  vec4 sc = FLAG(res, 8.0);
  // Q (A, C, I, G for the corners x, y, z, w) is an outline close to black, darker than both E and P
  vec3 Px = sc.x > 0.5 ? B : D, Py = sc.y > 0.5 ? F : B, Pz = sc.z > 0.5 ? H : F, Pw = sc.w > 0.5 ? D : H;
  vec4 lQ = vec4(dot(A, lumaW), dot(C, lumaW), dot(I, lumaW), dot(G, lumaW));
  vec4 lP = vec4(dot(Px, lumaW), dot(Py, lumaW), dot(Pz, lumaW), dot(Pw, lumaW));
  vec4 dark = vec4(lessThan(lQ + 0.1, lP)) * vec4(lessThan(lQ + 0.1, vec4(dot(E, lumaW)))) * vec4(lessThan(lQ, vec4(0.15)));
  vec4 closed = dark * line;
  if (dot(closed, vec4(1.0)) <= 0.0)
    return res;
  // P is closed in a row between two pixels of Q's color, which also takes the corner's other neighbour
  bool sx = sc.x > 0.5 ? (alike(A, C) && alike(A, D) && !alike(A, B) && !alike(A, E)) : (alike(A, G) && alike(A, B) && !alike(A, D) && !alike(A, E));
  bool sy = sc.y > 0.5 ? (alike(C, I) && alike(B, C) && !alike(C, F) && !alike(C, E)) : (alike(A, C) && alike(C, F) && !alike(B, C) && !alike(C, E));
  bool sz = sc.z > 0.5 ? (alike(G, I) && alike(F, I) && !alike(H, I) && !alike(E, I)) : (alike(C, I) && alike(H, I) && !alike(F, I) && !alike(E, I));
  bool sw = sc.w > 0.5 ? (alike(A, G) && alike(G, H) && !alike(D, G) && !alike(E, G)) : (alike(G, I) && alike(D, G) && !alike(G, H) && !alike(E, G));
  closed *= vec4(sx, sy, sz, sw);
  return res * (1.0 - closed);
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

  vec3 B = P( 0.,-1.);
  vec3 D = P(-1., 0.);
  vec3 E = P( 0., 0.);
  vec3 F = P( 1., 0.);
  vec3 H = P( 0., 1.);
  // fast path: xBRZ blends a corner only where E differs from both pixels beside it, so where E equals a side
  // neighbour at every corner nothing is cut and only the second-color bits (+8) and rule 1 are left
  if ((eq(E,F) || eq(E,H)) && (eq(E,H) || eq(E,D)) && (eq(E,D) || eq(E,B)) && (eq(E,B) || eq(E,F)))
  {
    float fEB = DistYCbCr(B, E);
    float fED = DistYCbCr(D, E);
    float fEF = DistYCbCr(E, F);
    float fEH = DistYCbCr(E, H);
    vec4 fres = 8.0 * vec4(fED <= fEB ? 0.0 : 1.0, fEB <= fEF ? 0.0 : 1.0, fEF <= fEH ? 0.0 : 1.0, fEH <= fED ? 0.0 : 1.0);
    vec4 fcontrast, fweak;
    fres = minimumContrast(fres, fEB, fED, fEF, fEH, fcontrast, fweak);
    FRAG_OUT = fres / 255.0;
    return;
  }
  vec3 A = P(-1.,-1.);
  vec3 C = P( 1.,-1.);
  vec3 G = P(-1., 1.);
  vec3 I = P( 1., 1.);
  N_m1_m2 = P(-1., -2.);
  N_p0_m2 = P(0., -2.);
  N_p1_m2 = P(1., -2.);
  N_m2_m1 = P(-2., -1.);
  N_p2_m1 = P(2., -1.);
  N_m2_p0 = P(-2., 0.);
  N_p2_p0 = P(2., 0.);
  N_m2_p1 = P(-2., 1.);
  N_p2_p1 = P(2., 1.);
  N_m1_p2 = P(-1., 2.);
  N_p0_p2 = P(0., 2.);
  N_p1_p2 = P(1., 2.);

  // ============================================================================================
  // xBRZ: the reference decisions (only the line tests use DistShape and toneLine, rule 9)
  // ============================================================================================

  // blendResult Mapping: x|y|
  //                      w|z|
  ivec4 blendResult = ivec4(BLEND_NONE,BLEND_NONE,BLEND_NONE,BLEND_NONE);

  // the color distances of the four corner tests below, each computed once
  float d_E_G = DistYCbCr(E, G);
  float d_C_E = DistYCbCr(C, E);
  float d_I_p0p2 = DistYCbCr(I, N_p0_p2);
  float d_I_p2p0 = DistYCbCr(I, N_p2_p0);
  float d_F_H = DistYCbCr(F, H);
  float d_D_H = DistYCbCr(D, H);
  float d_H_p1p2 = DistYCbCr(H, N_p1_p2);
  float d_B_F = DistYCbCr(B, F);
  float d_F_p2p1 = DistYCbCr(F, N_p2_p1);
  float d_E_I = DistYCbCr(E, I);
  float d_D_m2p1 = DistYCbCr(D, N_m2_p1);
  float d_B_D = DistYCbCr(B, D);
  float d_H_m1p2 = DistYCbCr(H, N_m1_p2);
  float d_G_m2p0 = DistYCbCr(G, N_m2_p0);
  float d_G_p0p2 = DistYCbCr(G, N_p0_p2);
  float d_A_E = DistYCbCr(A, E);
  float d_B_p1m2 = DistYCbCr(B, N_p1_m2);
  float d_F_p2m1 = DistYCbCr(F, N_p2_m1);
  float d_C_p0m2 = DistYCbCr(C, N_p0_m2);
  float d_C_p2p0 = DistYCbCr(C, N_p2_p0);
  float d_A_m2p0 = DistYCbCr(A, N_m2_p0);
  float d_A_p0m2 = DistYCbCr(A, N_p0_m2);
  float d_D_m2m1 = DistYCbCr(D, N_m2_m1);
  float d_B_m1m2 = DistYCbCr(B, N_m1_m2);

  // Preprocess corners
  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|-|B|C|-
  //                    -|D|E|F|x
  //                    -|G|H|I|x
  //                    -|-|x|x|-
  if (!((eq(E,F) && eq(H,I)) || (eq(E,H) && eq(F,I))))
  {
    float dist_H_F = d_E_G + d_C_E + d_I_p0p2 + d_I_p2p0 + (4.0 * d_F_H);
    float dist_E_I = d_D_H + d_H_p1p2 + d_B_F + d_F_p2p1 + (4.0 * d_E_I);
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
    float dist_G_E = d_D_m2p1 + d_B_D + d_H_m1p2 + d_F_H + (4.0 * d_E_G);
    float dist_D_H = d_G_m2p0 + d_G_p0p2 + d_A_E + d_E_I + (4.0 * d_D_H);
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
    float dist_E_C = d_B_D + d_B_p1m2 + d_F_H + d_F_p2m1 + (4.0 * d_C_E);
    float dist_B_F = d_A_E + d_E_I + d_C_p0m2 + d_C_p2p0 + (4.0 * d_B_F);
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
    float dist_D_B = d_A_m2p0 + d_A_p0m2 + d_E_G + d_C_E + (4.0 * d_B_D);
    float dist_A_E = d_D_m2m1 + d_D_H + d_B_m1m2 + d_B_F + (4.0 * d_A_E);
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
    !((blendResult.y != BLEND_NONE && !IsPixEqual(E, G)) || (blendResult.w != BLEND_NONE && !IsPixEqual(C, E)) ||
     (IsPixEqual(G, H) && IsPixEqual(H, I) && IsPixEqual(F, I) && IsPixEqual(C, F) && !IsPixEqual(E, I)))))
  {
    res.z += 4.0;
    float dist_F_G = DistShape(F, G);
    float dist_H_C = DistShape(H, C);
    if((((STEEP_E * dist_F_G <= dist_H_C) && farTone(F, G, H, C, E, eq(N_m1_p2, H) && !eq(G, H))) || plainLine(F, G, H, C, DistYCbCr(F, H), eq(N_m1_p2, H) && !eq(G, H))) && neq(E,G) && neq(D,G))
      res.z += 16.0 + 32.0 * toneLine(F, G, H, C);
    if((((STEEP_E * dist_H_C <= dist_F_G) && farTone(H, C, F, G, E, eq(N_p2_m1, F) && !eq(C, F))) || plainLine(H, C, F, G, DistYCbCr(F, H), eq(N_p2_m1, F) && !eq(C, F))) && neq(E,C) && neq(B,C))
      res.z += 64.0 + 32.0 * toneLine(H, C, F, G);
  }

  // Pixel Tap Mapping: -|-|-|-|-
  //                    -|A|B|-|-
  //                    x|D|E|F|-
  //                    x|G|H|I|-
  //                    -|x|x|-|-
  if(blendResult.w == BLEND_DOMINANT || (blendResult.w == BLEND_NORMAL &&
    !((blendResult.z != BLEND_NONE && !IsPixEqual(A, E)) || (blendResult.x != BLEND_NONE && !IsPixEqual(E, I)) ||
     (IsPixEqual(A, D) && IsPixEqual(D, G) && IsPixEqual(G, H) && IsPixEqual(H, I) && !IsPixEqual(E, G)))))
  {
    res.w += 4.0;
    float dist_H_A = DistShape(H, A);
    float dist_D_I = DistShape(D, I);
    if((((STEEP_E * dist_H_A <= dist_D_I) && farTone(H, A, D, I, E, eq(N_m2_m1, D) && !eq(A, D))) || plainLine(H, A, D, I, DistYCbCr(D, H), eq(N_m2_m1, D) && !eq(A, D))) && neq(E,A) && neq(B,A))
      res.w += 16.0 + 32.0 * toneLine(H, A, D, I);
    if((((STEEP_E * dist_D_I <= dist_H_A) && farTone(D, I, H, A, E, eq(N_p1_p2, H) && !eq(I, H))) || plainLine(D, I, H, A, DistYCbCr(D, H), eq(N_p1_p2, H) && !eq(I, H))) && neq(E,I) && neq(F,I))
      res.w += 64.0 + 32.0 * toneLine(D, I, H, A);
  }

  // Pixel Tap Mapping: -|-|x|x|-
  //                    -|A|B|C|x
  //                    -|D|E|F|x
  //                    -|-|H|I|-
  //                    -|-|-|-|-
  if(blendResult.y == BLEND_DOMINANT || (blendResult.y == BLEND_NORMAL &&
    !((blendResult.x != BLEND_NONE && !IsPixEqual(E, I)) || (blendResult.z != BLEND_NONE && !IsPixEqual(A, E)) ||
     (IsPixEqual(F, I) && IsPixEqual(C, F) && IsPixEqual(B, C) && IsPixEqual(A, B) && !IsPixEqual(C, E)))))
  {
    res.y += 4.0;
    float dist_B_I = DistShape(B, I);
    float dist_F_A = DistShape(F, A);
    if((((STEEP_E * dist_B_I <= dist_F_A) && farTone(B, I, F, A, E, eq(N_p2_p1, F) && !eq(I, F))) || plainLine(B, I, F, A, DistYCbCr(B, F), eq(N_p2_p1, F) && !eq(I, F))) && neq(E,I) && neq(H,I))
      res.y += 16.0 + 32.0 * toneLine(B, I, F, A);
    if((((STEEP_E * dist_F_A <= dist_B_I) && farTone(F, A, B, I, E, eq(N_m1_m2, B) && !eq(A, B))) || plainLine(F, A, B, I, DistYCbCr(B, F), eq(N_m1_m2, B) && !eq(A, B))) && neq(E,A) && neq(D,A))
      res.y += 64.0 + 32.0 * toneLine(F, A, B, I);
  }

  // Pixel Tap Mapping: -|x|x|-|-
  //                    x|A|B|C|-
  //                    x|D|E|F|-
  //                    -|G|H|-|-
  //                    -|-|-|-|-
  if(blendResult.x == BLEND_DOMINANT || (blendResult.x == BLEND_NORMAL &&
    !((blendResult.w != BLEND_NONE && !IsPixEqual(C, E)) || (blendResult.y != BLEND_NONE && !IsPixEqual(E, G)) ||
     (IsPixEqual(B, C) && IsPixEqual(A, B) && IsPixEqual(A, D) && IsPixEqual(D, G) && !IsPixEqual(A, E)))))
  {
    res.x += 4.0;
    float dist_D_C = DistShape(D, C);
    float dist_B_G = DistShape(B, G);
    if((((STEEP_E * dist_D_C <= dist_B_G) && farTone(D, C, B, G, E, eq(N_p1_m2, B) && !eq(C, B))) || plainLine(D, C, B, G, DistYCbCr(B, D), eq(N_p1_m2, B) && !eq(C, B))) && neq(E,C) && neq(F,C))
      res.x += 16.0 + 32.0 * toneLine(D, C, B, G);
    if((((STEEP_E * dist_B_G <= dist_D_C) && farTone(B, G, D, C, E, eq(N_m2_p1, D) && !eq(G, D))) || plainLine(B, G, D, C, DistYCbCr(B, D), eq(N_m2_p1, D) && !eq(G, D))) && neq(E,G) && neq(H,G))
      res.x += 64.0 + 32.0 * toneLine(B, G, D, C);
  }

  // Decisions for the output pass, made once per input pixel instead of once per output pixel:
  // +8 when a corner blends with its second candidate colour (ties go to the first, as in xBRZ).
  float dEB = DistYCbCr(B, E);
  float dED = DistYCbCr(D, E);
  float dEF = DistYCbCr(E, F);
  float dEH = DistYCbCr(E, H);
  vec4 second = vec4(dED <= dEB ? 0.0 : 1.0, dEB <= dEF ? 0.0 : 1.0, dEF <= dEH ? 0.0 : 1.0, dEH <= dED ? 0.0 : 1.0);
  res += 8.0 * second;

  // ============================================================================================
  // the crisp rules, in order
  // ============================================================================================
  vec4 xbrz = res;
  vec4 contrast, weak;
  res = minimumContrast(res, dEB, dED, dEF, dEH, contrast, weak);              // 1
  res = diagonalRules(res, coord, A, B, C, D, E, F, G, H, I, dEB, dED, dEF, dEH);  // 2 to 7
  res = weakCorners(res, weak);                                                 // 1, weak corners
  res = lineThroughAA(res, xbrz, contrast, B, D, E, F, H);                      // 8
  res = closedPixel(res, A, B, C, D, E, F, G, H, I);                            // 10

  FRAG_OUT = res / 255.0;
}

#endif
