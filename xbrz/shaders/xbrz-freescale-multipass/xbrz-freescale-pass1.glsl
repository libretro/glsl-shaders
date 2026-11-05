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

// Pass 1 of xbrz-freescale-multipass (OpenGL / GLES)

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

// the input of the first pass, which is the original image unless other shaders run before xBRZ
uniform sampler2D PassPrev2Texture;
uniform COMPAT_PRECISION vec2 PassPrev2TextureSize;
uniform COMPAT_PRECISION vec2 PassPrev2InputSize;
#define OUT_SIZE OutputSize
#define ORIG_SIZE vec4(PassPrev2TextureSize, 1.0 / PassPrev2TextureSize)
#define ORIG_INPUT_SIZE PassPrev2InputSize
// the first pass's texture and the original's can have different sizes (RetroArch rounds each one
// up to a power of two on its own, e.g. 256 and 512 with snes9x), so each one is read with its own
#define SRC_SIZE vec4(TextureSize, 1.0 / TextureSize)
#define P(x,y) COMPAT_TEXTURE(PassPrev2Texture, ocoord + ORIG_SIZE.zw * vec2(x, y)).rgb
#define INFO(uv) COMPAT_TEXTURE(Texture, uv)

float distYCbCr(vec3 pixA, vec3 pixB)
{
  const vec3 w = vec3(0.2627, 0.6780, 0.0593);
  vec3 diff = pixA - pixB;
  float Y = dot(diff, w);
  float Cb = 0.5 / (1.0 - 0.0593) * (diff.b - Y);
  float Cr = 0.5 / (1.0 - 0.2627) * (diff.r - Y);
  return sqrt(Y * Y + Cb * Cb + Cr * Cr);
}

float get_left_ratio(vec2 center, vec2 origin, vec2 direction, vec2 scale)
{
  vec2 P0 = center - origin;
  vec2 proj = direction * (dot(P0, direction) / dot(direction, direction));
  vec2 distv = P0 - proj;
  vec2 orth = vec2(-direction.y, direction.x);
  float side = sign(dot(P0, orth));
  float v = side * length(distv * scale);
  return smoothstep(-sqrt(2.0)/2.0, sqrt(2.0)/2.0, v);
}

