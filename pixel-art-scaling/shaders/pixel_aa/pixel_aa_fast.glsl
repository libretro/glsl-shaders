#version 130

// See main shader file for copyright and other information.

#define FRAGMENT

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

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec2 tx_per_px;
COMPAT_VARYING vec2 px_per_tx;
COMPAT_VARYING vec2 tx_to_uv;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    tx_coord = TexCoord.xy * TextureSize - 0.5;
    tx_per_px = InputSize / OutputSize;
    px_per_tx = OutputSize / InputSize;
    tx_to_uv = 1.0 / TextureSize;
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

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec2 tx_per_px;
COMPAT_VARYING vec2 px_per_tx;
COMPAT_VARYING vec2 tx_to_uv;

void main() {
    vec2 period;
    vec2 phase = modf(tx_coord, period);
    period = (period + 0.5) * tx_to_uv;

    vec3 samples[4] =
        vec3[4](COMPAT_TEXTURE(Texture, period).rgb,
                COMPAT_TEXTURE(Texture, period + vec2(tx_to_uv.x, 0.0)).rgb,
                COMPAT_TEXTURE(Texture, period + vec2(0.0, tx_to_uv.y)).rgb,
                COMPAT_TEXTURE(Texture, period + tx_to_uv).rgb);

    vec2 t = clamp((phase - 0.5) * px_per_tx + 0.5, 0.0, 1.0);
    vec2 offset = t * t * (3.0 - 2.0 * t);

    vec3 res =
        mix(mix(samples[0] * samples[0], samples[1] * samples[1], offset.x),
            mix(samples[2] * samples[2], samples[3] * samples[3], offset.x),
            offset.y);
    FragColor = vec4(sqrt(res), 1.0);
}

#endif
