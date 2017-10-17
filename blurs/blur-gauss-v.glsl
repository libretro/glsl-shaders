// Implementation based on the article "Efficient Gaussian blur with linear sampling"
// http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
/* A version for MasterEffect Reborn, a standalone version, and a custom shader version for SweetFX can be 
   found at http://reshade.me/forum/shader-presentation/27-gaussian-blur-bloom-unsharpmask */
 /*-----------------------------------------------------------.
/                  Gaussian Blur settings                     /
'-----------------------------------------------------------*/

#define VW 1.00

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
// out variables go here as COMPAT_VARYING whatever

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
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	vec2 texcoord  = vTexCoord;
	vec2 PIXEL_SIZE = SourceSize.zw;
#if __VERSION__ < 130
	float sampleOffsets1 = 0.0;
	float sampleOffsets2 = 1.4347826;
	float sampleOffsets3 = 3.3478260;
	float sampleOffsets4 = 5.2608695;
	float sampleOffsets5 = 7.1739130;

	float sampleWeights1 = 0.16818994;
	float sampleWeights2 = 0.27276957;
	float sampleWeights3 = 0.11690125;
	float sampleWeights4 = 0.024067905;
	float sampleWeights5 = 0.0021112196;

	vec4 color = COMPAT_TEXTURE(Source, texcoord) * sampleWeights1;

// unroll the loop
		color += COMPAT_TEXTURE(Source, texcoord + vec2(0.0, sampleOffsets2* VW * PIXEL_SIZE.y)) * sampleWeights2;
		color += COMPAT_TEXTURE(Source, texcoord - vec2(0.0, sampleOffsets2* VW * PIXEL_SIZE.y)) * sampleWeights2;

		color += COMPAT_TEXTURE(Source, texcoord + vec2(0.0, sampleOffsets3* VW * PIXEL_SIZE.y)) * sampleWeights3;
		color += COMPAT_TEXTURE(Source, texcoord - vec2(0.0, sampleOffsets3* VW * PIXEL_SIZE.y)) * sampleWeights3;

		color += COMPAT_TEXTURE(Source, texcoord + vec2(0.0, sampleOffsets4* VW * PIXEL_SIZE.y)) * sampleWeights4;
		color += COMPAT_TEXTURE(Source, texcoord - vec2(0.0, sampleOffsets4* VW * PIXEL_SIZE.y)) * sampleWeights4;

		color += COMPAT_TEXTURE(Source, texcoord + vec2(0.0, sampleOffsets5* VW * PIXEL_SIZE.y)) * sampleWeights5;
		color += COMPAT_TEXTURE(Source, texcoord - vec2(0.0, sampleOffsets5* VW * PIXEL_SIZE.y)) * sampleWeights5;
#else

	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };

	vec4 color = COMPAT_TEXTURE(Source, texcoord) * sampleWeights[0];
	for(int i = 1; i < 5; ++i) {
		color += COMPAT_TEXTURE(Source, texcoord + vec2(0.0, sampleOffsets[i]*VW * PIXEL_SIZE.y)) * sampleWeights[i];
		color += COMPAT_TEXTURE(Source, texcoord - vec2(0.0, sampleOffsets[i]*VW * PIXEL_SIZE.y)) * sampleWeights[i];
	}
#endif

   FragColor = vec4(color);
} 
#endif
