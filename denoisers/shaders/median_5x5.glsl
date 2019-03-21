/*
5x5 Median

Morgan McGuire and Kyle Whitson, 2006
Williams College
http://graphics.cs.williams.edu

Copyright (c) Morgan McGuire and Williams College, 2006
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
COMPAT_VARYING vec4 t01;
COMPAT_VARYING vec4 t02;
COMPAT_VARYING vec4 t03;
COMPAT_VARYING vec4 t04;
COMPAT_VARYING vec4 t05;
COMPAT_VARYING vec4 t06;
COMPAT_VARYING vec4 t07;
COMPAT_VARYING vec4 t08;
COMPAT_VARYING vec4 t09;
COMPAT_VARYING vec4 t10;
COMPAT_VARYING vec4 t11;
COMPAT_VARYING vec4 t12;

vec4 _oPosition1;
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    vec4 _oColor;
    vec2 _otexCoord;
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    _oPosition1 = gl_Position;
    _oColor = COLOR;
    _otexCoord = TexCoord.xy;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;

	vec2 ps = vec2(1.0).xy / TextureSize.xy;
	float dx1 = ps.x;
	float dx2 = ps.x + ps.x;
	float dy1 = ps.y;
	float dy2 = ps.y + ps.y;

	t01 = TEX0.xyxy + vec4(-dx2, -dy2, -dx1, -dy2);
	t02 = TEX0.xyxy + vec4(   0, -dy2,  dx1, -dy2);
	t03 = TEX0.xyxy + vec4( dx2, -dy2, -dx2, -dy1);
	t04 = TEX0.xyxy + vec4(-dx1, -dy1,    0, -dy1);
	t05 = TEX0.xyxy + vec4( dx1, -dy1,  dx2, -dy1);
	t06 = TEX0.xyxy + vec4(-dx2,    0, -dx1,    0);

	t07 = TEX0.xyxy + vec4( dx1,    0,  dx2,    0);
	t08 = TEX0.xyxy + vec4(-dx2,  dy1, -dx1,  dy1);
	t09 = TEX0.xyxy + vec4(   0,  dy1,  dx1,  dy1);
	t10 = TEX0.xyxy + vec4( dx2,  dy1, -dx2,  dy2);
	t11 = TEX0.xyxy + vec4(-dx1,  dy2,    0,  dy2);
	t12 = TEX0.xyxy + vec4( dx1,  dy2,  dx2,  dy2);
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
COMPAT_VARYING vec4 t01;
COMPAT_VARYING vec4 t02;
COMPAT_VARYING vec4 t03;
COMPAT_VARYING vec4 t04;
COMPAT_VARYING vec4 t05;
COMPAT_VARYING vec4 t06;
COMPAT_VARYING vec4 t07;
COMPAT_VARYING vec4 t08;
COMPAT_VARYING vec4 t09;
COMPAT_VARYING vec4 t10;
COMPAT_VARYING vec4 t11;
COMPAT_VARYING vec4 t12;

//standard texture sample looks like this: COMPAT_COMPAT_TEXTURE(Texture, TEX0.xy);
#define SourceSize		vec4(TextureSize, 1.0 / TextureSize)

#define s2(a, b)				temp = a; a = min(a, b); b = max(temp, b);
#define t2(a, b)				s2(v[a], v[b]);
#define t24(a, b, c, d, e, f, g, h)			t2(a, b); t2(c, d); t2(e, f); t2(g, h);
#define t25(a, b, c, d, e, f, g, h, i, j)		t24(a, b, c, d, e, f, g, h); t2(i, j);

void main()
{
  vec3 v[25];
  /*
  // Add the pixels which make up our window to the pixel array.
  for(int dX = -2; dX <= 2; ++dX) {
    for(int dY = -2; dY <= 2; ++dY) {
      vec2 offset = vec2(float(dX), float(dY));

      // If a pixel in the window is located at (x+dX, y+dY), put it at index (dX + R)(2R + 1) + (dY + R) of the
      // pixel array. This will fill the pixel array, with the top left pixel of the window at pixel[0] and the
      // bottom right pixel of the window at pixel[N-1].
      v[(dX + 2) * 5 + (dY + 2)] = COMPAT_TEXTURE(Texture, TEX0.xy + offset * SourceSize.zw).rgb;
    }
  }
  */
  v[0]  = COMPAT_TEXTURE(Texture, t01.xy).rgb;
  v[5]  = COMPAT_TEXTURE(Texture, t01.zw).rgb;
  v[10] = COMPAT_TEXTURE(Texture, t02.xy).rgb;
  v[15] = COMPAT_TEXTURE(Texture, t02.zw).rgb;
  v[20] = COMPAT_TEXTURE(Texture, t03.xy).rgb;
  v[1]  = COMPAT_TEXTURE(Texture, t03.zw).rgb;
  v[6]  = COMPAT_TEXTURE(Texture, t04.xy).rgb;
  v[11] = COMPAT_TEXTURE(Texture, t04.zw).rgb;
  v[16] = COMPAT_TEXTURE(Texture, t05.xy).rgb;
  v[21] = COMPAT_TEXTURE(Texture, t05.zw).rgb;
  v[2]  = COMPAT_TEXTURE(Texture, t06.xy).rgb;
  v[7]  = COMPAT_TEXTURE(Texture, t06.zw).rgb;
  v[12] = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
  v[17] = COMPAT_TEXTURE(Texture, t07.xy).rgb;
  v[22] = COMPAT_TEXTURE(Texture, t07.zw).rgb;
  v[3]  = COMPAT_TEXTURE(Texture, t08.xy).rgb;
  v[8]  = COMPAT_TEXTURE(Texture, t08.zw).rgb;
  v[13] = COMPAT_TEXTURE(Texture, t09.xy).rgb;
  v[18] = COMPAT_TEXTURE(Texture, t09.zw).rgb;
  v[23] = COMPAT_TEXTURE(Texture, t10.xy).rgb;
  v[4]  = COMPAT_TEXTURE(Texture, t10.zw).rgb;
  v[9]  = COMPAT_TEXTURE(Texture, t11.xy).rgb;
  v[14] = COMPAT_TEXTURE(Texture, t11.zw).rgb;
  v[19] = COMPAT_TEXTURE(Texture, t12.xy).rgb;
  v[24] = COMPAT_TEXTURE(Texture, t12.zw).rgb;



  vec3 temp;

  t25(0, 1,			3, 4,		2, 4,		2, 3,		6, 7);
  t25(5, 7,			5, 6,		9, 7,		1, 7,		1, 4);
  t25(12, 13,		11, 13,		11, 12,		15, 16,		14, 16);
  t25(14, 15,		18, 19,		17, 19,		17, 18,		21, 22);
  t25(20, 22,		20, 21,		23, 24,		2, 5,		3, 6);
  t25(0, 6,			0, 3,		4, 7,		1, 7,		1, 4);
  t25(11, 14,		8, 14,		8, 11,		12, 15,		9, 15);
  t25(9, 12,		13, 16,		10, 16,		10, 13,		20, 23);
  t25(17, 23,		17, 20,		21, 24,		18, 24,		18, 21);
  t25(19, 22,		8, 17,		9, 18,		0, 18,		0, 9);
  t25(10, 19,		1, 19,		1, 10,		11, 20,		2, 20);
  t25(2, 11,		12, 21,		3, 21,		3, 12,		13, 22);
  t25(4, 22,		4, 13,		14, 23,		5, 23,		5, 14);
  t25(15, 24,		6, 24,		6, 15,		7, 16,		7, 19);
  t25(3, 11,		5, 17,		11, 17,		9, 17,		4, 10);
  t25(6, 12,		7, 14,		4, 6,		4, 7,		12, 14);
  t25(10, 14,		6, 7,		10, 12,		6, 10,		6, 17);
  t25(12, 17,		7, 17,		7, 10,		12, 18,		7, 12);
  t24(10, 18,		12, 20,		10, 20,		10, 12);

  FragColor = vec4(v[12], 1.0);
}
#endif
