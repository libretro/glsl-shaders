/*
   AGS-001 shader
   A pristine recreation of the illuminated Game Boy Advance SP
   Author: endrift
   License: MPL 2.0

   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. 
*/

#pragma parameter reflectionBrightness "Reflection brightness" 0.07 0.0 1.0 0.01
#pragma parameter reflectionDistanceX "Reflection Distance X" 0.0 -1.0 1.0 0.005
#pragma parameter reflectionDistanceY "Reflection Distance Y" 0.025 -1.0 1.0 0.005
#pragma parameter lightBrightness "Light brightness" 1.0 0.0 1.0 0.01

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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	gl_Position = MVPMatrix * VertexCoord;
	TEX0.xy = TexCoord.xy;
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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float reflectionBrightness;
uniform COMPAT_PRECISION float reflectionDistanceX;
uniform COMPAT_PRECISION float reflectionDistanceY;
uniform COMPAT_PRECISION float lightBrightness;
#else
#define reflectionBrightness 0.07
#define reflectionDistanceX 0.0
#define reflectionDistanceY 0.025
#define lightBrightness 1.0
#endif

const float speed = 2.0;
const float decay = 2.0;
const float coeff = 2.5;

void main()
{
	vec2 reflectionDistance = vec2(reflectionDistanceX,reflectionDistanceY);
	float sp = pow(speed, lightBrightness);
	float dc = pow(decay, -lightBrightness);
	float s = (sp - dc) / (sp + dc);
	vec2 radius = (vTexCoord.st - vec2(0.5, 0.5)) * vec2(coeff * s);
	radius = pow(abs(radius), vec2(4.0));
	vec3 bleed = vec3(0.12, 0.14, 0.19);
	bleed += (dot(radius, radius) + vec3(0.02, 0.03, 0.05)) * vec3(0.14, 0.18, 0.2);

	vec4 color = COMPAT_TEXTURE(Source, vTexCoord);
	color.rgb += pow(bleed, pow(vec3(lightBrightness), vec3(-0.5)));

	vec4 reflection = COMPAT_TEXTURE(Source, vTexCoord - reflectionDistance);
	color.rgb += reflection.rgb * reflectionBrightness;
	color.a = 1.0;
	FragColor = color;

}
#endif
