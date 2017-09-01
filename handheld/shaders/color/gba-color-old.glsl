/*
   Author: Pokefan531
   License: Public domain
*/

// Shader that replicates the LCD dynamics from a GameBoy Advance

vec3 grayscale(vec3 col)
{
    // Non-conventional way to do grayscale,
    // but bSNES uses this as grayscale value.
    return vec3(dot(col, vec3(0.2126, 0.7152, 0.0722)));
}

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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
//part 1
    float saturation    = 1.0;
    float Display_gamma = 1.02;
    float CRT_gamma     = 2.4;
    float luminance     = 1.0;

    vec3 gamma  = vec3(CRT_gamma / Display_gamma);
    vec3 res    = texture(Source, vTexCoord).xyz;
    res         = mix(grayscale(res), res, saturation); // Apply saturation
    res         = pow(res, gamma.rgb); // Apply gamma
    vec4 c      = vec4(clamp(res * luminance, 0.0, 1.0), 1.0);

//part 2
    float r = c.x;
    float g = c.y;
    float b = c.z;
    float a = c.w;
    float w = r * 0.714 + g * 0.251 + b * 0.000;
    float q = r * 0.071 + g * 0.643 + b * 0.216;
    float e = r * 0.071 + g * 0.216 + b * 0.643;

//part 3
    saturation      = 1.0;
    Display_gamma   = 3.6;
    CRT_gamma       = 2.4;
    luminance       = 1.01;

    res     = vec3(w, q, e);
    gamma   = gamma = vec3(CRT_gamma / Display_gamma);
    res     = mix(grayscale(res), res, saturation); // Apply saturation
    res     = pow(res, gamma.rgb); // Apply gamma
    
    FragColor = vec4(clamp(res * luminance, 0.0, 1.0), 1.0);
} 
#endif
