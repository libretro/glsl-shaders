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

//kirby jump
// fizzer 2018-01-31
// https://www.shadertoy.com/view/lt2fD3

// polynomial smooth min (from IQ)
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}


float smax(float a,float b, float k)
{
    return -smin(-a,-b,k);
}

mat2 rotmat(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float shoesDist(vec3 p)
{
    vec3 op=p;
    float d=1e4;

    p.y-=1.5;

    // right shoe
    op=p;
    p-=vec3(-.5,-.6,-.9);
    p.yz=rotmat(-.7)*p.yz;
    p.xz=rotmat(0.1)*p.xz;
    d=min(d,-smin(p.y,-(length(p*vec3(1.6,1,1))-.64),.2));
    p=op;

    // left shoe
    op=p;
    p-=vec3(.55,-.8,0.4);
    p.x=-p.x;
    p.yz=rotmat(1.4)*p.yz;
    d=min(d,-smin(p.y,-(length(p*vec3(1.6,1,1))-.73),.2));
    p=op;
    return d;
}

float sceneDist(vec3 p)
{
    vec3 op=p;
    float d=shoesDist(p);

    d=min(d,p.y);
    p.y-=1.5;

    // torso
    d=min(d,length(p)-1.);


    // left arm
    op=p;
    p-=vec3(.66,.7,0);
    p.xz=rotmat(-0.1)*p.xz;
    d=smin(d,(length(p*vec3(1.8,1,1))-.58),.07);
    p=op;

    // right arm
    op=p;
    p-=vec3(-.75,0.2,0);
    d=smin(d,(length(p*vec3(1,1.5,1))-.54),.03);
    p=op;

    // mouth
    p.y-=.11;
    float md=smax(p.z+.84,smax(smax(p.x-.2,p.y-.075,.2),dot(p,vec3(.7071,-.7071,0))-.1,.08),.04);
    p.x=-p.x;
    md=smax(md,smax(p.z+.84,smax(smax(p.x-.2,p.y-.075,.2),dot(p,vec3(.7071,-.7071,0))-.1,.08),.01),.13);
    d=smax(d,-md,.012);

    // tongue
    p=op;
    d=smin(d,length((p-vec3(0,.03,-.75))*vec3(1,1,1))-.16,.01);

    return min(d,10.);
}



vec3 sceneNorm(vec3 p)
{
    vec3 e=vec3(1e-3,0,0);
    float d = sceneDist(p);
    return normalize(vec3(sceneDist(p + e.xyy) - sceneDist(p - e.xyy), sceneDist(p + e.yxy) - sceneDist(p - e.yxy),
                          sceneDist(p + e.yyx) - sceneDist(p - e.yyx)));
}


// from simon green and others
float ambientOcclusion(vec3 p, vec3 n)
{
    const int steps = 4;
    const float delta = 0.15;

    float a = 0.0;
    float weight = 4.;
    for(int i=1; i<=steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - sceneDist(p + n*d));
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

// a re-shaped cosine, to make the peaks more pointy
float cos2(float x){return cos(x-sin(x)/3.);}

float starShape(vec2 p)
{
    float a=atan(p.y,p.x)+iGlobalTime/3.;
    float l=pow(length(p),.8);
    float star=1.-smoothstep(0.,(3.-cos2(a*5.*2.))*.02,l-.5+cos2(a*5.)*.1);
    return star;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    float an=cos(iGlobalTime)*.1;

    vec2 ot=uv*2.-1.;
    ot.y*=iResolution.y/iResolution.x;
    vec3 ro=vec3(0.,1.4,4.);
    vec3 rd=normalize(vec3(ot.xy,-1.3));

    rd.xz=mat2(cos(an),sin(an),sin(an),-cos(an))*rd.xz;
    ro.xz=mat2(cos(an),sin(an),sin(an),-cos(an))*ro.xz;

    float s=20.;

    // primary ray
    float t=0.,d=0.;
    for(int i=0;i<80;++i)
    {
        d=sceneDist(ro+rd*t);
        if(d<1e-4)
            break;
        if(t>10.)
            break;
        t+=d*.9;
    }

    t=min(t,10.0);

    // shadow ray
    vec3 rp=ro+rd*t;
    vec3 n=sceneNorm(rp);
    float st=5e-3;
    vec3 ld=normalize(vec3(2,4,-4));
    for(int i=0;i<20;++i)
    {
        d=sceneDist(rp+ld*st);
        if(d<1e-5)
            break;
        if(st>5.)
            break;
        st+=d*2.;
    }

    // ambient occlusion and shadowing
    vec3 ao=vec3(ambientOcclusion(rp, n));
    float shad=mix(.85,1.,step(5.,st));

    ao*=mix(.3,1.,.5+.5*n.y);

    // soft floor shadow
    if(rp.y<1e-3)
        ao*=mix(mix(vec3(1,.5,.7),vec3(1),.4)*.6,vec3(1),smoothstep(0.,1.6,length(rp.xz)));



    vec3 diff=vec3(1);
    vec3 emit=vec3(0);

    // skin
    diff*=vec3(1.15,.3,.41)*1.4;
    diff+=.4*mix(1.,0.,smoothstep(0.,1.,length(rp.xy-vec2(0.,1.9))));
    diff+=.5*mix(1.,0.,smoothstep(0.,.5,length(rp.xy-vec2(.7,2.5))));
    diff+=.36*mix(1.,0.,smoothstep(0.,.5,length(rp.xy-vec2(-1.1,1.8))));

    if(rp.y<1e-3)
        diff=vec3(.6,1,.6);

    // mouth
    diff*=mix(vec3(1,.3,.2),vec3(1),smoothstep(.97,.99,length(rp-vec3(0,1.5,0))));

    // shoes
    diff=mix(vec3(1.,.05,.1),diff,smoothstep(0.,0.01,shoesDist(rp)));
    diff+=.2*mix(1.,0.,smoothstep(0.,.2,length(rp.xy-vec2(-0.5,1.4))));
    diff+=.12*mix(1.,0.,smoothstep(0.,.25,length(rp.xy-vec2(0.57,.3))));

    // bounce light from the floor
    diff+=vec3(.25,1.,.25)*smoothstep(-.3,1.7,-rp.y+1.)*max(0.,-n.y)*.7;

    vec3 orp=rp;
    rp.y-=1.5;
    rp.x=abs(rp.x);

    // blushes
    diff*=mix(vec3(1,.5,.5),vec3(1),smoothstep(.1,.15,length((rp.xy-vec2(.4,.2))*vec2(1,1.65))));

    rp.xy-=vec2(.16,.45);
    rp.xy*=.9;
    orp=rp;
    rp.y=pow(abs(rp.y),1.4)*sign(rp.y);

    // eye outline
    diff*=smoothstep(.058,.067,length((rp.xy)*vec2(.9,.52)));

    rp=orp;
    rp.y+=.08;
    rp.y-=pow(abs(rp.x),2.)*16.;

    // eye reflections
    emit+=vec3(.1,.5,1.)*(1.-smoothstep(.03,.036,length((rp.xy)*vec2(.7,.3))))*max(0.,-rp.y)*10.;

    rp=orp;
    rp.y-=.12;

    // eye highlights
    emit+=vec3(1)*(1.-smoothstep(.03,.04,length((rp.xy)*vec2(1.,.48))));

    // fresnel
    diff+=pow(clamp(1.-dot(-rd,n),0.,.9),4.)*.5;

    // background and floor fade
    vec3 backg=vec3(1.15,.3,.41)*.9;
    ot.x+=.6+iGlobalTime/50.;
    ot.y+=cos(floor(ot.x*2.)*3.)*.1+.2;
    ot.x=mod(ot.x,.5)-.25;
    backg=mix(backg,vec3(1.,1.,.5),.1*starShape((ot-vec2(0.,.6))*8.)*smoothstep(9.,10.,t));
    diff=mix(diff,backg,smoothstep(.9,10.,t));

    fragColor.rgb=mix(vec3(.15,0,0),vec3(1),ao)*shad*diff*1.1;
    fragColor.rgb+=emit;
    fragColor.a = 1.0f;

    fragColor.rgb=pow(fragColor.rgb,vec3(1./2.4));
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
