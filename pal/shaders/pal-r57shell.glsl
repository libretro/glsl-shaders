// NES PAL composite signal simulation for RetroArch
// shader by r57shell
// thanks to feos & HardWareMan & NewRisingSun

// also TV subpixels and scanlines

// LICENSE: PUBLIC DOMAIN

// NOTE: for nice TV subpixels and scanlines I recommend to
// disable this features here and apply CRT-specialized shader.

// Quality considerations

// there are three main options:
// USE_RAW (R), USE_DELAY_LINE (D), USE_COLORIMETRY (C)
// here is table of quality in decreasing order:
// RDC, RD, RC, DC, D, C

// compatibility macros
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define frac(c) fract(c)
#define saturate(c) clamp(c, 0.0, 1.0)
#define fmod(x,y) mod(x,y)
#define mul(x,y) (y*x)
#define float2x2 mat2
#define float3x3 mat3
#define float4x4 mat4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4
#define static  

// TWEAKS start

// uncomment this to disable dynamic settings, and use static.
// if you unable to compile shader with dynamic settings,
// and you want to tune parameters in menu, then
// try to reduce somewhere below Mwidth from 32 to lower,
// or disable USE_DELAY_LINE or USE_RAW, or all at once.
//#undef PARAMETER_UNIFORM

// use delay line technique
// without delay line technique, color would interleave
// to avoid this, set HueRotation to zero.
#define USE_DELAY_LINE

// use this if you need to swap even/odd V sign.
// sign of V changes each scanline
// so if some scanline is positive, then next is negative
// and if you want to match picture
// to actual running PAL NES on TV
// you may want to have this option, to change signs
// if they don't match
//#define SWAP_VSIGN

// phase shift from frame to frame as NTSC NES does.
// but PAL NES doesn't
//#define ANIMATE_PHASE

// rough simulation of scanlines
// better if you use additional shader instead
// if you still use it, make sure that SizeY
// is at least twice lower than output height
//#define USE_SCANLINES

// this option changes active visible fields.
// this is not how actual NES works
// it does not alter fields.
//#define ANIMATE_SCANLINE

// simulate CRT TV subpixels
// better if you use CRT-specialized shader instead
//#define USE_SUBPIXELS

// to change gamma of virtual TV from 2.2 to something else
//#define USE_GAMMA

// use core size. for NES use this, for other cores turn off
// for other cores use "size" tweak.
//#define USE_CORE_SIZE

// use raw palette, turn it on if you
// have nestopia and having using raw palette
//#define USE_RAW

// use lookup texture, faster but less accuracy
// it's working only if USE_RAW enabled.
//#define USE_LUT

// compensate filter width
// it will make width of picture shorter
// to make picture right border visible
#define COMPENSATE_WIDTH

// use sampled version. it's much more slower version of shader.
// because it is computing x4 more values. NOT RECOMMENDED.
//#define USE_SAMPLED

// this is using following matrixes.
// it provides more scientific approach
// by conversion into linear XYZ space
// and back to sRGB.
// it's using Gamma setting too.
// define USE_GAMMA is not required.
#define USE_COLORIMETRY

// TWEAKS end

#pragma parameter USE_RAW_param "(NES ONLY) Decode RAW Colors" 0.0 0.0 1.0 1.0
#pragma parameter USE_LUT_param "(NES ONLY) Use RAW LUT For Speed" 0.0 0.0 1.0 1.0

#pragma parameter Gamma "PAL Gamma" 2.5 0.0 10.0 0.03125
#pragma parameter Brightness "PAL Brightness" 0.0 -1.0 2.0 0.03125
#pragma parameter Contrast "PAL Contrast" 1.0 -1.0 2.0 0.03125
#pragma parameter Saturation "PAL Saturation" 1.0 -1.0 2.0 0.03125
#pragma parameter HueShift "PAL Hue Shift" -2.5 -6.0 6.0 0.015625
#pragma parameter HueRotation "PAL Hue Rotation" 2.0 -5.0 5.0 0.015625
#pragma parameter Ywidth "PAL Y Width" 12.0 1.0 32.0 1.0
#pragma parameter Uwidth "PAL U Width" 23.0 1.0 32.0 1.0
#pragma parameter Vwidth "PAL V Width" 23.0 1.0 32.0 1.0
#pragma parameter SizeX "Active Width" 256.0 1.0 4096.0 1.0
#pragma parameter SizeY "Active Height" 240.0 1.0 4096.0 1.0
#pragma parameter TV_Pixels "PAL TV Pixels" 200.0 1.0 2400.0 1.0
#pragma parameter dark_scanline "PAL Scanline" 0.5 0.0 1.0 0.025
#pragma parameter Phase_Y "PAL Phase Y" 2.0 0.0 12.0 0.025
#pragma parameter Phase_One "PAL Phase One" 0.0 0.0 12.0 0.025
#pragma parameter Phase_Two "PAL Phase Two" 8.0 0.0 12.0 0.025

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

