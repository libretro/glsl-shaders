// white point adjustment
// adapted by Dogway (based on hunterk's original shader as template)
//
// based on blog post by Neil Bartlett (inspired on Tanner Helland's work)
// http://www.zombieprototypes.com/?p=210

#pragma parameter temperature "White Point" 6500.0 1000.0 12000.0 100.0
#pragma parameter luma_preserve "Preserve Luminance" 1.0 0.0 1.0 1.0
#pragma parameter red "Red Shift" 0.0 -1.0 1.0 0.01
#pragma parameter green "Green Shift" 0.0 -1.0 1.0 0.01
#pragma parameter blue "Blue Shift" 0.0 -1.0 1.0 0.01

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

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float temperature, luma_preserve, red, green, blue;
#else
#define temperature 6500.0
#define luma_preserve 1.0
#define red 0.0
#define green 0.0
#define blue 0.0
#endif

// white point adjustment
// based on blog post by Neil Bartlett (inspired by Tanner Helland's work)
// http://www.zombieprototypes.com/?p=210
vec3 wp_adjust(vec3 color){
   float temp = temperature / 100.0;
   
   // all calculations assume a scale of 255. We'll normalize this at the end
   vec3 wp = vec3(255.);
   
   // calculate RED
   wp.r = (temp <= 66.) ? 255. : 351.97690566805693 + 0.114206453784165 * (temp - 55.) - 40.25366309332127 * log(temp - 55.);
   
   // calculate GREEN
   float mg = - 155.25485562709179 - 0.44596950469579133 * (temp - 2.)  + 104.49216199393888 * log(temp - 2.);
   float pg =   325.4494125711974  + 0.07943456536662342 * (temp - 50.) - 28.0852963507957   * log(temp - 50.);
   wp.g = (temp <= 66.) ? mg : pg;
   
   // calculate BLUE
   wp.b = (temp >= 66.) ? 255. : (temp <= 19.) ? 0. : - 254.76935184120902 + 0.8274096064007395 * (temp - 10.) + 115.67994401066147 * log(temp - 10.) ;
   
   // clamp and normalize
   wp.rgb = clamp(wp.rgb, vec3(0.), vec3(255.)) / vec3(255.);
   
   // this is dumb, but various cores don't always show white as white. Use this to make white white...
   wp.rgb += vec3(red, green, blue);
   
   return (color * wp);
}

vec3 sRGB_to_XYZ(vec3 RGB){

    const mat3x3 m = mat3x3(
    0.4124564,  0.3575761,  0.1804375,
    0.2126729,  0.7151522,  0.0721750,
    0.0193339,  0.1191920,  0.9503041);
    return RGB * m;
}


vec3 XYZtoYxy(vec3 XYZ){

    float XYZrgb = XYZ.r+XYZ.g+XYZ.b;
    float Yxyr = XYZ.g;
    float Yxyg = (XYZrgb <= 0.0) ? 0.3805 : XYZ.r / XYZrgb;
    float Yxyb = (XYZrgb <= 0.0) ? 0.3769 : XYZ.g / XYZrgb;
    return vec3(Yxyr,Yxyg,Yxyb);
}

vec3 XYZ_to_sRGB(vec3 XYZ){

    const mat3x3 m = mat3x3(
    3.2404542, -1.5371385, -0.4985314,
   -0.9692660,  1.8760108,  0.0415560,
    0.0556434, -0.2040259,  1.0572252);
    return XYZ * m;
}


vec3 YxytoXYZ(vec3 Yxy){

    float Xs = Yxy.r * (Yxy.g/Yxy.b);
    float Xsz = (Yxy.r <= 0.0) ? 0 : 1;
    vec3 XYZ = vec3(Xsz,Xsz,Xsz) * vec3(Xs, Yxy.r, (Xs/Yxy.g)-Xs-Yxy.r);
    return XYZ;
}


void main()
{
   vec3 original = COMPAT_TEXTURE(Source, vTexCoord).rgb;
   vec3 adjusted = wp_adjust(original);
   vec3 base_luma = XYZtoYxy(sRGB_to_XYZ(original));
   vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
   adjusted = (luma_preserve > 0.5) ? adjusted_luma + (vec3(base_luma.r,0.,0.) - vec3(adjusted_luma.r,0.,0.)) : adjusted_luma;
   FragColor = vec4(XYZ_to_sRGB(YxytoXYZ(adjusted)), 1.0);
} 
#endif
