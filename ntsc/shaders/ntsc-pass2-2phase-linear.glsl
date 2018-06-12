#version 130

#define NTSC_CRT_GAMMA 2.4

#define fetch_offset(offset, one_x) \
   COMPAT_TEXTURE(Source, vTexCoord + vec2((offset) * (one_x), 0.0)).xyz

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
    TEX0.xy = TexCoord.xy - vec2(0.5 / SourceSize.x, 0.0); // Compensate for decimate-by-2.
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

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

// begin ntsc-rgbyuv
const mat3 yiq2rgb_mat = mat3(
   1.0, 0.956, 0.6210,
   1.0, -0.2720, -0.6474,
   1.0, -1.1060, 1.7046);

vec3 yiq2rgb(vec3 yiq)
{
   return yiq * yiq2rgb_mat;
}

const mat3 yiq_mat = mat3(
      0.2989, 0.5870, 0.1140,
      0.5959, -0.2744, -0.3216,
      0.2115, -0.5229, 0.3114
);

vec3 rgb2yiq(vec3 col)
{
   return col * yiq_mat;
}
// end ntsc-rgbyuv

// begin ntsc-decode-filter-3phase
#ifdef GL_ES
float luma_filter1 = -0.000174844;
float luma_filter2 = -0.000205844;
float luma_filter3 = -0.000149453;
float luma_filter4 = -0.000051693;
float luma_filter5 = 0.000000000;
float luma_filter6 = -0.000066171;
float luma_filter7 = -0.000245058;
float luma_filter8 = -0.000432928;
float luma_filter9 = -0.000472644;
float luma_filter10 = -0.000252236;
float luma_filter11 = 0.000198929;
float luma_filter12 = 0.000687058;
float luma_filter13 = 0.000944112;
float luma_filter14 = 0.000803467;
float luma_filter15 = 0.000363199;
float luma_filter16 = 0.000013422;
float luma_filter17 = 0.000253402;
float luma_filter18 = 0.001339461;
float luma_filter19 = 0.002932972;
float luma_filter20 = 0.003983485;
float luma_filter21 = 0.00302668;
float luma_filter22 = -0.001102056;
float luma_filter23 = -0.008373026;
float luma_filter24 = -0.016897700;
float luma_filter25 = -0.022914480;
float luma_filter26 = -0.021642347;
float luma_filter27 = -0.008863273;
float luma_filter28 = 0.017271957;
float luma_filter29 = 0.054921920;
float luma_filter30 = 0.098342579;
float luma_filter31 = 0.139044281;
float luma_filter32 = 0.168055832;
float luma_filter33 = 0.178571429;

float chroma_filter1 = 0.001384762;
float chroma_filter2 = 0.001678312;
float chroma_filter3 = 0.002021715;
float chroma_filter4 = 0.002420562;
float chroma_filter5 = 0.002880460;
float chroma_filter6 = 0.003406879;
float chroma_filter7 = 0.004004985;
float chroma_filter8 = 0.004679445;
float chroma_filter9 = 0.005434218;
float chroma_filter10 = 0.006272332;
float chroma_filter11 = 0.007195654;
float chroma_filter12 = 0.008204665;
float chroma_filter13 = 0.009298238;
float chroma_filter14 = 0.010473450;
float chroma_filter15 = 0.011725413;
float chroma_filter16 = 0.013047155;
float chroma_filter17 = 0.014429548;
float chroma_filter18 = 0.015861306;
float chroma_filter19 = 0.017329037;
float chroma_filter20 = 0.018817382;
float chroma_filter21 = 0.020309220;
float chroma_filter22 = 0.021785952;
float chroma_filter23 = 0.023227857;
float chroma_filter24 = 0.024614500;
float chroma_filter25 = 0.025925203;
float chroma_filter26 = 0.027139546;
float chroma_filter27 = 0.028237893;
float chroma_filter28 = 0.029201910;
float chroma_filter29 = 0.030015081;
float chroma_filter30 = 0.030663170;
float chroma_filter31 = 0.031134640;
float chroma_filter32 = 0.031420995;
float chroma_filter33 = 0.031517031;
#else
#define TAPS 32
const float luma_filter[TAPS + 1] = float[TAPS + 1](
   -0.000174844,
   -0.000205844,
   -0.000149453,
   -0.000051693,
   0.000000000,
   -0.000066171,
   -0.000245058,
   -0.000432928,
   -0.000472644,
   -0.000252236,
   0.000198929,
   0.000687058,
   0.000944112,
   0.000803467,
   0.000363199,
   0.000013422,
   0.000253402,
   0.001339461,
   0.002932972,
   0.003983485,
   0.003026683,
   -0.001102056,
   -0.008373026,
   -0.016897700,
   -0.022914480,
   -0.021642347,
   -0.008863273,
   0.017271957,
   0.054921920,
   0.098342579,
   0.139044281,
   0.168055832,
   0.178571429);

