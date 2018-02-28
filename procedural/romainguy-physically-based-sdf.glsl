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

#define saturate(x) clamp(x, 0.0, 1.0)
#define PI 3.14159265359

//------------------------------------------------------------------------------
// Distance field functions
//------------------------------------------------------------------------------

float sdPlane(in vec3 p) {
    return p.y;
}

float sdSphere(in vec3 p, float s) {
    return length(p) - s;
}

float sdTorus(in vec3 p, in vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

vec2 opUnion(vec2 d1, vec2 d2) {
    return d1.x < d2.x ? d1 : d2;
}

vec2 scene(in vec3 position) {
    vec2 scene = opUnion(
          vec2(sdPlane(position), 1.0),
          vec2(sdSphere(position - vec3(0.0, 0.4, 0.0), 0.4), 12.0)
    );
    return scene;
}

//------------------------------------------------------------------------------
// Ray casting
//------------------------------------------------------------------------------

float shadow(in vec3 origin, in vec3 direction) {
    float hit = 1.0;
    float t = 0.02;
    
    for (int i = 0; i < 1000; i++) {
        float h = scene(origin + direction * t).x;
        if (h < 0.001) return 0.0;
        t += h;
        hit = min(hit, 10.0 * h / t);
        if (t >= 2.5) break;
    }

    return clamp(hit, 0.0, 1.0);
}

vec2 traceRay(in vec3 origin, in vec3 direction) {
    float material = -1.0;

    float t = 0.02;
    
    for (int i = 0; i < 1000; i++) {
        vec2 hit = scene(origin + direction * t);
        if (hit.x < 0.002 || t > 20.0) break;
        t += hit.x;
        material = hit.y;
    }

    if (t > 20.0) {
        material = -1.0;
    }

    return vec2(t, material);
}

vec3 normal(in vec3 position) {
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 n = vec3(
          scene(position + epsilon.xyy).x - scene(position - epsilon.xyy).x,
          scene(position + epsilon.yxy).x - scene(position - epsilon.yxy).x,
          scene(position + epsilon.yyx).x - scene(position - epsilon.yyx).x);
    return normalize(n);
}

//------------------------------------------------------------------------------
// BRDF
//------------------------------------------------------------------------------

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float D_GGX(float linearRoughness, float NoH, const vec3 h) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNoHSquared = 1.0 - NoH * NoH;
    float a = NoH * linearRoughness;
    float k = linearRoughness / (oneMinusNoHSquared + a * a);
    float d = k * k * (1.0 / PI);
    return d;
}

float V_SmithGGXCorrelated(float linearRoughness, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float a2 = linearRoughness * linearRoughness;
    float GGXV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
    float GGXL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    return 0.5 / (GGXV + GGXL);
}

vec3 F_Schlick(const vec3 f0, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (vec3(1.0) - f0) * pow5(1.0 - VoH);
}

float F_Schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float Fd_Burley(float linearRoughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    float lightScatter = F_Schlick(1.0, f90, NoL);
    float viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / PI);
}

float Fd_Lambert() {
    return 1.0 / PI;
}

//------------------------------------------------------------------------------
// Indirect lighting
//------------------------------------------------------------------------------

