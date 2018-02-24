// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter RETRO_PIXEL_SIZE "Retro Pixel Size" 0.84 0.0 1.0 0.01
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float RETRO_PIXEL_SIZE;
#else
#define RETRO_PIXEL_SIZE 0.84
#endif

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
// out variables go here as COMPAT_VARYING whatever

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
    TEX0.xy = VertexCoord.xy;
// Paste vertex contents here:
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
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// delete all 'params.' or 'registers.' or whatever in the fragment
float iGlobalTime = float(FrameCount)*0.025;
vec2 iResolution = OutputSize.xy;

// Stairway to the Stars -  dr2 - 2015-05-13
// https://www.shadertoy.com/view/lls3z7

// A long climb; use the mouse to look around.

// "Stairway to the Stars" by dr2 - 2015
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

const float pi = 3.14159;
const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 i = floor (p);
  vec2 f = fract (p);
  f = f * f * (3. - 2. * f);
  vec4 t = Hashv4f (dot (i, cHashA3.xy));
  return mix (mix (t.x, t.y, f.x), mix (t.z, t.w, f.x), f.y);
}

float Fbm2 (vec2 p)
{
  float s = 0.;
  float a = 1.;
  for (int i = 0; i < 5; i ++) {
    s += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return s;
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
}

#define REFBALL

int idObj;
float tCur, stPitch, rotAng, rOut, rIn, rWid;
vec3 qHit, ltPos[2];
int doLt;
const float dstFar = 20.;

vec3 BrickCol (vec2 p)
{
  vec2 i = floor (p);
  if (2. * floor (i.y / 2.) != i.y) {
    p.x += 0.5;
    i = floor (p);
  }
  p = smoothstep (0.02, 0.08, abs (fract (p + 0.5) - 0.5));
  return (0.5 + 0.5 * p.x * p.y) * vec3 (0.5, 0.4, 0.3);
}

vec3 WoodCol (vec2 p)
{
  float f = Fbm2 (p * vec2 (1., 0.1));
  return mix (vec3 (0.8, 0.4, 0.2), vec3 (0.45, 0.25, 0.1), f);
}

float ObjDf (vec3 p)
{
  vec3 q, pp;
  float d, dr, da, dy, dMin, r, ns, nh, sh, sw, rw, ca, sa;
  const int ins = 12;
  const int inh = 6;
  dMin = dstFar;
  ns = float (ins);
  nh = float (inh);
  sh = 0.2 * stPitch / ns;
  sw = 1.1 * pi * rOut / ns;
  rw = 0.09;
  pp = p;
  pp.xz = Rot2D (pp.xz, rotAng);
  pp.y += stPitch * rotAng / (2. * pi);
  r = length (pp.xz);
  dr = max (r - rOut, rIn - r);
  q = pp;
  d = dMin;
  dy = stPitch / ns;
  q.y -= dy;
  da = 2. * pi / ns;
  ca = cos (da);  sa = sin (da);
  for (int j = 0; j < ins; j ++) {
    q.y = mod (q.y + dy + 0.5 * stPitch, stPitch) - 0.5 * stPitch;
    d = min (d, max (max (max (dr, abs (q.z) - sw), q.x), abs (q.y) - sh));
    if (d < dMin) { dMin = d;  idObj = 1;  qHit = q; }
    q.xz = q.xz * ca + q.zx * vec2 (- sa, sa);
  }
  d = min (min (d, max (r - rIn, - (r - rIn + rWid))),
     max (r - rOut - rWid, - (r - rOut)));
  q = pp;
  dy = stPitch / nh;
  q.y -= 0.25 * stPitch + dy;
  da = 2. * pi / nh;
  ca = cos (da);  sa = sin (da);
  for (int j = 0; j < inh; j ++) {
    q.y = mod (q.y + dy + 0.5 * stPitch, stPitch) - 0.5 * stPitch;
    d = max (d, - length (q.xy) + rw);
    q.xz = q.xz * ca + q.zx * vec2 (- sa, sa);
  }
  if (d < dMin) { dMin = d;  idObj = 2;  qHit = q; }
  if (doLt != 0) {
    d = PrSphDf (p - ltPos[0], 0.07 * rIn);
    if (d < dMin) { dMin = d;  idObj = 5; }
   }
  if (doLt != 1) {
    d = PrSphDf (p - ltPos[1], 0.07 * rIn);
    if (d < dMin) { dMin = d;  idObj = 6; }
  }
#ifdef REFBALL
  d = min (d, max (r - 0.006 * rIn, 0.));
  if (d < dMin) { dMin = d;  idObj = 3; }
  pp = p;
  pp.y = mod (pp.y + stPitch * rotAng / (2. * pi) + 0.5 * stPitch, stPitch) -
     0.5 * stPitch;
  d = PrSphDf (pp, 0.3 * rIn);
  if (d < dMin) { dMin = d;  idObj = 4; }
#endif
  return dMin;
}

vec3 ObjNf (vec3 p)
{
  const vec3 e = vec3 (0.001, -0.001, 0.);
  vec4 v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * vec3 (v.y, v.z, v.w));
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjCol (vec3 ro, vec3 rd, vec3 vn)
{
  vec3 ltDir, acDif, col; 
  float ltDist, ltDistSq, dif, atten, acSpe, sh, d, h;
  col = vec3 (0.);
  if (idObj == 1) {
    col = WoodCol (120. * qHit.zx);
  } else if (idObj == 2) {
    if (abs (vn.y) > 0.005) col = 0.4 * vec3 (0.5, 0.4, 0.3);
    else col = BrickCol (vec2 (20. * (atan (qHit.z, qHit.x) / pi + 1.),
       40. * qHit.y));
  } else if (idObj == 3) {
    col = vec3 (0.4, 0.4, 0.2);
  } else if (idObj == 5) {
    col = vec3 (1., 1., 0.5) * (0.75 + 0.25 * dot (rd, normalize (ltPos[0] - ro)));
  } else if (idObj == 6) {
    col = vec3 (1., 1., 0.5) * (0.75 + 0.25 * dot (rd, normalize (ltPos[1] - ro)));
  }
  if (idObj < 5) {
    acDif = vec3 (0.);
    acSpe = 0.;
    for (int j = 0; j < 2; j ++) {
      doLt = j;
      ltDir = ltPos[j] - ro;
      ltDistSq = dot (ltDir, ltDir);
      ltDist = sqrt (ltDistSq);
      ltDir /= ltDist;
      dif = clamp (dot (vn, ltDir), 0., 1.);
      sh = 0.;
      if (dif > 0.) {
	sh = 1.;
	d = 0.01;
	for (int i = 0; i < 60; i ++) {
	  h = ObjDf (ro + ltDir * d);
	  sh = min (sh, 50. * h / d);
	  d += h;
	  if (d > ltDist) break;
	}
	dif *= sh;
      }
      atten = 1. / (0.1 + ltDistSq);
      acDif += atten * dif;
      acSpe += atten * sh * pow (clamp (dot (reflect (rd, vn), ltDir), 0., 1.), 16.);
    }
    col = (0.4 + 0.2 * acDif) * col + 0.03 * acSpe * vec3 (1.);
  }
  return col;
}

float GlowCol (vec3 ro, vec3 rd, float dstHit)
{
  vec3 ltDir;
  float ltDist, wGlow;
  wGlow = 0.;
  for (int j = 0; j < 2; j ++) {
    ltDir = ltPos[j] - ro;
    ltDist = length (ltDir);
    ltDir /= ltDist;
    if (ltDist < dstHit) wGlow += pow (max (dot (rd, ltDir), 0.), 1024.) / ltDist;
  }
  return clamp (0.5 * wGlow, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, roo, rds;
  float dstHit, rLt, aLt;
  int idObjT;
  rotAng = 0.3 * tCur;
  stPitch = 0.4;
  rWid = 0.006;
  rLt = 0.6 * rOut;
  aLt = 0.1 * pi;
  ltPos[0] = vec3 (rLt * cos (aLt), stPitch * (0.1 - 0.14 * cos (tCur)),
     rLt * sin (aLt));
  aLt = - 0.95 * pi;
  ltPos[1] = vec3 (rLt * cos (aLt), stPitch * (-0.4 + 0.14 * sin (tCur)),
     rLt * sin (aLt));
  roo = ro;
  idObj = -1;
  doLt = -1;
  dstHit = ObjRay (ro, rd);
  if (idObj < 0) dstHit = dstFar;
#ifdef REFBALL
  if (idObj == 4 && dstHit < dstFar) {
    ro += rd * dstHit;
    rd = reflect (rd, ObjNf (ro));
    ro += 0.01 * rd;
    roo = ro;
    idObj = -1;
    dstHit = ObjRay (ro, rd);
  }
#endif
  if (dstHit >= dstFar) {
    col = vec3 (0., 0., 0.1);
    rds = rd;
    rds.xz = Rot2D (rds.xz, rotAng);
    rds = (rds + vec3 (1.));
    for (int j = 0; j < 10; j ++)
       rds = 11. * abs (rds) / dot (rds, rds) - 3.;
    col += min (1., 1.5e-6 * pow (min (16., length (rds)), 5.)) *
       vec3 (0.7, 0.6, 0.6);
  } else {
    ro += rd * dstHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    col = ObjCol (ro, rd, vn);
  }
  col = mix (col, vec3 (1., 1., 0.5), GlowCol (roo, rd, dstHit));
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec2 canvas = iResolution.xy;
  vec2 uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iGlobalTime;
#ifdef MOUSE
  vec4 mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
#endif
  mat3 vuMat;
  vec3 ro, rd;
  vec2 vEl, vAz;
  float az, el;
  rOut = 0.5;
  rIn = 0.2;
  ro = - vec3 (0., 0.1, 0.9) * rOut;
  az = 0.2;
  el = 0.1;
#ifdef MOUSE
  if (mPtr.z > 0.) {
    ro.z = clamp (ro.z + 0.8 * mPtr.x, - 0.99 * rOut, - 0.4 * rIn);
    el = clamp (el + 3. * mPtr.y, -1.5, 1.5);
  }
#endif
  vEl = vec2 (cos (el), sin (el));
  vAz = vec2 (cos (az), sin (az));
  vuMat = mat3 (1., 0., 0., 0., vEl.x, - vEl.y, 0., vEl.y, vEl.x) *
     mat3 (vAz.x, 0., vAz.y, 0., 1., 0., - vAz.y, 0., vAz.x);
  rd = normalize (vec3 (uv, 1.5)) * vuMat;
  fragColor = vec4 (ShowScene (ro, rd), 1.);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
