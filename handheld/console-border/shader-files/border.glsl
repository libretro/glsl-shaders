// Parameter lines go here:
#pragma parameter box_scale "Image Scale" 4.0 1.0 10.0 1.0
#pragma parameter location_x "Viewport X Pos." 0.5 0.0 1.0 0.05
#pragma parameter location_y "Viewport Y Pos." 0.5 0.0 1.0 0.05
#pragma parameter in_res_x "Viewport Size X" 320.0 100.0 600.0 1.0
#pragma parameter in_res_y "Viewport Size Y" 240.0 64.0 512.0 1.0
#pragma parameter border_on_top "Show Viewport" 1.0 0.0 1.0 1.0
#pragma parameter border_zoom_x "Border Zoom X" 1.0 0.0 4.0 0.01
#pragma parameter border_zoom_y "Border Zoom Y" 1.0 0.0 4.0 0.01

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
COMPAT_VARYING vec2 screen_coord;

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float box_scale;
uniform COMPAT_PRECISION float location_x;
uniform COMPAT_PRECISION float location_y;
uniform COMPAT_PRECISION float in_res_x;
uniform COMPAT_PRECISION float in_res_y;
uniform COMPAT_PRECISION float border_on_top;
uniform COMPAT_PRECISION float border_zoom_x;
uniform COMPAT_PRECISION float border_zoom_y;
#else
#define box_scale 4.0
#define location_x 0.5
#define location_y 0.5
#define in_res_x 320.0
#define in_res_y 240.0
#define border_on_top 1.0
#define border_zoom_x 1.0
#define border_zoom_y 1.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
   vec2 corrected_size = vec2(in_res_x, in_res_y);
   vec2 scale = (OutputSize.xy / corrected_size) / box_scale;
   vec2 middle = vec2(location_x, location_y) * InputSize.xy / TextureSize.xy;;
   vec2 diff = TexCoord.xy - middle;
   screen_coord = middle + diff * scale;
   middle = vec2(0.4999, 0.4999);
   diff = TexCoord.xy * (TextureSize.xy / InputSize.xy) - middle;
    TEX0.xy = middle + diff * vec2(border_zoom_x, border_zoom_y);
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
uniform sampler2D BORDER;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 screen_coord;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float box_scale;
uniform COMPAT_PRECISION float location_x;
uniform COMPAT_PRECISION float location_y;
uniform COMPAT_PRECISION float in_res_x;
uniform COMPAT_PRECISION float in_res_y;
uniform COMPAT_PRECISION float border_on_top;
uniform COMPAT_PRECISION float border_zoom_x;
uniform COMPAT_PRECISION float border_zoom_y;
#endif

void main()
{
vec4 screen = COMPAT_TEXTURE(Source, screen_coord); //the main video screen
vec4 background = vec4(COMPAT_TEXTURE(BORDER, vTexCoord)); //put your background function's output here
if ( screen_coord.x < 0.9999 && screen_coord.x > 0.0001 && screen_coord.y < 0.9999 && screen_coord.y > 0.0001 && border_on_top > 0.5 )
background.a *= 0.0;
   FragColor = vec4(mix(screen, background, background.a));
} 
#endif
