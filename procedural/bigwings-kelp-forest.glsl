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

// "Kelp Forest" by Martijn Steinrucken aka BigWings - 2016
// countfrolic@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// SONG : Hollywood Principle - Breathing Underwater (Ether Remix)

// Use these to change the effect

#define FISH_ONLY false
#define FISH true
#define KELP true
#define BUBBLES true

#define INVERTMOUSE 1.

#define MAX_STEPS 200
#define CAM_DEPTH 30.

#define S(x,y,z) smoothstep(x,y,z)
#define B(x,y,z,w) S(x-z, x+z, w)*S(y+z, y-z, w)
#define sat(x) clamp(x,0.,1.)
#define SIN(x) sin(x)*.5+.5


const vec3 lf=vec3(1., 0., 0.);
const vec3 up=vec3(0., 1., 0.);
const vec3 fw=vec3(0., 0., 1.);

const float pi = 3.141592653589793238;
const float twopi = 6.283185307179586;


vec3 bg; // global background color

float dist2(vec3 a, vec3 b) { vec3 D=a-b; return dot(D, D); } 
float L2(vec3 p) {return dot(p, p);}
float L2(vec2 p) {return dot(p, p);}

float N1( float x ) { return fract(sin(x)*5346.1764); }
float N2(float x, float y) { return N1(x + y*134.324); }

vec3 hash31(float p) {
    //  3 out, 1 in... DAVE HOSKINS
   vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}


struct ray {
    vec3 o;
    vec3 d;
};
ray e;				// the eye ray

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

float remap01(float a, float b, float t) { return (t-a)/(b-a); }


// DE functions from IQ
// https://www.shadertoy.com/view/Xds3zN

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

float fmin( float a, float b, float k, float f, float amp) {
	// 'fancy' smoothmin min.
    // inserts a cos wave at intersections so you can add ridges between two unioned objects
    
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    float scale = h*(1.0-h);
	return mix( b, a, h ) - (k+cos(h*pi*f)*amp*k)*scale;
}

float sdSphere( vec3 p, vec3 pos, float s ) { return length(p-pos)-s; }

float scaleSphere( vec3 p, vec3 scale, float s )
{
    return (length(p/scale)-s)*min(scale.x, min(scale.y, scale.z));
}

