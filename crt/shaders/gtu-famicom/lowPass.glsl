////////////////////////////////////////////////////////
//  GTU-famicom version 0.50
//  Author: aliaspider - aliaspider@gmail.com
//  License: GPLv3      
////////////////////////////////////////////////////////

// Parameter lines go here:
#pragma parameter signalResolution "Signal Resolution" 700.0 20.0 2000.0 10.0
#pragma parameter addNoise "Add Noise" 0.0 0.0 1.0 1.0
#pragma parameter noiseStrength "Noise Strength" 0.0 0.0 1.0 0.05

#define pi          3.14159265358
#define a(x) abs(x)
#define d(x,b) (pi*b*min(a(x)+0.5,1.0/b))
#define e(x,b) (pi*b*min(max(a(x)-0.5,-1.0/b),1.0/b))
#define STU(x,b) ((d(x,b)+sin(d(x,b))-e(x,b)-sin(e(x,b)))/(2.0*pi))
#define X(i) (offset-(i))
#define S(i) (COMPAT_TEXTURE(Source, vec2(vTexCoord.x - X(i)/SourceSize.x,vTexCoord.y)).x)
#define VAL(i) (S(i)*STU(X(i),(signalResolution / InputSize.x)))

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
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float signalResolution;
uniform COMPAT_PRECISION float addNoise;
uniform COMPAT_PRECISION float noiseStrength;
#else
#define signalResolution 700.0
#define addNoise 0.0
#define noiseStrength 0.0
#endif

float rand2(vec2 co)
{
    float c = 43758.5453;
    float dt = dot(co.xy, vec2(12.9898, 78.233));
    float sn = mod(dt, 3.14);
    
    return fract(sin(sn) * c);
}

float rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    float   offset  =   fract((vTexCoord.x * SourceSize.x) - 0.50001);
    float   signal  =   0.0;
    float   range   =   ceil(0.50001 + InputSize.x / signalResolution);
    range           =   min(range, 255.0);
            
    float i;
    for (i = 1. - range; i < 1. + range; i++)
        signal += VAL(i);

    if (addNoise > 0.0)
    {
        vec2 pos = (vTexCoord.xy * InputSize.xy);
        signal -= 0.5;
        signal += (rand(vec2(pos.x * pos.y, FrameCount)) - 0.50001) * noiseStrength;
        signal += 0.5;
    }
    
    FragColor = vec4(signal);
} 
#endif
