#version 120
// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter RETRO_PIXEL_SIZE "Retro Pixel Size" 0.84 0.0 1.0 0.01
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float RETRO_PIXEL_SIZE;
#else
#define RETRO_PIXEL_SIZE 0.84
#endif

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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = VertexCoord.xy;
// Paste vertex contents here:
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
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// delete all 'params.' or 'registers.' or whatever in the fragment
float iGlobalTime = float(FrameCount)*0.025;
vec2 iResolution = OutputSize.xy;

// Atari ST Union Demo old skool intro recreated using ShaderToy fragment shader
// Created by Simon Morris (ZippyCoder)
// License: Creative Commons CC0 1.0 Universal (CC-0) 
//  
// Inspired by other ShaderToy work:
// Gerard Geer - https://www.shadertoy.com/view/4dtGD2
// P_Malin - https://www.shadertoy.com/view/4sBSWW
// Uses Gerard Geer's neat bit extraction approach with no division
//
// SoundCloud audioclip of Jochen Hippel's awesmome "Ikari Union" chiptune recorded by RockABit 
// https://soundcloud.com/rockabit/jochen-hippel-ikari-union?in=rockabit/sets/union-demo-jochen-hippel
//
// Original demo - https://www.youtube.com/watch?v=l2i859S_4no
//
// ---------------------------------------------------------------------------------------
// My first shadertoy project, so probably not as optimized as it could be. 
//
// The bitmaps were encoded into shader functions from source GIF/PNG images using 
// a python scipt I threw together - https://github.com/simondotm/shadertoys
// The logo is 4-bits per pixel, the background is 2-bit and the text is 1-bit
// all packed into vec4's so there's less if checks when decoding.
// I was originally going to render/animate each text letter individually 
// but in the end I just took a shortcut and rendered the whole text as one image.
// I also tried unpacking the bitmaps to a separate buffer first, thinking that texture lookup
// might be faster than computing each pixel from encoded floats, but it actually seemed slower.
// ----------------------------------------------------------------------------------------



