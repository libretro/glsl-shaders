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

float time;

// ******* Tools  ******* 

vec3 rotate(vec3 r, float v){ return vec3(r.x*cos(v)+r.z*sin(v),r.y,r.z*cos(v)-r.x*sin(v));}

float box( vec3 p, vec3 b ){ 
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0)+length(max(d,0.0));
}

float sphere( vec3 p, float r ){
    return r-length(p);
}

float rand2d(vec2 n){ 
  return fract(sin(dot(n,vec2(12.9898,4.1414))) * 43758.5453);
}

float noise2d(vec2 n){
  vec2 b = floor(n);
  vec2 f = smoothstep(vec2(0.0,0.0),vec2(1.0,1.0),fract(n));
  return mix(mix(rand2d(b),rand2d(b+vec2(1.0,0.0)),f.x),mix(rand2d(b+vec2(0.0,1.0)),rand2d(b+vec2(1.0,1.0)),f.x),f.y);
}

// ******* Scene  ******* 

vec3 path(float t){
	t += 6.0;
    return vec3(sin(t*-0.2)*200.0,sin(t*0.053)*300.0-470.0,sin(t*0.13)*400.0+3.2);
}

vec3 env(vec3 r){
    return mix(vec3(0.05,0.08,0.15),vec3(0.41,0.45,0.45),pow(0.6+sin(r.y)*0.4,4.0));
}

float terrain(vec3 pos){ 

    pos = rotate(pos,time*0.01);
    float  n1 = noise2d(pos.xz*0.1+pos.z*0.1);
    float  p1 =  pos.y - 500.0;
    float  s1 =  450.0 + pos.y + sin(pos.x*0.01)*30.0 - abs(pos.z*0.2) - n1*10.0;
    
    vec3 pp =   abs(pos) -120.0; 
         pp =   abs(pp)  -120.0; 
         pp =   abs(pp)  -120.0; 
           
    float p2 = 8.0 - box(pp+vec3(0.0,0.0,30.0),   vec3(10.0,115.0,10.0)); 
    float p3 = 1.0 - box(pp+vec3(0.0,0.0,0.0),    vec3(110.0,3.0,115.0))-sin(n1*10.)*0.1; 
    float p4 = 1.0 - box(pp+vec3(0.0,0.0,30.0),   vec3(120.0,6.0,10.0));
    float p5 = 1.0 - box(pp+vec3(-120.0,20.0,0.0),vec3(2.0,80.0,120.0));
    float p6 = 1.0 - box(pp+vec3(0.0,20.0,-120.0),vec3(120.0,40.0,2.0));
    float p7 = 1.0 - box(pp+vec3(70.0,0.0,-130.0),vec3(2.0,120.0,2.0));

    float c1 = sphere(pos,300.0)+n1*10.0 -sin(pos.y*0.01)*10.0;
    float c2 = sphere(pos+vec3(0.0,300.0+sin(time*0.3)*50.0,00.0),120.0)+n1*5.0*sin(time*2.0+pos.z*0.01);
    
    float s = min(max(min(min(max(max(max(max(max(max(p2,p3),p4),p1),p5),p6),p7),-c1),-c2-50.0),c2),s1);

	return s;
}


// ******* Main  ******* 

float test = 0.0;
float tran = 0.0;
vec3  pos = vec3(0.0);

void raymarch(vec3 p,vec3 r){
    test = 0.0;
    tran = 0.0;
	pos  = p;
    for(int i=0;i<40;i++){
        test  = terrain(pos); 
        pos  += r*test;
        tran += test;
        if(abs(test)<=0.01){ break; }
    }
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
 
    time        = iGlobalTime*2.0;
    float pulse	= pow(max(sin(time*0.5),0.0)*0.98,50.0);
	
	vec2 uv     = fragCoord.xy/(iResolution.xx*0.5)-vec2(1.0,iResolution.y/iResolution.x);
    vec3 ray1   = normalize(vec3(uv.x,uv.y,0.5));   
#ifdef MOUSE
    vec3 campos = path(time)+vec3(iMouse.x,-50.0+iMouse.y,500.0+sin(time*0.02)*400.0);
#else
    vec3 campos = path(time)+vec3(0.0,-50.0+0.0,500.0+sin(time*0.02)*400.0);
#endif
    vec3 lightpos = path(time+0.5);
    
	
    // Surface
    raymarch(campos + ray1*-10.0, ray1);
    float test1 = test;
    float tran1 = tran; 
    vec3  pos1  = pos;

    // Shadow
	vec3  ray2   = normalize(pos1-lightpos);
    raymarch(pos1+ray1,ray2);
    float test2  = test;
    float tran2  = tran; 
    vec3  pos2   = pos;
    float dist   = distance(lightpos,pos1);
	float dist2  = distance(lightpos,campos);

    // Normal
    vec3  axe = vec3(0.1,0.0,0.0);
    vec3  nor = normalize(vec3( test1-terrain(pos1-axe.xyy) , test1-terrain(pos1-axe.yxy) , test1-terrain(pos1-axe.yyx) ) ); 
    float ang = max(0.0,dot(nor,-ray1)); 
    
    // Shade
    float bkg = smoothstep(4000.0,0.0,distance(campos,pos1));    
    float ocl = min(smoothstep(0.0,80.0,test1-terrain(pos1-nor*20.0)),pow(smoothstep(0.0,1000.0,test1-terrain(pos1-nor*200.0)),1.0))*bkg;  
    float sha = smoothstep(-50.0,0.0,abs(tran2)-dist)*pow(smoothstep(2000.0+pulse*1000.0,0.0,dist),20.0)*bkg;    
   
	float fog = noise2d(ray1.xy*3.0+campos.xz*0.001+vec2(0.0,-time*0.2));
	float mtr = noise2d(pos1.xz*0.5+pos1.y)*1.0;
	
    float dif = smoothstep(0.0,1.0,ang)*sha; 
    float spc = smoothstep(0.8,1.0,ang)*sha; 
   
    vec3  col  = mix(env(ray1)*0.3,(0.01+mtr*0.1+env(nor))*pow(ocl,0.6),bkg);
          col += (vec3(1.70,1.65,1.60)+mtr*0.3)*dif;
          col += (vec3(0.80,0.80,0.70)+mtr*0.3)*spc;
    
	
    // Fake some visible light
	float lightdist = smoothstep(200.0+pulse*400.0,0.0,length(cross(ray1,lightpos-campos)));
    float lightdepth = smoothstep(10.0,-100.0,tran1+dist2); 
	float l = pow(lightdist,20.0)*lightdepth;
		  l += fog*0.2*lightdist*lightdepth + fog*0.01;
	
    fragColor = vec4(sqrt(col+l)-dot(uv,uv)*0.12,1.0);

}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
