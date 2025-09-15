// version directive if necessary

// blendSoftlight
// based on:
// https://github.com/jamieowen/glsl-blend for blendSoftlight
//
// The MIT License (MIT) Copyright (c) 2015 Jamie Owen
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Same MIT License applies to contributions from Ben Reaves
//

#pragma parameter OverlayMix "Overlay Mix" 1.0 0.0 1.0 0.05
#pragma parameter SCALE "Box Scale" 4.0 0.25 4.0 0.05
#pragma parameter ASPECTRATIO "Aspect Ratio" 87.0 43.0 87.0 44.0
#pragma parameter BorderBool "Normal Borders" 0.0 0.0 1.0 1.0
#pragma parameter ThickBool "Thick Borders" 0.0 0.0 1.0 1.0
#pragma parameter ThinBool "Thin Borders" 0.0 0.0 1.0 1.0

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
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float SCALE;
uniform COMPAT_PRECISION float ASPECTRATIO;
#else
#define SCALE 1.0
#define ASPECTRATIO 43.0
#endif

void main()
{
    gl_Position =   MVPMatrix * VertexCoord;
    if (ASPECTRATIO == 43.0) {
        TEX0.xy = TexCoord.xy;
    }
    else if (ASPECTRATIO == 87.0) {
        vec2 box_scale = vec2(SCALE + 0.06, SCALE + 0.06);
        vec2 scale = (OutputSize.xy / SourceSize.xy) / box_scale;
        vec2 middle =   vec2(0.5, 0.5) * SourceSize.xy / TextureSize.xy;
        vec2 diff   =   TexCoord.xy - middle;
        TEX0.xy     =   (middle + diff * scale);
    }
    else {
        TEX0.xy = TexCoord.xy;
    }
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
out COMPAT_PRECISION vec4 FragColor;
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
uniform sampler2D BORDER;
uniform sampler2D BORDERTHICK;
uniform sampler2D BORDERTHIN;
uniform sampler2D overlay;
uniform sampler2D overlay2;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float OverlayMix;
uniform COMPAT_PRECISION float ASPECTRATIO;
uniform COMPAT_PRECISION float BorderBool;
uniform COMPAT_PRECISION float ThickBool;
uniform COMPAT_PRECISION float ThinBool;
#else
#define OverlayMix 1.0
#define ASPECTRATIO 43.0
#define BorderBool 0.0
#define ThickBool 0.0
#define ThinBool 0.0
#endif

float blendSoftlight(float base, float blend) {
    return (blend<0.5)?(2.0*base*blend+base*base*(1.0-2.0*blend)):(sqrt(base)*(2.0*blend-1.0)+2.0*base*(1.0-blend));
}

void main()
{

    vec4 frame     = COMPAT_TEXTURE(Source, vTexCoord).rgba;
    vec4 softlight = COMPAT_TEXTURE(overlay, vTexCoord).rgba;
    if ( OverlayMix < 1.0 ){
        softlight   = COMPAT_TEXTURE(overlay2, vTexCoord).rgba;
        softlight.a = OverlayMix;
    }

    vec4 ImageFinal  = frame;

    ImageFinal.r = blendSoftlight(frame.r,softlight.r);
    ImageFinal.g = blendSoftlight(frame.g,softlight.g);
    ImageFinal.b = blendSoftlight(frame.b,softlight.b);
    ImageFinal.a = blendSoftlight(frame.a,softlight.a);
    ImageFinal   = mix(frame,ImageFinal,softlight.a);
    // ImageFinal   = mix(frame,clamp(ImageFinal,0.0,OverlayMix),softlight.a);

    // Aspect ratio 8:7 will always have a normal border applied
    // otherwise glitching will occur on the edges
    if (ASPECTRATIO == 87.0 || BorderBool == 1.0 || ThickBool == 1.0 || ThinBool == 1.0) {
        vec4 background = COMPAT_TEXTURE(BORDER, vTexCoord);
        if(ThickBool == 1.0){
            background = COMPAT_TEXTURE(BORDERTHICK, vTexCoord);
        }
        if(ThinBool == 1.0){
            background = COMPAT_TEXTURE(BORDERTHIN, vTexCoord);
        }
        FragColor = vec4(mix(ImageFinal, background, background.a));
    }
    else{
        FragColor = vec4(ImageFinal);
    }
} 
#endif
