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

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// The source code for these videos from 2009: 
// https://www.youtube.com/watch?v=eKUh4nkmQbc
// https://www.youtube.com/watch?v=erS6SKqtXLY

// More info here: http://iquilezles.org/www/articles/mandelbulb/mandelbulb.htm

// See https://www.shadertoy.com/view/MdfGRr to see the Julia counterpart


// make this 1 for slow machines (image quality will go down)
#define AA 2


vec2 isphere( in vec4 sph, in vec3 ro, in vec3 rd )
{
    vec3 oc = ro - sph.xyz;
    
	float b = dot(oc,rd);
	float c = dot(oc,oc) - sph.w*sph.w;
    float h = b*b - c;
    
    if( h<0.0 ) return vec2(-1.0);

    h = sqrt( h );

    return -b + vec2(-h,h);
}

float map( in vec3 p, out vec4 resColor )
{
    vec3 w = p;
    float m = dot(w,w);

    vec4 trap = vec4(abs(w),m);
	float dz = 1.0;
    
    
	for( int i=0; i<4; i++ )
    {
#if 0
        float m2 = m*m;
        float m4 = m2*m2;
		dz = 8.0*sqrt(m4*m2*m)*dz + 1.0;

        float x = w.x; float x2 = x*x; float x4 = x2*x2;
        float y = w.y; float y2 = y*y; float y4 = y2*y2;
        float z = w.z; float z2 = z*z; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;

        w.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        w.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
        w.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
#else
        dz = 8.0*pow(sqrt(m),7.0)*dz + 1.0;
		//dz = 8.0*pow(m,3.5)*dz + 1.0;
        
        float r = length(w);
        float b = 8.0*acos( w.y/r);
        float a = 8.0*atan( w.x, w.z );
        w = p + pow(r,8.0) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );
#endif        
        
        trap = min( trap, vec4(abs(w),m) );

        m = dot(w,w);
		if( m > 256.0 )
            break;
    }

    resColor = vec4(m,trap.yzw);

    return 0.25*log(m)*sqrt(m)/dz;
}

float intersect( in vec3 ro, in vec3 rd, out vec4 rescol, in float px )
{
    float res = -1.0;

    // bounding sphere
    vec2 dis = isphere( vec4(0.0,0.0,0.0,1.25), ro, rd );
    if( dis.y<0.0 )
        return -1.0;
    dis.x = max( dis.x, 0.0 );
    dis.y = min( dis.y, 10.0 );

    // raymarch fractal distance field
	vec4 trap;

	float t = dis.x;
	for( int i=0; i<128; i++  )
    { 
        vec3 pos = ro + rd*t;
        float th = 0.25*px*t;
		float h = map( pos, trap );
		if( t>dis.y || h<th ) break;
        t += h;
    }
    
    
    if( t<dis.y )
    {
        rescol = trap;
        res = t;
    }

    return res;
}

float softshadow( in vec3 ro, in vec3 rd, in float k )
{
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<64; i++ )
    {
        vec4 kk;
        float h = map(ro + rd*t, kk);
        res = min( res, k*h/t );
        if( res<0.001 ) break;
        t += clamp( h, 0.01, 0.2 );
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos, in float t, in float px )
{
    vec4 tmp;
    vec2 eps = vec2( 0.25*px, 0.0 );
	return normalize( vec3(
           map(pos+eps.xyy,tmp) - map(pos-eps.xyy,tmp),
           map(pos+eps.yxy,tmp) - map(pos-eps.yxy,tmp),
           map(pos+eps.yyx,tmp) - map(pos-eps.yyx,tmp) ) );

}

const vec3 light1 = vec3(  0.577, 0.577, -0.577 );
const vec3 light2 = vec3( -0.707, 0.000,  0.707 );


