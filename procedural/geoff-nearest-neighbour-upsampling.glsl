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

#define AO
#define SHADOWS
#define RESOLUTION 150.0
//#define VIDEO

mat3 rotX(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(1.0, 0.0, 0.0,
                0.0,   c,  -s,
                0.0,   s,   c );
}

mat3 rotY(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(  c, 0.0,  -s,
                0.0, 1.0, 0.0,
                  s, 0.0,   c );
}

float closeObj = 0.0;

float capsule(vec3 p, vec3 a, vec3 b, float r){
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float torus(vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

vec2 vecMin(vec2 a, vec2 b){
    if(a.x <= b.x){
        return a;
    }
    return b;
}

vec2 mapMat(vec3 p){
    vec3 q = p;
    p = vec3(mod(p.x, 5.0) - 2.5, p.y, mod(p.z, 5.0) - 2.5);
    p -= vec3(0.0, 0.0, 0.0);
    float qpi = 3.141592 / 4.0;
    float sub = 10000.0;
    for(float i = 0.0; i < 8.0; i++){
        float x = 0.2 * cos(i * qpi);
        float z = 0.2 * sin(i * qpi);
        vec3 transp = p - vec3(x, 0.0, z);
        vec3 a = vec3(x, 1.2, z);
        vec3 b = vec3(x, -1.2, z);
        sub = min(sub, capsule(transp, a, b, 0.1));
    }
    float ttorus = torus(p - vec3(0.0, -1.5, 0.0), vec2(0.22));
    float btorus = torus(p - vec3(0.0, 1.5, 0.0), vec2(0.22));
    float u = min(btorus, ttorus);
    vec2 column = vec2(min(u, max(-sub, length(p.xz) - 0.35)), 2.0);
    vec2 flo = vec2(q.y + 1.5, 1.0);
    vec2 roof = vec2(-q.y + 1.5, 1.0);
    return vecMin(column, vecMin(flo, roof));
}

float map(vec3 p){
    return mapMat(p).x;
}

float trace(vec3 ro, vec3 rd){
    float t = 0.0;
    float d = 0.0;
    vec2 c;
    int inter = 0;
    for(int i = 0; i < 1000; i++){
        c = mapMat(ro + rd * t);
        d = c.x;
        if(d < 0.0001){
            inter = 1;
            break;
        }
        t += d;
        if(t > 30.0){
            break;
        }
    }
    closeObj = c.y;
    if(inter == 0){
        t = -1.0;
    }
    return t;
}

vec3 normal(vec3 p){
    return normalize(vec3(map(vec3(p.x + 0.0001, p.yz)) - map(vec3(p.x - 0.0001, p.yz)),
                          map(vec3(p.x, p.y + 0.0001, p.z)) - map(vec3(p.x, p.y - 0.0001, p.z)),
                	      map(vec3(p.xy, p.z + 0.0001)) - map(vec3(p.xy, p.z - 0.0001))));
}

vec3 camPos = vec3(0.0, 1.0, 0.0);
vec3 lightPos = vec3(0.0, 1.0, -1.0);

vec3 amb(vec3 c, float k){
    return c * k;
}

vec3 diff(vec3 c, float k, vec3 p){
    vec3 n = normal(p);
    vec3 l = normalize(lightPos - p);
    return c * k * max(0.0, dot(n, l));
}

vec3 spec(vec3 c, float k, vec3 p, float a){
    vec3 n = normal(p);
    vec3 l = normalize(lightPos - p);
    vec3 v = normalize(p - camPos);
    float facing = dot(l, n) > 0.0 ? 1.0 : 0.0;
    vec3 r = reflect(l, n);
    return c * k * facing * pow(max(0.0, dot(r, v)), a);
}

float shadow(vec3 ro, vec3 rd){
    float t = 0.4;
    float d = 0.0;
    float shadow = 1.0;
    for(int iter = 0; iter < 1000; iter++){
        d = map(ro + rd * t);
        if(d < 0.0001){
            return 0.0;
        }
        if(t > length(ro - lightPos) - 0.5){
            break;
        }
        shadow = min(shadow, 128.0 * d / t);
        t += d;
    }
    return shadow;
}

float occlusion(vec3 ro, vec3 rd){
    float k = 1.0;
    float d = 0.0;
    float occ = 0.0;
    for(int i = 0; i < 25; i++){
        d = map(ro + 0.1 * k * rd);
        occ += 1.0 / pow(2.0, k) * (k * 0.1 - d);
        k += 1.0;
    }
    return 1.0 - clamp(2.0 * occ, 0.0, 1.0);
}

float s = 1.0;
float ao = 1.0;

vec3 colour(vec3 p, float id){
    
    #ifdef SHADOWS
    float s = shadow(p, normalize(lightPos - p));
    #endif
    
    #ifdef AO
    float ao = occlusion(p, normal(p));
    #endif
    
    if(id == 1.0){
        vec3 col;
        vec2 t = mod(floor(p.xz), 2.0);
        if(t == vec2(0.0) || t == vec2(1.0)){
            col = vec3(0.2);
        }else{
            col = vec3(0.8);
        }
        //floor(s) is 1.0 only when the point is completely unshadowed - removes specular highlight from shadowed areas
        return amb(col, 0.5) * ao + diff(col, 0.9, p) + floor(s) * spec(vec3(1.0), 0.3, p, 4.0) - vec3(0.4 - 0.4 * s);;
    }else if(id == 2.0){
    	vec3 col = vec3(0.929412, 0.882353, 0.788235);
    	return amb(col, 0.5) * ao + diff(col, 0.9, p) + floor(s) * spec(vec3(1.0), 0.3, p, 4.0) - vec3(0.4 - 0.4 * s);
    }
    return vec3(0.0, 1.0, 0.0);
} 

float lastx = 0.0;
float lasty = 0.0;

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    //SIMULATED UPSAMPLING
    uv = floor(uv * RESOLUTION) / RESOLUTION;
    
    vec3 col = vec3(1.0);
    
    #ifndef VIDEO
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    camPos = vec3(0.0 , 0.0, 0.0);
    lightPos = vec3(0.0, 0.0, 10.0 * sin(iGlobalTime/ 2.0));
#ifdef MOUSE
    lastx += iMouse.x - 0.5;
    lasty += iMouse.y - 0.5;
#endif
    vec3 ro = camPos;
    vec3 rd = normalize(rotY(radians(lastx)) * rotX(radians(lasty)) * vec3(uv, 1.0));
    float d = trace(ro, rd);
    vec3 c = ro + rd * d;
    
    //If intersected
    if(d > 0.0){
    	col = colour(c, closeObj);
    	col *= 1.0 / exp(d * 0.1);
    }else{
        col = vec3(0.0);
    }
    #endif
    
    #ifdef VIDEO
    col = texture(iChannel0, uv).xyz;
    #endif
    
	fragColor = vec4(col,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
