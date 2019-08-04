// Parameter lines go here:
#pragma parameter frameShape "Border mask shape" 0.35 0.0 1.0 0.01
#pragma parameter frameLimit "Border mask limit" 0.30 0.0 1.0 0.01
#pragma parameter frameSharpness "Border mask sharpness" 1.10 0.0 4.0 0.01
#pragma parameter TVNoise "PAL signal modulation + noise" 1.0 0.0 1.0 1.0
#pragma parameter PALSignal "PAL signal simulation" 1.0 0.0 1.0 1.0
#pragma parameter phosphors "Phosphor mask" 1.0 0.0 1.0 1.0
#pragma parameter border "Border mask" 1.0 0.0 1.0 1.0

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

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float frameShape;
uniform COMPAT_PRECISION	float frameLimit;
uniform COMPAT_PRECISION	float frameSharpness;
uniform COMPAT_PRECISION    float TVNoise;
uniform COMPAT_PRECISION    float PALSignal;
uniform COMPAT_PRECISION    float phosphors;
uniform COMPAT_PRECISION    float border;
#else
#define frameShape 0.35
#define frameLimit 0.30
#define frameSharpness 1.10
#define TVNoise 1.0
#define PALSignal 1.0
#define phosphors 1.0
#define border 1.0
#endif

float f(float e){vec2 f=vec2(e,e);float v=12.9898,r=78.233,t=43758.5,S=dot(f.rg,vec2(v,r)),b=mod(S,3.14);return fract(sin(b)*t);}vec2 e(vec2 e){return e=(e-.5)*2.,e*=1.1,e.r*=1.+pow(abs(e.g)/5.,2.),e.g*=1.+pow(abs(e.r)/4.,2.),e=e/2.+.5,e=e*.92+.04,e;}void main(){vec2 v=vTexCoord.rg*TextureSize.rg/InputSize.rg,r=v;r=mix(r,e(r),1.)*InputSize.rg/TextureSize.rg;vec4 c=vec4(0.);vec2 m=r,t=m;mat3 b=mat3(.299,-.147,.615,.587,-.289,-.515,.114,.436,-.1),g=mat3(1.,1.,1.,0.,-.395,2.032,1.14,-.581,0.);float F=1.;if(TVNoise==1.)F-=f(m.r*FrameCount*.1+m.g*FrameCount*50.+FrameCount)*.5;if(PALSignal==1.){vec3 i=vec3(0.);float O=.3,S=-.002;for(int a=10;a>=0;a-=1){float s=float(a)/10.;if(s<0.)s=0.;float p=s*-.05*O+S,l=s*.1*O+S;vec3 T=(vec3(1.)-pow(vec3(s),vec3(.2,1.,1.)))*.2;vec2 o=t+vec2(p,0.),u=t+vec2(l,0.);i+=b*texture(Source,o).rgb*T;i+=b*texture(Source,u).rgb*T;}i.r=i.r*.2+(b*texture(Source,t).rgb).r*.8;c.rgb=g*i*F;}else c.rgb=texture(Source,t).rgb;if(phosphors==1.){float S=v.g*OutputSize.g*OutputSize.g/OutputSize.g;vec3 s=mix(vec3(1.,.7,1.),vec3(.7,1.,.7),floor(mod(S,2.)));c.rgb*=s;}if(border==1.){vec2 s=-1.+2.*v;float S=(1.-s.r*s.r)*(1.-s.g*s.g),u=clamp(frameSharpness*(pow(S,frameShape)-frameLimit),0.,1.);c.rgb*=u;}FragColor=vec4(c.rgb,1.);}


#endif

