/*
   Simple Edge Directed Interpolation (SEDI) v1.0

   Copyright (C) 2017 SimoneT - simone1tarditi@gmail.com

   de Blur - Copyright (C) 2016 guest(r) - guest.r@gmail.com

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

// Parameter lines go here:
#pragma parameter filterparam "Edge Size" 7.0 1.0 25.0 1.0

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
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float filterparam;
#else
#define filterparam 7.0
#endif

//const   vec4 Size = vec4( 1024.0, 512.0, 0.0009765625, 0.001953125 );
const   vec4 Size = vec4( 2048.0, 1024.0, 0.00048828125, 0.0009765625 );

float CLength(vec3 c1){

	float rmean = c1.r*0.5;

	c1*= c1;

	return sqrt((2.0+rmean)*c1.r+4.0*c1.g+(3.0-rmean)*c1.b);
}

float Cdistance(vec3 c1, vec3 c2){

	float rmean = (c1.r+c2.r)*0.5;

	c1 = pow(c1-c2,vec3(2.0));

	return sqrt((2.0+rmean)*c1.r+4.0*c1.g+(3.0-rmean)*c1.b);
}

vec3 ColMin(vec3 a, vec3 b){

	float dist = step(0.01,sign(CLength(a) - CLength(b)));

	return mix(a,b,dist);

}

vec3 ColMax(vec3 a, vec3 b){

	float dist = step(0.01,sign(CLength(a) - CLength(b)));

	return mix(b,a,dist);

}

vec3 Blur( sampler2D Frame, vec2 TexCoord ) {
	vec2 shift  = Size.zw * 0.5;

	vec3 C06 = COMPAT_TEXTURE(Frame, TexCoord - shift.xy).rgb;
	vec3 C07 = COMPAT_TEXTURE(Frame, TexCoord + vec2( shift.x,-shift.y)).rgb;
	vec3 C11 = COMPAT_TEXTURE(Frame, TexCoord + vec2(-shift.x, shift.y)).rgb;
	vec3 C12 = COMPAT_TEXTURE(Frame, TexCoord + shift.xy).rgb;

	float dif1 = Cdistance(C06,C12) + 0.00001;
	float dif2 = Cdistance(C07,C11) + 0.00001;
 
	float filterparam = 7.0; // de Blur control

	dif1=pow(dif1,filterparam);
	dif2=pow(dif2,filterparam);

	float dif3=dif1+dif2; 
 
	return (dif1*(C07+C11)*0.5 + dif2*(C06+C12)*0.5)/dif3;
}

//      de Blur code
vec3 deBlur(vec3 C9, sampler2D tex, vec2 coord) {

	vec2 dx = vec2( Size.z,    0.0);
	vec2 dy = vec2(    0.0, Size.w);
	vec2 g1 = vec2( Size.z, Size.w);
	vec2 g2 = vec2(-Size.z, Size.w);

	vec3 C0 = Blur(tex, coord-g1).rgb; 
	vec3 C1 = Blur(tex, coord-dy).rgb;
	vec3 C2 = Blur(tex, coord-g2).rgb;
	vec3 C3 = Blur(tex, coord-dx).rgb;
	vec3 C4 = Blur(tex, coord   ).rgb;
	vec3 C5 = Blur(tex, coord+dx).rgb;
	vec3 C6 = Blur(tex, coord+g2).rgb;
	vec3 C7 = Blur(tex, coord+dy).rgb;
	vec3 C8 = Blur(tex, coord+g1).rgb;

	vec3 mn1 = ColMin(ColMin(C0,C1),C2);
	vec3 mn2 = ColMin(ColMin(C3,C4),C5);
	vec3 mn3 = ColMin(ColMin(C6,C7),C8);
	     mn1 = ColMin(ColMin(mn1,mn2),mn3);

	vec3 mx1 = ColMax(ColMax(C0,C1),C2);
	vec3 mx2 = ColMax(ColMax(C3,C4),C5);
	vec3 mx3 = ColMax(ColMax(C6,C7),C8);
 	     mx1 = ColMax(ColMax(mx1,mx2),mx3);

	float dif1 = Cdistance(C4,mn1) + 0.00001;
	float dif2 = Cdistance(C4,mx1) + 0.00001;
 
	// float filterparam = 14.0; // de Blur control

	dif1=pow(dif1,filterparam);
	dif2=pow(dif2,filterparam);

	float dif3=dif1+dif2; 
 
	return (dif1*mx1 + dif2*mn1)/dif3;
}

// end de/blur //

void main()
{
	vec3 C9 = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
	FragColor = vec4(deBlur( C9, Texture, TEX0.xy), 1.0);
} 
#endif
