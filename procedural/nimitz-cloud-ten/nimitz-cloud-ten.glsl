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

//Cloud Ten by nimitz (twitter: @stormoid)

#define time iGlobalTime
mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
float noise(float t){return textureLod(iChannel0,vec2(t,.0)/iChannelResolution.xy,0.0).x;}
float moy = 0.;

float noise(in vec3 x) //3d noise from iq
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}

float fbm(in vec3 x)
{
    float rz = 0.;
    float a = .35;
    for (int i = 0; i<2; i++)
    {
        rz += noise(x)*a;
        a*=.35;
        x*= 4.;
    }
    return rz;
}

float path(in float x){ return sin(x*0.01-3.1415)*28.+6.5; }
float map(vec3 p){
    return p.y*0.07 + (fbm(p*0.3)-0.1) + sin(p.x*0.24 + sin(p.z*.01)*7.)*0.22+0.15 + sin(p.z*0.08)*0.05;
}

float march(in vec3 ro, in vec3 rd)
{
    float precis = .3;
    float h= 1.;
    float d = 0.;
    for( int i=0; i<17; i++ )
    {
        if( abs(h)<precis || d>70. ) break;
        d += h;
        vec3 pos = ro+rd*d;
        pos.y += .5;
	    float res = map(pos)*7.;
        h = res;
    }
	return d;
}

vec3 lgt = vec3(0);
float mapV( vec3 p ){ return clamp(-map(p), 0., 1.);}
vec4 marchV(in vec3 ro, in vec3 rd, in float t, in vec3 bgc)
{
	vec4 rz = vec4( 0.0 );
	
	for( int i=0; i<150; i++ )
	{
		if(rz.a > 0.99 || t > 200.) break;
		
		vec3 pos = ro + t*rd;
        float den = mapV(pos);
        
        vec4 col = vec4(mix( vec3(.8,.75,.85), vec3(.0), den ),den);
        col.xyz *= mix(bgc*bgc*2.5,  mix(vec3(0.1,0.2,0.55),vec3(.8,.85,.9),moy*0.4), clamp( -(den*40.+0.)*pos.y*.03-moy*0.5, 0., 1. ) );
        col.rgb += clamp((1.-den*6.) + pos.y*0.13 +.55, 0., 1.)*0.35*mix(bgc,vec3(1),0.7); //Fringes
        col += clamp(den*pos.y*.15, -.02, .0); //Depth occlusion
        col *= smoothstep(0.2+moy*0.05,.0,mapV(pos+1.*lgt))*.85+0.15; //Shadows
        
		col.a *= .9;
		col.rgb *= col.a;
		rz = rz + col*(1.0 - rz.a);

        t += max(.4,(2.-den*30.)*t*0.011);
	}

	return clamp(rz, 0., 1.);
}

float pent(in vec2 p){    
    vec2 q = abs(p);
    return max(max(q.x*1.176-p.y*0.385, q.x*0.727+p.y), -p.y*1.237)*1.;
}

vec3 flare(vec2 p, vec2 pos) //Inspired by mu6k's lens flare (https://www.shadertoy.com/view/4sX3Rs)
{
	vec2 q = p-pos;
    vec2 pds = p*(length(p))*0.75;
	float a = atan(q.x,q.y);
	
    float rz = .55*(pow(abs(fract(a*.8+.12)-0.5),3.)*(noise(a*15.)*0.9+.1)*exp2((-dot(q,q)*4.))); //Spokes
	
    rz += max(1.0/(1.0+32.0*pent(pds+0.8*pos)),.0)*00.2; //Projected ghost (main lens)
    vec2 p2 = mix(p,pds,-.5); //Reverse distort
	rz += max(0.01-pow(pent(p2 + 0.4*pos),2.2),.0)*3.0;
	rz += max(0.01-pow(pent(p2 + 0.2*pos),5.5),.0)*3.0;	
	rz += max(0.01-pow(pent(p2 - 0.1*pos),1.6),.0)*4.0;
    rz += max(0.01-pow(pent(-(p2 + 1.*pos)),2.5),.0)*5.0;
    rz += max(0.01-pow(pent(-(p2 - .5*pos)),2.),.0)*4.0;
    rz += max(0.01-pow(pent(-(p2 + .7*pos)),5.),.0)*3.0;
	
    return vec3(clamp(rz,0.,1.));
}

mat3 rot_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rot_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rot_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = q - 0.5;
	float asp =iResolution.x/iResolution.y;
    p.x *= asp;
#ifdef MOUSE
	vec2 mo = iMouse.xy / iResolution.xy;
#else
	vec2 mo = 0.0 / iResolution.xy;
#endif
	moy = mo.y;
    float st = sin(time*0.3-1.3)*0.2;
    vec3 ro = vec3(0.,-2.+sin(time*.3-1.)*2.,time*30.);
    ro.x = path(ro.z);
    vec3 ta = ro + vec3(0,0,1);
    vec3 fw = normalize( ta - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), fw ));
    vec3 vv = normalize(cross(fw,uu));
    const float zoom = 1.;
    vec3 rd = normalize( p.x*uu + p.y*vv + -zoom*fw );
    
    float rox = sin(time*0.2)*0.8+2.9;
    rox += smoothstep(0.6,1.2,sin(time*0.25))*3.5;
   	float roy = sin(time*0.5)*0.2;
    mat3 rotation = rot_x(-roy)*rot_y(-rox+st*1.5)*rot_z(st);
	mat3 inv_rotation = rot_z(-st)*rot_y(rox-st*1.5)*rot_x(roy);
    rd *= rotation;
    rd.y -= dot(p,p)*0.06;
    rd = normalize(rd);
    
    vec3 col = vec3(0.);
    lgt = normalize(vec3(-0.3,mo.y+0.1,1.));  
    float rdl = clamp(dot(rd, lgt),0.,1.);
  
    vec3 hor = mix( vec3(.9,.6,.7)*0.35, vec3(.5,0.05,0.05), rdl );
    hor = mix(hor, vec3(.5,.8,1),mo.y);
    col += mix( vec3(.2,.2,.6), hor, exp2(-(1.+ 3.*(1.-rdl))*max(abs(rd.y),0.)) )*.6;
    col += .8*vec3(1.,.9,.9)*exp2(rdl*650.-650.);
    col += .3*vec3(1.,1.,0.1)*exp2(rdl*100.-100.);
    col += .5*vec3(1.,.7,0.)*exp2(rdl*50.-50.);
    col += .4*vec3(1.,0.,0.05)*exp2(rdl*10.-10.);  
    vec3 bgc = col;
    
    float rz = march(ro,rd);
    
    if (rz < 70.)
    {   
        vec4 res = marchV(ro, rd, rz-5., bgc);
    	col = col*(1.0-res.w) + res.xyz;
    }
    
    vec3 projected_flare = (-lgt*inv_rotation);
    col += 1.4*vec3(0.7,0.7,0.4)*max(flare(p,-projected_flare.xy/projected_flare.z*zoom)*projected_flare.z,0.);
    
    float g = smoothstep(0.03,.97,mo.x);
    col = mix(mix(col,col.brg*vec3(1,0.75,1),clamp(g*2.,0.0,1.0)), col.bgr, clamp((g-0.5)*2.,0.0,1.));
    
	col = clamp(col, 0., 1.);
    col = col*0.5 + 0.5*col*col*(3.0-2.0*col); //saturation
    col = pow(col, vec3(0.416667))*1.055 - 0.055; //sRGB
	col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign

	fragColor = vec4( col, 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