void drawSpriteUnionDemoLogo( inout vec4 color, in float x, in float y )
{
	
	vec4 tile = vec4(0.0);
	
	// unpack the bitmap on a row-by-row basis
	if (y == 0.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0xaeeeee, 0xeeea03, 0xeeeeee, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 1.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0x3eeeee, 0xeec09c, 0xeeeeee, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 2.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0xc3eeee, 0xec3966, 0xeeeeee, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 3.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0x9a3eee, 0xc3ae66, 0xeeeeee, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 4.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0xe9a0ee, 0x3a6e66, 0xeeeeec, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 5.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0xee6a3e, 0xae6e66, 0xeeeee3, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 6.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee) : ( x < 48.0 ) ? vec4(0xe6e9a0, 0xee6e66, 0xeeeeaa, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 7.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee, 0xeeeeee, 0xeeeeee, 0x0eeeee) : ( x < 48.0 ) ? vec4(0xe66e9a, 0x6e6e64, 0xeeea3e, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 8.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee, 0xeeeeee, 0xeeeeee, 0xa0eeee) : ( x < 48.0 ) ? vec4(0xe66ee9, 0xee6eee, 0xeea066, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 9.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee, 0xeeeeee, 0xeeeeee, 0x9a3eee) : ( x < 48.0 ) ? vec4(0xe66e4e, 0x4e6e64, 0xea0666, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 10.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee, 0xeeeeee, 0xeeeeee, 0x99a3ee) : ( x < 48.0 ) ? vec4(0xe46e64, 0xee6e44, 0xa06eee, 0xeeeeee) : vec4(0xeeeeee, 0xeeeeee, 0x00eeee, 0x000000);
	if (y == 11.0) tile = ( x < 24.0 ) ? vec4(0x58eeee, 0xeeee82, 0x8258ee, 0x499a3e) : ( x < 48.0 ) ? vec4(0x666646, 0x646666, 0x066666, 0x55eeea) : vec4(0xeeeee5, 0xec88ee, 0x00eeee, 0x000000);
	if (y == 12.0) tile = ( x < 24.0 ) ? vec4(0x22eeee, 0xeeee88, 0x8122ee, 0x469ca3) : ( x < 48.0 ) ? vec4(0x664644, 0x666466, 0x946666, 0x22eea3) : vec4(0xeeee81, 0xe125ee, 0x00eeee, 0x000000);
	if (y == 13.0) tile = ( x < 24.0 ) ? vec4(0x22eeee, 0xeeee88, 0x8112ee, 0x4669ca) : ( x < 48.0 ) ? vec4(0x666646, 0x666666, 0x466666, 0x15ea39) : vec4(0xeee812, 0xe211ee, 0x00eeee, 0x000000);
	if (y == 14.0) tile = ( x < 24.0 ) ? vec4(0x22eeee, 0xeeee88, 0x8212ee, 0x44822c) : ( x < 48.0 ) ? vec4(0x465266, 0x266621, 0x021122, 0x25c352) : vec4(0xee8201, 0xe025ee, 0x00eeee, 0x000000);
	if (y == 15.0) tile = ( x < 24.0 ) ? vec4(0x22eeee, 0xeeee88, 0x8221ee, 0x652129) : ( x < 48.0 ) ? vec4(0x642246, 0x256611, 0x221022, 0x020612) : vec4(0xe12212, 0xe012ee, 0x00eeee, 0x000000);
	if (y == 16.0) tile = ( x < 24.0 ) ? vec4(0x21eeee, 0xeeee88, 0x8222ee, 0x802214) : ( x < 48.0 ) ? vec4(0x642244, 0x256601, 0x566662, 0x256420) : vec4(0x820221, 0xe215ee, 0x00eeee, 0x000000);
	if (y == 17.0) tile = ( x < 24.0 ) ? vec4(0x22d7ee, 0xbbbd88, 0x8022bb, 0x22122d) : ( x < 48.0 ) ? vec4(0xdd22b8, 0x25dd21, 0x5bbbd2, 0x05dd20) : vec4(0x2120d2, 0xe225e8, 0x00eedd, 0x000000);
	if (y == 18.0) tile = ( x < 24.0 ) ? vec4(0x22ddde, 0xdddd88, 0x8222b7, 0x22d12b) : ( x < 48.0 ) ? vec4(0xbd2251, 0x25bd21, 0x5bbbb2, 0x22bd12) : vec4(0x121bd2, 0xd12282, 0x00eddd, 0x000000);
	if (y == 19.0) tile = ( x < 24.0 ) ? vec4(0x77dddd, 0x7dddbb, 0xb777db, 0x7bb77b) : ( x < 48.0 ) ? vec4(0xbb7777, 0x77bb77, 0xbbbbb7, 0x7bbb77) : vec4(0x7bbbd7, 0xd77b77, 0x00dddd, 0x000000);
	if (y == 20.0) tile = ( x < 24.0 ) ? vec4(0xbbbddd, 0xddeedd, 0xddbbbd, 0xdddbbd) : ( x < 48.0 ) ? vec4(0xddbbbb, 0xbdddbb, 0xdddddb, 0xbddbbd) : vec4(0xddddbb, 0xbbbbbb, 0x00dbbb, 0x000000);
	if (y == 21.0) tile = ( x < 24.0 ) ? vec4(0x22eeee, 0x828582, 0x821288, 0x646226) : ( x < 48.0 ) ? vec4(0x662226, 0x266621, 0x122211, 0x256662) : vec4(0xec3a62, 0xe02221, 0x00eeee, 0x000000);
	if (y == 22.0) tile = ( x < 24.0 ) ? vec4(0x25eeee, 0x222021, 0x822022, 0x646666) : ( x < 48.0 ) ? vec4(0x666666, 0x664666, 0x464466, 0x226666) : vec4(0xe3a642, 0xe2012e, 0x00eeee, 0x000000);
	if (y == 23.0) tile = ( x < 24.0 ) ? vec4(0x1eeeee, 0x222122, 0x822212, 0x666666) : ( x < 48.0 ) ? vec4(0x666669, 0x646666, 0x464449, 0x254966) : vec4(0xaa6661, 0xe222ee, 0x00eeee, 0x000000);
	if (y == 24.0) tile = ( x < 24.0 ) ? vec4(0xdeeeee, 0x222118, 0x422211, 0x666666) : ( x < 48.0 ) ? vec4(0x666669, 0x966666, 0x666644, 0x664466) : vec4(0x066664, 0xe12eea, 0x00eeee, 0x000000);
	if (y == 25.0) tile = ( x < 24.0 ) ? vec4(0xeeeeee, 0x4669a0, 0x646664, 0x666666) : ( x < 48.0 ) ? vec4(0x666666, 0x666666, 0x666666, 0x466666) : vec4(0x6666c6, 0xeeeea0, 0x00eeee, 0x000000);
	if (y == 26.0) tile = ( x < 24.0 ) ? vec4(0x0eeeee, 0x44496a, 0x6cc466, 0xcc66cc) : ( x < 48.0 ) ? vec4(0xcc6c66, 0x9c6c6c, 0xcc6c4c, 0x6c6c6c) : vec4(0x6666c6, 0xeeea06, 0x00eeee, 0x000000);
	if (y == 27.0) tile = ( x < 24.0 ) ? vec4(0xa0eeee, 0x644666, 0x666c64, 0x6c66cc) : ( x < 48.0 ) ? vec4(0xc4c6c6, 0x6c6c66, 0xc66c6c, 0x6cc446) : vec4(0x646666, 0xeea066, 0x00eeee, 0x000000);
	if (y == 28.0) tile = ( x < 24.0 ) ? vec4(0x630eee, 0x444446, 0x6cc466, 0xcc6c4c) : ( x < 48.0 ) ? vec4(0xc6c6c9, 0xc96c66, 0xc66c66, 0x66cc64) : vec4(0x4666c6, 0xea0646, 0x00eeee, 0x000000);
	if (y == 29.0) tile = ( x < 24.0 ) ? vec4(0x6c3aee, 0x666444, 0x466646, 0x466644) : ( x < 48.0 ) ? vec4(0x646466, 0x666444, 0x464666, 0x666666) : vec4(0x646466, 0xa09464, 0x00eeee, 0x000000);
	if (y == 30.0) tile = ( x < 24.0 ) ? vec4(0x0000ee, 0x000000, 0x000000, 0x000000) : ( x < 48.0 ) ? vec4(0x000000) : vec4(0x000000, 0x300000, 0x00eeec, 0x000000);
	if (y == 31.0) tile = ( x < 24.0 ) ? vec4(0xccccee, 0xcccccc, 0xcccccc, 0xcccccc) : ( x < 48.0 ) ? vec4(0xcccccc) : vec4(0xcccccc, 0xcccccc, 0x00eeee, 0x000000);
	
	float n = mod(x, 24.0); // quantize x coordinate to nearest 24 pixels and get float containing 6 pixels
	float t = ( ( n < 6.0 ) ? tile.x : ( n < 12.0 ) ? tile.y : (n < 18.0 ) ? tile.z : tile.w );
	float p = mod( x, 6.0 ) * 4.0; // quantize x coordinate to nearest 6 pixels to determine pixel bit index
    int idx = int( mod( floor( t*exp2(-p) ), 16.0 ));
    
	// look up colour palette for the indexed pixel
	if (idx == 0) color = vec4(0.913725, 0.913725, 0.913725, 1.0);
	if (idx == 1) color = vec4(0.913725, 0.913725, 0.309804, 1.0);
	if (idx == 2) color = vec4(0.913725, 0.670588, 0.309804, 1.0);
	if (idx == 3) color = vec4(0.670588, 0.670588, 0.670588, 1.0);
	if (idx == 4) color = vec4(0.670588, 0.670588, 0.431373, 1.0);
	if (idx == 5) color = vec4(0.913725, 0.552941, 0.670588, 1.0);
	if (idx == 6) color = vec4(0.552941, 0.552941, 0.309804, 1.0);
	if (idx == 7) color = vec4(0.431373, 0.552941, 0.913725, 1.0);
	if (idx == 8) color = vec4(0.792157, 0.431373, 0.309804, 1.0);
	if (idx == 9) color = vec4(0.552941, 0.431373, 0.309804, 1.0);
	if (idx == 10) color = vec4(0.431373, 0.431373, 0.431373, 1.0);
	if (idx == 11) color = vec4(0.309804, 0.431373, 0.913725, 1.0);
	if (idx == 12) color = vec4(0.309804, 0.309804, 0.309804, 1.0);
	if (idx == 13) color = vec4(0.188235, 0.188235, 0.792157, 1.0);
	if (idx == 14) color = vec4(0.070588, 0.070588, 0.070588, 0.0);
	if (idx == 15) color = vec4(0.000000, 0.000000, 0.000000, 0.0);
}


