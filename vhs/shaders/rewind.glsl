// VHS Rewind Effect
// adapter from VHS Pause Effect shadertoy by caaaaaaarter
// https://www.shadertoy.com/view/4lB3Dc

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
uniform sampler2D rew;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define iTime float(FrameCount)

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float onOff(float a, float b, float c, float framecount)
{
	return step(c, sin((framecount * 0.001) + a*cos((framecount * 0.001)*b)));
}

vec2 jumpy(vec2 uv, float framecount)
{
	vec2 look = uv;
	float window = 1./(1.+80.*(look.y-mod(framecount/4.,1.))*(look.y-mod(framecount/4.,1.)));
	look.x += 0.05 * sin(look.y*10. + framecount)/20.*onOff(4.,4.,.3, framecount)*(0.5+cos(framecount*20.))*window;
	float vShift = 0.4*onOff(2.,3.,.9, framecount)*(sin(framecount)*sin(framecount*20.) + 
										 (0.5 + 0.1*sin(framecount*200.)*cos(framecount)));
	look.y = mod(look.y - 0.01 * vShift, 1.);
	return look;
}

void main()
{
    vec4 texColor = COMPAT_TEXTURE(Source, vTexCoord);
	if (float(FrameDirection) < 0.0)
	{
		vec2 uv = vTexCoord.xy;
		uv.x -= sin(0.0006 * mod(iTime, 11.0)) * cos(mod(iTime, 17.0) * -uv.y);
		texColor = COMPAT_TEXTURE(Source, jumpy(uv, iTime));
		vec4 rew_osd = COMPAT_TEXTURE(rew, jumpy(vTexCoord * TextureSize / InputSize, iTime));
		rew_osd.a = ((mod(iTime, 100.0) < 50.0)) ? rew_osd.a : 0.0;
		texColor = mix(texColor, rew_osd, rew_osd.a);
		// get position to sample
		vec2 samplePosition = uv.xy * TextureSize.xy / InputSize.xy - vec2(0.0, 0.45);
		float whiteNoise;
		
	 	// Jitter each line left and right
		samplePosition.x += (rand(vec2(iTime,vTexCoord.y))+0.5);
		// Jitter the whole picture up and down
		samplePosition.y = samplePosition.y+(rand(vec2(iTime))-0.5)/32.0;
		// Slightly add color noise to each line
		texColor = texColor + (vec4(-0.5)+vec4(rand(vec2(vTexCoord.y,iTime)),rand(vec2(vTexCoord.y,iTime+1.0)),rand(vec2(vTexCoord.y,iTime+2.0)),0))*0.1;
	   
		// Either sample the texture, or just make the pixel white (to get the staticy-bit at the bottom)
		whiteNoise = rand(vec2(floor(samplePosition.y*160.0),floor(samplePosition.x*cos(iTime)))+vec2(iTime,0.));
		if ((whiteNoise > 11.5-30.0*samplePosition.y || whiteNoise < 1.5-5.0*samplePosition.y) &&
			(whiteNoise > 11.5-30.0*(samplePosition.y + 0.5) || whiteNoise < 1.5-5.0*(samplePosition.y + 0.4))) {
		    // Sample the texture.
			samplePosition.y = 1.0-samplePosition.y; //Fix for upside-down texture
		} else {
		    // Use white. (I'm adding here so the color noise still applies)
		    texColor += vec4(0.5 + rand(samplePosition));
		}

	}
	FragColor = texColor;
} 
#endif
