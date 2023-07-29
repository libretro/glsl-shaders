#version 110

// NTSC-Adaptive
// based on Themaister's NTSC shader

#pragma parameter quality "NTSC Preset (Svideo=0 Composite=1 RF=2 Custom=-1)" 1.0 -1.0 2.0 1.0
#pragma parameter ntsc_fields "NTSC Merge Fields" 0.0 0.0 1.0 1.0
#pragma parameter ntsc_phase "NTSC Phase: Auto | 2 phase | 3 phase" 1.0 1.0 3.0 1.0
#pragma parameter ntsc_scale "NTSC Resolution Scaling" 1.0 0.20 3.0 0.05
#pragma parameter ntsc_sat "NTSC Color Saturation" 1.0 0.0 2.0 0.01
#pragma parameter ntsc_bright "NTSC Brightness" 1.0 0.0 1.5 0.01
#pragma parameter cust_fringing "NTSC Custom Fringing Value" 0.0 0.0 5.0 0.1
#pragma parameter cust_artifacting "NTSC Custom Artifacting Value" 0.0 0.0 5.0 0.1

#define PI 3.14159265

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
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 pix_no;
COMPAT_VARYING float phase;
COMPAT_VARYING float BRIGHTNESS;
COMPAT_VARYING float SATURATION;
COMPAT_VARYING float FRINGING;
COMPAT_VARYING float ARTIFACTING;
COMPAT_VARYING float CHROMA_MOD_FREQ;
COMPAT_VARYING float MERGE;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float quality, ntsc_sat, cust_fringing, cust_artifacting, ntsc_bright, ntsc_scale, ntsc_fields, ntsc_phase;
#else
#define ntsc_fields 0.0
#define ntsc_phase 1.0
#define ntsc_sat 1.0
#define ntsc_bright 1.0
#define cust_fringing 0.0
#define cust_artifacting 0.0
#define quality 0.0
#endif

void main()
{
   float res = ntsc_scale;
   float OriginalSize = OrigInputSize.x;
   gl_Position = MVPMatrix * VertexCoord;
   TEX0.xy = TexCoord.xy;
	if (res < 1.0) pix_no = vTexCoord * SourceSize.xy * (res * OutSize.xy / InputSize.xy);
	else
                  pix_no = vTexCoord * SourceSize.xy * (      OutSize.xy / InputSize.xy);
   pix_no = vTexCoord * SourceSize.xy * (OutSize.xy / InputSize.xy);
	phase = (ntsc_phase < 1.5) ? ((OriginalSize > 300.0) ? 2.0 : 3.0) : ((ntsc_phase > 2.5) ? 3.0 : 2.0);
	
	res = max(res, 1.0);	
	CHROMA_MOD_FREQ = (phase < 2.5) ? (4.0 * PI / 15.0) : (PI / 3.0);
	ARTIFACTING = (quality > -0.5) ? quality * 0.5*(res+1.0) : cust_artifacting;
	FRINGING = (quality > -0.5) ? quality : cust_fringing;
	SATURATION = ntsc_sat;
	BRIGHTNESS = ntsc_bright;	
	pix_no.x = pix_no.x * res;

	MERGE = (int(quality) == 2 || phase < 2.5) ? 0.0 : 1.0;
	MERGE = (int(quality) == -1) ? ntsc_fields : MERGE;
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
uniform COMPAT_PRECISION vec2 OrigInputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 pix_no;
COMPAT_VARYING float phase;
COMPAT_VARYING float BRIGHTNESS;
COMPAT_VARYING float SATURATION;
COMPAT_VARYING float FRINGING;
COMPAT_VARYING float ARTIFACTING;
COMPAT_VARYING float CHROMA_MOD_FREQ;
COMPAT_VARYING float MERGE;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float quality, ntsc_sat, cust_fringing, cust_artifacting, ntsc_bright, ntsc_scale, ntsc_fields, ntsc_phase;
#else
#define ntsc_fields 0.0
#define ntsc_phase 1.0
#define ntsc_sat 1.0
#define ntsc_bright 1.0
#define cust_fringing 0.0
#define cust_artifacting 0.0
#define quality 0.0
#endif

#define PI 3.14159265

#define mix_mat mat3(BRIGHTNESS, FRINGING, FRINGING, ARTIFACTING, 2.0 * SATURATION, 0.0, ARTIFACTING, 0.0, 2.0 * SATURATION)

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

vec4 pack_float(vec4 color)
{
	return ((color * 10.0) - 1.0);
}

void main()
{
   vec3 col = COMPAT_TEXTURE(Source, vTexCoord).rgb;
   vec3 yiq = rgb2yiq(col);
   vec3 yiq2 = yiq;	

   float mod1 = 2.0;
   float mod2 = 3.0; 
   float frame = float (FrameCount);

if (MERGE > 0.5)
{
   float chroma_phase2 = (phase < 2.5) ? PI * (mod(pix_no.y, mod1) + mod(frame+1., 2.)) : 0.6667 * PI * (mod(pix_no.y, mod2) + mod(frame+1.0, 2.));
   float mod_phase2 = chroma_phase2 + pix_no.x * CHROMA_MOD_FREQ;
   float i_mod2 = cos(mod_phase2);
   float q_mod2 = sin(mod_phase2);
   yiq2.yz *= vec2(i_mod2, q_mod2); // Modulate.
   yiq2 *= mix_mat; // Cross-talk.
   yiq2.yz *= vec2(i_mod2, q_mod2); // Demodulate.   
}
   
   float chroma_phase = (phase < 2.5) ? PI * (mod(pix_no.y, mod1) + mod(frame, 2.)) : 0.6667 * PI * (mod(pix_no.y, mod2) + mod(frame, 2.));
   float mod_phase = chroma_phase + pix_no.x * CHROMA_MOD_FREQ;

   float i_mod = cos(mod_phase);
   float q_mod = sin(mod_phase);

   yiq.yz *= vec2(i_mod, q_mod); // Modulate.
   yiq *= mix_mat; // Cross-talk.
   yiq.yz *= vec2(i_mod, q_mod); // Demodulate.
      
   yiq = (MERGE < 0.5) ? yiq : 0.5*(yiq+yiq2);
   
   FragColor = vec4(yiq, 1.0);
#ifdef GL_ES
   FragColor = pack_float(FragColor);
#endif
} 
#endif
