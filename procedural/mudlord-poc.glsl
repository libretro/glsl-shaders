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


vec3 rotatex(in vec3 p, float ang) { return vec3(p.x, p.y*cos(ang) - p.z*sin(ang), p.y*sin(ang) + p.z*cos(ang)); }

vec3 rotatey(in vec3 p, float ang) { return vec3(p.x*cos(ang) - p.z*sin(ang), p.y, p.x*sin(ang) + p.z*cos(ang)); }

vec3 rotatez(in vec3 p, float ang) { return vec3(p.x*cos(ang) - p.y*sin(ang), p.x*sin(ang) + p.y*cos(ang), p.z); }

float scene(vec3 p)
{
  float time = float(FrameCount)*0.015;
  p = rotatex(p, 0.18*time);
  p = rotatez(p, 0.20*time);
  p = rotatey(p, 0.22*time);

  float d0 = length(max(abs(p) - 0.5, 0.0)) - 0.01 + clamp(sin((p.x +p.y + p.z)*20.0)*0.03, 0.0, 1.0);
  float d1 = length(p) - 0.5;
  return sin(max(d0, -d1));
}

vec3 get_normal(vec3 p)
{
  vec3 eps = vec3(0.01, 0.0, 0.0);
  float nx = scene(p + eps.xyy) - scene(p - eps.xyy);
  float ny = scene(p + eps.yxy) - scene(p - eps.yxy);
  float nz = scene(p + eps.yyx) - scene(p - eps.yyx);
  return normalize(vec3(nx, ny, nz));
}

void main(void)
{

  vec2 p = 2.0 * (vTexCoord.xy*OutputSize.xy)/ OutputSize.xy - 1.0;
  
  p.x*=OutputSize.x/OutputSize.y;
  vec3 ro = vec3(0.0, 0.0, 1.7);
  vec3 rd = normalize(vec3(p.x, p.y, -1.4));
  vec3 color = (1.0 - vec3(length(p*0.5)))*0.2;
  vec3 pos = ro;
  float dist = 0.0;
  for (int i = 0; i < 64; i++)
  {
    float d = scene(pos);
    pos += rd*d;
    dist += d;
  }

  if (dist < 100.0)
  {
    vec3 n = get_normal(pos);
    vec3 r = reflect(normalize(pos - ro), n);
    vec3 h = -normalize(n + pos - ro);
    float diff = 1.0*clamp(dot(n, normalize(vec3(1, 1, 1))), 0.0, 1.0);
    float diff2 = 0.2*clamp(dot(n, normalize(vec3(0.7, -1, 0.5))), 0.0, 1.0);
    float diff3 = 0.1*clamp(dot(n, normalize(vec3(-0.7, -0.4, 0.7))), 0.0, 1.0);
    float spec = pow(clamp(dot(h, normalize(vec3(1, 1, 1))), 0.0, 1.0), 50.0);
    float amb = 0.2 + pos.y;
    color = diff*vec3(1, 1, 1) + diff2*vec3(1, 0, 0) + diff3*vec3(1, 0, 1) + spec*vec3(1, 1, 1) + amb*vec3(0.2, 0.2, 0.2);
    color /= dist;
  }
  FragColor = vec4(color, 1.0);
}
#endif