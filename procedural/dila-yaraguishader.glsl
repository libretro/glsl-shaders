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

float sdBoxXY( vec3 p, vec3 b )
{
  vec2 d = abs(p.xy) - b.xy;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

mat2 rot(float x) {
	return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float map(vec3 p) {
    float k = 0.5 * 2.0;
	vec3 q = (fract((p - vec3(0.25, 0.0, 0.25))/ k) - 0.5) * k;
    vec3 s = vec3(q.x, p.y, q.z);
    float d = udRoundBox(s, vec3(0.1, 1.0, 0.1), 0.05);
    
    k = 0.5;
    q = (fract(p / k) - 0.5) * k;
    s = vec3(q.x, abs(p.y) - 1.5, q.z);
    float g = udRoundBox(s, vec3(0.17, 0.5, 0.17), 0.2);
    
    float sq = sqrt(0.5);
    vec3 u = p;
    u.xz *= mat2(sq, sq, -sq, sq);
    d = max(d, -sdBoxXY(u, vec3(0.8, 1.0, 0.8)));
    
    return smin(d, g, 16.0);
}

vec3 normal(vec3 p)
{
	vec3 o = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy) - map(p-o.xyy),
                          map(p+o.yxy) - map(p-o.yxy),
                          map(p+o.yyx) - map(p-o.yyx)));
}

float trace(vec3 o, vec3 r) {
    float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        t += map(o + r * t);
    }
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float gt = iGlobalTime / 5.0;
    vec3 r = normalize(vec3(uv, 1.7 - dot(uv, uv) * 0.1));
    float sgt = sin(gt * 3.141592 * 2.0);
    r.xy *= rot(sgt * 3.141592 / 8.0);
    r.xz *= rot(gt * 3.141592 * 2.0);
    r.xz *= rot(3.141592 * -0.25);

    vec3 o = vec3(0.0, 0.0, gt * 5.0 * sqrt(2.0) * 2.0);
    o.xz *= rot(3.141592 * -0.25);

    float t = trace(o, r);
    vec3 w = o + r * t;
    vec3 sn = normal(w);
    float fd = map(w);

    vec3 col = vec3(0.514, 0.851, 0.933) * 0.5;
    vec3 ldir = normalize(vec3(-1, -0.5, 1.1));

    float fog = 1.0 / (1.0 + t * t * 0.1 + fd * 100.0);
    float front = max(dot(r, -sn), 0.0);
    float ref = max(dot(r, reflect(-ldir, sn)), 0.0);
    float grn = pow(abs(sn.y), 3.0);

    vec3 cl = vec3(grn);
    cl += mix(col*vec3(1.5), vec3(0.25), grn) * pow(ref, 16.0);
    cl = mix(col, cl, fog);

	fragColor = vec4(cl, 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
