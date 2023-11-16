#version 110



#define pi 3.1415926535897932384626433

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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float fragpos;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 dbwarp;


vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0      
   
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    scale = TextureSize.xy/InputSize.xy;
    warpp = TEX0.xy*scale;
    dbwarp = warpp*2.0-1.0;
    fragpos = warpp.x*OutputSize.x*pi*0.6666;
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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float fragpos;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 dbwarp;


// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE  1.0      
    
#endif

vec2 Warp(vec2 pos)
{
    pos = dbwarp;
    pos *= vec2(1.0+pos.y*pos.y*0.03, 1.0+pos.x*pos.x*0.04);
    pos = pos*0.5+0.5;
    return pos;
}

void main()
{
vec2 pos = Warp(warpp);
vec2 corn = min(pos, 1.0-pos);    // This is used to mask the rounded
  corn.x = 0.0002/corn.x;         // corners later on
  pos /= scale;

float y = pos.y*SourceSize.y;
float gl2pos = floor(y) + 0.5;
float near = gl2pos*SourceSize.w;
float dy = y - gl2pos;
      dy = dy*dy*dy*4.0*SourceSize.w;
   
vec2 p = vec2(pos.x, near+dy);

vec3 res = COMPAT_TEXTURE(Source,p).rgb;

vec3 clean = res;
float w = dot(vec3(0.15),res);

// vignette  
float x = (warpp.x-0.5);  // range -0.5 to 0.5, 0.0 being center of screen
      x = x*x;   
res *= (0.25+x)*sin((y-0.25)*pi*2.0)+(0.75-x);
res *= 0.15*sin(fragpos)+0.85;

res = mix(res,clean, w);

res *= vec3(1.0,0.85,1.2);


float lum = dot(vec3(0.29,0.6,0.11),res);
res = mix(vec3(lum),res, 1.1);

res *= mix(1.25,1.0,w);
if (corn.y <= corn.x || corn.x < 0.0001 )res = vec3(0.0);

FragColor.rgb = res;   
}
#endif
