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

// Parameter lines go here:
#pragma parameter TWO_D_SCALE "2D Filter Scale" 2.0 1.0 8.0 1.0
#pragma parameter THREE_D_SCALE "3D Filter Scale" 4.0 1.0 8.0 1.0

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
uniform COMPAT_PRECISION float TWO_D_SCALE;
uniform COMPAT_PRECISION float THREE_D_SCALE;
#else
#define TWO_D_SCALE 2.0
#define THREE_D_SCALE 4.0
#endif

vec2 Size1D    = vec2( SourceSize.x, SourceSize.y );
vec2 InvSize1D = 1.0 / Size1D;//vec2(0.000976562,0.001953125);
vec4 Size2D = vec4(vec2(TWO_D_SCALE * Size1D), vec2(1.0 / (TWO_D_SCALE * Size1D)));//vec4( 2048.0, 1024.0, 0.00048828125  , 0.0009765625   );
vec4 Size3D = vec4(vec2(THREE_D_SCALE * Size1D), vec2(1.0 / (THREE_D_SCALE * Size1D)));//vec4( 8192.0, 4096.0, 0.0001220703125, 0.000244140625 );

const   vec3 ones = vec3(1.0,1.0,1.0);

const	vec4 exp = vec4(30.0);	

const	vec4 yx = vec4( 0.000244140625, 0.00048828125,-0.000244140625,-0.00048828125);
const	vec4 xy = vec4( 0.00048828125 , 0.0009765625 ,-0.00048828125 ,-0.0009765625 );

const   vec2 dx  = vec2( 0.00048828125, 0.0         );
const   vec2 dy  = vec2( 0.0          , 0.0009765625);
const   vec2 g1  = vec2( 0.00048828125, 0.0009765625);
const   vec2 g2  = vec2(-0.00048828125, 0.0009765625);

vec3 ColMin(vec3 a, vec3 b){

	float dist = step(0.1,sign(length(a) - length(b)));

	return mix(a,b,dist);

}

vec3 ColMax(vec3 a, vec3 b){

	float dist = step(0.1,sign(length(a) - length(b)));

	return mix(b,a,dist);

}
 
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

vec3 Interpolate2d( vec3 a, vec3 b, vec3 c, vec3 d ) {

	return (( a + b ) * 9.0 +  c + d ) * 0.05;

}

