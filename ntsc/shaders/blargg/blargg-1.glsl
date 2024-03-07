#version 110

#pragma parameter kernel_half "Kernel Half-Size (speed-up)" 16.0 1.0 16.0 1.0
#pragma parameter ntsc_sat "Saturation" 2.0 0.0 6.0 0.05
#pragma parameter ntsc_res "Resolution" 0.0 -1.0 1.0 0.05
#pragma parameter ntsc_sharp "Sharpness" 0.1 -1.0 1.0 0.05
#pragma parameter fring "Fringing" 0.0 0.0 1.0 0.05
#pragma parameter afacts "Artifacts" 0.0 0.0 1.0 0.05
#pragma parameter ntsc_bleed "Chroma Bleed" 0.0 -0.75 2.0 0.05
#pragma parameter LUMA_CUTOFF "Luma Cutoff" 0.2 0.0 1.0 0.005
#pragma parameter stat_ph "Dot Crawl On/Off" 0.0 0.0 1.0 1.0
#pragma parameter dummy " [ System Specific Tweaks] " 0.0 0.0 0.0 0.0
#pragma parameter pi_mod "Phase-Horiz. Angle" 90.0 1.0 360.0 1.0
#pragma parameter vert_scal "Phase-Vertical Scale" 0.6667 0.0 1.0 0.05555

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
uniform COMPAT_PRECISION float ntsc_bleed ;
uniform COMPAT_PRECISION float ntsc_res ;
uniform COMPAT_PRECISION float ntsc_sharp ;
uniform COMPAT_PRECISION float LUMA_CUTOFF ;
uniform COMPAT_PRECISION float stat_ph ;
uniform COMPAT_PRECISION float fring ;
uniform COMPAT_PRECISION float afacts ;
uniform COMPAT_PRECISION float kernel_half ;
uniform COMPAT_PRECISION float pi_mod ;
uniform COMPAT_PRECISION float vert_scal ;

#else
#define ntsc_sat 1.0
#define ntsc_bleed 0.05
#define ntsc_res 2.0
#define ntsc_sharp 0.3
#define LUMA_CUTOFF 0.04
#define stat_ph 0.0
#define  fring 0.4
#define  afacts 0.4
#define  kernel_half 16.0
#define pi_mod 90.0
#define vert_scal 0.6667
#endif

#define PI 3.1415926
#define fringing_mid 0.8
#define fringing_max 1.6
#define artifacts_mid 0.4
#define artifacts_max 0.6
#define onedeg 0.017453

// Colorspace conversion matrix for YIQ-to-RGB
const mat3 YIQ2RGB = mat3(
   1.0, 0.956, 0.6210,
   1.0, -0.2720, -0.6474,
   1.0, -1.1060, 1.7046);

float blackman (float x)
{
float b = 0.42 - 0.5 * cos(x) + 0.08 * cos( x * 2.0 );
return b;
}

void main()
{
vec2 size = SourceSize.xy;
vec2 uv = vTexCoord;
int i = int(kernel_half);
float cutoff_factor = -0.03125;
float cutoff = ntsc_bleed;       
    if ( cutoff < 0.0 )
        {
    // keep extreme value accessible only near upper end of scale (1.0)
    cutoff *= cutoff;
    cutoff *= cutoff;
    cutoff *= cutoff;
    cutoff *= -30.0 / 0.65;    
        }
    cutoff = cutoff_factor - 0.65 * cutoff_factor * cutoff;
    
    // Sample composite signal and decode to YUV
    vec3 YUV = vec3(0);
    float sum = 0.0;
    float to_angle = ntsc_res + 1.0;
    float  rolloff = 1.0 + ntsc_sharp * 0.032;
    float  maxh = kernel_half*2.0;
    float  pow_a_n = pow( rolloff, maxh );
    to_angle = PI / maxh * LUMA_CUTOFF * (to_angle * to_angle + 1.0);

for (int n=0; n<i*2+1; n++) { // 2*maxh + 1
        // blargg-ntsc
        // generate luma (y) filter using sinc kernel 
        float a = PI * 2.0 / (kernel_half * 2.0) * float(n);
        float w = blackman(a);
        vec2 pos = uv - vec2(kernel_half/size.x,0.0) + vec2(float(n) / size.x, 0.0);
        
        float x = float(n) - kernel_half; // maxh/2
        
        float angle = x * to_angle;
        float kernel = 0.0;
 
float fringing = 0.0; 
if (fract(float(n+2)/4.0) == 0.0)
{
    if(fring >0.0)
    fringing = -fring*(fringing_max-fringing_mid);
}

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
           
        YUV.x += COMPAT_TEXTURE(Source, pos).r*w*kernel*(1.0+fringing);

        sum += w*kernel;
        }
        YUV.x /= sum;
    float sumc = 0.0;

// blargg ntsc-chroma
// generate chroma (iq) filter using gaussian kernel

for (int n=-i; n<i; n++) {
    vec2 pos = uv + vec2(float(n) / size.x, 0.0);
    float phase = (floor(vTexCoord.x*SourceSize.x)+float(n))*pi_mod*onedeg + mod(floor(vTexCoord.y*SourceSize.y)*vert_scal,2.0)*PI; 
    if (stat_ph == 1.0) phase += sin(mod(float(FrameCount),2.0))*PI;

    float r = exp(cutoff*float(n)*float(n));

float artifacts = 0.0; 
if (fract(float(n+i+2)/4.0) == 0.0)
{
    if(afacts>0.0)
    artifacts= -afacts*(artifacts_max-artifacts_mid);
}

    vec2 carrier = ntsc_sat*vec2(cos(phase), sin(phase));
        YUV.yz += r*COMPAT_TEXTURE(Source, pos).gb * carrier*(1.0+artifacts);
        sumc += r;
        }
    YUV.yz /= sumc;

    //  Convert signal to RGB
    YUV = YUV*YIQ2RGB;
    FragColor = vec4(YUV, 1.0);
    
}
#endif
