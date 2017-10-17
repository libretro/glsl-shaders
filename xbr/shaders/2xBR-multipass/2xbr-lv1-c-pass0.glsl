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
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;
COMPAT_VARYING vec4 t4;
COMPAT_VARYING vec4 t5;
COMPAT_VARYING vec4 t6;
COMPAT_VARYING vec4 t7;

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
  
   t1 = TEX0.xxxy + vec4(    -dx,   0,  dx, -2.0*dy);  //  A1 B1 C1
   t2 = TEX0.xxxy + vec4(    -dx,   0,  dx,     -dy);  //   A  B  C
   t3 = TEX0.xxxy + vec4(    -dx,   0,  dx,       0);  //   D  E  F
   t4 = TEX0.xxxy + vec4(    -dx,   0,  dx,      dy);  //   G  H  I
   t5 = TEX0.xxxy + vec4(    -dx,   0,  dx,  2.0*dy);  //  G5 H5 I5
   t6 = TEX0.xyyy + vec4(-2.0*dx, -dy,   0,      dy);  //  A0 D0 G0
   t7 = TEX0.xyyy + vec4( 2.0*dx, -dy,   0,      dy);  //  C4 F4 I4
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
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;
COMPAT_VARYING vec4 t4;
COMPAT_VARYING vec4 t5;
COMPAT_VARYING vec4 t6;
COMPAT_VARYING vec4 t7;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

float threshold = 15.0;

float y_weight = 48.0;
float u_weight = 7.0;
float v_weight = 6.0;

mat3 yuv          = mat3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
mat3 yuv_weighted = mat3(14.352, 28.176, 5.472, -1.183, -2.317, 3.493, 2.994, 2.508, -0.4878);
vec4 bin          = vec4(1.0, 2.0, 4.0, 8.0);
vec4 maximo       = vec4(255.0, 255.0, 255.0, 255.0);

bvec4 _and_(bvec4 A, bvec4 B) {
   return bvec4(A.x && B.x, A.y && B.y, A.z && B.z, A.w && B.w);
}

bvec4 _or_(bvec4 A, bvec4 B) {
   return bvec4(A.x || B.x, A.y || B.y, A.z || B.z, A.w || B.w);
}

vec4 df(vec4 A, vec4 B) {
   return vec4(abs(A - B));
}

bvec4 close(vec4 A, vec4 B) {
   return (lessThan(df(A, B), vec4(threshold)));
}

vec4 weighted_distance(vec4 a, vec4 b, vec4 c, vec4 d, vec4 e, vec4 f, vec4 g, vec4 h) {
   return (df(a, b) + df(a, c) + df(d, e) + df(d, f) + 4.0 * df(g, h));
}

vec4 remapTo01(vec4 v, vec4 high) {
   return (v/high);
}

void main()
{
   bvec4 edr, px; // px = pixel, edr = edge detection rule
   bvec4 interp_restriction_lv1;

   vec3 A1 = COMPAT_TEXTURE(Source, t1.xw).rgb;
   vec3 B1 = COMPAT_TEXTURE(Source, t1.yw).rgb;
   vec3 C1 = COMPAT_TEXTURE(Source, t1.zw).rgb;

   vec3 A  = COMPAT_TEXTURE(Source, t2.xw).rgb;
   vec3 B  = COMPAT_TEXTURE(Source, t2.yw).rgb;
   vec3 C  = COMPAT_TEXTURE(Source, t2.zw).rgb;

   vec3 D  = COMPAT_TEXTURE(Source, t3.xw).rgb;
   vec3 E  = COMPAT_TEXTURE(Source, t3.yw).rgb;
   vec3 F  = COMPAT_TEXTURE(Source, t3.zw).rgb;

   vec3 G  = COMPAT_TEXTURE(Source, t4.xw).rgb;
   vec3 H  = COMPAT_TEXTURE(Source, t4.yw).rgb;
   vec3 I  = COMPAT_TEXTURE(Source, t4.zw).rgb;

   vec3 G5 = COMPAT_TEXTURE(Source, t5.xw).rgb;
   vec3 H5 = COMPAT_TEXTURE(Source, t5.yw).rgb;
   vec3 I5 = COMPAT_TEXTURE(Source, t5.zw).rgb;

   vec3 A0 = COMPAT_TEXTURE(Source, t6.xy).rgb;
   vec3 D0 = COMPAT_TEXTURE(Source, t6.xz).rgb;
   vec3 G0 = COMPAT_TEXTURE(Source, t6.xw).rgb;

   vec3 C4 = COMPAT_TEXTURE(Source, t7.xy).rgb;
   vec3 F4 = COMPAT_TEXTURE(Source, t7.xz).rgb;
   vec3 I4 = COMPAT_TEXTURE(Source, t7.xw).rgb;

   vec4 bdhf = yuv_weighted[0]*mat4x3( B,  D,  H,  F);
   vec4 cagi = yuv_weighted[0]*mat4x3( C,  A,  G,  I);
   vec4 e    = yuv_weighted[0]*mat4x3( E,  E,  E,  E);
   vec4 i4   = yuv_weighted[0]*mat4x3(I4, C4, A0, G0);
   vec4 i5   = yuv_weighted[0]*mat4x3(I5, C1, A1, G5);
   vec4 h5x  = yuv_weighted[0]*mat4x3(H5, F4, B1, D0);

   vec4 b = bdhf.xzzx;
   vec4 d = bdhf.yyww;
   vec4 h = bdhf.zxxz;
   vec4 f = bdhf.wwyy;
   vec4 c = cagi.xwzy;
   vec4 a = cagi.yzwx;
   vec4 g = cagi.zyxw;
   vec4 i = cagi.wxyz;

   vec4 f4 = h5x.yyww;
   vec4 h5 = h5x.xzzx;

   bvec4 r1 = _and_( notEqual(  e,  f ), notEqual( e,  h ) );
   bvec4 r2 = _and_( not(close( f,  b)), not(close(f,  c)) );
   bvec4 r3 = _and_( not(close( h,  d)), not(close(h,  g)) );
   bvec4 r4 = _and_( not(close( f, f4)), not(close(f, i4)) );
   bvec4 r5 = _and_( not(close( h, h5)), not(close(h, i5)) );
   bvec4 r6 = _and_( close(e, i),  _or_(r4, r5) );
   bvec4 r7 =  _or_( close(e, g), close( e,  c) );

   interp_restriction_lv1 = _and_( r1, _or_( _or_( _or_(r2, r3), r6 ), r7 ) );

   edr = _and_( lessThan(weighted_distance(e, c, g, i, h5, f4, h, f), weighted_distance(h, d, i5, f, i4, b, e, i)), interp_restriction_lv1 );

   px  = lessThanEqual(df(e, f), df(e, h));

   vec4 info = bin*mat4(
                          edr.x, px.x, 0.0, 0.0,
                          edr.y, px.y, 0.0, 0.0,
                          edr.z, px.z, 0.0, 0.0,
                          edr.w, px.w, 0.0, 0.0
                          );
   FragColor = vec4(remapTo01(info, maximo));
} 
#endif
