/*
   SGENPT-MIX - Sega Genesis Pseudo Transparency Mixer Shader - v8b
   
   2011-2020 Hyllian - sergiogdb@gmail.com

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

#pragma parameter SGPT_BLEND_OPTION "0.OFF | 1.VL | 2.CB | 3.CB-S | 4.Both | 5.Both2 | 6.Both-S" 4.0 0.0 6.0 1.0
#pragma parameter SGPT_BLEND_LEVEL "SGENPT-MIX Both Blend Level" 1.0 0.0 1.0 0.1
#pragma parameter SGPT_ADJUST_VIEW "SGENPT-MIX Adjust View" 0.0 0.0 1.0 1.0
#pragma parameter SGPT_LINEAR_GAMMA "SGENPT-MIX Use Linear Gamma" 1.0 0.0 1.0 1.0


#define texCoord TEX0

#if defined(VERTEX)

#if __VERSION__ >= 130
#define OUT out
#define IN  in
#define tex2D texture
#else
#define OUT varying
#define IN attribute
#define tex2D texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif


IN  vec4 VertexCoord;
IN  vec4 Color;
IN  vec2 TexCoord;
OUT vec4 color;
OUT vec2 texCoord;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int  FrameDirection;
uniform COMPAT_PRECISION int  FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    color = Color;
    texCoord = TexCoord;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define IN in
#define tex2D texture
out vec4 FragColor;
#else
#define IN varying
#define FragColor gl_FragColor
#define tex2D texture2D
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
uniform sampler2D s_p;
IN vec2 texCoord;

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


const vec3 Y = vec3(.2126, .7152, .0722);

vec3 min_s(vec3 central, vec3 adj1, vec3 adj2) {return min(central, max(adj1, adj2));}
vec3 max_s(vec3 central, vec3 adj1, vec3 adj2) {return max(central, min(adj1, adj2));}


void main()
{
	vec2 dx = vec2(1.0, 0.0)/TextureSize;
	vec2 dy = vec2(0.0, 1.0)/TextureSize;

	// Reading the texels.
	vec3 C = GAMMA_IN(tex2D(s_p, texCoord    ).xyz);
	vec3 L = GAMMA_IN(tex2D(s_p, texCoord -dx).xyz);
	vec3 R = GAMMA_IN(tex2D(s_p, texCoord +dx).xyz);
	vec3 U = GAMMA_IN(tex2D(s_p, texCoord -dy).xyz);
	vec3 D = GAMMA_IN(tex2D(s_p, texCoord +dy).xyz);
	vec3 UL = GAMMA_IN(tex2D(s_p, texCoord -dx -dy).xyz);
	vec3 UR = GAMMA_IN(tex2D(s_p, texCoord +dx -dy).xyz);
	vec3 DL = GAMMA_IN(tex2D(s_p, texCoord -dx +dy).xyz);
	vec3 DR = GAMMA_IN(tex2D(s_p, texCoord +dx +dy).xyz);

	vec3 color = C;

	//  Get min/max samples
	vec3 min_sample = min_s(C, L, R);
	vec3 max_sample = max_s(C, L, R);

	float diff = dot(max(max(C, L), max(C, R)) - min(min(C, L), min(C, R)), Y);

	if (int(SGPT_BLEND_OPTION) == 1) // Only Vertical Lines
	{
		min_sample = max_s(min_sample, min_s(C, DL, DR), min_s(C, UL, UR));
		max_sample = min_s(max_sample, max_s(C, DL, DR), max_s(C, UL, UR));

		diff *= (1.0 - SGPT_BLEND_LEVEL);

		color = 0.5*( 1.0 + diff )*C + 0.25*( 1.0 - diff )*(L + R);
	}
	else if (int(SGPT_BLEND_OPTION) == 2) // Only Checkerboard
	{
		min_sample = max(min_sample, min_s(C, U, D));
		max_sample = min(max_sample, max_s(C, U, D));

		diff *= (1.0 - SGPT_BLEND_LEVEL);

		color = 0.5*( 1.0 + diff )*C + 0.125*( 1.0 - diff )*(L + R + U + D);
	}
	else if (int(SGPT_BLEND_OPTION) == 3) // Only Checkerboard - Soft
	{
		min_sample = min_s(min_sample, U, D);
		max_sample = max_s(max_sample, U, D);

		diff *= (1.0 - SGPT_BLEND_LEVEL);

		color = 0.5*( 1.0 + diff )*C + 0.125*( 1.0 - diff )*(L + R + U + D);
	}
	else if (int(SGPT_BLEND_OPTION) == 4) // VL-CB
	{
		diff *= (1.0 - SGPT_BLEND_LEVEL);

		color = 0.5*( 1.0 + diff )*C + 0.25*( 1.0 - diff )*(L + R);
	}
	else if (int(SGPT_BLEND_OPTION) == 5) // VL-CB-2
	{
		min_sample = min_s(min_sample, U, D);
		max_sample = max_s(max_sample, U, D);

		diff *= (1.0 - SGPT_BLEND_LEVEL);

		color = 0.5*( 1.0 + diff )*C + 0.25*( 1.0 - diff )*(L + R);
	}
	else if (int(SGPT_BLEND_OPTION) == 6) // VL-CB-Soft
	{
		min_sample = min(min_sample, min(min_s(D, DL, DR), min_s(U, UL, UR)));
		max_sample = max(max_sample, max(max_s(D, DL, DR), max_s(U, UL, UR)));

		diff *= (1.0 - SGPT_BLEND_LEVEL);

		color = 0.5*( 1.0 + diff )*C + 0.25*( 1.0 - diff )*(L + R);
	}

	color = clamp(color, min_sample, max_sample);

	color = mix(color, vec3(dot(abs(C-color), vec3(1.0, 1.0, 1.0))), SGPT_ADJUST_VIEW);

	FragColor.xyz = GAMMA_OUT(color);
}
#endif
