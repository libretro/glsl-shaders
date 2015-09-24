//
// PUBLIC DOMAIN CRT STYLED SCAN-LINE SHADER
//
//   by Timothy Lottes
//
// This is more along the style of a really good CGA arcade monitor.
// With RGB inputs instead of NTSC.
// The shadow mask example has the mask rotated 90 degrees for less chromatic aberration.
//
// Left it unoptimized to show the theory behind the algorithm.
//
// It is an example what I personally would want as a display option for pixel art games.
// Please take and use, change, or whatever.
//

// -- config  -- //
#pragma parameter hardScan "hardScan" -8.0 -20.0 0.0 1.0 // default, minimum, maximum, optional step
#pragma parameter hardPix "hardPix" -3.0 -20.0 0.0 1.0
#pragma parameter warpX "warpX" 0.031 0.0 0.125 0.01
#pragma parameter warpY "warpY" 0.041 0.0 0.125 0.01
#pragma parameter maskDark "maskDark" 0.5 0.0 2.0 0.1
#pragma parameter maskLight "maskLight" 1.5 0.0 2.0 0.1
#pragma parameter brightboost "brightness" 1.0 0.0 2.0 0.05

#ifdef PARAMETER_UNIFORM // If the shader implementation understands #pragma parameters, this is defined.
uniform float hardScan;
uniform float hardPix;
uniform float warpX;
uniform float warpY;
uniform float maskDark;
uniform float maskLight;
uniform float brightboost;
#else
#define hardScan -8.0
#define hardPix -3.0
#define warpX 0.031
#define warpY 0.041
#define maskDark 0.5
#define maskLight 1.5
#define brightboost 1