// have to duplicate these in both stages...
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float USE_RAW_param;
uniform COMPAT_PRECISION float USE_LUT_param;

bool USE_RAW = bool(USE_RAW_param);
bool USE_LUT = bool(USE_LUT_param);

#endif
#ifndef PARAMETER_UNIFORM

// use true/false to togglehttps://github.com/libretro/RetroArch/pull/12539
bool USE_RAW = false;
bool USE_LUT = false;

#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING float DeltaV;
COMPAT_VARYING float Voltage_0;
COMPAT_VARYING float Voltage_1;

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

	if(USE_RAW)
	{
		Voltage_0 = (!USE_LUT) ? 0.518 : 0.15103768593097774;
		Voltage_1 = (!USE_LUT) ? 1.962 : 1.;
		DeltaV = (Voltage_1-Voltage_0);
	}
	else DeltaV = 1.;
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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float Gamma;
uniform COMPAT_PRECISION float Brightness;
uniform COMPAT_PRECISION float Contrast;
uniform COMPAT_PRECISION float Saturation;
uniform COMPAT_PRECISION float HueShift;
uniform COMPAT_PRECISION float HueRotation;
uniform COMPAT_PRECISION float Ywidth;
uniform COMPAT_PRECISION float Uwidth;
uniform COMPAT_PRECISION float Vwidth;
uniform COMPAT_PRECISION float TV_Pixels;
uniform COMPAT_PRECISION float SizeX;
uniform COMPAT_PRECISION float SizeY;
uniform COMPAT_PRECISION float dark_scanline;
uniform COMPAT_PRECISION float Phase_Y;
uniform COMPAT_PRECISION float Phase_One;
uniform COMPAT_PRECISION float Phase_Two;
uniform COMPAT_PRECISION float USE_RAW_param;
uniform COMPAT_PRECISION float USE_LUT_param;

bool USE_RAW = bool(USE_RAW_param);
bool USE_LUT = bool(USE_LUT_param);

static const float Mwidth = 24.;

static const int Ywidth_static = 1;
static const int Uwidth_static = 1;
static const int Vwidth_static = 1;

static const float Contrast_static = 1.;
static const float Saturation_static = 1.;

#else

#define Brightness Brightness_static
#define Gamma Gamma_static

#define Ywidth Ywidth_static
#define Uwidth Uwidth_static
#define Vwidth Vwidth_static

static const int Mwidth = max(float(Ywidth), max(float(Uwidth), float(Vwidth)));

#ifdef USE_CORE_SIZE
// just use core output size.
#define size (InputSize.xy)
#else
static const float2 size = float2(SizeX,SizeY);
#endif

#endif

#ifndef PARAMETER_UNIFORM

// use true/false to toggle
bool USE_RAW = false;
bool USE_LUT = false;

// NTSC standard gamma = 2.2
// PAL standard gamma = 2.8
// according to many sources, very unlikely gamma of TV is 2.8
// most likely gamma of PAL TV is in range 2.4-2.5
static const float Gamma_static = 2.5; // gamma of virtual TV

static const float Brightness_static = 0.0;
static const float Contrast_static = 1.0;
static const float Saturation_static = 1.0;

static const int
	Ywidth_static = 12,
	Uwidth_static = 23,
	Vwidth_static = 23;

// correct one is -2.5
// works only with USE_RAW
static const float HueShift = -2.5;

// rotation of hue due to luma level.
static const float HueRotation = 2.;

// touch this only if you know what you doing
static const float Phase_Y = 2.; // fmod(341*10,12)
static const float Phase_One = 0.; // alternating phases.
static const float Phase_Two = 8.;

// screen size, scanlines = y*2; y one field, and y other field.
static const int SizeX = 256;
static const int SizeY = 240;

// count of pixels of virtual TV.
// value close to 1000 produce small artifacts
static const int TV_Pixels = 400;

static const float dark_scanline = 0.5; // half

#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D nes_lut;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING float DeltaV;
COMPAT_VARYING float Voltage_0;
COMPAT_VARYING float Voltage_1;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

