// EPX (Eric's Pixel Scaler)
// based on the description from Wikipedia:
// https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms#EPX/Scale2%C3%97/AdvMAME2%C3%97
// adapted for glsl by hunterk
// license GPL, I think

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
// out variables go here as COMPAT_VARYING whatever

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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

bool same(vec3 B, vec3 A0){
   return all(equal(B, A0));
}

bool notsame(vec3 B, vec3 A0){
   return any(notEqual(B, A0));
}

// sample with coordinate offsets
#define TEX(c,d) COMPAT_TEXTURE(Source, vTexCoord.xy + vec2(c,d) * SourceSize.zw).rgb

void main()
{
// The algorithm looks at the current pixel and the 4 surrounding cardinal pixels  
// ___|_A_|___  
// _C_|_P_|_B_
//    | D |  

// Our current pixel, P
   vec3 P = TEX( 0., 0.);

// Input pixels
   vec3 A = TEX( 0., 1.);
   vec3 B = TEX( 1., 0.);
   vec3 D = TEX( 0.,-1.);
   vec3 C = TEX(-1., 0.);
   
// Output: 2x2 grid. Default to the current pixel color (Nearest magnification)
// ___one_|_two___
//  three | four
   vec3 one   = P;
   vec3 two   = P;
   vec3 three = P;
   vec3 four  = P;

// EPX algorithm rules:   
// IF C==A AND C!=D AND A!=B => 1=A
// IF A==B AND A!=C AND B!=D => 2=B
// IF D==C AND D!=B AND C!=A => 3=C
// IF B==D AND B!=A AND D!=C => 4=D

   one   = (same(C, D) && notsame(C, A) && notsame(C, B)) ? C : P;
   two   = (same(D, B) && notsame(D, C) && notsame(D, A)) ? D : P;
   three = (same(A, C) && notsame(A, B) && notsame(A, D)) ? A : P;
   four  = (same(B, A) && notsame(B, D) && notsame(B, C)) ? B : P;

   vec2 px = fract(vTexCoord * SourceSize.xy);
// split the texels into 4 and assign one of our output pixels to each
   FragColor.rgb = (px.x < 0.5) ? (px.y < 0.5 ? one : three) : (px.y < 0.5 ? two : four);
   FragColor.a = 1.0;
} 
#endif
