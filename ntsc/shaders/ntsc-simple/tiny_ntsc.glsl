#version 110
/*
   TINY_NTSC DariusG 2025-2026 

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
// Parameter lines go here:

#define PI 3.14159


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
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 ogl2pos;

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
   TEX0.xy = TexCoord.xy*1.0001;
   scale = SourceSize.xy/InputSize.xy;
   invdims = 1.0/TextureSize.xy;
   ogl2pos = TEX0.xy*TextureSize.xy;
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
out lowfp vec4 FragColor;
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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 ogl2pos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define iTime float(FrameCount)

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float WARP;
#else
#define WARP 0.04
#endif

// we tell it to pass chroma "info" every four sample pixels at PI/2.0 (90 degrees)
#define pi_two PI/2.0
#define pi_four PI/4.0

vec3 rgb_yiq(vec3 color)
{
    float Y = 0.3*color.r+0.59*color.g+0.11*color.b;
    float I = 0.6*color.r-0.275*color.g-0.32*color.b;
    float Q = 0.21*color.r-0.52*color.g+0.31*color.b;
    return vec3(Y,I,Q);
}
vec3 yiq_rgb(vec3 res){
 /* --- Decode: YIQ -> RGB --- */
    vec3 rgb;
    float Y = res.r; float I = res.g; float Q= res.b;
    rgb.r = Y + 0.956 * I + 0.621 * Q;
    rgb.g = Y - 0.272 * I - 0.647 * Q;
    rgb.b = Y - 1.106 * I + 1.703 * Q;
return rgb;
}

// "lines" in analogue is time actually, assuming clock 14.36 mhz
// 14.36 mhz is 910 "lines" but need 2 pixels to carry chroma
// 7.18 mhz are 455, maximum NTSC horiz. "resolution", 227,5 chroma "pixels".
// part of 7.18 carries sound, h_sync etc.
// total Y lines 6.0 mhz 2 chroma samples (14.36 clock)
// Y 4.2 mhz ~ 0.66 of full x 4 = 6 approxim. 
// a further part of it will be low passed to remove chroma
// so actual Y is 3.2-3.4 mhz.
// I 1.5 mhz ~ 1/5 of full, x 4 = 16 approxim.
// Q 0.55 mhz ~ 1/11 of full, x 4 = 44 approxim.
// keep them both ~1.0 mhz for speed
// as color clock is 3.58, we got 4 "910" pixels sharing color at 14.36

void main()
{
    vec2 dx = vec2(invdims.x,0.0);
    vec3 final = vec3(0.0);
    float sumY = 0.0;
    float sumI = 0.0;
    float sumQ = 0.0;
// one frame is 29.97 in ntsc so iTime/2.0 as retroarch will do 60.    
    float crawl = mod(iTime/2.0,4.0);
    float pixel_x = floor(ogl2pos.x)*4.0;
    float line_off = floor(ogl2pos.y)*2.0;

// maximum Chroma blur width, assuming 1.0 mhz at 4x input scale
// 6.0 mhz : 1.0 mhz * 4.0 scale = 24.0 samples sharing color
// it could be 6 at 1x scale but blurry and undefined, not as in real analogue
for (float x=-12.0; x<12.0; x=x+1.0)
{
   vec3 res = COMPAT_TEXTURE(Source,vTexCoord + dx*x).rgb;
   vec3 yiq = rgb_yiq(res);
// line_off: ntsc will alter phase every vertical line   
   float angle = (pixel_x + x + crawl + line_off)*pi_two;
   float cs = cos(angle);
   float sn = sin(angle);
   float hamm = cos(x*pi_four);
// merge all in one "cable"
   float signal = dot(vec3(yiq),vec3(1.0,cs,sn));
// luma ~4.0 mhz is more crisp than chroma

// hamming: 1.0-sharp + sharp*cos*(PI/4.0);
   if(x>=-4.0 && x<4.0) { 
    float wY = 0.75+0.25*hamm; sumY += wY;
    final.r += signal*wY;
    }

    float wc = 0.9+0.1*hamm; 
    // saturation paramater can be injected here
    final.g += signal*cs*2.0*wc;
    final.b += signal*sn*2.0*wc;
    sumI += wc;
    sumQ += wc;
}
   final.r /= sumY;
   final.g /= sumI;
   final.b /= sumQ;
   
   FragColor.rgb = yiq_rgb(final);
} 
#endif
