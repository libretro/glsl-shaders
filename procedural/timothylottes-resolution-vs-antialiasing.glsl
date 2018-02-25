#version 120
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


// SHOWING RESOLUTION VS SAMPLES VS MOTION
//
// Warning full-screen on a slow machine is a likely TDR!!!!
// I'm too afraid to try it, so this is tuned to the standard 1920x1080 shadertoy view in a browser.
// Shader built and tested only on a laptop, probably fine on big desktop GPU.
//
// Each pair of rows has same number of shaded samples.
// Samples are shaded either to white or black.
// Top of pair is at full resolution.
// Bottom of pair is at 1/2 resolution (aka 1/4 area).
// Shows geometric aliasing in motion.
//
// Rows from top to bottom,
//
//  1x       at full resolution 
//  4xSGSSAA at 1/4 area in resolution 
//
//  2xSGSSAA at full resolution
//  8xSGSSAA at 1/4 area in resolution 
//
//  4xSGSSAA at full resolution
// 16xSGSSAA at 1/4 area in resolution 
//
//  8xSGSSAA at full resolution
// 32xSGSSAA at 1/4 area in resolution 
//
// 16xSGSSAA at full resolution
// 64xSGSSAA at 1/4 area in resolution 
//
// Since everything is exactly up/down this SGSSAA simplifies to sampling in a line...
// Resolve is a simple cubic filter which is larger than a pixel.
//
// Precision in motion = resolution * intensity steps as edge moves across pixel.
//
// For the same number of samples the lower resolution display 
// offers better motion precision but with compromized sharpness.
// The extra spatial precision for the lower resolution display
// is a product of being able to adjust sampling locations
// from exactly resolving detail in the rectangular grid, 
// to better resolving sub-pixel position.
// providing more effective intensity steps as a edge moves across a pixel.

// Types.
#define F1 float
#define F2 vec2
#define F3 vec3
#define F4 vec4
#define S1 int
#define S2 int2
#define S3 int3
#define S4 int4

// Controls.
#define BARS (1.0/6000.0)
#define THROW (16.0/1.0)
#define SPEED (1.0/4.0)

// Generates the source image.
F1 Src(F1 x){return fract(x*x*BARS)<0.5?0.0:1.0;}

// Convert from linear to sRGB.
F1 Srgb(F1 c){return(c<0.0031308?c*12.92:1.055*pow(c,0.41666)-0.055);}

// Filter as Cubic B-spline (x = distance from center).
// General Mitchell-Netravali filter,
//   http://www.cs.utexas.edu/users/fussell/courses/cs384g/lectures/mitchell/Mitchell.pdf
F1 Filter(F1 x){
  F1 b=1.0,c=0.0;
  if(abs(x)<1.0)return(1.0/6.0)*((12.0-9.0*b-6.0*c)*x*x*abs(x)+(-18.0+12.0*b+6.0*c)*x*x+(6.0-2.0*b));
  if(abs(x)<2.0)return(1.0/6.0)*((-b-6.0*c)*x*x*abs(x)+(6.0*b+30.0*c)*x*x+(-12.0*b-48.0*c)*abs(x)+(8.0*b+24.0*c));
  return 0.0;}

