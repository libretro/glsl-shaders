// Parameter lines go here:
#pragma parameter LINES "Lines" 4.0 2.0 5.0 1.0
#pragma parameter TATE "TATE mode"  0.0 0.0 1.0 1.0
#pragma parameter L1 "Line 1 Scanline Strength %" 0.25 0.0 1.0 0.01
#pragma parameter L2 "Line 2 Scanline Strength %" 0.0 0.0 1.0 0.01
#pragma parameter L3 "Line 3 Scanline Strength %" 0.0 0.0 1.0 0.01
#pragma parameter L4 "Line 4 Scanline Strength %" 0.4 0.0 1.0 0.01
#pragma parameter L5 "Line 5 Scanline Strength %" 0.5 0.0 1.0 0.01
#pragma parameter HYBRID "Scanline Hybrid Blend % (depend on pixel overlayed)" 0.0 0.0 1.0 0.01
#pragma parameter OVERSCAN "Overscan" 0.0 0.0 1.0 1.0 
#pragma parameter something "--Set Retroarch Aspect to FULL--" 0.0 0.0 0.0 0.0
#pragma parameter ASPECTX "Aspect Ratio X" 4.0 1.0 32.0 1.0 
#pragma parameter ASPECTY "Aspect Ratio Y" 3.0 1.0 32.0 1.0 

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
COMPAT_VARYING vec4 TEX0;


vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;


void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float LINES;
uniform COMPAT_PRECISION float TATE;
uniform COMPAT_PRECISION float L1;
uniform COMPAT_PRECISION float L2;
uniform COMPAT_PRECISION float L3;
uniform COMPAT_PRECISION float L4;
uniform COMPAT_PRECISION float L5;
uniform COMPAT_PRECISION float HYBRID;
uniform COMPAT_PRECISION float OVERSCAN;
uniform COMPAT_PRECISION float ASPECTX;
uniform COMPAT_PRECISION float ASPECTY;

#else
#define LINES 4.0
#define TATE 0.0
#define L1 0.2
#define L2 0.0 
#define L3 0.0 
#define L4 0.4
#define L5 0.5
#define HYBRID 0.0
#define OVERSCAN 0.0
#define ASPECTX 4.0
#define ASPECTY 3.0

#endif




float scanline5(float y, float lm)
{
   float l = 1.0/LINES;
   float m = fract(y*l);
   if (m<l) return 1.0-L1*(1.0-lm*HYBRID);
   else if (m<2.0*l) return 1.0-L2*(1.0-lm*HYBRID);
   else if (m<3.0*l) return 1.0-L3*(1.0-lm*HYBRID);
   else if (m<4.0*l) return 1.0-L4*(1.0-lm*HYBRID);
   else return 1.0-L5*(1.0-lm*HYBRID);
}

float scanline4(float y, float lm)
{
   float l = 1.0/LINES;
   float m = fract(y*l);
   if (m<l) return 1.0-L1*(1.0-lm*HYBRID);
   else if (m<2.0*l) return 1.0-L2*(1.0-lm*HYBRID);
   else if (m<3.0*l) return 1.0-L3*(1.0-lm*HYBRID);
   else return   1.0-L4*(1.0-lm*HYBRID); 
}

float scanline3(float y, float lm)
{
   float l = 1.0/LINES;
   float m = fract(y*l);
   if (m<l) return 1.0-L1*(1.0-lm*HYBRID);
   else if (m<2.0*l) return 1.0-L2*(1.0-lm*HYBRID);
   else return   1.0-L3*(1.0-lm*HYBRID);
}

float scanline2(float y, float lm)
{
   float l = 1.0/LINES;
   float m = fract(y*l);
   if (m<l) return 1.0-L1*(1.0-lm*HYBRID);
   else return 1.0-L2*(1.0-lm*HYBRID);
      
}
vec2 Overscan(vec2 pos, float dx, float dy){
   pos = pos*2.0-1.0;    
   pos *=vec2(dx/(ASPECTX/ASPECTY/OutputSize.x*OutputSize.y),dy);
   return pos*0.5 + 0.5;
} 
void main()
{
   vec2 texcoord = vTexCoord.xy;
   vec2 ofactor = OutputSize.xy/InputSize.xy;
   vec2 intfactor;
   if (OVERSCAN == 0.0) intfactor = floor(ofactor); else intfactor = ceil(ofactor);
   vec2 diff = ofactor/intfactor;
   float scan = diff.y;
   texcoord = Overscan(texcoord*(SourceSize.xy/InputSize.xy), scan, scan)*InputSize.xy/SourceSize.xy;

   vec2 OGL2Pos = gl_FragCoord.xy*1.0001;
   if (TATE == 1.0) OGL2Pos = vec2(OGL2Pos.y,OGL2Pos.x);
   
   vec3 res = COMPAT_TEXTURE(Source, texcoord).rgb;
   vec3 lumweight = vec3 (0.2126,0.7152,0.0722);
   float lum = dot(res, lumweight);

   if      (LINES == 5.0){res *= scanline5(OGL2Pos.y,lum);}
   else if (LINES == 4.0){res *= scanline4(OGL2Pos.y,lum);}
   else if (LINES == 3.0){res *= scanline3(OGL2Pos.y,lum);}
   else if (LINES == 2.0){res *= scanline2(OGL2Pos.y,lum);}

   FragColor = vec4(res,1.0);
}
#endif
