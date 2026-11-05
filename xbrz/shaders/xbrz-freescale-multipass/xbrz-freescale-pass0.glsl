// xBRZ freescale, multipass: xBRZ at any scale factor, in two passes.
//
// Two optional rules, both off by default (plain xBRZ); the xbrz-crisp preset turns them on:
// - XBRZ_MINC (crisp: 24) leaves a corner square when its two colors differ by less than this
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

// the distance for the shallow and steep line tests: with the crisp rules on (XBRZ_DIAG > 0) hue
// weighs 1.2x more than lightness, scaled so that as many neighbour pairs pass the thresholds
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

// a shallow or steep line found only because hue weighs more (DistShape) between two different
// colors is flagged +32, so the second pass can drop it where it runs into the neighbour's line
float toneLine(vec3 a, vec3 b, vec3 c, vec3 d)
{
  return float(!IsPixEqual(a, b) && STEEP_E * DistYCbCr(a, b) > DistYCbCr(c, d));
}

#define eq(a,b)  (a == b)
#define neq(a,b) (a != b)

// ---- diagonal rules (XBRZ_DIAG) ----
#define XBRZ_DIAG_AA 92.0   // diagonal limit for antialiasing ramps
#define XBRZ_HYST 4.0        // a corner this close below XBRZ_MINC is rounded inside a rounded diagonal
#define XBRZ_TIP 64.0       // stripe ends stay square above this diagonal distance
#define XBRZ_STRIPE 64.0    // a diagonal stripe keeps a close color (within this) along its length
#define XBRZ_OUTLINE 0.15   // an outline is darker (in luma) than both inner tones by this much
#define alike(a,b) (DistYCbCr(a, b) * 255.0 <= 20.0)

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

