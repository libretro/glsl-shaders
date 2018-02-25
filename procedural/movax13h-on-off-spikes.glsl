#version 120
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

// On/Off Spikes, fragment shader by movAX13h, oct 2014

#define HARD_SHADOW
#define GLOW
#define EDGES
#define NUM_TENTACLES 6
#define BUMPS
#define NUM_BUMPS 8
#define BACKGROUND
#define SUN_POS vec3(15.0, 15.0, -15.0)
//#define SUN_SPHERE

#define SPHERE_COL vec3(0.6, 0.3, 0.1)
#define MOUTH_COL vec3(0.9, 0.6, 0.1)
#define TENTACLE_COL vec3(0.06)

#define GAMMA 2.2

//---
#define resolution iResolution
#define mouse iMouse
#define pi2 6.283185307179586476925286766559
#define pih 1.5707963267949

// Using the nebula function of the "Star map shader" by morgan3d 
// as environment map and light sphere texture (https://www.shadertoy.com/view/4sBXzG)
const float pi= 3.1415927;const int NUM_OCTAVES = 4;float hash(float n) { return fract(sin(n) * 1e4); } float hash(vec2 p){return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 +p.x))));}float noise(float x) { float i = floor(x);float f = fract(x); float u = f * f * (3.0 - 2.0 * f);return mix(hash(i),hash(i+1.0),u);}float noise(vec2 x){vec2 i=floor(x);vec2 f=fract(x);	float a = hash(i); float b=hash(i + vec2(1.0,0.0));float c=hash(i+vec2(0.0, 1.0)); float d = hash(i + vec2(1.0, 1.0)); vec2 u = f * f * (3.0 - 2.0 * f); return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y; }float NOISE(vec2 x){ float v = 0.0; float a = 0.5; vec2 shift=vec2(100);mat2 rot=mat2(cos(0.5),sin(0.5), -sin(0.5), cos(0.50)); for (int i = 0; i < NUM_OCTAVES;++i) {v+=a*noise(x);x = rot* x * 2.0 + shift; a *= 0.5; } return v; }float square(float x) { return x * x;}mat3 rotation(float yaw, float pitch){return mat3(cos(yaw),0,-sin(yaw), 0, 1, 0, sin(yaw), 0, cos(yaw)) * mat3(1, 0, 0, 0, cos(pitch), sin(pitch), 0, -sin(pitch), cos(pitch)); }vec3 nebula(vec3 dir) { float purple = abs(dir.x); float yellow = noise(dir.y);vec3 streakyHue = vec3(purple + yellow, yellow * 0.7, purple);vec3 puffyHue = vec3(0.8, 0.1, 1.0);float streaky = min(1.0, 8.0 * pow(NOISE(dir.yz*square(dir.x) * 13.0+ dir.xy * square(dir.z) * 7.0 + vec2(150.0, 2.0)),10.0));float puffy=square(NOISE(dir.xz * 4.0 + vec2(30, 10)) * dir.y);
return pow(clamp(puffyHue * puffy * (1.0 - streaky) + streaky * streakyHue, 0.0, 1.0), vec3(1.0/2.2));}
// ---

float sdBox( vec3 p, vec3 b ) 
{	
	vec3 d = abs(p) - b;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdSphere(vec3 p, float r)
{
	return length(p)-r;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xy),p.z)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 rotate(vec2 p, float a)
{
	vec2 r;
	r.x = p.x*cos(a) - p.y*sin(a);
	r.y = p.x*sin(a) + p.y*cos(a);
	return r;
}

