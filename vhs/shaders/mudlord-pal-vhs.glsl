// Parameter lines go here:
#pragma parameter frameShape "Border mask shape" 0.35 0.0 1.0 0.01
#pragma parameter frameLimit "Border mask limit" 0.30 0.0 1.0 0.01
#pragma parameter frameSharpness "Border mask sharpness" 1.10 0.0 4.0 0.01
#pragma parameter TVNoise "PAL signal modulation + noise" 1.0 0.0 1.0 1.0
#pragma parameter PALSignal "PAL signal simulation" 1.0 0.0 1.0 1.0
#pragma parameter phosphors "Phosphor mask" 1.0 0.0 1.0 1.0
#pragma parameter border "Border mask" 1.0 0.0 1.0 1.0

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
uniform COMPAT_PRECISION float frameShape;
uniform COMPAT_PRECISION	float frameLimit;
uniform COMPAT_PRECISION	float frameSharpness;
uniform COMPAT_PRECISION    float TVNoise;
uniform COMPAT_PRECISION    float PALSignal;
uniform COMPAT_PRECISION    float phosphors;
uniform COMPAT_PRECISION    float border;
#else
#define frameShape 0.35
#define frameLimit 0.30
#define frameSharpness 1.10
#define TVNoise 1.0
#define PALSignal 1.0
#define phosphors 1.0
#define border 1.0
#endif

float rand(float x)
{
    vec2 co = vec2(x,x);
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

vec2 crt(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	uv *= 1.1;	
	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
	uv  = (uv / 2.0) + 0.5;
	uv =  uv *0.92 + 0.04;
	return uv;
}

void main()
{
    vec2 q = (vTexCoord.xy * TextureSize.xy / InputSize.xy);//fragCoord.xy / iResolution.xy;
    vec2 uv = q;
    uv = mix( uv, crt( uv ), 1.0 ) * InputSize.xy / TextureSize.xy;
    vec4 col = vec4(0.0);
    vec2 uv_q =uv;

    vec2 uv_n = uv_q;
    mat3 rgbtoyuv = mat3(0.299, -0.147,  0.615, 0.587, -0.289, -0.515, 0.114, 0.436, -0.100);
	mat3 yuvtorgb = mat3(1.000, 1.000, 1.000, 0.000, -0.395, 2.032, 1.140, -0.581, 0.000);
    float shade = 1.0;

    if(TVNoise == 1.0)
{
shade -= rand((uv_q.x*FrameCount) * 0.1 + (uv_q.y*FrameCount) * 50.0 + FrameCount) * 0.5;
}

if(PALSignal == 1.0)
{
     vec3 yuv = vec3(0.0);
	float fix = 0.3;
	float lumadelay = -0.002;

  for (int x = 10; x >= 0; x -= 1)
  {
       float xx = float(x) / 10.0;
       if(xx < 0.0) xx = 0.0 ;
       float x1 = (xx * -0.05)* fix + lumadelay;
       float x2 = (xx * 0.1)* fix + lumadelay;
       vec3 mult = (vec3(1.0) - pow(vec3(xx), vec3(0.2, 1.0, 1.0))) * 0.2;
        vec2 uv1 = uv_n + vec2(x1,0.0);
       vec2 uv2 = uv_n + vec2(x2,0.0);
       yuv += (rgbtoyuv * texture(Source,uv1).rgb) * mult;
       yuv += (rgbtoyuv * texture(Source,uv2).rgb) * mult;

  }
  yuv.r = yuv.r * 0.2 + (rgbtoyuv *  texture(Source,uv_n).rgb).r * 0.8;
    col.rgb = yuvtorgb * yuv * shade;
}
else
{
 col.rgb = texture(Source,uv_n).rgb;
}
    

   
if(phosphors==1.0)
{
    float mod_factor = q.y * OutputSize.y * OutputSize.y / OutputSize.y;
	vec3 dotMaskWeights = mix(vec3(1.0, 0.7, 1.0),vec3(0.7, 1.0, 0.7),floor(mod(mod_factor, 2.0)));
    col.rgb*= dotMaskWeights;
}
 

if(border ==1.0)
{
    vec2 p=-1.0+2.0*q;
	float f = (1.0- p.x *p.x) * (1.0-p.y *p.y);
	float frame = clamp(frameSharpness * (pow(f, frameShape) - frameLimit), 0.0, 1.0);
	col.rgb*=frame;
}
   FragColor = vec4(col.rgb, 1.0);
} 
#endif
