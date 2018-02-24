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

// Industry -  srtuss - 2013-07-06
// https://www.shadertoy.com/view/Msf3D7

// Me beeing creative in 2D ;)
// Its a work in progress, but you guys might still enjoy it.

// by srtuss, 2013
// a little expression of my love for complex machines and stuff
// was going for some cartoonish 2d look
// still could need some optimisation

// * improved gears
// * improved camera movement

float hash(float x)
{
	return fract(sin(x) * 43758.5453);
}

vec2 hash(vec2 p)
{
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// simulates a resonant lowpass filter
float mechstep(float x, float f, float r)
{
	float fr = fract(x);
	float fl = floor(x);
	return fl + pow(fr, 0.5) + sin(fr * f) * exp(-fr * 3.5) * r;
}

// voronoi cell id noise
vec3 voronoi(in vec2 x)
{
	vec2 n = floor(x);
	vec2 f = fract(x);

	vec2 mg, mr;
	
	float md = 8.0;
	for(int j = -1; j <= 1; j ++)
	{
		for(int i = -1; i <= 1; i ++)
		{
			vec2 g = vec2(float(i),float(j));
			vec2 o = hash(n + g);
			vec2 r = g + o - f;
			float d = max(abs(r.x), abs(r.y));
			
			if(d < md)
			{
				md = d;
				mr = r;
				mg = g;
			}
		}
	}
	
	return vec3(n + mg, mr);
}

vec2 rotate(vec2 p, float a)
{
	return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

float stepfunc(float a)
{
	return step(a, 0.0);
}

float fan(vec2 p, vec2 at, float ang)
{
	p -= at;
	p *= 3.0;
	
	float v = 0.0, w, a;
	float le = length(p);
	
	v = le - 1.0;
	
	if(v > 0.0)
		return 0.0;
	
	a = sin(atan(p.y, p.x) * 3.0 + ang);
	
	w = le - 0.05;
	v = max(v, -(w + a * 0.8));
	
	w = le - 0.15;
	v = max(v, -w);
	
	return stepfunc(v);
}

float gear(vec2 p, vec2 at, float teeth, float size, float ang)
{
	p -= at;
	float v = 0.0, w;
	float le = length(p);
	
	w = le - 0.3 * size;
	v = w;
	
	w = sin(atan(p.y, p.x) * teeth + ang);
	w = smoothstep(-0.7, 0.7, w) * 0.1;
	v = min(v, v - w);
	
	w = le - 0.05;
	v = max(v, -w);
	
	return stepfunc(v);
}

float car(vec2 p, vec2 at)
{
	p -= at;
	float v = 0.0, w;
	w = length(p + vec2(-0.05, -0.31)) - 0.03;
	v = w;
	w = length(p + vec2(0.05, -0.31)) - 0.03;
	v = min(v, w);
	
	vec2 box = abs(p + vec2(0.0, -0.3 - 0.07));
	w = max(box.x - 0.1, box.y - 0.05);
	v = min(v, w);
	return stepfunc(v);
}

float layerA(vec2 p, float seed)
{
	float v = 0.0, w, a;
	
	float si = floor(p.y);
	float sr = hash(si + seed * 149.91);
	vec2 sp = vec2(p.x, mod(p.y, 4.0));
	float strut = 0.0;
	strut += step(abs(sp.y), 0.3);
	strut += step(abs(sp.y - 0.2), 0.1);
	
	float st = iGlobalTime + sr;
	float ct = mod(st * 3.0, 5.0 + sr) - 2.5;
	
	v = step(2.0, abs(voronoi(p + vec2(0.35, seed * 194.9)).x));
	
	w = length(sp - vec2(-2.0, 0.0)) - 0.8;
	v = min(v, 1.0 - step(w, 0.0));
	
	
	a = st;
	w = fan(sp, vec2(2.5, 0.65), a * 40.0);
	v = min(v, 1.0 - w);
	
	
	return v;
}

float layerB(vec2 p, float seed)
{
	float v = 0.0, w, a;
	
	float si = floor(p.y / 3.0) * 3.0;
	vec2 sp = vec2(p.x, mod(p.y, 3.0));
	float sr = hash(si + seed * 149.91);
	sp.y -= sr * 2.0;
	
	float strut = 0.0;
	strut += step(abs(sp.y), 0.3);
	strut += step(abs(sp.y - 0.2), 0.1);
	
	float st = iGlobalTime + sr;
	
	float cs = 2.0;
	if(hash(sr) > 0.5)
		cs *= -1.0;
	float ct = mod(st * cs, 5.0 + sr) - 2.5;

	
	v = step(2.0, abs(voronoi(p + vec2(0.35, seed * 194.9)).x) + strut);
	
	w = length(sp - vec2(-2.3, 0.6)) - 0.15;
	v = min(v, 1.0 - step(w, 0.0));
	w = length(sp - vec2(2.3, 0.6)) - 0.15;
	v = min(v, 1.0 - step(w, 0.0));
	
	if(v > 0.0)
		return 1.0;
	
	
	w = car(sp, vec2(ct, 0.0));
	v = w;
	
	if(hash(si + 81.0) > 0.5)
		a = mechstep(st * 2.0, 20.0, 0.4) * 3.0;
	else
		a = st * (sr - 0.5) * 30.0;
	w = gear(sp, vec2(-2.0 + 4.0 * sr, 0.5), 8.0, 1.0, a);
	v = max(v, w);
	
	w = gear(sp, vec2(-2.0 + 0.65 + 4.0 * sr, 0.35), 7.0, 0.8, -a);
	v = max(v, w);
	if(hash(si - 105.13) > 0.8)
	{
		w = gear(sp, vec2(-2.0 + 0.65 + 4.0 * sr, 0.35), 7.0, 0.8, -a);
		v = max(v, w);
	}
	if(hash(si + 77.29) > 0.8)
	{
		w = gear(sp, vec2(-2.0 - 0.55 + 4.0 * sr, 0.30), 5.0, 0.5, -a + 0.7);
		v = max(v, w);
	}
	
	return v;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv = uv * 2.0 - 1.0;
	vec2 p = uv;
	p.x *= iResolution.x / iResolution.y;
	
	float t = iGlobalTime;
	
	vec2 cam = vec2(sin(t) * 0.2, t);
	
	// for future use
	/*float quake = exp(-fract(t) * 5.0) * 0.5;
	if(quake > 0.001)
	{
		cam.x += (hash(t) - 0.5) * quake;
		cam.y += (hash(t - 118.29) - 0.5) * quake;
	}*/
	
	p = rotate(p, sin(t) * 0.02);
	
	vec2 o = vec2(0.0, t);
	float v = 0.0, w;
	
	
	float z = 3.0 - sin(t * 0.7) * 0.1;
	for(int i = 0; i < 5; i ++)
	{
		float f = 1.0;
		
		float zz = 0.3 + z;
		
		f = zz * 2.0 * 0.9;
		
		
		if(i == 3 || i == 1)
			w = layerA(vec2(p.x, p.y) * f + cam, float(i));
		else
			w = layerB(vec2(p.x, p.y) * f + cam, float(i));
		v = mix(v, exp(-abs(zz) * 0.3 + 0.1), w);
		
		
		z -= 0.6;
	}
	
	
	
	
	v = 1.0 - v;// * pow(1.0 - abs(uv.x), 0.1);
	
	fragColor = vec4(v, v, v, 1.0);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
