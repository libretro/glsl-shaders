  // after mixing with the adaptive comb filter
#pragma parameter postfilter_taps "Post-filter Taps" 15.0 1.0 30.0 1.0
#define postfiltertaps int(postfilter_taps)
#pragma parameter postfilterchromacutoff "Post-filter Chroma Cutoff" 0.3 0.1 1.0 0.05

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
#define texCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float postfilter_taps, postfilterchromacutoff;
#else
#define postfilter_taps 15.0
#define postfilterchromacutoff 0.3
#endif

vec3 chroma_sample(vec2 shift) {
  vec2 coord = texCoord + SourceSize.zw*shift;
  if (coord.x < 0.0 || coord.x > 1.0) return vec3(0.0);
  return COMPAT_TEXTURE(Source, texCoord + SourceSize.zw*shift).xyz-vec3(0,0.5,0.5);
}

float sinc(float x) {
  x = max(abs(x),0.0001);
  return sin(x)/x;
}

void main()
{
  int width = postfiltertaps;
  float bw_c = postfilterchromacutoff/3.0;

  const vec4 one = vec4(1.0);
  const float PI = 3.14159265359;
  const vec4 PI_6 = vec4(PI/6.0);

  float norm_c = 0.0;
  vec3 yiq = vec3(0.0);
  yiq.x = chroma_sample(vec2(0,0)).x;
  for (int i = -width/2; i <= width/2; i++) {
    // Hamming window
    const float alpha = 0.54;
    const float beta  = 0.46;
    float window = alpha - beta * cos(2.0*PI/(width-1)*(width/2+i));

    float chromafilt = 2.0*bw_c*sinc(2.0*PI*bw_c*i);

    vec3 samp = chroma_sample(vec2(i,0));
    float filt = window*chromafilt;
    yiq.yz += samp.yz*vec2(filt);
    norm_c += filt;
  }

  yiq *= vec3(1.0, 1.0/norm_c, 1.0/norm_c);

  FragColor = vec4(dot(yiq, vec3(1.0, 0.946882, 0.623557)),
		   dot(yiq, vec3(1.0,-0.274788,-0.635691)),
		   dot(yiq, vec3(1.0,-1.108545, 1.709007)),
		   0.0);
} 
#endif
