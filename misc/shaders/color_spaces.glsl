#version 140

/*
RGB Colorspace Conversion by Tynach

Converts images encoded for different TV standards.

Converted from shadertoy to Retroarch by DariusG 11/2023
https://www.shadertoy.com/view/MtfBRB
*/
#pragma parameter CS_TO "Col.Space: RGB-NTSC1953-PAL-NTSC 80s-NTSC 90s-Sony" 0.0 0.0 5.0 1.0 
#pragma parameter CS_FROM "Device Col.Space: RGB-Android-Rec709-RGBtv-Rec2020" 0.0 0.0 4.0 1.0 
#pragma parameter BLACK_lvl  "Black Level" 0.0 -0.20 0.20 0.01 


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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float CS_FROM;
uniform COMPAT_PRECISION float CS_TO;
uniform COMPAT_PRECISION float BLACK_lvl;
#else
#define CS_FROM 0.0
#define CS_TO 0.0
#define BLACK_lvl 0.0
#endif

/*
 * Structures
 */

// Parameters for transfer characteristics (gamma curves)
struct transfer {
    // Exponent used to linearize the signal
    float power;

    // Offset from 0.0 for the exponential curve
    float off;

    // Slope of linear segment near 0
    float slope;

    // Values below this are divided by slope during linearization
    float cutoffToLinear;

    // Values below this are multiplied by slope during gamma correction
    float cutoffToGamma;

    // Gamma-corrected values should be in the range 16-235
    bool tvRange;
};

// Parameters for a colorspace
struct rgb_space {
    // Chromaticity coordinates (xyz) for Red, Green, and Blue primaries
    mat3 primaries;

    // Chromaticity coordinates (xyz) for white point
    vec3 whitePoint;

    // Linearization and gamma correction parameters
    transfer trc;
};


/*
 * Preprocessor 'functions' that help build colorspaces as constants
 */

// Turns 6 chromaticity coordinates into a 3x3 matrix
#define Primaries(rx, ry, gx, gy, bx, by)\
    mat3(\
        (rx), (ry), 1.0 - (rx) - (ry),\
        (gx), (gy), 1.0 - (gx) - (gy),\
        (bx), (by), 1.0 - (bx) - (by))

// Creates a whitepoint's xyz chromaticity coordinates from the given xy coordinates
#define White(x, y)\
    vec3((x), (y), 1.0 - (x) - (y))/(y)

// Creates a scaling matrix using a vec3 to set the xyz scalars
#define diag(v)\
    mat3(\
        (v).x, 0.0, 0.0,\
        0.0, (v).y, 0.0,\
        0.0, 0.0, (v).z)

// Creates a conversion matrix that turns RGB colors into XYZ colors
#define rgbToXyz(space)\
    space.primaries*diag(inverse((space).primaries)*(space).whitePoint)

// Creates a conversion matrix that turns XYZ colors into RGB colors
#define xyzToRgb(space)\
    inverse(rgbToXyz(space))

// Creates a conversion matrix converts linear RGB colors from one colorspace to another
#define conversionMatrix(f, t)\
    xyzToRgb(t)*rgbToXyz(f)


/*
 * Chromaticities for RGB primaries
 */

// Original 1953 NTSC primaries
const mat3 primariesNtsc = Primaries(
    0.67, 0.33,
    0.21, 0.71,
    0.14, 0.08
);

// Never-popular and antiquated 'HDTV' primaries based mostly on 1953 NTSC
const mat3 primaries240m = Primaries(
    0.67, 0.33,
    0.21, 0.71,
    0.15, 0.06
);

// European Broadcasting Union primaries for SDTV and Rec. 601 (625 lines)
const mat3 primariesEbu = Primaries(
    0.64, 0.33,
    0.29, 0.6,
    0.15, 0.06
);

// P22 Phosphor primaries (allegedly; only found one source)
// Used by older versions of SMPTE-C, before specific chromaticities were given
const mat3 primariesP22 = Primaries(
    0.61, 0.342,
    0.298, 0.588,
    0.151, 0.064
);

// Modern day SMPTE-C primaries, used in modern NTSC and Rec. 601 (525 lines)
const mat3 primariesSmpteC = Primaries(
    0.63, 0.34,
    0.31, 0.595,
    0.155, 0.07
);

// Alleged primaries for old Sony TVs with a very blue whitepoint
const mat3 primariesSony = Primaries(
    0.625, 0.34,
    0.28, 0.595,
    0.155, 0.07
);

// Rec. 709 (HDTV) and sRGB primaries
const mat3 primaries709 = Primaries(
    0.64, 0.33,
    0.3, 0.6,
    0.15, 0.06
);

