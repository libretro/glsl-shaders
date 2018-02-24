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

// Sound - Digital Ambience -  srtuss - 2014-07-31
// https://www.shadertoy.com/view/MdXXW2

// i tried to rebuild the technique that creates the ambience sounds in my game project. it's based on additive synthesis. go ahead and "listen" to various textures

// srtuss, 2014

vec2 rotate(vec2 p, float a)
{
	return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

#define ITS 8

vec2 circuit(vec3 p)
{
	p = mod(p, 2.0) - 1.0;
	float w = 1e38;
	vec3 cut = vec3(1.0, 0.0, 0.0);
	vec3 e1 = vec3(-1.0);
	vec3 e2 = vec3(1.0);
	float rnd = 0.23;
	float pos, plane, cur;
	float fact = 0.9;
	float j = 0.0;
	for(int i = 0; i < ITS; i ++)
	{
		pos = mix(dot(e1, cut), dot(e2, cut), (rnd - 0.5) * fact + 0.5);
		plane = dot(p, cut) - pos;
		if(plane > 0.0)
		{
			e1 = mix(e1, vec3(pos), cut);
			rnd = fract(rnd * 9827.5719);
			cut = cut.yzx;
		}
		else
		{
			e2 = mix(e2, vec3(pos), cut);
			rnd = fract(rnd * 15827.5719);
			cut = cut.zxy;
		}
		j += step(rnd, 0.2);
		w = min(w, abs(plane));
	}
	return vec2(j / float(ITS - 1), w);
}

float scene(vec3 p)
{
	vec2 cir = circuit(p);
	return exp(-100.0 * cir.y) + pow(cir.x * 1.8 * (sin(p.z * 10.0 + iGlobalTime * -5.0 + cir.x * 10.0) * 0.5 + 0.5), 8.0);
}

float nse(float x)
{
    return fract(sin(x * 297.9712) * 90872.2961);
}

float nseI(float x)
{
    float fl = floor(x);
    return mix(nse(fl), nse(fl + 1.0), smoothstep(0.0, 1.0, fract(x)));
}

float fbm(float x)
{
    return nseI(x) * 0.5 + nseI(x * 2.0) * 0.25 + nseI(x * 4.0) * 0.125;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec2 suv = uv;
	uv = 2.0 * uv - 1.0;
	uv.x *= iResolution.x / iResolution.y;
	vec3 ro = vec3(0.0, iGlobalTime * 0.2, 0.1);
	vec3 rd = normalize(vec3(uv, 0.9));
	ro.xz = rotate(ro.xz, iGlobalTime * 0.1);
	ro.xy = rotate(ro.xy, 0.2);
	rd.xz = rotate(rd.xz, iGlobalTime * 0.2);
	rd.xy = rotate(rd.xy, 0.2);
	float acc = 0.0;
	vec3 r = ro + rd * 0.5;
	for(int i = 0; i < 50; i ++)
	{
		acc += scene(r + nse(r.x) * 0.03);
		r += rd * 0.015;
	}
	vec3 col = pow(vec3(acc * 0.04), vec3(0.2, 0.6, 2.0) * 8.0) * 2.0;
	//col -= exp(length(suv - 0.5) * -2.5 - 0.2);
    col = clamp(col, vec3(0.0), vec3(1.0));
    col *= fbm(iGlobalTime * 6.0) * 2.0;
	col = pow(col, vec3(1.0 / 2.2));
	//col = clamp(col, vec3(0.0), vec3(1.0));
	fragColor = vec4(col, 1.0);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
