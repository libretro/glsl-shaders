// xBRZ freescale, multipass: xBRZ at any scale factor, in three passes.
//
// Rules 2 and 4 to 7 below keep xBRZ from cutting corners into shapes the artist did not draw
// (fake diagonals at junctions of three colors, bent frames, rounded ends of stripes). They are
// on by default; XBRZ_DIAG = 0 turns them off, for the reference xBRZ shapes. Rules 1, 3 and 8 to
// 13 are the crisp look: with XBRZ_MINC fixed at 0 they compile away in this file. The
// xbrz-crisp preset uses xbrz-crisp-pass0, which has them, with XBRZ_MINC 20, so
// low-contrast shading and textures keep their pixels.
//
// xBRZ decides, for each corner of each pixel, whether to cut it and how (a corner piece, a 45-degree
// line, or a shallow or steep line). The rules below then change some of those decisions. Each rule
// has a section of the same number and name in the code. The first pass (pass 0) makes the decisions,
// the resolve pass, also once per game pixel, finishes rules 1, 2 and 9, which need the neighbours'
// decisions, and the output pass (pass 1) only draws the corners.
//
// 1. Minimum contrast (XBRZ_MINC): a corner whose two colors differ by less than XBRZ_MINC (x/255,
//    YCbCr distance) is left square, so low-contrast shading, dithering and textures (grass,
//    foliage, stone) keep their pixel detail, while outlines, text and sprites are smoothed as in
//    xBRZ. A corner up to 4 below the limit is weak: it is still rounded when the same corner of both
//    neighbours along its cut is rounded, so a diagonal edge has no tooth where its contrast dips.
// 2. Diagonal limit (XBRZ_DIAG): a corner is blocked when the two colors on its diagonal (the colors
//    the cut would join) differ by more than XBRZ_DIAG, so a junction of three different colors is
//    not pulled into a fake diagonal (an idea from torcado's cleanEdge, MIT license).
//    Antialiasing ramps, where one of those colors sits between the pixel and the other one, use 92.
//    A corner is not blocked:
//    - on a shallow or steep line, unless it would cut a pixel with a lighter color, so dark
//      outlines, eyes and eyebrows keep their pixels;
//    - at the tip of a 1-pixel diagonal stripe, so the stripe runs on to the edge;
//    - between two close inner tones next to an outline darker than both, so the cut runs up to the
//      outline, which stays whole (not at the corner of a solid block, along a 1-pixel stripe or next
//      to a corner the artist already rounded with an antialiasing pixel).
//    A blocked corner whose blend color runs straight on, like a frame or a horizontal line, stays
//    square, so lines do not bend where they meet. Any other blocked corner is cut by the resolve pass
//    only where it continues a cut: when a neighbour on the same diagonal is cut, so lines are drawn
//    to the end, or when the neighbour across its edge cuts the other end of that edge with a line in
//    the pixel's color, so the two cuts make one diagonal that ends on a straight edge, like the tip
//    of a lock of hair (that line may also run toward the pixel diagonal to E when it has E's color,
//    so a thin arm closes up to the next color).
// 3. Eye: where two dark strokes of different colors meet in an L around a 1-pixel light gap, like
//    a pupil under an eyebrow, the corner stays square. Not where one stroke ends in the other's
//    color, like a shaded outline: that is one outline, cut as in xBRZ.
// 4. Diagonal up to the wall: a corner changed by rules 2 and 3 comes back as in xBRZ where the
//    pixel's color runs on as a 45-degree diagonal along the cut up to a straight line, like hair or
//    a fence post, unless that would bend a straight line or stretch a lone 1-pixel dot.
// 5. Thin light stroke: it also comes back where a 1-pixel stroke lighter than both colors runs on
//    along the cut, like the white strokes of letters.
// 6. Antialiasing notch: and where a single antialiasing pixel steps along a diagonal edge between
//    two colors, like the shaded edge of a cape.
// 7. Stripe ends: where a stack of 1- or 2-pixel stripes of different colors ends flush, like the
//    bars of a gauge or a striped wall, the end corners stay square when their diagonal colors differ
//    by more than 36, so every stripe ends the same way. A line that turns diagonal at its end is
//    not a stripe end. A stripe only 3 pixels long is left alone when the color past its end
//    runs straight on, like a line meeting it. Nor is a pixel whose side neighbour is a close tone of
//    it, where the end corner is a line between two outline colors darker than it, like a dark outline
//    turning diagonal over a forehead.
// 8. Line through an antialiasing pixel: when a line cuts one corner of a pixel whose color lies
//    between the line's two colors on a strong edge, and rule 1 left the opposite corner square, that
//    corner is cut too, as in xBRZ, so the pixel becomes a thin strip of the diagonal instead of a
//    notch in it.
// 9. Line shapes: the shallow and steep line tests weigh hue a little more than lightness (1.2x), so
//    lines in hue-shifted shading follow the artist's pixels. A line xBRZ finds is kept too, unless it
//    would bring back a corner blocked by rule 2 or the line's color runs on along a 45-degree
//    diagonal in the same color. Where a line found only by the hue weighting, between two
//    different colors, would run into the line of the neighbour across the same edge, it is drawn
//    as in xBRZ. A line found only by the hue weighting is not drawn where the pixel at its far end is
//    closer to the pixel's own color than to the line's, so a diagonal of that color is not cut short
//    (Goku's brow in Buu's Fury), nor where its two colors clearly differ and the line's color runs on
//    along a 45-degree diagonal in the same color (the tip of Goku's nose).
// 10. Pixel closed between outlines: a pixel closed in a straight row between two pixels of a
//     near-black outline that also wraps the corner, like the brown brow between the black lines of
//     Link's eye, is not pulled toward E by a line through the outline; that corner stays square.
// 11. Lines in a larger window: a corner that rule 1 left square is still cut as in xBRZ where it lies
//     on a straight line (45 degrees or 2:1, with regular steps) between two stripes that run on for
//     5 pixels or more, one of them 1 pixel wide against a strong contour, like the inner side of an
//     outline's antialiasing band or the stripes of a bar, so those lines have no teeth.
// 12. Closed shadow: where a near-black shadow runs under an object, like the round shadow under a
//     character's feet, the background pixel in the notch between them gets a wedge of the shadow's
//     color and the shadow's corners next to the notch stay square, so the shadow's outline closes.
//     The shape is read in a 7x7 window (an arm 3 pixels long with background outside it, a solid
//     2x2 lobe, an object bigger than 1 pixel), so serifs, letters and textures are left alone.
//     The floor around the notch may have any color or texture (grass, tiles): it only has to be
//     lighter than the shadow and differ from both the shadow and the object.
// 13. Tiles between walls: in a row of 1-pixel tiles (4 or more, in a repeating pattern) that runs
//     between two straight walls, like the squares of a gauge, a blocked corner between two tiles
//     stays square, so no diagonal is chained through the row.
// XBRZ_DIAG = 0 turns rules 2 to 7, 9, 10, 12 and 13 off, and XBRZ_MINC = 0 turns rules 1, 3 and 8 to
// 13 off, so with XBRZ_MINC at 0 only rules 2 and 4 to 7 run.
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
#pragma parameter XBRZ_DIAG "xBRZ: max color distance on the diagonal (0 = off)" 100 0 160 4

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
#define XBRZ_MINC 0.0
uniform COMPAT_PRECISION float XBRZ_DIAG;
#else
#define XBRZ_TOL 15.0
#define XBRZ_DOM 3.8
#define XBRZ_STEEP 3.2
#define XBRZ_MINC 0.0
#define XBRZ_DIAG 100.0
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

