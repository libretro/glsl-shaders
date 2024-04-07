// See downsample.glsl for copyright and other information.

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
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
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BLUR_RADIUS;
#else
#define BLUR_RADIUS 1.0
#endif

COMPAT_VARYING vec2 in_size_normalized;
COMPAT_VARYING vec2 mirror_min;
COMPAT_VARYING vec2 mirror_max;
COMPAT_VARYING vec2 offset;

#define vTexCoord TEX0.xy

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    in_size_normalized = InputSize / TextureSize;
    mirror_min = 0.5 / TextureSize;
    mirror_max = (InputSize - 0.5) / TextureSize;
    offset = 0.5 * BLUR_RADIUS / TextureSize;
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

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

#define Source Texture
#define vTexCoord TEX0.xy

COMPAT_VARYING vec2 in_size_normalized;
COMPAT_VARYING vec2 mirror_min;
COMPAT_VARYING vec2 mirror_max;
COMPAT_VARYING vec2 offset;

vec2 mirror_repeat(vec2 coord) {
    vec2 doubled = mod(coord, 2.0 * in_size_normalized);
    vec2 mirror = step(in_size_normalized, doubled);
    return clamp(mix(doubled, 2.0 * in_size_normalized - doubled, mirror),
                 mirror_min, mirror_max);
}

vec3 upsample(sampler2D tex, vec2 coord, vec2 offset) {
    // The offset should be 0.5 source pixel sizes which equals 1 output pixel
    // size in the default configuration.
    return (COMPAT_TEXTURE(tex,
                           mirror_repeat(coord + vec2(0.0, -offset.y * 2.0)))
                .rgb +
            (COMPAT_TEXTURE(tex,
                            mirror_repeat(coord + vec2(-offset.x, -offset.y)))
                 .rgb +
             COMPAT_TEXTURE(tex,
                            mirror_repeat(coord + vec2(offset.x, -offset.y)))
                 .rgb) *
                2.0 +
            COMPAT_TEXTURE(tex,
                           mirror_repeat(coord + vec2(-offset.x * 2.0, 0.0)))
                .rgb +
            COMPAT_TEXTURE(tex,
                           mirror_repeat(coord + vec2(offset.x * 2.0, 0.0)))
                .rgb +
            (COMPAT_TEXTURE(tex,
                            mirror_repeat(coord + vec2(-offset.x, offset.y)))
                 .rgb +
             COMPAT_TEXTURE(tex,
                            mirror_repeat(coord + vec2(offset.x, offset.y)))
                 .rgb) *
                2.0 +
            COMPAT_TEXTURE(tex,
                           mirror_repeat(coord + vec2(0.0, offset.y * 2.0)))
                .rgb) /
           12.0;
}

void main() { FragColor = vec4(upsample(Source, vTexCoord, offset), 1.0); }

#endif
