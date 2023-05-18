/*
   Lanczos3 - passX 

   Multipass code by Hyllian 2022.

*/


/*
   Copyright (C) 2010 Team XBMC
   http://www.xbmc.org
   Copyright (C) 2011 Stefanos A.
   http://www.opentk.com

This Program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This Program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with XBMC; see the file COPYING.  If not, write to
the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
http://www.gnu.org/copyleft/gpl.html
*/


#pragma parameter LANCZOS3_ANTI_RINGING "Lanczos3 Anti-Ringing [ OFF | ON ]" 1.0 0.0 1.0 1.0
#define AR_STRENGTH 0.8

#define FIX(c) (max(abs(c), 1e-5))

const float PI     = 3.1415926535897932384626433832795;
const float radius = 3.0;


#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE(c,d) texture(c,d)
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision COMPAT_PRECISION float;
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
#define COMPAT_TEXTURE texture2D
#define COMPAT_VARYING varying
#define FragColor gl_FragColor

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
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float LANCZOS3_ANTI_RINGING;


#else
#define LANCZOS3_ANTI_RINGING 1.0

#endif



vec3 weight3(float x)
{
   // Looks like "sample" is a reserved word in slang.
   vec3 Sample = FIX(2.0 * PI * vec3(x - 1.5, x - 0.5, x + 0.5));

   // Lanczos3. Note: we normalize outside this function, so no point in multiplying by radius.
   return sin(Sample) * sin(Sample / radius) / (Sample * Sample);
}
	

void main()
{
    vec2 ps = SourceSize.zw;
    vec2 pos = vTexCoord.xy + ps * vec2(0.5, 0.0);
    vec2 fp = fract(pos / ps);

    vec2 xystart = (-2.5 - fp) * ps + pos;

    float ypos = xystart.y  + ps.y * 3.0;

    vec3 C0 = COMPAT_TEXTURE(Source, vec2(xystart.x             , ypos)).rgb;
    vec3 C1 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x      , ypos)).rgb;
    vec3 C2 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x * 2.0, ypos)).rgb;
    vec3 C3 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x * 3.0, ypos)).rgb;
    vec3 C4 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x * 4.0, ypos)).rgb;
    vec3 C5 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x * 5.0, ypos)).rgb; 

    vec3 w1 = weight3(0.5 - fp.x * 0.5);
    vec3 w2 = weight3(1.0 - fp.x * 0.5);

    float sum   = dot(  w1, vec3(1)) + dot(  w2, vec3(1));
    w1   /= sum;
    w2   /= sum;

    vec3 color = mat3( C0, C2, C4 ) * w1 +  mat3( C1, C3, C5) * w2;

    // Anti-ringing
    if (LANCZOS3_ANTI_RINGING == 1.0)
    {
        vec3 aux = color;
        vec3 min_sample = min(min(C1, C2), min(C3, C4));
        vec3 max_sample = max(max(C1, C2), max(C3, C4));
        color = clamp(color, min_sample, max_sample);
        color = mix(aux, color, AR_STRENGTH*step(0.0, (C1-C2)*(C3-C4)));
    }

    FragColor = vec4(color, 1.0);
}
#endif