vec3 STAA2D( vec2 coord, vec4 texSize ) {

	vec2 TexCoord = (floor(coord*texSize.xy)+0.5)*texSize.zw;
	vec4 shift  = vec4( texSize.zw,-texSize.zw);
	vec4 shift2 = 2.0*shift;

	vec3 C00 = COMPAT_TEXTURE(Source, TexCoord - shift2.xy                ).rgb;
	vec3 C01 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.x , shift2.y)).rgb;
	vec3 C02 = COMPAT_TEXTURE(Source, TexCoord - vec2( 0.0     , shift2.y)).rgb;
	vec3 C03 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.z , shift2.y)).rgb;
	vec3 C04 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.z, shift2.y)).rgb;

	vec3 C05 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.x, shift.y )).rgb;
	vec3 C06 = COMPAT_TEXTURE(Source, TexCoord - shift.xy                 ).rgb;
	vec3 C07 = COMPAT_TEXTURE(Source, TexCoord - vec2( 0.0     , shift.y )).rgb;
	vec3 C08 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.z , shift.y )).rgb;
	vec3 C09 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.z, shift.y )).rgb;

	vec3 C10 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.x, 0.0     )).rgb;
	vec3 C11 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.x , 0.0     )).rgb;
	vec3 C12 = COMPAT_TEXTURE(Source, TexCoord                            ).rgb;
	vec3 C13 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , 0.0     )).rgb;
	vec3 C14 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, 0.0     )).rgb;

	vec3 C15 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift.y )).rgb;
	vec3 C16 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift.y )).rgb;
	vec3 C17 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift.y )).rgb;
	vec3 C18 = COMPAT_TEXTURE(Source, TexCoord + shift.xy                 ).rgb;
	vec3 C19 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, shift.y )).rgb;

	vec3 C20 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift2.y)).rgb;
	vec3 C21 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift2.y)).rgb;
	vec3 C22 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift2.y)).rgb;
	vec3 C23 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , shift2.y)).rgb;
	vec3 C24 = COMPAT_TEXTURE(Source, TexCoord + shift2.xy                ).rgb;

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

	vec3 DR0 = Interpolate2d( C06, C12, C00, C18 ); 
	vec3 UR0 = Interpolate2d( C07, C11, C03, C15 ); 

	vec3 DR1 = Interpolate2d( C07, C13, C01, C19 ); 
	vec3 UR1 = Interpolate2d( C08, C12, C04, C16 ); 

	vec3 DR2 = Interpolate2d( C11, C17, C05, C23 ); 
	vec3 UR2 = Interpolate2d( C12, C16, C08, C20 ); 

	vec3 DR3 = Interpolate2d( C12, C18, C06, C24 ); 
	vec3 UR3 = Interpolate2d( C13, C17, C09, C21 ); 

	vec2 frac = fract(coord*texSize.xy);

	vec3 sum0 = (DR0 * weight01.x + UR0 * weight02.x)*weight03.x; 
	vec3 sum1 = (DR1 * weight01.y + UR1 * weight02.y)*weight03.y;
	vec3 sum2 = (DR2 * weight01.z + UR2 * weight02.z)*weight03.z;
	vec3 sum3 = (DR3 * weight01.w + UR3 * weight02.w)*weight03.w;

	return mix(mix(sum0,sum1,frac.x),mix(sum2,sum3,frac.x),frac.y);
 
}

vec3 Interpolate3d( vec3 a, vec3 b, vec3 c, vec3 d ) {

	return ( a + b + c + d ) * 0.25;

}

vec3 STAA3D( vec2 coord, vec4 texSize ) {

	vec2 TexCoord = (floor(coord*texSize.xy)+0.5)*texSize.zw;
	vec4 shift  = vec4( texSize.zw,-texSize.zw);
	vec4 shift2 = 2.0*shift;

	vec3 C00 = COMPAT_TEXTURE(Source, TexCoord - shift2.xy                ).rgb;
	vec3 C01 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.x , shift2.y)).rgb;
	vec3 C02 = COMPAT_TEXTURE(Source, TexCoord - vec2( 0.0     , shift2.y)).rgb;
	vec3 C03 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.z , shift2.y)).rgb;
	vec3 C04 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.z, shift2.y)).rgb;

	vec3 C05 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.x, shift.y )).rgb;
	vec3 C06 = COMPAT_TEXTURE(Source, TexCoord - shift.xy                 ).rgb;
	vec3 C07 = COMPAT_TEXTURE(Source, TexCoord - vec2( 0.0     , shift.y )).rgb;
	vec3 C08 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.z , shift.y )).rgb;
	vec3 C09 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.z, shift.y )).rgb;

	vec3 C10 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift2.x, 0.0     )).rgb;
	vec3 C11 = COMPAT_TEXTURE(Source, TexCoord - vec2( shift.x , 0.0     )).rgb;
	vec3 C12 = COMPAT_TEXTURE(Source, TexCoord                            ).rgb;
	vec3 C13 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , 0.0     )).rgb;
	vec3 C14 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, 0.0     )).rgb;

	vec3 C15 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift.y )).rgb;
	vec3 C16 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift.y )).rgb;
	vec3 C17 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift.y )).rgb;
	vec3 C18 = COMPAT_TEXTURE(Source, TexCoord + shift.xy                 ).rgb;
	vec3 C19 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, shift.y )).rgb;

	vec3 C20 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift2.y)).rgb;
	vec3 C21 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift2.y)).rgb;
	vec3 C22 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift2.y)).rgb;
	vec3 C23 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , shift2.y)).rgb;
	vec3 C24 = COMPAT_TEXTURE(Source, TexCoord + shift2.xy                ).rgb;

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
//	4xGLSoft lite code ( some modification... )

