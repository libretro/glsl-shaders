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

// The MIT License
// Copyright © 2016 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// Computing normals analytically has the benefit of being faster if you need them often, 
// while numerical normals are easier to filter for antialiasing. See line 200.
//
// More info: http://iquilezles.org/www/articles/morenoise/morenoise.htm
//
// See this too: https://www.shadertoy.com/view/XsXfRH
//
// Proper noise code isolated here: https://www.shadertoy.com/view/XsXfRH
//
//#define SHOW_NUMERICAL_NORMALS  // for comparison purposes

float hash( float n ) { return fract(sin(n)*753.5453123); }


//---------------------------------------------------------------
// value noise, and its analytical derivatives
//---------------------------------------------------------------

vec4 noised( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
	vec3 u = w*w*(3.0-2.0*w);
    vec3 du = 6.0*w*(1.0-w);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    
    float a = hash(n+  0.0);
    float b = hash(n+  1.0);
    float c = hash(n+157.0);
    float d = hash(n+158.0);
    float e = hash(n+113.0);
	float f = hash(n+114.0);
    float g = hash(n+270.0);
    float h = hash(n+271.0);
	
    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                 du * (vec3(k1,k2,k3) + u.yzx*vec3(k4,k5,k6) + u.zxy*vec3(k6,k4,k5) + k7*u.yzx*u.zxy ));
}

//---------------------------------------------------------------

vec4 sdBox( vec3 p, vec3 b ) // distance and normal
{
    vec3 d = abs(p) - b;
    float x = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    vec3  n = step(d.yzx,d.xyz)*step(d.zxy,d.xyz)*sign(p);
    return vec4( x, n );
}

vec4 fbmd( in vec3 x )
{
    const float scale  = 1.5;

    float a = 0.0;
    float b = 0.5;
	float f = 1.0;
    vec3  d = vec3(0.0);
    for( int i=0; i<8; i++ )
    {
        vec4 n = noised(f*x*scale);
        a += b*n.x;           // accumulate values		
        d += b*n.yzw*f*scale; // accumulate derivatives
        b *= 0.5;             // amplitude decrease
        f *= 1.8;             // frequency increase
    }

	return vec4( a, d );
}

vec4 map( in vec3 p )
{
	vec4 d1 = fbmd( p );
    d1.x -= 0.37;
	d1.x *= 0.7;
    d1.yzw = normalize(d1.yzw);

    // clip to box
    vec4 d2 = sdBox( p, vec3(1.5) );
    return (d1.x>d2.x) ? d1 : d2;
}

// ray-box intersection in box space
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	if( tN > tF || tF < 0.0) return vec2(-1.0);
	return vec2( tN, tF );
}

// raymarch
vec4 interesect( in vec3 ro, in vec3 rd )
{
	vec4 res = vec4(-1.0);

    // bounding volume    
    vec2 dis = iBox( ro, rd, vec3(1.5) ) ;
    if( dis.y<0.0 ) return res;

    // raymarch
    float tmax = dis.y;
    float t = dis.x;
	for( int i=0; i<128; i++ )
	{
        vec3 pos = ro + t*rd;
		vec4 hnor = map( pos );
        res = vec4(t,hnor.yzw);
        
		if( hnor.x<0.001 ) break;
		t += hnor.x;
        if( t>tmax ) break;
	}

	if( t>tmax ) res = vec4(-1.0);
	return res;
}

// compute normal numerically
#ifdef SHOW_NUMERICAL_NORMALS
vec3 calcNormal( in vec3 pos )
{
	vec2 eps = vec2( 0.0001, 0.0 );
	vec3 nor = vec3( map(pos+eps.xyy).x - map(pos-eps.xyy).x,
	                 map(pos+eps.yxy).x - map(pos-eps.yxy).x,
	                 map(pos+eps.yyx).x - map(pos-eps.yyx).x );
	return normalize(nor);
}
#endif

// fibonazzi points in s aphsre, more info:
// http://lgdv.cs.fau.de/uploads/publications/spherical_fibonacci_mapping_opt.pdf
vec3 forwardSF( float i, float n) 
{
    const float PI  = 3.141592653589793238;
    const float PHI = 1.618033988749894848;
    float phi = 2.0*PI*fract(i/PHI);
    float zi = 1.0 - (2.0*i+1.0)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float ao = 0.0;
    for( int i=0; i<32; i++ )
    {
        vec3 ap = forwardSF( float(i), 32.0 );
        float h = hash(float(i));
		ap *= sign( dot(ap,nor) ) * h*0.25;
        ao += clamp( map( pos + nor*0.001 + ap ).x*3.0, 0.0, 1.0 );
    }
	ao /= 32.0;
	
    return clamp( ao*5.0, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;
   
	// camera anim
    float an = 0.1*iGlobalTime;
	vec3 ro = 3.0*vec3( cos(an), 0.8, sin(an) );
	vec3 ta = vec3( 0.0 );
	
    // camera matrix	
	vec3  cw = normalize( ta-ro );
	vec3  cu = normalize( cross(cw,vec3(0.0,1.0,0.0)) );
	vec3  cv = normalize( cross(cu,cw) );
	vec3  rd = normalize( p.x*cu + p.y*cv + 1.7*cw );

	// render
	vec3 col = vec3(0.0);
    vec4 tnor = interesect( ro, rd );
	float t = tnor.x;

    if( t>0.0 )
	{
		vec3 pos = ro + t*rd;
        #ifndef SHOW_NUMERICAL_NORMALS
        vec3 nor = tnor.yzw; // no need to call calcNormal( pos );
        #else
        vec3 nor = calcNormal( pos );
        #endif
        float occ = calcAO( pos, nor );
        float fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
        float fro = clamp( dot(nor,-rd), 0.0, 1.0 );
        col = mix( vec3(0.05,0.2,0.3), vec3(1.0,0.95,0.85), 0.5+0.5*nor.y );
        //col = 0.5+0.5*nor;
        col += 10.0*pow(fro,12.0)*(0.04+0.96*pow(fre,5.0));
        col *= pow(vec3(occ),vec3(1.0,1.1,1.1) );
	}

    col = sqrt(col);
	
    fragColor=vec4(col,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