#endif


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
};
vec4 _oPosition1;
vec4 _r0007;
COMPAT_ATTRIBUTE vec4 VertexCoord;
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
    vec2 _oTex;
    _r0007 = VertexCoord.x*MVPMatrix[0];
    _r0007 = _r0007 + VertexCoord.y*MVPMatrix[1];
    _r0007 = _r0007 + VertexCoord.z*MVPMatrix[2];
    _r0007 = _r0007 + VertexCoord.w*MVPMatrix[3];
    _oPosition1 = _r0007;
    _oTex = TexCoord.xy;
    gl_Position = _r0007;
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
};
vec4 _ret_0;
vec3 _TMP3;
float _TMP5;
float _TMP4;
float _TMP10;
float _TMP11;
vec2 _TMP1;
vec2 _TMP9;
vec2 _TMP14;
vec2 _TMP7;
vec4 _TMP13;
float _TMP16;
float _TMP15;
float _TMP18;
vec2 _TMP12;
vec2 _TMP8;
vec2 _TMP0;
uniform sampler2D Texture;
input_dummy _IN1;
vec2 _pos0025;
vec3 _a0027;
vec3 _b0027;
vec3 _c0027;
vec3 _TMP30;
vec2 _pos0031;
vec2 _x0033;
vec3 _c0037;
float _x0041;
float _x0045;
float _x0049;
vec3 _TMP50;
vec2 _pos0051;
vec2 _x0053;
vec3 _c0057;
float _x0061;
float _x0065;
float _x0069;
vec3 _TMP70;
vec2 _pos0071;
vec2 _x0073;
vec3 _c0077;
float _x0081;
float _x0085;
float _x0089;
vec2 _pos0091;
float _TMP94;
float _pos0095;
float _x0097;
float _TMP98;
float _x0101;
float _TMP102;
float _pos0103;
float _x0105;
vec3 _TMP108;
vec2 _pos0109;
vec2 _x0111;
vec3 _c0115;
float _x0119;
float _x0123;
float _x0127;
vec3 _TMP128;
vec2 _pos0129;
vec2 _x0131;
vec3 _c0135;
float _x0139;
float _x0143;
float _x0147;
vec3 _TMP148;
vec2 _pos0149;
vec2 _x0151;
vec3 _c0155;
float _x0159;
float _x0163;
float _x0167;
vec3 _TMP168;
vec2 _pos0169;
vec2 _x0171;
vec3 _c0175;
float _x0179;
float _x0183;
float _x0187;
vec3 _TMP188;
vec2 _pos0189;
vec2 _x0191;
vec3 _c0195;
float _x0199;
float _x0203;
float _x0207;
vec2 _pos0209;
float _TMP212;
float _pos0213;
float _x0215;
float _TMP216;
float _pos0217;
float _x0219;
float _TMP220;
float _x0223;
float _TMP224;
float _pos0225;
float _x0227;
float _TMP228;
float _pos0229;
float _x0231;
vec3 _TMP234;
vec2 _pos0235;
vec2 _x0237;
vec3 _c0241;
float _x0245;
float _x0249;
float _x0253;
vec3 _TMP254;
vec2 _pos0255;
vec2 _x0257;
vec3 _c0261;
float _x0265;
float _x0269;
float _x0273;
vec3 _TMP274;
vec2 _pos0275;
vec2 _x0277;
vec3 _c0281;
float _x0285;
float _x0289;
float _x0293;
vec2 _pos0295;
float _TMP298;
float _pos0299;
float _x0301;
float _TMP302;
float _x0305;
float _TMP306;
float _pos0307;
float _x0309;
vec2 _pos0313;
float _TMP316;
float _pos0317;
float _x0319;
vec2 _pos0323;
float _TMP326;
float _x0329;
vec2 _pos0333;
float _TMP336;
float _pos0337;
float _x0339;
vec2 _x0341;
vec2 _pos0343;
vec3 _mask0343;
float _TMP344;
float _x0345;
COMPAT_VARYING vec4 TEX0;
 
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
void main()
{
    vec2 _pos9;
    vec3 _outColor;
    _pos0025 = TEX0.xy*(TextureSize.xy/InputSize.xy);
    _pos0025 = _pos0025*2.00000000E+00 - 1.00000000E+00;
    _pos0025 = _pos0025*vec2(1.00000000E+00 + _pos0025.y*_pos0025.y*warpX, 1.00000000E+00 + _pos0025.x*_pos0025.x*warpY);
    _TMP0 = _pos0025*5.00000000E-01 + 5.00000000E-01;
    _pos9 = _TMP0*(InputSize.xy/TextureSize.xy);
    _x0033 = _pos9*TextureSize.xy + vec2( -1.00000000E+00, -1.00000000E+00);
    _TMP12 = floor(_x0033);
    _pos0031 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0031.xy);
    _c0037 = brightboost*_TMP13.xyz;
    if (_c0037.x <= 4.04499993E-02) { 
        _TMP18 = _c0037.x/1.29200001E+01;
    } else {
        _x0041 = (_c0037.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0041, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0037.y <= 4.04499993E-02) { 
        _TMP18 = _c0037.y/1.29200001E+01;
    } else {
        _x0045 = (_c0037.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0045, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0037.z <= 4.04499993E-02) { 
        _TMP18 = _c0037.z/1.29200001E+01;
    } else {
        _x0049 = (_c0037.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0049, 2.40000010E+00);
    } 
    _TMP30 = vec3(_TMP15, _TMP16, _TMP18);
    _x0053 = _pos9*TextureSize.xy + vec2( 0.00000000E+00, -1.00000000E+00);
    _TMP12 = floor(_x0053);
    _pos0051 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0051.xy);
    _c0057 = brightboost*_TMP13.xyz;
    if (_c0057.x <= 4.04499993E-02) { 
        _TMP18 = _c0057.x/1.29200001E+01;
    } else {
        _x0061 = (_c0057.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0061, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0057.y <= 4.04499993E-02) { 
        _TMP18 = _c0057.y/1.29200001E+01;
    } else {
        _x0065 = (_c0057.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0065, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0057.z <= 4.04499993E-02) { 
        _TMP18 = _c0057.z/1.29200001E+01;
    } else {
        _x0069 = (_c0057.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0069, 2.40000010E+00);
    } 
    _TMP50 = vec3(_TMP15, _TMP16, _TMP18);
    _x0073 = _pos9*TextureSize.xy + vec2( 1.00000000E+00, -1.00000000E+00);
    _TMP12 = floor(_x0073);
    _pos0071 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0071.xy);
    _c0077 = brightboost*_TMP13.xyz;
    if (_c0077.x <= 4.04499993E-02) { 
        _TMP18 = _c0077.x/1.29200001E+01;
    } else {
        _x0081 = (_c0077.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0081, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0077.y <= 4.04499993E-02) { 
        _TMP18 = _c0077.y/1.29200001E+01;
    } else {
        _x0085 = (_c0077.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0085, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0077.z <= 4.04499993E-02) { 
        _TMP18 = _c0077.z/1.29200001E+01;
    } else {
        _x0089 = (_c0077.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0089, 2.40000010E+00);
    } 
    _TMP70 = vec3(_TMP15, _TMP16, _TMP18);
    _pos0091 = _pos9*TextureSize.xy;
    _TMP14 = floor(_pos0091);
    _TMP7 = -((_pos0091 - _TMP14) - vec2( 5.00000000E-01, 5.00000000E-01));
    _pos0095 = _TMP7.x - 1.00000000E+00;
    _x0097 = hardPix*_pos0095*_pos0095;
    _TMP94 = exp2(_x0097);
    _x0101 = hardPix*_TMP7.x*_TMP7.x;
    _TMP98 = exp2(_x0101);
    _pos0103 = _TMP7.x + 1.00000000E+00;
    _x0105 = hardPix*_pos0103*_pos0103;
    _TMP102 = exp2(_x0105);
    _a0027 = (_TMP30*_TMP94 + _TMP50*_TMP98 + _TMP70*_TMP102)/(_TMP94 + _TMP98 + _TMP102);
    _x0111 = _pos9*TextureSize.xy + vec2( -2.00000000E+00, 0.00000000E+00);
    _TMP12 = floor(_x0111);
    _pos0109 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0109.xy);
    _c0115 = brightboost*_TMP13.xyz;
    if (_c0115.x <= 4.04499993E-02) { 
        _TMP18 = _c0115.x/1.29200001E+01;
    } else {
        _x0119 = (_c0115.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0119, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0115.y <= 4.04499993E-02) { 
        _TMP18 = _c0115.y/1.29200001E+01;
    } else {
        _x0123 = (_c0115.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0123, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0115.z <= 4.04499993E-02) { 
        _TMP18 = _c0115.z/1.29200001E+01;
    } else {
        _x0127 = (_c0115.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0127, 2.40000010E+00);
    } 
    _TMP108 = vec3(_TMP15, _TMP16, _TMP18);
    _x0131 = _pos9*TextureSize.xy + vec2( -1.00000000E+00, 0.00000000E+00);
    _TMP12 = floor(_x0131);
    _pos0129 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0129.xy);
    _c0135 = brightboost*_TMP13.xyz;
    if (_c0135.x <= 4.04499993E-02) { 
        _TMP18 = _c0135.x/1.29200001E+01;
    } else {
        _x0139 = (_c0135.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0139, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0135.y <= 4.04499993E-02) { 
        _TMP18 = _c0135.y/1.29200001E+01;
    } else {
        _x0143 = (_c0135.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0143, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0135.z <= 4.04499993E-02) { 
        _TMP18 = _c0135.z/1.29200001E+01;
    } else {
        _x0147 = (_c0135.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0147, 2.40000010E+00);
    } 
    _TMP128 = vec3(_TMP15, _TMP16, _TMP18);
    _x0151 = _pos9*TextureSize.xy;
    _TMP12 = floor(_x0151);
    _pos0149 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0149.xy);
    _c0155 = brightboost*_TMP13.xyz;
    if (_c0155.x <= 4.04499993E-02) { 
        _TMP18 = _c0155.x/1.29200001E+01;
    } else {
        _x0159 = (_c0155.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0159, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0155.y <= 4.04499993E-02) { 
        _TMP18 = _c0155.y/1.29200001E+01;
    } else {
        _x0163 = (_c0155.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0163, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0155.z <= 4.04499993E-02) { 
        _TMP18 = _c0155.z/1.29200001E+01;
    } else {
        _x0167 = (_c0155.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0167, 2.40000010E+00);
    } 
    _TMP148 = vec3(_TMP15, _TMP16, _TMP18);
    _x0171 = _pos9*TextureSize.xy + vec2( 1.00000000E+00, 0.00000000E+00);
    _TMP12 = floor(_x0171);
    _pos0169 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0169.xy);
    _c0175 = brightboost*_TMP13.xyz;
    if (_c0175.x <= 4.04499993E-02) { 
        _TMP18 = _c0175.x/1.29200001E+01;
    } else {
        _x0179 = (_c0175.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0179, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0175.y <= 4.04499993E-02) { 
        _TMP18 = _c0175.y/1.29200001E+01;
    } else {
        _x0183 = (_c0175.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0183, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0175.z <= 4.04499993E-02) { 
        _TMP18 = _c0175.z/1.29200001E+01;
    } else {
        _x0187 = (_c0175.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0187, 2.40000010E+00);
    } 
    _TMP168 = vec3(_TMP15, _TMP16, _TMP18);
    _x0191 = _pos9*TextureSize.xy + vec2( 2.00000000E+00, 0.00000000E+00);
    _TMP12 = floor(_x0191);
    _pos0189 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0189.xy);
    _c0195 = brightboost*_TMP13.xyz;
    if (_c0195.x <= 4.04499993E-02) { 
        _TMP18 = _c0195.x/1.29200001E+01;
    } else {
        _x0199 = (_c0195.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0199, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0195.y <= 4.04499993E-02) { 
        _TMP18 = _c0195.y/1.29200001E+01;
    } else {
        _x0203 = (_c0195.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0203, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0195.z <= 4.04499993E-02) { 
        _TMP18 = _c0195.z/1.29200001E+01;
    } else {
        _x0207 = (_c0195.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0207, 2.40000010E+00);
    } 
    _TMP188 = vec3(_TMP15, _TMP16, _TMP18);
    _pos0209 = _pos9*TextureSize.xy;
    _TMP14 = floor(_pos0209);
    _TMP8 = -((_pos0209 - _TMP14) - vec2( 5.00000000E-01, 5.00000000E-01));
    _pos0213 = _TMP8.x - 2.00000000E+00;
    _x0215 = hardPix*_pos0213*_pos0213;
    _TMP212 = exp2(_x0215);
    _pos0217 = _TMP8.x - 1.00000000E+00;
    _x0219 = hardPix*_pos0217*_pos0217;
    _TMP216 = exp2(_x0219);
    _x0223 = hardPix*_TMP8.x*_TMP8.x;
    _TMP220 = exp2(_x0223);
    _pos0225 = _TMP8.x + 1.00000000E+00;
    _x0227 = hardPix*_pos0225*_pos0225;
    _TMP224 = exp2(_x0227);
    _pos0229 = _TMP8.x + 2.00000000E+00;
    _x0231 = hardPix*_pos0229*_pos0229;
    _TMP228 = exp2(_x0231);
    _b0027 = (_TMP108*_TMP212 + _TMP128*_TMP216 + _TMP148*_TMP220 + _TMP168*_TMP224 + _TMP188*_TMP228)/(_TMP212 + _TMP216 + _TMP220 + _TMP224 + _TMP228);
    _x0237 = _pos9*TextureSize.xy + vec2( -1.00000000E+00, 1.00000000E+00);
    _TMP12 = floor(_x0237);
    _pos0235 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0235.xy);
    _c0241 = brightboost*_TMP13.xyz;
    if (_c0241.x <= 4.04499993E-02) { 
        _TMP18 = _c0241.x/1.29200001E+01;
    } else {
        _x0245 = (_c0241.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0245, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0241.y <= 4.04499993E-02) { 
        _TMP18 = _c0241.y/1.29200001E+01;
    } else {
        _x0249 = (_c0241.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0249, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0241.z <= 4.04499993E-02) { 
        _TMP18 = _c0241.z/1.29200001E+01;
    } else {
        _x0253 = (_c0241.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0253, 2.40000010E+00);
    } 
    _TMP234 = vec3(_TMP15, _TMP16, _TMP18);
    _x0257 = _pos9*TextureSize.xy + vec2( 0.00000000E+00, 1.00000000E+00);
    _TMP12 = floor(_x0257);
    _pos0255 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0255.xy);
    _c0261 = brightboost*_TMP13.xyz;
    if (_c0261.x <= 4.04499993E-02) { 
        _TMP18 = _c0261.x/1.29200001E+01;
    } else {
        _x0265 = (_c0261.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0265, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0261.y <= 4.04499993E-02) { 
        _TMP18 = _c0261.y/1.29200001E+01;
    } else {
        _x0269 = (_c0261.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0269, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0261.z <= 4.04499993E-02) { 
        _TMP18 = _c0261.z/1.29200001E+01;
    } else {
        _x0273 = (_c0261.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0273, 2.40000010E+00);
    } 
    _TMP254 = vec3(_TMP15, _TMP16, _TMP18);
    _x0277 = _pos9*TextureSize.xy + vec2( 1.00000000E+00, 1.00000000E+00);
    _TMP12 = floor(_x0277);
    _pos0275 = (_TMP12 + vec2( 5.00000000E-01, 5.00000000E-01))/TextureSize.xy;
    _TMP13 = COMPAT_TEXTURE(Texture, _pos0275.xy);
    _c0281 = brightboost*_TMP13.xyz;
    if (_c0281.x <= 4.04499993E-02) { 
        _TMP18 = _c0281.x/1.29200001E+01;
    } else {
        _x0285 = (_c0281.x + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0285, 2.40000010E+00);
    } 
    _TMP15 = _TMP18;
    if (_c0281.y <= 4.04499993E-02) { 
        _TMP18 = _c0281.y/1.29200001E+01;
    } else {
        _x0289 = (_c0281.y + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0289, 2.40000010E+00);
    } 
    _TMP16 = _TMP18;
    if (_c0281.z <= 4.04499993E-02) { 
        _TMP18 = _c0281.z/1.29200001E+01;
    } else {
        _x0293 = (_c0281.z + 5.49999997E-02)/1.05499995E+00;
        _TMP18 = pow(_x0293, 2.40000010E+00);
    } 
    _TMP274 = vec3(_TMP15, _TMP16, _TMP18);
    _pos0295 = _pos9*TextureSize.xy;
    _TMP14 = floor(_pos0295);
    _TMP7 = -((_pos0295 - _TMP14) - vec2( 5.00000000E-01, 5.00000000E-01));
    _pos0299 = _TMP7.x - 1.00000000E+00;
    _x0301 = hardPix*_pos0299*_pos0299;
    _TMP298 = exp2(_x0301);
    _x0305 = hardPix*_TMP7.x*_TMP7.x;
    _TMP302 = exp2(_x0305);
    _pos0307 = _TMP7.x + 1.00000000E+00;
    _x0309 = hardPix*_pos0307*_pos0307;
    _TMP306 = exp2(_x0309);
    _c0027 = (_TMP234*_TMP298 + _TMP254*_TMP302 + _TMP274*_TMP306)/(_TMP298 + _TMP302 + _TMP306);
    _pos0313 = _pos9*TextureSize.xy;
    _TMP14 = floor(_pos0313);
    _TMP9 = -((_pos0313 - _TMP14) - vec2( 5.00000000E-01, 5.00000000E-01));
    _pos0317 = _TMP9.y + -1.00000000E+00;
    _x0319 = hardScan*_pos0317*_pos0317;
    _TMP316 = exp2(_x0319);
    _pos0323 = _pos9*TextureSize.xy;
    _TMP14 = floor(_pos0323);
    _TMP9 = -((_pos0323 - _TMP14) - vec2( 5.00000000E-01, 5.00000000E-01));
    _x0329 = hardScan*_TMP9.y*_TMP9.y;
    _TMP326 = exp2(_x0329);
    _pos0333 = _pos9*TextureSize.xy;
    _TMP14 = floor(_pos0333);
    _TMP9 = -((_pos0333 - _TMP14) - vec2( 5.00000000E-01, 5.00000000E-01));
    _pos0337 = _TMP9.y + 1.00000000E+00;
    _x0339 = hardScan*_pos0337*_pos0337;
    _TMP336 = exp2(_x0339);
    _outColor = _a0027*_TMP316 + _b0027*_TMP326 + _c0027*_TMP336;
    _x0341 = TEX0.xy*(TextureSize.xy/InputSize.xy)*OutputSize.xy;
    _TMP1 = floor(_x0341);
    _pos0343 = _TMP1 + vec2( 5.00000000E-01, 5.00000000E-01);
    _pos0343.x = _pos0343.x + _pos0343.y*3.00000000E+00;
    _mask0343 = vec3( maskDark, maskDark, maskDark);
    _x0345 = _pos0343.x/6.00000000E+00;
    _TMP344 = fract(_x0345);
    if (_TMP344 < 3.33000004E-01) { 
        _mask0343.x = maskLight;
    } else {
        if (_TMP344 < 6.66000009E-01) { 
            _mask0343.y = maskLight;
        } else {
            _mask0343.z = maskLight;
        } 
    } 
    _outColor.xyz = _outColor.xyz*_mask0343;
    if (_outColor.x < 3.13080009E-03) { 
        _TMP10 = _outColor.x*1.29200001E+01;
    } else {
        _TMP11 = pow(_outColor.x, 4.16660011E-01);
        _TMP10 = 1.05499995E+00*_TMP11 - 5.49999997E-02;
    } 
    _TMP4 = _TMP10;
    if (_outColor.y < 3.13080009E-03) { 
        _TMP10 = _outColor.y*1.29200001E+01;
    } else {
        _TMP11 = pow(_outColor.y, 4.16660011E-01);
        _TMP10 = 1.05499995E+00*_TMP11 - 5.49999997E-02;
    } 
    _TMP5 = _TMP10;
    if (_outColor.z < 3.13080009E-03) { 
        _TMP10 = _outColor.z*1.29200001E+01;
    } else {
        _TMP11 = pow(_outColor.z, 4.16660011E-01);
        _TMP10 = 1.05499995E+00*_TMP11 - 5.49999997E-02;
    } 
    _TMP3 = vec3(_TMP4, _TMP5, _TMP10);
    _ret_0 = vec4(_TMP3.x, _TMP3.y, _TMP3.z, 1.00000000E+00);
    FragColor = _ret_0;
    return;
} 
#endif
