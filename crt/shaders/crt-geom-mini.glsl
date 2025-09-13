#version 110

/*
   CRT-Geom replica by DariusG 2024.
   This shader should run well on gpu's with around 60-70 gflops.
   
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
#pragma parameter CURV "CRT-Geom Curvature" 1.0 0.0 1.0 1.0
#pragma parameter scanlines "CRT-Geom Scanline Weight" 0.3 0.0 0.5 0.05
#pragma parameter MASK "CRT-Geom Dotmask Strength" 0.15 0.0 0.5 0.05
#pragma parameter INTERL "CRT-Geom Interlacing Simulation" 1.0 0.0 1.0 1.0
#pragma parameter lum "CRTGeom Luminance" 0.0 0.0 1.0 0.01
#pragma parameter SAT "CRT-Geom Saturation" 1.0 0.0 2.0 0.05

#define pi 3.1415926
#define tau 6.2831852
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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float maskpos;

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    scale = SourceSize.xy/InputSize.xy;
    maskpos = TEX0.x*OutputSize.x*scale.x*pi;
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
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float maskpos;

// compatibility #defines
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float scanlines;
uniform COMPAT_PRECISION float CURV;
uniform COMPAT_PRECISION float MASK;
uniform COMPAT_PRECISION float SAT;
uniform COMPAT_PRECISION float INTERL;
uniform COMPAT_PRECISION float lum;
#else
#define scanlines 0.5
#define CURV 1.0
#define MASK 0.2
#define SAT 1.0
#define INTERL 1.0
#define lum 0.0
#endif

#define timer mod(float(FrameCount),2.0)

vec2 Warp(vec2 coord)
{
        vec2 CURVATURE_DISTORTION = vec2(0.12, 0.25);
        // Barrel distortion shrinks the display area a bit, this will allow us to counteract that.
        vec2 barrelScale = vec2(0.97,0.945);
        coord -= vec2(0.5);
        float rsq = coord.x*coord.x + coord.y*coord.y;
        coord += coord * (CURVATURE_DISTORTION * rsq);
        coord *= barrelScale;
        if (abs(coord.x) >= 0.5 || abs(coord.y) >= 0.5)
                coord = vec2(-1.0);             // If out of bounds, return an invalid value.
        else
        {
                coord += vec2(0.5);
        }

        return coord;
}

#define one 1.384615
#define two 3.230769
// precalculated Lanczos weight (approximate)
#define w0   1.174
#define w1  -0.095
#define w2   0.007

#define TEX(p) COMPAT_TEXTURE(Source,p).rgb

void main()
{
vec3 res = vec3(0.0);
vec2 dx = vec2(SourceSize.z,0.0); //sharpness
vec2 pos, corn;
if(CURV == 1.0){
 pos = Warp(vTexCoord*scale);
 corn = min(pos, 1.0-pos);    // This is used to mask the rounded
     corn.x = 0.0001/corn.x;      // corners later on
pos /= scale;
}
else pos = vTexCoord;

vec2 xy = pos;
xy -= dx;
vec2 near = floor(pos*SourceSize.xy)+0.5;
vec2 f = pos*SourceSize.xy - near;

xy.y = (near.y + 16.0*f.y*f.y*f.y*f.y*f.y)*SourceSize.w;    
if (InputSize.y>300.0 && INTERL == 1.0) xy.y += SourceSize.w*timer;
//  lanczos approximation in 5 taps
    res += TEX(xy)*w0;
    res += TEX(xy - one*dx).rgb*w1; 
    res += TEX(xy + one*dx).rgb*w1;
    res += TEX(xy + two*dx).rgb*w2;
    res += TEX(xy - two*dx).rgb*w2;

    res = clamp(res,vec3(0.0),vec3(1.0));

    float a = dot(vec3(0.25),res);
    float s = mix(scanlines,scanlines*0.6,a);

    float texsize = 1.0;
    float fp = 0.5;
    if (InputSize.y > 300.0) texsize = 0.5;

    if (INTERL == 1.0 && InputSize.y > 300.0) 
    {
    fp = timer >0.0 ? 0.5+fp :0.5;
    }

    float mask = MASK*sin(maskpos)+1.0-MASK;
    res *= mask;
    res = sqrt(res);
    float scan = s*sin(((pos.y*SourceSize.y+0.15)*texsize-fp)*tau)+1.0-s+lum;
    res *= scan;
    //res *= 1.5;
    float l = dot(vec3(0.29, 0.6, 0.11), res);
    res  = mix(vec3(l), res, SAT);
    
    if (corn.y <= corn.x && CURV == 1.0 || corn.x < 0.0001 && CURV ==1.0 )res = vec3(0.0);
    FragColor.rgb = (res);
}
#endif
