#version 130
#define phase FrameCount

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
uniform COMPAT_PRECISION vec2 PassPrev2TextureSize;
#define encode_passSize vec4(PassPrev2TextureSize.xy, 1.0/PassPrev2TextureSize.xy)
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D PassPrev2Texture;
#define encode_pass PassPrev2Texture
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define texCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

vec4 decode_sample(vec2 shift) {
  const float min = 0.350*0.746;
  const float max = 1.962;
  const float black = 0.518;
  vec2 coord = texCoord + encode_passSize.zw*shift;
  if (coord.x < 0.0 || coord.x > 1.0 || coord.y < 0.0 || coord.y > 1.0) return vec4(0.0);
  return (COMPAT_TEXTURE(encode_pass, coord) * vec4(max-min) + vec4(min-black)) / vec4(max-black);
}

vec3 filtsample(vec2 shift) {
  vec2 coord = texCoord + SourceSize.zw*shift;
  if (coord.x < 0.0 || coord.x > 1.0 || coord.y < 0.0 || coord.y > 1.0) return vec3(0.0);
  return COMPAT_TEXTURE(Source, texCoord + SourceSize.zw*shift).xyz-vec3(0,0.5,0.5);
}

void main()
{
  vec4 samps[] = vec4[](decode_sample(vec2(-1,0)),
			decode_sample(vec2( 0,0)),			
			decode_sample(vec2( 1,0)));
  // quarter-pixel shift between scanlines needed for comb filter
  vec4 s1, s2, s3, s4;
  s1 = decode_sample(vec2(-2,-1));
  s2 = decode_sample(vec2(-1,-1));
  s3 = decode_sample(vec2( 0,-1));
  s4 = decode_sample(vec2( 1,-1));
  vec4 samps_prev[] = vec4[](vec4(s1.zw,s2.xy),
			     vec4(s2.zw,s3.xy),
			     vec4(s3.zw,s4.xy));
  s1 = decode_sample(vec2(-1,1));
  s2 = decode_sample(vec2(-0,1));
  s3 = decode_sample(vec2( 1,1));
  s4 = decode_sample(vec2( 2,1));
  vec4 samps_next[] = vec4[](vec4(s1.zw,s2.xy),
			     vec4(s2.zw,s3.xy),
			     vec4(s3.zw,s4.xy));

  uint x = uint(floor(texCoord.x*SourceSize.x));
  uint y = uint(floor(texCoord.y*SourceSize.y));
  uint p = (x+y+uint(phase)) % 3u;

  const vec4 one = vec4(1.0);
  const vec4 PI_6 = vec4(3.14159265359/6.0);
  const vec4 offs = vec4(-0.0);
  const vec4 sins[] = vec4[](sin((vec4(0,1, 2, 3)+offs)*PI_6),
			     sin((vec4(4,5, 6, 7)+offs)*PI_6),
			     sin((vec4(8,9,10,11)+offs)*PI_6));
  const vec4 coss[] = vec4[](cos((vec4(0,1, 2, 3)+offs)*PI_6),
			     cos((vec4(4,5, 6, 7)+offs)*PI_6),
			     cos((vec4(8,9,10,11)+offs)*PI_6));

  vec3 filt      = filtsample(vec2(0, 0));
  vec3 filt_cur  = (filt + filtsample(vec2(-1,0))+filtsample(vec2(1,0)))/3.0;
  vec3 filt_prev = (filtsample(vec2(0,-1))+filtsample(vec2(-1,-1))+filtsample(vec2(1,-1)))/3.0;
  vec3 filt_next = (filtsample(vec2(0, 1))+filtsample(vec2(-1, 1))+filtsample(vec2(1, 1)))/3.0;
  vec3 dif1 = filt_cur-filt_prev;
  vec3 dif2 = filt_cur-filt_next;
  // this formula can be tweaked
  float xprev = clamp(0.5-sqrt(dot(dif1,dif1)),0,0.5);
  float xnext = clamp(0.5-sqrt(dot(dif2,dif2)),0,0.5);
  float xcur  = clamp(xprev+xnext,0,0.5);
  float scale = (xcur+0.0001)/(xprev+xnext+0.0001);
  xprev *= scale;
  xnext *= scale;
  float xfilt = 1.0 - 2.0*xcur;

  vec3 yiq = vec3(0.0);
  yiq.x = xcur*dot(samps[1],one) + xprev*dot(samps_prev[1],one) + xnext*dot(samps_next[1],one);
  for (uint i = 0u; i < 3u; i++) {
    samps[i] = xcur*samps[i] - xprev*samps_prev[i] - xnext*samps_next[i];
    yiq.y += dot(samps[i],coss[(i+p+2u)%3u]);
    yiq.z += dot(samps[i],sins[(i+p+2u)%3u]);
  }

  yiq *= vec3(1.0/4.0, 1.0/6.0, 1.0/6.0);
  yiq += xfilt*filt;

  //FragColor = vec4(dot(yiq, vec3(1.0, 0.946882, 0.623557)),
  //		   dot(yiq, vec3(1.0,-0.274788,-0.635691)),
  //		   dot(yiq, vec3(1.0,-1.108545, 1.709007)),
  //		   0.0);
  FragColor = vec4(yiq+vec3(0,0.5,0.5),0.0);
} 
#endif
