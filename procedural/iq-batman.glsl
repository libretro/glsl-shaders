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

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// The batman logo, sort of copied from random image I found online


#define ANIMATE

//-----------------------------------------------------------------------

float ellipse( in vec2 p, in float x, in float y, in float dirx, in float diry, in float radx, in float rady )
{
	vec2  q = p - vec2(x,y);
	float u = dot( q, vec2(dirx,diry) );
	float v = dot( q, vec2(diry,dirx)*vec2(-1.0,1.0) );
	return dot(vec2(u*u,v*v),vec2(1.0/(radx*radx),1.0/(rady*rady)))-1.0;
}

float box( in vec2 p, in float x, in float y, in float dirx, in float diry, in float radx, in float rady )
{
	vec2  q = p - vec2(x,y);
	float u = dot( q, vec2(dirx,diry) );
	float v = dot( q, vec2(diry,dirx)*vec2(-1.0,1.0) );
	vec2  d = abs(vec2(u,v)) - vec2(radx,rady);
	return max(d.x,d.y);
}

float fillEllipse( in vec2 p, in float x, in float y, in float dirx, in float diry, in float radx, in float rady )
{
	float d = ellipse(p,x,y,dirx,diry,radx,rady);
    float w = fwidth(d);
	return 1.0 - smoothstep( -w, w, d);
}

float strokeEllipse( in vec2 p, in float x, in float y, in float dirx, in float diry, in float radx, in float rady, in float thickness )
{
	float d = abs(ellipse(p,x,y,dirx,diry,radx,rady)) - thickness;
    float w = fwidth(d);
	return 1.0 - smoothstep( -w, w, d);
}


float fillRectangle( in vec2 p, in float x, in float y, in float dirx, in float diry, in float radx, in float rady )
{
	float d = box(p,x,y,dirx,diry,radx,rady);
    float w = fwidth(d);
	return 1.0 - smoothstep( -w, w, d);
}

//-----------------------------------------------------------------------

// batmap logo
float logo( vec2 p )
{
	p *= 0.66;
	p.x = abs(p.x);
	
    vec2 q = p;	
	#ifdef ANIMATE
    q.x *= 1.0 + 0.05*q.x*sin(2.0*iGlobalTime+0.0);
    q.y *= 1.0 + 0.05*q.x*sin(2.0*iGlobalTime+1.3);
    #endif	
	
	
	float f = 1.0;
	
	f = mix( f, 0.0,     fillEllipse(   q, 0.000, 0.000,  1.0, 0.0, 0.800, 0.444) );
	f = mix( f, 1.0,     fillEllipse(   q, 0.260, 0.300,  1.0, 0.0, 0.150, 0.167) );
	f = mix( f, 1.0,     fillRectangle( p, 0.180, 0.400,  1.0, 0.0, 0.070, 0.100) );
	f = mix( f, 1.0,     fillRectangle( p, 0.000, 0.400,  1.0, 0.0, 0.040, 0.040) );
	f = mix( f, 1.0,     fillRectangle( p, 0.036, 0.448,  0.6, 0.8, 0.065, 0.057) );
	f = mix( f, 1.0,     fillEllipse(   q, 0.200,-0.450,  1.0, 0.0, 0.200, 0.333) );
	f = mix( f, 1.0,     fillEllipse(   q, 0.400,-0.350, -0.8, 0.6, 0.150, 0.278) );
    f = mix( f, 0.0, 1.0-fillEllipse(   p, 0.000, 0.000,  1.0, 0.0, 1.000, 0.556) );
	f = mix( f, 0.0,     strokeEllipse( p, 0.000, 0.000,  1.0, 0.0, 0.950, 0.528, 0.06) );

	return f;
}

// blurred batmap logo
float slogo( in vec2 p )
{
	float s = 0.0;
	for( int j=0; j<3; j++ )
	for( int i=0; i<3; i++ )
		s += logo( p + 3.5*vec2(i-1,j-1)/iResolution.y );
    s /= 9.0;
	return s;
}
//-----------------------------------------------------------------------

float hash( float n ) { return fract(sin(n)*43758.5453); }

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);

}

float fbm( vec2 p )
{
    const mat2 m = mat2( 0.8, 0.6, -0.6, 0.8 );

	float f = 0.0;
    f += 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

//-----------------------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (-iResolution.xy+2.0*fragCoord.xy)/iResolution.y;

    // batman logo black and white	
	float f = logo( p );
	
    // make black and yellow	
    vec3 col = vec3( f, f*0.8, 0.1 );

	// add texture
	col += f*3.0*smoothstep( 0.53, 0.9, fbm( 0.8*p.yx + 9.0 ) );
	col *= 0.7 + 0.3*smoothstep( 0.2, 0.8, fbm( 4.0*p  + fbm(32.0*p) ) );

    // smooth	 
	float s = slogo( p );
	
    // calc normal	
	float a = slogo( p );
	float b = slogo( p + vec2(2.0,0.0)/iResolution.y );
	float c = slogo( p + vec2(0.0,2.0)/iResolution.y );
	vec2 nor = normalize( vec2(b-a, c-a) );
	

    // add specular	borders
	col += 0.3*pow(clamp(dot(nor,normalize(vec2(-1.0,1.0))),0.0,1.0),2.0);
	col += 0.6*pow(clamp(dot(nor,normalize(vec2(-1.0,1.0))),0.0,1.0),8.0);
	// specular highlight
	col += 0.8*(1.0-f)*exp(-4.0*length(p-vec2(-0.3,0.3)));
	
	fragColor = vec4(col,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
