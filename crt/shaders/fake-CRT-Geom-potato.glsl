#version 110

#pragma parameter size "Mask Size" 1.0 0.6667 1.0 0.3333

#define PI   3.14159265358979323846
#define tau  6.283185

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
COMPAT_VARYING vec2 screenscale;
COMPAT_VARYING float maskpos;

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float size;
#else
#define size 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    screenscale = SourceSize.xy/InputSize.xy;
    maskpos = TEX0.x*OutputSize.x*screenscale.x*PI*size;
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
COMPAT_VARYING float maskpos;
COMPAT_VARYING vec2 screenscale;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float sharpness;


#else
#define sharpness 0.0

#endif

vec2 Warp(vec2 coord)
{
        coord -= vec2(0.5);
        float rsq = dot(coord,coord);
        // x and y axis distortion
        coord += coord*(vec2(0.13, 0.23)*rsq);
        // Barrel distortion shrinks the display area a bit, 
        // this will allow us to counteract that.
        coord *= vec2(0.99,0.95);

        return coord+0.5;
}

void main() 
{
vec2 pos = Warp(vTexCoord*screenscale);

vec2 corn = min(pos, 1.0-pos);    // This is used to mask the rounded
     corn.x = 0.0001/corn.x;      // corners later on
pos /= screenscale;

vec2 spos = pos*SourceSize.xy;
vec2 near = floor(spos)+0.5;
vec2 f = spos - near;

pos.y = (near.y + 16.0*f.y*f.y*f.y*f.y*f.y)*SourceSize.w;    

vec3 res = COMPAT_TEXTURE(Source,pos).rgb;
    
float l = dot(vec3(0.25),res);

float scan_pow = mix(0.5,0.2,l);
float scn = scan_pow*sin((spos.y-0.25)*tau)+1.0-scan_pow;
float msk = 0.2*sin(maskpos)+0.8;

res *= scn*msk;
res *= mix(1.45,1.25,l);
res = sqrt(res);
if (corn.y <= corn.x || corn.x < 0.0001 )res = vec3(0.0);

FragColor.rgb = res;
}
#endif
