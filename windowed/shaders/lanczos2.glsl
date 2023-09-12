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


void main()
{
  
    // Source position in fractions of a texel
    vec2 src_pos = vTexCoord*SourceSize.xy;
    // Source bottom left texel centre
    vec2 src_centre = floor(src_pos - 0.5) + 0.5;
    // f is position. f.x runs left to right, y bottom to top, z right to left, w top to bottom
    vec4 f; 
    f.xy = src_pos - src_centre;
    f.zw = 1.0 - f.xy;
    // Calculate weights in x and y in parallel.
    // These polynomials are piecewise approximation of Lanczos kernel
    // Calculator here: https://gist.github.com/going-digital/752271db735a07da7617079482394543
    vec4 l2_w0_o3 = (( 1.5672 * f - 2.6445) * f + 0.0837) * f + 0.9976;
    vec4 l2_w1_o3 = ((-0.7389 * f + 1.3652) * f - 0.6295) * f - 0.0004;

    vec4 w1_2  = l2_w0_o3;
    vec2 w12   = w1_2.xy + w1_2.zw;
    vec4 wedge = l2_w1_o3 * vec4 (w12.yx, w12.yx);

    // Calculate texture read positions. tc12 uses bilinear interpolation to do 4 reads in 1.
    vec2 tc12 = SourceSize.zw * (src_centre + w1_2.zw / w12);
    vec2 tc0  = SourceSize.zw * (src_centre - 1.0);
    vec2 tc3  = SourceSize.zw * (src_centre + 2.0);
    
    // Sharpening adjustment
    float sum = wedge.x + wedge.y + wedge.z + wedge.w + w12.x * w12.y;    
    wedge /= sum;

    vec3 col = vec3(
        COMPAT_TEXTURE(Source, vec2(tc12.x, tc0.y)).rgb * wedge.y +
        COMPAT_TEXTURE(Source, vec2(tc0.x, tc12.y)).rgb * wedge.x +
        COMPAT_TEXTURE(Source, tc12.xy).rgb * (w12.x * w12.y) +
        COMPAT_TEXTURE(Source, vec2(tc3.x, tc12.y)).rgb * wedge.z +
        COMPAT_TEXTURE(Source, vec2(tc12.x, tc3.y)).rgb * wedge.w
    );

    FragColor = vec4(col,1.0);
}
#endif