vec3 render( in vec2 p, in mat4 cam )
{
	// ray setup
    const float fle = 1.5;

    vec2  sp = (-iResolution.xy + 2.0*p) / iResolution.y;
    float px = 2.0/(iResolution.y*fle);

    vec3  ro = vec3( cam[0].w, cam[1].w, cam[2].w );
	vec3  rd = normalize( (cam*vec4(sp,fle,0.0)).xyz );

    // intersect fractal
	vec4 tra;
    float t = intersect( ro, rd, tra, px );
    
	vec3 col;

    // color sky
    if( t<0.0 )
    {
     	col  = vec3(0.8,.95,1.0)*(0.6+0.4*rd.y);
		col += 5.0*vec3(0.8,0.7,0.5)*pow( clamp(dot(rd,light1),0.0,1.0), 32.0 );
	}
    // color fractal
	else
	{
        // color
        col = vec3(0.01);
		col = mix( col, vec3(0.10,0.20,0.30), clamp(tra.y,0.0,1.0) );
	 	col = mix( col, vec3(0.02,0.10,0.30), clamp(tra.z*tra.z,0.0,1.0) );
        col = mix( col, vec3(0.30,0.10,0.02), clamp(pow(tra.w,6.0),0.0,1.0) );
        col *= 0.5;
		//col = vec3(0.1);
        
        // lighting terms
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos, t, px );
        vec3 hal = normalize( light1-rd);
        vec3 ref = reflect( rd, nor );
        float occ = clamp(0.05*log(tra.x),0.0,1.0);
        float fac = clamp(1.0+dot(rd,nor),0.0,1.0);

        // sun
        float sha1 = softshadow( pos+0.001*nor, light1, 32.0 );
        float dif1 = clamp( dot( light1, nor ), 0.0, 1.0 )*sha1;
        float spe1 = pow( clamp(dot(nor,hal),0.0,1.0), 32.0 )*dif1*(0.04+0.96*pow(clamp(1.0-dot(hal,light1),0.0,1.0),5.0));
        // bounce
        float dif2 = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 )*occ;
        // sky
        float dif3 = (0.7+0.3*nor.y)*(0.2+0.8*occ);
        
		vec3 lin = vec3(0.0); 
		     lin += 7.0*vec3(1.50,1.10,0.70)*dif1;
		     lin += 4.0*vec3(0.25,0.20,0.15)*dif2;
        	 lin += 1.5*vec3(0.10,0.20,0.30)*dif3;
             lin += 2.5*vec3(0.35,0.30,0.25)*(0.05+0.95*occ); // ambient
        	 lin += 4.0*fac*occ;                          // fake SSS
		col *= lin;
		col = pow( col, vec3(0.7,0.9,1.0) );                  // fake SSS
        col += spe1*15.0;
        //col += 8.0*vec3(0.8,0.9,1.0)*(0.2+0.8*occ)*(0.03+0.97*pow(fac,5.0))*smoothstep(0.0,0.1,ref.y )*softshadow( pos+0.01*nor, ref, 2.0 );
        //col = vec3(occ*occ);
    }

    // gamma
	return sqrt( col );
}
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iGlobalTime*.1;

    // camera
	float di = 1.4+0.1*cos(.29*time);
	vec3  ro = di * vec3( cos(.33*time), 0.8*sin(.37*time), sin(.31*time) );
	vec3  ta = vec3(0.0,0.1,0.0);
	float cr = 0.5*cos(0.1*time);

    // camera matrix
    vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
    mat4 cam = mat4( cu, ro.x, cv, ro.y, cw, ro.z, 0.0, 0.0, 0.0, 1.0 );

    // render
    #if AA<2
	vec3 col = render(  fragCoord, cam );
    #else
    vec3 col = vec3(0.0);
    for( int j=0; j<AA; j++ )
    for( int i=0; i<AA; i++ )
    {
	    col += render( fragCoord + (vec2(i,j)/float(AA)), cam );
    }
	col /= float(AA*AA);
    #endif

	fragColor = vec4( col, 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