static const mat3 RGB_to_XYZ =
mat3(
	0.4306190, 0.3415419, 0.1783091,
	0.2220379, 0.7066384, 0.0713236,
	0.0201853, 0.1295504, 0.9390944
);

static const mat3 XYZ_to_sRGB =
mat3(
	 3.2406, -1.5372, -0.4986,
	-0.9689,  1.8758,  0.0415,
	 0.0557, -0.2040,  1.0570
);

static const float YUV_u = 0.492;
static const float YUV_v = 0.877;

static const mat3 RGB_to_YUV =
mat3(
	float3( 0.299, 0.587, 0.114), //Y
	float3(-0.299,-0.587, 0.886)*YUV_u, //B-Y
	float3( 0.701,-0.587,-0.114)*YUV_v //R-Y
);

#ifdef USE_DELAY_LINE
static const float comb_line = 1.;
#else
static const float comb_line = 2.;
#endif

static float RGB_y = Contrast_static/float(Ywidth_static)/DeltaV;
static float RGB_u = comb_line*Contrast_static*Saturation_static/YUV_u/float(Uwidth_static)/DeltaV;
static float RGB_v = comb_line*Contrast_static*Saturation_static/YUV_v/float(Vwidth_static)/DeltaV;

static const float pi = 3.1415926535897932384626433832795;

bool InColorPhase(int color, float phase)
{
	return fmod((float(color)*2. + phase),24.) < 12.;
}

// signal low
const float levels_0 = 0.350;
const float levels_1 = 0.518;
const float levels_2 = 0.962;
const float levels_3 = 1.550;
// signal high
const float levels_4 = 1.094;
const float levels_5 = 1.506;
const float levels_6 = 1.962;
const float levels_7 = 1.962;

// from nesdev wiki page NTSC_video
float NTSCsignal(float3 pixel, float phase)
{
   // use LUT for RAW palette decoding for speed vs quality and return early
   if(USE_LUT) return COMPAT_TEXTURE(nes_lut,float2(dot(pixel,float3(
		15.*(8.)/512.,
		3.*(16.*8.)/512.,
		7./512.)
		) + 0.5/(4.*16.*8.), frac(phase/24.))).r;
		
	// Voltage levels, relative to synch voltage
	static const float black=.518, white=1.962, attenuation=.746;

	// Decode the NES color.
	int color = int(pixel.r*15.);	// 0..15 "cccc"
	int level = int(pixel.g*3.);	// 0..3  "ll"
	int emphasis = int(pixel.b*7.+0.1);	// 0..7  "eee"
	if (color > 13) { level = 1; }	// For colors 14..15, level 1 is forced.

	// The square wave for this color alternates between these two voltages:
	float low = levels_0, high = levels_4;
	if (level == 1) { low = levels_1, high = levels_5; }
	if (level == 2) { low = levels_2, high = levels_6; }
	if (level == 3) { low = levels_3, high = levels_7; }
	if(color == 0) { low = high; } // For color 0, only high level is emitted
	if(color > 12) { high = low; } // For colors 13..15, only low level is emitted


	// Generate the square wave
	// When de-emphasis bits are set, some parts of the signal are attenuated:
	float2 e = fmod(float2(emphasis,emphasis), float2(2.,4.));
	float signal = InColorPhase(color,phase) ? high : low;

	if( ((int(e.x) != 0) && InColorPhase(0,phase))
	||  ((int(e.y-e.x) != 0) && InColorPhase(4,phase))
	||  ((emphasis-int(e.y) != 0) && InColorPhase(8,phase)) )
		return signal * attenuation;
	else
		return signal;
}

float sinn(float x)
{
	return sin(/*fmod(x,24)*/x*(pi*2./24.));
}

float coss(float x)
{
	return cos(/*fmod(x,24)*/x*(pi*2./24.));
}

