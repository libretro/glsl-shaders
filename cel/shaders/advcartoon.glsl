// Advanced Cartoon shader I and II
// by guest(r) (guest.r@gmail.com)
// license: GNU-GPL

#pragma parameter border "Toon Border Thickness" 1.0 0.0 4.0 0.5
#pragma parameter mute_colors "Toon Mute Colors" 0.0 0.0 1.0 1.0

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
COMPAT_VARYING vec2 Coord_0;
COMPAT_VARYING vec2 Coord_1;
COMPAT_VARYING vec2 Coord_2;
COMPAT_VARYING vec2 Coord_3;
COMPAT_VARYING vec2 Coord_4;
COMPAT_VARYING vec2 Coord_5;
COMPAT_VARYING vec2 Coord_6;
COMPAT_VARYING vec2 Coord_7;
COMPAT_VARYING vec2 Coord_8;


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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float border, mute_colors;
#else
#define border 1.0
#define mute_colors 0.0
#endif

vec2 OGL2Param = vec2(border, border);

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy * 1.0001;
    
   float x = (SourceSize.z / 8.0)*OGL2Param.x;
   float y = (SourceSize.w / 8.0)*OGL2Param.y;
   vec2 dg1 = vec2( x,y);
   vec2 dg2 = vec2(-x,y);
   vec2 dx  = vec2(x,0.0);
   vec2 dy  = vec2(0.0,y);
   Coord_0.xy = TEX0.xy;
   Coord_1.xy = TEX0.xy - dy;
   Coord_2.xy = TEX0.xy + dy;
   Coord_3.xy = TEX0.xy - dx;
   Coord_4.xy = TEX0.xy + dx;
   Coord_5.xy = TEX0.xy - dg1;
   Coord_6.xy = TEX0.xy + dg1;
   Coord_7.xy = TEX0.xy - dg2;
   Coord_8.xy = TEX0.xy + dg2;
}

#elif defined(FRAGMENT)

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 Coord_0;
COMPAT_VARYING vec2 Coord_1;
COMPAT_VARYING vec2 Coord_2;
COMPAT_VARYING vec2 Coord_3;
COMPAT_VARYING vec2 Coord_4;
COMPAT_VARYING vec2 Coord_5;
COMPAT_VARYING vec2 Coord_6;
COMPAT_VARYING vec2 Coord_7;
COMPAT_VARYING vec2 Coord_8;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float border, mute_colors;
#else
#define border 1.0
#define mute_colors 0.0
#endif

const float bb = 0.5; // effects black border sensitivity

void main()
{
	vec3 c00 = texture(Source, Coord_5.xy).xyz; 
	vec3 c10 = texture(Source, Coord_1.xy).xyz; 
	vec3 c20 = texture(Source, Coord_8.xy).xyz; 
	vec3 c01 = texture(Source, Coord_3.xy).xyz; 
	vec3 c11 = texture(Source, Coord_0.xy).xyz; 
	vec3 c21 = texture(Source, Coord_4.xy).xyz; 
	vec3 c02 = texture(Source, Coord_7.xy).xyz; 
	vec3 c12 = texture(Source, Coord_2.xy).xyz; 
	vec3 c22 = texture(Source, Coord_6.xy).xyz; 
	vec3 dt = vec3(1.0,1.0,1.0); 

	float d1=dot(abs(c00-c22),dt);
	float d2=dot(abs(c20-c02),dt);
	float hl=dot(abs(c01-c21),dt);
	float vl=dot(abs(c10-c12),dt);
	float d = bb*(d1+d2+hl+vl)/(dot(c11,dt)+0.15);
   
   float lc, f;
   vec3 frct;
   
   if(mute_colors < 0.5)
   {
   	lc = 4.0*length(c11);
      f = fract(lc); f*=f;
      lc = 0.25*(floor(lc) + f*f)+0.05;
      c11 = 4.0*normalize(c11); 
      vec3 frct = fract(c11); frct*=frct;
      c11 = floor(c11)+ 0.05*dt + frct*frct;
      FragColor.xyz = 0.25*lc*(1.1-d*sqrt(d))*c11;
      return;
   }
   else
   {
      lc = 5.0*length(c11); 
      lc = 0.2*(floor(lc) + pow(fract(lc),4.0));
      c11 = 4.0*normalize(c11); 
      frct = fract(c11); frct*=frct;
      c11 = floor(c11) + frct*frct;
      c11 = 0.25*(c11)*lc; lc*=0.577;
      c11 = mix(c11,lc*dt,lc);
      FragColor.xyz = (1.1-pow(d,1.5))*c11;
   }
} 
#endif
