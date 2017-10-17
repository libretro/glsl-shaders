/*
/   "Conditional Blending of Dither" Shader v1.0 - Pass 1
/   Copyright (c) 2013, Alexander Kulagin <coastkid3d@gmail.com>
/   All Rights reserved.
/
/   Redistribution and use in source and binary forms, with or without
/   modification, are permitted provided that the following conditions are met:
/
/     * Redistributions of source code must retain the above copyright notice,
/       this list of conditions and the following disclaimer.
/
/     * Redistributions in binary form must reproduce the above copyright
/       notice, this list of conditions and the following disclaimer in the
/       documentation and/or other materials provided with the distribution.
/
/   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
/   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
/   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
/   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
/   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
/   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
/   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
/   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
/   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
/   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
/   POSSIBILITY OF SUCH DAMAGE.
*/

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

void main()
{
  vec2 uv = vTexCoord - (SourceSize.zw) * 0.25;
  vec2 uv_shift = (SourceSize.zw);
	vec3 src = COMPAT_TEXTURE(Source, uv).rgb;

  // Searching for the Vertical Dithering Zones
	vec3 dither_v_zone = vec3(COMPAT_TEXTURE(Source, uv + vec2(uv_shift.x, 0.)).rgb == COMPAT_TEXTURE(Source, uv - vec2(uv_shift.x, 0.)).rgb);
  dither_v_zone = vec3(smoothstep(0.2, 1.0, dot(dither_v_zone, vec3(0.33333))));

  // Searching for High Contrast "Safe" Zones
  vec3 safe_zone = vec3(abs(dot(COMPAT_TEXTURE(Source, uv).rgb - COMPAT_TEXTURE(Source, uv - vec2(uv_shift.x, 0.)).rgb, vec3(0.3333))));
  safe_zone = vec3(lessThan(safe_zone , vec3(0.45)));

  // Horizontal Bluring by 1 pixel
  vec3 blur_h = (COMPAT_TEXTURE(Source, uv).rgb + COMPAT_TEXTURE(Source, uv - vec2(uv_shift.x, 0.)).rgb) * 0.5;

  // Final Blend between Source and Blur using Dithering Zone and Safe Zone
  vec3 finalcolor = mix(src, blur_h, dither_v_zone * safe_zone);

   FragColor = vec4(finalcolor, 1.0);
}
#endif
