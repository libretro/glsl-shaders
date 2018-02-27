#version 130
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
uniform sampler2D iChannel0;
vec2 iChannelResolution = vec2(64.0, 64.0);
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

#define NUMPASES 1


//-------------------------------------------------------------------------------------------
// sphere related functions
//-------------------------------------------------------------------------------------------

vec3 sphNormal( in vec3 pos, in vec4 sph )
{
    return normalize(pos-sph.xyz);
}

float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

float sphShadow( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    return step( min( -b, min( c, b*b - c ) ), 0.0 );
}
            
vec2 sphDistances( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    float d = sqrt( max(0.0,sph.w*sph.w-h)) - sph.w;
    return vec2( d, -b-sqrt(max(h,0.0)) );
}

float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph )
{
    float s = 1.0;
    vec2 r = sphDistances( ro, rd, sph );
    if( r.y>0.0 )
        s = max(r.x,0.0)/r.y;
    return s;
}    
            
float sphOcclusion( in vec3 pos, in vec3 nor, in vec4 sph )
{
    vec3  r = sph.xyz - pos;
    float l = length(r);
    float d = dot(nor,r);
    float res = d;

    if( d<sph.w ) res = pow(clamp((d+sph.w)/(2.0*sph.w),0.0,1.0),1.5)*sph.w;
    
    return clamp( res*(sph.w*sph.w)/(l*l*l), 0.0, 1.0 );
}

//-------------------------------------------------------------------------------------------
// rendering functions
//-------------------------------------------------------------------------------------------

#define NUMSPHEREES 15

vec4 sphere[NUMSPHEREES];

float shadow( in vec3 ro, in vec3 rd )
{
	float res = 1.0;
	for( int i=0; i<NUMSPHEREES; i++ )
        res = min( res, 8.0*sphSoftShadow(ro,rd,sphere[i]) );
    return res;					  
}

float occlusion( in vec3 pos, in vec3 nor )
{
	float res = 1.0;
	for( int i=0; i<NUMSPHEREES; i++ )
	    res *= 1.0 - sphOcclusion( pos, nor, sphere[i] ); 
    return res;					  
}

//-------------------------------------------------------------------------------------------
// utlity functions
//-------------------------------------------------------------------------------------------


vec3 hash3( float n ) { return fract(sin(vec3(n,n+1.0,n+2.0))*43758.5453123); }
vec3 textureBox( sampler2D sam, in vec3 pos, in vec3 nor )
{
    vec3 w = abs(nor);
    return (w.x*texture( sam, pos.yz ).xyz + 
            w.y*texture( sam, pos.zx ).xyz + 
            w.z*texture( sam, pos.xy ).xyz ) / (w.x+w.y+w.z);
}

//-------------------------------------------------------------------------------------------
// SCENE
//-------------------------------------------------------------------------------------------

vec3 lig = normalize( vec3( -0.8, 0.3, -0.5 ) );

vec3 shade( in vec3 rd, in vec3 pos, in vec3 nor, in float id, in vec3 uvw, in float dis )
{
    vec3 ref = reflect(rd,nor);
    float occ = occlusion( pos, nor );
    float fre = clamp(1.0+dot(rd,nor),0.0,1.0);
    
    occ = occ*0.5 + 0.5*occ*occ;
    
    vec3 lin = vec3(0.0);
    lin += 1.0*vec3(0.6,0.6,0.6)*occ;
    lin += 0.5*vec3(0.3,0.3,0.3)*(0.2+0.8*occ);
    lin += 0.3*vec3(0.5,0.4,0.3)*pow( fre, 2.0 )*occ;
    lin += 0.1*nor.y + 0.1*nor;

    float dif = clamp( nor.y, 0.0, 1.0 ) * shadow( pos, vec3(0.0,1.0,0.0) );

    lin = lin*0.7 + 0.8*dif;
    
    vec3 mate = 0.6 + 0.4*cos( 10.0*sin(id) + vec3(0.0,0.5,1.0) + 2. );
    vec3 te = textureBox( iChannel0, 0.25*uvw, nor );
    vec3 qe = te;
    te = 0.1 + 0.9*te;
    mate *= te*1.7;
    
    float h = id / float(NUMSPHEREES);
    mate *= 1.0-smoothstep(0.5,0.6,sin(50.0*uvw.x*(1.0-0.95*h))*
                                   sin(50.0*uvw.y*(1.0-0.95*h))*
                                   sin(50.0*uvw.z*(1.0-0.95*h)) );

    vec3 col = mate*lin;

    float r = clamp(qe.x,0.0,1.0);
    col += 0.2 * r * pow( clamp(dot(-rd,nor), 0.0, 1.0 ), 4.0 ) * occ;
    col += 0.4 * r * pow( clamp(reflect(rd,nor).y, 0.0, 1.0 ), 8.0 ) * dif;

    
    //col *= 1.5*exp( -0.05*dis*dis );
    
    return col;
}    


