// This is a copy of ../blurs/shaders/kawase/linearize.glsl with added
// parameters for the preset.

// clang-format off
#pragma parameter BLUR_FILL_SETTINGS "=== Blur fill v1.10 settings ===" 0.0 0.0 1.0 1.0

#pragma parameter SCALING_SETTINGS "= Scaling parameters =" 0.0 0.0 1.0 1.0
#pragma parameter FORCE_ASPECT_RATIO "Force aspect ratio" 1.0 0.0 1.0 1.0
#pragma parameter ASPECT_H "Horizontal aspect ratio before crop (0 = unchanged)" 0.0 0.0 256.0 1.0
#pragma parameter ASPECT_V "Vertical aspect ratio before crop (0 = unchanged)" 0.0 0.0 256.0 1.0
#pragma parameter FORCE_INTEGER_SCALING_H "Force integer scaling horizontally" 0.0 0.0 1.0 1.0
#pragma parameter FORCE_INTEGER_SCALING_V "Force integer scaling vertically" 0.0 0.0 1.0 1.0

#pragma parameter OVERSCALE "Overscale (0 = full image, 1 = full screen)" 0.0 0.0 1.0 0.01

#pragma parameter CROPPING_SETTINGS "= Cropping parameters =" 0.0 0.0 1.0 1.0
#pragma parameter OS_CROP_TOP "Overscan crop top" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_BOTTOM "Overscan crop bottom" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_LEFT "Overscan crop left" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_RIGHT "Overscan crop right" 0.0 0.0 1024.0 1.0

#pragma parameter MOVING_SETTINGS "= Moving parameters =" 0.0 0.0 1.0 1.0
#pragma parameter SHIFT_H "Horizontal shift" 0.0 -1024.0 1024.0 0.5
#pragma parameter SHIFT_V "Vertical shift" 0.0 -1024.0 1024.0 0.5
#pragma parameter CENTER_AFTER_CROPPING "Center cropped area" 1.0 0.0 1.0 1.0

#pragma parameter OTHER_SETTINGS "= Other parameters =" 0.0 0.0 1.0 1.0
#pragma parameter EXTEND_H "Extend the fill horizontally" 0.0 0.0 1.0 1.0
#pragma parameter EXTEND_V "Extend the fill vertically" 1.0 0.0 1.0 1.0

#pragma parameter MIRROR_BLUR "Mirror the blur" 0.0 0.0 1.0 1.0

#pragma parameter FILL_GAMMA "Background fill gamma adjustment" 1.4 0.5 2.0 0.1

#pragma parameter SAMPLE_SIZE "No. of lines for rendering the blur" 16.0 1.0 1024.0 1.0
// clang-format on

// clang-format off
#pragma parameter DUAL_FILTER_SETTINGS "=== Dual Filter Blur & Bloom v1.2 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter BLUR_RADIUS "Blur radius" 1.0 0.0 7.5 0.1
// clang-format on

// clang-format off
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.5 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SHARP "Pixel AA sharpening amount" 1.5 0.0 2.0 0.05
#pragma parameter PIX_AA_GAMMA "Enable gamma-correct blending" 1.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX "Enable subpixel AA" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX_ORIENTATION "Subpixel layout (0=RGB, 1=RGB vert., 2=BGR, 3=BGR vert.)" 0.0 0.0 3.0 1.0
// clang-format on

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
#define SourceSize \
    vec4(TextureSize, 1.0 / TextureSize)  // either TextureSize or InputSize
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
uniform COMPAT_PRECISION vec2 OutputSize; // = What you think it is
uniform COMPAT_PRECISION vec2 TextureSize; // = POT dimensions larger than InputSize
uniform COMPAT_PRECISION vec2 InputSize; // = What you think it is
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize \
    vec4(TextureSize, 1.0 / TextureSize)  // either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

uniform COMPAT_PRECISION vec2 FinalViewportSize; // = What you think it is
uniform COMPAT_PRECISION vec2 OrigInputSize; // = What you think it is
#define OriginalInputSize OrigInputSize
uniform COMPAT_PRECISION vec2 OrigTextureSize; // POT dimensions larger than OrigInputSize
#define OriginalInputPOTSize OrigTextureSize