vec3 opTwist( vec3 p, float a )
{
    float  c = cos(a*p.y*pi);
    float  s = sin(a*p.y*pi);
    mat2   m = mat2(c,-s,s,c);
    
    p.xz = m*p.xz;
    return vec3(p);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

mat3 RotMat(vec3 axis, float angle)
{
    // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
}

struct de {
    // data type used to pass the various bits of information used to shade a de object
	float d;	// distance to the object
    float b;	// bump
    float m; 	// material
    float a;	// angle
    float a2;
    
    float d1, d2, d3, d4, d5;	// extra distance params you can use to color your object
    
    vec3 p;		// the offset from the object center
    
    vec3 s1;	// more data storage
};
    
struct rc {
    // data type used to handle a repeated coordinate
	vec3 id;	// holds the floor'ed coordinate of each cell. Used to identify the cell.
    vec3 h;		// half of the size of the cell
    vec3 p;		// the repeated coordinate
};
    
rc Repeat(vec3 pos, vec3 size) {
	rc o;
    o.h = size*.5;					
    o.id = floor(pos/size);			// used to give a unique id to each cell
    o.p = mod(pos, size)-o.h;
    return o;
}

float SkipCell(rc q, vec3 rd) {
	// returns a distance so that we skip the current cell and end up in the next cell
    
    vec3 r;	// ray that will bring us to the next cell
    if(rd.x<0.) r.x = -(q.p.x+q.h.x); else r.x = (q.h.x-q.p.x);
    if(rd.y<0.) r.y = -(q.p.y+q.h.y); else r.y = (q.h.y-q.p.y);
    if(rd.z<0.) r.z = -(q.p.z+q.h.z); else r.z = (q.h.z-q.p.z);
    vec3 steps = r/rd;
    
    return length(min(min(steps.x, steps.y), steps.z)*rd)+.01;// add a little bit so we for sure end up in the next cell
}

vec3 background(vec3 r) {
	float x = atan(r.x, r.z);		// from -pi to pi	
	float y = pi*0.5-acos(r.y);  		// from -1/2pi to 1/2pi		
    
    vec3 upCol = vec3(.15, .25, .6)*7.;
    
    float u = dot(r, up)*.5+.5;
    
    vec3 col = mix(upCol*.05, upCol, u*u);
    
    float t = iGlobalTime*4.;				// add god rays
    float a = sin(r.x);
    
    float beam = sat(sin(10.*x+a*y*5.+t));
    beam *= sat(sin(7.*x+a*y*3.5-t));
    
    float beam2 = sat(sin(42.*x+a*y*21.-t));
    beam2 *= sat(sin(34.*x+a*y*17.+t));
    
    beam += beam2;
    col *= 1.+beam*.03;
    
    return col;
}

float WaterSurface(vec3 r) {
    
    float u = dot(r, up);
    
    vec2 p = r.xz*(CAM_DEPTH/r.y)*3.; 
    
    float t = iGlobalTime*5.;
    
    float bump = sin(p.x*2.+t+sin(p.y*.73+t));
    bump += sin(p.x*1.43+t)*.5;
    
    bump += sin(p.x*1.21-t+sin(p.y*.3-t*.34));
    bump += sin(p.x*.43-t)*.5;
    
    bump += sin(p.y*.81-t+sin(p.x*.334-t*.34));
    bump += sin(p.y*.63-t)*.5;
    
    bump *= u*S(9., 1., u);
    bump *= S(.5, 1., u)*.05;

    return bump;
}

vec3 Caustics(vec3 p) {
    float t = iGlobalTime*2.;
    
    float s1 = sin(p.x*5.+t)*.5+.5;
    float s2 = sin(p.z*5.+t)*.5+.5;
    float s3 = sin(p.x*s1+p.z*s2*.1+t*.32)*.5+.5;
    
    float c = pow(s1*s2, 2.);
    
	return c*vec3(1., 1., .9);
}
    
vec3 Scales(vec2 uv, float seed) {
    // returns a scale info texture: x = brightness y=noise z=distance to center of scale
    vec2 uv2 = fract(uv);
    vec2 uv3 = floor(uv);
    
    float rDist = length(uv2-vec2(1., .5));
    float rMask = S(.5, .45, rDist);
    float rN = N2(uv3.x, uv3.y+seed);
    vec3 rCol = vec3(uv2.x-.5, rN, rDist);
     
    float tDist = length(uv2-vec2(.5, 1.));    
    float tMask = S(.5, .45, tDist);
    float tN = N2(uv3.x, uv3.y+seed);
    vec3 tCol = vec3(1.*uv2.x, tN, tDist);
    
    float bDist = length(uv2-vec2(.5, 0.));
    float bMask = S(.5, .45, bDist);
    float bN = N2(uv3.x, uv3.y-1.+seed);
    vec3 bCol = vec3(uv2.x, bN, bDist);
    
    float lDist = length(uv2-vec2(.0, .5));
    float lMask = S(.5, .45, lDist);
    float lN = N2(uv3.x-1., uv3.y+seed);
    vec3 lCol = vec3(uv2.x+.5, lN, lDist);
    
    vec3 col = rMask*rCol;
    col = mix(col, tCol, tMask);
    col = mix(col, bCol, bMask);
    col = mix(col, lCol, lMask);
    
    return col;
}

de Fish(vec3 p, vec3 n, float camDist) {
    // p = position of the point to be sampled
    // n = per-fish random values
    // camDist = the distance of the fish, used to scale bump effects
    
    p.z += sin(p.x-iGlobalTime*2.+n.x*100.)*mix(.15, .25, n.y);
    p.z = abs(p.z);
   
    float fadeDetail = S(25., 5., camDist);
    
    vec3 P;
    
    float dist;		// used to keep track of the distance to a certain point
    float mask;		// used to mask effects
    float r;
    vec2 dR;
    
    float bump=0.; // keeps track of bump offsets
    
    float lobe = scaleSphere(p-vec3(-1., 0., 0.25), vec3(1., 1., .5), .4);
    float lobe2 = scaleSphere(p-vec3(-1., 0., -0.25), vec3(1., 1., .5), .4);
    
    vec3 eyePos = p-vec3(-1., 0., 0.4);
    float eye = scaleSphere(eyePos, vec3(1., 1., .35), .25);
    float eyeAngle = atan(eyePos.x, eyePos.y);
    
    float snout = scaleSphere(p-vec3(-1.2, -0.2, 0.), vec3(1.5, 1., .5), .4);
    P = p-vec3(-1.2, -0.6, 0.);
    P = P*RotMat(vec3(0., 0., 1.), .35);
    float jawDn = scaleSphere(P, vec3(1., .2, .4), .6);
    float jawUp = scaleSphere(P-vec3(-0.3, 0.15, 0.), vec3(.6, .2, .3), .6);
    float mouth = fmin(jawUp, jawDn, 0.03, 5., .1);
    snout = smin(snout, mouth, 0.1);
    
    float body1 = scaleSphere(p-vec3(.6, -0., 0.), vec3(2., 1., .5), 1.);
    float body2 = scaleSphere(p-vec3(2.4, 0.1, 0.), vec3(3., 1., .4), .6); 

    P = p-vec3(-1., 0., 0.);
    
    float angle = atan(P.y, P.z);
    vec2 uv = vec2(remap01(-2., 3., p.x), (angle/pi)+.5); // 0-1
    vec2 uv2 = uv * vec2(2., 1.)*20.;
    
    vec3 sInfo = Scales(uv2, n.z);
    float scales = -(sInfo.x-sInfo.z*2.)*.01;
    scales *= S(.33, .45, eye)*S(1.8, 1.2, eye)*S(-.3, .0, p.x);
    
    // gill plates
    P = p-vec3(-.7, -.25, 0.2);
    P = P * RotMat(vec3(0., 1., 0.), .4);
    float gill = scaleSphere(P, vec3(1., .9, .15), .8);
    
    // fins
    float tail = scaleSphere(p-vec3(4.5, 0.1, 0.), vec3(1., 2., .2), .5);
    dR = (p-vec3(3.8, 0.1, 0.)).xy;
    r = atan(dR.x, dR.y);
    
    mask = B(0.45, 2.9, .2, r) * S(.2*.2, 1., L2(dR));
    
    bump += sin(r*70.)*.005*mask;
    tail += (sin(r*5.)*.03 + bump)*mask;
    tail += sin(r*280.)*.001*mask*fadeDetail;
    
    float dorsal1 = scaleSphere(p-vec3(1.5, 1., 0.), vec3(3., 1., .2), .5);
    float dorsal2 = scaleSphere(p-vec3(0.5, 1.5, 0.), vec3(1., 1., .1), .5);
    dR = (p-vec3(0.)).xy;
    r = atan(dR.x, dR.y);
    dorsal1 = smin(dorsal1, dorsal2, .1);
    
    mask = B(-.2, 3., .2, p.x);
    bump += sin(r*100.)*.003*mask;
    bump += (1.-pow(sin(r*50.)*.5+.5, 15.))*.015*mask;
    bump += sin(r*400.)*.001*mask*fadeDetail;
    dorsal1 += bump;
    
    float anal = scaleSphere(p-vec3(2.6, -.7, 0.), vec3(2., .7, .1), .5);
    anal += sin(r*300.)*.001;
    anal += sin(r*40.)*.01;
    
    
    // Arm fins
    P = p-vec3(0.7, -.6, 0.55);
    dR = (p-vec3(0.3, -.4, 0.6)).xy;
    r = atan(dR.x, dR.y);
    P = P*RotMat(lf, .2);
    P = P*RotMat(up, .2);
    mask = B(1.5, 2.9, .1, r); 			// radial mask
    mask *= S(.1*.1, .6*.6, L2(dR));			// distance mask
 	float arm = scaleSphere(P, vec3(2., 1., .2), .2);
    arm += (sin(r*10.)*.01 + sin(r*100.)*.002) * mask;
   
    // Breast fins
    P = p-vec3(0.9, -1.1, 0.2);
    P = P*RotMat(fw, .4);
    P = P*RotMat(lf, .4);
    dR = (p-vec3(0.5, -.9, 0.6)).xy;
    r = atan(dR.x, dR.y);
    mask = B(1.5, 2.9, .1, r); 			// radial mask
    mask *= S(.1*.1, .4*.4, L2(dR));
    float breast = scaleSphere(P, vec3(2., 1., .2), .2);
    breast += (sin(r*10.)*.01 + sin(r*60.)*.002)*mask;
    
    
    de f;
    f.p = p;
    f.a = angle;
    f.a2 = eyeAngle;
    f.d4 = length(eyePos);
    f.m = 1.;
    
    f.d1 = smin(lobe, lobe2, .2);												// d1 = BODY
    f.d1 = smin(f.d1, snout, .3);
    f.d1 += 0.005*(sin(f.a2*20.+f.d4)*sin(f.a2*3.+f.d4*-4.)*SIN(f.d4*10.));
    f.d1 = smin(f.d1, body1, .15);
    f.d1 = smin(f.d1, body2, .3);
    f.d1 += scales*fadeDetail;
    f.d1 = fmin(f.d1, gill, .1, 5., 0.1);
    
    float fins = min(arm, breast);
    fins = min(fins, tail);
    fins = min(fins, dorsal1);
    fins = min(fins, anal);    
        
    f.d = smin(f.d1, fins, .05);
    f.d = fmin(f.d, eye, .01, 2., 1.);
    f.d *= .8;
    
    f.d2 = dorsal1;
    f.d3 = tail;
    f.d5 = mouth;
    f.b = bump;
    
    f.s1 = sInfo;
    
    return f;
}

de Kelp(vec3 p, vec3 n) {
	de o;
    
    p = opTwist(p, floor(n.y*10.)/40.);
    o.d = udRoundBox(p, vec3(mix(.1, .7, n.x), 40., .01), .005);
    
    o.d *=.6;
    o.m=3.;
    
    return o;
}

de SmallBubbles(rc q, vec3 p, vec3 n) {
	// q = repeated coord
    // p = world pos
    // n = per-bubble random values
    
    de o;
    o.m=2.;
   
    float t = iGlobalTime*2.;
    
    n -= 0.5;
    
    float s = fract((n.x+n.y+n.z)*100.);
    s = pow(s, 4.);
    float size = mix(.05, .7, s)*.5;
    
    vec3 pos;
    
    pos.x = sin((t+n.y)*twopi*(1.-s)*3.)*n.x*s;
    
    o.d = sdSphere(q.p, pos, size);
    
    p.y += t;
    p *= 7.;
    
    n *= twopi;
    o.d += (sin(p.x+n.x+t)+sin(p.y+n.y)+sin(p.z+n.z+t))*s*.05;
    
    o.d*=.8;
    return o;
}

de map( vec3 p, vec3 rd) {
    // returns a vec3 with x = distance, y = bump, z = mat transition w = mat id
    de o;
    o.d = 1000.;
    
    float t = iGlobalTime;
    
    if(FISH_ONLY) {
       p.x += 1.5;
       o = Fish(p, vec3(0.), 0.); 
    } else {
        rc q;
        vec3 n;
        
        if(FISH) {
            q = Repeat(vec3(p.x+t, p.y, p.z), vec3(11.5, 4.5, 2.5)); // make fishies move forward
            n = hash31(q.id.x+q.id.y*123.231+q.id.z*87.342);

            float camDist = length(p);
            if(n.x>.95) 
                o = Fish(q.p, n, camDist);
            else
                o.d = SkipCell(q, rd);
        }
        
        if(KELP) {										
            q = Repeat(vec3(p.x+sin(t+p.y*.2)*.5, p.y, p.z), vec3(2., 40., 2.)); // make kelp sway
            n = hash31(q.id.x+q.id.z*765.);

            de kelp;
            if(n.z*S(7., 10., length(q.id)) > .9)
                kelp = Kelp(q.p, n);
            else 
                kelp.d = SkipCell(q, rd);

            if(kelp.d<o.d) o=kelp;
        }
        
        if(BUBBLES) {										// Map kelp
            p.y -= t*4.;			// sway with the water
			
            p.y += 40.;
            q = Repeat(p, vec3(4., 4., 4.));
            n = hash31(q.id.x+q.id.y*1234.5234+q.id.z*765.);
			
            de bubbles;
            if(n.z*S(2., 5., length(q.id)) > .95)
                bubbles = SmallBubbles(q, p, n);
            else 
                bubbles.d = SkipCell(q, rd);

            if(bubbles.d<o.d) o=bubbles;
        }
        
    }
    
    return o;
    
}

de map( in vec3 p){return map(p, vec3(1.));}

de castRay( in vec3 ro, in vec3 rd ) {
    // returns a distance and a material id
    
    float dmin = 1.0;
    float dmax = 100.0;
    
	float precis = 0.002;
    
    de o;
    o.d = dmin;
    o.m = -1.0;
    
    for( int i=0; i<MAX_STEPS; i++ )
    {
	    de res = map( ro+rd*o.d, rd );
        if( res.d<precis || o.d>dmax ) break;
        
        float d = o.d;
        o = res;
        o.d += d;
    }

    if( o.d>dmax ) o.m=-1.0;
    
    return o;
}

float calcAO( in vec3 pos, in vec3 nor ) {
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<4; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos, nor ).d;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 calcNormal( in vec3 pos )
{
	vec3 eps = vec3( 0.001, 0.0, 0.0 );
	vec3 nor = vec3(
	    map(pos+eps.xyy).d - map(pos-eps.xyy).d,
	    map(pos+eps.yxy).d - map(pos-eps.yxy).d,
	    map(pos+eps.yyx).d - map(pos-eps.yyx).d );
	return normalize(nor);
}


vec3 FishMaterial(de o, vec3 nor, float fresnel, float spec, float occ, vec3 amb, vec3 ref, float u, vec3 pos) {
   vec3 finCol = vec3(1., .5, .25);
        
        float dorsalMask = (1.-sat(o.d2*15.))*B(-.3, 3., .1, o.p.x);
        float finMask = o.d1*2.;
        float spikeMask = pow(o.b*50., 2.);
        float dorsalTrans = sat(finMask*spikeMask*dorsalMask*3.);
        float tailMask = S(3.8, 5.2, o.p.x);
        float tailTrans = tailMask*(1.-pow(max(1.-(o.b*100.+0.5), 0.), 3.));
        float translucency = (dorsalTrans+tailTrans+o.d1*3.);
        translucency *= u+.2;
        
        float bodyMask = sat(1.-(o.d1-.01)*50.);
        vec3 topCol = vec3(.5, .5, .5);
        vec3 bottomCol = vec3(1.3);
        float w = sin(o.p.x*5.)*.1;
 		vec3 bodyCol = mix(topCol, bottomCol, S(.4, -.2, o.p.y)+(o.s1.y-.5)*.5);
        
        float camo = SIN(o.d4*5.);
        camo *= SIN(o.d2*10.);
        
        float headMask = S(.8, 1., o.d3);
        vec3 headCol = mix(vec3(1.2), topCol,  S(0., .5, o.d4)*S(1.1, .5, o.d4));
        headCol += 0.1*(sin(o.a2*20.+o.d4)*sin(o.a2*3.+o.d4*-4.)*SIN(o.d4*10.));
        
        headCol += (1.-fresnel)*ref.b*.2;
        vec3 mouthCol = vec3(1.3);
        headCol = mix(headCol, mouthCol, (1.-S(.0, .2, o.d5)));
        
    	vec3 col = vec3(1.);
        col = mix(col, col*mix(bodyCol, headCol, headMask), bodyMask);
        col *= camo*.5+.5;
        
       	vec3 eyeColor = vec3(.8, .6, .2);
        eyeColor += sin(o.a2*2.*pi+.345)*sin(o.a2*pi)*.1;
       
        float eyeMask = S(.27, .25, o.d4);
        eyeColor *= S(.13, .15, o.d4);
        eyeColor *= S(.25, .19, o.d4)+.25;
        eyeColor += spec;
        
        col = mix(col, eyeColor, eyeMask);
        
        vec3 ambient = mix(amb, vec3(occ), .5);   
        col *= ambient;
        
        col = mix(col, bg*finCol, translucency);	// add light through fins
        
        float dif = clamp( dot( nor, up ), 0., 1.0 );
        col += Caustics(pos)*dif*S(-20., 1., pos.y);
    
    return col;
}

vec3 BubbleMaterial(de o, float fresnel, float spec, vec3 ref) {
    vec3 col = ref;
    
    return col;
}

vec3 KelpMaterial(de o, float fresnel, vec3 amb, vec3 ref, float u, vec3 pos) {
	vec3 kelpColor = vec3(1., .5, .2);
    vec3 col = amb;
    vec3 transColor = kelpColor*bg*1.3;
    col = mix(col, transColor, fresnel);
    col += Caustics(pos)*.2;
    col *= sat(u*2.);
    
    return col;
}


vec4 render( in vec3 ro, in vec3 rd, float depth ) {
    // outputs a color
    
    vec3 col = vec3(0.);
    de o = castRay(ro,rd);

    vec3 pos = ro + o.d*rd;
    vec3 nor = calcNormal( pos );
    vec3 r = reflect( rd, nor );
    vec3 amb = background(nor);		// the background in the direction of the normal
    vec3 ref = background(r);		// the background in the direction of the reflection vector

    float fresnel = sat(dot(rd, -nor));

    float occ = calcAO( pos, nor );
    float lookUp = dot(rd, up)*.5+.5;		// 1 when looking straight up, 0 when looking straight down

    float spec = pow(sat(dot(r, up)), 20.);
   
    
    if( o.m==1. )
        col = FishMaterial(o, nor, fresnel, spec, occ, amb, ref, lookUp, pos);
    else if(o.m==2.)
    	col = BubbleMaterial(o, fresnel, spec, ref);
    else if(o.m==3.)
       col = KelpMaterial(o, fresnel, amb, ref, lookUp, pos);
    
    
    float backContrast = max(S(.9, .70, lookUp), S(30., 25., o.d)); 
    col *= backContrast;
    
    float fog = S(0., 60., o.d);
    col = mix(col, bg, fog);

    return vec4( col, o.m );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy / iResolution.xy) - 0.5;
   	uv.y *= iResolution.y/iResolution.x;
#ifdef MOUSE
    vec2 mouse = iMouse.xy/iResolution.xy;
    if(mouse.x==0. &&mouse.y==0.) mouse = vec2(.96, .6);
#else
    vec2 mouse = vec2(.96, .6);
#endif
	float t = iGlobalTime;
    
    float turn = (.1-mouse.x)*twopi;
    float s = sin(turn);
    float c = cos(turn);
    mat3 rotX = mat3(	  c,  0., s,
                   		  0., 1., 0.,
                   		  s,  0., -c);
    
    vec3 camPos = vec3(0., 0., 0.);
    vec3 pos = vec3(0., INVERTMOUSE*10.*cos((mouse.y)*pi), -10.)*rotX;
   	
    CameraSetup(uv, camPos+pos, camPos, 1.);
    
    bg = background(cam.ray.d);

    vec4 info = render(cam.ray.o, cam.ray.d, 0.);
  
    vec3 col;
    if(info.w==-1.) 
        col = bg+WaterSurface(cam.ray.d); 
    else 
        col = info.rgb;
    
    fragColor = vec4(col, .1);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
