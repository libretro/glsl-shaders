// version directive if necessary

// blendoverlay
// based on:
// https://github.com/jamieowen/glsl-blend for blendOverlay

#pragma parameter OverlayMix "Overlay Mix" 1.0 0.0 1.0 0.05
#pragma parameter LUTWidth "LUT Width" 6.0 1.0 1920.0 1.0
#pragma parameter LUTHeight "LUT Height" 4.0 1.0 1920.0 1.0

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
uniform sampler2D overlay;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float OverlayMix, LUTWidth, LUTHeight;
#else
#define OverlayMix 1.0
#define LUTWidth 6.0
#define LUTHeight 4.0
#endif

float blendOverlay(float base, float blend) {
	return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}

void main()
{
    vec3  Picture    = COMPAT_TEXTURE(Source, vTexCoord).xyz;

    float Luminance    = 0.299*Picture.x + 0.587*Picture.y + 0.114*Picture.z;

    vec2  LutCoord   = vTexCoord * TextureSize / InputSize;
    LutCoord   =  vec2(fract(LutCoord.x*OutputSize.x/LUTWidth),fract(LutCoord.y*OutputSize.y/LUTHeight));

    vec3  ShadowMask = COMPAT_TEXTURE(overlay, LutCoord).xyz;
    
    vec3 ImageFinal  = Picture;
    
    ImageFinal.r = blendOverlay(ImageFinal.r,ShadowMask.r);
    ImageFinal.g = blendOverlay(ImageFinal.g,ShadowMask.g);
    ImageFinal.b = blendOverlay(ImageFinal.b,ShadowMask.b);
    
    ImageFinal   = mix(Picture,clamp(ImageFinal,0.0,1.0),OverlayMix);
    
    FragColor = vec4(ImageFinal,1.0);
} 
#endif
