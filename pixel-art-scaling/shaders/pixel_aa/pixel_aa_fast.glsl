#version 130

// See the main shader file for copyright and other information.

#ifdef GL_ES
#define PREC_LOW lowp
#define PREC_MED mediump
#define PREC_HIGH highp
#else
#define PREC_LOW
#define PREC_MED
#define PREC_HIGH
#endif

#if defined(VERTEX)

uniform PREC_HIGH mat4 MVPMatrix;
uniform PREC_HIGH vec2 OutputSize;
uniform PREC_HIGH vec2 TextureSize;
uniform PREC_HIGH vec2 InputSize;

in PREC_HIGH vec4 VertexCoord;
in PREC_HIGH vec4 TexCoord;

out PREC_HIGH vec2 tx_coord;
out PREC_MED vec2 px_per_tx;
out PREC_MED vec2 tx_to_uv;

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    tx_coord = TexCoord.xy * TextureSize - 0.5;
    px_per_tx = OutputSize / InputSize;
    tx_to_uv = 1.0 / TextureSize;
}

#elif defined(FRAGMENT)

#ifdef GL_ES
precision mediump float;
#endif

uniform PREC_LOW sampler2D Texture;

in PREC_HIGH vec2 tx_coord;
in PREC_MED vec2 px_per_tx;
in PREC_MED vec2 tx_to_uv;

out PREC_LOW vec4 FragColor;

void main() {
    PREC_MED vec2 period;
    PREC_MED vec2 phase = modf(tx_coord, period);

    PREC_MED vec2 t = clamp((phase - 0.5) * px_per_tx + 0.5, 0.0, 1.0);
    PREC_MED vec2 offset = t * t * (3.0 - 2.0 * t);

    PREC_LOW vec3 res = texture(Texture, (period + 0.5 + offset) * tx_to_uv).rgb;
    FragColor = vec4(sqrt(res), 1.0);
}

#endif