// Generates a swatch to test resolution and sample settings.
F1 Swatch(F1 x,F1 o,F1 res,S1 num) {
  // Filter sums.
  F1 rSum=0.0;
  F1 wSum=0.0;
  F1 rSum2=0.0;
  F1 wSum2=0.0;
  // Base and stride for sampling.
  F1 xBase=(floor(x/res)+(0.5/F1(num)))*res-(res*1.5);
  F1 xStride=res/F1(num);
  F1 xMid=(floor(x/res)+0.5)*res-(res*1.0);
  // Filtering.
  F1 xCenter=x+0.5;
  F1 xScale=1.0/res;
  F1 xScale2=1.0/res;
  F1 p,r,w;
  F1 r0,r1,r2;
  F1 p0,p1,p2;
  //    
  if(num==1){return Src((floor(x/res)+(0.5/F1(num)))*res+o);}
  //    
  if(num==2){
    p0=xMid;  
    for(S1 i=0;i<2*2;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r0=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p0-xCenter)*xScale2);rSum2+=r0*w;wSum2+=w;  
    p1=xMid;  
    for(S1 i=0;i<2*2;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r1=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p1-xCenter)*xScale2);rSum2+=r1*w;wSum2+=w;  
    p2=xMid;  
    for(S1 i=0;i<2*2;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r2=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p2-xCenter)*xScale2);rSum2+=r2*w;wSum2+=w;
    return rSum2/wSum2;}
  //
  if(num==4){
    p0=xMid;  
    for(S1 i=0;i<2*4;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r0=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p0-xCenter)*xScale2);rSum2+=r0*w;wSum2+=w;  
    p1=xMid;  
    for(S1 i=0;i<2*4;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r1=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p1-xCenter)*xScale2);rSum2+=r1*w;wSum2+=w;  
    p2=xMid;  
    for(S1 i=0;i<2*4;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r2=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p2-xCenter)*xScale2);rSum2+=r2*w;wSum2+=w;
    return rSum2/wSum2;}
  //
  if(num==8){
    p0=xMid;  
    for(S1 i=0;i<2*8;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r0=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p0-xCenter)*xScale2);rSum2+=r0*w;wSum2+=w;  
    p1=xMid;  
    for(S1 i=0;i<2*8;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r1=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p1-xCenter)*xScale2);rSum2+=r1*w;wSum2+=w;  
    p2=xMid;  
    for(S1 i=0;i<2*8;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r2=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p2-xCenter)*xScale2);rSum2+=r2*w;wSum2+=w;
    return rSum2/wSum2;}
  //
  if(num==16){
    p0=xMid;  
    for(S1 i=0;i<2*16;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r0=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p0-xCenter)*xScale2);rSum2+=r0*w;wSum2+=w;  
    p1=xMid;  
    for(S1 i=0;i<2*16;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r1=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p1-xCenter)*xScale2);rSum2+=r1*w;wSum2+=w;  
    p2=xMid;  
    for(S1 i=0;i<2*16;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r2=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p2-xCenter)*xScale2);rSum2+=r2*w;wSum2+=w;
    return rSum2/wSum2;}
  //
  if(num==32){
    p0=xMid;  
    for(S1 i=0;i<2*32;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r0=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p0-xCenter)*xScale2);rSum2+=r0*w;wSum2+=w;  
    p1=xMid;  
    for(S1 i=0;i<2*32;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r1=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p1-xCenter)*xScale2);rSum2+=r1*w;wSum2+=w;  
    p2=xMid;  
    for(S1 i=0;i<2*32;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r2=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p2-xCenter)*xScale2);rSum2+=r2*w;wSum2+=w;
    return rSum2/wSum2;}
  //
  if(num==64){
    p0=xMid;  
    for(S1 i=0;i<2*64;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r0=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p0-xCenter)*xScale2);rSum2+=r0*w;wSum2+=w;  
    p1=xMid;  
    for(S1 i=0;i<2*64;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r1=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p1-xCenter)*xScale2);rSum2+=r1*w;wSum2+=w;  
    p2=xMid;  
    for(S1 i=0;i<2*64;i++){p=xBase+F1(i)*xStride;r=Src(p+o);w=Filter(abs(p-xMid)*xScale);rSum+=r*w;wSum+=w;}
    r2=rSum/wSum;xBase+=res;xMid+=res;rSum=0.0;wSum=0.0;
    w=Filter(abs(p2-xCenter)*xScale2);rSum2+=r2*w;wSum2+=w;
    return rSum2/wSum2;}
  //
  return 0.0;}      

// Shader.
void mainImage(out F4 fragColor,in F2 fragCoord){ 
  F1 x=fragCoord.x;
  F1 y=1.0-fragCoord.y/iResolution.y;
  F1 o=sin(iGlobalTime*SPEED)*THROW;
  fragColor.g=0.0;  
  if((y>0.04)&&(y<0.09))     fragColor.g=Swatch(x,o,1.0,1);
  else if((y>0.11)&&(y<0.16))fragColor.g=Swatch(x,o,2.0,4);
  //
  else if((y>0.24)&&(y<0.29))fragColor.g=Swatch(x,o,1.0,2);
  else if((y>0.31)&&(y<0.36))fragColor.g=Swatch(x,o,2.0,8);
  //
  else if((y>0.44)&&(y<0.49))fragColor.g=Swatch(x,o,1.0,4);
  else if((y>0.51)&&(y<0.56))fragColor.g=Swatch(x,o,2.0,16);
  //
  else if((y>0.64)&&(y<0.69))fragColor.g=Swatch(x,o,1.0,8);
  else if((y>0.71)&&(y<0.76))fragColor.g=Swatch(x,o,2.0,32);
  //
  else if((y>0.84)&&(y<0.89))fragColor.g=Swatch(x,o,1.0,16);
  else if((y>0.91)&&(y<0.96))fragColor.g=Swatch(x,o,2.0,64);
  //        
  fragColor.g = Srgb(fragColor.g);
  fragColor.rgb = fragColor.ggg;
  fragColor.a = 0.0;
}    

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
