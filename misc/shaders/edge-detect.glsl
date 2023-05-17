#pragma parameter minimum "Edge Thresh Min" 0.05 0.0 1.0 0.01
#pragma parameter maximum "Edge Thresh Max" 0.35 0.0 1.0 0.01

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

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
precision mediump int;
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
uniform sampler2D PassPrevTexture;
uniform sampler2D PassPrev1Texture;
uniform sampler2D OrigTexture;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)
#define Smooth PassPrev1Texture
#define Sharp PassPrevTexture

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float minimum;
uniform COMPAT_PRECISION float maximum;
#else
#define minimum 0.05
#define maximum 0.35
#endif

float threshold(float thr1, float thr2 , float val) {
 val = (val < thr1) ? 0.0 : val;
 val = (val > thr2) ? 1.0 : val;
 return val;
}

// averaged pixel intensity from 3 color channels
float avg_intensity(vec4 pix) {
 return dot(pix.rgb, vec3(0.2126, 0.7152, 0.0722));
}

vec4 get_pixel(sampler2D tex, vec2 coords, float dx, float dy) {
 return COMPAT_TEXTURE(tex, coords + vec2(dx, dy));
}

// returns pixel color
float IsEdge(sampler2D tex, vec2 coords){
  float dxtex = SourceSize.z;
  float dytex = SourceSize.w;
  float pix[9];
  int k = -1;
  float delta;

  // read neighboring pixel intensities
  for (int i=-1; i<2; i++) {
   for(int j=-1; j<2; j++) {
    k++;
    pix[k] = avg_intensity(get_pixel(tex, coords, float(i) * dxtex,
                                          float(j) * dytex));
   }
  }

  // average color differences around neighboring pixels
  delta = (abs(pix[1]-pix[7])+
          abs(pix[5]-pix[3]) +
          abs(pix[0]-pix[8])+
          abs(pix[2]-pix[6])
           )/4.;

  return threshold(minimum, maximum,clamp(delta,0.0,1.0));
}

void main()
{
   float test = IsEdge(Source, vTexCoord);
//   vec4 hybrid = vec4(0.0);
//   hybrid = (test > 0.01) ? COMPAT_TEXTURE(Sharp, vTexCoord) : COMPAT_TEXTURE(Smooth, vTexCoord);
   FragColor = vec4(test);
} 
#endif
