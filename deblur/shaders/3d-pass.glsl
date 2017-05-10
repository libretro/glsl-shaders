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

// Parameter lines go here:
#pragma parameter THREE_D_SCALE "3D Filter Scale" 4.0 1.0 8.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float THREE_D_SCALE;
#else
#define THREE_D_SCALE 4.0
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
uniform sampler2D OrigTexture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

vec2 Size1D    = vec2( SourceSize.x, SourceSize.y );
vec2 InvSize1D = 1.0 / Size1D;//vec2(0.000976562,0.001953125);
vec4 Size3D = vec4(vec2(THREE_D_SCALE * Size1D), vec2(1.0 / (THREE_D_SCALE * Size1D)));//vec4( 8192.0, 4096.0, 0.0001220703125, 0.000244140625 );

const	vec4 exp = vec4(30.0);

vec3 Interpolate3d( vec3 a, vec3 b, vec3 c, vec3 d ) {

	return ( a + b + c + d ) * 0.25;

}

vec3 STAA3D( vec2 coord, vec4 texSize ) {

	vec2 TexCoord = (floor(coord*texSize.xy)+0.5)*texSize.zw;
	vec4 shift  = vec4( texSize.zw,-texSize.zw);
	vec4 shift2 = 2.0*shift;

	vec3 C00 = COMPAT_TEXTURE(OrigTexture, TexCoord - shift2.xy                ).rgb;
	vec3 C01 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift.x , shift2.y)).rgb;
	vec3 C02 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( 0.0     , shift2.y)).rgb;
	vec3 C03 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift.z , shift2.y)).rgb;
	vec3 C04 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift2.z, shift2.y)).rgb;

	vec3 C05 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift2.x, shift.y )).rgb;
	vec3 C06 = COMPAT_TEXTURE(OrigTexture, TexCoord - shift.xy                 ).rgb;
	vec3 C07 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( 0.0     , shift.y )).rgb;
	vec3 C08 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift.z , shift.y )).rgb;
	vec3 C09 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift2.z, shift.y )).rgb;

	vec3 C10 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift2.x, 0.0     )).rgb;
	vec3 C11 = COMPAT_TEXTURE(OrigTexture, TexCoord - vec2( shift.x , 0.0     )).rgb;
	vec3 C12 = COMPAT_TEXTURE(OrigTexture, TexCoord                            ).rgb;
	vec3 C13 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift.x , 0.0     )).rgb;
	vec3 C14 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift2.x, 0.0     )).rgb;

	vec3 C15 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift2.z, shift.y )).rgb;
	vec3 C16 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift.z , shift.y )).rgb;
	vec3 C17 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( 0.0     , shift.y )).rgb;
	vec3 C18 = COMPAT_TEXTURE(OrigTexture, TexCoord + shift.xy                 ).rgb;
	vec3 C19 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift2.x, shift.y )).rgb;

	vec3 C20 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift2.z, shift2.y)).rgb;
	vec3 C21 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift.z , shift2.y)).rgb;
	vec3 C22 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( 0.0     , shift2.y)).rgb;
	vec3 C23 = COMPAT_TEXTURE(OrigTexture, TexCoord + vec2( shift.x , shift2.y)).rgb;
	vec3 C24 = COMPAT_TEXTURE(OrigTexture, TexCoord + shift2.xy                ).rgb;

	float C03C09 = distance(C03,C09);
	float C02C08 = distance(C02,C08);
	float C08C14 = distance(C08,C14);
	float C01C07 = distance(C01,C07);
	float C07C13 = distance(C07,C13);
	float C13C19 = distance(C13,C19);
	float C00C06 = distance(C00,C06);
	float C06C12 = distance(C06,C12);
	float C12C18 = distance(C12,C18);
	float C18C24 = distance(C18,C24);
	float C05C11 = distance(C05,C11);
	float C11C17 = distance(C11,C17);
	float C17C23 = distance(C17,C23);
	float C10C16 = distance(C10,C16);
	float C16C22 = distance(C16,C22);
	float C15C21 = distance(C15,C21);

	vec4 d01 = vec4(
	C02C08 + C01C07 + C07C13 + C00C06 + C06C12 + C12C18 + C05C11 + C11C17 + C10C16,
	C03C09 + C02C08 + C08C14 + C01C07 + C07C13 + C13C19 + C06C12 + C12C18 + C11C17,
	C07C13 + C06C12 + C12C18 + C05C11 + C11C17 + C17C23 + C10C16 + C16C22 + C15C21,
	C08C14 + C07C13 + C13C19 + C06C12 + C12C18 + C18C24 + C11C17 + C17C23 + C16C22);

	d01 = pow(d01,exp)+0.001;

	float C01C05 = distance(C01,C05);
	float C02C06 = distance(C02,C06);
	float C06C10 = distance(C06,C10);
	float C03C07 = distance(C03,C07);
	float C07C11 = distance(C07,C11);
	float C11C15 = distance(C11,C15);
	float C04C08 = distance(C04,C08);
	float C08C12 = distance(C08,C12);
	float C12C16 = distance(C12,C16);
	float C16C20 = distance(C16,C20);
	float C09C13 = distance(C09,C13);
	float C13C17 = distance(C13,C17);
	float C17C21 = distance(C17,C21);
	float C14C18 = distance(C14,C18);
	float C18C22 = distance(C18,C22);
	float C19C23 = distance(C19,C23);

	vec4 d02 = vec4(
	C01C05 + C02C06 + C06C10 + C03C07 + C07C11 + C11C15 + C08C12 + C12C16 + C13C17,
	C02C06 + C03C07 + C07C11 + C04C08 + C08C12 + C12C16 + C09C13 + C13C17 + C14C18,
	C06C10 + C07C11 + C11C15 + C08C12 + C12C16 + C16C20 + C13C17 + C17C21 + C18C22,
	C07C11 + C08C12 + C12C16 + C09C13 + C13C17 + C17C21 + C14C18 + C18C22 + C19C23);

	d02 = pow(d02,exp)+0.001;

	vec4 weight01 = d02;
	vec4 weight02 = d01;
	vec4 weight03 = 1.0/(d01 + d02);

	vec3 DR0 = Interpolate3d( C06, C12, C00, C18 ); 
	vec3 UR0 = Interpolate3d( C07, C11, C03, C15 ); 

	vec3 DR1 = Interpolate3d( C07, C13, C01, C19 ); 
	vec3 UR1 = Interpolate3d( C08, C12, C04, C16 ); 

	vec3 DR2 = Interpolate3d( C11, C17, C05, C23 ); 
	vec3 UR2 = Interpolate3d( C12, C16, C08, C20 ); 

	vec3 DR3 = Interpolate3d( C12, C18, C06, C24 ); 
	vec3 UR3 = Interpolate3d( C13, C17, C09, C21 ); 

	vec2 frac = fract(coord*texSize.xy);

	vec3 sum0 = (DR0 * weight01.x + UR0 * weight02.x)*weight03.x; 
	vec3 sum1 = (DR1 * weight01.y + UR1 * weight02.y)*weight03.y;
	vec3 sum2 = (DR2 * weight01.z + UR2 * weight02.z)*weight03.z;
	vec3 sum3 = (DR3 * weight01.w + UR3 * weight02.w)*weight03.w;

	return mix(mix(sum0,sum1,frac.x),mix(sum2,sum3,frac.x),frac.y);
 
}

void main()
{

    FragColor = vec4(STAA3D( vTexCoord.xy, Size3D ), 1.0);
} 
#endif
