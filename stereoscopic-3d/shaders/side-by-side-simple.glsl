#pragma parameter eye_sep "Eye Separation" 0.30 -1.0 5.0 0.05
#pragma parameter y_loc "Vertical Placement" 0.25 -1.0 1.0 0.01
#pragma parameter BOTH "Horizontal Placement" 0.51 -2.0 2.0 0.005
#pragma parameter ana_zoom "Zoom" 0.75 -2.0 2.0 0.05
#pragma parameter WIDTH "Side-by-Side Image Width" 3.05 1.0 7.0 0.05
#pragma parameter HEIGHT "Side-by-Side Image Height" 2.0 1.0 5.0 0.1
#pragma parameter warpX "Lens Warp Correction X" 0.1 0.0 0.5 0.05
#pragma parameter warpY "Lens Warp Correction Y" 0.1 0.0 0.5 0.05
#pragma parameter pulfrich "Pulfrich Effect" 0.0 0.0 0.5 0.25

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float eye_sep, y_loc, ana_zoom, WIDTH, BOTH, HEIGHT, warpX, warpY, pulfrich;
#else
#define eye_sep 0.35
#define y_loc 0.30
#define ana_zoom 0.75
#define WIDTH 3.05
#define BOTH 0.64
#define HEIGHT 2.0
#define warpX 0.3
#define warpY 0.3
#define pulfrich 0.0
#endif

void main()
{
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    vec2 shift = 0.5 * InputSize / TextureSize;
    TEX0.xy = ((TexCoord.xy - shift) * ana_zoom + shift) * vec2(WIDTH, HEIGHT) - vec2(BOTH, 0.0);
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


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float eye_sep, y_loc, ana_zoom, WIDTH, BOTH, HEIGHT, warpX, warpY, pulfrich;
#else
#define eye_sep 0.30
#define y_loc 0.25
#define ana_zoom 0.75
#define WIDTH 3.05
#define BOTH 0.51
#define HEIGHT 2.0
#define warpX 0.1
#define warpY 0.1
#define pulfrich 0.0
#endif

//distortion
vec2 Warp(vec2 pos){
  pos.xy = pos.xy * 2.0-1.0;    
  pos.xy *= vec2(1.0+(pos.y*pos.y)*warpX,1.0+(pos.x*pos.x)*warpY);
  return pos*0.5+0.5;}

void main()
{
	vec2 warpCoord1 = Warp((TEX0.xy - vec2(eye_sep,  y_loc))*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
	vec2 warpCoord2 = Warp((TEX0.xy + vec2(eye_sep, -y_loc))*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
   vec2 fragCoord1 = warpCoord1 * InputSize / TextureSize;
   vec2 fragCoord2 = warpCoord2 * InputSize / TextureSize;
   vec4 frame1 = vec4(0.0);
   if ( fragCoord1.x < 1.0 && fragCoord1.x > 0.0 && fragCoord1.y < 1.0 && fragCoord1.y > 0.0 )
   frame1 = COMPAT_TEXTURE(Texture, warpCoord1);
   vec4 frame2 = vec4(0.0);
   if ( fragCoord2.x < 1.0 && fragCoord2.x > 0.0 && fragCoord2.y < 1.0 && fragCoord2.y > 0.0 )
   frame2 = COMPAT_TEXTURE(Texture, warpCoord2) * (1.0 - pulfrich);

   vec4 final = vec4(frame1 + frame2);
    FragColor = final;
} 
#endif
