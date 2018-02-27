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

#define PI 3.14159

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

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float map(vec3 pos)
{
    float speed = 1.0;
    vec3 grid = floor(pos);
    vec3 gmod = mod(grid, 2.0);
    vec3 rmod = mod(grid, 4.0) - 2.0;
    float tm = fract(iGlobalTime * speed);
    rmod *= (cos(tm*PI)-1.0);
    
    float g = floor(mod(iGlobalTime*speed,3.0));
    if (g==0.0){
        if (gmod.y*gmod.x==1.0) {
            pos.z += rmod.x*rmod.y*0.5;
        }
    } else if (g==1.0){
        if (gmod.y*gmod.z==1.0) {
            pos.x += rmod.y;
        }
    } else if (g==2.0){
        if (gmod.z==0.0) {
            pos.y += rmod.z*rmod.x*0.5;
        }
    }
        
    grid = floor(pos);
    pos = pos - grid;
    pos = pos * 2.0 - 1.0;

    float len = 0.9;

    float d = sdBox(pos,vec3(len));

    bool skip = false;

    if (mod(grid.x,2.0)==0.0 && mod(grid.y,2.0)==0.0) {
        skip = true;
    }

    if (mod(grid.x,2.0)==0.0 && mod(grid.z,2.0)==0.0) {
        skip = true;
    }

    if (mod(grid.y,2.0)==0.0 && mod(grid.z,2.0)==1.0) {
        skip = true;
    }

    if (skip) {
        d = 100.0;
        vec3 off = vec3(2.0,0.0,0.0);
        for (int i = 0; i < 3; ++i) {
            float a = sdBox(pos + off,vec3(len));
            float b = sdBox(pos - off,vec3(len));
            d = min(d,min(a,b));
            off = off.zxy;
        }
        d *= 0.5;
    } else {
        d *= 0.8;   
    }
    
    return d;
}

vec3 surfaceNormal(vec3 pos) {
 	vec3 delta = vec3(0.01, 0.0, 0.0);
    vec3 normal;
    normal.x = map(pos + delta.xyz) - map(pos - delta.xyz);
    normal.y = map(pos + delta.yxz) - map(pos - delta.yxz);
    normal.z = map(pos + delta.zyx) - map(pos - delta.zyx);
    return normalize(normal);
}

float aoc(vec3 origin, vec3 ray)
{
    float delta = 0.05;
    const int samples = 8;
    float r = 0.0;
    for (int i = 1; i <= samples; ++i) {
        float t = delta * float(i);
     	vec3 pos = origin + ray * t;
        float dist = map(pos);
        float len = abs(t - dist);
        r += len * pow(2.0, -float(i));
    }
    return r;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
	vec3 eye = normalize(vec3(uv, 1.0 - dot(uv,uv) * 0.33));
    vec3 origin = vec3(0.0);
    
    eye = eye * yrot(iGlobalTime) * xrot(iGlobalTime);
    
    float speed = 0.5;
    
    float j = iGlobalTime * speed;
    
    float f = fract(j);
    float g = 1.0 - f;
    f = f*f * g + (1.0-g*g) * f;
    f = f * 2.0 - 1.0;
	float a = floor(j) + f * floor(mod(j,2.0));
    float b = floor(j) + f * floor(mod(j+1.0,2.0));
    
    origin.x += 0.5 + a;
    origin.y += 0.5;
    origin.z += 0.5 + b;
    
    float t = 0.0;
    float d = 0.0;
    
    for (int i = 0; i < 32; ++i){
        vec3 pos = origin + eye * t;
        d = map(pos);
        t += d;
    }
    
    vec3 worldPos = origin + eye * t;
    
    vec3 norm = surfaceNormal(worldPos);
    
    float prod = max(0.0, dot(norm, -eye));
    
    float amb = 0.0;//aoc(worldPos, -eye);
    
    vec3 ref = reflect(eye, norm);
    
    vec3 spec = vec3(0.0);//texture(iChannel0, ref).xyz;
    
    prod = pow(1.0 - prod, 2.0);
    
    vec3 col = vec3(0.1, 0.3, 0.5);
    
    spec *= col;
    
    col = mix(col, spec, prod);
    
    float shade = pow(max(1.0 - amb, 0.0), 4.0);
    
    float fog = 1.0 / (1.0 + t * t * 0.2) * shade;
    
    vec3 final = col;
    
    final = mix(final, vec3(1.0), fog);
    
    fog = 1.0 / (1.0 + t * t * 0.1);
    
	fragColor = vec4(final*fog,0.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
