
///////////////
//	TV-out tweaks
//	Author: aliaspider - aliaspider@gmail.com
//	License: GPLv3
////////////////////////////////////////////////////////


// this shader is meant to be used when running
// an emulator on a real CRT-TV @240p or @480i
////////////////////////////////////////////////////////
// Basic settings:

// signal resolution
// higher = sharper
#pragma parameter TVOUT_RESOLUTION "TVOut Signal Resolution" 256.0 0.0 1024.0 32.0 // default, minimum, maximum, optional step

// simulate a composite connection instead of RGB
#pragma parameter TVOUT_COMPOSITE_CONNECTION "TVOut Composite Enable" 0.0 0.0 1.0 1.0

// use TV video color range (16-235)
// instead of PC full range (0-255)
#pragma parameter TVOUT_TV_COLOR_LEVELS "TVOut TV Color Levels Enable" 0.0 0.0 1.0 1.0
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
// Advanced settings:
//
// these values will be used instead
// if COMPOSITE_CONNECTION is defined
// to simulate different signal resolutions(bandwidth)
// for luma (Y) and chroma ( I and Q )
// this is just an approximation
// and will only simulate the low bandwidth anspect of
// composite signal, not the crosstalk between luma and chroma
// Y = 4MHz I=1.3MHz Q=0.4MHz
#pragma parameter TVOUT_RESOLUTION_Y "TVOut Luma (Y) Resolution" 256.0 0.0 1024.0 32.0
#pragma parameter TVOUT_RESOLUTION_I "TVOut Chroma (I) Resolution" 83.2 0.0 256.0 8.0
#pragma parameter TVOUT_RESOLUTION_Q "TVOut Chroma (Q) Resolution" 25.6 0.0 256.0 8.0

// formula is MHz=resolution*15750Hz
// 15750Hz being the horizontal Frequency of NTSC
// (=262.5*60Hz)
////////////////////////////////////////////////////////

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

vec4 _oPosition1;
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
vec4 _oColor;
vec2 _otexCoord;
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    _oPosition1 = gl_Position;
    _oColor = COLOR;
    _otexCoord = TexCoord.xy;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
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

#ifdef PARAMETER_UNIFORM // If the shader implementation understands #pragma parameters, this is defined.
uniform COMPAT_PRECISION float TVOUT_RESOLUTION;
uniform COMPAT_PRECISION float TVOUT_COMPOSITE_CONNECTION;
uniform COMPAT_PRECISION float TVOUT_TV_COLOR_LEVELS;
uniform COMPAT_PRECISION float TVOUT_RESOLUTION_Y;
uniform COMPAT_PRECISION float TVOUT_RESOLUTION_I;
uniform COMPAT_PRECISION float TVOUT_RESOLUTION_Q;
#else
// Fallbacks if parameters are not supported.
#define TVOUT_RESOLUTION 256.0 // Default
#define TVOUT_COMPOSITE_CONNECTION 0
#define TVOUT_TV_COLOR_LEVELS 0
#define TVOUT_RESOLUTION_Y 256.0
#define TVOUT_RESOLUTION_I 83.2
#define TVOUT_RESOLUTION_Q 25.6
#endif

struct output_dummy {
    vec4 _color;
};

#define pi			3.14159265358
#define a(x) abs(x)
#define d(x,b) (pi*b*min(a(x)+0.5,1.0/b))
#define e(x,b) (pi*b*min(max(a(x)-0.5,-1.0/b),1.0/b))
#define STU(x,b) ((d(x,b)+sin(d(x,b))-e(x,b)-sin(e(x,b)))/(2.0*pi))
//#define X(i) (offset-(i))
#define L(C) clamp((C -16.5/ 256.0)*256.0/(236.0-16.0),0.0,1.0)
#define LCHR(C) clamp((C -16.5/ 256.0)*256.0/(240.0-16.0),0.0,1.0)

vec3 LEVELS(vec3 c0)
{
   if (TVOUT_TV_COLOR_LEVELS > 0.5)
   {
      if (TVOUT_COMPOSITE_CONNECTION > 0.5)
         return vec3(L(c0.x),LCHR(c0.y),LCHR(c0.z));
      else
         return L(c0);
   }
   else
      return c0;
}

#define GETC(c) \
   if (TVOUT_COMPOSITE_CONNECTION > 0.5) \
      c = (LEVELS(COMPAT_TEXTURE(Texture, vec2(TEX0.x - X*oneT,TEX0.y)).xyz) * RGB_to_YIQ); \
   else \
      c = (LEVELS(COMPAT_TEXTURE(Texture, vec2(TEX0.x - X*oneT,TEX0.y)).xyz))

#define VAL(tempColor) \
   if (TVOUT_COMPOSITE_CONNECTION > 0.5) \
      tempColor += vec3((c.x*STU(X,(TVOUT_RESOLUTION_Y*oneI))),(c.y*STU(X,(TVOUT_RESOLUTION_I*oneI))),(c.z*STU(X,(TVOUT_RESOLUTION_Q*oneI)))); \
   else \
      tempColor += (c*STU(X,(TVOUT_RESOLUTION*oneI)))


uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

void main()
{
mat3 RGB_to_YIQ = mat3(0.299,0.587,0.114,
		 0.595716,-0.274453,-0.321263,
		 0.211456,-0.522591, 0.311135);

mat3 YIQ_to_RGB = mat3(1.0,0.9563,0.6210,
		 1.0,-0.2721,-0.6474,
		 1.0,-1.1070, 1.7046);

vec3 tempColor=vec3(0.0,0.0,0.0);
float	offset	= fract((TEX0.x * TextureSize.x) - 0.5);
   float oneT=1.0/TextureSize.x;
   float oneI=1.0/InputSize.x;

   float X;
   vec3 c;

   X = (offset-(-1.0));//X(-1.0);
   GETC(c);
   VAL(tempColor);

   X = (offset-(0.0));//X(0.0);
   GETC(c);
   VAL(tempColor);

   X = (offset-(1.0));//X(1.0);
   GETC(c);
   VAL(tempColor);

   X = (offset-(2.0));//X(2.0);
   GETC(c);
   VAL(tempColor);

   if (TVOUT_COMPOSITE_CONNECTION > 0.5)
      tempColor= tempColor * YIQ_to_RGB;

    output_dummy _OUT;
    _OUT._color = vec4(tempColor, 1.0);
    FragColor = _OUT._color;
    return;
}
#endif
