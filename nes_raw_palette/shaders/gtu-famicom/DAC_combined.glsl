////////////////////////////////////////////////////////
//  GTU-famicom version 0.50
//  Author: aliaspider - aliaspider@gmail.com
//  License: GPLv3      
////////////////////////////////////////////////////////

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
COMPAT_VARYING float colorPhase;

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
    vec2 pos    = (TEX0.xy*outsize.xy*TextureSize.xy/InputSize.xy)-0.5;
    colorPhase  = 8.0001 + pos.x + pos.y * 4.0001 + float(FrameCount) * 4.0001;
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
uniform sampler2D nestable;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING float colorPhase;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef GL_ES
#define GET_LEVEL(X) ((X)*(255.0 / (128.0*(1.962-.518)))-(.518 / (1.962-.518)))
#elif __VERSION__ <= 130
#define GET_LEVEL(X) ((X)*(255.0 / (128.0*(1.962-.518)))-(.518 / (1.962-.518)))
#else
#define TO_INT2(X) int(floor(((X) * 3.0) + 0.5))
#define TO_INT3(X) int(floor(((X) * 7.0) + 0.5))
#define TO_INT4(X) int(floor(((X) * 15.0) + 0.5))

bool InColorp (int p, int color)
{
    return ((color + p) % 12 < 6);
}

float NTSCsignal(int emphasis, int level, int color, int p)
{
    float black = .518;
    float white = 1.962;

    float attenuation = 0.746;
    const float levels[8] = float[] (   0.350 , 0.518, 0.962, 1.550,
                                        1.094, 1.506, 1.962, 1.962);
    if (color > 13)  
        level = 1;
    
    float low  = levels[0 + level];
    float high = levels[4 + level];
    
    if (color == 0) 
        low = high;
    
    if (color > 12) 
        high = low;

    float signal = InColorp(p, color) ? high : low;

    if ((bool(emphasis & 1) && InColorp(p, 0)) ||
        (bool(emphasis & 2) && InColorp(p, 4)) ||
        (bool(emphasis & 4) && InColorp(p, 8))) 
    {
        signal = signal * attenuation;
    }


    signal = (signal - black) / (white - black);

    return signal;
}
#endif

void main()
{
    vec4 c = COMPAT_TEXTURE(Source, vTexCoord.xy);
#ifdef GL_ES
    vec2 pixmapCoord;
    pixmapCoord.x = c.x * (15.0 / (16.0 * 4.0)) + c.y * (3.0 / 4.0) +(0.5 / (16.0 * 4.0));
    pixmapCoord.y = 1.0 - (floor(mod(colorPhase + 0.5, 12.0)) / (12.0 * 8.0) + c.z * (7.0 / 8.0) + (0.5 / (12.0 * 8.0)));

    FragColor = vec4(GET_LEVEL(COMPAT_TEXTURE(nestable, pixmapCoord.xy).r));//vec4(signal);
#elif __VERSION__ <= 130
    vec2 pixmapCoord;
    pixmapCoord.x = c.x * (15.0 / (16.0 * 4.0)) + c.y * (3.0 / 4.0) +(0.5 / (16.0 * 4.0));
    pixmapCoord.y = 1.0 - (floor(mod(colorPhase + 0.5, 12.0)) / (12.0 * 8.0) + c.z * (7.0 / 8.0) + (0.5 / (12.0 * 8.0)));

    FragColor = vec4(GET_LEVEL(COMPAT_TEXTURE(nestable, pixmapCoord.xy).r));//vec4(signal);
#else
    int color    = TO_INT4(c.x);
    int level    = TO_INT2(c.y);
    int emphasis = TO_INT3(c.z);

    float signal = NTSCsignal(emphasis, level, color, int(colorPhase + 0.5));
    FragColor    = vec4(signal);
#endif
} 
#endif
