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

// Bokeh Parallax -  knarkowicz - 2017-04-12
// https://www.shadertoy.com/view/4s2yW1

// Feeling artsy

const float MATH_PI	= float( 3.14159265359 );

void Rotate( inout vec2 p, float a ) 
{
	p = cos( a ) * p + sin( a ) * vec2( p.y, -p.x );
}

float Circle( vec2 p, float r )
{
    return ( length( p / r ) - 1.0 ) * r;
}

float Rand( vec2 c )
{
	return fract( sin( dot( c.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 );
}

float saturate( float x )
{
	return clamp( x, 0.0, 1.0 );
}

void BokehLayer( inout vec3 color, vec2 p, vec3 c )   
{
    float wrap = 450.0;    
    if ( mod( floor( p.y / wrap + 0.5 ), 2.0 ) == 0.0 )
    {
        p.x += wrap * 0.5;
    }    
    
    vec2 p2 = mod( p + 0.5 * wrap, wrap ) - 0.5 * wrap;
    vec2 cell = floor( p / wrap + 0.5 );
    float cellR = Rand( cell );
        
    c *= fract( cellR * 3.33 + 3.33 );    
    float radius = mix( 30.0, 70.0, fract( cellR * 7.77 + 7.77 ) );
    p2.x *= mix( 0.9, 1.1, fract( cellR * 11.13 + 11.13 ) );
    p2.y *= mix( 0.9, 1.1, fract( cellR * 17.17 + 17.17 ) );
    
    float sdf = Circle( p2, radius );
    float circle = 1.0 - smoothstep( 0.0, 1.0, sdf * 0.04 );
    float glow	 = exp( -sdf * 0.025 ) * 0.3 * ( 1.0 - circle );
    color += c * ( circle + glow );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec2 p = ( 2.0 * fragCoord - iResolution.xy ) / iResolution.x * 1000.0;
    
    // background
	vec3 color = mix( vec3( 0.3, 0.1, 0.3 ), vec3( 0.1, 0.4, 0.5 ), dot( uv, vec2( 0.2, 0.7 ) ) );

    float time = iGlobalTime - 15.0;
    
    Rotate( p, 0.2 + time * 0.03 );
    BokehLayer( color, p + vec2( -50.0 * time +  0.0, 0.0  ), 3.0 * vec3( 0.4, 0.1, 0.2 ) );
	Rotate( p, 0.3 - time * 0.05 );
    BokehLayer( color, p + vec2( -70.0 * time + 33.0, -33.0 ), 3.5 * vec3( 0.6, 0.4, 0.2 ) );
	Rotate( p, 0.5 + time * 0.07 );
    BokehLayer( color, p + vec2( -60.0 * time + 55.0, 55.0 ), 3.0 * vec3( 0.4, 0.3, 0.2 ) );
    Rotate( p, 0.9 - time * 0.03 );
    BokehLayer( color, p + vec2( -25.0 * time + 77.0, 77.0 ), 3.0 * vec3( 0.4, 0.2, 0.1 ) );    
    Rotate( p, 0.0 + time * 0.05 );
    BokehLayer( color, p + vec2( -15.0 * time + 99.0, 99.0 ), 3.0 * vec3( 0.2, 0.0, 0.4 ) );     

	fragColor = vec4( color, 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
