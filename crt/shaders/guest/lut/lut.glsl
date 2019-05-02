// Parameter lines go here:
#pragma parameter TNTC "LUT Colors" 0.0 0.0 3.0 1.0

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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
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
uniform sampler2D SamplerLUT1;
uniform sampler2D SamplerLUT2;
uniform sampler2D SamplerLUT3;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float TNTC;
#else
#define TNTC 0.0
#endif

#define LUT_Size 32.0

const mat3 D65_to_XYZ = mat3 (
           0.4306190,  0.2220379,  0.0201853,
           0.3415419,  0.7066384,  0.1295504,
           0.1783091,  0.0713236,  0.9390944);
 
const mat3 XYZ_to_D50 = mat3 (
           2.9603944, -0.9787684,  0.0844874,
          -1.4678519,  1.9161415, -0.2545973,
          -0.4685105,  0.0334540,  1.4216174);


// This shouldn't be necessary but it seems some undefined values can
// creep in and each GPU vendor handles that differently. This keeps
// all values within a safe range
vec4 mixfix(vec4 a, vec4 b, float c)
{
	return (a.z < 1.0) ? mix(a, b, c) : a;
}

void main()
{
	vec4 imgColor = COMPAT_TEXTURE(Source, vTexCoord.xy);
	float red = ( imgColor.r * (LUT_Size - 1.0) + 0.499999 ) / (LUT_Size * LUT_Size);
	float green = ( imgColor.g * (LUT_Size - 1.0) + 0.499999 ) / LUT_Size;
	float blue1 = (floor( imgColor.b  * (LUT_Size - 1.0) ) / LUT_Size) + red;
	float blue2 = (ceil( imgColor.b  * (LUT_Size - 1.0) ) / LUT_Size) + red;
	float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
	vec4 color1, color2, res;
	if (TNTC == 1.0)
	{
		color1 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue1, green ));
		color2 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue2, green ));
		res = mixfix(color1, color2, mixer);
		float mx = max(res.r,max(res.g,res.b));
		float l = mix(length(imgColor.rgb), length(res.rgb), max(mx-0.5,0.0));
		res.rgb = mix(imgColor.rgb, res.rgb, clamp(25.0*(mx-0.02),0.0,1.0));
		res.rgb = normalize(res.rgb+1e-10)*l;
		vec3 cooler = D65_to_XYZ*res.rgb;
		cooler = XYZ_to_D50*cooler;
		res.rgb = mix(res.rgb, cooler, 0.25);
	}
	else if (TNTC == 2.0)
	{
		color1 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue1, green ));
		color2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue2, green ));
		res = mixfix(color1, color2, mixer);
		float l = mix(length(imgColor.rgb), length(res.rgb), 0.4);
		res.rgb = normalize(res.rgb + 1e-10)*l;
	}	
	else if (TNTC == 3.0)
	{
		color1 = COMPAT_TEXTURE( SamplerLUT3, vec2( blue1, green ));
		color2 = COMPAT_TEXTURE( SamplerLUT3, vec2( blue2, green ));
		res = mixfix(color1, color2, mixer);
		res.rgb = pow(res.rgb, vec3(1.0/1.20));
		float mx = max(res.r,max(res.g,res.b));
		res.rgb = mix(imgColor.rgb, res.rgb, clamp(25.0*(mx-0.05),0.0,1.0));		
		float l = length(imgColor.rgb);
		res.rgb = normalize(res.rgb + 1e-10)*l;
	}	
	
	FragColor = vec4(mix(imgColor.rgb, res.rgb, min(TNTC,1.0)),1.0);
} 
#endif
