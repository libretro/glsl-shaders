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
precision mediump int;
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


float time      = float(FrameCount)*0.0325;
vec2 resolution = OutputSize.xy;
float fade      = 0.45;

const float PI  = 3.14159265358979323846;

float speed     = time*0.25;
float ground_x  = 0.125 - 0.25*cos(PI*speed*0.25);
float ground_y  = 0.125 + 0.25*sin(PI*speed*0.25);
float ground_z  = speed*0.125;

vec2 rotate(vec2 k, float t)
{
    return vec2(cos(t)*k.x - sin(t)*k.y, sin(t)*k.x + cos(t)*k.y);
}

float scene(vec3 p)
{
    float ball_p = 0.25;
    float ball_w = ball_p*1.0;
    float ball   = length(mod(p.xyz, ball_p) - ball_p*0.5) - ball_w;
    float hole_w = ball_p*0.55;
    float hole   = length(mod(p.xyz, ball_p) - ball_p*0.5) - hole_w;
    float pipe_p = 0.015;
    float pipe_w = pipe_p*0.42; //-0.00375*sync;
    float pipe_y = length(max(abs(mod(p.xy, pipe_p) - pipe_p*0.5) - pipe_w,0.0));
    float pipe_z = length(max(abs(mod(p.xz, pipe_p) - pipe_p*0.5) - pipe_w,0.0));

    return max(max(ball, -hole), max(pipe_y, max(pipe_y, pipe_z)));
}

vec3 getNormal(vec3 pos) 
{ 
    vec3 e = vec3(0.0, 0.0001, 0.0); 

    return normalize(vec3(scene(pos + e.yxx) - scene(pos - e.yxx),
                          scene(pos + e.xyx) - scene(pos - e.xyx),
                          scene(pos + e.xxy) - scene(pos - e.xxy))); 
}

float render_scene(vec3 ray_origin, vec3 ray_dir, float t)
{
    const int ray_n = 96;
    for (int i = 0; i < ray_n; i++)
    {
        float k = scene(ray_origin + ray_dir*t);
        t      += k*fade;
    }
    return t;   
}

void main(void)
{
    vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
    vec2 position = (FragCoord.xy/resolution.xy);
    vec2 p        = -1.0 + 2.0*position;
    
    //set up camera
    float speed = time*0.5;
    vec3 dir = normalize(vec3(p*vec2(1.0, 1.0), 1.));
    dir.yz   = rotate(dir.yz,PI*1.0*sin(speed*0.25));     // rotation x
    dir.zx   = rotate(dir.zx,PI*1.0*cos(speed*0.25));     // rotation y
    dir.xy   = rotate(dir.xy, -speed*0.5);                 // rotation z
    vec3 ray = vec3(ground_x, ground_y, ground_z);
    
    //the raymarch
    float t  = 0.0;
    t        = render_scene(ray, dir, t);
    vec3 hit = ray + dir*t;
    t       += hit.x;
    
    //get normal for reflection
    vec3 n = getNormal(hit);
    
    //render reflection
    dir        = reflect(dir, n);
    dir        = normalize(refract(dir, n, .82));   
    t          = render_scene(ray, dir, t); 
    float c    = (n.x*1.0 + n.y + n.z)*0.5;   
    vec3 color = vec3(0., c*t*0.125*p.x + t*0.1, c*t*0.);
    color     *= 2.412;
    
    FragColor = vec4(color, 1.0);
}
#endif