const int tppfont[] = int[13](31599,  // 0 111101101101111
                              9370,   // 1 010010010011010
                              29671,  // 2 111001111100111
                              31143,  // 3 111100110100111
                              18925,  // 4 100100111101101
                              31183,  // 5 111100111001111
                              31689,  // 6 111101111001001
                              9383,   // 7 010010010100111
                              31727,  // 8 111101111101111
                              31215,  // 9 111100111101111
                              8192,   // . 010000000000000
                              448,    // - 000000111000000
                              0       //   000000000000000
);

const int ipow10[12] =
    int[12](1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000,
            1000000000, 2147483647, 2147483647);
#define calc_ipow10(x) ipow10[x]

float char3x5(int ch, vec2 uv) {
    vec2 fuv = fract(uv);
    ivec2 pos = ivec2(fuv * vec2(4, 6));
    int offset = pos.x + pos.y * 3;
    // In 16-bit mode, overshifting produces weird results.  Make surt to clip
    // off.
    return (pos.x < 3 && pos.y < 5) ? float((tppfont[ch] >> offset) & 1) : 0.0;
}

float print3x5int(int num, vec2 uv, int places) {
    vec2 cuv = uv * vec2(places, 1.);
    vec2 luv = cuv * vec2(1, 1.);
    ivec2 iuv = ivec2(luv);
    int posi = int(iuv.x);
    int marknegat = -1;
    if (num < 0) {
        marknegat = places - int(log(-float(num)) / log(10.0)) - 2;
    }
    num = abs(num);
    int nn = (num / calc_ipow10(places - posi - 1));
    if (posi == marknegat)
        nn = 11;
    else if (nn <= 0 && posi != places - 1)
        nn = 12;
    else
        nn %= 10;
    int ch = nn;
    return char3x5(ch, fract(cuv) * vec2(1., 1.));
}

// Zero Leading Integer Print
float print3x5intzl(int num, vec2 uv, int places) {
    vec2 cuv = uv * vec2(places, 1.);
    vec2 luv = cuv * vec2(1, 1.);
    ivec2 iuv = ivec2(luv);
    int posi = int(iuv.x);
    int nn = (num / calc_ipow10(places - posi - 1));
    nn %= 10;
    int ch = nn;
    return char3x5(ch, fract(cuv) * vec2(1., 1.));
}

float print3x5float(float num, vec2 uv, int wholecount, int decimalcount) {
    vec2 cuv = uv * vec2(wholecount + decimalcount + 1, 1.);
    vec2 luv = cuv * vec2(1, 1);
    ivec2 iuv = ivec2(luv);
    int posi = int(iuv.x);
    int nn = 10;

    int marknegat = -1;
    if (num < 0.0) {
        marknegat = wholecount - 2 - int(log(-num) / log(10.0));
    }

    num = abs(num);
    num += pow(.1f, float(decimalcount)) * .499;
    int nv = int(num);

    if (posi < wholecount) {
        int wholediff = posi - wholecount + 1;
        float v = (pow(10.0, float(wholediff)));
        int ni = int(float(nv) * v);
        if (posi == marknegat)
            nn = 11;
        else if (ni <= 0 && wholediff != 0)
            nn = 12;  // Blank out.
        else
            nn = ni % 10;
    } else if (posi > wholecount) {
        num -= float(nv);
        nn = int(num * pow(10.0, float(posi - wholecount)));
        nn %= 10;
    }
    int ch = nn;

    return char3x5(ch, fract(cuv) * vec2(1, 1.));
}

void main() {
    FragColor =
        pow(vec4(COMPAT_TEXTURE(Source, vTexCoord).rgb, 1.0), vec4(2.2));



    // vec2 uv = vTexCoord * TextureSize / InputSize;
    // //   FragColor.rgb = vec3(max(uv.x, uv.y));

    // if (uv.x < 0.5) {
    //     uv.y *= 12.0;
    //     uv.x *= 4.0;
    //     FragColor =
    //         vec4(vec3(print3x5int(int(OrigTextureSize.x), uv, 4)), 1.0);
    // } else {
    //     uv.x -= 0.5;
    //     uv.y *= 12.0;
    //     uv.x *= 4.0;
    //     FragColor =
    //         vec4(vec3(print3x5int(int(OrigTextureSize.y), uv, 4)), 1.0);
    // }
}
#endif
