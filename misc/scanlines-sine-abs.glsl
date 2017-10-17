/*
    Scanlines Sine Absolute Value
    An ultra light scanline shader
    by RiskyJumps
	license: public domain
*/

#pragma parameter amp          "Amplitude"      1.2500  0.000 2.000 0.05
#pragma parameter phase        "Phase"          0.5000  0.000 2.000 0.05
#pragma parameter lines_black  "Lines Blacks"   0.0000  0.000 1.000 0.05
#pragma parameter lines_white  "Lines Whites"   1.0000  0.000 2.000 0.05
 
#define freq             0.500000
#define offset           0.000000
#define pi               3.141592654

#ifndef PARAMETER_UNIFORM
#define amp              1.250000
#define phase            0.500000
#define lines_black      0.000000
#define lines_white      1.000000
#endif
 
#if defined(VERTEX)

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif
 
#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif
 
COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING float angle;
 
vec4 _oPosition1;
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float amp;
uniform COMPAT_PRECISION float phase;
uniform COMPAT_PRECISION float lines_black;
uniform COMPAT_PRECISION float lines_white;
#endif
 
void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
 
    float omega = 2.0 * pi * freq;              // Angular frequency
    angle = TEX0.y * omega * TextureSize.y + phase;
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
COMPAT_VARYING float angle;
 
// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)
 
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float amp;
uniform COMPAT_PRECISION float phase;
uniform COMPAT_PRECISION float lines_black;
uniform COMPAT_PRECISION float lines_white;
#endif
 
void main()
{
    vec3 color = COMPAT_TEXTURE(Source, vTexCoord).xyz;
    float grid;
 
    float lines;
 
    lines = sin(angle);
    lines *= amp;
    lines += offset;
    lines = abs(lines);
    lines *= lines_white - lines_black;
    lines += lines_black;
    color *= lines;
 
    FragColor = vec4(color.xyz, 1.0);
}
#endif