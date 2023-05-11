/*
   CRT Glass shader
      > CRT related artifacts:
        ::grain
        ::glass inner reflection
        ::glass outer reflection
        ::chromatic aberration (for beam deconvergence and glass diffraction)
        ::screen flicker
        ::screen jitter
        ::afterglow (dr-venom's mod)
        ::CRT border corner (cgwg's crt-geom)
      > Stack just before scanlines. Works better with curved geometry modes.

   Author: Dogway
   License: Public domain
*/

#pragma parameter g_csize      "Corner Size"         0.02 0.0 0.07 0.01
#pragma parameter g_bsize      "Border Smoothness"   600.0 100.0 600.0 25.0
#pragma parameter g_flicker    "Screen Flicker"      0.25 0.0 1.0 0.01
#pragma parameter g_shaker     "Screen Shake"        0.02 0.0 0.5 0.01
#pragma parameter g_refltog    "Reflection Toggle"   1.0 0.0 1.0 1.00
#pragma parameter g_reflgrain  "Refl. Deband Grain"  0.0 0.0 2.0 0.01
#pragma parameter g_reflstr    "Refl. Brightness"    0.15 0.0 1.0 0.01
#pragma parameter g_fresnel    "Refl. Fresnel"       1.0 0.0 1.0 0.10
#pragma parameter g_reflblur   "Refl. Blur"          0.6 0.0 1.0 0.10
#pragma parameter gz           "Zoom"                1.2 1.0 1.5 0.01
#pragma parameter gx           "Shift-X"             0.0 -1.0 1.0 0.01
#pragma parameter gy           "Shift-Y"            -0.01 -1.0 1.0 0.01
#pragma parameter gzr          "Zoom Red"            1.03 1.0 1.5 0.01
#pragma parameter gzg          "Zoom Green"          1.01 1.0 1.5 0.01
#pragma parameter gzb          "Zoom Blue"           1.0 1.0 1.5 0.01
#pragma parameter goxr         "Shift-X Red"         0.0 -1.0 1.0 0.01
#pragma parameter goyr         "Shift-Y Red"        -0.01 -1.0 1.0 0.01
#pragma parameter goxg         "Shift-X Green"       0.0 -1.0 1.0 0.01
#pragma parameter goyg         "Shift-Y Green"      -0.01 -1.0 1.0 0.01
#pragma parameter goxb         "Shift-X Blue"        0.0 -1.0 1.0 0.01
#pragma parameter goyb         "Shift-Y Blue"        0.0 -1.0 1.0 0.01

// https://www.desmos.com/calculator/1nfq4uubnx
// PER = 2.0 for realistic (1.0 or less when using scanlines). Phosphor Index; it's the same as in the "grade" shader
#pragma parameter TO           "Afterglow OFF/ON"                            1.0 0.0 1.0 1.0
#pragma parameter PH           "AG Phosphor (0:RGB 1:NTSC-U 2:NTSC-J 3:PAL)" 2.0 0.0 3.0 1.0
#pragma parameter ASAT         "Afterglow Saturation"                        0.20 0.0 1.0 0.01
#pragma parameter PER          "Persistence (more is less)"                  0.75 0.5 2.0 0.1


