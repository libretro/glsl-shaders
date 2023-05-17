/*
 * Deband shader by haasn
 * https://github.com/mpv-player/mpv/blob/master/video/out/opengl/video_shaders.c
 *
 * This file is part of mpv.
 *
 * mpv is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * mpv is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with mpv.  If not, see <http://www.gnu.org/licenses/>.
 *
 * You can alternatively redistribute this file and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Modified and optimized for RetroArch by hunterk
*/

// Parameter lines go here:
#pragma parameter iterations "Deband Iterations" 2.0 1.0 10.0 1.0
#pragma parameter threshold "Deband Threshold" 1.0 1.0 16.0 0.5
#pragma parameter range "Deband Range" 1.5 0.0 10.0 0.5
#pragma parameter grain "Deband Grain" 0.0 0.0 2.0 0.1

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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float iterations;
uniform COMPAT_PRECISION float threshold;
uniform COMPAT_PRECISION float range;
uniform COMPAT_PRECISION float grain;
#else
#define iterations 2.0
#define threshold 1.0
#define range 1.5
#define grain 0.0
#endif

// Wide usage friendly PRNG, shamelessly stolen from a GLSL tricks forum post.
// Obtain random numbers by calling rand(h), followed by h = permute(h) to
// update the state. Assumes the texture was hooked.
float mod289(float x)
{
	return x - floor(x / 289.0) * 289.0;
}

float permute(float x)
{
	return mod289((34.0 * x + 1.0) * x);
}

float rand(float x)
{
	return fract(x * 0.024390243);
}

vec4 average(sampler2D tex, vec2 coord, float range, inout float h, vec2 size)
{
	float dist = rand(h) * range;	h = permute(h);
	float dir = rand(h) * 6.2831853;	h = permute(h);
	vec2 o = vec2(cos(dir), sin(dir));
	vec2 pt = dist / size.xy;
	
	vec4 ref[4];
	ref[0] = COMPAT_TEXTURE(tex, coord + pt * vec2( o.x, o.y));
	ref[1] = COMPAT_TEXTURE(tex, coord + pt * vec2(-o.y, o.x));
	ref[2] = COMPAT_TEXTURE(tex, coord + pt * vec2(-o.x,-o.y));
	ref[3] = COMPAT_TEXTURE(tex, coord + pt * vec2( o.y,-o.x));
	
	return (ref[0] + ref[1] + ref[2] + ref[3]) * 0.25;
}

void main()
{
	// Initialize the PRNG by hashing the position + a random uniform
	vec3 m = vec3(vTexCoord, rand(sin(vTexCoord.x / vTexCoord.y) * mod(float(FrameCount), 79.) + 22.759)) + vec3(1.0);
	float h = permute(permute(permute(m.x) + m.y) + m.z);
	
	vec4 avg;
	vec4 diff;
	
	// Sample the source pixel
	vec4 color = COMPAT_TEXTURE(Source, vTexCoord).rgba;
	
	for (int i = 1; i <= int(iterations); i++)
		{
			// Sample the average pixel and use it instead of the original if
			// the difference is below the given threshold
			avg = average(Source, vTexCoord, float(i) * range, h, TextureSize.xy);
			diff = abs(color - avg);
			color = mix(avg, color, float(greaterThan(diff, vec4(threshold / (float(i) * 10.0)))));
		}
	if (grain > 0.0)
		{
			// Add some random noise to smooth out residual differences
			vec3 noise;
			noise.x = rand(h); h = permute(h);
			noise.y = rand(h); h = permute(h);
			noise.z = rand(h); h = permute(h);
			color.rgb += grain * (noise - vec3(0.5));
		}
	
   FragColor = vec4(color);
} 
#endif
