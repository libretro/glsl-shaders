#version 110

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
uniform COMPAT_PRECISION float SCANLINE;

#else
#define SCANLINE 0.3

#endif


#define FIX(c) max(abs(c), 0.000001);
#define PI  3.1415926535897932384626433832795

vec2 weight2(float x)
        {
            const float radius = 2.0;
            vec2 smpl = FIX(PI * vec2(1.0 - x, x));

            // Lanczos2. Note: we normalize below, so no point in multiplying by radius.
            vec2 ret = sin(smpl) * sin(smpl / radius) / (smpl * smpl);

            // Normalize
            return ret / dot(ret, vec2(1.0));
        }

vec3 pixel(float xpos, float ypos)
        {

            return COMPAT_TEXTURE(Source, vec2(xpos, ypos)).rgb;
        }

vec3 line(float ypos, vec2 xpos, vec2 linetaps)
        {
            return (pixel(xpos.x, ypos) * linetaps.x +
                    pixel(xpos.y, ypos) * linetaps.y) ;
        }




void main()
        {
            
// LANCZOS 2 taps
            vec2 one_pix = SourceSize.zw;
            vec2 pos = vTexCoord + one_pix*2.5;
            vec2 f = fract(pos * SourceSize.xy);

            vec2 linetaps   = weight2(f.x);
            vec2 columntaps = weight2(f.y);

            vec2 xystart = pos - one_pix*(f + 1.5);
            vec2 xpos = vec2(
                xystart.x,
                xystart.x - one_pix.x 
              );

        vec3 rgb = 
                line(xystart.y                  , xpos, linetaps)* columntaps.x +
                line(xystart.y - one_pix.y      , xpos, linetaps)* columntaps.y
                 ;
               
                rgb = clamp(rgb,0.0,1.0);
        

        FragColor.rgb = rgb;
        }
#endif