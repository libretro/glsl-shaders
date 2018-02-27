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

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
#define t iGlobalTime
vec4 ot; 
float ss=.5;
float g=1.32;
vec3 CSize = vec3(1.0);
vec3 C1 = vec3(1.0);


vec3 tsqr(vec3 p) 
{
if(p.x==0. && p.y==0.)return vec3(-p.z*p.z,0.,0.);
float a=1.-p.z*p.z/dot(p.xy,p.xy);
return vec3((p.x*p.x-p.y*p.y)*a ,2.*p.x*p.y*a,2.*p.z*length(p.xy));
}

vec3 talt(vec3 z){return vec3(z.xy,-z.z);}

float map( vec3 p )
{
	float scale = 1.0;

	ot = vec4(1000.0); 

	vec3 p0=p;
	
	for( int i=0; i<8;i++ )
	{

	//BoxFold
		p = (-1.0 + 2.0*fract(0.5*p*CSize+0.5))/CSize;
        
		
	//Trap	
		float r2 = dot(p,p);
        ot = min( ot, vec4(abs(p),r2) );
		
	//SphereFold and scaling	
		
		float k = max(ss/r2,.1)*g;

		p     *= k;
		scale *= k;

	//Triplex squaring and translation 
          
            
		p = tsqr(p)-vec3(.9,0.8,.4);
        scale *= 2.*sqrt(length(p));//???   


	}
	return .10*length(p)/scale;

}

float trace( in vec3 ro, in vec3 rd )
{
	float maxd = 100.0;
	float precis = 0.001;
    float h=precis*2.0;
    float t = 0.0;
    for( int i=0; i<200; i++ )
    {

        if( abs(h)<precis*(1.+.8*t) ) continue;//break;//
        t += h;
	h = map( ro+rd*t );
    }

   	if( t>maxd ) t=-1.0;
    return t;
}

vec3 calcNormal( in vec3 pos )
{
	vec3  eps = vec3(.0001,0.0,0.0);
	vec3 nor;
	nor.x = map(pos+eps.xyy) - map(pos-eps.xyy);
	nor.y = map(pos+eps.yxy) - map(pos-eps.yxy);
	nor.z = map(pos+eps.yyx) - map(pos-eps.yyx);
	return normalize(nor);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = -1.0 + 2.0*fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;

#ifdef MOUSE
	float time = iGlobalTime*0.25 + 0.01*iMouse.x;
   

	vec2 m = (iMouse.xy/iResolution.xy-.5)*6.28;
#else
	float time = iGlobalTime*0.25 + 0.01*0.0;
   

	vec2 m = (0.0/iResolution.xy-.5)*6.28;
#endif
	m+=vec2(cos(0.15*iGlobalTime),cos(0.09*iGlobalTime));      
	
    // camera


	vec3 ta = vec3( 3.*cos(1.2+.41*time), 0.6 + 0.10*cos(0.27*time), 3.*cos(2.0+0.38*time) );
	vec3 ro = ta+ 2.*vec3( cos(m.x)*cos(m.y), sin(m.y), sin(m.x)*cos(m.y)); 
	
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(0., 1.,0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
	vec3 rd = normalize( p.x*cu + p.y*cv + 2.0*cw );


    // trace	
	vec3 col = vec3(0.0);
	float t = trace( ro, rd );
	if( t>0.0 )
	{
		vec4 tra = ot;
		vec3 pos = ro + t*rd;
		vec3 nor = calcNormal( pos );
		
		// lighting
        vec3  light1 = vec3(  0.577, 0.577, -0.577 );
        vec3  light2 = vec3( -0.707, 0.000,  0.707 );
		float key = clamp( dot( light1, nor ), 0.0, 1.0 );
		float bac = clamp( 0.2 + 0.8*dot( light2, nor ), 0.0, 1.0 );
		float amb = (0.7+0.3*nor.y);
		float ao = pow( clamp(ot.w*2.0,0.0,1.0), 1.2 );		
                vec3 brdf = vec3(ao)*(.4*amb+key+.4*bac);

        // material		
		vec3 rgb = vec3(1.0);		
		
		rgb =(0.4*abs(sin(2.5+(vec3(.5*ot.w,ot.y*ot.y,2.-ot.w))))+0.6*sin(vec3(-0.2,-0.6,0.8)+2.3+ot.x*12.5))*.75 + .15;
		rgb=mix(rgb,rgb.bgr+vec3(0.,0.1,-.2),0.4+.4*sin(5.*p.x));
		col = mix(vec3(0.9,0.8,.6),rgb*brdf,exp(-0.04*t));
		
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