vec3 Irradiance_SphericalHarmonics(const vec3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          vec3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + vec3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + vec3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

vec2 PrefilteredDFG_Karis(float roughness, float NoV) {
    // Karis 2014, "Physically Based Material on Mobile"
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return vec2(-1.04, 1.04) * a004 + r.zw;
}

//------------------------------------------------------------------------------
// Tone mapping and transfer functions
//------------------------------------------------------------------------------

vec3 Tonemap_ACES(const vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 OECF_sRGBFast(const vec3 linear) {
    return pow(linear, vec3(1.0 / 2.2));
}

//------------------------------------------------------------------------------
// Rendering
//------------------------------------------------------------------------------

vec3 render(in vec3 origin, in vec3 direction, out float distance) {
    // Sky gradient
    vec3 color = vec3(0.65, 0.85, 1.0) + direction.y * 0.72;

    // (distance, material)
    vec2 hit = traceRay(origin, direction);
    distance = hit.x;
    float material = hit.y;

    // We've hit something in the scene
    if (material > 0.0) {
        vec3 position = origin + distance * direction;

        vec3 v = normalize(-direction);
        vec3 n = normal(position);
        vec3 l = normalize(vec3(0.6, 0.7, -0.7));
        vec3 h = normalize(v + l);
        vec3 r = normalize(reflect(direction, n));

        float NoV = abs(dot(n, v)) + 1e-5;
        float NoL = saturate(dot(n, l));
        float NoH = saturate(dot(n, h));
        float LoH = saturate(dot(l, h));

        vec3 baseColor = vec3(0.0);
        float roughness = 0.0;
        float metallic = 0.0;

        float intensity = 2.0;
        float indirectIntensity = 0.64;

        if (material < 4.0)  {
            // Checkerboard floor
            float f = mod(floor(6.0 * position.z) + floor(6.0 * position.x), 2.0);
            baseColor = 0.4 + f * vec3(0.6);
            roughness = 0.1;
        } else if (material < 16.0) {
            // Metallic objects
            baseColor = vec3(0.3, 0.0, 0.0);
            roughness = 0.2;
        }

        float linearRoughness = roughness * roughness;
        vec3 diffuseColor = (1.0 - metallic) * baseColor.rgb;
        vec3 f0 = 0.04 * (1.0 - metallic) + baseColor.rgb * metallic;

        float attenuation = shadow(position, l);

        // specular BRDF
        float D = D_GGX(linearRoughness, NoH, h);
        float V = V_SmithGGXCorrelated(linearRoughness, NoV, NoL);
        vec3  F = F_Schlick(f0, LoH);
        vec3 Fr = (D * V) * F;

        // diffuse BRDF
        vec3 Fd = diffuseColor * Fd_Burley(linearRoughness, NoV, NoL, LoH);

        color = Fd + Fr;
        color *= (intensity * attenuation * NoL) * vec3(0.98, 0.92, 0.89);

        // diffuse indirect
        vec3 indirectDiffuse = Irradiance_SphericalHarmonics(n) * Fd_Lambert();

        vec2 indirectHit = traceRay(position, r);
        vec3 indirectSpecular = vec3(0.65, 0.85, 1.0) + r.y * 0.72;
        if (indirectHit.y > 0.0) {
            if (indirectHit.y < 4.0)  {
                vec3 indirectPosition = position + indirectHit.x * r;
                // Checkerboard floor
                float f = mod(floor(6.0 * indirectPosition.z) + floor(6.0 * indirectPosition.x), 2.0);
                indirectSpecular = 0.4 + f * vec3(0.6);
            } else if (indirectHit.y < 16.0) {
                // Metallic objects
                indirectSpecular = vec3(0.3, 0.0, 0.0);
            }
        }

        // indirect contribution
        vec2 dfg = PrefilteredDFG_Karis(roughness, NoV);
        vec3 specularColor = f0 * dfg.x + dfg.y;
        vec3 ibl = diffuseColor * indirectDiffuse + indirectSpecular * specularColor;

        color += ibl * indirectIntensity;
    }

    return color;
}

//------------------------------------------------------------------------------
// Setup and execution
//------------------------------------------------------------------------------

mat3 setCamera(in vec3 origin, in vec3 target, float rotation) {
    vec3 forward = normalize(target - origin);
    vec3 orientation = vec3(sin(rotation), cos(rotation), 0.0);
    vec3 left = normalize(cross(forward, orientation));
    vec3 up = normalize(cross(left, forward));
    return mat3(left, up, forward);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalized coordinates
    vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    // Aspect ratio
    p.x *= iResolution.x / iResolution.y;

    // Camera position and "look at"
    vec3 origin = vec3(0.0, 0.8, 0.0);
    vec3 target = vec3(0.0);

    origin.x += 1.7 * cos(iGlobalTime * 0.2);
    origin.z += 1.7 * sin(iGlobalTime * 0.2);

    mat3 toWorld = setCamera(origin, target, 0.0);
    vec3 direction = toWorld * normalize(vec3(p.xy, 2.0));

    // Render scene
    float distance;
    vec3 color = render(origin, direction, distance);

    // Tone mapping
    color = Tonemap_ACES(color);

    // Exponential distance fog
    color = mix(color, 0.8 * vec3(0.7, 0.8, 1.0), 1.0 - exp2(-0.011 * distance * distance));

    // Gamma compression
    color = OECF_sRGBFast(color);

    fragColor = vec4(color, 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