void drawSpriteUnionBackground( inout vec4 color, float x, float y )
{
	
	vec4 tile = vec4(0.0);
	
	// unpack the bitmap on a row-by-row basis
	if (y == 0.0) tile = vec4(0xe46e6e, 0x1ba41a, 0xfbae6e, 0xffffff);
	if (y == 1.0) tile = vec4(0xffffff);
	if (y == 2.0) tile = vec4(0xffffff, 0xffffff, 0xbbffff, 0xbb6e6e);
	if (y == 3.0) tile = vec4(0x9bbfbf, 0xfefffb, 0xfffe6f, 0xffffff);
	if (y == 4.0) tile = vec4(0xbfffff, 0xffeeae, 0xffffff, 0xeb9bae);
	if (y == 5.0) tile = vec4(0xffffff);
	if (y == 6.0) tile = vec4(0xae6e56, 0xbbefbb, 0x6e91b9, 0xbaffae);
	if (y == 7.0) tile = vec4(0xffffff);
	if (y == 8.0) tile = vec4(0xffffff, 0xffffff, 0xb9baff, 0xffbb95);
	if (y == 9.0) tile = vec4(0x1b9bef, 0x9b96e9, 0xffffeb, 0xffffff);
	if (y == 10.0) tile = vec4(0xffffff, 0xffffff, 0xbaeeff, 0xeb9b91);
	if (y == 11.0) tile = vec4(0xfffeeb, 0xffffff, 0xffffff, 0xbfffff);
	if (y == 12.0) tile = vec4(0xffffff);
	if (y == 13.0) tile = vec4(0x1b9b9f, 0xe79b99, 0xffffbe, 0xafbeff);
	if (y == 14.0) tile = vec4(0xffffff, 0xffffff, 0x9bafff, 0xfffffb);
	if (y == 15.0) tile = vec4(0xebabaf, 0xfffffe, 0xfffeeb, 0xbfffff);
	if (y == 16.0) tile = vec4(0xffffff, 0xbaffff, 0xffffff, 0xffffff);
	if (y == 17.0) tile = vec4(0xeffbeb, 0xfffaea, 0x7efbff, 0xeb6d2e);
	if (y == 18.0) tile = vec4(0xffffff, 0xffffff, 0xfffffb, 0xffffff);
	if (y == 19.0) tile = vec4(0xffffff, 0xffffff, 0xffffff, 0xbfffff);
	if (y == 20.0) tile = vec4(0xb9baef, 0xa41ae4, 0xb9b91b, 0xfeffbf);
	if (y == 21.0) tile = vec4(0xffffff);
	if (y == 22.0) tile = vec4(0xffffff);
	if (y == 23.0) tile = vec4(0xbae6e1, 0xfffeff, 0xbeffff, 0xb9baed);
	if (y == 24.0) tile = vec4(0xffffff, 0xafbfff, 0xffefab, 0xffffff);
	if (y == 25.0) tile = vec4(0xffefff, 0xffffff, 0xffffff, 0xbfffff);
	if (y == 26.0) tile = vec4(0xffffff, 0x92ebef, 0x92e41b, 0xffeb9b);
	if (y == 27.0) tile = vec4(0xffffff);
	if (y == 28.0) tile = vec4(0xbae46e, 0xeffffb, 0xffffef, 0x6ebfff);
	if (y == 29.0) tile = vec4(0xffffff);
	if (y == 30.0) tile = vec4(0xfffffe, 0x7afafb, 0xef6e1e, 0xffeffb);
	if (y == 31.0) tile = vec4(0xfbffff, 0xffffff, 0xffffff, 0xffffff);
	if (y == 32.0) tile = vec4(0xffffff, 0xffffff, 0x6effff, 0xffffae);
	if (y == 33.0) tile = vec4(0x9b96e9, 0xefffeb, 0xffefff, 0x1b9bef);
	if (y == 34.0) tile = vec4(0xffffff);
	if (y == 35.0) tile = vec4(0xfeffef, 0x86e6eb, 0x86e41b, 0xfffbeb);
	if (y == 36.0) tile = vec4(0xffffff);
	if (y == 37.0) tile = vec4(0xbae6e4, 0xfffbe7, 0xffbfff, 0xb9baef);
	if (y == 38.0) tile = vec4(0xffffff, 0xffffff, 0xfffffe, 0xffffff);
	if (y == 39.0) tile = vec4(0xffffff);
	if (y == 40.0) tile = vec4(0x1b9bae, 0x9416b9, 0xe6e46e, 0xffffba);
	if (y == 41.0) tile = vec4(0xffffff, 0xffffff, 0xffffff, 0xffbfff);
	if (y == 42.0) tile = vec4(0xbabaef, 0xefffee, 0xe6e4ba, 0xafffba);
	if (y == 43.0) tile = vec4(0xffffff);
	if (y == 44.0) tile = vec4(0xeeb9b9, 0xffffff, 0xbebfbf, 0x1b92f9);
	if (y == 45.0) tile = vec4(0xffffff, 0xb9e6eb, 0xffffff, 0xffffff);
	if (y == 46.0) tile = vec4(0xfffffe, 0xffffff, 0xaeffff, 0xebfabf);
	if (y == 47.0) tile = vec4(0xffffff, 0xffffff, 0xffffff, 0xffbffb);
	
	float n = mod(x, 48.0); // quantize x coordinate to nearest 48 pixels and get float containing 12 pixels
	float t = ( ( n < 12.0 ) ? tile.x : ( n < 24.0 ) ? tile.y : (n < 36.0 ) ? tile.z : tile.w );
	float p = mod( x, 12.0 ) * 2.0; // quantize x coordinate to nearest 12 pixels to determine pixel bit index
    int idx = int( mod( floor( t*exp2(-p) ), 4.0 ));
                  
	// look up colour palette for the indexed pixel
	if (idx == 0) color = vec4(0.431373, 0.552941, 0.913725, 1.0);
	if (idx == 1) color = vec4(0.309804, 0.431373, 0.913725, 1.0);
	if (idx == 2) color = vec4(0.188235, 0.188235, 0.792157, 1.0);
	if (idx == 3) color = vec4(0.070588, 0.070588, 0.070588, 1.0);
}


