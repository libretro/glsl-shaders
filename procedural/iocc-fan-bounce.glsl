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

//////////////////////////////////////////////////////////////////////
//
// "State-less" physics demonstration. Probably useless.
//
// Written by ioccc_fan, license:
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
//
//////////////////////////////////////////////////////////////////////

// x/z size of box (minus ball radius)
#define size     1.0

// radius of ball
#define rad      0.1

// x/z size of box 
#define dsize   (size+rad)

// initial velocity in x, y, z
#define dx0      3.0
#define dy0     10.0
#define dz0      1.0

// accel due to gravity
#define g        9.8     

// coeff. of restitution for vertical bounces
#define gamma    0.9     

// inverse coeff. of restitution for horiz. bounces
#define invgamma 1.6     

// height at which ball "shadow" vanishes
#define hmax     6.0     

// height at which box walls turn black
#define smax     4.0     

#define M_PI 3.14159265

// initial velocity for x/z as vector
const vec2 dxz0 = vec2(dx0, dz0);

// magic numbers for timing:
const float Ty0 = 2.0*dy0/g;
const float ty0 = 0.5*Ty0;
const vec2 Txz0 = vec2(2.0*size/dxz0);
const vec2 txz0 = vec2(0.5*Txz0.x, 0.25*Txz0.y);

//////////////////////////////////////////////////////////////////////
// helper stuff for raytracing:

// struct to track raytracing hits
struct hit_t {
  float t;
  vec3  N;
  vec3  color;
};

// detect hitting a plane - there's got to be a way to do this with
// fewer parameters :(
bool plane(in vec3 o, 
           in vec3 d,
           in vec3 N,
           in float D,
           in vec3 tx, 
           in vec3 ty,
           in vec2 lo, 
           in vec2 hi,
           in vec3 color,
           inout hit_t res) {

  float num = (D - dot(o, N));
  float denom = dot(d, N);
  if (num < 0.0 && denom < 0.0) { 
    float t = num / denom;
    vec3  p = o+d*t;
    float x = dot(p, tx);
    float y = dot(p, ty);
    if (x > lo.x && x < hi.x &&
        y > lo.y && y < hi.y && t < res.t) {
      res.t = t;
      res.N = N;
      res.color = color;
      return true;
    }
  }

  return false;

}

// raytrace a sphere
bool sphere(in vec3 o,
            in vec3 d,
            in vec3 s,
            in float r,
            in vec3 color,
            inout hit_t res) {

  o -= s;

  float p = -dot(o, d);
  float q = dot(o, o) - r*r;

  float D = p*p - q;
  if (D >= 0.0) {
    float sqrtD = sqrt(D);
    float t = min(p+sqrtD, p-sqrtD);
    if (t > 0.0 && t < res.t) {
      res.t = t;
      res.N = normalize(o + d*t);
      res.color = color;
      return true;
    }
  }

  return false;


}

//////////////////////////////////////////////////////////////////////
// raytrace the scene