float3 monitor(sampler2D tex, float2 p)
{
mat3 YUV_to_RGB = mat3(
	float3(1., 1., 1.)*RGB_y,
	float3(0., -0.114/0.587, 1.)*RGB_u,
	float3(1., -0.299/0.587, 0.)*RGB_v
);
#ifdef PARAMETER_UNIFORM
	float2 size = float2(SizeX,SizeY);
#endif
	// align vertical coord to center of texel
	float2 uv = float2(
#ifdef COMPENSATE_WIDTH
		p.x+p.x*(Ywidth/8.)/size.x,
#else
		p.x,
#endif
		(floor(p.y*TextureSize.y)+0.5)/TextureSize.y);
#ifdef USE_DELAY_LINE
	float2 sh = (InputSize/TextureSize/size)*float2(14./10.,-1.0);
#endif
	float2 pc = uv*TextureSize/InputSize*size*float2(10.,1.);
	float alpha = dot(floor(float2(pc.x,pc.y)),float2(2.,Phase_Y*2.));
	alpha += Phase_One*2.;
#ifdef ANIMATE_PHASE
	if (fmod(FrameCount,2) > 1.)
		alpha += (Phase_Two-Phase_One)*2.;
#endif

	// 1/size.x of screen in uv coords = InputSize.x/TextureSize.x/size.x;
	// then 1/10*size.x of screen:
	float ustep = InputSize.x/TextureSize.x/size.x/10.;

	float border = InputSize.x/TextureSize.x;
	float ss = 2.0;
#ifdef SWAP_VSIGN
#define PAL_SWITCH(A) A < 1.
#else
#define PAL_SWITCH(A) A > 1.
#endif
	if (PAL_SWITCH(fmod(uv.y*TextureSize.y/InputSize.y*size.y,2.0)))
	{
		// cos(pi-alpha) = -cos(alpha)
		// sin(pi-alpha) = sin(alpha)
		// pi - alpha
		alpha = -alpha+12012.0;
		ss = -2.0;
	}

	float ysum = 0., usum = 0., vsum = 0., sig = 0., sig1 = 0.;
	for (int i=0; i<int(Mwidth); ++i)
	{	
	   float4 res = COMPAT_TEXTURE(tex, uv);
	   
      if(USE_RAW)
      {
		   sig = NTSCsignal(res.xyz,HueShift*2.+alpha-res.g*ss*HueRotation)-Voltage_0;
		   // outside of texture is 0,0,0 which is white instead of black
		   if (uv.x <= 0.0 || uv.x >= border)
			   sig = 0.;
#ifdef USE_DELAY_LINE
		   float4 res1 = COMPAT_TEXTURE(tex, uv+sh);
		   sig1 = NTSCsignal(res1.xyz,HueShift*2.+12012.0-alpha+res.g*ss*HueRotation)-Voltage_0;
		   if (uv.x + sh.x <= 0.0 || uv.x + sh.x >= border)
			   sig1 = 0.;
#endif
      }
      else
      {
		   float3 yuv = mul(RGB_to_YUV, res.xyz);
		   float a1 = alpha+(HueShift+2.5)*2.-yuv.x*ss*HueRotation;
		   sig = yuv.x+dot(yuv.yz,sign(float2(sinn(a1),coss(a1))));
#ifdef USE_DELAY_LINE
		   float4 res1 = COMPAT_TEXTURE(tex, uv+sh);
		   float3 yuv1 = mul(RGB_to_YUV, res1.xyz);
		   float a2 = (HueShift+2.5)*2.+12012.0-alpha+yuv.x*ss*HueRotation;
		   sig1 = yuv1.x+dot(yuv1.yz,sign(float2(sinn(a2),coss(a2))));
#endif
      }
		if (i < int(Ywidth))
			ysum += sig;

#ifdef USE_DELAY_LINE
		if (i < int(Uwidth))
			usum += (sig+sig1)*sinn(alpha);
		if (i < int(Vwidth))
			vsum += (sig-sig1)*coss(alpha);
#else
		if (i < int(Uwidth))
			usum += sig*sinn(alpha);
		if (i < int(Vwidth))
			vsum += sig*coss(alpha);
#endif
		alpha -= ss;
		uv.x -= ustep;
	}

#ifdef PARAMETER_UNIFORM
	ysum *= Contrast/Ywidth;
	usum *= Contrast*Saturation/Uwidth;
	vsum *= Contrast*Saturation/Vwidth;
#endif

	float3 rgb = mul(float3(ysum+Brightness*float(Ywidth_static),usum,vsum), YUV_to_RGB);
#if defined(USE_GAMMA) && !defined(USE_COLORIMETRY)
	float3 rgb1 = saturate(rgb);
	rgb = pow(rgb1, float3(Gamma/2.2,Gamma/2.2,Gamma/2.2));
#endif

#ifdef USE_COLORIMETRY
	float3 rgb1 = saturate(rgb);
	rgb = pow(rgb1, float3(Gamma,Gamma,Gamma));
#endif

#if (defined(USE_SUBPIXELS) || defined(USE_SCANLINES))
	float2 q = (p*TextureSize/InputSize)*float2(TV_Pixels*3.,size.y*2.);
#endif

#ifdef USE_SCANLINES
	float scanlines = size.y/OutputSize.x;
	float top = fmod(q.y-0.5*scanlines*2.,2.);
	float bottom = top+frac(scanlines)*2.;
	float2 sw = saturate(min(float2(1.,2.),float2(bottom, bottom))
		-max(float2(0.,1.),float2(top)))
		+saturate(min(float2(3.,4.),float2(bottom, bottom))
		-max(float2(2.,3.),float2(top)))
		+floor(scanlines);
#ifdef ANIMATE_SCANLINE
#define SCANLINE_MUL (fmod(float(FrameCount),2.0)<1.0001 \
		? sw.x*dark_scanline+sw.y \
		: sw.x+sw.y*dark_scanline)
