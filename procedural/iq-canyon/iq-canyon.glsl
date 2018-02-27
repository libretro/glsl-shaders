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
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
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

//-----------------------------------------------------------------------------------

#define LOWDETAIL
//#define HIGH_QUALITY_NOISE

float noise1( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
#ifndef HIGH_QUALITY_NOISE
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel2, (uv+ 0.5)/256.0, 0.0 ).yx;
#else
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z);
	vec2 rg1 = textureLod( iChannel2, (uv+ vec2(0.5,0.5))/256.0, 0.0 ).yx;
	vec2 rg2 = textureLod( iChannel2, (uv+ vec2(1.5,0.5))/256.0, 0.0 ).yx;
	vec2 rg3 = textureLod( iChannel2, (uv+ vec2(0.5,1.5))/256.0, 0.0 ).yx;
	vec2 rg4 = textureLod( iChannel2, (uv+ vec2(1.5,1.5))/256.0, 0.0 ).yx;
	vec2 rg = mix( mix(rg1,rg2,f.x), mix(rg3,rg4,f.x), f.y );
#endif	
	return mix( rg.x, rg.y, f.z );
}

//-----------------------------------------------------------------------------------
const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float displacement( vec3 p )
{
    float f;
    f  = 0.5000*noise1( p ); p = m*p*2.02;
    f += 0.2500*noise1( p ); p = m*p*2.03;
    f += 0.1250*noise1( p ); p = m*p*2.01;
	#ifndef LOWDETAIL
    f += 0.0625*noise1( p ); 
	#endif
    return f;
}

vec4 texcube( sampler2D sam, in vec3 p, in vec3 n )
{
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(abs(n.x)+abs(n.y)+abs(n.z));
}


vec4 textureGood( sampler2D sam, vec2 uv, float lo )
{
    uv = uv*1024.0 - 0.5;
    vec2 iuv = floor(uv);
    vec2 f = fract(uv);
	vec4 rg1 = textureLod( sam, (iuv+ vec2(0.5,0.5))/1024.0, lo );
	vec4 rg2 = textureLod( sam, (iuv+ vec2(1.5,0.5))/1024.0, lo );
	vec4 rg3 = textureLod( sam, (iuv+ vec2(0.5,1.5))/1024.0, lo );
	vec4 rg4 = textureLod( sam, (iuv+ vec2(1.5,1.5))/1024.0, lo );
	return mix( mix(rg1,rg2,f.x), mix(rg3,rg4,f.x), f.y );
}
//-----------------------------------------------------------------------------------

float terrain( in vec2 q )
{
	float th = smoothstep( 0.0, 0.7, textureLod( iChannel0, 0.001*q, 0.0 ).x );
    float rr = smoothstep( 0.1, 0.5, textureLod( iChannel1, 2.0*0.03*q, 0.0 ).y );
	float h = 1.9;
	#ifndef LOWDETAIL
	h += -0.15 + (1.0-0.6*rr)*(1.5-1.0*th) * 0.3*(1.0-textureLod( iChannel0, 0.04*q*vec2(1.2,0.5), 0.0 ).x);
	#endif
	h += th*7.0;
    h += 0.3*rr;
    return -h;
}

float terrain2( in vec2 q )
{
	float th = smoothstep( 0.0, 0.7, textureGood( iChannel0, 0.001*q, 0.0 ).x );
    float rr = smoothstep( 0.1, 0.5, textureGood( iChannel1, 2.0*0.03*q, 0.0 ).y );
	float h = 1.9;
	h += th*7.0;
    return -h;
}


vec4 map( in vec3 p )
{
	float h = terrain( p.xz );
	float dis = displacement( 0.25*p*vec3(1.0,4.0,1.0) );
	dis *= 3.0;
	return vec4( (dis + p.y-h)*0.25, p.x, h, 0.0 );
}

vec4 intersect( in vec3 ro, in vec3 rd, in float tmax )
{
    float t = 0.1;
    vec3 res = vec3(0.0);
    for( int i=0; i<256; i++ )
    {
	    vec4 tmp = map( ro+rd*t );
        res = tmp.ywz;
        t += tmp.x;
        if( tmp.x<(0.001*t) || t>tmax ) break;
    }

    return vec4( t, res );
}

