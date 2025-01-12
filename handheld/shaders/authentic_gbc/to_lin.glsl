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

uniform PREC_MED mat4 MVPMatrix;

in PREC_MED vec4 VertexCoord;
in PREC_MED vec4 TexCoord;

out PREC_MED vec2 tx_coord;

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    tx_coord = TexCoord.xy;
}

#elif defined(FRAGMENT)

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#endif

uniform PREC_LOW sampler2D Texture;

in PREC_MED vec2 tx_coord;

out PREC_LOW vec4 FragColor;

void main() {
    PREC_LOW vec3 s = texture(Texture, tx_coord).rgb;
    FragColor = vec4(pow(s, vec3(2.2)), 1.0);
}

#endif
