#version 130

// Insert a configurable count (1, 2, 3...) of interpolated display (high-res)
// pixel rows between each pair of adjacent source (low-res) pixels.
// by decavoid


#pragma parameter PixelCount "Pixel Count" 2.0 1.0 8.0 1.0

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
COMPAT_VARYING vec4 sizeScale;
COMPAT_VARYING vec2 interpolationRangeHalf;
COMPAT_VARYING float stepPerRow;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PixelCount;
#else
#define PixelCount 2.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy * TextureSize.xy; // NES x: [0; 256], y: [0; 240]

    sizeScale = vec4(OutputSize / InputSize, InputSize / OutputSize);
    interpolationRangeHalf = PixelCount * 0.5 * sizeScale.zw;
    stepPerRow = 1.0 / (PixelCount + 1.0);
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
COMPAT_VARYING vec4 sizeScale;
COMPAT_VARYING vec2 interpolationRangeHalf;
COMPAT_VARYING float stepPerRow;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize


// uncomment to see a red grid of modified pixels
//#define DEBUG_DRAW_EDGES

void main()
{
	vec2 PixelCoords = vTexCoord;
	vec2 iPixelCoords = floor(PixelCoords);
	vec2 coordAtPixelCenter = iPixelCoords + vec2(0.5);
	vec2 coordBetweenPixels = round(PixelCoords);
	vec2 origOffset = PixelCoords - coordBetweenPixels + 1e-3; // [-0.5; 0.5]

	vec2 needInterpolate = step(abs(origOffset), interpolationRangeHalf);

	// if needInterpolate == 0, disable interpolation, choose coordAtPixelCenter.
	//
	// if needInterpolate == 1, transform origOffset.x
	// from range [-interpolationRangeHalf.x; interpolationRangeHalf.x]
	// to range (-0.5; 0.5)
	vec2 segmentIndex = floor((origOffset + interpolationRangeHalf) * sizeScale.xy);
	vec2 transformedOffset = stepPerRow * (segmentIndex + 1.0) - 0.5;
	vec2 interpolatedCoord = coordBetweenPixels + transformedOffset;

	vec2 newCoord = (1.0 - needInterpolate) * coordAtPixelCenter + needInterpolate * interpolatedCoord;
	vec2 newTexCoord = newCoord * SourceSize.zw;

	FragColor = vec4(COMPAT_TEXTURE(Source, newTexCoord).rgb, 1.0);

#ifdef DEBUG_DRAW_EDGES
	if (needInterpolate.x + needInterpolate.y > 0)
		FragColor.r = 1;
#endif
}

#endif
