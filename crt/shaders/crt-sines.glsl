#version 110

/* 
  work by DariusG 2023, some ideas borrowed from Dogway's zfast_crt_geo
  
  v1.6  speed-up tweaks, corrected some errors (e.g. too bright on slot mask)
  v1.5  re-worked version with better colors (real Trinitron), add Android preset
  v1.4c added real Trinitron color profile as default, with real measured primaries
  v1.4b added some system specific tweaks
  v1.4 removed junk, optimized white point a bit
  v1.3 added more color options and Color Temp switch
  v1.2b: Lanczos4 --> Lanczos2 for performance. mask 0 improved
  v1.2: improved mask/scanlines
  v1.1: switched to lanczos4 taps filter
*/

#pragma parameter SHARPX "Blurriness Horiz." 0.3 0.0 1.0 0.05

#pragma parameter CURV "Curvature On/Off" 1.0 0.0 1.0 1.0
#pragma parameter NTSC_asp "Amiga NTSC-PAL,eg Monkey Island" 0.0 0.0 01.0 1.0

#pragma parameter bogus_ms " [ SCANLINES/MASK ] " 0.0 0.0 1.0 0.0
#pragma parameter interlacing "Interlacing On/Off" 1.0 0.0 1.0 1.0
#pragma parameter SCANLOW "Scanline Low" 0.6 0.0 1.0 0.05
#pragma parameter SCANHIGH "Scanline High" 0.3 0.0 1.0 0.05
#pragma parameter mask "Mask type: 1-Dotmask, 2-RGB, 3-SlotMask" 2.0 0.0 3.0 1.0
#pragma parameter m_str "Mask Strength" 0.3 0.0 0.5 0.05
#pragma parameter slotx "Slot Mask Size x" 3.0 2.0 3.0 1.0

#pragma parameter bogus_conv " [ CONVERGENCE ] " 0.0 0.0 1.0 0.0
#pragma parameter RX "Red Convergence Horiz." 0.0 -1.0 1.0 0.05
#pragma parameter RY "Red Convergence Vert." 0.0 -1.0 1.0 0.05
#pragma parameter GX "Green Convergence Horiz." 0.0 -1.0 1.0 0.05
#pragma parameter GY "Green Convergence Vert." 0.0 -1.0 1.0 0.05
#pragma parameter BX "Blue Convergence Horiz." 0.0 -1.0 1.0 0.05
#pragma parameter BY "Blue Convergence Vert." 0.0 -1.0 1.0 0.05

#pragma parameter bogus_col " [ COLORS ] " 0.0 0.0 1.0 0.0
#pragma parameter BOOST "Bright Boost" 0.15 0.0 1.0 0.05
#pragma parameter SAT "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter CRT "Trinitron Colors, 1:PC1, 2:PC2, 3:Android" 1.0 0.0 3.0 1.0


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
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 ps;
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
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float RX;
uniform COMPAT_PRECISION float RY;
uniform COMPAT_PRECISION float GX;
uniform COMPAT_PRECISION float GY;
uniform COMPAT_PRECISION float BX;
uniform COMPAT_PRECISION float BY;
#else
#define mask     1.0      
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
    float size = 1.0;
    if (mask == 2.0) size = 0.6667;
    maskpos = TEX0.xy*OutputSize.xy*TextureSize.xy/InputSize.xy*size;
    warpp = TEX0.xy*scale*2.0-1.0;
    ps = 1.0/TextureSize.xy;
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
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 ps;
COMPAT_VARYING vec3 dx;
COMPAT_VARYING vec3 dy;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SCANLOW;
uniform COMPAT_PRECISION float SCANHIGH;
uniform COMPAT_PRECISION float SHARPX;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float m_str;
uniform COMPAT_PRECISION float BOOST;
uniform COMPAT_PRECISION float SAT;
uniform COMPAT_PRECISION float CRT;
uniform COMPAT_PRECISION float CURV;
uniform COMPAT_PRECISION float NTSC_asp;
uniform COMPAT_PRECISION float slotx;
uniform COMPAT_PRECISION float interlacing;

