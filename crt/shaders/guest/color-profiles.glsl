/*
   CRT Color Profiles
   
   Copyright (C) 2019 guest(r) and Dr. Venom
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
   
*/ 

// Parameter lines go here:
#pragma parameter CP "CRT Color Profile" 0.0 -1.0 5.0 1.0 
#pragma parameter CS "Color Space: sRGB, DCI, Adobe, Rec.2020" 0.0 0.0 3.0 1.0 

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
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float CP;
uniform COMPAT_PRECISION float CS;
#else
#define CP  0.0
#define CS  0.0
#endif 
 

mat3 Profile0 = 
transpose(mat3(
 0.412391,  0.357584,  0.180481,
 0.212639,  0.715169,  0.072192,
 0.019331,  0.119195,  0.950532
));

 
mat3 Profile1 = 
transpose(mat3(
 0.430554,  0.341550,  0.178352,
 0.222004,  0.706655,  0.071341,
 0.020182,  0.129553,  0.939322
));


mat3 Profile2 = 
transpose(mat3(
 0.396686,  0.372504,  0.181266,
 0.210299,  0.713766,  0.075936,
 0.006131,  0.115356,  0.967571
));


mat3 Profile3 = 
transpose(mat3(
 0.393521,  0.365258,  0.191677,
 0.212376,  0.701060,  0.086564,
 0.018739,  0.111934,  0.958385
));


mat3 Profile4 = 
transpose(mat3(
 0.392258,  0.351135,  0.166603,
 0.209410,  0.725680,  0.064910,
 0.016061,  0.093636,  0.850324
));


mat3 Profile5 = 
transpose(mat3(
 0.377923,  0.317366,  0.207738,
 0.195679,  0.722319,  0.082002,
 0.010514,  0.097826,  1.076960
));


mat3 ToSRGB = 
transpose(mat3(
 3.240970, -1.537383, -0.498611,
-0.969244,  1.875968,  0.041555,
 0.055630, -0.203977,  1.056972
));
 
mat3 ToDCI = 
transpose(mat3(
 2.725394,  -1.018003,  -0.440163,
-0.795168,   1.689732,   0.022647,
 0.041242,  -0.087639,   1.100929
));

mat3 ToAdobe = 
transpose(mat3(
 2.041588, -0.565007, -0.344731,
-0.969244,  1.875968,  0.041555,
 0.013444, -0.118362,  1.015175
));

mat3 ToREC = 
transpose(mat3(
 1.716651, -0.355671, -0.253366,
-0.666684,  1.616481,  0.015769,
 0.017640, -0.042771,  0.942103
));


void main()
{
	vec3 c = COMPAT_TEXTURE(Source, TEX0.xy).rgb;
	
	float p;
	mat3 m_out;
	
	if (CS == 0.0) { p = 2.4; m_out =  ToSRGB; } else
	if (CS == 1.0) { p = 2.6; m_out =  ToDCI;  } else
	if (CS == 2.0) { p = 2.2; m_out =  ToAdobe;} else
	if (CS == 3.0) { p = 2.4; m_out =  ToREC;  }
	
	vec3 color = pow(c, vec3(p));
	
	mat3 m_in = Profile0;

	if (CP == 0.0) { m_in = Profile0; } else	
	if (CP == 1.0) { m_in = Profile1; } else
	if (CP == 2.0) { m_in = Profile2; } else
	if (CP == 3.0) { m_in = Profile3; } else
	if (CP == 4.0) { m_in = Profile4; } else
	if (CP == 5.0) { m_in = Profile5; }
	
	color = m_in*color;
	color = m_out*color;

	color = pow(color, vec3(1.0/p));	
	
	if (CP == -1.0) color = c;
	
	FragColor = vec4(color,1.0);
} 
#endif
