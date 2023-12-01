#version 110

//SHADER ORIGINALY CREADED BY "ompuco" ON SHADERTOY
//MODIFIED AND PORTED TO RETROARCH BY DARIUSG 2023
//COMPATIBLE WITH GLES 2.0, GLES 3.0
//https://www.shadertoy.com/view/XlsczN

#pragma parameter blur_amount "Chroma Resolution"  1.0 0.0 8.0 0.1
#pragma parameter BLUR_X "Chroma Bleed Starting Point, left-right"  -90.0 -100.0 10.0 1.0
#pragma parameter blur_amountY "Luma Resolution"  2.0 0.0 8.0 0.1
#pragma parameter SIG "Signal quality, more = worse"  0.2 0.0 50.0 0.05
#pragma parameter bottom_strenth "Bottom Strength"  2.0 0.0 6.0 0.1
#pragma parameter TEAR "Main Tearing Strength"  50.0 0.0 100.0 1.0
#pragma parameter SAT "Saturation"  1.0 0.0 2.0 0.05
#pragma parameter QHUE "Hue Green to Purple"  0.0 -2.0 2.0 0.01
#pragma parameter IHUE "Hue Blue to Orange"  0.0 -2.0 2.0 0.01

#define PI 3.141592
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
    TEX0.xy = TexCoord.xy*1.0001;
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
uniform sampler2D NOISE;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float blur_amount;
uniform COMPAT_PRECISION float blur_amountY;
uniform COMPAT_PRECISION float SIG;
uniform COMPAT_PRECISION float bottom_strenth;
uniform COMPAT_PRECISION float TEAR;
uniform COMPAT_PRECISION float BLUR_X;
uniform COMPAT_PRECISION float SAT;
uniform COMPAT_PRECISION float QHUE;
uniform COMPAT_PRECISION float IHUE;

#else
#define blur_amount 2.5
#define blur_amountY 2.0
#define SIG 2.0
#define bottom_strenth 3.0
#define TEAR 50.0
#define BLUR_X 2.0
#define SAT 1.0
#define QHUE 0.0
#define IHUE 0.0
#endif


//uniform sampler2D grain_tex; 
#define signal_quality SIG/100.0
#define TIME float(FrameCount)

float grain (vec2 st, float iTime) {
    return fract(sin(dot(st, vec2(17.0,180.0)))* 2500.0 + iTime);
}

vec3 rgb2yiq(vec3 c){   
    return vec3(
        (0.2989 * c.x + 0.5959 * c.y + 0.2115 * c.z),
        (0.5870 * c.x - 0.2744 * c.y - 0.5229 * c.z),
        (0.1140 * c.x - 0.3216 * c.y + 0.3114 * c.z)
        );
}
vec3 yiq2rgb(vec3 c){
    return vec3(
        (1.0 * c.x + 1.0 * c.y + 1.0 * c.z),
        (0.956 * c.x - 0.2720 * c.y - 1.1060 * c.z),
        (0.6210 * c.x - 0.6474 * c.y + 1.7046 * c.z)
        );
}
        
vec2 Circle(float Start, float Points, float Point){
    float Rad = (3.141592 * 2.0 * (1.0 / Points)) * (Point + Start);
    return vec2(-(.3+Rad), cos(Rad));
}

vec3 Blur(vec2 uv, float f, float d, float iTime){
    float t = (sin(iTime * 5.0 + uv.y * 5.0)) / 10.0;
    float b = 1.0;
    
    t = 0.0;
    vec2 PixelOffset = vec2(d + .0005 * t, 0);
    
    float Start = BLUR_X / 14.0;
    vec2 Scale = 0.66 * blur_amount * 2.0 * PixelOffset.xy;
    
    vec3 N0 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 0.0) * Scale).rgb;
    vec3 N1 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 1.0) * Scale).rgb;
    vec3 N2 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 2.0) * Scale).rgb;
    vec3 N3 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 3.0) * Scale).rgb;
    vec3 N4 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 4.0) * Scale).rgb;
    vec3 N5 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 5.0) * Scale).rgb;
    vec3 N6 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 6.0) * Scale).rgb;
    vec3 N7 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 7.0) * Scale).rgb;
    vec3 N8 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 8.0) * Scale).rgb;
    vec3 N9 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 9.0) * Scale).rgb;
    vec3 N10 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 10.0) * Scale).rgb;
    vec3 N11 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 11.0) * Scale).rgb;
    vec3 N12 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 12.0) * Scale).rgb;
    vec3 N13 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 13.0) * Scale).rgb;
    vec3 N14 = COMPAT_TEXTURE(Source, uv).rgb;
    
    vec4 clr = COMPAT_TEXTURE(Source, uv);
    float W = 1.0 / 15.0;
    
    clr.rgb= 
        (N0 * W) +
        (N1 * W) +
        (N2 * W) +
        (N3 * W) +
        (N4 * W) +
        (N5 * W) +
        (N6 * W) +
        (N7 * W) +
        (N8 * W) +
        (N9 * W) +
        (N10 * W) +
        (N11 * W) +
        (N12 * W) +
        (N13 * W) +
        (N14 * W);
    
    return  vec3(clr.xyz)*b;
}
   
