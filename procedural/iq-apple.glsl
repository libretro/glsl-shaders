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

//=======================================================================

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float hash( float n )
{
    return fract(sin(n)*4121.15393);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*157.0 + 113.0*p.z;

    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

float fbm( vec3 p )
{
    float f = 0.0;

    f += 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );

    return f/0.9375;
}

//=======================================================================

vec2 map( vec3 p )
{
    // table
    vec2 d2 = vec2( p.y+0.55, 2.0 );

    // apple
    p.y -= 0.75*pow(dot(p.xz,p.xz),0.2);
    vec2 d1 = vec2( length(p) - 1.0, 1.0 );

    // union    
    return (d2.x<d1.x) ? d2 : d1; 
}

vec3 appleColor( in vec3 pos, in vec3 nor, out vec2 spe )
{
    spe.x = 1.0;
    spe.y = 1.0;

    float a = atan(pos.x,pos.z);
    float r = length(pos.xz);

    // red
    vec3 col = vec3(1.0,0.0,0.0);

    // green
    float f = smoothstep( 0.4, 1.0, fbm(pos*1.0) );
    col = mix( col, vec3(0.9,0.9,0.2), f );

    // dirty
    f = smoothstep( 0.0, 1.0, fbm(pos*4.0) );
    col *= 0.8+0.2*f;

    // frekles
    f = smoothstep( 0.0, 1.0, fbm(pos*48.0) );
    f = smoothstep( 0.6,1.0,f);
    col = mix( col, vec3(0.9,0.9,0.6), f*0.4 );

    // stripes
    f = fbm( vec3(a*7.0 + pos.z,3.0*pos.y,pos.x)*2.0);
    f = smoothstep( 0.2,1.0,f);
    f *= smoothstep(0.4,1.2,pos.y + 0.75*(noise(4.0*pos.zyx)-0.5) );
    col = mix( col, vec3(0.4,0.2,0.0), 0.5*f );
    spe.x *= 1.0-0.35*f;
    spe.y = 1.0-0.5*f;

    // top
    f = 1.0-smoothstep( 0.14, 0.2, r );
    col = mix( col, vec3(0.6,0.6,0.5), f );
    spe.x *= 1.0-f;


    float ao = 0.5 + 0.5*nor.y;
    col *= ao*1.2;

    return col;
}

vec3 floorColor( in vec3 pos, in vec3 nor, out vec2 spe )
{
    spe.x = 1.0;
    spe.y = 1.0;
    vec3 col = vec3(0.5,0.4,0.3)*1.7;

    float f = fbm( 4.0*pos*vec3(6.0,0.0,0.5) );
    col = mix( col, vec3(0.3,0.2,0.1)*1.7, f );
    spe.y = 1.0 + 4.0*f;

    f = fbm( 2.0*pos );
    col *= 0.7+0.3*f;

    // frekles
    f = smoothstep( 0.0, 1.0, fbm(pos*48.0) );
    f = smoothstep( 0.7,0.9,f);
    col = mix( col, vec3(0.2), f*0.75 );

    // fake ao
    f = smoothstep( 0.1, 1.55, length(pos.xz) );
    col *= f*f*1.4;
    col.x += 0.1*(1.0-f);
    return col;
}

vec2 intersect( in vec3 ro, in vec3 rd )
{
    float t=0.0;
    float dt = 0.06;
    float nh = 0.0;
    float lh = 0.0;
    float lm = -1.0;
    for(int i=0;i<128;i++)
    {
        vec2 ma = map(ro+rd*t);
        nh = ma.x;
        if(nh>0.0) { lh=nh; t+=dt;  } lm=ma.y;
    }

    if( nh>0.0 ) return vec2(-1.0);
    t = t - dt*nh/(nh-lh);

    return vec2(t,lm);
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float dt = 0.1;
    float t = mint;
    for( int i=0; i<30; i++ )
    {
        float h = map(ro + rd*t).x;
        h = max(h,0.0);
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += dt;
		if( h<0.001 ) break;
    }
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    vec2 eps = vec2(.001,0.0);
    return normalize( vec3(map(pos+eps.xyy).x - map(pos-eps.xyy).x,
                           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
                           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;

    // camera
    vec3 ro = 2.5*normalize(vec3(cos(0.2*iGlobalTime),0.9+0.3*cos(iGlobalTime*.11),
								  sin(0.2*iGlobalTime)));
    vec3 ww = normalize(vec3(0.0,0.5,0.0) - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

    // raymarch
    vec3 col = vec3(0.96,0.98,1.0);
    vec2 tmat = intersect(ro,rd);
    if( tmat.y>0.5 )
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect(rd,nor);
        vec3 lig = normalize(vec3(1.0,0.8,-0.6));
     
        float con = 1.0;
        float amb = 0.5 + 0.5*nor.y;
        float dif = max(dot(nor,lig),0.0);
        float bac = max(0.2 + 0.8*dot(nor,vec3(-lig.x,lig.y,-lig.z)),0.0);
        float rim = pow(1.0+dot(nor,rd),3.0);
        float spe = pow(clamp(dot(lig,ref),0.0,1.0),16.0);

        // shadow
        float sh = softshadow( pos, lig, 0.06, 4.0, 6.0 );

        // lights
        col  = 0.10*con*vec3(0.80,0.90,1.00);
        col += 0.70*dif*vec3(1.00,0.97,0.85)*vec3(sh, (sh+sh*sh)*0.5, sh*sh );
        col += 0.15*bac*vec3(1.00,0.97,0.85);
        col += 0.50*amb*vec3(0.10,0.15,0.20);

        // color
        vec2 pro;
        if( tmat.y<1.5 )
        col *= appleColor(pos,nor,pro);
        else
        col *= floorColor(pos,nor,pro);

        // rim and spec
        col += 0.70*rim*vec3(1.0,0.9,0.8)*amb*amb*amb;
        col += 0.60*pow(spe,pro.y)*vec3(1.0)*pro.x*sh;

        // gamma
        col = sqrt(col);
    }

    // vignetting
    col *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );

    fragColor = vec4(col,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