vec3 trace( in vec3 ro, in vec3 rd, vec3 col, in float px )
{
    float tmin = 1e20;
    
	float t = tmin;
	float id  = -1.0;
    vec4  obj = vec4(0.0);
	for( int i=0; i<NUMSPHEREES; i++ )
	{
		vec4 sph = sphere[i];
	    float h = sphIntersect( ro, rd, sph ); 
		if( h>0.0 && h<t ) 
		{
			t = h;
            obj = sph;
			id = float(i);
		}
	}
						  
    if( id>-0.5 )
    {
		vec3 pos = ro + t*rd;
		vec3 nor = sphNormal( pos, obj );
        col = shade( rd, pos, nor, float(NUMSPHEREES-1)-id, pos-obj.xyz, t );
    }

    return col;
}


vec3 animate( float time )
{
	
    // animate
    vec3 cen = vec3(0.0);
	for( int i=0; i<NUMSPHEREES; i++ )
	{
		float id  = float(NUMSPHEREES-1-i);
        float ra = pow(id/float(NUMSPHEREES-1),3.0);
        vec3  pos = 1.0*cos( 6.2831*hash3(id*16.0+2.0*0.0) + 1.5*(1.0-0.7*ra)*sin(id)*time*2.0 );
        ra = 0.2 + 0.8*ra;

        // repell
        #if NUMPASES>0
        #if NUMPASES>1
        for( int k=0; k<NUMPASES; k++ )
        #endif
        for( int j=0; j<NUMSPHEREES; j++ )
        {
            if( j<i )
            {
                vec3  di = pos.xyz - sphere[j].xyz;
                float rr = ra + sphere[j].w;
                if( dot(di,di) < rr*rr )
                {
                    float l = length(di);
                    pos += di*(rr-l)/l;
                }
            }
        }
        #endif
        
		sphere[i] = vec4( pos, ra );
        cen += pos;
    }
    
    cen /= float(NUMSPHEREES);
    return cen;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = (2.0*fragCoord.xy-iResolution.xy)/iResolution.y;
#ifdef MOUSE
    vec2 m = step(0.0001,iMouse.z) * iMouse.xy/iResolution.xy;
#else
    vec2 m = step(0.0001,0.0) * 0.0/iResolution.xy;
#endif

  	float time = iGlobalTime*0.5;
    vec3 cen = animate( time );


    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
  	float an = 0.3*time - 7.0*m.x - 3.5;

    float le = 2.5;
	vec3 ro = cen + vec3(4.0*sin(an),1.0,4.0*cos(an));
    vec3 ta = cen;
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
	vec3 rd = normalize( p.x*uu + p.y*vv + le*ww );

    float px = 1.0*(2.0/iResolution.y)*(1.0/le);

	vec3 col = vec3(0.2)*clamp(1.0-0.3*length(p),0.0,1.0);
    
    col = trace( ro, rd, col, px );

    //-----------------------------------------------------
	// postprocess
    //-----------------------------------------------------

    // gama
    col = pow( col, vec3(0.45,0.5,0.55) );
    
    // contrast    
    col = mix( col, smoothstep( 0.0, 1.0, col ), 0.5 );
    
    // saturate
    //col = mix( col, vec3(dot(col,vec3(0.333))), -0.2 );
    
	// vigneting
    col *= 0.2 + 0.8*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.2);

    // dithering
    col += (1.0/255.0)*hash3(q.x+13.0*q.y);

    fragColor = vec4( col, 1.0 );
}


void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
  	float time = iGlobalTime*0.5;
    vec3 cen = animate( time );

    vec3 ro = fragRayOri + vec3( 0.0, 1.0, 3.0 );
    vec3 rd = fragRayDir;

    vec3 col = trace( ro, rd, vec3(0.2), 0.01 );

    // gama
    col = pow( col, vec3(0.45,0.5,0.55) );
    
    // contrast    
    col = mix( col, smoothstep( 0.0, 1.0, col ), 0.5 );

	fragColor = vec4( col, 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
