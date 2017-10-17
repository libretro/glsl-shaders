// Parameter lines go here:
#pragma parameter intensity "NTSC Intensity" 1.0 0.0 1.0 0.05

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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
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
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float intensity;
#else
#define intensity 1.0
#endif

vec3 DecodeGamma(vec3 color, float gamma)
{
    color = clamp(color, 0.0, 1.0);
    color.r = (color.r <= 0.00313066844250063) ?
    color.r * 12.92 : 1.055 * pow(color.r, 1.0 / gamma) - 0.055;
    color.g = (color.g <= 0.00313066844250063) ?
    color.g * 12.92 : 1.055 * pow(color.g, 1.0 / gamma) - 0.055;
    color.b = (color.b <= 0.00313066844250063) ?
    color.b * 12.92 : 1.055 * pow(color.b, 1.0 / gamma) - 0.055;

    return color;
}

vec3 RGBtoXYZ(vec3 RGB)
  {
      mat3 m = mat3(
      0.6068909, 0.1735011, 0.2003480,
      0.2989164, 0.5865990, 0.1144845,
      0.0000000, 0.0660957, 1.1162243);
  
    return RGB * m;
  }

vec3 XYZtoSRGB(vec3 XYZ)
{
    mat3 m = mat3(
    3.2404542,-1.5371385,-0.4985314,
   -0.9692660, 1.8760108, 0.0415560,
    0.0556434,-0.2040259, 1.0572252);

    return XYZ * m;
  }

vec3 XYZtoRGB(vec3 XYZ)
  {
      mat3 m = mat3(
      1.9099961, -0.5324542, -0.2882091,
     -0.9846663,  1.9991710, -0.0283082,
      0.0583056, -0.1183781,  0.8975535);
  
    return XYZ * m;
}

// conversion from NTSC RGB Reference White D65 ( color space used by NA/Japan TV's ) to XYZ
vec3 NTSC(vec3 c)
 {
     vec3 v = vec3(pow(c.r, 2.2), pow(c.g, 2.2), pow(c.b, 2.2)); //Inverse Companding
     return RGBtoXYZ(v);
 }
 
// conversion from XYZ to sRGB Reference White D65 ( color space used by windows ) 
vec3 sRGB(vec3 c)
 {
     vec3 v = XYZtoSRGB(c);
     v = DecodeGamma(v, 2.4); //Companding
 
     return v;
 }

// NTSC RGB to sRGB
vec3 NTSCtoSRGB( vec3 c )
 { 
     return sRGB(NTSC( c )); 
 }

void main()
{
     vec3 color = COMPAT_TEXTURE(Source, vTexCoord).rgb;
     color = mix(color.rgb, NTSCtoSRGB(color.rgb), intensity);
   FragColor = vec4(color, 1.0);
} 
#endif
