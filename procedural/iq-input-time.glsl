// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter RETRO_PIXEL_SIZE "Retro Pixel Size" 0.84 0.0 1.0 0.01
#pragma parameter FPS "Display Refresh Rate (Hz)" 60.0 50.0 240.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float RETRO_PIXEL_SIZE;
uniform COMPAT_PRECISION float FPS;
#else
#define RETRO_PIXEL_SIZE 0.84
#define FPS 60.0
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
float iGlobalTime = float(FrameCount)* 1.0 / FPS;
vec2 iResolution = OutputSize.xy;

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// See also:
//
// Input - Keyboard    : https://www.shadertoy.com/view/lsXGzf
// Input - Microphone  : https://www.shadertoy.com/view/llSGDh
// Input - Mouse       : https://www.shadertoy.com/view/Mss3zH
// Input - Sound       : https://www.shadertoy.com/view/Xds3Rr
// Input - SoundCloud  : https://www.shadertoy.com/view/MsdGzn
// Input - Time        : https://www.shadertoy.com/view/lsXGz8
// Input - TimeDelta   : https://www.shadertoy.com/view/lsKGWV
// Inout - 3D Texture  : https://www.shadertoy.com/view/4llcR4


float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
	vec2 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}

vec3 line( in vec3 buf, in vec2 a, in vec2 b, in vec2 p, in vec2 w, in vec4 col )
{
   float f = sdSegment( p, a, b );
   float g = fwidth(f)*w.y;
   return mix( buf, col.xyz, col.w*(1.0-smoothstep(w.x-g, w.x+g, f)) );
}

vec3 hash3( float n ) { return fract(sin(vec3(n,n+1.0,n+2.0))*43758.5453123); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // get time
    float mils = fract(iGlobalTime);
	float secs = mod( floor(iGlobalTime),        60.0 );
	float mins = mod( floor(iGlobalTime/60.0),   60.0 );
	float hors = mod( floor(iGlobalTime/3600.0), 24.0 );
    
    // enable this for subsecond resolution
    //secs += mils;

	vec2 uv = (2.0*fragCoord.xy-iResolution.xy)/min(iResolution.y,iResolution.x);

	float r = length( uv );
	float a = atan( uv.y, uv.x )+3.1415926;
    
	// background color
	vec3 nightColor = vec3( 0.2, 0.2, 0.2 ) + 0.1*uv.y;
	vec3 dayColor   = vec3( 0.5, 0.6, 0.7 ) + 0.2*uv.y;
	vec3 col = mix( nightColor, dayColor, smoothstep( 5.0, 7.0, hors ) - 
				                          smoothstep(19.0,21.0, hors ) );

    // inner watch body	
	col = mix( col, vec3(0.9-0.4*pow(r,4.0)), 1.0-smoothstep(0.94,0.95,r) );

    // 5 minute marks	
	float f = abs(2.0*fract(0.5+a*60.0/6.2831)-1.0);
	float g = 1.0-smoothstep( 0.0, 0.1, abs(2.0*fract(0.5+a*12.0/6.2831)-1.0) );
	float w = fwidth(f);
	f = 1.0 - smoothstep( 0.1*g+0.05-w, 0.1*g+0.05+w, f );
	f *= smoothstep( 0.85, 0.86, r+0.05*g ) - smoothstep( 0.94, 0.95, r );
	col = mix( col, vec3(0.0), f );

	// seconds hand
	vec2 dir;
	dir = vec2( sin(6.2831*secs/60.0), cos(6.2831*secs/60.0) );
    col = line( col, vec2(0.0), dir*0.9, uv+0.05, vec2(0.005,4.0), vec4(0.0,0.0,0.0,0.2) );
    col = line( col, vec2(0.0), dir*0.9, uv,      vec2(0.005,1.0), vec4(0.5,0.0,0.0,1.0) );

	// minutes hand
	dir = vec2( sin(6.2831*mins/60.0), cos(6.2831*mins/60.0) );
    col = line( col, vec2(0.0), dir*0.7, uv+0.05, vec2(0.015,4.0), vec4(0.0,0.0,0.0,0.2) );
    col = line( col, vec2(0.0), dir*0.7, uv,      vec2(0.015,1.0), vec4(0.0,0.0,0.0,1.0) );

    // hours hand
	dir = vec2( sin(6.2831*hors/12.0), cos(6.2831*hors/12.0) );
    col = line( col, vec2(0.0), dir*0.4, uv+0.05, vec2(0.015,4.0), vec4(0.0,0.0,0.0,0.2) );
    col = line( col, vec2(0.0), dir*0.4, uv,      vec2(0.015,1.0), vec4(0.0,0.0,0.0,1.0) );

    // center mini circle	
	col = mix( col, vec3(0.5), 1.0-smoothstep(0.050,0.055,r) );
	col = mix( col, vec3(0.0), 1.0-smoothstep(0.005,0.01,abs(r-0.055)) );

    // border of watch
	col = mix( col, vec3(0.0), 1.0-smoothstep(0.01,0.02,abs(r-0.95)) );

    // dithering    
    col += (1.0/255.0)*hash3(uv.x+13.0*uv.y);

	fragColor = vec4( col,1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