#else
#define slotx 1.0
#define mask 1.0
#define SCANLOW 0.5
#define SCANHIGH 0.3
#define SHARPX 0.3
#define m_str 0.3          
#define BOOST 0.0     
#define SAT 1.3     
#define CRT 1.0     
#define CURV 1.0     
#define NTSC_asp 0.0     
#define interlacing 1.0     
#endif


float Mask()
{
    float oddx = 0.0;
    vec2 pos = maskpos;
if (mask == 1.0 || mask == 2.0) return m_str*sin(pos.x*pi)+1.0-m_str;
  
if (mask == 3.0)
    {
        oddx = mod(maskpos.x,slotx*2.0) < slotx ? 1.0 : 0.0;

        return m_str*(sin(pos.x*2.0/slotx*pi) 
              + sin((pos.y+oddx)*pi))+1.0-m_str ;
    }

if (mask == 0.0) return 1.0;
}

vec2 Warp(vec2 pos)
{
    pos *= vec2(1.0+pos.y*pos.y*0.031, 1.0 + pos.x*pos.x*0.042);
    pos = pos*0.5 + 0.5;
    return pos;
}

mat3 huePC = mat3(
    1.05, -0.05, 0.1,
    -0.1, 1.2, -0.2,
    0.1, 0.15, 1.0
);
mat3 huePC2 = mat3(
    1.0,  0.0, 0.04,
    0.06, 1.0, 0.0,
    0.08, 0.15, 1.0
);
mat3 hueAnd = mat3(
    1.0,  -0.03, -0.04,
    0.03, 1.0, -0.11,
    0.04, 0.11, 1.05
);

void main()
{
  vec2 pos,c,corn;
  if (CURV == 1.0)  
  {pos = Warp(warpp);
     // CORNERS
    c = pos;
    corn   = min(c, 1.0-c);    // This is used to mask the rounded
    corn.x = 0.0001/corn.x; // corners later on
  pos /= scale;
  }
  else pos = vTexCoord;  
    
  if(NTSC_asp == 1.0) { pos.y *= 200.0/240.0; 
                        pos.y += 0.005;}

  vec2 bpos = pos;

  vec2 p = pos*SourceSize.xy ;
  vec2 i = floor(pos*SourceSize.xy) + 0.5;
  vec2 f = p - i;        // -0.5 to 0.5
    f = 4.0*f*f*f;
    p = (i + f)*ps;

    p.x = mix(p.x,pos.x,SHARPX);


  vec3 res = COMPAT_TEXTURE(Source,p).rgb;
  float r =  COMPAT_TEXTURE(Source,p + vec2(dx.r,dy.r)).r;
  float g =  COMPAT_TEXTURE(Source,p + vec2(dx.g,dy.g)).g;
  float b =  COMPAT_TEXTURE(Source,p + vec2(dx.b,dy.b)).b;

  vec3 conv = vec3(r,g,b);

  res = res*0.5 + conv*0.5;
  
  if(CRT == 1.0) res *= huePC;
  if(CRT == 2.0) res *= huePC2;
  if(CRT == 3.0) res *= hueAnd;
  
  vec3 clean = res;
  float w = dot(vec3(BOOST),clean);
  float l = max(max(res.r,res.g),res.b);

  float SCAN = mix(SCANLOW,SCANHIGH,l);

  float size = 1.0;
  if (InputSize.y > 400.0) size = 0.5;
  float yy = bpos.y*SourceSize.y*2.0*size-0.5;

// interlacing
  if (interlacing == 1.0 && InputSize.y > 400.0) 
  {yy =  mod(float(FrameCount),2.0) < 1.0? 1.0+yy : yy;} 
  
  float scn = BOOST+(SCAN * sin(yy*pi)+1.0-SCAN)/(1.0+BOOST*l);

  res *= sqrt(scn*Mask());

  vec3 lumweight = vec3(0.29,0.6,0.11);

  float grays = dot(lumweight,res);
  res = mix(res,clean,w);
  res = mix(vec3(grays),res, SAT);
  if (corn.y <= corn.x && CURV == 1.0 || corn.x < 0.0001 && CURV ==1.0 )res = vec3(0.0);
  FragColor.rgb = res;
}
#endif