vec3 calcNormal( in vec3 pos, in float t )
{
    vec2 eps = vec2( 0.005*t, 0.0 );
	return normalize( vec3(
           map(pos+eps.xyy).x - map(pos-eps.xyy).x,
           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<50; i++ )
    {
        float h = map(ro + rd*t).x;
        res = min( res, k*h/t );
		t += clamp( h, 0.5, 1.0 );
		if( h<0.001 ) break;
    }
    return clamp(res,0.0,1.0);
}

// Oren-Nayar
float Diffuse( in vec3 l, in vec3 n, in vec3 v, float r )
{
	
    float r2 = r*r;
    float a = 1.0 - 0.5*(r2/(r2+0.57));
    float b = 0.45*(r2/(r2+0.09));

    float nl = dot(n, l);
    float nv = dot(n, v);

    float ga = dot(v-n*nv,n-n*nl);

	return max(0.0,nl) * (a + b*max(0.0,ga) * sqrt((1.0-nv*nv)*(1.0-nl*nl)) / max(nl, nv));
}

vec3 cpath( float t )
{
	vec3 pos = vec3( 0.0, 0.0, 95.0 + t );
	
	float a = smoothstep(5.0,20.0,t);
	pos.xz += a*150.0 * cos( vec2(5.0,6.0) + 1.0*0.01*t );
	pos.xz -= a*150.0 * cos( vec2(5.0,6.0) );
	pos.xz += a* 50.0 * cos( vec2(0.0,3.5) + 6.0*0.01*t );
	pos.xz -= a* 50.0 * cos( vec2(0.0,3.5) );

	return pos;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(0.0);
#ifdef MOUSE
	if( iMouse.z>0.0 ) m = iMouse.xy/iResolution.xy;
#endif

	
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

	float an = 0.5*(iGlobalTime-5.0);// + 12.0*(m.x-0.5);
	vec3 ro = cpath( an + 0.0 );
	vec3 ta = cpath( an + 10.0 *1.0);
	ta = mix( ro + vec3(0.0,0.0,1.0), ta, smoothstep(5.0,25.0,an) );
    ro.y = terrain2( ro.xz ) - 0.5;
	ta.y = ro.y - 0.1;
	ta.xy += step(0.01,m.x)*(m.xy-0.5)*4.0*vec2(-1.0,1.0);
	float rl = -0.1*cos(0.05*6.2831*an);
    // camera to world transform    
    mat3 cam = setCamera( ro, ta, rl );
    
    // ray
	vec3 rd = normalize( cam * vec3(p.xy, 2.0) );

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 klig = normalize(vec3(-1.0,0.19,0.4));
	
	float sun = clamp(dot(klig,rd),0.0,1.0 );

	vec3 hor = mix( 1.2*vec3(0.70,1.0,1.0), vec3(1.5,0.5,0.05), 0.25+0.75*sun );
	
    vec3 col = mix( vec3(0.2,0.6,.9), hor, exp(-(4.0+2.0*(1.0-sun))*max(0.0,rd.y-0.1)) );
    col *= 0.5;
	col += 0.8*vec3(1.0,0.8,0.7)*pow(sun,512.0);
	col += 0.2*vec3(1.0,0.4,0.2)*pow(sun,32.0);
	col += 0.1*vec3(1.0,0.4,0.2)*pow(sun,4.0);
	
	vec3 bcol = col;
	
	// clouds
	float pt = (1000.0-ro.y)/rd.y; 
	if( pt>0.0 )
	{
        vec3 spos = ro + pt*rd;
        float clo = texture( iChannel0, 0.00006*spos.xz ).x;	
        vec3 cloCol = mix( vec3(0.4,0.5,0.6), vec3(1.3,0.6,0.4), pow(sun,2.0))*(0.5+0.5*clo);
        col = mix( col, cloCol, 0.5*smoothstep( 0.4, 1.0, clo ) );
	}
	
	
	// raymarch
    float tmax = 120.0;
    
    // bounding plane    
    float bt = (0.0-ro.y)/rd.y; 
	if( bt>0.0 ) tmax = min( tmax, bt );
        
    vec4 tmat = intersect( ro, rd, tmax);
    if( tmat.x<tmax )
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal( pos, tmat.x );
		vec3 ref = reflect( rd, nor );

		float occ = smoothstep( 0.0, 1.5, pos.y + 11.5 ) * (1.0 - displacement( 0.25*pos*vec3(1.0,4.0,1.0) ));

		// materials
		vec4 mate = vec4(0.5,0.5,0.5,0.0);
		
		//if( tmat.z<0.5 )
		{
			vec3 uvw = 1.0*pos;

			vec3 bnor;
			float be = 1.0/1024.0;
			float bf = 0.4;
			bnor.x = texcube( iChannel0, bf*uvw+vec3(be,0.0,0.0), nor ).x - texcube( iChannel0, bf*uvw-vec3(be,0.0,0.0), nor ).x;
			bnor.y = texcube( iChannel0, bf*uvw+vec3(0.0,be,0.0), nor ).x - texcube( iChannel0, bf*uvw-vec3(0.0,be,0.0), nor ).x;
			bnor.z = texcube( iChannel0, bf*uvw+vec3(0.0,0.0,be), nor ).x - texcube( iChannel0, bf*uvw-vec3(0.0,0.0,be), nor ).x;
			bnor = normalize(bnor);
			float amo = 0.2  + 0.25*(1.0-smoothstep(0.6,0.7,nor.y) );
			nor = normalize( nor + amo*(bnor-nor*dot(bnor,nor)) );

			vec3 te = texcube( iChannel0, 0.15*uvw, nor ).xyz;
			te = 0.05 + te;
			mate.xyz = 0.6*te;
			mate.w = 1.5*(0.5+0.5*te.x);
			float th = smoothstep( 0.1, 0.4, texcube( iChannel0, 0.002*uvw, nor ).x );
			vec3 dcol = mix( vec3(0.2, 0.3, 0.0), 0.4*vec3(0.65, 0.4, 0.2), 0.2+0.8*th );
			mate.xyz = mix( mate.xyz, 2.0*dcol, th*smoothstep( 0.0, 1.0, nor.y ) );
			mate.xyz *= 0.5;
			float rr = smoothstep( 0.2, 0.4, texcube( iChannel1, 2.0*0.02*uvw, nor ).y );
			mate.xyz *= mix( vec3(1.0), 1.5*vec3(0.25,0.24,0.22)*1.5, rr );
			mate.xyz *= 1.5*pow(texcube( iChannel3, 8.0*uvw, nor ).xyz,vec3(0.5));
            mate = mix( mate, vec4(0.7,0.7,0.7,.0), smoothstep(0.8,0.9,nor.y + nor.x*0.6*te.x*te.x ));
			
			
			mate.xyz *= 1.5;
		}
		
		vec3 blig = normalize(vec3(-klig.x,0.0,-klig.z));
		vec3 slig = vec3( 0.0, 1.0, 0.0 );
			
		// lighting
        float sky = 0.0;
        sky += 0.2*Diffuse( normalize(vec3( 0.0, 1.0, 0.0 )), nor, -rd, 1.0 );
        sky += 0.2*Diffuse( normalize(vec3( 3.0, 1.0, 0.0 )), nor, -rd, 1.0 );
        sky += 0.2*Diffuse( normalize(vec3(-3.0, 1.0, 0.0 )), nor, -rd, 1.0 );
        sky += 0.2*Diffuse( normalize(vec3( 0.0, 1.0, 3.0 )), nor, -rd, 1.0 );
        sky += 0.2*Diffuse( normalize(vec3( 0.0, 1.0,-3.0 )), nor, -rd, 1.0 );
		float dif = Diffuse( klig, nor, -rd, 1.0 );
		float bac = Diffuse( blig, nor, -rd, 1.0 );


		float sha = 0.0; if( dif>0.001 ) sha=softshadow( pos+0.01*nor, klig, 0.005, 64.0 );
        float spe = mate.w*pow( clamp(dot(reflect(rd,nor),klig),0.0,1.0),2.0)*clamp(dot(nor,klig),0.0,1.0);
		
		// lights
		vec3 lin = vec3(0.0);
		lin += 7.0*dif*vec3(1.20,0.50,0.25)*vec3(sha,sha*0.5+0.5*sha*sha, sha*sha );
		lin += 1.0*sky*vec3(0.10,0.50,0.70)*occ;
		lin += 2.0*bac*vec3(0.30,0.15,0.15)*occ;
	    lin += 0.5*vec3(spe)*sha*occ;
		
		// surface-light interacion
		col = mate.xyz * lin;

		// fog
        bcol = 0.7*mix( vec3(0.2,0.5,1.0)*0.82, bcol, 0.15+0.8*sun ); col = mix( col, bcol, 1.0-exp(-0.02*tmat.x) );		
	}
	

	col += 0.15*vec3(1.0,0.9,0.6)*pow( sun, 6.0 );
	
	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------
    col *= 1.0 - 0.25*pow(1.0-clamp(dot(cam[2],klig),0.0,1.0),3.0);
	
	col = pow( clamp(col,0.0,1.0), vec3(0.45) );

	col *= vec3(1.1,1.0,1.0);
	col = col*col*(3.0-2.0*col);
	col = pow( col, vec3(0.9,1.0,1.0) );

	col = mix( col, vec3(dot(col,vec3(0.333))), 0.4 );
	col = col*0.5+0.5*col*col*(3.0-2.0*col);
	
	col *= 0.3 + 0.7*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    col *= smoothstep(0.0,2.5,iGlobalTime);

	fragColor = vec4( col, 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
