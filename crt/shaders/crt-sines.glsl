// A fast shader using sines and some tricks in the book
// by DariusG @2023

///////////////////////  Runtime Parameters  ///////////////////////
#pragma parameter SCANLINE1 "Scanline Brightness Dark" 0.3 0.0 1.0 0.05
#pragma parameter SCANLINE2 "Scanline Brightness Bright" 0.5 0.0 1.0 0.05
#pragma parameter INTERLACE "Interlace Mode" 1.0 0.0 1.0 1.0
#pragma parameter SCALE "Scanlines downscale"  1.0 1.0 4.0 1.0
#pragma parameter MSK1 "   Mask Brightness Dark" 0.4 0.0 1.0 0.05
#pragma parameter MSK2 "   Mask Brightness Bright" 0.7 0.0 1.0 0.05
#pragma parameter MSK_SIZE "   Mask Size" 1.0 0.25 4.0 0.25
#pragma parameter fade "   Mask/Scanlines Fade" 0.2 0.0 1.0 0.05
#pragma parameter BOOST "Bright Colors Boost" 1.06 1.0 1.5 0.02
#pragma parameter PRESERVE "Protect Bright Colors" 0.6 0.0 1.0 0.01
#pragma parameter WP "Color Temperature shift" 0.04 -0.25 0.25 0.01
#pragma parameter GAMMA "Gamma Adjust" 1.2 0.0 1.5 0.01
#pragma parameter sat "Saturation" 1.1 0.0 2.0 0.05

#define pi  3.141592654

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
COMPAT_VARYING vec2 omega;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION float SCALE;
uniform COMPAT_PRECISION float MSK_SIZE;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    omega = vec2(pi * OutputSize.x/MSK_SIZE, pi * SourceSize.y/SCALE);
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
COMPAT_VARYING vec2 omega;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SCANLINE1;
uniform COMPAT_PRECISION float SCANLINE2;
uniform COMPAT_PRECISION float BOOST;
uniform COMPAT_PRECISION float MSK1;
uniform COMPAT_PRECISION float MSK2;
uniform COMPAT_PRECISION float WP;
uniform COMPAT_PRECISION float GAMMA;
uniform COMPAT_PRECISION float PRESERVE;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float INTERLACE;
uniform COMPAT_PRECISION float fade;
#else
#define SCANLINE1 0.3
#define SCANLINE1 0.6
#define MSK1 0.4
#define MSK2 0.7
#define BOOST 1.0
#define WP 0.0
#define PRESERVE 0.9
#define GAMMA 0.8
#define sat 1.0
#define INTERLACE 1.0
#define fade 0.8
#endif



void main()
{

   // HERMITE FILTER 
   vec2 ps = SourceSize.zw;
   vec2 dx = vec2(ps.x, 0.0);
   vec2 dy = vec2(0.0, ps.y); 
   vec2 tc = (floor(vTexCoord.xy * SourceSize.xy) + vec2(0.49999, 0.49999)) / SourceSize.xy;  
   vec2 fp = fract(vTexCoord.xy * SourceSize.xy);
   
   vec3 c10 = COMPAT_TEXTURE(Source, tc -       dx).xyz;
   vec3 c11 = COMPAT_TEXTURE(Source, tc           ).xyz;
   vec3 c12 = COMPAT_TEXTURE(Source, tc +       dx).xyz;
   vec3 c13 = COMPAT_TEXTURE(Source, tc + 2.0 * dx).xyz;
    
   vec4 lobes = vec4(fp.x*fp.x*fp.x, fp.x*fp.x, fp.x, 1.0);
//hermite cubic filter
   vec4 InvX = vec4(0.0);
    InvX.x = dot(vec4(  0.0, 0.0,  0.0, 0.0), lobes);
    InvX.y = dot(vec4(  2.0,-3.0,  0.0, 1.0), lobes);
    InvX.z = dot(vec4( -2.0, 3.0,  0.0, 0.0), lobes);
    InvX.w = dot(vec4(  0.0, 0.0,  0.0, 0.0), lobes);
    
    vec3  res = InvX.x*c10.xyz;
          res+= InvX.y*c11.xyz;
          res+= InvX.z*c12.xyz;
          res+= InvX.w*c13.xyz;

    /////////////////////
    vec3 lumweight=vec3(0.3,0.6,0.1);
    float lum = dot(res,lumweight);
    //FAKE GAMMA
         res *= mix(GAMMA, 1.0, lum);
    //APPLY MASK 
         float MSK = mix(MSK1,MSK2,lum);       
         float mask = mix((1.0-MSK)*(sin(vTexCoord.x*omega.x*pi))+MSK, 1.0, lum*PRESERVE);

         float scan = 1.0;
         float SCANLINE = mix(SCANLINE1,SCANLINE2,lum);
    //INTERLACING MODE FIX SCANLINES
    if (INTERLACE > 0.0 && InputSize.y > 400.0 ) scan; else
         scan= (1.0 - SCANLINE)*abs(sin(vTexCoord.y* omega.y)) + SCANLINE+lum*0.1;
         res *=mix(scan*mask, scan, dot(res, vec3(fade)));
    //BRIGHT BOOST
         res *= mix(1.0,BOOST,lum);
    //CHEAP TEMPERATURE CONTROL     
         res *= vec3(1.0+WP,1.0,1.0-WP);
    
    //FAST SATURATION CONTROL
        float gray = lum;
        vec3 graycolour = vec3(gray);
        res = vec3(mix(graycolour,res,sat));

    FragColor = vec4(res,1.0);
}
#endif
