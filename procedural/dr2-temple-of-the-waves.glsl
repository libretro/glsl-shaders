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

// "Temple of the Waves" by dr2 - 2015
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

const float pi = 3.14159;
const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  const vec3 cHashVA3 = vec3 (37.1, 61.7, 12.4);
  const vec3 e = vec3 (1., 0., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 i = floor (p);
  vec2 f = fract (p);
  f = f * f * (3. - 2. * f);
  vec4 t = Hashv4f (dot (i, cHashA3.xy));
  return mix (mix (t.x, t.y, f.x), mix (t.z, t.w, f.x), f.y);
}

float Noisefv3a (vec3 p)
{
  vec3 i, f;
  i = floor (p);  f = fract (p);
  f *= f * (3. - 2. * f);
  vec4 t1 = Hashv4v3 (i);
  vec4 t2 = Hashv4v3 (i + vec3 (0., 0., 1.));
  return mix (mix (mix (t1.x, t1.y, f.x), mix (t1.z, t1.w, f.x), f.y),
              mix (mix (t2.x, t2.y, f.x), mix (t2.z, t2.w, f.x), f.y), f.z);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s = vec3 (0.);
  float a = 1.;
  for (int i = 0; i < 5; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 e = vec3 (0.2, 0., 0.);
  float s = Fbmn (p, n);
  vec3 g = vec3 (Fbmn (p + e.xyy, n) - s,
     Fbmn (p + e.yxy, n) - s, Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
}

int idObj;
vec3 qHit, sunDir, cloudDisp, waterDisp;
float tCur;
const float dstFar = 150.;
const int idBaseW = 10, idBase = 11, idCol = 12, idColEnd = 13, idTop = 14,
   idAltr = 15, idRBall = 16;

vec3 SkyCol (vec3 ro, vec3 rd)
{
  const vec3 sbCol = vec3 (0.2, 0.3, 0.55);
  vec3 col;
  vec2 p;
  float sd, w, f;
  col = sbCol + 0.25 * pow (1. - max (rd.y, 0.), 8.);
  sd = max (dot (rd, sunDir), 0.);
  rd.y = abs (rd.y);
  ro += cloudDisp;
  p = 0.1 * (rd.xz * (50. - ro.y) / rd.y + ro.xz);
  w = 0.8;
  f = 0.;
  for (int j = 0; j < 4; j ++) {
    f += w * Noisefv2 (p);
    w *= 0.5;
    p *= 2.;
  }
  col += 0.35 * pow (sd, 6.) + 0.65 * min (pow (sd, 256.), 0.3);
  return mix (col, vec3 (0.85), clamp (0.8 * f * rd.y + 0.1, 0., 1.));
}

float WaveHt (vec3 p)
{
  const mat2 qRot = mat2 (1.6, -1.2, 1.2, 1.6);
  vec4 t4, ta4, v4;
  vec2 q2, t2, v2;
  float wFreq, wAmp, pRough, ht;
  wFreq = 0.25;  wAmp = 0.25;  pRough = 5.;
  q2 = p.xz + waterDisp.xz;
  ht = 0.;
  for (int j = 0; j < 5; j ++) {
    t2 = 1.1 * tCur * vec2 (1., -1.);
    t4 = vec4 (q2 + t2.xx, q2 + t2.yy) * wFreq;
    t2 = vec2 (Noisefv2 (t4.xy), Noisefv2 (t4.zw));
    t4 += 2. * vec4 (t2.xx, t2.yy) - 1.;
    ta4 = abs (sin (t4));
    v4 = (1. - ta4) * (ta4 + abs (cos (t4)));
    v2 = pow (1. - sqrt (v4.xz * v4.yw), vec2 (pRough));
    ht += (v2.x + v2.y) * wAmp;
    q2 *= qRot;  wFreq *= 2.;  wAmp *= 0.25;
    pRough = 0.8 * pRough + 0.2;
  }
  return ht;
}

float WaveRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  dHit = dstFar;
  if (rd.y < 0.) {
    s = 0.;
    sLo = 0.;
    for (int j = 0; j < 100; j ++) {
      p = ro + s * rd;
      h = p.y - WaveHt (p);
      if (h < 0.) break;
      sLo = s;
      s += max (0.3, h) + 0.005 * s;
      if (s > dstFar) break;
    }
    if (h < 0.) {
      sHi = s;
      for (int j = 0; j < 5; j ++) {
	s = 0.5 * (sLo + sHi);
	p = ro + s * rd;
	h = step (0., p.y - WaveHt (p));
	sLo += h * (s - sLo);
	sHi += (1. - h) * (s - sHi);
      }
      dHit = sHi;
    }
  }
  return dHit;
}

vec3 WaveNf (vec3 p, float d)
{
  vec2 e = vec2 (max (0.01, 0.001 * d * d), 0.);
  float ht = WaveHt (p);
  return normalize (vec3 (ht - WaveHt (p + e.xyy), e.x, ht - WaveHt (p + e.yyx)));
}

float BldgDf (vec3 p, float dHit)
{
  vec3 q;
  float d, da, db, wr;
  p.y -= 0.5;
  q = p;
  q.y -= -0.2;
  d = PrBoxDf (q, vec3 (8.6, 0.301, 10.6));
  if (d < dHit) { dHit = d;  idObj = idBaseW;  qHit = q; }
  q.y -= 0.35;
  d = PrBoxDf (q, vec3 (8.4, 0.101, 10.4));
  q.y -= 0.15;
  d = min (d, PrBoxDf (q, vec3 (8.2, 0.101, 10.2)));
  if (d < dHit) { dHit = d;  idObj = idBase;  qHit = q; }
  q.y -= 5.52;
  d = max (PrBoxDf (q, vec3 (7.55, 0.05, 9.55)),
     - PrBoxDf (q, vec3 (4.45, 0.4, 6.45)));
  q.xz = mod (q.xz + vec2 (1.), 2.) - 1.;
  d = max (d, - PrBoxDf (q, vec3 (0.45, 0.4, 0.45)));
  if (d < dHit) { dHit = d;  idObj = idTop;  qHit = q; }
  q = p;  q.y -= 3.1;
  db = max (PrBoxDf (q, vec3 (8., 5., 10.)),
     - PrBoxDf (q, vec3 (4., 5., 6.)));
  q = p;  q.xz = mod (q.xz, 2.) - 1.;  q.y -= 3.1;
  wr = q.y / 2.5;
  d = max (PrCylDf (q.xzy, 0.3 * (1.05 - 0.05 * wr * wr), 2.55), db);
  if (d < dHit) { dHit = d;  idObj = idCol;  qHit = q; }
  q = p;  q.xz = mod (q.xz, 2.) - 1.;  q.y = abs (q.y - 3.1) - 2.5;
  d = PrCylDf (q.xzy, 0.4, 0.07);
  q.y -= 0.14;
  d = max (min (d, PrBoxDf (q, vec3 (0.5, 0.07, 0.5))), db);
  if (d < dHit) { dHit = d;  idObj = idColEnd;  qHit = q; }
  q = p;  q.y -= 0.4;
  d = PrCylDf (q.xzy, 1.1, 0.2);
  q = p;  q.y -= 1.;
  q.xz = abs (q.xz) - 0.4;
  d = min (d, PrCylDf (q.xzy, 0.15, 0.8));
  if (d < dHit) { dHit = d;  idObj = idAltr;  qHit = q; }
  q = p;  q.y -= 2.9;  
  d = PrSphDf (q, 1.5);
  if (d < dHit) { dHit = d;  idObj = idRBall;  qHit = q; }
  return dHit;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dHit, d;
  dHit = dstFar;
  dHit = 0.95 * BldgDf (p, dHit);
  return dHit;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float d;
  float dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  const vec3 e = vec3 (0.001, -0.001, 0.);
  vec4 v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 ObjCol (vec3 n)
{
  vec3 col;
  float sn = Noisefv3a (110. * qHit);
  if (idObj == idBase ||idObj == idTop) col = vec3 (0.7, 0.7, 0.6);
  else if (idObj == idBaseW) col =
     mix (vec3 (0.7, 0.7, 0.6), vec3 (0.1, 0.4, 0.3) * sn,
        clamp (0.6 - 2. * qHit.y, 0., 1.));
  else if (idObj == idCol || idObj == idColEnd) col = vec3 (0.6, 0.7, 0.5);
  else if (idObj == idAltr) col = vec3 (0.6, 0.5, 0.2);
  col *= 0.7 + 0.3 * sn;
  return col;
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh = 1.;
  float d = 0.05;
  for (int i = 0; i < 60; i ++) {
    float h = ObjDf (ro + rd * d);
    sh = min (sh, 30. * h / d);
    d += 0.15;
    if (h < 0.001) break;
  }
  return clamp (sh, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 objCol, col, rdd, vn, vnw;
  float dstHit, dstWat, dif, sh, a;
  int idObjT;
  bool objRefl, waterRefl;
  idObj = -1;
  dstHit = ObjRay (ro, rd);
  if (idObj < 0) dstHit = dstFar;
  objRefl = false;
  if (idObj == idRBall && dstHit < dstFar) {
    ro += rd * dstHit;
    rd = reflect (rd, ObjNf (ro));
    ro += 0.01 * rd;
    idObj = -1;
    dstHit = ObjRay (ro, rd);
    objRefl = true;
  }
  dstWat = WaveRay (ro, rd);
  waterRefl = (dstWat < min (dstFar, dstHit));
  if (waterRefl) {
    ro += rd * dstWat;
    vnw = WaveNf (ro, dstWat);
    rdd = rd;
    rd = reflect (rd, vnw);
    idObj = -1;
    dstHit = ObjRay (ro, rd);
    if (idObj < 0) dstHit = dstFar;
    if (idObj == idRBall && dstHit < dstFar) {
      ro += rd * dstHit;
      rd = reflect (rd, ObjNf (ro));
      ro += 0.01 * rd;
      idObj = -1;
      dstHit = ObjRay (ro, rd);
      objRefl = true;
    }
  }
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    if (idObj == idCol) {
      a = 0.5 - mod (12. * (atan (qHit.x, qHit.z) / (2. * pi) + 0.5), 1.);
      vn.xz = Rot2D (vn.xz, -0.15 * pi * sin (pi * a));
    }
    if (idObj == idBase || idObj == idBaseW) vn = VaryNf (10. * qHit, vn, 1.);
    else vn = VaryNf (20. * qHit, vn, 0.5);
    objCol = ObjCol (vn);
    sh = ObjSShadow (ro, sunDir);
    dif = max (dot (vn, sunDir), 0.);
    col = objCol * (0.2 * (1. +
       max (dot (vn, - normalize (vec3 (sunDir.x, 0., sunDir.z))), 0.)) + 
       max (0., dif) * (0.2 + 0.8 * sh) *
       (1. + 0.3 * pow (max (0., dot (sunDir, reflect (rd, vn))), 64.)));
    if (objRefl) col = 0.7 * col;
  } else col = SkyCol (ro, rd);
  if (waterRefl) col = mix (vec3 (0, 0.07, 0.08), 0.5 * col,
     0.8 * pow (1. - abs (dot (rdd, vnw)), 4.));
  return sqrt (clamp (col, 0., 1.));

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
  uv.x *= iResolution.x / iResolution.y;
  tCur = iGlobalTime;
#ifdef MOUSE
  vec4 mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
#else
  vec4 mPtr = vec4(0.0, 0.0, 0.0, 0.0);
#endif
  mat3 vuMat;
  vec3 ro, rd, vd, u;
  float dist, az, f;
  sunDir = normalize (vec3 (0.8, 1., -0.8));
  cloudDisp = 1.5 * tCur * vec3 (1., 0., -1.);
  waterDisp = 0.2 * tCur * vec3 (-1., 0., 1.);
#ifdef MOUSE
  if (mPtr.z <= 0.) {
    dist = 35.;
    az = 0.25 * pi + 0.01 * tCur;
  } else {
    dist = max (2., 17. - 30. * mPtr.y);
    az = 2.2 * pi * mPtr.x;
  }
#else
  dist = 35.;
  az = 0.25 * pi + 0.01 * tCur;
#endif
  ro = dist * vec3 (sin (az), 0., cos (az));
  ro.y = 5.;
  vd = normalize (vec3 (0., 3., 0.) - ro);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  rd = vuMat * normalize (vec3 (uv, 4.));
  vec3 col = ShowScene (ro, rd);
  fragColor = vec4 (col, 1.);
}


 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
