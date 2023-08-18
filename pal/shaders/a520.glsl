#version 130

/*
    A modification of Retroarch PAL Shader 
    to look-alike an Amiga A520 Composite 
    TV-modulator.
    Made by DariusG at Aug.2023
*/


#pragma parameter FIR_GAIN "FIR Gain" 1.62 0.0 3.0 0.01
#pragma parameter FIR_INVGAIN "FIR Inv Gain" 1.0 0.0 3.0 0.01
#pragma parameter ihue "I Hue" 0.1 -1.0 1.0 0.01
#pragma parameter qhue "Q Hue" 0.1 -1.0 1.0 0.01
#pragma parameter sat "Saturation" 1.0 0.0 2.0 0.01
#pragma parameter crawl "Dot Crawl" 1.0 0.0 1.0 1.0
#pragma parameter blur "Blur Size" 0.5 0.0 2.0 0.05
#pragma parameter SCAN "Scanline" 0.5 0.0 1.0 0.05
#pragma parameter BLUR "Texel Size" 0.07 0.0 1.0 0.01

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

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
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

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float FIR_GAIN;
uniform COMPAT_PRECISION float FIR_INVGAIN;
uniform COMPAT_PRECISION float ihue;
uniform COMPAT_PRECISION float qhue;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float crawl;
uniform COMPAT_PRECISION float blur;
uniform COMPAT_PRECISION float SCAN;
uniform COMPAT_PRECISION float BLUR;

#else
#define FIR_GAIN 2.0
#define FIR_INVGAIN 1.0
#define ihue 0.0
#define qhue 0.0
#define sat 1.0
#define crawl 1.0
#define blur 1.0
#define SCAN 0.4
#define BLUR 0.1

#endif



#define PI          3.14159265358
#define FSC         3579545.0*4.0
#define FLINE       15625.0
#define VISIBLELINES 312.0

#define RGB_to_YIQ  mat3( 0.299 , 0.595716 , 0.211456 ,   0.587    , -0.274453 , -0.522591 ,      0.114    , -0.321263 , 0.311135 )
#define YIQ_to_RGB  mat3( 1.0   , 1.0      , 1.0      ,   0.9563   , -0.2721   , -1.1070   ,      0.6210   , -0.6474   , 1.7046   )

#define RGB_to_YUV  mat3( 0.299 , -0.14713 , 0.615    ,   0.587    , -0.28886  , -0.514991 ,      0.114    , 0.436     , -0.10001 )
#define YUV_to_RGB  mat3( 1.0   , 1.0      , 1.0      ,   0.0      , -0.39465  , 2.03211   ,      1.13983  , -0.58060  , 0.0      )


#define FIRTAPS 20
const float FIR[20] = float[20] (-0.008030271,0.003107906,0.016841352,0.032545161,0.049360136,
											0.066256720,0.082120150,0.095848433,0.106453014,0.113151423,
											0.115441842,0.113151423,0.106453014,0.095848433,0.082120150,
											0.066256720,0.049360136,0.032545161,0.016841352,0.003107906);

//#define FIR_GAIN 2.0
//#define FIR_INVGAIN 1.02

float width_ratio;
float height_ratio;
float altv;
float invx;
vec2 dx;
float crawler;
#define time float(FrameCount)
#define fetch(offset, pos, invx) COMPAT_TEXTURE(Source, vec2(pos.xy + vec2(offset*invx ,0.0)))

float mod_luma(vec2 xy, float sinwt, float coswt) {
    vec3 rgb = fetch(0.0, xy, invx).xyz*0.5;
     rgb += fetch(0.0, xy + dx, invx).xyz*0.3;
     rgb += fetch(0.0, xy - dx, invx).xyz*0.2; 
    vec3 yuv = RGB_to_YUV * rgb;

    return clamp(yuv.r + yuv.g*sinwt + yuv.b*coswt, 0.0, 1.0);    
}

vec2 modem_UV(vec2 pos, float ofs) {

    float t = (pos.x + ofs*invx) * OutputSize.x*SourceSize.x/InputSize.x;
    float wt = t * 2.0 * PI/2.0 ;
    float phase = wt + altv;
    float sinwt = sin(phase);
    float coswt = cos(phase);
    vec3 rgb = fetch(ofs, pos, invx).xyz*0.5;
     rgb += fetch(0.0, pos + dx, invx).xyz*0.3;
     rgb += fetch(0.0, pos - dx, invx).xyz*0.2; 
         
    vec3 yuv = RGB_to_YUV * rgb;
    float signal = clamp(yuv.x + yuv.y*sinwt + yuv.z*coswt, 0.0, 1.0);

    return vec2(signal * sinwt, signal * coswt);
}

void main() {

mat3 mix_mat = mat3(
    1.0, 0.0, 0.0,
    ihue, sat, 0.0,
    qhue, 0.0, sat
);

// Quilez
    vec2 pos = vTexCoord * TextureSize;
    vec2 i = floor(pos) + 0.50;
    vec2 f = pos - i;
    pos = (i + 4.0*f*f*f)*SourceSize.zw;
    pos.x = mix( pos.x , vTexCoord.x, 0.5);
///
   dx = vec2(SourceSize.z*blur,0.0);

   crawler = crawl == 1.0? 2.0*mod(time,30.0): 0.0;
   altv = pos.y*SourceSize.y*PI/2.0 + crawler;
   invx = InputSize.x > 300.0?  BLUR*2.0/OutputSize.x : BLUR/OutputSize.x; // equals 5 samples per Fsc period

    // lowpass U/V at baseband
    vec2 UV = vec2(0.0);
    for (int i = 0; i < FIRTAPS; i++) {
        vec2 uv = modem_UV(pos, 2.0*float(i) - float(FIRTAPS)); // floats for GLES, or else, bang!
        UV += FIR_GAIN* uv * FIR[i];
        }

    float wt = (pos.x ) * SourceSize.x*2.0*PI/2.0;

    float sinwt = sin(wt + altv);
    float coswt = cos(wt + altv);

   float luma = mod_luma(pos, sinwt, coswt) - FIR_INVGAIN*(UV.x*sinwt + UV.y*coswt);
   vec3 yuv_result = vec3(luma, UV.x, UV.y);
    yuv_result *= mix_mat;

    float scan = SCAN*sin(vTexCoord.y*SourceSize.y*2.0*PI) + 1.0-SCAN; 
    
    vec3 RGB = 1.05*YUV_to_RGB * yuv_result;
    RGB *= RGB;
    RGB *= mix(scan,1.0, dot(RGB,vec3(0.25)));
    RGB = sqrt(RGB);
    FragColor = vec4(RGB, 1.0);
}
#endif