vec3 BlurY(vec2 uv, float f, float d, float iTime){
    float t = (sin(iTime * 5.0 + uv.y * 5.0)) / 10.0;
    float b = 1.0;
    
    t = 0.0;
    vec2 PixelOffset = vec2(d + .0005 * t, 0);
    
    float Start = BLUR_X / 14.0;
    vec2 Scale = 0.66 * blur_amountY * 2.0 * PixelOffset.xy;
    
    vec3 N0 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 0.0) * Scale).rgb;
    vec3 N1 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 1.0) * Scale).rgb;
    vec3 N2 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 2.0) * Scale).rgb;
    vec3 N3 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 3.0) * Scale).rgb;
    vec3 N4 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 4.0) * Scale).rgb;
    vec3 N5 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 5.0) * Scale).rgb;
    vec3 N6 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 6.0) * Scale).rgb;
    vec3 N7 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 7.0) * Scale).rgb;
    vec3 N8 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 8.0) * Scale).rgb;
    vec3 N9 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 9.0) * Scale).rgb;
    vec3 N10 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 10.0) * Scale).rgb;
    vec3 N11 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 11.0) * Scale).rgb;
    vec3 N12 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 12.0) * Scale).rgb;
    vec3 N13 = COMPAT_TEXTURE(Source, uv + Circle(Start, 14.0, 13.0) * Scale).rgb;
    vec3 N14 = COMPAT_TEXTURE(Source, uv).rgb;
    
    vec4 clr = COMPAT_TEXTURE(Source, uv);
    float W = 1.0 / 15.0;
    
    clr.rgb= 
        (N0 * W) +
        (N1 * W) +
        (N2 * W) +
        (N3 * W) +
        (N4 * W) +
        (N5 * W) +
        (N6 * W) +
        (N7 * W) +
        (N8 * W) +
        (N9 * W) +
        (N10 * W) +
        (N11 * W) +
        (N12 * W) +
        (N13 * W) +
        (N14 * W);
    
    return  vec3(clr.xyz)*b;
}



void main(){

// moved due to GLES fix. 
mat3 mix_mat = mat3(
    1.0, 0.0, 0.0,
    IHUE, SAT, 0.0,
    QHUE, 0.0, SAT
);

    float d = 0.1  / 50.0;
    vec2 uv = vTexCoord;

    // Signal Quality calculation
    float s = signal_quality * grain(vec2(uv.x, uv.y * 777777777777777.0), TIME); // Sorry... 
    
    // Main tearing
    float e = min(0.30, pow(max(0.0, cos(uv.y * 4.0 + 0.3) - 0.75) * (s + 0.5) * 1.0, 3.0)) * 25.0;
    s -= pow(COMPAT_TEXTURE(Source, vec2(0.01 + (uv.y * 32.0) / 32.0, 1.0)).r, 1.0);
    uv.x += e * abs(s * 3.0)*TEAR/100.0;
    
    // Bootom tearing, showing up, original shader using 0.0 at the bottom??
    float r = COMPAT_TEXTURE(NOISE, vec2(mod(TIME * 10.0, mod(TIME * 10.0, 256.0) * (1.0 / 256.0)), 0.0)).r * (2.0 * s);
    uv.x += abs(r * pow(min(0.003, (uv.y - 0.15)) * bottom_strenth, 2.0));
    
    // Apply blur
    d = 0.051 + abs(sin(s / 4.0));
    float c = max(0.0001, 0.002 * d);
    
    FragColor.xyz = BlurY(uv, 0.0, c + c * (uv.x), TIME);
    float Y = rgb2yiq(FragColor.xyz).r;
    
    uv.x += 0.01 * d;
    c *= 6.0;
    FragColor.xyz = Blur(uv, 0.333 ,c, TIME);
    float I = rgb2yiq(FragColor.xyz).g;
    
    uv.x += 0.005 * d;
    
    c *= 2.50;
    FragColor.xyz = Blur(uv, 0.666, c, TIME);
    // Blur end

    float Q = rgb2yiq(FragColor.xyz).b;
  
    FragColor.xyz = yiq2rgb(vec3(Y, I, Q)*mix_mat) - pow(s + e * 2.0, 3.0);
    FragColor.xyz *= smoothstep(1.0, 0.999, uv.x - .1);
}
#endif