#else
#define SCANLINE_MUL (sw.x*dark_scanline+sw.y)
#endif
	rgb = rgb*SCANLINE_MUL/(sw.x+sw.y);

/*
	//old stupid method
	float z =
#ifdef ANIMATE_SCANLINE
	fmod(FrameCount,2.0)+
#endif
		0.5;

	if (abs(fmod(q.y+0.5,2)-z)<0.5)
		rgb *= dark_scanline;
*/
#endif

	// size of pixel screen in texture coords:
	//float output_pixel_size = InputSize.x/(OutputSize.x*TextureSize.x);

	// correctness check
	//if (fmod(p.x*output_pixel_size,2.0) < 1.0)
	//	rgb = float3(0.,0.,0.);

#ifdef USE_SUBPIXELS
	float pixels = TV_Pixels/OutputSize.x;
	float left = fmod(q.x-0.5*pixels*3.,3.);
	float right = left+frac(pixels)*3.;
	float3 w = saturate(min(float3(1.,2.,3.),float3(right,right,right))
		-max(float3(0.,1.,2.),float3(left,left,left)))
		+saturate(min(float3(4.,5.,6.),float3(right,right,right))
		-max(float3(3.,4.,5.),float3(left,left,left)))
		+floor(pixels);
	rgb = rgb*3.*w/(w.x+w.y+w.z);
#endif

#ifdef USE_COLORIMETRY
	float3 xyz1 = mul(RGB_to_XYZ,rgb);
	float3 srgb = saturate(mul(XYZ_to_sRGB,xyz1));
	float3 a1 = 12.92*srgb;
	float3 a2 = 1.055*pow(srgb,float3(1./2.4,1./2.4,1./2.4))-0.055;
	float3 ssrgb;
   ssrgb.x = (srgb.x<0.0031308?a1.x:a2.x);
   ssrgb.y = (srgb.y<0.0031308?a1.y:a2.y);
   ssrgb.z = (srgb.z<0.0031308?a1.z:a2.z);
	return ssrgb;
#else
	return rgb;
#endif
}

// pos (left corner, sample size)
float4 monitor_sample(sampler2D tex, float2 p, float2 sample_)
{
	// linear interpolation was...
	// now other thing.
	// http://imgur.com/m8Z8trV
	// AT LAST IT WORKS!!!!
	// going to check in retroarch...
	float2 size = TextureSize;
	float2 next = float2(.25,1.)/size;
	float2 f = frac(float2(4.,1.)*size*p);
	sample_ *= float2(4.,1.)*size;
	float2 l;
	float2 r;
	if (f.x+sample_.x < 1.)
	{
		l.x = f.x+sample_.x;
		r.x = 0.;
	}
	else
	{
		l.x = 1.-f.x;
		r.x = min(1.,f.x+sample_.x-1.);
	}
	if (f.y+sample_.y < 1.)
	{
		l.y = f.y+sample_.y;
		r.y = 0.;
	}
	else
	{
		l.y = 1.-f.y;
		r.y = min(1.,f.y+sample_.y-1.);
	}
	float3 top = mix(monitor(tex, p), monitor(tex, p+float2(next.x,0.)), r.x/(l.x+r.x));
	float3 bottom = mix(monitor(tex, p+float2(0.,next.y)), monitor(tex, p+next), r.x/(l.x+r.x));
	return float4(mix(top,bottom, r.y/(l.y+r.y)),1.0);
}

void main()
{
#ifdef USE_SAMPLED
	FragColor = monitor_sample(Texture, TEX0.xy, 1./OutputSize);
#else
	FragColor = float4(monitor(Texture, TEX0.xy), 1.);
#endif
} 
#endif