// polynomial smooth min (k = 0.1); by iq
float smin(float a, float b, float k)
{
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

// globals
float glow, bite;
vec3 sphere_col;
vec3 sun = normalize(SUN_POS);
float focus = 5.0;
float far = 23.0;

struct Hit
{
	float d;
	vec3 color;
	float edge;
};

Hit scene(vec3 p)
{
	float d, d1, d2, d3, f, e = 0.15;
	
	vec3 q = p;
	q.xy = rotate(q.xy, 1.5);
	
	// center sphere
	d1 = sdSphere(q, 0.3);
	d = d1; 
    vec3 col = sphere_col; 
    
	// tentacles
	float r = length(q);
	float a = atan(q.z, q.x);
	a += 0.4*sin(r-iGlobalTime);
	
	q = vec3(a*float(NUM_TENTACLES)/pi2,q.y,length(q.xz)); // circular domain
	q = vec3(mod(q.x,1.0)-0.5*1.0,q.y,q.z); // repetition
	
	d3 = sdCappedCylinder(q-vec3(0.0,0.0,0.9+bite), vec2(0.1-(r-bite)/18.0,0.8));
	d2 = min(d3, sdBox(q-vec3(0.0, 0.0, 0.1+bite), vec3(0.2, 0.2, 0.2))); // close box
	d2 = smin(d2, sdBox(q-vec3(0.0, 0.0, 0.4+bite), vec3(0.2, 0.05, 0.4)), 0.1); // wide box
	
    f = smoothstep(0.11, 0.28, d2-d1);
	col = mix(MOUTH_COL, col, f);
	e = mix(e, 0.0, f);
	d = smin(d1, d2, 0.24);
    
	col = mix(TENTACLE_COL, col, smoothstep(0., 0.48, d3-d));
	
    #ifdef SUN_SPHERE
	d = min(d, sdSphere(p-sun, 0.1));
    #endif
    
	#ifdef BUMPS
	for(int i = 0; i < NUM_BUMPS; i++)
	{
        d2 = float(i);
        d1 = sdSphere(p-0.18*smoothstep(0.1, 1.0, glow)*
                      vec3(sin(4.0*iGlobalTime+d2*0.6), sin(5.3*iGlobalTime+d2*1.4), cos(5.8*iGlobalTime+d2*0.6)),
                      0.03);
		
		d = smin(d1, d, 0.2);
		//d = min(d1, d);
	}
	#endif
	
	#ifdef BACKGROUND
	q = p;
	q.yz = mod(q.yz, 1.0);
	q -= vec3(-.6, 0.5, 0.5);
	d1 = sdBox(q, vec3(0.1, 0.48, 0.48));
	if (d1 < d) { d = d1; col = vec3(0.1); }
	#endif
	
	return Hit(d, col, e);
}

vec3 normal(vec3 p)
{
	float c = scene(p).d;
	vec2 h = vec2(0.01, 0.0);
	return normalize(vec3(scene(p + h.xyy).d - c, 
						  scene(p + h.yxy).d - c, 
		                  scene(p + h.yyx).d - c));
}

float edges(vec3 p) // by srtuss
{
	float acc = 0.0;
	float h = 0.01;
	acc += scene(p + vec3(-h, -h, -h)).d;
	acc += scene(p + vec3(-h, -h, +h)).d;
	acc += scene(p + vec3(-h, +h, -h)).d;
	acc += scene(p + vec3(-h, +h, +h)).d;
	acc += scene(p + vec3(+h, -h, -h)).d;
	acc += scene(p + vec3(+h, -h, +h)).d;
	acc += scene(p + vec3(+h, +h, -h)).d;
	acc += scene(p + vec3(+h, +h, +h)).d;
	return acc / h;
}

vec3 colorize(Hit hit, vec3 n, vec3 dir, const in vec3 lightPos)
{
	float diffuse = 0.3*max(0.0, dot(n, lightPos));
	
	vec3 ref = normalize(reflect(dir, n));
	float specular = 0.4*pow(max(0.0, dot(ref, lightPos)), 6.5);

	return (hit.color.rgb + 
			diffuse * vec3(0.9) +
			specular * vec3(1.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    //time = iGlobalTime;
    glow = max(0.0, min(1.0, 2.0*sin(iGlobalTime*0.7-5.0)));
    bite = smoothstep(0.0, 1.0, 1.6*sin(iGlobalTime*0.7));
    sphere_col = SPHERE_COL*glow;

    
    vec2 pos = (fragCoord.xy*2.0 - resolution.xy) / resolution.y;
	
	float d = clamp(1.5*sin(0.3*iGlobalTime), 0.5, 1.0);
	vec3 cp = vec3(10.0*d, -2.3*d, -6.2*d+4.0*clamp(2.0*sin(iGlobalTime*0.5), 0.0, 1.0)); // anim curious spectator
	
#ifdef MOUSE
	if (mouse.z > 0.5)
	{
		vec2 mrel = mouse.xy/resolution.xy-0.5;
		float mdis = (8.0+6.0*mrel.y);
		cp = vec3(mdis*cos(-mrel.x*pih), 4.0*mrel.y, mdis*sin(-mrel.x*pih));
	}
#endif
	
    vec3 ct = vec3(0.0, 0.0, 0.0);
   	vec3 cd = normalize(ct-cp);
    vec3 cu  = vec3(0.0, 1.0, 0.0);
    vec3 cs = cross(cd, cu);
    vec3 dir = normalize(cs*pos.x + cu*pos.y + cd*focus);	
	
    Hit h;
	vec3 col = vec3(0.16);
	vec3 ray = cp;
	float dist = 0.0;
	
	// raymarch scene
    for(int i=0; i < 60; i++) 
	{
        h = scene(ray);
		
		if(h.d < 0.0001) break;
		
		dist += h.d;
		ray += dir * h.d * 0.9;

        if(dist > far) 
		{ 
			dist = far; 
			break; 
		}
    }

	float m = (1.0 - dist/far);
	vec3 n = normal(ray);
	col = colorize(h, n, dir, sun)*m;

    #ifdef EDGES
	float edge = edges(ray);
	col = mix(col, vec3(0.0), h.edge*edge*smoothstep(0.3, 0.35, length(ray)));
    #endif
    
	vec3 neb = nebula(n);
	col += min(glow, 0.1)*neb.brg;
	
	// HARD SHADOW with low number of rm iterations (from obj to sun)
	#ifdef HARD_SHADOW
	vec3 ray1 = ray;
	dir = normalize(SUN_POS - ray1);
	ray1 += n*0.002;
	
	float sunDist = length(SUN_POS-ray1);
	dist = 0.0;
	
	for(int i=0; i < 35; i++) 
	{
		h = scene(ray1 + dir*dist);
		dist += h.d;
		if (abs(h.d) < 0.001) break;
	}

	col -= 0.24*smoothstep(0.5, -0.3, min(dist, sunDist)/max(0.0001,sunDist));
	#endif
	
	// ILLUMINATION & free shadow with low number of rm iterations (from obj to sphere)
	#ifdef GLOW
	dir = normalize(-ray);
	ray += n*0.002;
	
	float sphereDist = max(0.0001, length(ray)-0.3);
	dist = 0.0;
	
	for(int i=0; i < 35; i++) 
	{
		h = scene(ray + dir*dist);
		dist += h.d;
		if (abs(h.d) < 0.001) break;
	}
	
	vec3 neb1 = nebula(dir*rotation(0.0, iGlobalTime*0.4)).brg;
    
	col += (0.7*sphere_col+glow*neb1)*(0.6*(smoothstep(3.0, 0.0, sphereDist))*min(dist, sphereDist)/sphereDist + 
		   0.6*smoothstep(0.1, 0.0, sphereDist));
	#endif
    
	col -= 0.2*smoothstep(0.6,3.7,length(pos));
	col = clamp(col, vec3(0.0), vec3(1.0));
	col = pow(col, vec3(2.2, 2.4, 2.5)) * 3.9;
	col = pow(col, vec3(1.0 / GAMMA));
    
	fragColor = vec4(col, 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
