/*
   Phosphor Afterglow Shader
   
   Copyright (C) 2018 guest(r) - guest.r@gmail.com

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
#pragma parameter SW "Afterglow switch ON/OFF" 1.0 0.0 1.0 1.0
#pragma parameter AR "Afterglow Red (more is more)" 0.07 0.0 1.0 0.01
#pragma parameter PR "Persistence Red (more is less)" 0.05 0.0 1.0 0.01
#pragma parameter AG "Afterglow Green" 0.07 0.0 1.0 0.01
#pragma parameter PG "Persistence Green"  0.05 0.0 1.0 0.01
#pragma parameter AB "Afterglow Blue" 0.07 0.0 1.0 0.01
#pragma parameter PB "Persistence Blue"  0.05 0.0 1.0 0.01
#pragma parameter sat "Afterglow saturation" 0.10 0.0 1.0 0.01

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
uniform sampler2D PrevTexture;
uniform sampler2D Prev1Texture;
uniform sampler2D Prev2Texture;
uniform sampler2D Prev3Texture;
uniform sampler2D Prev4Texture;
uniform sampler2D Prev5Texture;
uniform sampler2D Prev6Texture;


COMPAT_VARYING vec4 TEX0;
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SW;
uniform COMPAT_PRECISION float AR;
uniform COMPAT_PRECISION float PR;
uniform COMPAT_PRECISION float AG;
uniform COMPAT_PRECISION float PG;
uniform COMPAT_PRECISION float AB;
uniform COMPAT_PRECISION float PB;
uniform COMPAT_PRECISION float sat;
#else
	#define SW 1.00
	#define AR 0.07
	#define PR 0.05
	#define AG 0.07
	#define PG 0.05
	#define AB 0.07
	#define PB 0.05
	#define sat 0.10
#endif 

#define eps 1e-3

vec3 afterglow(float number)
{
	return vec3(AR, AG, AB)*exp2(-vec3(PR, PG, PB)*vec3(number*number));
}

void main()
{
	vec3 color = COMPAT_TEXTURE(Source, TEX0.xy).rgb;
	vec3 color1 = COMPAT_TEXTURE(Prev1Texture, TEX0.xy).rgb * afterglow(1.0);
	vec3 color2 = COMPAT_TEXTURE(Prev2Texture, TEX0.xy).rgb * afterglow(2.0);
	vec3 color3 = COMPAT_TEXTURE(Prev3Texture, TEX0.xy).rgb * afterglow(3.0);
	vec3 color4 = COMPAT_TEXTURE(Prev4Texture, TEX0.xy).rgb * afterglow(4.0);
	vec3 color5 = COMPAT_TEXTURE(Prev5Texture, TEX0.xy).rgb * afterglow(5.0);
	vec3 color6 = COMPAT_TEXTURE(Prev6Texture, TEX0.xy).rgb * afterglow(6.0);

	vec3 glow = color1 + color2 + color3 + color4 + color5 + color6;
	
	float l = length(glow);
	glow = normalize(pow(glow + vec3(eps), vec3(sat)))*l;		
	
	float w = 1.0;
	if ((color.r + color.g + color.b) > 7.0/255.0) w = 0.0;
	
	FragColor = vec4(color + SW*w*glow,1.0);
} 
#endif