// Rec. 2020 UHDTV primaries
const mat3 primaries2020 = Primaries(
    0.708, 0.292,
    0.17, 0.797,
    0.131, 0.046
);

// Approximate Google Pixel primaries
const mat3 primariesPixel = Primaries(
    0.66, 0.34,
    0.228, 0.719,
    0.144, 0.04
);


/*
 * Chromaticities for white points
 */

// Standard Illuminant C. White point for the original 1953 NTSC color system
const vec3 whiteC = White(0.310063, 0.316158);

// Standard illuminant E (also known as the 'equal energy' white point)
const vec3 whiteE = vec3(1.0);

// Alleged whitepoint to use with the P22 phosphors (D65 might be more proper)
const vec3 whiteP22 = White(0.313, 0.329);

// Standard illuminant D65. Note that there are more digits here than specified
// in either sRGB or Rec 709, so in some cases results may differ from other
// software. Color temperature is roughly 6504 K (originally 6500K, but complex
// science stuff made them realize that was innaccurate)
const vec3 whiteD65 = White(0.312713, 0.329016);

// Standard illuminant D50. Just included for the sake of including it. Content
// for Rec. 709 and sRGB is recommended to be produced using a D50 whitepoint.
// For the same reason as D65, the color temperature is 5003 K instead of 5000 K
const vec3 whiteD50 = White(0.34567, 0.35850);

// Very blue white point for old Sony televisions. Color temperature of 9300 K.
// Use with the 'primariesSony' RGB primaries defined above
const vec3 whiteSony = White(0.283, 0.298);

// Approximate Google Pixel white point
//const vec3 whitePixel = white(0.299, 0.324);
const vec3 whitePixel = White(0.312, 0.334);


/*
 * Gamma curve parameters
 */

// Gamma of 2.2; not linear near 0. Was defined abstractly to be used by early
// NTSC systems, before SMPTE 170M was modified to specify a more exact curve
const transfer gam22 = transfer(2.2, 0.0, 1.0, 0.0, 0.0, true);

// Gamma of 2.2; not linear near 0 and full range. Commonly used with some
// computer monitors, including all Adobe RGB monitors
const transfer gam22Pc = transfer(2.2, 0.0, 1.0, 0.0, 0.0, false);

// Gamma of 2.4; not linear near 0. Seems a popular choice among some people
// online, so I included it. I don't think any standard uses this
const transfer gam24 = transfer(2.4, 0.0, 1.0, 0.0, 0.0, true);

// Gamma of 2.5; not linear near 0. Approximately what old Sony TVs used
const transfer gam25 = transfer(2.5, 0.0, 1.0, 0.0, 0.0, true);

// Gamma of 2.8; not linear near 0. Loosely defined gamma for European SDTV
const transfer gam28 = transfer(2.8, 0.0, 1.0, 0.0, 0.0, true);

// Modern SMPTE 170M, as well as Rec. 601, Rec. 709, and a rough approximation
// for Rec. 2020 content as well. Do not use with Rec. 2020 if you work with
// high bit depths!
const transfer gam170m = transfer(1.0/0.45, 0.099, 4.5, 0.0812, 0.018, true);

// Gamma for sRGB. Besides being full-range (0-255 values), this is the only
// difference between sRGB and Rec. 709.
const transfer gamSrgb = transfer(2.4, 0.055, 12.92, 0.04045, 0.0031308, false);
const transfer gamtweak = transfer(2.2, 0.055, 12.92, 0.04045, 0.0031308, false);

// This is sRGB's gamma, but set to TV value ranges (16-235)
const transfer gamSrgbTv = transfer(2.4, 0.055, 12.92, 0.04045, 0.0031308, true);



/*
 * Conversion Functions
 */

// Converts RGB colors to a linear light scale
vec4 toLinear(vec4 color, const transfer trc)
{
    if (trc.tvRange) {
        color = color*85.0/73.0 - 16.0/219.0;
    }

    bvec4 cutoff = lessThan(color, vec4(trc.cutoffToLinear));
    bvec4 negCutoff = lessThanEqual(color, vec4(-1.0*trc.cutoffToLinear));
    vec4 higher = pow((color + trc.off)/(1.0 + trc.off), vec4(trc.power));
    vec4 lower = color/trc.slope;
    vec4 neg = -1.0*pow((color - trc.off)/(-1.0 - trc.off), vec4(trc.power));

    color = mix(higher, lower, cutoff);
    color = mix(color, neg, negCutoff);

    return color;
}

