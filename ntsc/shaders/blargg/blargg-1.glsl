#version 110

#pragma parameter ntsc_sat "Saturation" 2.0 0.0 6.0 0.05
#pragma parameter bleed "Bleed" 0.5 0.0 2.0 0.05
#pragma parameter resolution "Resolution" 2.0 0.0 2.0 0.05
#pragma parameter sharpness "Sharpness" 0.3 0.0 1.0 0.05
#pragma parameter LUMA_CUTOFF "Luma Cut-off" 0.04 0.0 1.0 0.01
#pragma parameter stat_ph "Dot Crawl On/Off" 1.0 0.0 1.0 1.0

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ntsc_sat;
uniform COMPAT_PRECISION float bleed ;
uniform COMPAT_PRECISION float resolution ;
uniform COMPAT_PRECISION float sharpness ;
uniform COMPAT_PRECISION float LUMA_CUTOFF ;
uniform COMPAT_PRECISION float stat_ph ;


#else
#define ntsc_sat 1.0
#define bleed 0.05
#define resolution 2.0
#define sharpness 0.3
#define LUMA_CUTOFF 0.04
#define stat_ph 0.0
#endif

#define PI 3.1415926

// Colorspace conversion matrix for YUV-to-RGB
// All modern CRTs use YUV instead of YIQ
const mat3 YUV2RGB = mat3(1.0, 0.0, 1.13983,
                          1.0, -0.39465, -0.58060,
                          1.0, 2.03211, 0.0);

float blackman (float x)
{
float b = 0.42 - 0.5 * cos(x) + 0.08 * cos( x * 2.0 );
return b;
}

void main()
{
vec2 size = SourceSize.xy;
vec2 uv = vTexCoord;

float cutoff_factor = -0.03125;
float cutoff = bleed;       
    if ( cutoff < 0.0 )
        {
    /* keep extreme value accessible only near upper end of scale (1.0) */
    cutoff *= cutoff;
    cutoff *= cutoff;
    cutoff *= cutoff;
    cutoff *= -30.0 / 0.65;    
        }

    cutoff = cutoff_factor - 0.65 * cutoff_factor * cutoff;
    
    //Sample composite signal and decode to YUV
    vec3 YUV = vec3(0);
    float sum = 0.0;
    float to_angle = resolution + 1.0;
    float  rolloff = 1.0 + sharpness * 0.032;
    float  maxh = 32.0;
    float  pow_a_n = pow( rolloff, maxh );
    to_angle = PI / maxh * LUMA_CUTOFF * (to_angle * to_angle + 1.0);

for (int n=0; n<35; n++) { // 2*maxh + 1
        // blargg-ntsc
        // generate luma (y) filter using sinc kernel 
        float a = PI * 2.0 / (16.0 * 2.0) * float(n);
        float w = blackman(a);
        vec2 pos = uv - vec2(16.0/size.x,0.0) + vec2(float(n) / size.x, 0.0);
        
        float x = float(n) - 16.0; // maxh/2
        
        float angle = x * to_angle;
        float kernel = 0.0;
                
            //instability occurs at center point with rolloff very close to 1.0 
            if ( x > 1.056  || pow_a_n > 1.056 || pow_a_n < 0.981 )
            {
                float rolloff_cos_a = rolloff * cos( angle );
                float num = 1.0 - rolloff_cos_a -
                        pow_a_n * cos( maxh * angle ) +
                        pow_a_n * rolloff * cos( (maxh - 1.0) * angle );
                float den = 1.0 - rolloff_cos_a - rolloff_cos_a + rolloff * rolloff;
                float dsf = num / den;
                kernel = dsf - 0.5; 
            }
                   
        YUV.x += COMPAT_TEXTURE(Source, pos).r*w*kernel ;
        sum += w*kernel;
        }
        YUV.x /= sum;
    float sumc = 0.0;

// blargg ntsc-chroma
// generate chroma (iq) filter using gaussian kernel

for (int n=-16; n<16; n++) {
    vec2 pos = uv + vec2(float(n) / size.x, 0.0);
    float phase = (floor(vTexCoord.x*SourceSize.x)+float(n))*PI*0.5 + mod(floor(vTexCoord.y*SourceSize.y)*0.6667,2.0)*PI; 
    if (stat_ph == 1.0) phase += sin(mod(float(FrameCount),2.0))*PI;

    float r = exp(cutoff*float(n)*float(n));
 
    vec2 carrier = ntsc_sat*vec2(sin(phase), cos(phase));
        YUV.yz += r*COMPAT_TEXTURE(Source, pos).gb * carrier;
        sumc += r;
        }
    YUV.yz /= sumc;

    //  Convert signal to RGB
    YUV = YUV*YUV2RGB;
    FragColor = vec4(YUV, 1.0);
    
}
#endif