#define SW    TO
#define sat   ASAT
#define GRAIN g_reflgrain

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
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION float g_reflblur;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define reflblur g_reflblur

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    float blur = abs(1. - reflblur) + 1.;
    vec2 ps = vec2(1.0/TextureSize.x, 1.0/TextureSize.y) / blur;
    float dx = ps.x;
    float dy = ps.y;

    t1 = TEX0.xxxy + vec4(    -dx,    0.0,     dx,    -dy);
    t2 = TEX0.xxxy + vec4(    -dx,    0.0,     dx,    0.0);
    t3 = TEX0.xxxy + vec4(    -dx,    0.0,     dx,     dy);
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
uniform sampler2D Prev1Texture;
uniform sampler2D Prev2Texture;
uniform sampler2D Prev3Texture;
uniform sampler2D Prev4Texture;
uniform sampler2D Prev5Texture;
uniform sampler2D Prev6Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float g_csize;
uniform COMPAT_PRECISION float g_bsize;
uniform COMPAT_PRECISION float g_flicker;
uniform COMPAT_PRECISION float g_shaker;
uniform COMPAT_PRECISION float g_refltog;
uniform COMPAT_PRECISION float g_reflstr;
uniform COMPAT_PRECISION float g_fresnel;
uniform COMPAT_PRECISION float g_reflblur;
uniform COMPAT_PRECISION float gz;
uniform COMPAT_PRECISION float gx;
uniform COMPAT_PRECISION float gy;
uniform COMPAT_PRECISION float gzr;
uniform COMPAT_PRECISION float gzg;
uniform COMPAT_PRECISION float gzb;
uniform COMPAT_PRECISION float goxr;
uniform COMPAT_PRECISION float goyr;
uniform COMPAT_PRECISION float goxg;
uniform COMPAT_PRECISION float goyg;
uniform COMPAT_PRECISION float goxb;
uniform COMPAT_PRECISION float goyb;
uniform COMPAT_PRECISION float SW;
uniform COMPAT_PRECISION float PH;
uniform COMPAT_PRECISION float PER;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float GRAIN;
#else
#define g_csize 0.00
#define g_bsize 600.00
#define g_flicker 0.00
#define g_shaker 0.00
#define g_refltog 1.00
#define g_reflstr 0.00
#define g_fresnel 1.00
#define g_reflblur 0.6
#define gz 1.0
#define gx 0.0
#define gy 0.0
#define gzr 1.0
#define gzg 1.0
#define gzb 1.0
#define goxr 0.0
#define goyr 0.0
#define goxg 0.0
#define goyg 0.0
#define goxb 0.0
#define goyb 0.0
#define SW 1.0
#define PH 2.0
#define PER 0.75
#define sat 0.20
#define GRAIN 0.05
#endif

// Wide usage friendly PRNG, shamelessly stolen from a GLSL tricks forum post.
// Obtain random numbers by calling rand(h), followed by h = permute(h) to
// update the state. Assumes the texture was hooked.
float mod289(float x)
{
    return x - floor(x / 289.0) * 289.0;
}

float permute(float x)
{
    return mod289((34.0 * x + 1.0) * x);
}

float randg(float x)
{
    return fract(x * 0.024390243);
}


float rand(float co, float size){
    return fract(sin(dot(co, 12.9898)) * size);
}


vec3 afterglow(float Pho, vec3 decay)
{
    // Rec.601
    vec3 RGB =    vec3(0.299, 0.587, 0.114);
    // SMPTE
    vec3 NTSC =   vec3(0.310, 0.595, 0.095);
    // JAP
    vec3 NTSC_J = vec3(0.280, 0.605, 0.115);
    // PAL
    vec3 PAL =    vec3(0.290, 0.600, 0.110);

    vec3 p_in;

    if (Pho ==  0.0) { p_in = RGB;            } else
    if (Pho ==  1.0) { p_in = NTSC;           } else
    if (Pho ==  2.0) { p_in = NTSC_J;         } else
    if (Pho ==  3.0) { p_in = PAL;            }

// Phosphor Response / Cone Response
    vec3 p_res = (p_in / (vec3(0.21259990334510803, 0.71517896652221680, 0.07222118973731995)) / 10.0);

    float decr = clamp((log(1. / p_res.r) + 0.2) / (decay.r), 0., 1.);
    float decg = clamp((log(1. / p_res.g) + 0.2) / (decay.g), 0., 1.);
    float decb = clamp((log(1. / p_res.b) + 0.2) / (decay.b), 0., 1.);

    return vec3(decr, decg, decb);
}

//  Borrowed from cgwg's crt-geom, under GPL
float corner(vec2 coord)
{
    coord *= SourceSize.xy / InputSize.xy;
    coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
    coord = min(coord, vec2(1.0)-coord) * vec2(1.0, OutputSize.y/OutputSize.x);
    vec2 cdist = vec2(max(g_csize, max((1.0-smoothstep(100.0,600.0,g_bsize))*0.01,0.002)));
    coord = (cdist - min(coord,cdist));
    float dist = sqrt(dot(coord,coord));
    return clamp((cdist.x-dist)*g_bsize,0.0, 1.0);
}




