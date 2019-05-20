#version 130

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

bool wave (int p, int color)
{
   return ((color + p + 8) % 12 < 6);
}

void main()
{
/* original palette decode for historical purposes:
  uint n = uint(COMPAT_TEXTURE(Source, vTexCoord).r);
  uint color = n & 0xfu;
  uint level = color < 0xeu ? (n>>4u)&3u : 1u;
uint emphasis = n >> 6u;
*/

   vec4 c = COMPAT_TEXTURE(Source, vTexCoord.xy);

   // Extract the chroma, level, and emphasis from the normalized RGB triplet
   int color =    int(floor((c.r * 15.0) + 0.5));
   int level =    int(floor((c.g *  3.0) + 0.5));
   int emphasis = int(floor((c.b *  7.0) + 0.5));

  const float levels[] = float[](0.350, 0.518, 0.962, 1.550,
				 1.094, 1.506, 1.962, 1.962);
  const float attenuation = 0.746;
  const float min = levels[0]*attenuation;
  const float max = levels[7];

  float lo_hi[] = float[](levels[uint(level) + 4u*uint(color == int(0x0u))],
			  levels[uint(level) + 4u*uint(color <  int(0xdu))]);

  uint x = uint(floor(vTexCoord.x*SourceSize.x*2.0));
  uint y = uint(floor(vTexCoord.y*SourceSize.y));
  float frag[4];
  for (uint i = 0u; i < 4u; i++) {
    uint p = (x*4u+i + y*4u + uint(FrameCount*4)) % 12u;
#define wave(ph,co) ((uint(co)+uint(ph)+8u)%12u<6u)
    float spot = lo_hi[uint(wave(p,color))];
    if ( (((uint(emphasis)&1u)==1u) && wave(p,12u))
	 || (((uint(emphasis)&2u)==1u) && wave(p,4u))
	 || (((uint(emphasis)&4u)==1u) && wave(p,8u)))
      spot *= attenuation;
    frag[i] = spot;
  }
  FragColor = (vec4(frag[0], frag[1], frag[2], frag[3]) - vec4(min))/vec4(max-min);
} 
#endif
