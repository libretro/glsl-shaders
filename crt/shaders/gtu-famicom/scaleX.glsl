////////////////////////////////////////////////////////
//  GTU-famicom version 0.50
//  Author: aliaspider - aliaspider@gmail.com
//  License: GPLv3
////////////////////////////////////////////////////////

// Parameter lines go here:
#pragma parameter cropOverscan_x "Crop Overscan X" 0.0 0.0 1.0 1.0
#pragma parameter signalResolutionY "Signal Res Y" 200.0 20.0 500.0 10.0
#pragma parameter signalResolutionI "Signal Res I" 125.0 20.0 350.0 10.0
#pragma parameter signalResolutionQ "Signal Res Q" 125.0 20.0 350.0 10.0

#define pi          3.14159265358

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float cropOverscan_x;
#else
#define cropOverscan_x 0.0
#endif

void main()
{
    if (cropOverscan_x > 0.0)
        gl_Position.x /= (240.0 / 256.0);
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
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float signalResolutionY;
uniform COMPAT_PRECISION float signalResolutionI;
uniform COMPAT_PRECISION float signalResolutionQ;
#else
#define signalResolutionY 200.0
#define signalResolutionI 125.0
#define signalResolutionQ 125.0
#endif

float d(float x, float b)
{
    return (pi*b*min(abs(x)+0.5,1.0/b));
}

float e(float x, float b)
{
    return (pi*b*min(max(abs(x)-0.5,-1.0/b),1.0/b));
}

void main()
{
    float   offset  = fract((vTexCoord.x * SourceSize.x) - 0.5);
    vec3    YIQ =   vec3(0.0);
    vec3    RGB =   vec3(0.0);
    float   X;
    vec3    c;
    float   Y = signalResolutionY / InputSize.x;
    float   I = signalResolutionI / InputSize.x;
    float   Q = signalResolutionQ / InputSize.x;
    
    float range = ceil(0.5 + InputSize.x / min(min(signalResolutionY, signalResolutionI), signalResolutionQ));
    
    float i;
//  for (i=-range;i<range+2.0;i++){
    for (i = 1.0 - range; i < range + 1.0; i++)
    {
        X = offset - i;
        c = COMPAT_TEXTURE(Source, vec2(vTexCoord.x - X * SourceSize.z, vTexCoord.y)).rgb;
        c.x *= ((d(X, Y) + sin(d(X, Y)) - e(X, Y) - sin(e(X, Y))) / (2.0 * pi));
        c.y *= ((d(X, I) + sin(d(X, I)) - e(X, I) - sin(e(X, I))) / (2.0 * pi));
        c.z *= ((d(X, Q) + sin(d(X, Q)) - e(X, Q) - sin(e(X, Q))) / (2.0 * pi));
        YIQ += c;
    }

    RGB.r = YIQ.r + 0.956 * YIQ.g + 0.621 * YIQ.b;
    RGB.g = YIQ.r - 0.272 * YIQ.g - 0.647 * YIQ.b;
    RGB.b = YIQ.r - 1.106 * YIQ.g + 1.703 * YIQ.b;

    FragColor = vec4(clamp(RGB, 0.0, 1.0), 1.0);
} 
#endif
