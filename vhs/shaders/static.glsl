// Loose Connection shader
// by hunterk
// adapted from drmelon's VHS Distortion shadertoy:
// https://www.shadertoy.com/view/4dBGzK
// ryk's VCR Distortion shadertoy:
// https://www.shadertoy.com/view/ldjGzV
// and Vladmir Storm's VHS Tape Noise shadertoy:
// https://www.shadertoy.com/view/MlfSWr

// Parameter lines go here:
#pragma parameter magnitude "Distortion Magnitude" 0.9 0.0 25.0 0.1
#pragma parameter always_on "OSD Always On" 0.0 0.0 1.0 1.0

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

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
uniform sampler2D play;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float magnitude;
uniform COMPAT_PRECISION float always_on;
#else
#define magnitude 0.9
#define always_on 0.0
#endif

float rand(vec2 co)
{
     float a = 12.9898;
     float b = 78.233;
     float c = 43758.5453;
     float dt= dot(co.xy ,vec2(a,b));
     float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

//random hash
vec4 hash42(vec2 p){
    
	vec4 p4 = fract(vec4(p.xyxy) * vec4(443.8975,397.2973, 491.1871, 470.7827));
    p4 += dot(p4.wzxy, p4+19.19);
    return fract(vec4(p4.x * p4.y, p4.x*p4.z, p4.y*p4.w, p4.x*p4.w));
}

float hash( float n ){
    return fract(sin(n)*43758.5453123);
}

// 3d noise function (iq's)
float n( in vec3 x ){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

//tape noise
float nn(vec2 p, float framecount){


    float y = p.y;
    float s = mod(framecount * 0.15, 4837.0);
    
    float v = (n( vec3(y*.01 +s, 			1., 1.0) ) + .0)
          	 *(n( vec3(y*.011+1000.0+s, 	1., 1.0) ) + .0) 
          	 *(n( vec3(y*.51+421.0+s, 	1., 1.0) ) + .0)   
        ;
   	v*= hash42(   vec2(p.x +framecount*0.01, p.y) ).x +.3 ;

    
    v = pow(v+.3, 1.);
	if(v<.99) v = 0.;  //threshold
    return v;
}

vec3 distort(sampler2D tex, vec2 uv, float magnitude, float framecount){
	float mag = magnitude * 0.0001;

	vec2 offset_x = vec2(uv.x);
	offset_x.x += rand(vec2(mod(framecount, 9847.0) * 0.03, uv.y * 0.42)) * 0.001 + sin(rand(vec2(mod(framecount, 5583.0) * 0.2, uv.y))) * mag;
	offset_x.y += rand(vec2(mod(framecount, 5583.0) * 0.004, uv.y * 0.002)) * 0.004 + sin(mod(framecount, 9847.0) * 9.0) * mag;
	
	return vec3(COMPAT_TEXTURE(tex, vec2(offset_x.x, uv.y)).r,
				COMPAT_TEXTURE(tex, vec2(offset_x.x, uv.y)).g,
				COMPAT_TEXTURE(tex, uv).b);
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
	float timer = vec2(FrameCount, FrameCount).x;
	vec3 res = distort(Source, jumpy(vTexCoord, timer), magnitude, timer);
	float col = nn(-vTexCoord * SourceSize.y * 4.0, timer);
	vec3 play_osd = distort(play, jumpy(vTexCoord * TextureSize / InputSize, timer), magnitude, timer);
	float overlay_alpha = COMPAT_TEXTURE(play, jumpy(vTexCoord * TextureSize / InputSize, timer)).a;
	float show_overlay = (mod(timer, 100.0) < 50.0) && (timer < 500.0) ? COMPAT_TEXTURE(play, jumpy(vTexCoord * TextureSize / InputSize, timer)).a : 0.0;
	show_overlay = clamp(show_overlay + always_on * overlay_alpha, 0.0, 1.0);
	res = mix(res, play_osd, show_overlay);

	FragColor = vec4(res + clamp(vec3(col), 0.0, 0.5), 1.0);
} 
#endif
