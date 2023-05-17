#pragma parameter height "Image Height" -1.145 -6.0 6.0 0.01
#pragma parameter width "Image Width" 2.0 0.0 10.0 0.05
#pragma parameter location_y "Image Location Y" 0.75 -4.0 4.0 0.005
#pragma parameter location_x "Image Location X" -0.5 -4.0 4.0 0.005
#pragma parameter ZOOM "Image Zoom" 1.0 0.0 2.0 0.005

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
COMPAT_VARYING     vec4 _color1;
COMPAT_VARYING     float _frame_rotation;
struct input_dummy {
    vec2 _video_size;
    vec2 _texture_size;
    vec2 _output_dummy_size;
    float _frame_count;
    float _frame_direction;
    float _frame_rotation;
};
struct output_dummy {
    vec4 _color1;
};
vec4 _oPosition1;
vec4 _r0020;
vec4 _r0022;
vec2 _r0024;
vec2 _r0026;
COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;
 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float height;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float location_y;
uniform COMPAT_PRECISION float location_x;
uniform COMPAT_PRECISION float ZOOM;
#else
#define height -1.145
#define width 2.0
#define location_y 0.75
#define location_x -0.5
#define ZOOM 1.0
#endif

void main()
{
    vec4 _oColor;
    vec2 _otexCoord1;
    vec2 _otexCoord2;
    _r0020 = VertexCoord.x*MVPMatrix[0];
    _r0020 = _r0020 + VertexCoord.y*MVPMatrix[1];
    _r0020 = _r0020 + VertexCoord.z*MVPMatrix[2];
    _r0020 = _r0020 + VertexCoord.w*MVPMatrix[3];
    _r0022 = _r0020.x*vec4( height, 0.00000000E+00, 0.00000000E+00, 0.00000000E+00);
    _r0022 = _r0022 + _r0020.y*vec4( 0.00000000E+00, width, 0.00000000E+00, 0.00000000E+00);
    _r0022 = _r0022 + _r0020.z*vec4( 0.00000000E+00, 0.00000000E+00, 1.00000000E+00, 0.00000000E+00);
    _r0022 = _r0022 + _r0020.w*vec4( 0.00000000E+00, 0.00000000E+00, 0.00000000E+00, 1.00000000E+00);
    _oPosition1 = _r0022;
    _oColor = COLOR;
    _r0024 = VertexCoord.x*vec2( 0.00000000E+00, 1.00000000E+00);
    _r0024 = _r0024 + VertexCoord.y*vec2( -1.00000000E+00, 0.00000000E+00);
    _otexCoord1 = _r0024 + vec2( location_y, location_x);
    _r0026 = VertexCoord.x*vec2( 0.00000000E+00, 1.00000000E+00);
    _r0026 = _r0026 + VertexCoord.y*vec2( -1.00000000E+00, 0.00000000E+00);
    _otexCoord2 = -(_r0026 + vec2( 1.0 - location_y, -1.0 - location_x));
    gl_Position = _r0022;
    COL0 = COLOR;
    TEX0.xy = _otexCoord1;
    TEX1.xy = _otexCoord2;
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
COMPAT_VARYING     vec4 _color1;
COMPAT_VARYING     float _frame_rotation;
struct input_dummy {
    vec2 _video_size;
    vec2 _texture_size;
    vec2 _output_dummy_size;
    float _frame_count;
    float _frame_direction;
    float _frame_rotation;
};
struct output_dummy {
    vec4 _color1;
};
vec4 _TMP1;
vec4 _TMP0;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;
 
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float height;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float location_y;
uniform COMPAT_PRECISION float location_x;
uniform COMPAT_PRECISION float ZOOM;
#endif

void main()
{
    vec4 _color;

//fix for clamping issues on GLES
vec2 fragCoord1 = TEX0.xy * InputSize / TextureSize;
vec2 fragCoord2 = TEX1.xy* InputSize / TextureSize;

_TMP0 = vec4(0.0);
if ( fragCoord1.x < 1.0 && fragCoord1.x > 0.0 && fragCoord1.y < 1.0 && fragCoord1.y > 0.0 )
_TMP0 = COMPAT_TEXTURE(Texture, TEX0.xy / ZOOM);
_TMP1 = vec4(0.0);
if ( fragCoord2.x < 1.0 && fragCoord2.x > 0.0 && fragCoord2.y < 1.0 && fragCoord2.y > 0.0 )
_TMP1 = COMPAT_TEXTURE(Texture, TEX1.xy / ZOOM);

    _color = _TMP0 + _TMP1;
    FragColor = _color;
    return;
} 
#endif
