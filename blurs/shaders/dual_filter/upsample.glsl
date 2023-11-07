// See downsample.glsl for copyright and other information.

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
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main() {
  gl_Position = MVPMatrix * VertexCoord;
  TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
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

#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BLUR_RADIUS;
#else
#define BLUR_RADIUS 1.0
#endif

vec3 downsample(sampler2D tex, vec2 coord, vec2 offset) {
  // The offset should be 1 source pixel size which equals 0.5 output pixel
  // sizes in the default configuration.
  return (COMPAT_TEXTURE(tex, coord - offset).rgb +                    //
          COMPAT_TEXTURE(tex, coord + vec2(offset.x, -offset.y)).rgb + //
          COMPAT_TEXTURE(tex, coord).rgb * 4.0 +                       //
          COMPAT_TEXTURE(tex, coord + offset).rgb +                    //
          COMPAT_TEXTURE(tex, coord - vec2(offset.x, -offset.y)).rgb) *
         0.125;
}

vec3 upsample(sampler2D tex, vec2 coord, vec2 offset) {
  // The offset should be 0.5 source pixel sizes which equals 1 output pixel
  // size in the default configuration.
  return (COMPAT_TEXTURE(tex, coord + vec2(0.0, -offset.y * 2.0)).rgb +
          (COMPAT_TEXTURE(tex, coord + vec2(-offset.x, -offset.y)).rgb +
           COMPAT_TEXTURE(tex, coord + vec2(offset.x, -offset.y)).rgb) *
              2.0 +
          COMPAT_TEXTURE(tex, coord + vec2(-offset.x * 2.0, 0.0)).rgb +
          COMPAT_TEXTURE(tex, coord + vec2(offset.x * 2.0, 0.0)).rgb +
          (COMPAT_TEXTURE(tex, coord + vec2(-offset.x, offset.y)).rgb +
           COMPAT_TEXTURE(tex, coord + vec2(offset.x, offset.y)).rgb) *
              2.0 +
          COMPAT_TEXTURE(tex, coord + vec2(0.0, offset.y * 2.0)).rgb) /
         12.0;
}

void main() {
  vec2 offset = 0.5 * SourceSize.zw * BLUR_RADIUS;
  FragColor = vec4(upsample(Source, vTexCoord, offset), 1.0);
}

#endif