const float chroma_filter[TAPS + 1] = float[TAPS + 1](
   0.001384762,
   0.001678312,
   0.002021715,
   0.002420562,
   0.002880460,
   0.003406879,
   0.004004985,
   0.004679445,
   0.005434218,
   0.006272332,
   0.007195654,
   0.008204665,
   0.009298238,
   0.010473450,
   0.011725413,
   0.013047155,
   0.014429548,
   0.015861306,
   0.017329037,
   0.018817382,
   0.020309220,
   0.021785952,
   0.023227857,
   0.024614500,
   0.025925203,
   0.027139546,
   0.028237893,
   0.029201910,
   0.030015081,
   0.030663170,
   0.031134640,
   0.031420995,
   0.031517031);
#endif
// end ntsc-decode-filter-3phase

void main()
{
// begin ntsc-pass2-decode
	float one_x = 1.0 / SourceSize.x;
	vec3 signal = vec3(0.0);
#ifdef GL_ES
	float offset;
	vec3 sums;
	
	#define macro_loopz(c) offset = float(c) - 1.0; \
		sums = fetch_offset(offset - 32., one_x) + fetch_offset(32. - offset, one_x); \
		signal += sums * vec3(luma_filter##c, chroma_filter##c, chroma_filter##c);

	macro_loopz(1)
	macro_loopz(2)
	macro_loopz(3)
	macro_loopz(4)
	macro_loopz(5)
	macro_loopz(6)
	macro_loopz(7)
	macro_loopz(8)
	macro_loopz(9)
	macro_loopz(10)
	macro_loopz(11)
	macro_loopz(12)
	macro_loopz(13)
	macro_loopz(14)
	macro_loopz(15)
	macro_loopz(16)
	macro_loopz(17)
	macro_loopz(18)
	macro_loopz(19)
	macro_loopz(20)
	macro_loopz(21)
	macro_loopz(22)
	macro_loopz(23)
	macro_loopz(24)
	macro_loopz(25)
	macro_loopz(26)
	macro_loopz(27)
	macro_loopz(28)
	macro_loopz(29)
	macro_loopz(30)
	macro_loopz(31)
	macro_loopz(32)

	signal += COMPAT_TEXTURE(Texture, TEX0.xy).xyz *
		vec3(luma_filter33, chroma_filter33, chroma_filter33);
#else
	for (int i = 0; i < TAPS; i++)
	{
		float offset = float(i);

		vec3 sums = fetch_offset(offset - float(TAPS), one_x) +
			fetch_offset(float(TAPS) - offset, one_x);

		signal += sums * vec3(luma_filter[i], chroma_filter[i], chroma_filter[i]);
	}
	signal += COMPAT_TEXTURE(Source, vTexCoord).xyz *
		vec3(luma_filter[TAPS], chroma_filter[TAPS], chroma_filter[TAPS]);
#endif
// end ntsc-pass2-decode
	vec3 rgb = yiq2rgb(signal);
	FragColor = vec4(pow(rgb, vec3(NTSC_CRT_GAMMA)), 1.0);
}
#endif
