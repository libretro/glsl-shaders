#version 130

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
COMPAT_VARYING vec4 t1;

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
    TEX0.xy = TexCoord.xy;
   //     A1 B1 C1
   //  A0  A  B  C C4
   //  D0  D  E  F F4
   //  G0  G  H  I I4
   //     G5 H5 I5

   float dx = SourceSize.z;
   float dy = SourceSize.w;
   
   t1 = vec4(dx, 0, 0, dy);  // F H
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
uniform sampler2D OrigTexture;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#define OriginalSize vec4(OrigTextureSize, 1.0 / OrigTextureSize)
#define Original OrigTexture

mat4x2 sym_vectors  = mat4x2(1.,  1.,   1., -1.,   -1., -1.,   -1.,  1.);

float remapFrom01(float v, float high)
{
   return (high*v + 0.5);
}

vec2 unpack_info(float i)
{
   vec2 info;
   info.x = round(modf(i/2.0, i));
   info.y = i;

   return info;
}

void main()
{
//get original texture coordinates relative to the current pass
   vec2 OriginalCoord = floor(OriginalSize.xy * vTexCoord);
   OriginalCoord = (OriginalCoord + 0.5) * OriginalSize.zw;
   
   float px, edr; // px = pixel to blend, edr = edge detection rule

   vec2 pos = fract(vTexCoord*SourceSize.xy)-vec2(0.5, 0.5); // pos = pixel position
   vec2 dir = sign(pos); // dir = pixel direction

   vec2 g1  = dir*t1.xy;
   vec2 g2  = dir*t1.zw;

   vec3 F   = COMPAT_TEXTURE(Original, OriginalCoord +g1).rgb;
   vec3 H   = COMPAT_TEXTURE(Original, OriginalCoord +g2).rgb;
   vec3 E   = COMPAT_TEXTURE(Original, OriginalCoord    ).rgb;

   vec4 icomp = round(clamp(dir*sym_vectors, vec4(0.0), vec4(1.0))); // choose info component
   float  info  = remapFrom01(dot(COMPAT_TEXTURE(Source, vTexCoord), icomp), 255.0f); // retrieve 1st pass info
   vec2 flags = unpack_info(info); // retrieve 1st pass flags

   edr = flags.x;
   px  = flags.y;

   vec3 color = mix(E, mix(H, F, px), edr*0.5); // interpolate if there's edge
   
   FragColor = vec4(color, 1.0);
} 
#endif
