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
#if __VERSION__ <= 130
float luma_filter1 = -0.000012020;
float luma_filter2 = -0.000022146;
float luma_filter3 = -0.000013155;
float luma_filter4 = -0.000012020;
float luma_filter5 = -0.000049979;
float luma_filter6 = -0.000113940;
float luma_filter7 = -0.000122150;
float luma_filter8 = -0.000005612;
float luma_filter9 = 0.000170516;
float luma_filter10 = 0.000237199;
float luma_filter11 = 0.000169640;
float luma_filter12 = 0.000285688;
float luma_filter13 = 0.000984574;
float luma_filter14 = 0.002018683;
float luma_filter15 = 0.002002275;
float luma_filter16 = -0.000909882;
float luma_filter17 = -0.007049081;
float luma_filter18 = -0.013222860;
float luma_filter19 = -0.012606931;
float luma_filter20 = 0.002460860;
float luma_filter21 = 0.035868225;
float luma_filter22 = 0.084016453;
float luma_filter23 = 0.135563500;
float luma_filter24 = 0.175261268;
float luma_filter25 = 0.190176552;

float chroma_filter1 = -0.000118847;
float chroma_filter2 = -0.000271306;
float chroma_filter3 = -0.000502642;
float chroma_filter4 = -0.000930833;
float chroma_filter5 = -0.001451013;
float chroma_filter6 = -0.002064744;
float chroma_filter7 = -0.002700432;
float chroma_filter8 = -0.003241276;
float chroma_filter9 = -0.003524948;
float chroma_filter10 = -0.003350284;
float chroma_filter11 = -0.002491729;
float chroma_filter12 = -0.000721149;
float chroma_filter13 = 0.002164659;
float chroma_filter14 = 0.006313635;
float chroma_filter15 = 0.011789103;
float chroma_filter16 = 0.018545660;
float chroma_filter17 = 0.026414396;
float chroma_filter18 = 0.035100710;
float chroma_filter19 = 0.044196567;
float chroma_filter20 = 0.053207202;
float chroma_filter21 = 0.061590275;
float chroma_filter22 = 0.068803602;
float chroma_filter23 = 0.074356193;
float chroma_filter24 = 0.077856564;
float chroma_filter25 = 0.079052396;
#else
#define TAPS 24
const float luma_filter[TAPS + 1] = float[TAPS + 1](
   -0.000012020,
   -0.000022146,
   -0.000013155,
   -0.000012020,
   -0.000049979,
   -0.000113940,
   -0.000122150,
   -0.000005612,
   0.000170516,
   0.000237199,
   0.000169640,
   0.000285688,
   0.000984574,
   0.002018683,
   0.002002275,
   -0.000909882,
   -0.007049081,
   -0.013222860,
   -0.012606931,
   0.002460860,
   0.035868225,
   0.084016453,
   0.135563500,
   0.175261268,
   0.190176552);

const float chroma_filter[TAPS + 1] = float[TAPS + 1](
   -0.000118847,
   -0.000271306,
   -0.000502642,
   -0.000930833,
   -0.001451013,
   -0.002064744,
   -0.002700432,
   -0.003241276,
   -0.003524948,
   -0.003350284,
   -0.002491729,
   -0.000721149,
   0.002164659,
   0.006313635,
   0.011789103,
   0.018545660,
   0.026414396,
   0.035100710,
   0.044196567,
   0.053207202,
   0.061590275,
   0.068803602,
   0.074356193,
   0.077856564,
   0.079052396);
#endif
// end ntsc-decode-filter-3phase

void main()
{
// begin ntsc-pass2-decode
	float one_x = 1.0 / SourceSize.x;
	vec3 signal = vec3(0.0);
#if __VERSION__ <= 130
	float offset;
	vec3 sums;

	#define macro_loopz(c) offset = float(c) - 1.0; \
		sums = fetch_offset(offset - 24., one_x) + fetch_offset(24. - offset, one_x); \
		signal += sums * vec3(luma_filter##c, chroma_filter##c, chroma_filter##c);

	// unrolling the loopz
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

	signal += COMPAT_TEXTURE(Texture, TEX0.xy).xyz *
		vec3(luma_filter25, chroma_filter25, chroma_filter25);
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