void drawSpriteUnionLettersWhite( inout vec4 color, float x, float y )
{
	
	vec4 tile = vec4(0.0);
	
	// unpack the bitmap on a row-by-row basis
	if (y == 0.0) tile = ( x < 96.0 ) ? vec4(0xc0c4c0, 0xccffff, 0xc0f3cc, 0xe0ffcc) : vec4(0xc09cc0, 0x0000f3, 0x000000, 0x000000);
	if (y == 1.0) tile = ( x < 96.0 ) ? vec4(0xc4c4f3, 0xccffff, 0xccf3c8, 0xccffc8) : vec4(0xcc88c4, 0x0000f3, 0x000000, 0x000000);
	if (y == 2.0) tile = ( x < 96.0 ) ? vec4(0xfcccf3, 0xccffff, 0xccf3c0, 0xccffc0) : vec4(0xcc80fc, 0x0000f3, 0x000000, 0x000000);
	if (y == 3.0) tile = ( x < 96.0 ) ? vec4(0xc0c0f3, 0xccffff, 0xc8f3c0, 0xccc040) : vec4(0xc894c0, 0x0000f3, 0x000000, 0x000000);
	if (y == 4.0) tile = ( x < 96.0 ) ? vec4(0xfcccf1, 0xc4ffff, 0xc8f1cc, 0xc8c04c) : vec4(0xc89cfc, 0x0000f3, 0x000000, 0x000000);
	if (y == 5.0) tile = ( x < 96.0 ) ? vec4(0xc4c8f1, 0xc4ffff, 0xc8f1c8, 0xc8ffc8) : vec4(0xc88cc4, 0x0000ff, 0x000000, 0x000000);
	if (y == 6.0) tile = ( x < 96.0 ) ? vec4(0xc0c8f1, 0xc0ffff, 0xc0f1c8, 0xc0ffc8) : vec4(0xc08cc0, 0x0000f3, 0x000000, 0x000000);
	if (y == 7.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 8.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 9.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 10.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 11.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 12.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 13.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 14.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 15.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 16.0) tile = ( x < 96.0 ) ? vec4(0xc0ffff, 0xc09cc0, 0xf3c4ff, 0xc0c0cc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 17.0) tile = ( x < 96.0 ) ? vec4(0xc4ffff, 0xc488cc, 0xf3c4ff, 0xc4f3c8) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 18.0) tile = ( x < 96.0 ) ? vec4(0xfcffff, 0xfc80cc, 0xf3ccff, 0xfcf3c0) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 19.0) tile = ( x < 96.0 ) ? vec4(0xe1ffff, 0xc094c8, 0xf3c0ff, 0xe1f3c0) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 20.0) tile = ( x < 96.0 ) ? vec4(0xcfffff, 0xfc9cc8, 0xf1ccff, 0xcff1cc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 21.0) tile = ( x < 96.0 ) ? vec4(0xccffff, 0xc48cc8, 0xf1c8ff, 0xccf1c8) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 22.0) tile = ( x < 96.0 ) ? vec4(0xc0ffff, 0xc08cc0, 0xf1c8ff, 0xc0f1c8) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 23.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 24.0) tile = ( x < 96.0 ) ? vec4(0xfffff3, 0xc0ccff, 0xc0ffc0, 0xccf8cc) : vec4(0xc4c0ff, 0x0000c0, 0x000000, 0x000000);
	if (y == 25.0) tile = ( x < 96.0 ) ? vec4(0xfffff1, 0xc4ccff, 0xccffc4, 0xccf8c8) : vec4(0xc4f3ff, 0x0000c4, 0x000000, 0x000000);
	if (y == 26.0) tile = ( x < 96.0 ) ? vec4(0xfffff0, 0xfcccff, 0xccfffc, 0xccf8c0) : vec4(0xccf3ff, 0x0000fc, 0x000000, 0x000000);
	if (y == 27.0) tile = ( x < 96.0 ) ? vec4(0xfffff3, 0xe1ccff, 0xc8ffc0, 0xc0f9c0) : vec4(0xc0f3ff, 0x0000c0, 0x000000, 0x000000);
	if (y == 28.0) tile = ( x < 96.0 ) ? vec4(0xfffff3, 0xcfc4ff, 0xc8fffc, 0xf3f9cc) : vec4(0xccf1ff, 0x0000fc, 0x000000, 0x000000);
	if (y == 29.0) tile = ( x < 96.0 ) ? vec4(0xfff3f3, 0xccc4ff, 0xc8ffc4, 0xe3c9c8) : vec4(0xc8f1ff, 0x0000c4, 0x000000, 0x000000);
	if (y == 30.0) tile = ( x < 96.0 ) ? vec4(0xfff3c0, 0xc0c0ff, 0xc0ffc0, 0xe3c1c8) : vec4(0xc8f1ff, 0x0000c0, 0x000000, 0x000000);
	if (y == 31.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 32.0) tile = ( x < 96.0 ) ? vec4(0xf3cce0, 0xffe0f8, 0xffccf3, 0xc0c0c0) : vec4(0xc0ffcc, 0x0000c0, 0x000000, 0x000000);
	if (y == 33.0) tile = ( x < 96.0 ) ? vec4(0xf3cce4, 0xffccf8, 0xffc8f3, 0xcccccc) : vec4(0xf3ffcc, 0x0000cc, 0x000000, 0x000000);
	if (y == 34.0) tile = ( x < 96.0 ) ? vec4(0xf3cce4, 0xffccf8, 0xffc0f3, 0xccccfc) : vec4(0xf3ffcc, 0x0000cc, 0x000000, 0x000000);
	if (y == 35.0) tile = ( x < 96.0 ) ? vec4(0xf3ccc0, 0xc04cf9, 0xffc0f3, 0xc0c8f8) : vec4(0xf3ffc0, 0x0000c8, 0x000000, 0x000000);
	if (y == 36.0) tile = ( x < 96.0 ) ? vec4(0xf1c4cc, 0xc048f9, 0xffccf1, 0xfcc8f8) : vec4(0xf1fff3, 0x0000c8, 0x000000, 0x000000);
	if (y == 37.0) tile = ( x < 96.0 ) ? vec4(0xf1c4cc, 0xffc8c9, 0xffc8f1, 0xf8c8c8) : vec4(0xf1ffe3, 0x0000c8, 0x000000, 0x000000);
	if (y == 38.0) tile = ( x < 96.0 ) ? vec4(0xf1c0c0, 0xffc0c1, 0xffc8f1, 0xf8c0c0) : vec4(0xf1ffe3, 0x0000c0, 0x000000, 0x000000);
	if (y == 39.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 40.0) tile = ( x < 96.0 ) ? vec4(0xc0cce0, 0xc0f3f8, 0xc0c0e1, 0xc0f3ff) : vec4(0xc0ccff, 0x0000c0, 0x000000, 0x000000);
	if (y == 41.0) tile = ( x < 96.0 ) ? vec4(0xcccccc, 0xccf3f8, 0xc4f3ed, 0xf3f3ff) : vec4(0xc4ccff, 0x0000c4, 0x000000, 0x000000);
	if (y == 42.0) tile = ( x < 96.0 ) ? vec4(0xcccccc, 0xfcf3f8, 0xfcf3ed, 0xf3f3ff) : vec4(0xfcccff, 0x0000fc, 0x000000, 0x000000);
	if (y == 43.0) tile = ( x < 96.0 ) ? vec4(0xc0cccc, 0xf8f3f9, 0xc0f3c0, 0xf3f3ff) : vec4(0xe1ccff, 0x0000c0, 0x000000, 0x000000);
	if (y == 44.0) tile = ( x < 96.0 ) ? vec4(0xfcc4c8, 0xf8f1f9, 0xfcf1cc, 0xf1f1ff) : vec4(0xcfc4ff, 0x0000fc, 0x000000, 0x000000);
	if (y == 45.0) tile = ( x < 96.0 ) ? vec4(0xf8c4c8, 0xc8f1c9, 0xc4f1c4, 0xf1f1ff) : vec4(0xccc4f3, 0x0000c4, 0x000000, 0x000000);
	if (y == 46.0) tile = ( x < 96.0 ) ? vec4(0xf8c0c0, 0xc0f1c1, 0xc0f1c4, 0xf1f1ff) : vec4(0xc0c0f3, 0x0000c0, 0x000000, 0x000000);
	if (y == 47.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 48.0) tile = ( x < 96.0 ) ? vec4(0x9cfff3, 0xffc0c0, 0xf3c0e0, 0xc0c0c4) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 49.0) tile = ( x < 96.0 ) ? vec4(0x88fff1, 0xffccc4, 0xf3cccc, 0xc4c4c4) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 50.0) tile = ( x < 96.0 ) ? vec4(0x80fff0, 0xfffcfc, 0xf3cccc, 0xfcfcc4) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 51.0) tile = ( x < 96.0 ) ? vec4(0x94fff3, 0xffc4c0, 0xf3c0cc, 0xe1c0cc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 52.0) tile = ( x < 96.0 ) ? vec4(0x9cfff3, 0xffc4fc, 0xf1e4c8, 0xcffccc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 53.0) tile = ( x < 96.0 ) ? vec4(0x8cfff3, 0xffccc4, 0xf1c4c8, 0xccc4e1) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 54.0) tile = ( x < 96.0 ) ? vec4(0x8cffc0, 0xffc0c0, 0xf1c4c0, 0xc0c0f3) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 55.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 56.0) tile = ( x < 96.0 ) ? vec4(0xc0c4c0, 0xc0e0ff, 0xffc09c, 0xc0c0f3) : vec4(0xc0f8c0, 0x0000ff, 0x000000, 0x000000);
	if (y == 57.0) tile = ( x < 96.0 ) ? vec4(0xc4c4f3, 0xc4ccff, 0xffcc88, 0xc4f3f3) : vec4(0xc4f8c4, 0x0000ff, 0x000000, 0x000000);
	if (y == 58.0) tile = ( x < 96.0 ) ? vec4(0xfcccf3, 0xfcccff, 0xffcc80, 0xfcf3f3) : vec4(0xfcf8fc, 0x0000ff, 0x000000, 0x000000);
	if (y == 59.0) tile = ( x < 96.0 ) ? vec4(0xc0c0f3, 0xc0ccff, 0xffc894, 0xe1f3f3) : vec4(0xf0f9c0, 0x0000ff, 0x000000, 0x000000);
	if (y == 60.0) tile = ( x < 96.0 ) ? vec4(0xfcccf1, 0xfcc8ff, 0xffc89c, 0xcff1f1) : vec4(0xfcf9fc, 0x0000ff, 0x000000, 0x000000);
	if (y == 61.0) tile = ( x < 96.0 ) ? vec4(0xc4c8f1, 0xc4c8ff, 0xffc88c, 0xccf1f1) : vec4(0xfcc9c4, 0x0000ff, 0x000000, 0x000000);
	if (y == 62.0) tile = ( x < 96.0 ) ? vec4(0xc0c8f1, 0xc0c0ff, 0xffc08c, 0xc0f1f1) : vec4(0xfcc1c0, 0x0000ff, 0x000000, 0x000000);
	if (y == 63.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 64.0) tile = ( x < 96.0 ) ? vec4(0xccccc0, 0xc0ffc0, 0xf3ffcc, 0xffc1ff) : vec4(0xc0c09c, 0x0000ff, 0x000000, 0x000000);
	if (y == 65.0) tile = ( x < 96.0 ) ? vec4(0xc8cccc, 0xccffc4, 0xf1ffc8, 0xff9c9f) : vec4(0xccc488, 0x0000ff, 0x000000, 0x000000);
	if (y == 66.0) tile = ( x < 96.0 ) ? vec4(0xc0cccc, 0xccfffc, 0xf0ffc0, 0xff9fcf) : vec4(0xfcfc80, 0x0000ff, 0x000000, 0x000000);
	if (y == 67.0) tile = ( x < 96.0 ) ? vec4(0xc0ccc0, 0xc8ffe1, 0xf3ffc0, 0xffc1e7) : vec4(0xc4c094, 0x0000ff, 0x000000, 0x000000);
	if (y == 68.0) tile = ( x < 96.0 ) ? vec4(0xccc4e4, 0xc8ffcf, 0xf3ffcc, 0xfffcf3) : vec4(0xc4fc9c, 0x0000ff, 0x000000, 0x000000);
	if (y == 69.0) tile = ( x < 96.0 ) ? vec4(0xc8c4c4, 0xc8ffcc, 0xf3ffc8, 0xfffcf9) : vec4(0xccc48c, 0x0000ff, 0x000000, 0x000000);
	if (y == 70.0) tile = ( x < 96.0 ) ? vec4(0xc8c0c4, 0xc0ffc0, 0xc0ffc8, 0xff80fc) : vec4(0xc0c08c, 0x0000ff, 0x000000, 0x000000);
	if (y == 71.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 72.0) tile = ( x < 96.0 ) ? vec4(0xcfc0c0, 0xe1ffc0, 0xffe0cc, 0xf3c0e0) : vec4(0xc0c0c4, 0x0000ff, 0x000000, 0x000000);
	if (y == 73.0) tile = ( x < 96.0 ) ? vec4(0xe7f3c4, 0xedffc4, 0xffccc8, 0xf3cccc) : vec4(0xc4c4c4, 0x0000ff, 0x000000, 0x000000);
	if (y == 74.0) tile = ( x < 96.0 ) ? vec4(0xf3f3fc, 0xedfffc, 0xffccc0, 0xf3cccc) : vec4(0xfcfcc4, 0x0000ff, 0x000000, 0x000000);
	if (y == 75.0) tile = ( x < 96.0 ) ? vec4(0xfff3e1, 0xc0ffe1, 0xffccc0, 0xf3c0cc) : vec4(0xe1c0cc, 0x0000ff, 0x000000, 0x000000);
	if (y == 76.0) tile = ( x < 96.0 ) ? vec4(0xfff1cf, 0xccffcf, 0xffc8cc, 0xf1e4c8) : vec4(0xcffccc, 0x0000ff, 0x000000, 0x000000);
	if (y == 77.0) tile = ( x < 96.0 ) ? vec4(0xfff1cc, 0xc4ffcc, 0xffc8c8, 0xf1c4c8) : vec4(0xccc4e1, 0x0000f3, 0x000000, 0x000000);
	if (y == 78.0) tile = ( x < 96.0 ) ? vec4(0xfff1c0, 0xc4ffc0, 0xffc0c8, 0xf1c4c0) : vec4(0xc0c0f3, 0x0000f3, 0x000000, 0x000000);
	if (y == 79.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 80.0) tile = ( x < 96.0 ) ? vec4(0xc0ffc1, 0xc0c7cc, 0xc0ffcc, 0xffc0c4) : vec4(0xc0c0e0, 0x0000c0, 0x000000, 0x000000);
	if (y == 81.0) tile = ( x < 96.0 ) ? vec4(0xc4ff9c, 0xccc7c8, 0xf3ffcc, 0xffc4c4) : vec4(0xc4c4e4, 0x0000f3, 0x000000, 0x000000);
	if (y == 82.0) tile = ( x < 96.0 ) ? vec4(0xfcff9f, 0xccc7c0, 0xf3ffcc, 0xfffccc) : vec4(0xfcfce4, 0x0000f3, 0x000000, 0x000000);
	if (y == 83.0) tile = ( x < 96.0 ) ? vec4(0xc0ffc1, 0xc8e7c0, 0xf3ffc0, 0xffc0c0) : vec4(0xe1c0c0, 0x0000f3, 0x000000, 0x000000);
	if (y == 84.0) tile = ( x < 96.0 ) ? vec4(0xfcfffc, 0xc8e7cc, 0xf1fff3, 0xfffccc) : vec4(0xcffccc, 0x0000f1, 0x000000, 0x000000);
	if (y == 85.0) tile = ( x < 96.0 ) ? vec4(0xc4f3fc, 0xc8e4c8, 0xf1ffe3, 0xffc4c8) : vec4(0xccc4cc, 0x0000f1, 0x000000, 0x000000);
	if (y == 86.0) tile = ( x < 96.0 ) ? vec4(0xc0f380, 0xc0e0c8, 0xf1ffe3, 0xffc0c8) : vec4(0xc0c0c0, 0x0000f1, 0x000000, 0x000000);
	if (y == 87.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 88.0) tile = ( x < 96.0 ) ? vec4(0xffc0c0, 0x9cc0e0, 0xc0ffc0, 0x9cc0c0) : vec4(0xc4c0ff, 0x0000c0, 0x000000, 0x000000);
	if (y == 89.0) tile = ( x < 96.0 ) ? vec4(0xfff3c4, 0x88c4cc, 0xc4ffcc, 0x88cccc) : vec4(0xc4f3ff, 0x0000c4, 0x000000, 0x000000);
	if (y == 90.0) tile = ( x < 96.0 ) ? vec4(0xfff3fc, 0x80fccc, 0xfcffcc, 0x80cccc) : vec4(0xccf3ff, 0x0000fc, 0x000000, 0x000000);
	if (y == 91.0) tile = ( x < 96.0 ) ? vec4(0xc073e1, 0x94c0cc, 0xf0ffc8, 0x94c8c0) : vec4(0xc0f3ff, 0x0000c0, 0x000000, 0x000000);
	if (y == 92.0) tile = ( x < 96.0 ) ? vec4(0xc071cf, 0x9cfcc8, 0xfcffc8, 0x9cc8e4) : vec4(0xccf1ff, 0x0000fc, 0x000000, 0x000000);
	if (y == 93.0) tile = ( x < 96.0 ) ? vec4(0xfff1cc, 0x8cc4c8, 0xfcffc8, 0x8cc8c4) : vec4(0xc8f1ff, 0x0000c4, 0x000000, 0x000000);
	if (y == 94.0) tile = ( x < 96.0 ) ? vec4(0xfff1c0, 0x8cc0c0, 0xfcffc0, 0x8cc0c4) : vec4(0xc8f1ff, 0x0000c0, 0x000000, 0x000000);
	if (y == 95.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 96.0) tile = ( x < 96.0 ) ? vec4(0xc0c0e0, 0xc0ffc0, 0xc0ffc0, 0xc0cccc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 97.0) tile = ( x < 96.0 ) ? vec4(0xc4c4e4, 0xc4fff3, 0xccfff3, 0xc4cccc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 98.0) tile = ( x < 96.0 ) ? vec4(0xfcfce4, 0xfcfff3, 0xfcfff3, 0xfccccc) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 99.0) tile = ( x < 96.0 ) ? vec4(0xe1c0c0, 0xe1fff3, 0xc4c073, 0xe1c0cc) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 100.0) tile = ( x < 96.0 ) ? vec4(0xcffccc, 0xcffff1, 0xc4c071, 0xcff3c4) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 101.0) tile = ( x < 96.0 ) ? vec4(0xccc4cc, 0xccfff1, 0xccfff1, 0xcce3c4) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 102.0) tile = ( x < 96.0 ) ? vec4(0xc0c0c0, 0xc0fff1, 0xc0fff1, 0xc0e3c0) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 103.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 104.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xc0c4c0, 0xccccff, 0xccc0f3) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 105.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xc4c4f3, 0xc8ccff, 0xc8ccf3) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 106.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xfcccf3, 0xc0ccff, 0xc0ccf3) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 107.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xc0c0f3, 0xc0ccff, 0xc0c8f3) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 108.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xfcccf1, 0xccc4ff, 0xccc8f1) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 109.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xc4c8f1, 0xc8c4ff, 0xc8c8f1) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	if (y == 110.0) tile = ( x < 96.0 ) ? vec4(0xffffff, 0xc0c8f1, 0xc8c0ff, 0xc8c0f1) : vec4(0xfffff3, 0x0000ff, 0x000000, 0x000000);
	if (y == 111.0) tile = ( x < 96.0 ) ? vec4(0xffffff) : vec4(0xffffff, 0x0000ff, 0x000000, 0x000000);
	
	float n = mod(x, 96.0); // quantize x coordinate to nearest 96 pixels and get float containing 24 pixels
	float t = ( ( n < 24.0 ) ? tile.x : ( n < 48.0 ) ? tile.y : (n < 72.0 ) ? tile.z : tile.w );
	float p = mod( x, 24.0 ) * 1.0; // quantize x coordinate to nearest 24 pixels to determine pixel bit index
	int idx = int( mod( floor( t*exp2(-p) ), 2.0 ));
    
	// look up colour palette for the indexed pixel
	if (idx == 0) color = vec4(1.000000, 1.000000, 1.000000, 1.0);
	if (idx == 1) color = vec4(0.898039, 0.447059, 0.796078, 0.0);
}




