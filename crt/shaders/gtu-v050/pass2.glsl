////////////////////////////////////////////////////////
// GTU version 0.50
// Author: aliaspider - aliaspider@gmail.com
// License: GPLv3
////////////////////////////////////////////////////////

// Parameter lines go here:
#pragma parameter compositeConnection "Composite Connection Enable" 0.0 0.0 1.0 1.0
#pragma parameter signalResolution "Signal Resolution Y" 256.0 16.0 1024.0 16.0
#pragma parameter signalResolutionI "Signal Resolution I" 83.0 1.0 350.0 2.0
#pragma parameter signalResolutionQ "Signal Resolution Q" 25.0 1.0 350.0 2.0

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
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
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float compositeConnection;
uniform COMPAT_PRECISION float signalResolution;
uniform COMPAT_PRECISION float signalResolutionI;
uniform COMPAT_PRECISION float signalResolutionQ;
#else
#define compositeConnection 0.0
#define RETRO_PIXEL_SIZE 256.0
#define RETRO_PIXEL_SIZE 83.0
#define RETRO_PIXEL_SIZE 25.0
#endif

#define YIQ_to_RGB 	mat3( 1.0   , 1.0      , 1.0      ,	0.9563   , -0.2721   , -1.1070   ,		0.6210   , -0.6474   , 1.7046   )
#define pi        3.14159265358
#define a(x) abs(x)
#define d(x,b) (pi*b*min(a(x)+0.5,1.0/b))
#define e(x,b) (pi*b*min(max(a(x)-0.5,-1.0/b),1.0/b))
#define STU(x,b) ((d(x,b)+sin(d(x,b))-e(x,b)-sin(e(x,b)))/(2.0*pi))
//#define X(i) (offset-(i))
#define GETC (COMPAT_TEXTURE(Source, vec2(vTexCoord.x - X * SourceSize.z, vTexCoord.y)).rgb)

#define VAL_composite vec3((c.x*STU(X,(signalResolution  / InputSize.x))),(c.y*STU(X,(signalResolutionI / InputSize.x))),(c.z*STU(X,(signalResolutionQ / InputSize.x))))
#define VAL (c*STU(X,(signalResolution / InputSize.x)))

#define PROCESS(i) X=(i);c=GETC;tempColor+=VAL;
#define PROCESS_composite(i) X=(i);c=GETC;tempColor+=VAL_composite;

void main()
{
	float offset   = fract((vTexCoord.x * SourceSize.x) - 0.5);
	vec3	tempColor = vec3(0.0);
	float	X;
	vec3	c;
	float range;
	if (compositeConnection > 0.0)
      range=ceil(0.5+InputSize.x/min(min(signalResolution,signalResolutionI),signalResolutionQ));
   else
      range=ceil(0.5+InputSize.x/signalResolution);
	  
	float i;
   if(compositeConnection > 0.0){
      for (i=-range;i<range+2.0;i++){
         PROCESS_composite((offset-(i)))
      }
   }
   else{
      for (i=-range;i<range+2.0;i++){
         PROCESS((offset-(i)))
      }
   }
   if(compositeConnection > 0.0)
      tempColor=clamp(tempColor * YIQ_to_RGB,0.0,1.0);
   else
      tempColor=clamp(tempColor,0.0,1.0);

   // tempColor=clamp(tempColor,0.0,1.0);
   FragColor = vec4(tempColor, 1.0);

} 
#endif
