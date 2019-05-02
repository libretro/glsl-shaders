// white point adjustment
// by hunterk
// based on blog post by Tanner Helland
// http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/

#pragma parameter temperature "White Point" 6500.0 0.0 12000.0 100.0
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
// based on blog post by Tanner Helland
// http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
vec3 wp_adjust(vec3 color){
   float temp = temperature / 100.0;
   
   // all calculations assume a scale of 255. We'll normalize this at the end
   vec3 wp = vec3(255.);
   
   // calculate RED
   wp.r = (temp <= 66.) ? 255. : 329.698727446 * pow((temp - 60.), -0.1332047592);
   
   // calculate GREEN
   wp.g = (temp <= 66.) ? 99.4708025861 * log(temp) - 161.1195681661 : 288.1221695283 * pow((temp - 60.), -0.0755148492);
   
   // calculate BLUE
   wp.b = (temp >= 66.) ? 255. : (temp <= 19.) ? 0. : 138.5177312231 * log(temp - 10.) - 305.0447927307;
   
   // clamp and normalize
   wp.rgb = clamp(wp.rgb, vec3(0.), vec3(255.)) / vec3(255.);
   
   // this is dumb, but various cores don't always show white as white. Use this to make white white...
   wp.rgb += vec3(red, green, blue);
   
   return (color * wp);
}

vec3 RGBtoYIQ(vec3 RGB){
   const mat3x3 m = mat3x3(
   0.2989, 0.5870, 0.1140,
   0.5959, -0.2744, -0.3216,
   0.2115, -0.5229, 0.3114);
   return RGB * m;
}

vec3 YIQtoRGB(vec3 YIQ){
   const mat3x3 m = mat3x3(
   1.0, 0.956, 0.6210,
   1.0, -0.2720, -0.6474,
   1.0, -1.1060, 1.7046);
   return YIQ * m;
}

void main()
{
   vec3 original = COMPAT_TEXTURE(Source, vTexCoord).rgb;
   vec3 adjusted = wp_adjust(original);
   vec3 base_luma = RGBtoYIQ(original);
   vec3 adjusted_luma = RGBtoYIQ(adjusted);
   adjusted = (luma_preserve > 0.5) ? adjusted_luma + (vec3(base_luma.r,0.,0.) - vec3(adjusted_luma.r,0.,0.)) : adjusted_luma;
   FragColor = vec4(YIQtoRGB(adjusted), 1.0);
} 
#endif