// Gamma-corrects RGB colors to be sent to a display
vec4 toGamma(vec4 color, const transfer trc)
{
    bvec4 cutoff = lessThan(color, vec4(trc.cutoffToGamma));
    bvec4 negCutoff = lessThanEqual(color, vec4(-1.0*trc.cutoffToGamma));
    vec4 higher = (1.0 + trc.off)*pow(color, vec4(1.0/trc.power)) - trc.off;
    vec4 lower = color*trc.slope;
    vec4 neg = (-1.0 - trc.off)*pow(-1.0*color, vec4(1.0/trc.power)) + trc.off;

    color = mix(higher, lower, cutoff);
    color = mix(color, neg, negCutoff);

    if (trc.tvRange) {
        color = color*73.0/85.0 + 16.0/255.0;
    }

    return color;
}

// Scales a color to the closest in-gamut representation of that color
vec4 gamutScale(vec4 color, float luma)
{
    float low = min(color.r, min(color.g, min(color.b, 0.0)));
    float high = max(color.r, max(color.g, max(color.b, 1.0)));

    float lowScale = low/(low - luma);
    float highScale = max((high - 1.0)/(high - luma), 0.0);
    float scale = max(lowScale, highScale);
    color.rgb += scale*(luma - color.rgb);

    return color;
}

// Converts from xy to RGB
vec4 convert(vec4 color, rgb_space from, rgb_space to)
{
    color.xyz = rgbToXyz(from)*color.rgb;
    float luma = color.y;

    color.rgb = xyzToRgb(to)*color.rgb;
    color = gamutScale(color, luma);

    return color;
}

// Sample a texture's linear light values
#define texLinear(tex, offset, trc) \
toLinear(texelFetch(tex, ivec2(texCoord + offset), 0), trc)



/*
 * RGB Colorspaces
 */


// Destinations

// sRGB (mostly the same as Rec. 709, but different gamma and full range values)
const rgb_space Srgb = rgb_space(primaries709, whiteD65, gamSrgb);

// Approximate Google Pixel colorspace
const rgb_space Pixel = rgb_space(primariesPixel, whitePixel, gam22Pc);

// Rec. 709 (HDTV)
const rgb_space Rec709 = rgb_space(primaries709, whiteD65, gam170m);

// Same as sRGB, but with limited range values (16-235)
const rgb_space SrgbTv = rgb_space(primaries709, whiteD65, gamSrgbTv);

// Rec. 2020
const rgb_space Rec2020 = rgb_space(primaries2020, whiteD65, gam170m);

// Sources

// Original 1953 NTSC
const rgb_space Ntsc = rgb_space(primariesNtsc, whiteC, gam22);

// European Broadcasting Union SDTV
const rgb_space Ebu = rgb_space(primariesEbu, whiteD65, gam28);

// Original, imprecise colorspace for NTSC after 1987 (probably incorrect)
const rgb_space SmpteC = rgb_space(primariesP22, whiteD65, gam22);

// Modern SMPTE "C" colorimetry
const rgb_space Smpte170m = rgb_space(primariesSmpteC, whiteD65, gam170m);

// Old Sony displays using high temperature white point
const rgb_space Sony = rgb_space(primariesSony, whiteSony, gam25);

// Mostly unused and early HDTV standard (SMPTE 240M)
const rgb_space Smpte240m = rgb_space(primaries240m, whiteD65, gam22);


void main()
{
    // Change these to change what colorspace is being converted from/to
    
    rgb_space from = rgb_space(primariesSony, whiteSony, gam25);
    rgb_space to = rgb_space(primaries709, whiteD65, gamSrgbTv);

    vec2 texCoord =vTexCoord*OutputSize.xy;
    vec2 scale = SourceSize.xy/OutputSize.xy;
    texCoord *= scale;

    if (CS_FROM == 0.0) from = Srgb;
    if (CS_FROM == 1.0) from = Pixel;
    if (CS_FROM == 2.0) from = Rec709;
    if (CS_FROM == 3.0) from = SrgbTv;
    if (CS_FROM == 4.0) from = Rec2020;

     
    if (CS_TO == 0.0) to = Srgb;
    if (CS_TO == 1.0) to = Ntsc;
    if (CS_TO == 2.0) to = Ebu;
    if (CS_TO == 3.0) to = SmpteC;
    if (CS_TO == 4.0) to = Smpte170m;
    if (CS_TO == 5.0) to = Sony;

    vec4 color = texLinear(Source, vec2(0, 0), from.trc);
    
    color = convert(color, from, to);
    color = toGamma(color, to.trc);
    color.rgb -= vec3(BLACK_lvl);
    color.rgb *= vec3(1.0)/vec3(1.0-BLACK_lvl);
    FragColor = color;
}
#endif
