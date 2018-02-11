/*
   Gambatte Color
   A GLSL port of the color correction option on Gambatte emulator
   Ported by: RiskyJumps
   License: Public domain
*/

/*
OPTIONS:

INT_OPS (default: Disabled)
It's supposed to be more "accurate" but it's a waste. Not recommended
*/
//#define INT_OPS

/*
SIMULATE_INT (default: Disabled)
Only meaningful if INT_OPS is disabled. It truncates floats. Then
again, it's supposed to be more "accurate" but it looks just
too similar. It's still a waste. Not recommended.
*/
//#define SIMULATE_INT

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
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
     COL0 = COLOR;
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
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
     vec4 color = COMPAT_TEXTURE(Texture, TEX0.xy);

#ifdef INT_OPS
     color.rgb *= 255.0;

     int r = (int)color.r;
     int g = (int)color.g;
     int b = (int)color.b;

     int R = (r * 13 + g * 2 + b) >> 4;
     int G = (g *  3 + b) >> 2;
     int B = (r *  3 + g * 2 + b * 11) >> 4;

     color.rgb = vec3((float)R, (float)G, (float)B);
     color.rgb /= 255.0;

     FragColor = color;
     return;

#else
     mat3 color_correction = mat3(
         13.0,  2.0,   1.0,
          0.0,  3.0,   1.0,
          3.0,  2.0,  11.0
     );

     mat3 scale = mat3(
         1.0/16.0,      0.0,       0.0,
              0.0,  1.0/4.0,       0.0,
              0.0,      0.0,  1.0/16.0
     );

     color_correction *= scale;

#ifdef SIMULATE_INT
     color.rgb *= 255.0;
     color.rgb = floor(color.rgb);
     color.rgb *= color_correction;
     color.rgb = floor(color.rgb);
     color.rgb /= 255.0;
     FragColor = color;
     return;

#else
     color.rgb *= color_correction;
     FragColor = color;
     return;

#endif

#endif
}
#endif
