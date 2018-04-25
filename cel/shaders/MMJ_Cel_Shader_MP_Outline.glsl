/*
----------------------------------------------------------------
MMJ's Cel Shader v2.01 - Multi-Pass 
----------------------------------------------------------------
Parameters:
-----------
Outline Weight = Adjusts darkness of the outlines.

At lower internal resolutions, smaller values work better to
reduce the appearance of lines around individual areas of some
textures. At higher internal resolutions, setting both a higher 
outline weight value plus increased blur factors will work 
together to thicken the appearance of the lines.
----------------------------------------------------------------
*/

#pragma parameter OutlineWeight "Outline Weight" 1.0 0.0 10.0 0.1


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
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;
COMPAT_VARYING vec4 TEX2;
COMPAT_VARYING vec4 TEX3;
COMPAT_VARYING vec4 TEX4;
COMPAT_VARYING vec4 TEX5;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	gl_Position = MVPMatrix * VertexCoord;
	
  TEX0 = TexCoord.xyxy;
	
  vec4 offset;

  offset.xy = -(offset.zw = vec2(SourceSize.z, 0.0));
  TEX1 = TEX0 + offset;
  TEX5 = TEX1 + offset;

  offset.xy = -(offset.zw = vec2(0.0, SourceSize.w));
  TEX2 = TEX0 + offset;
  TEX3 = TEX1 + offset;
  TEX4 = TEX2 + offset;
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

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;
COMPAT_VARYING vec4 TEX2;
COMPAT_VARYING vec4 TEX3;
COMPAT_VARYING vec4 TEX4;
COMPAT_VARYING vec4 TEX5;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float OutlineWeight;
#else
#define OutlineWeight 1.0
#endif


void main()
{
	vec3 c00 = COMPAT_TEXTURE(Source, TEX3.xy).rgb;
	vec3 c01 = COMPAT_TEXTURE(Source, TEX2.xy).rgb;
	vec3 c02 = COMPAT_TEXTURE(Source, TEX3.zy).rgb;
	vec3 c03 = COMPAT_TEXTURE(Source, TEX1.xy).rgb;
	vec3 c04 = COMPAT_TEXTURE(Source, TEX0.xy).rgb;
	vec3 c05 = COMPAT_TEXTURE(Source, TEX1.zw).rgb;
	vec3 c06 = COMPAT_TEXTURE(Source, TEX3.xw).rgb;
	vec3 c07 = COMPAT_TEXTURE(Source, TEX2.zw).rgb;
	vec3 c08 = COMPAT_TEXTURE(Source, TEX3.zw).rgb;	
  vec3 c09 = COMPAT_TEXTURE(Source, TEX4.xy).rgb;
  vec3 c10 = COMPAT_TEXTURE(Source, TEX4.zw).rgb;
  vec3 c11 = COMPAT_TEXTURE(Source, TEX5.xy).rgb;
  vec3 c12 = COMPAT_TEXTURE(Source, TEX5.zw).rgb;

  vec3 cNew = (c00 + c01 + c02 + c03 + c04 + c05 + c06 + c07 + c08 + c09 + c10 + c11 + c12) / 13.0;
  
	vec3 o = vec3(1.0), h = vec3(0.05), hz = h; 
	float k = 0.005, kz = 0.007, i = 0.0;

	vec3 cz = (cNew + h) / (dot(o, cNew) + k);

	hz = (cz - ((c00 + h) / (dot(o, c00) + k))); i  = kz / (dot(hz, hz) + kz);
	hz = (cz - ((c01 + h) / (dot(o, c01) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c02 + h) / (dot(o, c02) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c03 + h) / (dot(o, c03) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c05 + h) / (dot(o, c05) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c06 + h) / (dot(o, c06) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c07 + h) / (dot(o, c07) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c08 + h) / (dot(o, c08) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c09 + h) / (dot(o, c09) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c10 + h) / (dot(o, c10) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c11 + h) / (dot(o, c11) + k))); i += kz / (dot(hz, hz) + kz);
	hz = (cz - ((c12 + h) / (dot(o, c12) + k))); i += kz / (dot(hz, hz) + kz);

	i /= 12.0; 
	i = pow(i, OutlineWeight);

	FragColor.rgb = vec3(i);
}
#endif