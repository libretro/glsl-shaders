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

// ironicflux - greendestruction - 2018-02-22
// https://www.shadertoy.com/view/MdcyzB
// The words of these songs were composed without any human intervention whatever on an instrument known as a versificator. But the woman sang so tunefully as to turn the dreadful rubbish into an almost pleasant sound.

/* it even comes with a little message */

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float map(vec3 p) {
    
    p.z = abs(p.z) - 2.0;
    p.z = abs(p.z) - 2.0;
    
    
    float gt = iGlobalTime * 2.0;
    p.x += gt;
    float d = 1000.0;
    const int n = 12;
    for (int i = 1; i < n; ++i) {
        float x = float(i) / float(n);
        vec3 q = p;
        q.x += x * 3.141592 * 1.0;
        q.z = abs(q.z) - 1.0;
        q.yz *= rot(x * q.x);
        q.y = abs(q.y) - 2.0;
        q.y += x * 3.141592 * 0.5;
        float k = length(q.yz) - 0.125;
        d = min(d, k);
        d = max(d, 1.5 * x + gt - p.x);
    }
    return min(d, 5.0 + gt - p.x);
}

float trace(vec3 o, vec3 r) {
    float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        t += map(o + r * t) * 0.5;
    }
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv, uv) * 0.5));
    vec3 o = vec3(0.0, 0.0, 0.0);
    
    r.xz *= rot(3.141592 * 0.5);
    
    float t = trace(o, r);
    
    vec3 w = o + r * t;
    float fd = map(w);

    float f = 1.0 / (1.0 + t * t * 0.1 + fd * 1000.0);

    vec3 c = vec3(0.0, 0.5, 1.0) * f;
    
    c = mix(c, vec3(1.0), 1.0 / (1.0 + t * t * 0.1));
    
    c = mix(vec3(0.125), c, 1.0 / (1.0 + t * t * 0.1));
    
    vec3 fc = vec3(c);
    
    float b = sign((fract(uv.y * 16.0) - 0.5) / 16.0) * 0.5 + 0.5;
    
    float b2 = sign(0.8 - abs(uv.y)) * 0.5 + 0.5;
    
    fc = mix(fc * vec3(0.5, 0.5, 0.5), fc, b);
    
    fc *= b2;

    fragColor = vec4(fc, 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
