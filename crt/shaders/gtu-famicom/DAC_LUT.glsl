////////////////////////////////////////////////////////
//  GTU-famicom version 0.50
//  Author: aliaspider - aliaspider@gmail.com
//  License: GPLv3      
////////////////////////////////////////////////////////

#define GET_LEVEL(X) ((X)*(255.0 / (128.0*(1.962-.518)))-(.518 / (1.962-.518)))

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
    vec2 pos = (vTexCoord.xy*outsize.xy) - 0.5;
    colorPhase = 8.0001 + pos.x + pos.y * 4.0001 + FrameCount * 4.0001;
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
uniform sampler2D nestable;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING float colorPhase;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    vec4 c = COMPAT_TEXTURE(Source, vTexCoord.xy);

    vec2 pixmapCoord;
    pixmapCoord.x = c.x * (15.0 / (16.0 * 4.0)) + c.y * (3.0 / 4.0) +(0.5 / (16.0 * 4.0));
    pixmapCoord.y = 1.0 - (floor(mod(colorPhase + 0.5, 12.0)) / (12.0 * 8.0) + c.z * (7.0 / 8.0) + (0.5 / (12.0 * 8.0)));

    FragColor = vec4(GET_LEVEL(COMPAT_TEXTURE(nestable, pixmapCoord.xy).r));//vec4(signal);
} 
#endif