void main()
{
  //---------------------------------------
  // Input Pixel Mapping: -|B|-
  //                      D|E|F
  //                      -|H|-

  vec2 scale = OUT_SIZE.xy / ORIG_INPUT_SIZE.xy;
  vec2 pos = fract(vTexCoord * SRC_SIZE.xy) - vec2(0.5, 0.5);
  vec2 coord = vTexCoord - pos * SRC_SIZE.zw;
  vec2 ocoord = coord * SRC_SIZE.xy * ORIG_SIZE.zw;

  vec4 info = floor(INFO(coord) * 255.0 + 0.5);
  vec3 E = P( 0., 0.);
  vec3 res = E;

  // info Mapping: x|y|
  //               w|z|
  vec4 blendResult = mod(info, 4.0);

  // a corner flagged by the first pass (+128, XBRZ_DIAG) is still cut when the same corner of a
  // neighbour along the cut is cut and not flagged, so diagonal lines are drawn to the end
  // a weak corner (blend type 3, just below XBRZ_MINC) is only cut inside a cut diagonal
  vec4 weak = vec4(equal(mod(info, 4.0), vec4(3.0)));
  if (max(max(info.x, info.y), max(info.z, info.w)) >= 128.0 || dot(weak, vec4(1.0)) > 0.0)
  {
    vec4 blocked = floor(info / 128.0);
    info = mod(info, 128.0);
    blendResult = mod(info, 4.0);
    vec4 nA = floor(INFO(coord + vec2( 1.0,-1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 nB = floor(INFO(coord + vec2(-1.0, 1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 nC = floor(INFO(coord + vec2( 1.0, 1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 nD = floor(INFO(coord + vec2(-1.0,-1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 aA = vec4(greaterThan(mod(nA, 4.0), vec4(0.0))) * vec4(lessThan(mod(nA, 4.0), vec4(3.0))) * vec4(lessThan(nA, vec4(128.0)));
    vec4 aB = vec4(greaterThan(mod(nB, 4.0), vec4(0.0))) * vec4(lessThan(mod(nB, 4.0), vec4(3.0))) * vec4(lessThan(nB, vec4(128.0)));
    vec4 aC = vec4(greaterThan(mod(nC, 4.0), vec4(0.0))) * vec4(lessThan(mod(nC, 4.0), vec4(3.0))) * vec4(lessThan(nC, vec4(128.0)));
    vec4 aD = vec4(greaterThan(mod(nD, 4.0), vec4(0.0))) * vec4(lessThan(mod(nD, 4.0), vec4(3.0))) * vec4(lessThan(nD, vec4(128.0)));
    // top-left and bottom-right are cut along "/", top-right and bottom-left along "\"
    vec4 chain = vec4(max(aA.x, aB.x), max(aC.y, aD.y), max(aA.z, aB.z), max(aC.w, aD.w));
    // a flagged line corner is also cut where its blend color's pixel has a line at the other end
    // of their shared edge that blends E's color: the two cuts are one diagonal
    // running into a straight edge, like the end of a lock of hair
    vec4 oL = floor(INFO(coord + vec2(-1.0, 0.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 oR = floor(INFO(coord + vec2( 1.0, 0.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 oU = floor(INFO(coord + vec2( 0.0,-1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 oD = floor(INFO(coord + vec2( 0.0, 1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 sec = mod(floor(info / 8.0), 2.0);
    vec4 nO = vec4(mix(oL.z, oU.z, sec.x), mix(oU.w, oR.w, sec.y), mix(oR.x, oD.x, sec.z), mix(oD.y, oL.y, sec.w));
    // the neighbour may also blend the pixel diagonal to E on the far side when it has E's color
    vec3 dX = sec.x > 0.5 ? P( 1.,-1.) : P(-1., 1.), dY = sec.y > 0.5 ? P( 1., 1.) : P(-1.,-1.);
    vec3 dZ = sec.z > 0.5 ? P(-1., 1.) : P( 1.,-1.), dW = sec.w > 0.5 ? P(-1.,-1.) : P( 1., 1.);
    vec4 sameE = vec4(float(distYCbCr(E, dX) * 255.0 <= 20.0), float(distYCbCr(E, dY) * 255.0 <= 20.0),
                      float(distYCbCr(E, dZ) * 255.0 <= 20.0), float(distYCbCr(E, dW) * 255.0 <= 20.0));
    vec4 meet = vec4(greaterThan(mod(nO, 4.0), vec4(0.0))) * vec4(lessThan(nO, vec4(128.0))) * mod(floor(nO / 4.0), 2.0)
              * max(1.0 - abs(mod(floor(nO / 8.0), 2.0) - sec), abs(mod(floor(nO / 8.0), 2.0) - sec) * sameE)
              * mod(floor(info / 4.0), 2.0);
    blendResult *= max(1.0 - blocked, max(chain, meet));
    // a weak corner needs the same corner of both neighbours along the cut to be cut
    blendResult *= mix(vec4(1.0), vec4(min(aA.x, aB.x), min(aC.y, aD.y), min(aA.z, aB.z), min(aC.w, aD.w)), weak);
  }

  // most output pixels have no corner to blend, and only need these two reads
  if (blendResult.x + blendResult.y + blendResult.z + blendResult.w <= 0.0)
  {
    FRAG_OUT = vec4(res, 1.0);
    return;
  }

  vec4 doLineBlend = mod(floor(info / 4.0), 2.0);
  vec4 secondPix = mod(floor(info / 8.0), 2.0);
  vec4 haveShallowLine = mod(floor(info / 16.0), 2.0);
  vec4 haveSteepLine = mod(floor(info / 64.0), 2.0);

  // a line flagged +32 by the first pass (found only by hue, between two different colors) is drawn
  // as a plain line where the neighbour across its edge draws a line the same way: the two lines
  // would run into each other, one bending around the other's end
  vec4 tone = mod(floor(info / 32.0), 2.0);
  if (tone.x + tone.y + tone.z + tone.w > 0.0)
  {
    vec4 nL = floor(INFO(coord + vec2(-1.0, 0.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 nR = floor(INFO(coord + vec2( 1.0, 0.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 nU = floor(INFO(coord + vec2( 0.0,-1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    vec4 nD = floor(INFO(coord + vec2( 0.0, 1.0) * SRC_SIZE.zw) * 255.0 + 0.5);
    // a neighbour corner draws a line when it blends, is not flagged (+128) and has the line bit (+4)
    vec4 drawL = vec4(lessThan(nL, vec4(128.0))) * mod(floor(nL / 4.0), 2.0), drawR = vec4(lessThan(nR, vec4(128.0))) * mod(floor(nR / 4.0), 2.0);
    vec4 drawU = vec4(lessThan(nU, vec4(128.0))) * mod(floor(nU / 4.0), 2.0), drawD = vec4(lessThan(nD, vec4(128.0))) * mod(floor(nD / 4.0), 2.0);
    // steep lines meet the left/right neighbour, shallow ones the upper/lower one
    vec4 steepN = vec4(drawL.z * mod(floor(nL.z / 64.0), 2.0), drawR.w * mod(floor(nR.w / 64.0), 2.0),
                       drawR.x * mod(floor(nR.x / 64.0), 2.0), drawL.y * mod(floor(nL.y / 64.0), 2.0));
    vec4 shallowN = vec4(drawU.z * mod(floor(nU.z / 16.0), 2.0), drawU.w * mod(floor(nU.w / 16.0), 2.0),
                         drawD.x * mod(floor(nD.x / 16.0), 2.0), drawD.y * mod(floor(nD.y / 16.0), 2.0));
    haveSteepLine *= 1.0 - tone * steepN;
    haveShallowLine *= 1.0 - tone * shallowN;
  }

  // Corners are applied in the same order as the original xBRZ (0, 90, 180, 270 degrees). The first
  // pass picked each blend colour ("dist(e,f) <= dist(e,h) ? f : h").

  // Pixel Tap Mapping: -|-|-
  //                    -|E|F
  //                    -|H|-
  if(blendResult.z > 0.0)
  {
    vec2 origin = vec2(0.0, 1.0 / sqrt(2.0));
    vec2 direction = vec2(1.0, -1.0);
    if(doLineBlend.z > 0.0)
    {
      origin = haveShallowLine.z > 0.0? vec2(0.0, 0.25) : vec2(0.0, 0.5);
      direction.x += haveShallowLine.z;
      direction.y -= haveSteepLine.z;
    }
    vec3 blendPix = (secondPix.z > 0.0) ? P( 0., 1.) : P( 1., 0.);
    res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
  }

  // Pixel Tap Mapping: -|B|-
  //                    -|E|F
  //                    -|-|-
  if(blendResult.y > 0.0)
  {
    vec2 origin = vec2(1.0 / sqrt(2.0), 0.0);
    vec2 direction = vec2(-1.0, -1.0);
    if(doLineBlend.y > 0.0)
    {
      origin = haveShallowLine.y > 0.0? vec2(0.25, 0.0) : vec2(0.5, 0.0);
      direction.y -= haveShallowLine.y;
      direction.x -= haveSteepLine.y;
    }
    vec3 blendPix = (secondPix.y > 0.0) ? P( 1., 0.) : P( 0.,-1.);
    res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
  }

  // Pixel Tap Mapping: -|B|-
  //                    D|E|-
  //                    -|-|-
  if(blendResult.x > 0.0)
  {
    vec2 origin = vec2(0.0, -1.0 / sqrt(2.0));
    vec2 direction = vec2(-1.0, 1.0);
    if(doLineBlend.x > 0.0)
    {
      origin = haveShallowLine.x > 0.0? vec2(0.0, -0.25) : vec2(0.0, -0.5);
      direction.x -= haveShallowLine.x;
      direction.y += haveSteepLine.x;
    }
    vec3 blendPix = (secondPix.x > 0.0) ? P( 0.,-1.) : P(-1., 0.);
    res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
  }

  // Pixel Tap Mapping: -|-|-
  //                    D|E|-
  //                    -|H|-
  if(blendResult.w > 0.0)
  {
    vec2 origin = vec2(-1.0 / sqrt(2.0), 0.0);
    vec2 direction = vec2(1.0, 1.0);
    if(doLineBlend.w > 0.0)
    {
      origin = haveShallowLine.w > 0.0? vec2(-0.25, 0.0) : vec2(-0.5, 0.0);
      direction.y += haveShallowLine.w;
      direction.x += haveSteepLine.w;
    }
    vec3 blendPix = (secondPix.w > 0.0) ? P(-1., 0.) : P( 0., 1.);
    res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
  }

  FRAG_OUT = vec4(res, 1.0);
}

#endif
