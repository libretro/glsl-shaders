/*
   Lanczos2 - passX 

   Multipass code by dariusG 2025.
*/


/*

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
COMPAT_VARYING vec2 ps;

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
    ps = 1.0/TextureSize.xy;
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
COMPAT_VARYING vec2 ps;

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

// Lanczos2 horizontal pass (optimized for speed on handhelds)

#define RADIUS 2.0
#define PI 3.1415926

// Cheaper weight function (Lanczos2: radius 2 instead of 3)
float weight2(float x) {
    x = abs(x);
    if (x == 0.0) return 1.0;
    if (x >= RADIUS) return 0.0;
    return (sin(PI * x) / (PI * x)) * (sin(PI * x / RADIUS) / (PI * x / RADIUS));
}

void main()
{
    vec2 pos = vTexCoord.xy;       // current position
    float fx = fract(pos.x / ps.x);

    // sample 4 texels around target pixel
    float xpos = floor(pos.x / ps.x - 1.0);
    float ypos = floor(pos.y / ps.y);

    vec2 base = vec2(xpos, ypos) * ps;

    vec3 C0 = COMPAT_TEXTURE(Source, base).rgb;
    vec3 C1 = COMPAT_TEXTURE(Source, base + vec2(ps.x, 0.0)).rgb;
    vec3 C2 = COMPAT_TEXTURE(Source, base + vec2(ps.x*2.0, 0.0)).rgb;
    vec3 C3 = COMPAT_TEXTURE(Source, base + vec2(ps.x*3.0, 0.0)).rgb;

    // weights for 4 samples (Lanczos2 kernel)
    float w0 = weight2(fx + 1.0);
    float w1 = weight2(fx);
    float w2 = weight2(1.0 - fx);
    float w3 = weight2(2.0 - fx);

    float sum = w0 + w1 + w2 + w3;
    w0 /= sum; w1 /= sum; w2 /= sum; w3 /= sum;

    vec3 color = C0*w0 + C1*w1 + C2*w2 + C3*w3;
   
    // --- Lightweight anti-ringing ---
    vec3 min_sample = min(min(C0, C1), min(C2, C3));
    vec3 max_sample = max(max(C0, C1), max(C2, C3));
    color = clamp(color, min_sample, max_sample);

    FragColor = vec4(color, 1.0);
}
#endif
