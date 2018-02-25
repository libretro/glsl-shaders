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

float sphere
	(vec3 ray, vec3 dir, vec3 center, float radius, vec3 color, inout vec3 nml, inout vec3 mat, float closestHit)
{
	vec3 rc = ray-center;
	float c = dot(rc, rc) - (radius*radius);
	float b = dot(dir, rc);
	float d = b*b - c;
	float t = -b - sqrt(abs(d));
	float st = step(0.0, min(t,d)) * step(t, closestHit);
	closestHit = mix(closestHit, t, st);
	nml = mix(nml, (center-(ray+dir*t)) / radius, st);
	mat = mix(mat, color, st);
	return closestHit;
}

float scene(float t, vec3 ro, vec3 rd, inout vec3 nml, inout vec3 mat, float dist)
{
	dist = sphere(ro, rd, vec3(0.0), 1.0, vec3(0.5, 0.8, 1.0), nml, mat, dist);
	dist = sphere(ro, rd, 
				  vec3(sin(t*3.0)*3.0, cos(t*3.0)*3.0, cos(t)*8.0), 
				  1.5, vec3(1.0, 0.8, 1.0), 
				  nml, mat, dist);
	dist = sphere(ro, rd, 
				  vec3(sin(t*3.0)*-3.0, cos(t*3.0)*-3.0, sin(t)*8.0), 
				  1.5, vec3(0.5, 0.8, 0.5), 
				  nml, mat, dist);
	return dist;
}

vec3 background(float t, vec3 rd)
{
	vec3 sunColor = vec3(2.0, 1.6, 1.0);
	vec3 skyColor = vec3(0.5, 0.6, 0.7);
	vec3 sunDir = normalize(vec3(sin(t), sin(t*1.2), cos(t)));
	return
		pow(max(0.0, dot(sunDir, rd)), 128.0)*sunColor + 
		0.2*pow(max(0.0, dot(sunDir, rd)), 2.0)*sunColor + 
		pow(max(0.0, -dot(vec3(0.0, 1.0, 0.0), rd)), 1.0)*(1.0-skyColor) +
		pow(max(0.0, dot(vec3(0.0, 1.0, 0.0), rd)), 1.0)*skyColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = 
		(-1.0 + 2.0*fragCoord.xy / iResolution.xy) * 
		vec2(iResolution.x/iResolution.y, 1.0);
	vec3 light = vec3(0.0); // How much light hits the eye through the ray.
	
	float epsilon = 0.001;
	float maxDist = 1e5;
	
	const int mblur_count = 3;  // How many motion blur rays we trace.
	const int bounce_count = 3; // How many scene rays we trace.
	
	float exposureTime = 1.0/15.0;
	vec2 tuv = vec2(float(mblur_count), 1.0)*(fragCoord.xy / 256.0);
	
	for (int j=0; j<mblur_count; j++) {
		float t = iGlobalTime + exposureTime*((float(j)+2.0*(0.5))/float(mblur_count));
		vec3 ro = vec3(0.0, 0.0, -6.0);     // Ray origin.
		vec3 rd = normalize(vec3(uv, 1.0)); // Ray direction.
		vec3 transmit = vec3(1.0);          // How much light the ray lets through.
		
		for (int i=0; i<bounce_count; i++) {
			vec3 mat, nml;
			float dist = scene(t, ro, rd, nml, mat, maxDist);
			if (dist < maxDist) { // Object hit.
				transmit *= mat;       // Make the ray more opaque.
				ro += rd*dist;         // Move the ray to the hit point.
				rd = reflect(rd, nml); // Reflect the ray.
				// Move the ray off the surface to avoid hitting the same point twice.
				ro += rd*epsilon;
			} else { // Background hit.
				// Put the background light through the ray 
				// and add it to the light seen by the eye.
				light += transmit * background(t,rd);
				break; // Don't bounce off the background.
			}
		}
	}
	light /= float(mblur_count);
	fragColor = vec4(light, 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
