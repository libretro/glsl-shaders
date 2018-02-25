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

// Luminescence by Martijn Steinrucken aka BigWings - 2017
// countfrolic@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// My entry for the monthly challenge (May 2017) on r/proceduralgeneration 
// Use the mouse to look around. Uncomment the SINGLE define to see one specimen by itself.
// Code is a bit of a mess, too lazy to clean up. Hope you like it!

// Music by Klaus Lunde
// https://soundcloud.com/klauslunde/zebra-tribute

// YouTube: The Art of Code -> https://www.youtube.com/channel/UCcAlTqd9zID6aNX3TzwxJXg
// Twitter: @Steinrucken

#define INVERTMOUSE -1.

#define MAX_STEPS 100.
#define VOLUME_STEPS 8.
//#define SINGLE
#define MIN_DISTANCE 0.1
#define MAX_DISTANCE 100.
#define HIT_DISTANCE .01

#define S(x,y,z) smoothstep(x,y,z)
#define B(x,y,z,w) S(x-z, x+z, w)*S(y+z, y-z, w)
#define sat(x) clamp(x,0.,1.)
#define SIN(x) sin(x)*.5+.5

const vec3 lf=vec3(1., 0., 0.);
const vec3 up=vec3(0., 1., 0.);
const vec3 fw=vec3(0., 0., 1.);

const float halfpi = 1.570796326794896619;
const float pi = 3.141592653589793238;
const float twopi = 6.283185307179586;


vec3 accentColor1 = vec3(1., .1, .5);
vec3 secondColor1 = vec3(.1, .5, 1.);

vec3 accentColor2 = vec3(1., .5, .1);
vec3 secondColor2 = vec3(.1, .5, .6);

vec3 bg;	 	// global background color
vec3 accent;	// color of the phosphorecence

float N1( float x ) { return fract(sin(x)*5346.1764); }
float N2(float x, float y) { return N1(x + y*23414.324); }

