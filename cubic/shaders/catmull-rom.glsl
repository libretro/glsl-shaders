/*
	Bicubic Catmull-Rom 9 taps (Fast) - ported by Hyllian - 2020
	The following code is licensed under the MIT license: https://gist.github.com/TheRealMJP/bc503b0b87b643d3505d41eab8b332ae
	Ported from code: https://gist.github.com/TheRealMJP/c83b8c0f46b63f3a88a5986f4fa982b1
	Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
	See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
	ATENTION: This code only work using LINEAR filter sampling set on Retroarch!
*/

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
precision COMPAT_PRECISION float;
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
out mediump vec4 FragColor;
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

#define mul(c,d) (d*c)

void main()
{
    // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
    // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
    // location [1, 1] in the grid, where [0, 0] is the top left corner.
    vec2 samplePos = vTexCoord * SourceSize.xy;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

    // Compute the fractional offset from our starting texel to our original sample location, which we'll
    // feed into the Catmull-Rom spline function to get our filter weights.
    vec2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
 //   vec2 w3 = 1.0 - w0 - w1 - w2;

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / (w1 + w2);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0  = texPos1 - 1.;
    vec2 texPos3  = texPos1 + 2.;
    vec2 texPos12 = texPos1 + offset12;

    texPos0  *= SourceSize.zw;
    texPos3  *= SourceSize.zw;
    texPos12 *= SourceSize.zw;

    vec4 c00  = COMPAT_TEXTURE(Source, vec2(texPos0.x, texPos0.y));
    vec4 c10  = COMPAT_TEXTURE(Source, vec2(texPos12.x, texPos0.y));
    vec4 c20  = COMPAT_TEXTURE(Source, vec2(texPos3.x, texPos0.y));

    vec4 c01  = COMPAT_TEXTURE(Source, vec2(texPos0.x, texPos12.y));
    vec4 c11  = COMPAT_TEXTURE(Source, vec2(texPos12.x, texPos12.y));
    vec4 c21  = COMPAT_TEXTURE(Source, vec2(texPos3.x, texPos12.y));

    vec4 c02  = COMPAT_TEXTURE(Source, vec2(texPos0.x, texPos3.y));
    vec4 c12  = COMPAT_TEXTURE(Source, vec2(texPos12.x, texPos3.y));
    vec4 c22  = COMPAT_TEXTURE(Source, vec2(texPos3.x, texPos3.y));

    // initialize some variables
    vec4 c1, c2, c3, wx, wy = vec4(0.,0.,0.,0.);
    // junk vec4 used only to round out the non-square 3x4 matrices
    vec4 dummy = vec4(0.,0.,0.,1.);

    wx   = vec4(w0.x, w12.x, w3.x, 1.0);
    wy   = vec4(w0.y, w12.y, w3.y, 1.0);

    c1   = vec4(mul(wx, mat4(c00, c10, c20, dummy)));
    c2   = vec4(mul(wx, mat4(c01, c11, c21, dummy)));
    c3   = vec4(mul(wx, mat4(c02, c12, c22, dummy)));

    FragColor = mul(wy, mat4(c1, c2, c3, dummy));
}
#endif
