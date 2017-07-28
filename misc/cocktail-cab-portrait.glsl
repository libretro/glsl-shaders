#pragma parameter height "CocktailTable Image Height" 1.99 -3.0 3.0 0.01
#pragma parameter width "CocktailTable Image Width" 0.8 -5.0 5.0 0.05
#pragma parameter separation "CocktailTable Image Separation" -0.235 -2.0 2.0 0.005
#pragma parameter zoom "CocktailTable Zoom" 0.51 -2.0 5.0 0.01
#pragma parameter location_x "CocktailTable Location X" 0.0 -1.0 1.0 0.01
#pragma parameter location_y "CocktailTable Location Y" 0.0 -1.0 1.0 0.01

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
input_dummy _IN1;
vec4 _r0014;
vec4 _r0016;
vec2 _r0018;
vec2 _v0018;
COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;
 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float height;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float separation;
uniform COMPAT_PRECISION float zoom;
uniform COMPAT_PRECISION float location_x;
uniform COMPAT_PRECISION float location_y;
#else
#define height 1.99
#define width 0.8
#define separation -0.235
#define zoom 0.51
#define location_x 0.0
#define location_y 0.0
#endif

void main()
{
    vec4 _oColor;
    vec2 _otexCoord;
    vec2 _otexCoord1;
    vec2 _shift;
    _r0014 = VertexCoord.x*MVPMatrix[0];
    _r0014 = _r0014 + VertexCoord.y*MVPMatrix[1];
    _r0014 = _r0014 + VertexCoord.z*MVPMatrix[2];
    _r0014 = _r0014 + VertexCoord.w*MVPMatrix[3];
    _r0016 = _r0014.x*vec4( height, 0.00000000E+00, 0.00000000E+00, 0.00000000E+00);
    _r0016 = _r0016 + _r0014.y*vec4( 0.00000000E+00, width, 0.00000000E+00, 0.00000000E+00);
    _r0016 = _r0016 + _r0014.z*vec4( 0.00000000E+00, 0.00000000E+00, 1.00000000E+00, 0.00000000E+00);
    _r0016 = _r0016 + _r0014.w*vec4( 0.00000000E+00, 0.00000000E+00, 0.00000000E+00, 1.00000000E+00);
    _oPosition1 = _r0016;
    _oColor = COLOR;
    _shift = (5.00000000E-01*InputSize)/TextureSize;
    _otexCoord = (TexCoord.xy - _shift)/zoom + _shift;
    _v0018 = TexCoord.xy - _shift;
    _r0018 = _v0018.x*vec2( -1.00000000E+00, 0.00000000E+00);
    _r0018 = _r0018 + _v0018.y*vec2( 0.00000000E+00, -1.00000000E+00);
    _otexCoord1 = _r0018/zoom + _shift;
    gl_Position = _r0016;
    COL0 = COLOR;
    TEX0.xy = _otexCoord;
    TEX1.xy = _otexCoord1;
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
COMPAT_VARYING     vec4 _color;
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
    vec4 _color;
};
vec4 _TMP1;
vec4 _TMP0;
uniform sampler2D Texture;
vec2 _c0005;
vec2 _c0007;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;
 
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float height;
uniform COMPAT_PRECISION float width;
uniform COMPAT_PRECISION float separation;
uniform COMPAT_PRECISION float zoom;
uniform COMPAT_PRECISION float location_x;
uniform COMPAT_PRECISION float location_y;
#endif

void main()
{
    output_dummy _OUT;


//fix for clamping issues on GLES
vec2 fragCoord1 = TEX0.xy * InputSize / TextureSize * vec2(0.9999);
vec2 fragCoord2 = TEX1.xy* InputSize / TextureSize * vec2(0.9999);

if ( fragCoord1.x < 0.9999 && fragCoord1.x > 0.0001 && fragCoord1.y < 0.9999 && fragCoord1.y > 0.0001 )
if ( fragCoord2.x < 0.9999 && fragCoord2.x > 0.0001 && fragCoord2.y < 0.9999 && fragCoord2.y > 0.0001 )

    _c0005 = TEX0.xy + vec2( location_x, separation + location_y);
    _TMP0 = COMPAT_TEXTURE(Texture, _c0005);
    _c0007 = TEX1.xy + vec2( -location_x, separation - location_y);
    _TMP1 = COMPAT_TEXTURE(Texture, _c0007);
    _OUT._color = _TMP0 + _TMP1;
    FragColor = _OUT._color;
    return;
} 
#endif