float N3(vec3 p) {
    p  = fract( p*0.3183099+.1 );
	p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

struct ray {
    vec3 o;
    vec3 d;
};

struct camera {
    vec3 p;			// the position of the camera
    vec3 forward;	// the camera forward vector
    vec3 left;		// the camera left vector
    vec3 up;		// the camera up vector
	
    vec3 center;	// the center of the screen, in world coords
    vec3 i;			// where the current ray intersects the screen, in world coords
    ray ray;		// the current ray: from cam pos, through current uv projected on screen
    vec3 lookAt;	// the lookat point
    float zoom;		// the zoom factor
};

struct de {
    // data type used to pass the various bits of information used to shade a de object
	float d;	// final distance to field
    float m; 	// material
    vec3 uv;
    float pump;
    
    vec3 id;
    vec3 pos;		// the world-space coordinate of the fragment
};
    
struct rc {
    // data type used to handle a repeated coordinate
	vec3 id;	// holds the floor'ed coordinate of each cell. Used to identify the cell.
    vec3 h;		// half of the size of the cell
    vec3 p;		// the repeated coordinate
    //vec3 c;		// the center of the cell, world coordinates
};
    
rc Repeat(vec3 pos, vec3 size) {
	rc o;
    o.h = size*.5;					
    o.id = floor(pos/size);			// used to give a unique id to each cell
    o.p = mod(pos, size)-o.h;
    //o.c = o.id*size+o.h;
    
    return o;
}
    
camera cam;


void CameraSetup(vec2 uv, vec3 position, vec3 lookAt, float zoom) {
	
    cam.p = position;
    cam.lookAt = lookAt;
    cam.forward = normalize(cam.lookAt-cam.p);
    cam.left = cross(up, cam.forward);
    cam.up = cross(cam.forward, cam.left);
    cam.zoom = zoom;
    
    cam.center = cam.p+cam.forward*cam.zoom;
    cam.i = cam.center+cam.left*uv.x+cam.up*uv.y;
    
    cam.ray.o = cam.p;						// ray origin = camera position
    cam.ray.d = normalize(cam.i-cam.p);	// ray direction is the vector from the cam pos through the point on the imaginary screen
}


// ============== Functions I borrowed ;)

//  3 out, 1 in... DAVE HOSKINS
vec3 N31(float p) {
   vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

// DE functions from IQ
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( a, b, h ) + k*h*(1.0-h);
}

float sdSphere( vec3 p, vec3 pos, float s ) { return (length(p-pos)-s); }

// From http://mercury.sexy/hg_sdf
vec2 pModPolar(inout vec2 p, float repetitions, float fix) {
	float angle = twopi/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - (angle/2.)*fix;
	p = vec2(cos(a), sin(a))*r;

	return p;
}
    
// -------------------------


float Dist( vec2 P,  vec2 P0, vec2 P1 ) {
    //2d point-line distance
    
	vec2 v = P1 - P0;
    vec2 w = P - P0;

    float c1 = dot(w, v);
    float c2 = dot(v, v);
    
    if (c1 <= 0. )  // before P0
    	return length(P-P0);
    
    float b = c1 / c2;
    vec2 Pb = P0 + b*v;
    return length(P-Pb);
}

vec3 ClosestPoint(vec3 ro, vec3 rd, vec3 p) {
    // returns the closest point on ray r to point p
    return ro + max(0., dot(p-ro, rd))*rd;
}

vec2 RayRayTs(vec3 ro1, vec3 rd1, vec3 ro2, vec3 rd2) {
	// returns the two t's for the closest point between two rays
    // ro+rd*t1 = ro2+rd2*t2
    
    vec3 dO = ro2-ro1;
    vec3 cD = cross(rd1, rd2);
    float v = dot(cD, cD);
    
    float t1 = dot(cross(dO, rd2), cD)/v;
    float t2 = dot(cross(dO, rd1), cD)/v;
    return vec2(t1, t2);
}

float DistRaySegment(vec3 ro, vec3 rd, vec3 p1, vec3 p2) {
	// returns the distance from ray r to line segment p1-p2
    vec3 rd2 = p2-p1;
    vec2 t = RayRayTs(ro, rd, p1, rd2);
    
    t.x = max(t.x, 0.);
    t.y = clamp(t.y, 0., length(rd2));
                
    vec3 rp = ro+rd*t.x;
    vec3 sp = p1+rd2*t.y;
    
    return length(rp-sp);
}

vec2 sph(vec3 ro, vec3 rd, vec3 pos, float radius) {
	// does a ray sphere intersection
    // returns a vec2 with distance to both intersections
    // if both a and b are MAX_DISTANCE then there is no intersection
    
    vec3 oc = pos - ro;
    float l = dot(rd, oc);
    float det = l*l - dot(oc, oc) + radius*radius;
    if (det < 0.0) return vec2(MAX_DISTANCE);
    
    float d = sqrt(det);
    float a = l - d;
    float b = l + d;
    
    return vec2(a, b);
}


vec3 background(vec3 r) {
	
    float x = atan(r.x, r.z);		// from -pi to pi	
	float y = pi*0.5-acos(r.y);  		// from -1/2pi to 1/2pi		
    
    vec3 col = bg*(1.+y);
    
	float t = iGlobalTime;				// add god rays
    
    float a = sin(r.x);
    
    float beam = sat(sin(10.*x+a*y*5.+t));
    beam *= sat(sin(7.*x+a*y*3.5-t));
    
    float beam2 = sat(sin(42.*x+a*y*21.-t));
    beam2 *= sat(sin(34.*x+a*y*17.+t));
    
    beam += beam2;
    col *= 1.+beam*.05;

    return col;
}




float remap(float a, float b, float c, float d, float t) {
	return ((t-a)/(b-a))*(d-c)+c;
}



de map( vec3 p, vec3 id ) {

    float t = iGlobalTime*2.;
    
    float N = N3(id);
    
    de o;
    o.m = 0.;
    
    float x = (p.y+N*twopi)*1.+t;
    float r = 1.;
    
    float pump = cos(x+cos(x))+sin(2.*x)*.2+sin(4.*x)*.02;
    
    x = t + N*twopi;
    p.y -= (cos(x+cos(x))+sin(2.*x)*.2)*.6;
    p.xz *= 1. + pump*.2;
    
    float d1 = sdSphere(p, vec3(0., 0., 0.), r);
    float d2 = sdSphere(p, vec3(0., -.5, 0.), r);
    
    o.d = smax(d1, -d2, .1);
    o.m = 1.;
    
    if(p.y<.5) {
        float sway = sin(t+p.y+N*twopi)*S(.5, -3., p.y)*N*.3;
        p.x += sway*N;	// add some sway to the tentacles
        p.z += sway*(1.-N);
        
        vec3 mp = p;
    	mp.xz = pModPolar(mp.xz, 6., 0.);
        
        float d3 = length(mp.xz-vec2(.2, .1))-remap(.5, -3.5, .1, .01, mp.y);
    	if(d3<o.d) o.m=2.;
        d3 += (sin(mp.y*10.)+sin(mp.y*23.))*.03;
        
        float d32 = length(mp.xz-vec2(.2, .1))-remap(.5, -3.5, .1, .04, mp.y)*.5;
        d3 = min(d3, d32);
        o.d = smin(o.d, d3, .5);
        
        if( p.y<.2) {
             vec3 op = p;
    		op.xz = pModPolar(op.xz, 13., 1.);
            
        	float d4 = length(op.xz-vec2(.85, .0))-remap(.5, -3., .04, .0, op.y);
    		if(d4<o.d) o.m=3.;
            o.d = smin(o.d, d4, .15);
        }
    }    
    o.pump = pump;
    o.uv = p;
    
    o.d *= .8;
    return o;
}

vec3 calcNormal( de o ) {
	vec3 eps = vec3( 0.01, 0.0, 0.0 );
	vec3 nor = vec3(
	    map(o.pos+eps.xyy, o.id).d - map(o.pos-eps.xyy, o.id).d,
	    map(o.pos+eps.yxy, o.id).d - map(o.pos-eps.yxy, o.id).d,
	    map(o.pos+eps.yyx, o.id).d - map(o.pos-eps.yyx, o.id).d );
	return normalize(nor);
}

de CastRay(ray r) {
    float d = 0.;
    float dS = MAX_DISTANCE;
    
    vec3 pos = vec3(0., 0., 0.);
    vec3 n = vec3(0.);
    de o, s;
    
    float dC = MAX_DISTANCE;
    vec3 p;
    rc q;
    float t = iGlobalTime;
    vec3 grid = vec3(6., 30., 6.);
        
    for(float i=0.; i<MAX_STEPS; i++) {
        p = r.o + r.d*d;
        
        #ifdef SINGLE
        s = map(p, vec3(0.));
        #else
        p.y -= t;  // make the move up
        p.x += t;  // make cam fly forward
            
        q = Repeat(p, grid);
    	
        vec3 rC = ((2.*step(0., r.d)-1.)*q.h-q.p)/r.d;	// ray to cell boundary
        dC = min(min(rC.x, rC.y), rC.z)+.01;		// distance to cell just past boundary
        
        float N = N3(q.id);
        q.p += (N31(N)-.5)*grid*vec3(.5, .7, .5);
        
		if(Dist(q.p.xz, r.d.xz, vec2(0.))<1.1)
        //if(DistRaySegment(q.p, r.d, vec3(0., -6., 0.), vec3(0., -3.3, 0)) <1.1) 
        	s = map(q.p, q.id);
        else
            s.d = dC;
        
        
        #endif
           
        if(s.d<HIT_DISTANCE || d>MAX_DISTANCE) break;
        d+=min(s.d, dC);	// move to distance to next cell or surface, whichever is closest
    }
    
    if(s.d<HIT_DISTANCE) {
        o.m = s.m;
        o.d = d;
        o.id = q.id;
        o.uv = s.uv;
        o.pump = s.pump;
        
        #ifdef SINGLE
        o.pos = p;
        #else
        o.pos = q.p;
        #endif
    }
    
    return o;
}

float VolTex(vec3 uv, vec3 p, float scale, float pump) {
    // uv = the surface pos
    // p = the volume shell pos
    
	p.y *= scale;
    
    float s2 = 5.*p.x/twopi;
    float id = floor(s2);
    s2 = fract(s2);
    vec2 ep = vec2(s2-.5, p.y-.6);
    float ed = length(ep);
    float e = B(.35, .45, .05, ed);
    
   	float s = SIN(s2*twopi*15. );
	s = s*s; s = s*s;
    s *= S(1.4, -.3, uv.y-cos(s2*twopi)*.2+.3)*S(-.6, -.3, uv.y);
    
    float t = iGlobalTime*5.;
    float mask = SIN(p.x*twopi*2. + t);
    s *= mask*mask*2.;
    
    return s+e*pump*2.;
}

vec4 JellyTex(vec3 p) { 
    vec3 s = vec3(atan(p.x, p.z), length(p.xz), p.y);
    
    float b = .75+sin(s.x*6.)*.25;
    b = mix(1., b, s.y*s.y);
    
    p.x += sin(s.z*10.)*.1;
    float b2 = cos(s.x*26.) - s.z-.7;
   
    b2 = S(.1, .6, b2);
    return vec4(b+b2);
}

vec3 render( vec2 uv, ray camRay, float depth ) {
    // outputs a color
    
    bg = background(cam.ray.d);
    
    vec3 col = bg;
    de o = CastRay(camRay);
    
    float t = iGlobalTime;
    vec3 L = up;
    

    if(o.m>0.) {
        vec3 n = calcNormal(o);
        float lambert = sat(dot(n, L));
        vec3 R = reflect(camRay.d, n);
        float fresnel = sat(1.+dot(camRay.d, n));
        float trans = (1.-fresnel)*.5;
        vec3 ref = background(R);
        float fade = 0.;
        
        if(o.m==1.) {	// hood color
            float density = 0.;
            for(float i=0.; i<VOLUME_STEPS; i++) {
                float sd = sph(o.uv, camRay.d, vec3(0.), .8+i*.015).x;
                if(sd!=MAX_DISTANCE) {
                    vec2 intersect = o.uv.xz+camRay.d.xz*sd;

                    vec3 uv = vec3(atan(intersect.x, intersect.y), length(intersect.xy), o.uv.z);
                    density += VolTex(o.uv, uv, 1.4+i*.03, o.pump);
                }
            }
            vec4 volTex = vec4(accent, density/VOLUME_STEPS); 
            
            
            vec3 dif = JellyTex(o.uv).rgb;
            dif *= max(.2, lambert);

            col = mix(col, volTex.rgb, volTex.a);
            col = mix(col, vec3(dif), .25);

            col += fresnel*ref*sat(dot(up, n));

            //fade
            fade = max(fade, S(.0, 1., fresnel));
        } else if(o.m==2.) {						// inside tentacles
            vec3 dif = accent;
    		col = mix(bg, dif, fresnel);
            
            col *= mix(.6, 1., S(0., -1.5, o.uv.y));
            
            float prop = o.pump+.25;
            prop *= prop*prop;
            col += pow(1.-fresnel, 20.)*dif*prop;
            
            
            fade = fresnel;
        } else if(o.m==3.) {						// outside tentacles
        	vec3 dif = accent;
            float d = S(100., 13., o.d);
    		col = mix(bg, dif, pow(1.-fresnel, 5.)*d);
        }
        
        fade = max(fade, S(0., 100., o.d));
        col = mix(col, bg, fade);
        
        if(o.m==4.)
            col = vec3(1., 0., 0.);
    } 
     else
        col = bg;
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float t = iGlobalTime*.04;
    
    vec2 uv = (fragCoord.xy / iResolution.xy);
    uv -= .5;
    uv.y *= iResolution.y/iResolution.x; 
    
#ifdef MOUSE
    vec2 mouse = iMouse.xy/iResolution.xy;
    if(m.x<0.05 || m.x>.95) {				// move cam automatically when mouse is not used
    	mouse = vec2(t*.25, SIN(t*pi)*.5+.5);
    }
#else
    vec2 mouse = vec2(t*.25, SIN(t*pi)*.5+.5);
#endif
	
    accent = mix(accentColor1, accentColor2, SIN(t*15.456));
    bg = mix(secondColor1, secondColor2, SIN(t*7.345231));
    
    float turn = (.1-mouse.x)*twopi;
    float s = sin(turn);
    float c = cos(turn);
    mat3 rotX = mat3(c,  0., s, 0., 1., 0., s,  0., -c);
    
    #ifdef SINGLE
    float camDist = -10.;
    #else
    float camDist = -.1;
    #endif
    
    vec3 lookAt = vec3(0., -1., 0.);
    
    vec3 camPos = vec3(0., INVERTMOUSE*camDist*cos((mouse.y)*pi), camDist)*rotX;
   	
    CameraSetup(uv, camPos+lookAt, lookAt, 1.);
    
    vec3 col = render(uv, cam.ray, 0.);
    
    col = pow(col, vec3(mix(1.5, 2.6, SIN(t+pi))));		// post-processing
    float d = 1.-dot(uv, uv);		// vignette
    col *= (d*d*d)+.1;
    
    fragColor = vec4(col, 1.);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
