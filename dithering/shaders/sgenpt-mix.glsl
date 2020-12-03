/*
   SGENPT-MIX - Sega Genesis Pseudo Transparency Mixer Shader - v5
   
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

#pragma parameter SGPT_SHARPNESS "SGENPT-MIX Sharpness" 1.0 0.0 1.0 0.1
#pragma parameter SGPT_BLEND_OPTION "OFF | Transparency | Checkerboard" 1.0 0.0 2.0 1.0
#pragma parameter SGPT_BLEND_LEVEL "SGENPT-MIX Blend Level" 1.0 0.0 1.0 0.1


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
uniform COMPAT_PRECISION float SGPT_SHARPNESS;
uniform COMPAT_PRECISION float SGPT_BLEND_OPTION;
uniform COMPAT_PRECISION float SGPT_BLEND_LEVEL;
#else
#define SGPT_SHARPNESS 1.0
#define SGPT_BLEND_OPTION 1.0
#define SGPT_BLEND_LEVEL 1.0
#endif


const vec3 Y = vec3(.2126, .7152, .0722);


void main()
{
	vec2 dx = vec2(1.0, 0.0)/TextureSize;
	vec2 dy = vec2(0.0, 1.0)/TextureSize;

	// Reading the texels.
	vec3 C = tex2D(s_p, texCoord    ).xyz;
	vec3 L = tex2D(s_p, texCoord -dx).xyz;
	vec3 R = tex2D(s_p, texCoord +dx).xyz;
	vec3 U = tex2D(s_p, texCoord -dy).xyz;
	vec3 D = tex2D(s_p, texCoord +dy).xyz;

	vec3 color = C;

	if (SGPT_BLEND_OPTION > 0.0)
	{
		//  Get min/max samples
		vec3 min_sample = min(C, max(L, R));
		vec3 max_sample = max(C, min(L, R));

		float diff = (1.0 - SGPT_BLEND_LEVEL) * dot(max(max(C, L), max(C, R)) - min(min(C, L), min(C, R)), Y);

		color = 0.5*( 1.0 + diff )*C + 0.25*( 1.0 - diff )*(L + R);

		if (SGPT_BLEND_OPTION > 1.0)
		{
			//  Get min/max samples
			min_sample = max(min_sample, min(C, max(U, D)));
			max_sample = min(max_sample, max(C, min(U, D)));

			color = 0.5*( 1.0 + diff )*C + 0.125*( 1.0 - diff )*(L + R + U + D);
		}

		// Sharpness control
		vec3 aux = color;
		color = clamp(color, min_sample, max_sample);
		color = mix(aux, color, SGPT_SHARPNESS);
	}

	FragColor.xyz = color;
}
#endif
