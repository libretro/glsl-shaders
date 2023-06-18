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

#pragma parameter S16_ANTI_RINGING "Spline16 Anti-Ringing [ OFF | ON ]" 1.0 0.0 1.0 1.0


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
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float S16_ANTI_RINGING;

#else
#define S16_ANTI_RINGING 1.0

#endif

float weight(float x)
{
   x = abs(x);

   if (x < 1.0)
   {
      return
         (
          ((x - 9.0 / 5.0) * x - 1.0 / 5.0 ) * x + 1.0
         );
   }
   else if ((x >= 1.0) && (x < 2.0))
   {
      return
         (
          (( -1.0 / 3.0 * (x - 1.0) + 4.0 / 5.0 ) * (x - 1.0) - 7.0 / 15.0 ) * (x - 1.0)
         );
   }
   else
   {
      return 0.0;
   }
}

vec4 weight4(float x)
{
   return vec4(
         weight(x - 2.0),
         weight(x - 1.0),
         weight(x),
         weight(x + 1.0)
         );
}

   

void main()
{
    vec2 ps = SourceSize.zw;
    vec2 pos = vTexCoord.xy + ps * vec2(0.5, 0.0);
    vec2 fp = fract(pos / ps);

    vec2 xystart = (-1.5 - fp) * ps + pos;

    float ypos = xystart.y  + ps.y * 2.0;

    vec4 C0 = COMPAT_TEXTURE(Source, vec2(xystart.x             , ypos));
    vec4 C1 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x      , ypos));
    vec4 C2 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x * 2.0, ypos));
    vec4 C3 = COMPAT_TEXTURE(Source, vec2(xystart.x + ps.x * 3.0, ypos));

    vec4 w = weight4(1.0 - fp.x);

    float sum   = dot(  w, vec4(1.0));
    w   /= sum;

    vec4 color = mat4( C0, C1, C2, C3 ) * w;

    // Anti-ringing
    if (S16_ANTI_RINGING == 1.0)
    {
        vec3 aux = color.rgb;
        vec3 min_sample = min(min(C0.rgb, C1.rgb), min(C2.rgb, C3.rgb));
        vec3 max_sample = max(max(C0.rgb, C1.rgb), max(C2.rgb, C3.rgb));
        color.rgb = clamp(color.rgb, min_sample, max_sample);
        color.rgb = mix(aux, color.rgb, step(0.0, (C0.rgb-C1.rgb)*(C2.rgb-C3.rgb)));
    }

    FragColor = color;
}
#endif
