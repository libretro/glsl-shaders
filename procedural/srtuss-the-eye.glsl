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

// The Eye -  srtuss - 2014-10-08
// https://www.shadertoy.com/view/Xd2XDm

// Another interesting, trippy 2D effect, with a cool retro colorset.

// srtuss, 2014

// a fun little effect based on repetition and motion-blur :)
// enjoy staring at the center, in fullscreen :)

#define pi2 3.1415926535897932384626433832795

float tri(float x, float s)
{
    return (abs(fract(x / s) - 0.5) - 0.25) * s;
}

float hash(float x)
{
    return fract(sin(x * 171.2972) * 18267.978 + 31.287);
}

vec3 pix(vec2 p, float t, float s)
{
    s += floor(t * 0.25);
    float scl = (hash(s + 30.0) * 4.0);
    scl += sin(t * 2.0) * 0.25 + sin(t) * 0.5;
    t *= 3.0;
    vec2 pol = vec2(atan(p.y, p.x), length(p));
    float v;
    float id = floor(pol.y * 2.0 * scl);
    pol.x += t * (hash(id + s) * 2.0 - 1.0) * 0.4;
    float si = hash(id + s * 2.0);
    float rp = floor(hash(id + s * 4.0) * 5.0 + 4.0);
    v = (abs(tri(pol.x, pi2 / rp)) - si * 0.1) * pol.y;
    v = max(v, abs(tri(pol.y, 1.0 / scl)) - (1.0 - si) * 0.11);
    v = smoothstep(0.01, 0.0, v);
    return vec3(v);
}

vec3 pix2(vec2 p, float t, float s)
{
    return clamp(pix(p, t, s) - pix(p, t, s + 8.0) + pix(p * 0.1, t, s + 80.0) * 0.2, vec3(0.0), vec3(1.0));
}

vec2 hash2(in vec2 p)
{
	return fract(1965.5786 * vec2(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * 49.077)));
}

#define globaltime (iGlobalTime - 2.555)

vec3 blur(vec2 p)
{
    vec3 ite = vec3(0.0);
    for(int i = 0; i < 20; i ++)
    {
        float tc = 0.15;
        ite += pix2(p, globaltime * 3.0 + (hash2(p + float(i)) - 0.5).x * tc, 5.0);
    }
    ite /= 20.0;
    ite += exp(fract(globaltime * 0.25 * 6.0) * -40.0) * 2.0;
    return ite;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    uv += (vec2(hash(globaltime), hash(globaltime + 9.999)) - 0.5) * 0.03;
    vec3 c = vec3(blur(uv + vec2(0.005, 0.0)).x, blur(uv + vec2(0.0, 0.005)).y, blur(uv).z);
    c = pow(c, vec3(0.4, 0.6, 1.0) * 2.0) * 1.5;
    c *= exp(length(uv) * -1.0) * 2.5;
    c = pow(c, vec3(1.0 / 2.2));
	fragColor = vec4(c, 1.0);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