vec3 raytrace(vec3 o, vec3 d, vec3 s, vec3 L) {
  
  hit_t res = hit_t(1e5, vec3(0), vec3(-1.0));

  vec3 X = vec3(1.0, 0.0, 0.0);
  vec3 Y = vec3(0.0, 1.0, 0.0);
  vec3 Z = vec3(0.0, 0.0, 1.0);

  vec2 wall_lo = vec2(-dsize, -rad);
  vec2 wall_hi = vec2( dsize,  1e4);

  vec3 wc = vec3(0.8, 0.8, 1.0);
  vec3 fc = vec3(1.0, 0.9, 0.7);

  if (plane(o, d,  Z, -dsize, X, Y, wall_lo, wall_hi, wc, res) ||
      plane(o, d, -Z, -dsize, X, Y, wall_lo, wall_hi, wc, res) ||
      plane(o, d,  X, -dsize, Z, Y, wall_lo, wall_hi, wc, res) ||
      plane(o, d, -X, -dsize, Z, Y, wall_lo, wall_hi, wc, res) ) {
    // fade walls out
    vec3 p = o+res.t*d;
    res.color *= 1.0 - p.y/smax;
  }

  if (plane(o, d,  Y, -rad, X, Z, vec2(-dsize), vec2(dsize), fc, res)) {
    // fake shadow with incorrect lighting, whatever
    vec3 p = o+res.t*d;
    float d = length((p-s).xz);
    float u = clamp(0.75*(1.0 - s.y/hmax), 0.0, 1.0);
    res.color *= smoothstep(d, 0.0, 0.5*rad)*u + (1.0-u);
  }

  vec3 lgray = vec3(0.8);

  sphere(o, d, s, rad, vec3(1.0, 0.0, 0.0), res);

  if (res.color.x >= 0.0) {
     res.color *= (clamp(dot(res.N, L), 0.0, 1.0) * 0.7 + 0.3);
     res.color = mix(res.color, vec3(1.0), 
                     pow(clamp(dot(res.N, normalize(L-d)),0.,1.),40.0));
     return res.color;
  } else {
    return vec3(0.0);
  }

}

//////////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

  //////////////////////////////////////////////////
  // figure out where the ball is

  vec2 txz = iGlobalTime + txz0;
  float ty = iGlobalTime + ty0;

  vec3 ball_pos = vec3(0.0);

  float fy = 1.0 - (1.0-gamma)*ty/Ty0;

  float lg = log(gamma);

  if (fy > 1e-4) {

    float n = floor( log( fy ) / lg );
    float gn = pow(gamma, n);

    float dyn = dy0 * gn;
    ty -= Ty0 * (1.0 - gn) / (1.0 - gamma);

    ball_pos.y = -0.5*g*ty*ty + dyn*ty;

  }

  vec2 fxz = 1.0 - (1.0 - invgamma)*txz/Txz0;

  float lig = log(invgamma);
  vec2 nxz = floor( log(fxz) / lig );
  vec2 ign = pow(vec2(invgamma), nxz);
  vec2 sxz = mod(nxz, 2.0)*2.0 - vec2(1.0);

  txz -= Txz0 * vec2(1.0 - ign) / vec2(1.0 - invgamma);
  vec2 dxzn = dxz0/ign;
  ball_pos.xz = sxz*(size - txz*dxzn);

  //////////////////////////////////////////////////
  // now raytrace the scene

#ifdef MOUSE
  vec2 rot = vec2(2.0, 1.0)*M_PI*(iMouse.xy - 0.5*iResolution.xy) / iResolution.xy;

  if (iMouse.x<=0.0 || iMouse.y<=0.0){
    rot = vec2(0.0);
  }
#else
  vec2 rot = vec2(2.0, 1.0)*M_PI*(0.0 - 0.5*iResolution.xy) / iResolution.xy;
#endif

  mat3 Ry = mat3( cos(rot.x), 0.0, -sin(rot.x),
                  0.0, 1.0, 0.0,
                  sin(rot.x), 0.0, cos(rot.x));
  
  mat3 Rx = mat3( 1.0, 0.0, 0.0,  
                  0.0, cos(rot.y), -sin(rot.y),
                  0.0, sin(rot.y), cos(rot.y) );

  vec3 t = vec3(0.0, 1.1*size, 0.0);
  vec3 o = t + Ry*Rx*(vec3(0.0, t.y, 6.4*size)-t);

  vec3 rz = normalize(t-o);
  vec3 rx = normalize(cross(rz, vec3(0.0, 1.0, 0.0)));
  vec3 ry = cross(rz, rx);

  float px = (fragCoord.x - iResolution.x*0.5);
  float py = (-fragCoord.y + iResolution.y*0.5);

  vec3 d = normalize( rx*px + ry*py + rz*2.25*iResolution.y );

  vec3 L = Ry*Rx*normalize(vec3(-1.0, 1.0, 2.0));

  fragColor.xyz = raytrace(o, d, ball_pos, L);
  fragColor.w = 1.0;

}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
