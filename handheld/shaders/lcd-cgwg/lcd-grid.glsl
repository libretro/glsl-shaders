// Parameter lines go here:
#pragma parameter GRID_STRENGTH "LCD Grid Strength" 0.05 0.0 1.0 0.01
#pragma parameter gamma "LCD Input Gamma" 2.2 1.0 5.0 0.1

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
#define COMPAT_PRECISION highp
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
#define COMPAT_PRECISION highp
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
uniform COMPAT_PRECISION float GRID_STRENGTH;
uniform COMPAT_PRECISION float gamma;
#else
#define GRID_STRENGTH 0.05
#define gamma 2.2
#endif

float intsmear_func(float z)
{
  float z2 = z*z;
  float z4 = z2*z2;
  float z8 = z4*z4;
  return z - 2.0/3.0*z*z2 - 1.0/5.0*z*z4 + 4.0/7.0*z*z2*z4 - 1.0/9.0*z*z8
    - 2.0/11.0*z*z2*z8 + 1.0/13.0*z*z4*z8;
}

float intsmear(float x, float dx)
{
  const float d = 1.5;
  float zl = clamp((x-dx)/d,-1.0,1.0);
  float zh = clamp((x+dx)/d,-1.0,1.0);
  return d * ( intsmear_func(zh) - intsmear_func(zl) )/(2.0*dx);
}

#define round(x) floor( (x) + 0.5 )
#define TEX2D(c) pow(COMPAT_TEXTURE(Source, (c)), vec4(gamma))

void main()
{
  vec2 texelSize = 1.0 / TextureSize.xy;
  vec2 subtexelSize = texelSize / vec2(3.0,1.0);
  vec2 range;
  range = InputSize.xy / (OutputSize.xy * TextureSize.xy);
  
  float left   = vTexCoord.x - texelSize.x*0.4999;
  float top    = vTexCoord.y + range.y;
  float right  = vTexCoord.x + texelSize.x*0.4999;
  float bottom = vTexCoord.y - range.y;
  
  vec4 lcol, rcol;
  float subpix = mod(vTexCoord.x/subtexelSize.x+1.5,3.0);
  float rsubpix = range.x/subtexelSize.x;
  lcol = vec4(intsmear(subpix+1.0,rsubpix),intsmear(subpix    ,rsubpix),
	          intsmear(subpix-1.0,rsubpix),0.0);
  rcol = vec4(intsmear(subpix-2.0,rsubpix),intsmear(subpix-3.0,rsubpix),
	          intsmear(subpix-4.0,rsubpix),0.0);
			  
  vec4 topLeftColor     = TEX2D((floor(vec2(left, top)     / texelSize) + 0.4999) * texelSize) * lcol;
  vec4 bottomRightColor = TEX2D((floor(vec2(right, bottom) / texelSize) + 0.4999) * texelSize) * rcol;
  vec4 bottomLeftColor  = TEX2D((floor(vec2(left, bottom)  / texelSize) + 0.4999) * texelSize) * lcol;
  vec4 topRightColor    = TEX2D((floor(vec2(right, top)    / texelSize) + 0.4999) * texelSize) * rcol;
  
  vec2 border = round(vTexCoord.st/subtexelSize);
  vec2 bordert = clamp((border+vec2(0.0,+GRID_STRENGTH)) * subtexelSize,
		       vec2(left, bottom), vec2(right, top));
  vec2 borderb = clamp((border+vec2(0.0,-GRID_STRENGTH)) * subtexelSize,
		       vec2(left, bottom), vec2(right, top));
  float totalArea = 2.0 * range.y;  

   vec4 averageColor;
  averageColor  = ((top - bordert.y)    / totalArea) * topLeftColor;
  averageColor += ((borderb.y - bottom) / totalArea) * bottomRightColor;
  averageColor += ((borderb.y - bottom) / totalArea) * bottomLeftColor;
  averageColor += ((top - bordert.y)    / totalArea) * topRightColor;
  
   FragColor = pow(averageColor,vec4(1.0/gamma));
#ifdef GL_ES
   // fix broken clamp behavior used in console-border shaders
   if (vTexCoord.x > 0.0007 && vTexCoord.x < 0.9999 && vTexCoord.y > 0.0007 && vTexCoord.y < 0.9999)
      FragColor = FragColor;
   else
      FragColor = vec4(0.0);
#endif
} 
#endif
