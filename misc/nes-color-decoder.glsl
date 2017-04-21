// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter saturation "Saturation" 1.0 0.0 5.0 0.05
#pragma parameter hue_tweak "Hue" 0.0 -10.0 10.0 0.05
#pragma parameter contrast "Contrast" 1.0 0.0 2.0 0.05
#pragma parameter brightness "Brightness" 1.0 0.0 2.0 0.05
#pragma parameter gamma "Gamma" 1.8 1.0 2.5 0.05
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float saturation;
uniform COMPAT_PRECISION float hue_tweak;
uniform COMPAT_PRECISION float contrast;
uniform COMPAT_PRECISION float brightness;
uniform COMPAT_PRECISION float gamma;
#else
#define intensity 1.0
#endif

bool wave (int p, int color)
{
   return ((color + p + 8) % 12 < 6);
}

float gammafix (float f)
{
   return f < 0.0 ? 0.0 : pow(f, 2.2 / gamma);
}

vec3 MakeRGBColor(int emphasis, int level, int color)
{
   float y = 0.0;
   float i = 0.0;
   float q = 0.0;

   float r = 0.0;
   float g = 0.0;
   float b = 0.0;

   // Voltage levels, relative to synch voltage
   float black = 0.518;
   float white = 1.962;
   float attenuation = 0.746;
   const float levels[8] = float[] (   0.350 , 0.518, 0.962, 1.550,
                                       1.094, 1.506, 1.962, 1.962);
   
   float low  = levels[level + 4 * int(color == 0)];
   float high = levels[level + 4 * int(color < 13)];
   
   // Calculate the luma and chroma by emulating the relevant circuits:
   for(int p = 0; p < 12; p++) // 12 clock cycles per pixel.
   {
      // NES NTSC modulator (square wave between two voltage levels):
      float spot = wave(p, color) ? high : low;

      // De-emphasis bits attenuate a part of the signal:
      if ((bool(emphasis & 1) && wave(p, 12)) ||
          (bool(emphasis & 2) && wave(p, 4)) ||
          (bool(emphasis & 4) && wave(p, 8))) 
      {
          spot *= attenuation;
      }

      // Normalize:
      float v = (spot - black) / (white - black);

      // Ideal TV NTSC demodulator:
      // Apply contrast/brightness
      v = (v - 0.5) * contrast + 0.5;
      v *= (brightness / 12.0);

      y += v;
      i += v * cos((3.141592653 / 6.0) * (p + hue_tweak) );
      q += v * sin((3.141592653 / 6.0) * (p + hue_tweak) );

   }

   i *= saturation;
   q *= saturation;

   // Convert YIQ into RGB according to FCC-sanctioned conversion matrix.
   r = clamp((1.0 * gammafix(y +  0.946882 * i +  0.623557 * q)), 0, 1.0);
   g = clamp((1.0 * gammafix(y + -0.274788 * i + -0.635691 * q)), 0, 1.0);
   b = clamp((1.0 * gammafix(y + -1.108545 * i +  1.709007 * q)), 0, 1.0);

   return vec3(r,g,b);
}

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
uniform int FrameDirection;
uniform int FrameCount;
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

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
   vec4 c = texture(Source, vTexCoord.xy);

   // Extract the chroma, level, and emphasis from the normalized RGB triplet
   int color =    int(floor((c.r * 15.0) + 0.5));
   int level =    int(floor((c.g *  3.0) + 0.5));
   int emphasis = int(floor((c.b *  7.0) + 0.5));

   vec3 out_color = MakeRGBColor(emphasis, level, color);
   FragColor = vec4(out_color, 1.0);
} 
#endif
