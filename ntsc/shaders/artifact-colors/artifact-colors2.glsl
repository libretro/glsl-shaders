/*
Adapted for RetroArch from Flyguy's "Apple II-Like Artifact Colors" from shadertoy:
https://www.shadertoy.com/view/llyGzR

"Colors created through NTSC artifacting on 4-bit patterns, similar to the Apple II's lo-res mode."
*/ 

// Parameter lines go here:
#pragma parameter FIR_SIZE "FIR Size" 29.0 1.0 50.0 1.0
#pragma parameter F_COL "F Col" 0.25 0.25 0.5 0.25
#pragma parameter SATURATION "Saturation" 30.0 0.0 100.0 1.0
#pragma parameter BRIGHTNESS "Brightness" 1.0 0.0 2.0 0.01
#pragma parameter F_LUMA_LP "F Luma LP" 0.16667 0.0001 0.333333 0.02
#pragma parameter HUE "Hue" 0.0 0.0 1.0 0.01

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
uniform sampler2D OrigTexture;
#define Original OrigTexture
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float FIR_SIZE;
uniform COMPAT_PRECISION float F_COL;
uniform COMPAT_PRECISION float SATURATION;
uniform COMPAT_PRECISION float BRIGHTNESS;
uniform COMPAT_PRECISION float F_LUMA_LP;
uniform COMPAT_PRECISION float HUE;
#else
#define FIR_SIZE 29.0
#define F_COL 0.25
#define SATURATION 30.0
#define BRIGHTNESS 1.0
#define F_LUMA_LP 0.16667
#define HUE 0.0
#endif

//Composite color artifact simulator
//Change Buf A to change the input image.

//#define HUE 0.0 // moved to parameter
//#define SATURATION 30.0 // moved to parameter
//#define BRIGHTNESS 1.0 // moved to parameter

#define COMPOSITE 0 //Composite demodulated image
#define RGB 1 //Raw RGB input image
#define LUMA 2 //Luma component
#define CHROMA 3 //Chroma component
#define SIGNAL 4 //Modulated image
#define SPLIT 5 //Left = Input RGB, Right = Output composite

#define VIEW_MODE COMPOSITE

//#define F_COL (1.0 / 4.0) // moved to parameter
//#define F_LUMA_LP (1.0 / 6.0) // moved to parameter

//#define FIR_SIZE 29  // moved to parameter

float pi = 3.141592654;//atan(1.0)*4.0;
float tau = 6.283185308;//atan(1.0)*8.0;

mat3 yiq2rgb = mat3(1.000, 1.000, 1.000,
                    0.956,-0.272,-1.106,
                    0.621,-0.647, 1.703);

//Angle -> 2D rotation matrix 
mat2 rotate(float a)
{
    return mat2( cos(a), sin(a),
                -sin(a), cos(a));
}

vec4 remap(vec4 c)
{
#ifdef GL_ES
	return c - vec4(0.07);
#else
	return c;
#endif
}

//Non-normalized texture sampling.
vec4 sample2D(sampler2D tex,vec2 resolution, vec2 uv)
{
    return remap(COMPAT_TEXTURE(tex, uv / resolution));
}

float sinc(float x)
{
	return (x == 0.0) ? 1.0 : sin(x*pi)/(x*pi);   
}

//https://en.wikipedia.org/wiki/Window_function
float WindowBlackman(float a, int N, int i)
{
    float a0 = (1.0 - a) / 2.0;
    float a1 = 0.5;
    float a2 = a / 2.0;
    
    float wnd = a0;
    wnd -= a1 * cos(2.0 * pi * (float(i) / float(N - 1)));
    wnd += a2 * cos(4.0 * pi * (float(i) / float(N - 1)));
    
    return wnd;
}

//FIR lowpass filter 
//Fc = Cutoff freq., Fs = Sample freq., N = # of taps, i = Tap index
float Lowpass(float Fc, float Fs, int N, int i)
{    
    float wc = (Fc/Fs);
    
    float wnd = WindowBlackman(0.16, N, i);
    
    return 2.0*wc * wnd * sinc(2.0*wc * float(i - N/2));
}

void main()
{
    float Fs = SourceSize.x;
    float Fcol = Fs * F_COL;
    float Flumlp = Fs * F_LUMA_LP;
    float n = floor(gl_FragCoord.x);
    
	vec2 uv = gl_FragCoord.xy;
    
    float luma = sample2D(Source, SourceSize.xy, uv).r;
    vec2 chroma = vec2(0.);
    
    //Filtering out unwanted high freqency content from the chroma(IQ) signal.
    for(int i = 0;i < int(FIR_SIZE);i++)
    {
        int tpidx = int(FIR_SIZE) - i - 1;
        float lp = Lowpass(Flumlp, Fs, int(FIR_SIZE), tpidx);
        chroma += sample2D(Source, SourceSize.xy, uv - vec2(float(i) - FIR_SIZE / 2., 0.)).yz * lp;
    }
    
    chroma *= rotate(tau * HUE);
    
    vec3 color = yiq2rgb * vec3(BRIGHTNESS * luma, chroma * SATURATION);
    
    #if(VIEW_MODE == COMPOSITE)
    	FragColor = vec4(color, 0.);
    
    #elif(VIEW_MODE == RGB)
   		FragColor = COMPAT_TEXTURE(Original, vTexCoord.xy);
    
    #elif(VIEW_MODE == LUMA) 
    	FragColor = vec4(luma);
    
    #elif(VIEW_MODE == CHROMA)
    	FragColor = vec4(40.0*chroma+0.5,0.,0.);
    
    #elif(VIEW_MODE == SIGNAL)
    	FragColor = 0.5 * COMPAT_TEXTURE(Pass2, uv / SourceSize.xy).rrrr+0.25;
    
    #elif(VIEW_MODE == SPLIT)
    	if(vTexCoord.x < 0.30)
        {
            FragColor = COMPAT_TEXTURE(Original, vTexCoord.xy);
        }
        else
        {
    		FragColor = vec4(color, 0.);
        }
    #endif
} 
#endif
