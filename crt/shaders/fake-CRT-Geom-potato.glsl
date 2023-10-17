// Simple scanlines and mask effect by DariusG
// written on an old netbook with 9 gflops
// and runs 60-65 fps on 720p

#pragma parameter SEVTWO "Scanline Size" 2.0 1.0 2.0 1.0

#define pi 3.1415926

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
COMPAT_VARYING float fragpos;
COMPAT_VARYING float scanpos;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION float SEVTWO;

// compatibility #defines
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    fragpos = TEX0.x*OutputSize.x*TextureSize.x/InputSize.x*pi;
	float y = TEX0.y*TextureSize.y-0.25;
	scanpos = y*pi*SEVTWO;
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
COMPAT_VARYING float fragpos;
COMPAT_VARYING float scanpos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SCANLINE_BASE_BRIGHTNESS;

#else
#define SCANLINE_BASE_BRIGHTNESS 0.30

#endif

void main()
{
	float y = TEX0.y*SourceSize.y;
	float centr = (floor(y)+0.5)/SourceSize.y;
    float ycoord = mix(centr, vTexCoord.y,0.5); 
    vec3 res = COMPAT_TEXTURE(Source, vec2(vTexCoord.x, ycoord)).rgb;
	vec3 origin = res;
	float lum = dot(vec3(0.2), res);
	
     res *= 0.5*sin(scanpos)+0.5 ; 
     res *= 0.15*sin(fragpos)+0.85;
	 res = mix(res, origin, lum);
	 res *= mix(1.35,1.0,lum);
    FragColor = vec4(res,1.0);
} 
#endif