void main()
{

    vec2 c_dist = (vec2(0.5) * InputSize) / TextureSize;
    vec2 ch_dist = (InputSize / TextureSize) / 2.;
    vec2 vpos = vTexCoord * (TextureSize.xy / InputSize.xy);

    float vert_msk = abs(1. - vpos.y);
    float center_msk = clamp(abs(1. - (vTexCoord.x) * SourceSize.x / InputSize.x - ch_dist.x), 0., 1.);
    float horiz_msk = clamp(max(center_msk - 0.2, 0.0) + 0.1, 0., 1.);

    float zoom   = fract(gz) / 10.;

// Screen Jitter ------------------------------------

    float scale   = 2.0 + g_shaker/0.05;
    float prob    = 0.5 + g_shaker/3.0;
    float shaker  = rand(      float(FrameCount), 43758.5453)           * \
                    rand(      float(FrameCount), 4.37585453) * g_shaker;

          shaker  = shaker + shaker * round(rand(float(FrameCount), 53.7585453) * prob) * scale * clamp(g_shaker,0.0,0.01)*100.;

    vec2 coords  = vec2(gx,   gy   + shaker * 0.5);
    vec2 coordsr = vec2(goxr, goyr + shaker);
    vec2 coordsg = vec2(goxg, goyg + shaker);
    vec2 coordsb = vec2(goxb, goyb + shaker);


// Screen Zoom ------------------------------------

    float cr = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / (fract(gzr)/20. + 1.) + c_dist + coordsr/40.).r;
    float cg = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / (fract(gzg)/20. + 1.) + c_dist + coordsg/40.).g;
    float cb = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / (fract(gzb)/20. + 1.) + c_dist + coordsb/40.).b;
    vec3 color = vec3(cr,cg,cb);

// AfterGlow --------------------------------------

    vec3 color1 = COMPAT_TEXTURE(Prev1Texture, TEX0.xy).rgb * afterglow(PH, vec3(PER)*10.);
    vec3 color2 = COMPAT_TEXTURE(Prev2Texture, TEX0.xy).rgb * afterglow(PH, vec3(PER)*20.);
    vec3 color3 = COMPAT_TEXTURE(Prev3Texture, TEX0.xy).rgb * afterglow(PH, vec3(PER)*30.);
    vec3 color4 = COMPAT_TEXTURE(Prev4Texture, TEX0.xy).rgb * afterglow(PH, vec3(PER)*40.);
    vec3 color5 = COMPAT_TEXTURE(Prev5Texture, TEX0.xy).rgb * afterglow(PH, vec3(PER)*50.);
    vec3 color6 = COMPAT_TEXTURE(Prev6Texture, TEX0.xy).rgb * afterglow(PH, vec3(PER)*60.);

    vec3 glow = max(max(max(max(max(color1, color2), color3), color4), color5), color6);

    glow = normalize(pow(glow + vec3(0.001), vec3(sat)))*length(glow);

    float glowY  = dot(pow(glow,  vec3(2.2)), vec3(0.21260, 0.71518, 0.07222));
    float colorY = dot(pow(color, vec3(2.2)), vec3(0.21260, 0.71518, 0.07222));

    vec3 colormax = (colorY > glowY) ? color : glow;

    color = (SW == 0.0) ? color : clamp(colormax,0.0,1.0);

