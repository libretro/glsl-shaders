/*
Adapted for RetroArch from Flyguy's "Apple II-Like Artifact Colors" from shadertoy:
https://www.shadertoy.com/view/llyGzR

"Colors created through NTSC artifacting on 4-bit patterns, similar to the Apple II's lo-res mode."
*/ 

// Parameter lines go here:
//#pragma parameter FIR_SIZE "FIR Size" 29.0 1.0 50.0 1.0
//#pragma parameter F_COL "F Col" 0.25 0.25 0.5 0.25
//#pragma parameter F_LUMA_LP "F Luma LP" 0.16667 0.0001 0.333333 0.02
#pragma parameter F_COL_BW "F Col BW" 50.0 10.0 200.0 1.0

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
#pragma format R16G16B16A16_SFLOAT

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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float FIR_SIZE;
uniform COMPAT_PRECISION float F_COL;
uniform COMPAT_PRECISION float F_LUMA_LP;
uniform COMPAT_PRECISION float F_COL_BW;
#else
#define FIR_SIZE 0.29
#define F_COL 0.25
#define F_LUMA_LP 0.16667
#define F_COL_BW 50.0
#endif

//Demodulator

//#define F_COL (1.0 / 4.0) // moved to parameter
//#define F_LUMA_LP (1.0 / 6.0) // moved to parameter
//#define F_COL_BW (1.0 / 50.0) // moved to parameter


//#define FIR_SIZE 29 // moved to parameter

float pi = 3.141592654;//atan(1.0)*4.0;
float tau = 6.283185308;//atan(1.0)*8.0;

//Non-normalized texture sampling.
vec4 sample2D(sampler2D tex,vec2 resolution, vec2 uv)
{
    return COMPAT_TEXTURE(tex, uv / resolution);
}

//Complex multiply
vec2 cmul(vec2 a, vec2 b)
{
   return vec2((a.x * b.x) - (a.y * b.y), (a.x * b.y) + (a.y * b.x));
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

//FIR bandpass filter 
//Fa/Fb = Low/High cutoff freq., Fs = Sample freq., N = # of taps, i = Tap index
float Bandpass(float Fa, float Fb, float Fs, int N, int i)
{    
    float wa = (Fa/Fs);
    float wb = (Fb/Fs);
    
    float wnd = WindowBlackman(0.16, N, i);
    
    return 2.0*(wb-wa) * wnd * (sinc(2.0*wb * float(i - N/2)) - sinc(2.0*wa * float(i - N/2)));
}

//Complex oscillator, Fo = Oscillator freq., Fs = Sample freq., n = Sample index
vec2 Oscillator(float Fo, float Fs, float N)
{
    float phase = (tau*Fo*floor(N))/Fs;
    return vec2(cos(phase),sin(phase));
}

// use this to avoid needing float framebuffers
vec4 remap(vec4 c)
{
#ifdef GL_ES
	return (c + vec4(0.07));
#else
	return c;
#endif
}

void main()
{
    float Fs = SourceSize.x;
    float Fcol = Fs * F_COL;
    float Fcolbw = Fs * (1.0 / F_COL_BW);
    float Flumlp = Fs * F_LUMA_LP;
    float n = floor(gl_FragCoord.x);
    
    float y_sig = 0.0;    
    float iq_sig = 0.0;
    
    vec2 cOsc = Oscillator(Fcol, Fs, n);
	
    n += float(FIR_SIZE)/2.0;
    
    //Separate luma(Y) & chroma(IQ) signals
    for(int i = 0;i < int(FIR_SIZE);i++)
    {
        int tpidx = int(FIR_SIZE) - i - 1;
        float lp = Lowpass(Flumlp, Fs, int(FIR_SIZE), tpidx);
        float bp = Bandpass(Fcol - Fcolbw, Fcol + Fcolbw, Fs, int(FIR_SIZE), tpidx);
        
        y_sig += sample2D(Source, SourceSize.xy, vec2(n - float(i), (gl_FragCoord.y))).r * lp;
        iq_sig += sample2D(Source, SourceSize.xy, vec2(n - float(i), (gl_FragCoord.y))).r * bp;
    }
    
    //Shift IQ signal down from Fcol to DC 
    vec2 iq_sig_mix = cmul(vec2(iq_sig, 0.), cOsc);
    
   vec4 final = vec4(y_sig, iq_sig_mix, 0.);
	FragColor = remap(final);
} 
#endif
