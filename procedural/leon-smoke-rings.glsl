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

// Smoke Rings -  leon - 2017-05-09
// https://www.shadertoy.com/view/4sSyDd

// Experimenting shapes

// training for modeling shapes
// using koltes code as base https://www.shadertoy.com/view/XdByD3
// using iq articles
// using mercury library

#define PI 3.1415926535897932384626433832795
#define TAU 6.283185307179586476925286766559
#define t iGlobalTime

mat2 rz2 (float a) { float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }
float sphere (vec3 p, float r) { return length(p)-r; }
float iso (vec3 p, float r) { return dot(p, normalize(sign(p)))-r; }
float cyl (vec2 p, float r) { return length(p)-r; }
float cube (vec3 p, vec3 r) { return length(max(abs(p)-r,0.)); }
vec2 modA (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an*.5;
    a = mod(a, an)-an*.5;
    return vec2(cos(a),sin(a))*length(p);
}
float smin (float a, float b, float r)
{
    float h = clamp(.5+.5*(b-a)/r,0.,1.);
    return mix(b, a, h) - r*h*(1.-h);
}

float map (vec3 p)
{
    float sph3 = sphere(p, 3.);
    p.yz *= rz2(t*.2);
    p.xy *= rz2(t*.3);
    
    float d = length(p);
    
    float a = atan(p.y,p.x);
    float l = length(p.xy)-2.;
    p.xy = vec2(l,a);
    
    float as = PI*0.3;
    p.z += sin(a*2.+sin(l*4.))*.5;
    
    float wave1 = sin(p.y*6.)*.5+.5;
    float wave2 = .5+.5*sin(p.z*3.+t);
    
    p.x -= sin(p.z*1.+t)*.5;
    p.z = mod(p.z+t,as)-as*.5;
    
    float sphR = .2-.1*wave1;
    float sphC = .3;
    float sphN = 0.2;
    float sph1 = sphere(vec3(p.x,mod(sphN*p.y/TAU+t*.1,sphC)-sphC*.5,p.z), sphR);
    
    p.xz *= rz2(p.y*3.);
    p.xz = modA(p.xz, 3.);
    p.x -= 0.3*wave2;
    float cyl1 = cyl(p.xz, 0.02);
    float sph2 = sphere(vec3(p.x,mod(p.y*2.-t,1.)-.5,p.z), .1);
    
    return smin(sph1, smin(cyl1,sph2,.2), .2);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy-.5*iResolution.xy)/iResolution.y;
    vec3 ro = vec3(uv,-5), rp = vec3(uv,1), mp = ro;
    int i = 0;
    const int count = 50;
    for(;i<count;++i) {
		float md = map(mp);
        if (md < 0.001) {
            break;
        }
        mp += rp*md*.35;
    }
    float r = float(i)/float(count);
    fragColor = vec4(1);
    fragColor *= smoothstep(.0,10.,length(mp-ro));
  	fragColor *= r;
    fragColor = 1. - fragColor;
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
