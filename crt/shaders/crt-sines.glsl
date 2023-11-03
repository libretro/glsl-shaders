#version 110

/* 
  crt-sines, a work by DariusG 2023
  
  v1.8 replaced fake vignette with CRT accurate one.
  v1.7b minor tweaks here and there.
  v1.7 re-worked from scratch, compacted, faster, better looking and glow added. 
       that is almost the limit of what an HTC One M7 can do. 
  v1.6 speed-up tweaks, corrected some errors (e.g. too bright on slot mask)
  v1.5 re-worked version with better colors (real Trinitron), add Android preset
  v1.4c added real Trinitron color profile as default, with real measured primaries
  v1.4b added some system specific tweaks
  v1.4 removed junk, optimized white point a bit
  v1.3 added more color options and Color Temp switch
  v1.2b: Lanczos4 --> Lanczos2 for performance. mask 0 improved
  v1.2: improved mask/scanlines
  v1.1: switched to lanczos4 taps filter
*/


#pragma parameter CURV "Curvature On/Off" 1.0 0.0 1.0 1.0
#pragma parameter scanl "Scanlines/Mask Low" 0.4 0.0 1.0 0.05
#pragma parameter scanh "Scanlines/Mask High" 0.2 0.0 1.0 0.05
#pragma parameter SIZE "Mask Type, 2:Fine, 3:Coarse" 3.0 2.0 3.0 1.0
#pragma parameter glow "Glow Strength" 0.16 0.0 1.0 0.02
#pragma parameter Trin "Trinitron Colors" 1.0 0.0 1.0 1.0
#pragma parameter sat "Saturation" 1.1 0.0 2.0 0.05
#pragma parameter bogus_conv " [ CONVERGENCE ] " 0.0 0.0 0.0 0.0
#pragma parameter RX "Red Convergence Horiz." 0.0 -2.0 2.0 0.05
#pragma parameter RY "Red Convergence Vert." 0.0 -2.0 2.0 0.05
#pragma parameter GX "Green Convergence Horiz." 0.0 -2.0 2.0 0.05
#pragma parameter GY "Green Convergence Vert." 0.0 -2.0 2.0 0.05
#pragma parameter BX "Blue Convergence Horiz." 0.0 -2.0 2.0 0.05
#pragma parameter BY "Blue Convergence Vert." 0.0 -2.0 2.0 0.05

#define pi 3.14159265

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
COMPAT_VARYING vec2 warp;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING float fragpos;
COMPAT_VARYING vec2 ps;
COMPAT_VARYING vec2 psg;
COMPAT_VARYING vec3 dx;
COMPAT_VARYING vec3 dy;

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
uniform COMPAT_PRECISION float RX;
uniform COMPAT_PRECISION float RY;
uniform COMPAT_PRECISION float GX;
uniform COMPAT_PRECISION float GY;
uniform COMPAT_PRECISION float BX;
uniform COMPAT_PRECISION float BY;
#else
#define SIZE     2.0 
#define RX 0.0     
#define RY 0.0     
#define GX 0.0     
#define GY 0.0     
#define BX 0.0     
#define BY 0.0       
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    scale = TextureSize.xy/InputSize.xy;
    fragpos = TEX0.x*OutputSize.x*scale.x*2.0/SIZE;
    warp = TEX0.xy*scale;
    warpp = warp*2.0-1.0;
    ps = 1.0/TextureSize.xy;
    psg = vec2(1.5)/TextureSize.xy;
    dx = ps.x*vec3(RX,GX,BX);
    dy = ps.y*vec3(RY,GY,BY);
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
COMPAT_VARYING vec2 warp;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 ps;
COMPAT_VARYING vec2 psg;
COMPAT_VARYING vec3 dx;
COMPAT_VARYING vec3 dy;
// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float scanl;
uniform COMPAT_PRECISION float scanh;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float Trin;
uniform COMPAT_PRECISION float CURV;
uniform COMPAT_PRECISION float glow;
#else
#define scanl  0.5      
#define scanh  0.22      
#define sat  1.1  
#define Trin  1.0
#define CURV  1.0
#define glow  0.25   
#endif