// res holds the xBRZ decisions of the four corners (blend type +4 line +8 second color +16 shallow +64 steep)
vec4 diagonalRules(vec4 res, vec2 coord, vec3 A, vec3 B, vec3 C, vec3 D, vec3 E, vec3 F, vec3 G, vec3 H, vec3 I,
                   float dEB, float dED, float dEF, float dEH)
{
  // only pixels that still have a corner to cut
  vec4 cut = vec4(greaterThan(mod(res, 4.0), vec4(0.0)));
  if (XBRZ_DIAG <= 0.0 || dot(cut, vec4(1.0)) <= 0.0)
    return res;
  // the xBRZ decisions, before the rules below
  vec4 res0 = res;

  // the two colors on each corner's diagonal: top-left D-B, top-right B-F, bottom-right F-H, bottom-left H-D
  vec4 pair = vec4(DistYCbCr(D, B), DistYCbCr(B, F), DistYCbCr(F, H), DistYCbCr(H, D));

  // similar diagonal
  vec4 dEP = vec4(dED, dEB, dEF, dEH);
  vec4 dEQ = vec4(dEB, dEF, dEH, dED);
  // a ramp: one diagonal color lies (almost) on the way from E to the other one
  vec4 ramp = min((dEP + pair) / max(dEQ, vec4(1e-5)), (dEQ + pair) / max(dEP, vec4(1e-5)));
  vec4 limit = mix(vec4(XBRZ_DIAG), vec4(XBRZ_DIAG_AA), vec4(lessThanEqual(ramp, vec4(1.15))));
  // the blend color P of each corner (+8: the second of its two candidates) and the other one, Q
  vec4 sec = vec4(greaterThan(mod(floor(res / 8.0), 2.0), vec4(0.5)));
  vec3 Px = sec.x > 0.5 ? B : D, Py = sec.y > 0.5 ? F : B, Pz = sec.z > 0.5 ? H : F, Pw = sec.w > 0.5 ? D : H;
  vec3 Qx = sec.x > 0.5 ? D : B, Qy = sec.y > 0.5 ? B : F, Qz = sec.z > 0.5 ? F : H, Qw = sec.w > 0.5 ? H : D;
  const vec3 lw = vec3(0.2627, 0.6780, 0.0593);
  float lE = dot(E, lw);
  vec4 lP = vec4(dot(Px, lw), dot(Py, lw), dot(Pz, lw), dot(Pw, lw));
  vec4 lQ = vec4(dot(Qx, lw), dot(Qy, lw), dot(Qz, lw), dot(Qw, lw));
  // dark keeps its pixel: P is not lighter than E
  vec4 notLighter = vec4(lessThanEqual(lP, vec4(lE + 4.0 / 255.0)));
  // shallow and steep lines (+16, +64) are not blocked, unless P is lighter than E
  vec4 keep = max(vec4(lessThanEqual(pair * 255.0, limit)), vec4(greaterThanEqual(res, vec4(16.0))) * notLighter);
  // diagonal stripe tips: P is a 1-pixel stripe that runs on along the cut (a close color two pixels
  // away from E) and E's color runs on along its other side, so the tip is drawn to the edge
  vec4 tipLine;
  tipLine.x = sec.x > 0.5 ? float(alike(E, C) && min(DistYCbCr(B, P(0.,-2.)), DistYCbCr(B, P(1.,-2.))) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(E, G) && min(DistYCbCr(D, P(-2.,0.)), DistYCbCr(D, P(-2.,1.))) * 255.0 <= XBRZ_STRIPE);
  tipLine.y = sec.y > 0.5 ? float(alike(E, I) && min(DistYCbCr(F, P(2.,0.)), DistYCbCr(F, P(2.,1.))) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(E, A) && min(DistYCbCr(B, P(0.,-2.)), DistYCbCr(B, P(-1.,-2.))) * 255.0 <= XBRZ_STRIPE);
  tipLine.z = sec.z > 0.5 ? float(alike(E, G) && min(DistYCbCr(H, P(0.,2.)), DistYCbCr(H, P(-1.,2.))) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(E, C) && min(DistYCbCr(F, P(2.,0.)), DistYCbCr(F, P(2.,-1.))) * 255.0 <= XBRZ_STRIPE);
  tipLine.w = sec.w > 0.5 ? float(alike(E, A) && min(DistYCbCr(D, P(-2.,0.)), DistYCbCr(D, P(-2.,-1.))) * 255.0 <= XBRZ_STRIPE)
                          : float(alike(E, I) && min(DistYCbCr(H, P(0.,2.)), DistYCbCr(H, P(1.,2.))) * 255.0 <= XBRZ_STRIPE);
  keep = max(keep, tipLine);
  // P runs straight on away from the corner (a horizontal or vertical line or frame)
  vec4 straight = vec4(float(sec.x > 0.5 ? alike(B, C) : alike(D, G)), float(sec.y > 0.5 ? alike(F, I) : alike(B, A)),
                       float(sec.z > 0.5 ? alike(H, G) : alike(F, C)), float(sec.w > 0.5 ? alike(D, A) : alike(H, I)));
  // E's color goes on past E away from Q, so E is wider than a 1-pixel stripe along Q
  vec4 wide = vec4(float(alike(E, sec.x > 0.5 ? F : H)), float(alike(E, sec.y > 0.5 ? H : D)),
                   float(alike(E, sec.z > 0.5 ? D : B)), float(alike(E, sec.w > 0.5 ? B : F)));
  // E is the corner of a solid block of its color (E's color goes on past E on both far sides and
  // between them), so a dot of another color next to it does not round the block's corner
  vec4 block = wide * vec4(float(alike(E, sec.x > 0.5 ? H : F) && alike(E, I)), float(alike(E, sec.y > 0.5 ? D : H) && alike(E, G)),
                           float(alike(E, sec.z > 0.5 ? B : D) && alike(E, A)), float(alike(E, sec.w > 0.5 ? F : B) && alike(E, C)));
  // inner line up to the outline: E and P are close tones (within XBRZ_DIAG) and Q is an outline darker
  // than both, so the cut runs between the inner tones and the outline stays whole. A straight P is
  // left straight, and the steps of a 1-pixel stripe along the outline (a gauge) stay square
  // the pixel two steps from E through P (R), the pixel on the far side of P from Q (S), and the pixel
  // next to R on E's side (U)
  vec3 Rx = sec.x > 0.5 ? P(0.,-2.) : P(-2.,0.), Ry = sec.y > 0.5 ? P(2.,0.) : P(0.,-2.);
  vec3 Rz = sec.z > 0.5 ? P(0.,2.) : P(2.,0.), Rw = sec.w > 0.5 ? P(-2.,0.) : P(0.,2.);
  vec3 Sx = sec.x > 0.5 ? C : G, Sy = sec.y > 0.5 ? I : A, Sz = sec.z > 0.5 ? G : C, Sw = sec.w > 0.5 ? A : I;
  vec3 Ux = sec.x > 0.5 ? P(1.,-2.) : P(-2.,1.), Uy = sec.y > 0.5 ? P(2.,1.) : P(-1.,-2.);
  vec3 Uz = sec.z > 0.5 ? P(-1.,2.) : P(2.,-1.), Uw = sec.w > 0.5 ? P(-2.,-1.) : P(1.,2.);
  vec4 lR = vec4(dot(Rx, lw), dot(Ry, lw), dot(Rz, lw), dot(Rw, lw));
  vec4 lU = vec4(dot(Ux, lw), dot(Uy, lw), dot(Uz, lw), dot(Uw, lw));
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
  // a blocked corner is flagged (+128); the output pass keeps it only when it continues a cut line.
  // When P runs straight on, the corner is dropped instead, so a diagonal stops at a frame
  res += 128.0 * (1.0 - keep) * cut;
  res *= 1.0 - (1.0 - keep) * straight * cut;
  // two dark strokes of different colors meet in an L around a 1-pixel light gap E, like a pupil under
  // an eyebrow: Q passes the corner, P is a short 1-pixel line that ends against it. The corner is
  // dropped, so the two strokes are not joined into a diagonal
  vec4 eye = vec4(float(!alike(Px, Qx) && alike(Qx, A) && !alike(Px, A) && !alike(Px, Rx) && !alike(E, sec.x > 0.5 ? H : F)),
                  float(!alike(Py, Qy) && alike(Qy, C) && !alike(Py, C) && !alike(Py, Ry) && !alike(E, sec.y > 0.5 ? D : H)),
                  float(!alike(Pz, Qz) && alike(Qz, I) && !alike(Pz, I) && !alike(Pz, Rz) && !alike(E, sec.z > 0.5 ? B : D)),
                  float(!alike(Pw, Qw) && alike(Qw, G) && !alike(Pw, G) && !alike(Pw, Rw) && !alike(E, sec.w > 0.5 ? F : B)))
          * straight * cut * vec4(lessThan(max(lP, lQ), vec4(lE - XBRZ_OUTLINE)));
  // E is not part of a diagonal stripe along the cut
  float stripeCG = float(min(DistYCbCr(E, C), DistYCbCr(E, G)) * 255.0 <= XBRZ_STRIPE);
  float stripeAI = float(min(DistYCbCr(E, A), DistYCbCr(E, I)) * 255.0 <= XBRZ_STRIPE);
  eye *= 1.0 - vec4(stripeCG, stripeAI, stripeCG, stripeAI);
  if (dot(eye, vec4(1.0)) > 0.0)
  {
    eye *= vec4(sec.x > 0.5 ? strokeEnds(Px, coord, vec2(2.,-1.), vec2(0.,1.)) : strokeEnds(Px, coord, vec2(-1.,2.), vec2(1.,0.)),
                sec.y > 0.5 ? strokeEnds(Py, coord, vec2(1.,2.), vec2(1.,0.)) : strokeEnds(Py, coord, vec2(-2.,-1.), vec2(0.,1.)),
                sec.z > 0.5 ? strokeEnds(Pz, coord, vec2(-2.,1.), vec2(0.,1.)) : strokeEnds(Pz, coord, vec2(1.,-2.), vec2(1.,0.)),
                sec.w > 0.5 ? strokeEnds(Pw, coord, vec2(-1.,-2.), vec2(1.,0.)) : strokeEnds(Pw, coord, vec2(2.,1.), vec2(0.,1.)));
    res *= 1.0 - eye;
  }

  // diagonal up to the wall: a corner changed by the rules above goes back to the xBRZ decision when
  // E's color runs on as a 45-degree diagonal parallel to the cut (C or G for the / corners, A or I for
  // the \ ones) up to a wall at one end, and the neighbour on that diagonal sits on the same 45-degree
  // step (or E's color runs 3 pixels along it), like hair or the corner of a fence post
  vec4 kept = vec4(0.0), loneP = vec4(0.0), loneQ = vec4(0.0);
  if (any(notEqual(res, res0)))
  {
    float dCG = float(alike(E, C) || alike(E, G)), dAI = float(alike(E, A) || alike(E, I));
    float wCG = dCG > 0.5 ? max(runWall(E, coord, vec2(1., -1.)), runWall(E, coord, vec2(-1., 1.))) : 0.0;
    float wAI = dAI > 0.5 ? max(runWall(E, coord, vec2(1., 1.)), runWall(E, coord, vec2(-1., -1.))) : 0.0;
    // the neighbour of E's color on the diagonal differs from both pixels beside its own corner
    vec4 partner = vec4(
      float((alike(E, C) && !alike(C, B) && !alike(C, P(1., -2.))) || (alike(E, G) && !alike(G, P(-2., 1.)) && !alike(G, D))),
      float((alike(E, A) && !alike(A, P(-1., -2.)) && !alike(A, B)) || (alike(E, I) && !alike(I, F) && !alike(I, P(2., 1.)))),
      float((alike(E, C) && !alike(C, P(2., -1.)) && !alike(C, F)) || (alike(E, G) && !alike(G, H) && !alike(G, P(-1., 2.)))),
      float((alike(E, A) && !alike(A, D) && !alike(A, P(-2., -1.))) || (alike(E, I) && !alike(I, P(1., 2.)) && !alike(I, H))));
    float l3CG = float((alike(E, C) && alike(E, P(2., -2.))) || (alike(E, G) && alike(E, P(-2., 2.))));
    float l3AI = float((alike(E, A) && alike(E, P(-2., -2.))) || (alike(E, I) && alike(E, P(2., 2.))));
    partner = max(partner, vec4(l3CG, l3AI, l3CG, l3AI));
    // E ends a straight line of its color, 3 pixels or more, that runs away from the corner
    float lineR = float(alike(E, F) && alike(E, P(2., 0.))), lineL = float(alike(E, D) && alike(E, P(-2., 0.)));
    float lineD = float(alike(E, H) && alike(E, P(0., 2.))), lineU = float(alike(E, B) && alike(E, P(0., -2.)));
    vec4 endLine = vec4(max(lineR, lineD), max(lineL, lineD), max(lineL, lineU), max(lineR, lineU));
    // Q runs straight on away from the corner, or passes through it for 2 pixels (straightQ0) or 3 (straightQ)
    vec4 straightQ = vec4(float(sec.x > 0.5 ? alike(D, G) : alike(B, C)), float(sec.y > 0.5 ? alike(B, A) : alike(F, I)),
                          float(sec.z > 0.5 ? alike(F, C) : alike(H, G)), float(sec.w > 0.5 ? alike(H, I) : alike(D, A)));
    vec4 straightQ0 = max(straightQ, vec4(float(alike(Qx, A)), float(alike(Qy, C)), float(alike(Qz, I)), float(alike(Qw, G))));
    straightQ = max(straightQ, vec4(float(alike(Qx, A) && alike(Qx, sec.x > 0.5 ? P(-1., -2.) : P(-2., -1.))),
                                    float(alike(Qy, C) && alike(Qy, sec.y > 0.5 ? P(2., -1.) : P(1., -2.))),
                                    float(alike(Qz, I) && alike(Qz, sec.z > 0.5 ? P(1., 2.) : P(2., 1.))),
                                    float(alike(Qw, G) && alike(Qw, sec.w > 0.5 ? P(-2., 1.) : P(-1., 2.)))));
    // E is a 1-pixel stripe along P; there Q bends when it passes the corner for only 2 pixels
    float sH = float(!alike(E, B) && !alike(E, H) && !alike(B, H)), sV = float(!alike(E, D) && !alike(E, F) && !alike(D, F));
    vec4 stripeE = vec4(sec.x > 0.5 ? sH : sV, sec.y > 0.5 ? sV : sH, sec.z > 0.5 ? sH : sV, sec.w > 0.5 ? sV : sH);
    vec4 bendQ = straightQ0 * (1.0 - straightQ) * stripeE;
    vec4 sQ = mix(straightQ0, straightQ, stripeE);
    // Q runs on along the cut: the pixel after Q in the cut's direction has Q's color
    vec3 Qnx = sec.x > 0.5 ? P(-2., 1.) : P(1., -2.), Qny = sec.y > 0.5 ? P(-1., -2.) : P(2., 1.);
    vec3 Qnz = sec.z > 0.5 ? P(2., -1.) : P(-1., 2.), Qnw = sec.w > 0.5 ? P(1., 2.) : P(-2., -1.);
    vec4 qRun = vec4(float(alike(Qx, Qnx)), float(alike(Qy, Qny)), float(alike(Qz, Qnz)), float(alike(Qw, Qnw)));
    // not where P and Q both run straight (a right-angle junction), where a straight P is a darker line
    // or E ends a straight line beside it (unless Q bends), or where a straight P meets a Q that neither
    // runs straight nor along the cut
    vec4 run = vec4(wCG, wAI, wCG, wAI) * partner * (1.0 - straight * sQ) * (1.0 - straight * vec4(lessThan(lP, vec4(lE))) * (1.0 - bendQ))
             * (1.0 - endLine * straight * (1.0 - bendQ)) * (1.0 - straight * (1.0 - straightQ0) * (1.0 - qRun)) * cut;
    // not where P and Q are both lone pixels (no neighbour of their own color in a cross), like an eye.
    // B, D, F and H are each lone when none of their other three cross neighbours has their color; the
    // first and second blend candidates of the corners x y z w are D B F H and B F H D
    vec4 lone = vec4(float(!alike(B, A) && !alike(B, C) && !alike(B, P(0., -2.))), float(!alike(D, A) && !alike(D, G) && !alike(D, P(-2., 0.))),
                     float(!alike(F, C) && !alike(F, I) && !alike(F, P(2., 0.))), float(!alike(H, G) && !alike(H, I) && !alike(H, P(0., 2.))));
    loneP = mix(lone.yxzw, lone.xzwy, sec);
    loneQ = mix(lone.xzwy, lone.yxzw, sec);
    run *= 1.0 - loneP * loneQ;
    res = mix(res, res0, run);
    kept = run;
  }

  // thin light stroke: a blocked corner comes back as in xBRZ where E is a 1-pixel stroke lighter than both diagonal
  // colors that runs on along the diagonal of the cut (E's color in C or G for the / corners, A or I for the \ ones,
  // not on E's far side), like the white strokes of letters or a ring with gray antialiasing
  if (any(notEqual(res, res0)))
  {
    // E's color, or a tone closer to E than the corner's two colors (an antialiasing step), goes on along the diagonal
    vec4 dPQmin = min(mix(dEP, dEQ, sec), mix(dEQ, dEP, sec));
    float eC = DistYCbCr(E, C), eG = DistYCbCr(E, G), eA = DistYCbCr(E, A), eI = DistYCbCr(E, I);
    // a diagonal neighbour counts only when the stroke really bends there: the cross neighbour beside it on E's far side
    // is not E's tone too (a peak on top of a straight line is not a diagonal stroke)
    vec4 tE = 0.6 * dPQmin;
    bvec4 aD = bvec4(alike(E, C), alike(E, G), alike(E, A), alike(E, I));
    bvec4 nD = bvec4(aD.x || eC < tE.x, aD.y || eG < tE.x, aD.z || eA < tE.y, aD.w || eI < tE.y);
    bvec4 nD2 = bvec4(aD.x || eC < tE.z, aD.y || eG < tE.z, aD.z || eA < tE.w, aD.w || eI < tE.w);
    float fB = DistYCbCr(E, B), fD = DistYCbCr(E, D), fF = DistYCbCr(E, F), fH = DistYCbCr(E, H);
    // x: C beside F, G beside H; y: A beside D, I beside H; z: C beside B, G beside D; w: A beside B, I beside F
    vec4 sideA = vec4(float(aD.x && !(fF < tE.x)) + float(aD.y && !(fH < tE.x)), float(aD.z && !(fD < tE.y)) + float(aD.w && !(fH < tE.y)),
                      float(aD.x && !(fB < tE.z)) + float(aD.y && !(fD < tE.z)), float(aD.z && !(fB < tE.w)) + float(aD.w && !(fF < tE.w)));
    vec4 sideN = vec4(float(nD.x && !(fF < tE.x)) + float(nD.y && !(fH < tE.x)), float(nD.z && !(fD < tE.y)) + float(nD.w && !(fH < tE.y)),
                      float(nD2.x && !(fB < tE.z)) + float(nD2.y && !(fD < tE.z)), float(nD2.z && !(fB < tE.w)) + float(nD2.w && !(fF < tE.w)));
    sideA = min(sideA, vec4(1.0)); sideN = min(sideN, vec4(1.0));
    vec4 farOff = vec4(float(!alike(E, I)), float(!alike(E, G)), float(!alike(E, A)), float(!alike(E, C)));
    vec4 along = sideA * farOff;
    along = max(along, sideA * vec4(lessThan(max(lP, lQ), vec4(0.45))));
    along = max(along, sideN * farOff);
    vec4 light = vec4(greaterThan(vec4(lE) - max(lP, lQ), vec4(0.15)));
    vec4 back = along * light * cut * vec4(notEqual(res, res0));
    // not where P and Q are lone pixels (no neighbour of their own color in a cross), like an eye
    back *= 1.0 - loneP * loneQ;
    res = mix(res, res0, back);
    kept = max(kept, back);
  }

  // antialiasing notch: a corner blocked on an antialiasing ramp comes back as in xBRZ where P is a single
  // antialiasing pixel between E and Q (the ramp runs E, P, Q and the diagonal is within XBRZ_DIAG + 12), Q's
  // tone wraps around P in the outer corner (A, C, I, G) and E's tone runs on along the cut (C or G for the
  // / corners, A or I for the \ ones), like the shaded edges of a cape
  if (any(notEqual(res, res0)))
  {
    vec4 dPc = mix(dEP, dEQ, sec), dQc = mix(dEQ, dEP, sec);
    vec4 notch = vec4(lessThanEqual((dPc + pair) / max(dQc, vec4(1e-5)), vec4(1.15))) * vec4(lessThanEqual(pair * 255.0, vec4(XBRZ_DIAG + 45.0)))
               * loneP * cut * vec4(notEqual(res, res0));
    vec4 wrap = vec4(lessThan(vec4(DistYCbCr(A, Qx), DistYCbCr(C, Qy), DistYCbCr(I, Qz), DistYCbCr(G, Qw)), 0.6 * pair));
    // E's tone in a diagonal neighbour X: closer to E than to P and Q by 0.6
    float eA = DistYCbCr(E, A), eC = DistYCbCr(E, C), eG = DistYCbCr(E, G), eI = DistYCbCr(E, I);
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
    res = mix(res, res0, notch);
    kept = max(kept, notch);
  }

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
    // all three stripes run at least 3 pixels back from the end, and E's 4 when the color past the
    // end runs straight on (a line meeting a short stripe, not a gauge)
    float endL = (thinH && nF && !eD && alike(B, C) && alike(H, I) && !eq(B, A) && !eq(H, G) && alike(E, P(2., 0.)) && (alike(E, P(3., 0.)) || !eq(D, P(-2., 0.))) && alike(C, P(2., -1.)) && alike(I, P(2., 1.))) ? 1.0 : 0.0;
    float endR = (thinH && nD && !eF && alike(B, A) && alike(H, G) && !eq(B, C) && !eq(H, I) && alike(E, P(-2., 0.)) && (alike(E, P(-3., 0.)) || !eq(F, P(2., 0.))) && alike(A, P(-2., -1.)) && alike(G, P(-2., 1.))) ? 1.0 : 0.0;
    float endT = (thinV && nH && !eB && alike(D, G) && alike(F, I) && !eq(D, A) && !eq(F, C) && alike(E, P(0., 2.)) && (alike(E, P(0., 3.)) || !eq(B, P(0., -2.))) && alike(G, P(-1., 2.)) && alike(I, P(1., 2.))) ? 1.0 : 0.0;
    float endB = (thinV && nB && !eH && alike(D, A) && alike(F, C) && !eq(D, G) && !eq(F, I) && alike(E, P(0., -2.)) && (alike(E, P(0., -3.)) || !eq(H, P(0., 2.))) && alike(A, P(-1., -2.)) && alike(C, P(1., -2.))) ? 1.0 : 0.0;
    vec4 tip = vec4(max(endL, endT), max(endR, endT), max(endR, endB), max(endL, endB));
    tip *= vec4(greaterThan(pair * 255.0, vec4(XBRZ_TIP)));
    res *= 1.0 - tip * (1.0 - kept);
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
    float dist_F_G = DistShape(F, G);
    float dist_H_C = DistShape(H, C);
    if((STEEP_E * dist_F_G <= dist_H_C) && neq(E,G) && neq(D,G))
      res.z += 16.0 + 32.0 * toneLine(F, G, H, C);
    if((STEEP_E * dist_H_C <= dist_F_G) && neq(E,C) && neq(B,C))
      res.z += 64.0 + 32.0 * toneLine(H, C, F, G);
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
    float dist_H_A = DistShape(H, A);
    float dist_D_I = DistShape(D, I);
    if((STEEP_E * dist_H_A <= dist_D_I) && neq(E,A) && neq(B,A))
      res.w += 16.0 + 32.0 * toneLine(H, A, D, I);
    if((STEEP_E * dist_D_I <= dist_H_A) && neq(E,I) && neq(F,I))
      res.w += 64.0 + 32.0 * toneLine(D, I, H, A);
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
    float dist_B_I = DistShape(B, I);
    float dist_F_A = DistShape(F, A);
    if((STEEP_E * dist_B_I <= dist_F_A) && neq(E,I) && neq(H,I))
      res.y += 16.0 + 32.0 * toneLine(B, I, F, A);
    if((STEEP_E * dist_F_A <= dist_B_I) && neq(E,A) && neq(D,A))
      res.y += 64.0 + 32.0 * toneLine(F, A, B, I);
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
    float dist_D_C = DistShape(D, C);
    float dist_B_G = DistShape(B, G);
    if((STEEP_E * dist_D_C <= dist_B_G) && neq(E,C) && neq(F,C))
      res.x += 16.0 + 32.0 * toneLine(D, C, B, G);
    if((STEEP_E * dist_B_G <= dist_D_C) && neq(E,G) && neq(H,G))
      res.x += 64.0 + 32.0 * toneLine(B, G, D, C);
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
  vec4 weak = vec4(0.0);
  vec4 res0 = res;
  vec4 contrast = vec4(0.0);
  if (XBRZ_MINC > 0.0)
  {
    contrast = vec4(min(dED, dEB), min(dEB, dEF), min(dEF, dEH), min(dEH, dED)) * 255.0;
    weak = vec4(greaterThanEqual(contrast, vec4(XBRZ_MINC - XBRZ_HYST))) * vec4(lessThan(contrast, vec4(XBRZ_MINC)));
    res *= max(vec4(greaterThanEqual(contrast, vec4(XBRZ_MINC))), weak);
  }
  res = diagonalRules(res, coord, A, B, C, D, E, F, G, H, I, dEB, dED, dEF, dEH);
  // a corner just below XBRZ_MINC is marked weak (blend type 3): the output pass rounds it only where
  // the same corner of both neighbours along the cut is rounded
  weak *= vec4(greaterThan(mod(res, 4.0), vec4(0.0)));
  res += weak * (3.0 - mod(res, 4.0));
  // a line through an antialiasing pixel cuts both halves of it, as in xBRZ: when one corner is a rounded
  // line and the opposite corner is a line that XBRZ_MINC squared or left weak, and E lies between their
  // two blend colors on a strong edge, the opposite corner is rounded too
  if (XBRZ_MINC > 0.0)
  {
    vec4 cut = vec4(greaterThan(mod(res, 4.0), vec4(0.0))) * vec4(lessThan(mod(res, 4.0), vec4(3.0))) * mod(floor(res / 4.0), 2.0);
    vec4 sq = vec4(lessThan(contrast, vec4(XBRZ_MINC))) * vec4(greaterThan(mod(res0, 4.0), vec4(0.0))) * mod(floor(res0 / 4.0), 2.0)
            * vec4(notEqual(mod(res, 4.0), vec4(1.0))) * vec4(notEqual(mod(res, 4.0), vec4(2.0)));
    vec4 pair = sq * cut.zwxy;
    if (dot(pair, vec4(1.0)) > 0.0)
    {
      vec4 sc = mod(floor(res0 / 8.0), 2.0);
      vec3 Cx = sc.x > 0.5 ? B : D, Cy = sc.y > 0.5 ? F : B, Cz = sc.z > 0.5 ? H : F, Cw = sc.w > 0.5 ? D : H;
      float dXZ = DistYCbCr(Cx, Cz), dYW = DistYCbCr(Cy, Cw);
      float bxz = float(DistYCbCr(Cx, E) + DistYCbCr(E, Cz) <= 1.01 * dXZ && dXZ * 255.0 >= 40.0);
      float byw = float(DistYCbCr(Cy, E) + DistYCbCr(E, Cw) <= 1.01 * dYW && dYW * 255.0 >= 40.0);
      res = mix(res, res0, pair * vec4(bxz, byw, bxz, byw));
    }
  }

  FRAG_OUT = res / 255.0;
}

#endif
