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

const float pi = 3.14159;

mat3 xrot(float t)
{
    return mat3(1.0, 0.0, 0.0,
                0.0, cos(t), -sin(t),
                0.0, sin(t), cos(t));
}

mat3 yrot(float t)
{
    return mat3(cos(t), 0.0, -sin(t),
                0.0, 1.0, 0.0,
                sin(t), 0.0, cos(t));
}

mat3 zrot(float t)
{
    return mat3(cos(t), -sin(t), 0.0,
                sin(t), cos(t), 0.0,
                0.0, 0.0, 1.0);
}

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sdTube(vec3 p, float a)
{
    return length(p.xy) - a;
}

float room(vec3 p)
{
	float fd = sdBox(p, vec3(8.0));
    fd = min(fd, sdBox(p+vec3(0.0,6.0,0.0), vec3(2.0,2.0,100.0)));
    fd = min(fd, sdBox(p+vec3(0.0,6.0,0.0), vec3(100.0,2.0,2.0)));
    return fd;
}

bool alpha = false;

vec2 map(vec3 p)
{   
	float d = -room(p);
    float m = 0.0;
    
    float pe = sdBox(p+vec3(0.0,8.0,0.0), vec3(1.0, 2.0, 1.0));
    if (pe < d) {
        d = pe;
        m = 1.0;
    }
    
    if (alpha) {
        float c = sdBox(p+vec3(0.0,5.0,0.0), vec3(1.0));
        if (c < d)
        {
            d = c;
            m = 2.0;
        }
    } else {
        float c = length(p+vec3(0.0,5.3,0.0)) - 0.7;
        if (c < d)
        {
            d = c;
            m = 3.0;
        }
    }
    
    return vec2(d, m);
}

vec3 normal(vec3 p)
{
	vec3 o = vec3(0.01, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy).x - map(p-o.xyy).x,
                          map(p+o.yxy).x - map(p-o.yxy).x,
                          map(p+o.yyx).x - map(p-o.yyx).x));
}

float trace(vec3 o, vec3 r)
{
 	float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        vec3 p = o + r * t;
        float d = map(p).x;
        t += d;
    }
    return t;
}

float mapl(vec3 p)
{
    p *= yrot(pi*0.25);
	float r = 0.01;
    float o = 7.0;
    vec3 q = fract(p) * 2.0 - 1.0;
    float a = sdTube(vec3(q.z,q.y,q.x), r);
    float b = sdTube(vec3(q.x,q.y,q.z), r);
    return min(a,b);
}

float tracel(vec3 o, vec3 r)
{
 	float t = 0.0;
    for (int i = 0; i < 16; ++i) {
        vec3 p = o + r * t;
        float d = mapl(p);
        t += d * 0.8;
    }
    return t;
}

vec3 _texture(vec3 p)
{
	vec3 ta = texture(Texture, vec2(p.y,p.z)).xyz;
    vec3 tb = texture(Texture, vec2(p.x,p.z)).xyz;
    vec3 tc = texture(Texture, vec2(p.x,p.y)).xyz;
    return (ta + tb + tc) / 3.0;
}

vec4 diffcol(vec3 w, vec3 r, vec3 sn, vec2 fd, float t)
{
    vec3 mdiff = vec3(0.0); 
    float gloss = 0.0;
    float light = 1.0;
    if (fd.y == 1.0) {
        mdiff = vec3(1.0);
        gloss = 1.0;
    } else if (fd.y == 2.0) {
        mdiff = vec3(1.0);
    } else if (fd.y == 3.0) {
        mdiff = vec3(1.0);
        gloss = 1.0;
    } else {
        if (sn.y > 0.9) {
    		mdiff = vec3(1.0) * vec3(0.2,0.5,0.2);
            gloss = 0.1;
        } else if (sn.y < -0.9) {
            mdiff = vec3(5.0);
            gloss = 1.0;
            light = 0.0;
        } else {
            mdiff = _texture(w*0.1) * vec3(0.0, 1.0, 1.0);
            gloss = 1.0;
        }
    }
    float fog = 1.0 / (1.0 + t * t * 0.05);
    mdiff = mix(mdiff, vec3(1.0), abs(w.y) / 8.0 * light);
    return vec4(mdiff*fog, gloss);
}

vec3 laser(vec3 o, vec3 r)
{
    float t = tracel(o, r);
    float k = 1.0 / (1.0 + t * t * 0.1);
    return vec3(1.0, 0.0, 0.0) * k;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    mat3 xfm = xrot(sin(-iGlobalTime*0.25)*0.25) * yrot(iGlobalTime);
    
    vec3 r = normalize(vec3(uv, 1.0));
    r *= xrot(pi * 0.25) * xfm;
    
    vec3 o = vec3(0.0, 0.0, -3.0);
    o *= xfm;
    o.y -= 3.0;
    
    alpha = true;
    float t = trace(o, r);
    vec3 w = o + r * t;
    vec2 fd = map(w);
    vec3 sn = normal(w);

	vec4 mdiff = diffcol(w, r, sn, fd, t);
    
    if (fd.y == 2.0) {
    	alpha = false;
    	vec3 rr = refract(r, sn, 0.9);
    	float art = trace(w, rr);
        vec3 aw = w + rr * art;
    	vec2 afd = map(aw);
        vec3 asn = normal(aw);
		mdiff = diffcol(aw, rr, asn, afd, t+art);
        mdiff.xyz += laser(w, rr);
        mdiff.w = 1.0;
        
        if (afd.y == 3.0) {
            alpha = false;
            vec3 brf = reflect(rr, asn);
            float brt = trace(aw + asn * 0.1, brf);
            vec3 bw = aw + brf * brt;
            vec2 bfd = map(bw);
            vec3 bsn = normal(bw);
            vec4 bdiff = diffcol(bw, brf, bsn, bfd, brt);
            float prod = max(dot(rr, -asn), 0.0);
            mdiff.xyz = bdiff.xyz * prod + laser(aw, t+art+brf);
        }
    }

    alpha = true;
    vec3 rf = reflect(r, sn);
    float tr = trace(w + sn * 0.01, rf);
    vec3 rw = w + rf * tr;
    vec2 rfd = map(rw);
    vec3 rsn = normal(rw);
    vec4 rdiff = diffcol(rw, rf, rsn, rfd, t+tr);
    
    float prod = max(dot(r, -sn), 0.0);
    
	vec3 fdiff = mix(mdiff.xyz, rdiff.xyz, mdiff.w*(1.0-prod));

    vec3 fc = fdiff + laser(o, r);
    
	fragColor = vec4(sqrt(fc), 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