void drawLogo(inout vec4 bg, in float x, in float y, in vec2 pixelCoord)
{
    const float w = 64.0;
    const float h = 32.0;

    // bounds check - no idea how the GPU feels about these checks.
	if ( (pixelCoord.x >= x) && (pixelCoord.y >= y) 
        && (pixelCoord.x < (x + w)) && (pixelCoord.y < (y + h)))
    {
    	vec2 coord;
    	coord.x = (pixelCoord.x - x);
    	coord.y = (pixelCoord.y - y);
        drawSpriteUnionDemoLogo(bg,  coord.x, coord.y);  
    }

}

#define RGBA(r,g,b,a) vec4(float(r)/255.0, float(g)/255.0, float(b)/255.0, float(a)/255.0)

void textGradient(inout vec4 c, in float y)
{   
	const float GRADIENT_SCALE = 112.0/4.0; // 4 zones over the 112 pixel high bitmap
    const vec4 GRADIENT0 = RGBA(224,0,32,255);
    const vec4 GRADIENT1 = RGBA(224,0,224,255);
    const vec4 GRADIENT2 = RGBA(224,224,224,255);
    const vec4 GRADIENT3 = RGBA(224,224,32,255);
    const vec4 GRADIENT4 = RGBA(160,224,0,255);    
    
    // quantize vertical coord into 4 zones
    float n = floor(y / GRADIENT_SCALE);
    
    // compute interpolation amount
    float k = mod(y, GRADIENT_SCALE) / 112.0 * 4.0;
    
    // lerp the gradients across each zone
    if (n == 0.0) c *= mix(GRADIENT0, GRADIENT1, k);
    if (n == 1.0) c *= mix(GRADIENT1, GRADIENT2, k);
    if (n == 2.0) c *= mix(GRADIENT2, GRADIENT3, k);
    if (n == 3.0) c *= mix(GRADIENT3, GRADIENT4, k);    
}