vec2 Warp(vec2 pos)
{   
    pos *= vec2(1.0 + pos.y*pos.y*0.02, 1.0 + pos.x*pos.x*0.03);
    pos = pos*0.5 + 0.5;
    return pos;
}

#if defined GL_ES
 mat3 hue = mat3(
    1.0,  0.05, 0.05,
    -0.05, 1.0, -0.1,
    -0.05, 0.1,  1.0
);
#else
mat3 hue = mat3(
      0.95,  0.0, 0.05,
     -0.05,  1.0, -0.2,
      0.0,  0.15, 1.1
);
#endif


vec3 Glow (vec2 pos, vec3 frame)
{
    vec2 x = vec2(psg.x,0.0);
    vec2 y = vec2(0.0,psg.y);

    vec3 c00 = frame*0.28;
    vec3 c01 = COMPAT_TEXTURE(Source,pos + x).rgb*0.18;
    vec3 c02 = COMPAT_TEXTURE(Source,pos - x).rgb*0.18;
    vec3 c03 = COMPAT_TEXTURE(Source,pos + y).rgb*0.18;
    vec3 c04 = COMPAT_TEXTURE(Source,pos - y).rgb*0.18;

    vec3 glo = (c00+c01+c02+c03+c04); 
    float w = dot (vec3(0.33),glo);
    glo *= mix(0.0,1.25,w);
    return glo * glow;
}

void main()
{
vec2 pos;
 vec2 corn ;

 if (CURV == 1.0){
  pos = Warp(warpp);
  corn = min(pos, 1.0-pos);    // This is used to mask the rounded
  corn.x = 0.0003/corn.x;     // corners later on
  pos /= scale;
}

else pos = vTexCoord;
// Hermite
  vec2 ogl2pos = pos*TextureSize.xy;
  vec2 p = ogl2pos+0.5;
  vec2 i = floor(p);
  vec2 f = p - i;        // -0.5 to 0.5
       f = f*f*f*(3.0-2.0*f);
       f.y *= f.y;
       p = (i + f-0.5)*ps;
// Convergence
  vec3 res = COMPAT_TEXTURE(Source,p).rgb;
  float r =  COMPAT_TEXTURE(Source,p + vec2(dx.r,dy.r)).r;
  float g =  COMPAT_TEXTURE(Source,p + vec2(dx.g,dy.g)).g;
  float b =  COMPAT_TEXTURE(Source,p + vec2(dx.b,dy.b)).b;

// vignette  
  float x = (warp.x-0.5);  // range -0.5 to 0.5, 0.0 being center of screen
  x = x*x;    // curved response: higher values (more far from center) get higher results.

  vec3 conv = vec3(r,g,b);
  res = res*0.5 + conv*0.5;

// Glow, the more costly, costed ~15 fps and removal of slotmask to be able to handle all.
  res += Glow(p,res);   

 float w = dot(vec3(0.28),res);
 float scan = mix(scanl,scanh,w);
 float mask = scan*0.666;

// apply vignette here
 float scn = (scan+x)*sin((ogl2pos.y+0.5)*pi*2.0)+1.0-(scan+x);
 float msk = mask*sin(fragpos*pi)+1.0-mask;

    res = res*res; 

    if(Trin == 1.0) {res *= hue; 
    res = clamp(res,0.0,1.0);}

    res *= scn*msk;
    res = sqrt(res);
  float gray = dot(vec3(0.3,0.6,0.1),res);
    res  = mix(vec3(gray),res,sat);
    res *= mix(1.25,1.0,w);
    if (corn.y <= corn.x && CURV == 1.0 || corn.x < 0.0001 && CURV == 1.0 )res = vec3(0.0);

FragColor.rgb = res;
    
}
#endif
