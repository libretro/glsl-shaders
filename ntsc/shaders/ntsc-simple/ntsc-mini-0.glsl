#version 110

#pragma parameter compo "S-Video/Composite" 1.0 0.0 1.0 1.0
#pragma parameter mini_hue "Hue Shift" 0.0 0.0 6.3 0.05
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
COMPAT_VARYING vec2 scale;

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
    scale = SourceSize.xy/InputSize.xy;
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
COMPAT_VARYING vec2 scale;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float compo;
uniform COMPAT_PRECISION float animate_ph;
uniform COMPAT_PRECISION float mini_hue;

#else
#define compo 1.0
#define animate_ph 0.0
#define mini_hue 0.0
#endif


// Encoder or Modulator
// This pass converts RGB colors  to
// a YIQ (NTSC) Composite signal.

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693

const mat3 rgb_to_yiq = mat3(0.299, 0.596, 0.211,
                             0.587,-0.274,-0.523,
                             0.114,-0.322, 0.312);


void main() {
    vec3 yiq = COMPAT_TEXTURE(Source,vTexCoord).rgb;
    yiq *= rgb_to_yiq;

    float phase = vTexCoord.x*SourceSize.x*PI*0.666 + mod(vTexCoord.y*SourceSize.y*0.666,2.0)*PI;
    float time = animate_ph > 0.0? (float(FrameCount))*PI:0.0;
    float cs = cos(phase+mini_hue+time);
    float sn = sin(phase+mini_hue+time);
    yiq.yz *= 0.5*vec2(cs, sn);
   
    vec2 iq = yiq.yz;

    // Return a grayscale representation of the signal
    if (compo == 0.0)
    FragColor = vec4(vec3(yiq.r,iq), 1.0);
    else FragColor = vec4(vec3(yiq.r+iq.x+iq.y), 1.0);
}
#endif 