//--------------------------------------

    float rA = COMPAT_TEXTURE(Source, (t1.xw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rB = COMPAT_TEXTURE(Source, (t1.yw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rC = COMPAT_TEXTURE(Source, (t1.zw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rD = COMPAT_TEXTURE(Source, (t2.xw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rE = COMPAT_TEXTURE(Source, (t2.yw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rF = COMPAT_TEXTURE(Source, (t2.zw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rG = COMPAT_TEXTURE(Source, (t3.xw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rH = COMPAT_TEXTURE(Source, (t3.yw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rI = COMPAT_TEXTURE(Source, (t3.zw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;

    float gA = COMPAT_TEXTURE(Source, (t1.xw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gB = COMPAT_TEXTURE(Source, (t1.yw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gC = COMPAT_TEXTURE(Source, (t1.zw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gD = COMPAT_TEXTURE(Source, (t2.xw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gE = COMPAT_TEXTURE(Source, (t2.yw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gF = COMPAT_TEXTURE(Source, (t2.zw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gG = COMPAT_TEXTURE(Source, (t3.xw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gH = COMPAT_TEXTURE(Source, (t3.yw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gI = COMPAT_TEXTURE(Source, (t3.zw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;

    float bA = COMPAT_TEXTURE(Source, (t1.xw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bB = COMPAT_TEXTURE(Source, (t1.yw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bC = COMPAT_TEXTURE(Source, (t1.zw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bD = COMPAT_TEXTURE(Source, (t2.xw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bE = COMPAT_TEXTURE(Source, (t2.yw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bF = COMPAT_TEXTURE(Source, (t2.zw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bG = COMPAT_TEXTURE(Source, (t3.xw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bH = COMPAT_TEXTURE(Source, (t3.yw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bI = COMPAT_TEXTURE(Source, (t3.zw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;

    vec3 sumA = vec3(rA, gA, bA);
    vec3 sumB = vec3(rB, gB, bB);
    vec3 sumC = vec3(rC, gC, bC);
    vec3 sumD = vec3(rD, gD, bD);
    vec3 sumE = vec3(rE, gE, bE);
    vec3 sumF = vec3(rF, gF, bF);
    vec3 sumG = vec3(rG, gG, bG);
    vec3 sumH = vec3(rH, gH, bH);
    vec3 sumI = vec3(rI, gI, bI);

    vec3 blurred = (sumE+sumA+sumC+sumD+sumF+sumG+sumI+sumB+sumH) / 9.0;


    vpos *= 1. - vpos.xy;
    float vig = vpos.x * vpos.y * 10.;
    float vig_msk = abs(1. - vig) * (center_msk * 2. + 0.3);
    vig = abs(1. - pow(vig, 0.1)) * vert_msk * (center_msk * 2. + 0.3);

    blurred = min((vig_msk + (1. - g_fresnel)), 1.0) * blurred;
    vig = clamp(vig * g_fresnel, 0.001, 1.0);
    vec3 vig_c = vec3(vig) * vec3(0.75, 0.93, 1.0);

// Reflection in
    vec4 reflection = clamp(vec4((1. - (1. - color ) * (1. - blurred.rgb * g_reflstr)) / (1. + g_reflstr / 3.), 1.), 0.0, 1.0);


// Reflection-out noise dithering, from deband.slang
    // Initialize the PRNG by hashing the position + a random uniform
    vec3 m = vec3(vTexCoord, randg(sin(vTexCoord.x / vTexCoord.y) * mod(float(FrameCount), 79) + 22.759)) + vec3(1.0);
    float h = permute(permute(permute(m.x) + m.y) + m.z);

    if (GRAIN > 0.0)
        {
            vec3 noise;
            noise.x = randg(h); h = permute(h);
            noise.y = randg(h); h = permute(h);
            noise.z = randg(h); h = permute(h);
            vig_c += GRAIN * (noise - 0.5);
        }

// Reflection out
    reflection = clamp(vec4(1. - (1. - reflection.rgb ) * (1. - vig_c / 7.), 1.), 0., 1.);

// Corner Size
    vpos *= (InputSize.xy/TextureSize.xy);

// Screen Flicker
    float flicker = (g_flicker == 0.0) ? 1.0 : mix(1. - g_flicker / 10., 1.0, rand(float(FrameCount), 4.37585453));

    reflection = (g_refltog == 0.0) ? clamp(COMPAT_TEXTURE(Source, vTexCoord) * flicker, 0., 1.) : clamp(reflection * flicker, 0., 1.);
    FragColor = corner(vpos) * reflection;
}
#endif
