  // frequencies are in units of the chroma subcarrier
  // these are for the lowpass+notch filter
#pragma parameter filter_taps "Filter Taps" 15.0 1.0 30.0 1.0
#define filtertaps int(filter_taps)
#pragma parameter lumacutoff "Luma Cutoff" 0.9 0.1 1.0 0.05
#pragma parameter chromacutoff "Chroma Cutoff" 0.3 0.1 1.0 0.05

#define phase int(FrameCount)

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
uniform COMPAT_PRECISION float filter_taps, lumacutoff, chromacutoff;
#else
#define filter_taps 15.0
#define lumacutoff 0.9
#define chromacutoff 0.3
#endif

vec4 decode_sample(vec2 coord) {
  const float min = 0.350*0.746;
  const float max = 1.962;
  const float black = 0.518;
  if (coord.x < 0.0 || coord.x > 1.0) return vec4(0.0);
  return (COMPAT_TEXTURE(Source, coord) * vec4(max-min) + vec4(min-black)) / vec4(max-black);
}

vec4 sinc(vec4 x) {
  x = max(abs(x),vec4(0.0001));
  return sin(x)/x;
}
vec2 sinc(vec2 x) {
  x = max(abs(x),vec2(0.0001));
  return sin(x)/x;
}

void main()
{
  int width = filtertaps;
  float bw_y =   lumacutoff/12.0;
  float bw_c = chromacutoff/12.0;

  int x = int(floor(texCoord.x*SourceSize.x));
  int y = int(floor(texCoord.y*SourceSize.y));
  int p = (x+y+phase) % 3;

  const vec4 one = vec4(1.0);
  const float PI = 3.14159265359;
  const vec4 PI_6 = vec4(PI/6.0);

  float norm_y = 0.0;
  float norm_c = 0.0;
  vec3 yiq = vec3(0.0);

  vec4 samp  = decode_sample(texCoord + vec2((-width/2  )*SourceSize.z,0));
  vec4 samp2 = decode_sample(texCoord + vec2((-width/2+1)*SourceSize.z,0));
  // Hamming window
  const float alpha = 0.54;
  const float beta  = 0.46;
  int i;
  for (i = -width/2; i <= width/2-2; i++) {
    vec4 window = vec4(alpha) - vec4(beta) * cos(vec4(2.0*PI/(4*width-7))*(vec4(4*(width/2+i))+vec4(0,1,2,3)));

    vec4 t = vec4(i*4)+vec4(-1.5,-0.5,+0.5,+1.5);
#define lowpass(freq,x) vec4(2.0*(freq))*sinc(vec4(2.0*PI*(freq))*(x))
    vec4 lumafilt   = lowpass(bw_y, t);
    vec4 chromafilt = lowpass(bw_c, t);
#undef lowpass

    vec4 samp3 = decode_sample(texCoord + vec2((i+2)*SourceSize.z,0));
    vec4 rsamp  = vec4(samp2.zw, samp3.xy);
    vec4 filt = window*lumafilt;
    yiq.x += dot(samp, filt) + dot(rsamp,filt);
    norm_y += dot(one, filt);
    filt = window*chromafilt;
    yiq.y += dot(samp, filt*cos((vec4(0,1,2,3)+vec4(4*(i+p)))*PI_6));
    yiq.y += dot(rsamp,filt*cos((vec4(6,7,8,9)+vec4(4*(i+p)))*PI_6));
    yiq.z += dot(samp, filt*sin((vec4(0,1,2,3)+vec4(4*(i+p)))*PI_6));
    yiq.z += dot(rsamp,filt*sin((vec4(6,7,8,9)+vec4(4*(i+p)))*PI_6));
    norm_c += dot(one,filt);

    samp  = samp2;
    samp2 = samp3;
  }
  vec2 window = vec2(alpha) - vec2(beta) * cos(vec2(2.0*PI/(4*width-7))*(vec2(4*(width/2+i))+vec2(0,1)));
  vec2 t = vec2(i*4)+vec2(-1.5,-0.5);

#define lowpass(freq,x) vec2(2.0*(freq))*sinc(vec2(2.0*PI*(freq))*(x))
  vec2 lumafilt   = lowpass(bw_y, t);
  vec2 chromafilt = lowpass(bw_c, t);
#undef lowpass
  vec2 filt = window*lumafilt;
  yiq.x += dot(samp.xy, filt) + dot(samp2.zw, filt);
  norm_y += dot(one.xy, filt);
  filt = window*chromafilt;
  yiq.y += dot(samp.xy, filt*cos((vec2(0,1)+vec2(4*(i+p)))*vec2(PI/6.0)));
  yiq.y += dot(samp2.zw,filt*cos((vec2(6,7)+vec2(4*(i+p)))*vec2(PI/6.0)));
  yiq.z += dot(samp.xy, filt*sin((vec2(0,1)+vec2(4*(i+p)))*vec2(PI/6.0)));
  yiq.z += dot(samp2.zw,filt*sin((vec2(6,7)+vec2(4*(i+p)))*vec2(PI/6.0)));
  norm_c += dot(one.xy, filt);

  yiq *= vec3(0.5/norm_y, 1.0/norm_c, 1.0/norm_c);

  //FragColor = vec4(dot(yiq, vec3(1.0, 0.946882, 0.623557)),
  //		   dot(yiq, vec3(1.0,-0.274788,-0.635691)),
  //		   dot(yiq, vec3(1.0,-1.108545, 1.709007)),
  //		   0.0);
  FragColor = vec4(yiq+vec3(0,0.5,0.5),0.0);
} 
#endif
