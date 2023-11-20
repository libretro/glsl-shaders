#version 110

#pragma parameter SIZE "Mask Type" 2.0 2.0 3.0 1.0

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define pi 3.1415926535897932384626433


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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0      
   
#endif
uniform vec2 OutputSize;
uniform vec2 TextureSize;
uniform vec2 InputSize;
varying vec2 TEX0;
varying vec2 scale;
varying float fragpos;
varying vec2 warpp;
varying vec2 dbwarp;

#if defined(VERTEX)
uniform mat4 MVPMatrix;
attribute vec4 VertexCoord;
attribute vec2 TexCoord;

void main()
{   
    TEX0 = TexCoord*1.0001;
    gl_Position = MVPMatrix * VertexCoord;
    scale = TextureSize.xy/InputSize.xy;
   warpp = TEX0.xy*scale;
   dbwarp = warpp*2.0-1.0;
   fragpos = warpp.x*OutputSize.x*pi*2.0/SIZE;
}

#elif defined(FRAGMENT)
uniform sampler2D Texture;

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

vec3 res = texture2D(Texture,p).rgb;

vec3 clean = res;
float w = dot(vec3(0.15),res);

// vignette  
float x = (warpp.x-0.5);  // range -0.5 to 0.5, 0.0 being center of screen
      x = x*x; 
res *= (0.25+x)*sin((y-0.25)*pi*2.0)+(0.75-x);
res *= 0.15*sin(fragpos)+0.85;

res = mix(res,clean, w);

#if defined GL_ES
res;
#else
res *= vec3(1.0,0.9,1.15);
#endif

float lum = dot(vec3(0.29,0.6,0.11),res);
res = mix(vec3(lum),res, 1.1);

res *= mix(1.25,1.0,w);
if (corn.y <= corn.x || corn.x < 0.0001 )res = vec3(0.0);

gl_FragColor.rgb = res;   
}
#endif