void drawText(inout vec4 bg, in float x, in float y, in vec2 pixelCoord)
{
    float w = 128.0*2.0;	// we double up the horizontal pixels when rendering this one
    float h = 112.0;
    
	if ( (pixelCoord.x >= x) && (pixelCoord.y >= y) 
        && (pixelCoord.x < (x + w)) && (pixelCoord.y < (y + h)))
    {
    	vec2 coord;
    	coord.x = (pixelCoord.x - x);
    	coord.y = (pixelCoord.y - y);
        drawSpriteUnionLettersWhite(bg,  floor(coord.x/2.0), coord.y);  
        // apply colour gradient to white text bitmap
        textGradient(bg, coord.y);
    }
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{ 
	float sx, sy;
    vec4 c2;
    
    // convert screen space to 320x200 bitmap with top left origin
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixelCoord;
    pixelCoord.x = floor(uv.x * 320.0);
    pixelCoord.y = floor((1.0 - uv.y) * 200.0);
    
	// render background as tiled bitmap, with vertical scroll animation    
    vec4 bg = vec4(0.0);
    sx = mod(floor(fragCoord.x / 3.0), 48.0);
    sy = mod(floor(iGlobalTime * 50.0 + fragCoord.y / 3.0), 48.0);
	drawSpriteUnionBackground(bg, sx, sy);   

    // animate the logo horizontally & render it
    sx = floor(sin(iGlobalTime*3.0) * cos(iGlobalTime*2.0) * 280.0*0.3 + 260.0*0.5);
    sy = 4.0;
    c2 = vec4(0.0);
    drawLogo(c2, sx, sy, pixelCoord);
    bg = mix(bg, c2, c2.w);
    
	// animate the text in an old-skool sine wave way and render it
    float ws = iGlobalTime*2.5;
    sx = 32.0 + sin(pixelCoord.y/40.0 + ws)*20.0;
    sy = floor(64.0 + cos(pixelCoord.x/40.0 + ws)*4.0);
    drawText(c2, sx, sy, pixelCoord);
    bg = mix(bg, c2, c2.w);
 
    // final output
    fragColor = bg;
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
