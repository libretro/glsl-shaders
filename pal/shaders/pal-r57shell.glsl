// WARNING: NOOB HERE :)
// Stream RU
// http://sc2tv.ru/channel/r57shell
// http://cybergame.tv/r57shell
// http://twitch.tv/elektropage

// some details
// http://forums.nesdev.com/viewtopic.php?f=3&t=12788&start=15


// CG version for retroarch http://pastebin.com/aW3nCjaf

// old version
/*void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    float pi = acos(-1.0);
    float angle = -0.1;
    
    vec2 dir = vec2(cos(angle), sin(angle));
    
    float phase = dot(uv, dir)*700.+iGlobalTime*500.;
    float luma = 1.0-(sin(phase)/2.+0.5)/4.;
    uv.x *= iChannelResolution[0].y/iChannelResolution[0].x;
    uv.y = 1.-uv.y;
    uv *= 10.;
    uv.x -= floor(uv.x);
    uv.y -= floor(uv.y);
	fragColor = luma*COMPAT_TEXTURE(iChannel0, uv);
    float k = 1.0;
    float test = fragCoord.x/k;
    float xpos = test-floor(test/3.0)*3.;
    if (xpos < 1.)
        fragColor.yz = vec2(0.);
    else if (xpos < 2.)
        fragColor.xz = vec2(0.);
    else if (xpos < 3.)
        fragColor.xy = vec2(0.);
    float test2 = fragCoord.y/k/2.0 + floor(test/3.)/2.;
    float ypos = test2-floor(test2/3.0)*3.;
    float z = sin((test-floor(test))*pi);
    float w = sin((test2-floor(test2))*pi)*2.;
    float t = pow(z+0.3,2.0);
    float t2 = pow(w+0.3,2.0);
    if (t > 1.0)
        t = 1.0;
   	if (t2 > 1.0)
        t2 = 1.0;
    fragColor*= t*t2; 
}*/

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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)


const vec2 size = vec2(320.,240.);
const float pi = 3.142;

vec3 monitor(vec2 p)
{
	vec2 pos = floor(p*size);
	vec2 uv = vTexCoord.xy;//floor(pos)/size;
   	vec4 res = COMPAT_TEXTURE(Source, uv);
    vec3 yuv = res.xyz*mat3(
        0.2126, 0.7152, 0.0722,
		-0.09991, -0.33609, 0.436,
		0.615, -0.55861, -0.05639);
    float alpha = (floor(p.x*size.x*4.)/2.0)*pi;
    vec2 sincv = vec2(cos(alpha), sin(alpha));
    if (mod(pos.y + 5.,4.) < 2.)
     sincv.x = -sincv.x;
    if (mod(pos.y, 4.) >= 2.)
     sincv.y = -sincv.y;
    float mc = 1.+dot(sincv, yuv.zy)/yuv.x;

    /*vec3 rgb = vec3(
        yuv.x + 1.28033 * yuv.z,
		yuv.x - 0.21482 * yuv.y - 0.38059 * yuv.z,
		yuv.x + 2.12798 * yuv.y);*/
    return res.xyz*mc;
}

// pos (left corner, sample size)
vec4 monitor_sample(vec2 p, vec2 sample)
{
	// linear interpolation was...
    // now other thing.
    // http://imgur.com/m8Z8trV
    // AT LAST IT WORKS!!!!
    vec2 next = vec2(.25,1.)/size;
    vec2 f = fract(vec2(4.,1.)*size*p);
    sample *= vec2(4.,1.)*size;
    vec2 l;
    vec2 r;
    if (f.x+sample.x < 1.)
    {
       	l.x = f.x+sample.x;
        r.x = 0.;
    }
    else
    {
        l.x = 1.-f.x;
        r.x = min(1.,f.x+sample.x-1.);
    }
    if (f.y+sample.y < 1.)
    {
       	l.y = f.y+sample.y;
        r.y = 0.;
    }
    else
    {
        l.y = 1.-f.y;
        r.y = min(1.,f.y+sample.y-1.);
    }
    vec3 top = mix(monitor(p),monitor(p+vec2(next.x,0.)),r.x/(l.x+r.x));
    vec3 bottom = mix(monitor(p+vec2(0.,next.y)),monitor(p+next),r.x/(l.x+r.x));
   	return vec4(mix(top,bottom,r.y/(l.y+r.y)),1.0);
    //difference should be only on border of pixels
    //return vec4((mix(top,bottom,r.y/(l.y+r.y)) - monitor(p))*2.+0.5,1.0);
}

void main()
{
	float zoom = 1.;
	FragColor = monitor_sample(vTexCoord.xy, vec2(1.0));// /zoom/SourceSize.xy, 1./zoom/SourceSize.xy);
} 
#endif
