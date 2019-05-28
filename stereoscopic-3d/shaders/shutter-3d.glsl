// Shutter 3D to side-by-side
// by hunterk
// license: public domain

#pragma parameter ZOOM "Zoom" 1.0 0.0 2.0 0.01
#pragma parameter vert_pos "Vertical Modifier" 0.0 -2.0 2.0 0.01
#pragma parameter horz_pos "Horizontal Modifier" 0.0 -2.0 2.0 0.01
#pragma parameter separation "Eye Separation" 0.0 -2.0 2.0 0.01
#pragma parameter flicker "Hold Last Frame (reduce flicker)" 0.0 0.0 1.0 0.25
#pragma parameter height_mod "Image Height" 1.0 0.0 2.0 0.01
#pragma parameter swap_eye "Swap Eye Sequence" 0.0 0.0 1.0 1.0

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
COMPAT_VARYING vec2 left_coord;
COMPAT_VARYING vec2 right_coord;
COMPAT_VARYING float timer;

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ZOOM, vert_pos, separation, flicker, height_mod, horz_pos, swap_eye;
#else
#define ZOOM 1.0
#define vert_pos 0.0
#define horz_pos 0.0
#define separation 0.0
#define flicker 0.0
#define height_mod 1.0
#define swap_eye 0.0
#endif

void main()
{
   gl_Position = MVPMatrix * VertexCoord;
	vec2 temp_coord = TexCoord.xy - 0.5 * InputSize / TextureSize;
	temp_coord *= ZOOM;
	temp_coord *= vec2(2.,1. / height_mod);
	temp_coord += vec2(horz_pos, vert_pos);
	temp_coord += 0.5 * InputSize / TextureSize;
   left_coord  = temp_coord.xy - vec2(0.5 + separation,0.) * InputSize / TextureSize;
	right_coord = temp_coord.xy + vec2(0.5 + separation,0.) * InputSize / TextureSize;
	timer = abs(swap_eye - mod(float(FrameCount), 2.));
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
uniform sampler2D PrevTexture;
COMPAT_VARYING vec2 left_coord;
COMPAT_VARYING vec2 right_coord;
COMPAT_VARYING float timer;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ZOOM, vert_pos, separation, flicker, height_mod, horz_pos, swap_eye;
#else
#define ZOOM 1.0
#define vert_pos 0.0
#define horz_pos 0.0
#define separation 0.0
#define flicker 0.0
#define height_mod 1.0
#define swap_eye 0.0
#endif

void main()
{
	vec4 left_screen = COMPAT_TEXTURE(Source, left_coord);
	vec4 left_hold = COMPAT_TEXTURE(PrevTexture, left_coord);
	vec4 right_screen = COMPAT_TEXTURE(Source, right_coord);
	vec4 right_hold = COMPAT_TEXTURE(PrevTexture, right_coord);
	left_screen = left_screen * timer + (1. - timer) * left_hold * flicker;
	vec2 left_fragcoord = left_coord * InputSize / TextureSize;
	bool left_check = left_fragcoord.x > 0.0001 && left_fragcoord.y > 0.0001 && left_fragcoord.x < 0.9999 && left_fragcoord.y < 0.9999;
	left_screen *= (left_check) ? 1.0 : 0.0;
	right_screen = right_screen * (1. - timer) + right_hold * timer * flicker;
	vec2 right_fragcoord = right_coord * InputSize / TextureSize;
	bool right_check = right_fragcoord.x > 0.0001 && right_fragcoord.y > 0.0001 && right_fragcoord.x < 0.9999 && right_fragcoord.y < 0.9999;
	right_screen *= (right_check) ? 1.0 : 0.0;
   FragColor = left_screen + right_screen;
} 
#endif
