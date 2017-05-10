/*
   SimoneT mixed 3D - 2D games Shader v 1.16 WIP

   Copyright (C) 2016 SimoneT - simone1tarditi@gmail.com

   part of the code taken from "Directional Cubic Convolution Interpolation"
   created by Dengwen Zhou and Xiaoliu Shen.

   https://en.wikipedia.org/wiki/Directional_Cubic_Convolution_Interpolation

   de Blur, 4xGLSoft lite - Copyright (C) 2016 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
    
*/

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
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

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
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

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D Pass1Texture;
uniform sampler2D Pass2Texture;
COMPAT_VARYING vec4 TEX0;
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

const   vec2 Size1D    = vec2( 1024, 512 );
const   vec2 InvSize1D = vec2(0.000976562,0.001953125);
const   vec4 Size2D = vec4( 2048.0, 1024.0, 0.00048828125  , 0.0009765625   );
const   vec4 Size3D = vec4( 8192.0, 4096.0, 0.0001220703125, 0.000244140625 );

const   vec3 ones = vec3(1.0,1.0,1.0);

const	vec4 exp = vec4(30.0);	

const	vec4 yx = vec4( 0.000244140625, 0.00048828125,-0.000244140625,-0.00048828125);
const	vec4 xy = vec4( 0.00048828125 , 0.0009765625 ,-0.00048828125 ,-0.0009765625 );

const   vec2 dx  = vec2( 0.00048828125, 0.0         );
const   vec2 dy  = vec2( 0.0          , 0.0009765625);
const   vec2 g1  = vec2( 0.00048828125, 0.0009765625);
const   vec2 g2  = vec2(-0.00048828125, 0.0009765625);
 
float detect3d(sampler2D tex, vec2 texCoords ){

	vec2 pos = (floor(texCoords*Size2D.xy)+0.5)*Size2D.zw;

	vec2 swirl = step(0.5,fract((texCoords*Size2D.xy)*0.5));

	vec2 shift = mix(Size2D.zw,-Size2D.zw,swirl);

	vec3 a = COMPAT_TEXTURE(tex, pos                        ).rgb;
	vec3 b = COMPAT_TEXTURE(tex, pos + vec2( shift.x, 0.0 ) ).rgb;
	vec3 c = COMPAT_TEXTURE(tex, pos + vec2( 0.0, shift.y ) ).rgb;
	vec3 d = COMPAT_TEXTURE(tex, pos + shift                ).rgb; 

	float e = (min(1.0,distance(a,b)+distance(b,c)+distance(c,d)))*255.0; 

	return e;
}

void main()
{
	float e0  = detect3d( Source, vTexCoord.xy );
	float e1  = detect3d( Source, vTexCoord.xy+vec2(InvSize1D.x,0.0));
	float e2  = detect3d( Source, vTexCoord.xy+vec2(0.0,InvSize1D.y));
	float e3  = detect3d( Source, vTexCoord.xy+InvSize1D );

	float e = min(1.0,e0+e1+e2+e3);

	vec3 c11 = ( e < 1.0 ) ? (texture(Pass1Texture, vTexCoord).rgb): 
				 (texture(Source, vTexCoord).rgb);
    FragColor = vec4(c11, 1.0);
} 
#endif
