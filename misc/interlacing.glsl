/*
   Interlacing
   Author: hunterk
   License: Public domain
   
   Note: This shader is designed to work with the typical interlaced output from an emulator, which displays both even and odd fields twice.
   This shader will un-weave the image, resulting in a standard, alternating-field interlacing.
*/

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
COMPAT_VARYING     float _frame_rotation;
struct input_dummy {
    vec2 _video_size;
    vec2 _texture_size;
    vec2 _output_dummy_size;
    float _frame_count;
    float _frame_direction;
    float _frame_rotation;
float _placeholder26;
};
vec4 _oPosition1;
vec4 _r0006;
COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_VARYING vec4 COL0;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
void main()
{
    vec4 _oColor;
    vec2 _oTexCoord;
    _r0006 = VertexCoord.x*MVPMatrix[0];
    _r0006 = _r0006 + VertexCoord.y*MVPMatrix[1];
    _r0006 = _r0006 + VertexCoord.z*MVPMatrix[2];
    _r0006 = _r0006 + VertexCoord.w*MVPMatrix[3];
    _oPosition1 = _r0006;
    _oColor = COLOR;
    _oTexCoord = TexCoord.xy;
    gl_Position = _r0006;
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
COMPAT_VARYING     float _frame_rotation;
struct input_dummy {
    vec2 _video_size;
    vec2 _texture_size;
    vec2 _output_dummy_size;
    float _frame_count;
    float _frame_direction;
    float _frame_rotation;
float _placeholder27;
};
vec4 _ret_0;
float _TMP4;
float _TMP3;
float _TMP2;
float _TMP1;
input_dummy _IN1;
float mod_y;
float _a0011;
COMPAT_VARYING vec4 TEX0;
 
uniform sampler2D Texture;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
void main()
{
    vec4 _res;
    float _y;
    _res = COMPAT_TEXTURE(Texture, TEX0.xy);
    if (InputSize.y > 400.0000001) { 
        _y = TextureSize.y*TEX0.y + float(FrameCount);
    } else {
        _y = 2.0000001*TextureSize.y*TEX0.y;
    } 
    mod_y = abs(2.00001) * fract(abs(_y/2.0000001));

    if (mod_y > 0.99999) { 
        FragColor = _res;
        return;
    } else {
        FragColor = vec4(0.0);
        return;
    } 
    FragColor = _ret_0;
} 
#endif
