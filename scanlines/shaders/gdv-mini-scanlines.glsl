/*
 * GDV-mini scanlines
 * nothing more, nothing less
 *
 */

#pragma parameter BEAM "Scanline Beam" 6.0 4.0 15.0 1.0
#pragma parameter SCANLINE "Scanline Strength" 1.35 0.5 2.5 0.05
#define BEAM2 BEAM*1.5
#define SCANLINE2 SCANLINE*0.7
 
#define PI 3.141592653589
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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define Source Texture


uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 scale;

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float BEAM;
uniform COMPAT_PRECISION float SCANLINE;


#else
#define BEAM 6.0
#define SCANLINE 1.35

#endif

float sw(float y, float l)
{
    float scan = mix(BEAM, BEAM2, y);
    float tmp = mix(SCANLINE, SCANLINE2, l);
    float ex = y*tmp;
    return exp2(-scan*ex*ex);
}

void main()
{       
        vec2 OGL2Pos = vTexCoord * SourceSize.xy;
        float y = fract(OGL2Pos.y);
        vec2 pC4 = floor(OGL2Pos) * SourceSize.zw + 0.5*SourceSize.zw;
        pC4.x = vTexCoord.x;
        vec3 res1 = texture2D(Source,pC4).rgb;
        vec3 res2 = texture2D(Source,pC4 + vec2(0.0,SourceSize.w)).rgb;

        float lum = dot(vec3(0.3,0.6,0.1),res1);
        
        vec3 res = res1*sw(y,lum) + res2*sw(1.0-y,lum);

        FragColor = vec4(res, 1.0);
}
#endif