vec3 lite4xGLSoft(vec2 texcoord) {

	vec3 c11 = COMPAT_TEXTURE(Source, texcoord        ).rgb; 
	vec3 c00 = COMPAT_TEXTURE(Source, texcoord + xy.zw).rgb; 
	vec3 c20 = COMPAT_TEXTURE(Source, texcoord + xy.xw).rgb; 
	vec3 c22 = COMPAT_TEXTURE(Source, texcoord + xy.xy).rgb; 
	vec3 c02 = COMPAT_TEXTURE(Source, texcoord + xy.zy).rgb; 
	vec3 s00 = COMPAT_TEXTURE(Source, texcoord + yx.zw).rgb; 
	vec3 s20 = COMPAT_TEXTURE(Source, texcoord + yx.xw).rgb; 
	vec3 s22 = COMPAT_TEXTURE(Source, texcoord + yx.xy).rgb; 
	vec3 s02 = COMPAT_TEXTURE(Source, texcoord + yx.zy).rgb; 

	vec4 d1=vec4(
	distance(c00,c22),
	distance(c20,c02),
	distance(s00,s22),
	distance(s02,s20))+0.001;

	vec3 t2=(d1.x*(c20+c02)+d1.y*(c00+c22))/(2.0*(d1.x+d1.y));
	
	return .25*(c11+t2+(d1.w*(s00+s22)+d1.z*(s02+s20))/(d1.z+d1.w));

}

//      de Blur code ( some modification... )

vec3 deBlur(vec3 C4, vec2 texCoord ) {

	vec3 C0 = lite4xGLSoft(texCoord-g1); 
	vec3 C1 = lite4xGLSoft(texCoord-dy);
	vec3 C2 = lite4xGLSoft(texCoord-g2);
	vec3 C3 = lite4xGLSoft(texCoord-dx);
	//vec3 C4 = lite4xGLSoft(texCoord   );
	vec3 C5 = lite4xGLSoft(texCoord+dx);
	vec3 C6 = lite4xGLSoft(texCoord+g2);
	vec3 C7 = lite4xGLSoft(texCoord+dy);
	vec3 C8 = lite4xGLSoft(texCoord+g1);

	vec3 mn1 = ColMin(ColMin(C0,C1),C2);
	vec3 mn2 = ColMin(ColMin(C3,C4),C5);
	vec3 mn3 = ColMin(ColMin(C6,C7),C8);
	vec3 mx1 = ColMax(ColMax(C0,C1),C2);
	vec3 mx2 = ColMax(ColMax(C3,C4),C5);
	vec3 mx3 = ColMax(ColMax(C6,C7),C8);
 
	mn1 = ColMin(ColMin(mn1,mn2),mn3);
	mx1 = ColMax(ColMax(mx1,mx2),mx3);

	float dif1 = distance(C4,mn1) + 0.001;
	float dif2 = distance(C4,mx1) + 0.001;
 
	float filterparam = 6.0; // de Blur control

	dif1=pow(dif1,filterparam);
	dif2=pow(dif2,filterparam);
	float dif3=1.0/(dif1+dif2); 
 
	return (dif1*mx1 + dif2*mn1)*dif3;

}

void main()
{
	float e0  = detect3d( Source, vTexCoord.xy );
	float e1  = detect3d( Source, vTexCoord.xy+vec2(InvSize1D.x,0.0));
	float e2  = detect3d( Source, vTexCoord.xy+vec2(0.0,InvSize1D.y));
	float e3  = detect3d( Source, vTexCoord.xy+InvSize1D );

	float e = min(1.0,e0+e1+e2+e3);

	vec3 c11 = ( e < 1.0 ) ? (deBlur(STAA2D( vTexCoord.xy, Size2D ), vTexCoord.xy)): 
				 (       STAA3D( vTexCoord.xy, Size3D ));
    FragColor = vec4(c11, 1.0);
} 
#endif
