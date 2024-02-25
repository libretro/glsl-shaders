#version 110

#pragma parameter animate_ph "Animate Phase" 1.0 0.0 1.0 1.0
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
uniform COMPAT_PRECISION float animate_ph;

#else
#define animate_ph 1.0
#endif


// Encoder or Modulator
// This pass converts RGB colors  to
// a YIQ (NTSC) Composite signal.

#define PI   3.14159265358979323846
#define TAU  6.28318530717958647693

const mat3 yiq_to_rgb = mat3(1.000, 1.000, 1.000,
                             0.956,-0.272,-1.106,
                             0.621,-0.647, 1.703);

void main() {
    vec3 rgb = vec3(0.0);
    float sum = 0.0;
    vec2 ps = vec2(SourceSize.z,0.0);
    for (int i=-4; i<=4; i++)
    {    
    float offset = float(i);
    if ( offset>-3.0  && offset<=2.0 ) {
    // Low Pass Y    
        float w= exp(-0.2*offset*offset);
        rgb.r += COMPAT_TEXTURE(Source,vTexCoord + ps*offset).r*w;
        sum += w;
    }
    float phase = (vTexCoord.x*SourceSize.x + offset)*PI*0.666 + mod(vTexCoord.y*SourceSize.y*0.666,2.0)*PI;
    float time = animate_ph > 0.0? (float(FrameCount))*PI:0.0;

    float cs = cos(phase+time);
    float sn = sin(phase+time);
   
    // High Pass Chroma (1.0 - lowpass), crude separation like a very early TV
    float w = exp2(-0.3*offset*offset);
    float r = 1.0-w;
    rgb.yz += r*COMPAT_TEXTURE(Source,vTexCoord  + ps*offset).gb*3.0*vec2(cs,sn);
    }
    rgb.x /= sum;
    rgb.yz /= 9.0;

    rgb *= yiq_to_rgb;
 
    FragColor = vec4(rgb, 1.0);
}
#endif 
