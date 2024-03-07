#version 110

#pragma parameter ntsc_bri "Brightness" 1.0 0.0 2.0 0.01
#pragma parameter ntsc_hue "Hue" 0.0 -1.0 6.3 0.05

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
uniform COMPAT_PRECISION float ntsc_bri;
uniform COMPAT_PRECISION float ntsc_hue;
uniform COMPAT_PRECISION float stat_ph ;
uniform COMPAT_PRECISION float pi_mod ;
uniform COMPAT_PRECISION float vert_scal ;

#else
#define ntsc_bri 1.0
#define ntsc_hue 0.0
#define  stat_ph 1.0
#define  pi_mod 90.0
#define  vert_scal 0.6667
#endif

#define PI 3.1415926 

// Colorspace conversion matrix for RGB-to-YIQ
const mat3 RGBYIQ = mat3(
      0.2989, 0.5870, 0.1140,
      0.5959, -0.2744, -0.3216,
      0.2115, -0.5229, 0.3114
);
#define onedeg 0.017453

void main()
{
    float phase = floor(vTexCoord.x*SourceSize.x)*pi_mod*onedeg + mod(floor(vTexCoord.y*SourceSize.y)*vert_scal,2.0)*PI; 
    phase += ntsc_hue;
    if (stat_ph == 1.0) phase += sin(mod(float(FrameCount),2.0))*PI;
    
    vec3 YUV = COMPAT_TEXTURE(Source,vTexCoord).rgb; 
    YUV = YUV*RGBYIQ;

    YUV *= vec3(ntsc_bri, cos(phase), sin(phase));
    float signal = YUV.x + YUV.y + YUV.z;   
    FragColor = vec4(vec3(signal), 1.0);
    
}
#endif
