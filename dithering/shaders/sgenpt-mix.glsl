/*
   SGENPT-MIX - Sega Genesis Pseudo Transparency Mixer Shader - v10
   
   2011-2024 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is 
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

*/

#pragma parameter SGPT_NONONO       "SGENPT-MIX v10:"                                 0.0 0.0 1.0 1.0
#pragma parameter SGPT_BLEND_OPTION "    0: OFF | 1: VL+CB | 2: VL | 3: CB"           1.0 0.0 3.0 1.0
#pragma parameter SGPT_BLEND_LEVEL  "    Blend Level"                                 0.85 0.0 1.0 0.05
#pragma parameter SGPT_ADJUST_VIEW  "    Adjust View"                                 0.0 0.0 1.0 1.0
#pragma parameter SGPT_LINEAR_GAMMA "    Use Linear Gamma"                            1.0 0.0 1.0 1.0

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

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

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

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SGPT_BLEND_OPTION;
uniform COMPAT_PRECISION float SGPT_BLEND_LEVEL;
uniform COMPAT_PRECISION float SGPT_ADJUST_VIEW;
uniform COMPAT_PRECISION float SGPT_LINEAR_GAMMA;
#else
#define SGPT_BLEND_OPTION 4.0
#define SGPT_BLEND_LEVEL 1.0
#define SGPT_ADJUST_VIEW 0.0
#define SGPT_LINEAR_GAMMA 1.0
#endif

#define GAMMA_EXP		(SGPT_LINEAR_GAMMA+1.0)
#define GAMMA_IN(color)		pow(color, vec3(GAMMA_EXP, GAMMA_EXP, GAMMA_EXP))
#define GAMMA_OUT(color)	pow(color, vec3(1.0 / GAMMA_EXP, 1.0 / GAMMA_EXP, 1.0 / GAMMA_EXP))

const vec3 Y = vec3( 0.299,  0.587,  0.114);

vec3 min_s(vec3 central, vec3 adj1, vec3 adj2) {return min(central, max(adj1, adj2));}
vec3 max_s(vec3 central, vec3 adj1, vec3 adj2) {return max(central, min(adj1, adj2));}

void main()
{
	vec2 dx = vec2(1.0, 0.0)/SourceSize.xy;
	vec2 dy = vec2(0.0, 1.0)/SourceSize.xy;

	// Reading the texels.
	vec3 C = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord    ).xyz);
	vec3 L = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord -dx).xyz);
	vec3 R = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord +dx).xyz);

	//  Get min/max samples
	vec3 min_sample = min_s(C, L, R);
	vec3 max_sample = max_s(C, L, R);

	float contrast = dot(max(C, max(L, R)) - min(C, min(L, R)), Y);

	contrast = smoothstep(0.0, 1.0, (1.0 - SGPT_BLEND_LEVEL) * contrast);

	if (int(SGPT_BLEND_OPTION) == 2) // Only Vertical Lines
	{
		vec3 UL = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord -dx -dy).xyz);
		vec3 UR = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord +dx -dy).xyz);
		vec3 DL = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord -dx +dy).xyz);
		vec3 DR = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord +dx +dy).xyz);

		min_sample = max_s(min_sample, min_s(C, DL, DR), min_s(C, UL, UR));
		max_sample = min_s(max_sample, max_s(C, DL, DR), max_s(C, UL, UR));
	}
	else if (int(SGPT_BLEND_OPTION) == 3) // Only Checkerboard
	{
		vec3 U = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord -dy).xyz);
		vec3 D = GAMMA_IN(COMPAT_TEXTURE(Source, vTexCoord +dy).xyz);

		min_sample = max(min_sample, min_s(C, U, D));
		max_sample = min(max_sample, max_s(C, U, D));
	}

	vec3 col_L = 0.5*( C + L + contrast*( C - L ));
	vec3 col_R = 0.5*( C + R + contrast*( C - R ));

	float contrast_L = dot(abs(C - col_L), Y);
	float contrast_R = dot(abs(C - col_R), Y);

	// Choose smaller contrast
	vec3 color = contrast_R < contrast_L ? col_R : col_L;

	color = SGPT_BLEND_OPTION > 0.5 ? clamp(color, min_sample, max_sample) : C;

	color = SGPT_ADJUST_VIEW > 0.5 ? vec3(dot(abs(C-color), vec3(1.0, 1.0, 1.0))) : color;

	FragColor = vec4(GAMMA_OUT(color), 1.0);

} 
#endif