// ---- rule tunables (XBRZ_DIAG is in the menu, XBRZ_MINC is 0) ----
// rules 3, 9, 10, 12 and 13 belong to the crisp look rather than fixing clear xBRZ errors, so they
// run only when XBRZ_MINC is on too (plain xBRZ, with XBRZ_MINC 0, keeps rules 2 and 4 to 7)
#define CRISP_RULES (XBRZ_MINC > 0.0 && XBRZ_DIAG > 0.0)
#define XBRZ_HYST 4.0       // 1. a corner this close below XBRZ_MINC is weak
#define XBRZ_DIAG_AA 92.0   // 2. diagonal limit on antialiasing ramps
#define XBRZ_RAMP 1.15      // 2, 6. a ramp: (d(E,P) + d(P,Q)) / d(E,Q) up to this
#define XBRZ_STRIPE 64.0    // 2, 3. a diagonal stripe keeps a close color (within this) along its length
#define XBRZ_OUTLINE 0.15   // 2, 3. an outline is darker (in luma) than both inner tones by this much
#define XBRZ_TIP 36.0       // 7. stripe ends stay square above this diagonal distance
#define XBRZ_AA_LINE 1.01   // 8. E lies between the colors: d(P1,E) + d(E,P2) up to this times d(P1,P2)
#define XBRZ_AA_EDGE 40.0   // 8. the two colors differ by at least this
#define XBRZ_STRONG 40.0    // 11. the contour past a 1-pixel stripe differs from it by at least this
#define XBRZ_SHADOW 0.10    // 12. a shadow is darker than this (luma)
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
// the extra distance for the shallow and steep line tests with the crisp rules on (a line passes with
// it or with xBRZ's): hue weighs 1.2x more than lightness, scaled so that as many neighbour pairs pass
// the thresholds
float DistShape(vec3 pixA, vec3 pixB)
{
  const vec3 w = vec3(0.2627, 0.6780, 0.0593);
  const float scaleB = 0.5 / (1.0 - 0.0593);
  const float scaleR = 0.5 / (1.0 - 0.2627);
  const vec2 k = vec2(0.937, 1.125);
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

// the shallow (x) and steep (y) line tests of a corner, a line along a-b against one along c-d, as
// the flags they add (+16 and +64, and +32 for a line found only because hue weighs more): xBRZ's own
// test (STEEP_E * d(a, b) <= d(c, d)) without the crisp rules, the hue-weighted one with them
vec2 lineTests(vec3 a, vec3 b, vec3 c, vec3 d, vec3 E, float pairD, bool alt45s, bool alt45t)
{
  if (!CRISP_RULES)
  {
    float ab = DistYCbCr(a, b), cd = DistYCbCr(c, d);
    return vec2(STEEP_E * ab <= cd ? 16.0 : 0.0, STEEP_E * cd <= ab ? 64.0 : 0.0);
  }
  float sab = DistShape(a, b), scd = DistShape(c, d);
  float shallow = (((STEEP_E * sab <= scd) && farTone(a, b, c, d, E, alt45s)) || plainLine(a, b, c, d, pairD, alt45s)) ? 16.0 + 32.0 * toneLine(a, b, c, d) : 0.0;
  float steep = (((STEEP_E * scd <= sab) && farTone(c, d, a, b, E, alt45t)) || plainLine(c, d, a, b, pairD, alt45t)) ? 64.0 + 32.0 * toneLine(c, d, a, b) : 0.0;
  return vec2(shallow, steep);
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
// P's stroke ends at its pixel o - side: no pixel of P's color right after it, straight on (o) or diagonally (o +- side),
// and the pixel straight on is not Q's color either (a shaded outline whose tones step from P to Q is one outline)
float strokeEnds(vec3 p, vec3 q, vec2 coord, vec2 o, vec2 side)
{
  vec3 T = P(o.x, o.y);
  return float(!alike(p, T) && !alike(q, T) && !alike(p, P(o.x + side.x, o.y + side.y)) && !alike(p, P(o.x - side.x, o.y - side.y)));
}

// the pixel at t is part of a straight horizontal or vertical line of its color, 3 pixels or more (a wall)
float wallAt(vec2 coord, vec2 t)
{
  vec3 T = P(t.x, t.y);
  bool l = alike(T, P(t.x - 1., t.y)), r = alike(T, P(t.x + 1., t.y)), u = alike(T, P(t.x, t.y - 1.)), d = alike(T, P(t.x, t.y + 1.));
  return float((l && (r || alike(T, P(t.x - 2., t.y)))) || (r && alike(T, P(t.x + 2., t.y))) ||
               (u && (d || alike(T, P(t.x, t.y - 2.)))) || (d && alike(T, P(t.x, t.y + 2.))));
}

// E's color runs on along the diagonal d and the first pixel past the run (up to 3 pixels) is a wall;
// the run's length k is found first, so the wall test is compiled once
float runWall(vec3 E, vec2 coord, vec2 d)
{
  float k = !alike(E, P(d.x, d.y)) ? 1.0 : !alike(E, P(2. * d.x, 2. * d.y)) ? 2.0 : !alike(E, P(3. * d.x, 3. * d.y)) ? 3.0 : 0.0;
  return k > 0.0 ? wallAt(coord, k * d) : 1.0;
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
  if (CRISP_RULES)
  {
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
      eye *= vec4(sec.x > 0.5 ? strokeEnds(Px, Qx, coord, vec2(2.,-1.), vec2(0.,1.)) : strokeEnds(Px, Qx, coord, vec2(-1.,2.), vec2(1.,0.)),
                  sec.y > 0.5 ? strokeEnds(Py, Qy, coord, vec2(1.,2.), vec2(1.,0.)) : strokeEnds(Py, Qy, coord, vec2(-2.,-1.), vec2(0.,1.)),
                  sec.z > 0.5 ? strokeEnds(Pz, Qz, coord, vec2(-2.,1.), vec2(0.,1.)) : strokeEnds(Pz, Qz, coord, vec2(1.,-2.), vec2(1.,0.)),
                  sec.w > 0.5 ? strokeEnds(Pw, Qw, coord, vec2(-1.,-2.), vec2(1.,0.)) : strokeEnds(Pw, Qw, coord, vec2(2.,1.), vec2(0.,1.)));
      res *= 1.0 - eye;
    }
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
  if (!CRISP_RULES || dot(line, vec4(1.0)) <= 0.0)
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

// ============================================================================================
// 11. Lines in a larger window
// ============================================================================================
// a corner that rule 1 squared is cut as in xBRZ where it lies on a straight boundary between two
// stripes, along the slope xBRZ found for it (45 degrees, or a 2:1 shallow or steep line), read in a
// 7x7 window: E's tone runs on along the boundary on E's side and the corner's two colors run on along
// it on the other side, with every step of a 2:1 line exactly 2 pixels long; E's far side does not
// have the other tone (not a checkerboard); and one of the two stripes is 1 pixel wide with a strong
// contour past it (at least XBRZ_STRONG), so it is a line or the antialiasing band of one, not a band
// of shading or a texture
// X has a's tone against b: closer to a than to b, and alike a
float onTone(vec3 X, vec3 a, vec3 b)
{
  float da = DistYCbCr(X, a);
  return float(da < DistYCbCr(X, b) && da * 255.0 <= 20.0);
}
// X is past a stripe of tone a (next to tone b) on a strong contour: neither tone, and XBRZ_STRONG from a
float strongPx(vec3 X, vec3 a, vec3 b)
{
  return (1.0 - onTone(X, a, b)) * (1.0 - onTone(X, b, a)) * float(DistYCbCr(X, a) * 255.0 >= XBRZ_STRONG);
}
// the pixel at offset o in the corner's own frame (canonical corner: bottom-right, colors F and H)
#define RP(o) P((rot * (o)).x, (rot * (o)).y)

// one corner, in its own frame: shape 0 is a 45-degree boundary, 1 shallow (2:1), 2 steep (1:2)
float stripeLine(vec2 coord, mat2 rot, vec3 E, vec3 Pc, float shape)
{
  // offsets: e1..e4 run on E's side, p1..p5 on the other side (with F and H; p4 and p5 close the steps at
  // both ends, so each step of a 2:1 line is exactly 2 pixels long), f1 f2 are E's far side,
  // o1 o2 o3 the pixels past the other stripe
  vec2 e1, e2, e3, e4, p1, p2, p3, p4, p5, f1, f2, o1, o2, o3;
  if (shape < 0.5)
  {
    e1 = vec2(1., -1.); e2 = vec2(-1., 1.); e3 = vec2(2., -2.); e4 = vec2(-2., 2.);
    p1 = vec2(2., -1.); p2 = vec2(-1., 2.); p3 = p1; p4 = vec2(3., -2.); p5 = vec2(-2., 3.);
    f1 = vec2(0., -1.); f2 = vec2(-1., 0.);
    o1 = vec2(1., 1.); o2 = vec2(2., 0.); o3 = vec2(0., 2.);
  }
  else if (shape < 1.5)
  {
    // E's run is the 2-pixel step D E, then C and the pixel right of it, and the one below-left of D
    e1 = vec2(-1., 0.); e2 = vec2(1., -1.); e3 = vec2(2., -1.); e4 = vec2(-2., 1.);
    p1 = vec2(-1., 1.); p2 = vec2(2., 0.); p3 = vec2(-2., 2.); p4 = vec2(3., -1.); p5 = vec2(-3., 2.);
    f1 = vec2(0., -1.); f2 = vec2(-1., -1.);
    o1 = vec2(1., 1.); o2 = vec2(0., 2.); o3 = vec2(2., 1.);
  }
  else
  {
    e1 = vec2(0., -1.); e2 = vec2(-1., 1.); e3 = vec2(-1., 2.); e4 = vec2(1., -2.);
    p1 = vec2(1., -1.); p2 = vec2(0., 2.); p3 = vec2(2., -2.); p4 = vec2(-1., 3.); p5 = vec2(2., -3.);
    f1 = vec2(-1., 0.); f2 = vec2(-1., -1.);
    o1 = vec2(1., 1.); o2 = vec2(2., 0.); o3 = vec2(1., 2.);
  }
  // a strong contour on one side first (cheap: three reads), since textures seldom have one
  vec3 Fa = RP(f1), Fb = RP(f2), O1 = RP(o1);
  float eStrong = float(min(DistYCbCr(Fa, E), DistYCbCr(Fb, E)) * 255.0 >= XBRZ_STRONG);
  float pStrong = float(DistYCbCr(O1, Pc) * 255.0 >= XBRZ_STRONG);
  if (eStrong + pStrong <= 0.0)
    return 0.0;
  // then the two runs, nearest pixels first
  if (onTone(RP(e1), E, Pc) * onTone(RP(e2), E, Pc) <= 0.0)
    return 0.0;
  float runs = onTone(RP(e3), E, Pc) * onTone(RP(e4), E, Pc)
             * onTone(RP(p1), Pc, E) * onTone(RP(p2), Pc, E) * onTone(RP(p3), Pc, E)
             * onTone(RP(p4), Pc, E) * onTone(RP(p5), Pc, E)
             * (1.0 - onTone(Fa, Pc, E)) * (1.0 - onTone(Fb, Pc, E));
  if (runs <= 0.0)
    return 0.0;
  float eNarrow = eStrong * strongPx(Fa, E, Pc) * strongPx(Fb, E, Pc);
  float pNarrow = pStrong * strongPx(O1, Pc, E) * (1.0 - onTone(RP(o2), Pc, E)) * (1.0 - onTone(RP(o3), Pc, E));
  return max(eNarrow, pNarrow);
}

vec4 diagonalStripes(vec2 coord, vec3 B, vec3 D, vec3 E, vec3 F, vec3 H, float dEB, float dED, float dEF, float dEH, vec4 xb, vec4 sq)
{
  // the slope xBRZ found for each corner (+16 shallow, +64 steep, in the corner's own frame)
  vec4 shape = FLAG(xb, 4.0) * (FLAG(xb, 16.0) + 2.0 * FLAG(xb, 64.0));
  // P the closer candidate of each corner, Q the other one; Q must have P's tone (one stripe)
  vec3 Px = dED <= dEB ? D : B, Qx = dED <= dEB ? B : D;
  vec3 Py = dEB <= dEF ? B : F, Qy = dEB <= dEF ? F : B;
  vec3 Pz = dEF <= dEH ? F : H, Qz = dEF <= dEH ? H : F;
  vec3 Pw = dEH <= dED ? H : D, Qw = dEH <= dED ? D : H;
  sq *= vec4(lessThan(shape, vec4(2.5))) * vec4(onTone(Qx, Px, E), onTone(Qy, Py, E), onTone(Qz, Pz, E), onTone(Qw, Pw, E));
  // one corner at a time, so the test is compiled once (corner z is the canonical frame, the others turned)
  vec4 r = vec4(0.0);
  for (int k = 0; k < 4; k++)
  {
    vec4 m = vec4(equal(vec4(float(k)), vec4(0., 1., 2., 3.)));
    if (dot(sq, m) > 0.0)
    {
      mat2 rot = k == 0 ? mat2(-1., 0., 0., -1.) : (k == 1 ? mat2(0., -1., 1., 0.) : (k == 2 ? mat2(1., 0., 0., 1.) : mat2(0., 1., -1., 0.)));
      vec3 Pc = k == 0 ? Px : (k == 1 ? Py : (k == 2 ? Pz : Pw));
      r += m * stripeLine(coord, rot, E, Pc, dot(shape, m));
    }
  }
  return r;
}


// ============================================================================================
// 12. Closed shadow
// ============================================================================================
// E (background) sits in the notch where a near-black shadow blob runs under another object O (like
// feet over a round shadow): S = P(s) is the shadow's arm beside E, O = P(o) the object, K = P(o - s)
// the shadow on O's other side. The shape is read from a bigger window: the arm runs straight 3
// pixels with background outside it and the object over it, and beyond K the shadow is a solid 2x2
// lobe (a blob, not a 1-pixel stroke like a serif)
bool floorPx(vec3 X, vec3 S, vec3 O, float lS)
{
  return dot(X, lumaW) > lS + 0.15 && !alike(X, S) && !alike(X, O);
}

float shadowClose(vec2 coord, vec3 E, vec2 s, vec2 o)
{
  vec3 S = P(s.x, s.y);
  vec3 O = P(o.x, o.y);
  vec2 k = o - s;
  vec3 K = P(k.x, k.y);
  float lS = dot(S, lumaW);
  if (!(lS < XBRZ_SHADOW && dot(K, lumaW) < XBRZ_SHADOW && dot(E, lumaW) > XBRZ_SHADOW + 0.15 && alike(S, K) && !alike(O, S) && !alike(O, E) && !alike(E, S)
        && lS + 0.15 < dot(E, lumaW) && lS + 0.15 < dot(O, lumaW)))
    return 0.0;
  // the floor around the notch is any pixel lighter than the shadow that is neither the shadow nor the
  // object, so a textured floor (grass, tiles) counts the same as a flat one
  bool bg = floorPx(P(-s.x, -s.y), S, O, lS) && floorPx(P(-o.x, -o.y), S, O, lS);
  bool arm = alike(S, P(2. * s.x, 2. * s.y)) && alike(S, P(3. * s.x, 3. * s.y))
          && floorPx(P(s.x - o.x, s.y - o.y), S, O, lS) && floorPx(P(2. * s.x - o.x, 2. * s.y - o.y), S, O, lS)
          && !alike(S, P(s.x + o.x, s.y + o.y));
  bool lobe = alike(S, P(k.x + o.x, k.y + o.y)) && alike(S, P(k.x + o.x - s.x, k.y + o.y - s.y))
           && alike(S, P(k.x + 2. * o.x, k.y + 2. * o.y)) && alike(S, P(k.x + 2. * o.x - s.x, k.y + 2. * o.y - s.y));
  vec3 O2 = P(2. * o.x, 2. * o.y);
  bool obj = !alike(E, O2) && !alike(S, O2);
  return float(bg && arm && lobe && obj);
}


// ============================================================================================
// 13. Tiles between walls
// ============================================================================================
// E and its neighbour P = E + a are two square tiles of a row of tiles 1 pixel wide (4 tiles or more,
// in a repeating pattern, all lighter or all darker than the walls) that runs between two straight
// walls (Q's side w and the opposite side, 3 pixels or more each): a blocked corner between two tiles
// stays square, so the second pass does not chain a diagonal through the row (Castlevania's gauge)
float tileStripe(vec2 coord, vec3 E, vec2 a, vec2 w)
{
  vec3 P1 = P(a.x, a.y), Q = P(w.x, w.y), Q2 = P(w.x + a.x, w.y + a.y), O = P(-w.x, -w.y), O2 = P(a.x - w.x, a.y - w.y);
  vec3 T0 = P(-a.x, -a.y);
  // first what the 3x3 shows: both walls along E and P, E and P tiles, the pixel before E another tile
  float lE = dot(E, lumaW), lP = dot(P1, lumaW), lQ = dot(Q, lumaW), lO = dot(O, lumaW);
  bool light = min(lE, lP) > max(lQ, lO) + XBRZ_OUTLINE, dark = max(lE, lP) + XBRZ_OUTLINE < min(lQ, lO);
  if (!((light || dark) && alike(Q, Q2) && alike(O, O2) && !alike(E, T0) && !alike(T0, Q) && !alike(T0, O)))
    return 0.0;
  // then the row past P: the walls run on (3 pixels) and the next tile follows the pattern
  vec3 T3 = P(2. * a.x, 2. * a.y);
  bool wallQ = alike(Q, P(w.x - a.x, w.y - a.y)) || alike(Q, P(w.x + 2. * a.x, w.y + 2. * a.y));
  bool wallO = alike(O, P(-w.x - a.x, -w.y - a.y)) || alike(O, P(2. * a.x - w.x, 2. * a.y - w.y));
  bool tiles = !alike(P1, T3) && !alike(T3, Q) && !alike(T3, O) && (alike(T0, P1) || alike(E, T3));
  return float(wallQ && wallO && tiles);
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
    vec2 line = lineTests(F, G, H, C, E, DistYCbCr(F, H), eq(N_m1_p2, H) && !eq(G, H), eq(N_p2_m1, F) && !eq(C, F));
    if (neq(E,G) && neq(D,G)) res.z += line.x;
    if (neq(E,C) && neq(B,C)) res.z += line.y;
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
    vec2 line = lineTests(H, A, D, I, E, DistYCbCr(D, H), eq(N_m2_m1, D) && !eq(A, D), eq(N_p1_p2, H) && !eq(I, H));
    if (neq(E,A) && neq(B,A)) res.w += line.x;
    if (neq(E,I) && neq(F,I)) res.w += line.y;
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
    vec2 line = lineTests(B, I, F, A, E, DistYCbCr(B, F), eq(N_p2_p1, F) && !eq(I, F), eq(N_m1_m2, B) && !eq(A, B));
    if (neq(E,I) && neq(H,I)) res.y += line.x;
    if (neq(E,A) && neq(D,A)) res.y += line.y;
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
    vec2 line = lineTests(D, C, B, G, E, DistYCbCr(B, D), eq(N_p1_m2, B) && !eq(C, B), eq(N_m2_p1, D) && !eq(G, D));
    if (neq(E,C) && neq(F,C)) res.x += line.x;
    if (neq(E,G) && neq(H,G)) res.x += line.y;
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
  // the rules, in order
  // ============================================================================================
  vec4 xbrz = res;
  vec4 contrast, weak;
  res = minimumContrast(res, dEB, dED, dEF, dEH, contrast, weak);              // 1
  // 11. Lines in a larger window: corners squared by rule 1 on a straight line come back
  vec4 sq = vec4(lessThan(contrast, vec4(XBRZ_MINC))) * vec4(greaterThan(BLEND(xbrz), vec4(0.0)));
  if (XBRZ_MINC > 0.0 && dot(sq, vec4(1.0)) > 0.0)
  {
    sq *= diagonalStripes(coord, B, D, E, F, H, dEB, dED, dEF, dEH, xbrz, sq);
    res = mix(res, xbrz, sq);
    weak *= 1.0 - sq;
  }
  res = diagonalRules(res, coord, A, B, C, D, E, F, G, H, I, dEB, dED, dEF, dEH);  // 2 to 7
  res = weakCorners(res, weak);                                                 // 1, weak corners
  res = lineThroughAA(res, xbrz, contrast, B, D, E, F, H);                      // 8
  res = closedPixel(res, A, B, C, D, E, F, G, H, I);                            // 10

  // 12. closed shadow (the notch's corner and, on the shadow's side, the corners next to the notch)
  if (CRISP_RULES)
  {
    float lE = dot(E, lumaW);
    // cheap gates on the 3x3 before the 7x7 tests (cross order B D F H, diagonal order A C G I):
    // dS shadow, dA close to a shadow color, nd not a shadow, bg close to a background lighter than the shadow
    vec4 lX = vec4(dot(B, lumaW), dot(D, lumaW), dot(F, lumaW), dot(H, lumaW));
    vec4 lY = vec4(dot(A, lumaW), dot(C, lumaW), dot(G, lumaW), dot(I, lumaW));
    bvec4 dS = lessThan(lX, vec4(XBRZ_SHADOW)), dSd = lessThan(lY, vec4(XBRZ_SHADOW));
    bvec4 dA = lessThan(lX, vec4(XBRZ_SHADOW + 0.08)), dAd = lessThan(lY, vec4(XBRZ_SHADOW + 0.08));
    bvec4 nd = not(dS), ndd = not(dSd);
    bvec4 bg = greaterThan(lX, vec4(XBRZ_SHADOW + 0.07)), bgd = greaterThan(lY, vec4(XBRZ_SHADOW + 0.07));
    bvec4 lt = greaterThan(lX, vec4(XBRZ_SHADOW + 0.15)), ltd = greaterThan(lY, vec4(XBRZ_SHADOW + 0.15));
    // corner k (x, y, z, w) lies between the directions d = L, U, R, Dn and n = d turned 90 degrees (U, R, Dn, L);
    // the loops run one 7x7 test at a time, so the test is compiled once
    if (lE > XBRZ_SHADOW + 0.15 && any(dS))
    {
      // E is the notch: S = P(s) and K = P(o - s) shadow, O = P(o) not, background at -s, -o and s - o;
      // first candidate (s, o) = (d, n), second (n, d)
      vec4 g1 = vec4(dS.y && dSd.y && nd.x && bg.z && bg.w && bgd.z, dS.x && dSd.w && nd.z && bg.w && bg.y && bgd.x,
                     dS.z && dSd.z && nd.w && bg.y && bg.x && bgd.y, dS.w && dSd.x && nd.y && bg.x && bg.z && bgd.w);
      vec4 g2 = vec4(dS.x && dSd.z && nd.y && bg.w && bg.z && bgd.y, dS.z && dSd.x && nd.x && bg.y && bg.w && bgd.w,
                     dS.w && dSd.y && nd.z && bg.x && bg.y && bgd.z, dS.y && dSd.w && nd.w && bg.z && bg.x && bgd.x);
      vec4 c1 = vec4(0.0), c2 = vec4(0.0);
      vec2 d = vec2(-1., 0.);
      for (int i = 0; i < 8; i++)
      {
        int k = i / 2;
        bool second = i - 2 * k == 1;
        vec2 n = vec2(-d.y, d.x);
        vec4 m = vec4(equal(vec4(float(k)), vec4(0., 1., 2., 3.)));
        if (dot(second ? g2 : g1, m) > 0.0)
        {
          float r = shadowClose(coord, E, second ? n : d, second ? d : n);
          if (second) c2 += m * r; else c1 += m * r;
        }
        if (second) d = n;
      }
      // first candidate as S: x/z with a horizontal arm and y/w with a vertical one take +16; second (+8): +64
      c2 *= 1.0 - c1;
      res = mix(res, vec4(1. + 4. + 16.), c1);
      res = mix(res, vec4(1. + 4. + 8. + 64.), c2);
    }
    else if (lE < XBRZ_SHADOW && (any(lt) || any(ltd)))
    {
      // E is the shadow next to a notch Y: the arm's tip (Y = E + d, O = Y + o diagonal to E) or the lobe's
      // corner (Y = E + s - o diagonal to E, O = E + s); E's corner toward the notch stays square.
      // Candidates for corner k, as (Y, s, o): (d, -d, n), (n, -n, d), (d + n, d, -n), (d + n, n, -d)
      vec4 gT1 = vec4(lt.y && bg.w && bgd.w && dA.z && ndd.x, lt.x && bg.y && bgd.z && dA.w && ndd.y,
                      lt.z && bg.x && bgd.x && dA.y && ndd.w, lt.w && bg.z && bgd.y && dA.x && ndd.z);
      vec4 gT2 = vec4(lt.x && bg.z && bgd.w && dA.w && ndd.x, lt.z && bg.w && bgd.z && dA.y && ndd.y,
                      lt.w && bg.y && bgd.x && dA.x && ndd.w, lt.y && bg.x && bgd.y && dA.z && ndd.z);
      vec4 gK1 = vec4(ltd.x && nd.y && bg.x && dA.w && dAd.w, ltd.y && nd.x && bg.z && dA.y && dAd.z,
                      ltd.w && nd.z && bg.w && dA.x && dAd.x, ltd.z && nd.w && bg.y && dA.z && dAd.y);
      vec4 gK2 = vec4(ltd.x && nd.x && bg.y && dA.z && dAd.w, ltd.y && nd.z && bg.x && dA.w && dAd.z,
                      ltd.w && nd.w && bg.z && dA.y && dAd.x, ltd.z && nd.y && bg.w && dA.x && dAd.y);
      vec4 keepSq = vec4(0.0);
      vec2 d = vec2(-1., 0.);
      for (int i = 0; i < 16; i++)
      {
        int k = i / 4;
        int t = i - 4 * k;
        vec2 n = vec2(-d.y, d.x);
        vec4 m = vec4(equal(vec4(float(k)), vec4(0., 1., 2., 3.)));
        vec4 g = t == 0 ? gT1 : (t == 1 ? gT2 : (t == 2 ? gK1 : gK2));
        if (dot(g, m) > 0.0)
        {
          vec2 y = t == 0 ? d : (t == 1 ? n : d + n);
          vec2 s = t == 0 ? -d : (t == 1 ? -n : (t == 2 ? d : n));
          vec2 o = t == 0 ? n : (t == 1 ? d : (t == 2 ? -n : -d));
          keepSq = max(keepSq, m * shadowClose(coord + SRC_SIZE.zw * y, P(y.x, y.y), s, o));
        }
        if (t == 3) d = n;
      }
      res *= 1.0 - min(keepSq, vec4(1.0));
    }
  }
  // 13. tiles between walls: a blocked corner between two tiles is dropped
  if (CRISP_RULES && max(max(res.x, res.y), max(res.z, res.w)) >= 128.0)
  {
    vec4 blk = vec4(greaterThanEqual(res, vec4(128.0))) * vec4(greaterThan(BLEND(res), vec4(0.0)));
    vec4 sc = FLAG(mod(res, 128.0), 8.0);
    // corner k (x, y, z, w) lies between the directions d = L, U, R, Dn and n = d turned 90 degrees (U, R, Dn, L):
    // P = E + a is d's pixel, or n's with the second blend color, and Q's side w is the other one. The loop
    // runs one test at a time, so the test is compiled once
    vec4 tile = vec4(0.0);
    vec2 d = vec2(-1., 0.);
    for (int k = 0; k < 4; k++)
    {
      vec2 n = vec2(-d.y, d.x);
      vec4 m = vec4(equal(vec4(float(k)), vec4(0., 1., 2., 3.)));
      if (dot(blk, m) > 0.0)
      {
        bool second = dot(sc, m) > 0.5;
        tile += m * tileStripe(coord, E, second ? n : d, second ? d : n);
      }
      d = n;
    }
    res *= 1.0 - tile;
  }
  FRAG_OUT = res / 255.0;
}

#endif
