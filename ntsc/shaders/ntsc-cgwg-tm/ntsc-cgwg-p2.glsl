#version 110

/*
    NTSC encoding artifact shader

    This shader renders the input image with added NTSC artifacts, by
    transforming the input into an NTSC signal, then decoding it again.
    It was originally developed in this forum thread:

    http://board.byuu.org/viewtopic.php?f=10&t=1494

    Copyright (C) 2010-2012 cgwg and Themaister
    Port by DariusG 2023
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
*/


// begin params
#define PI 3.14159265
#define PIt 4.1887902 // 4.0*PI/3.0

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
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
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float xres;

#else

#define xres 54.0

#endif


// ------------

#define TEX2D(c) texture2D(Source,(c))

const mat3 yuv2rgb = mat3(1.0, 1.0, 1.0,
                 0.0,-0.39465,2.03211,
                 1.13983,-0.58060,0.0);

      void main()
      {
        vec2 pos = vTexCoord;
        vec2 onetexel = SourceSize.zw;

        vec2 pos_f = fract(pos * SourceSize.xy);
        vec2 posp = floor(pos * SourceSize.xy)+vec2(0.5);
        pos = posp *onetexel;
        
        float f = float (FrameCount);
        float offset = fract(f*0.5);
        float pospxy_o = posp.x+posp.y/2.0+offset;

        vec4 phases =  (vec4(0.0,0.25,0.5,0.75) + vec4(pospxy_o)) *PIt;
        vec4 phasesl = (vec4(0.0,0.25,0.5,0.75) + vec4(-1.0+pospxy_o)) *PIt;
        vec4 phasesr = (vec4(0.0,0.25,0.5,0.75) + vec4( 1.0+pospxy_o)) *PIt;
        
        vec4 phsin = sin(phases);
        vec4 phcos = cos(phases);
        vec4 phsinl= sin(phasesl);
        vec4 phcosl= cos(phasesl);
        vec4 phsinr= sin(phasesr);
        vec4 phcosr= cos(phasesr);
        vec4 one = vec4(1.0);

        vec4 res = TEX2D(pos)*2.3-0.65;
        vec4 resr= TEX2D(pos + vec2(-onetexel.x,0.0))*2.3-0.65;
        vec4 resl= TEX2D(pos + vec2( onetexel.x,0.0))*2.3-0.65;

        vec3 yuva = vec3((dot(resr.zw,one.zw) + dot(res.xyz,one.xyz) + 0.5*(resr.y+res.w))/6.0, 
                         (dot(resr.zw,phsinl.zw) + dot(res.xyz,phsin.xyz) + 0.5*(resr.y*phsinl.y+res.w*phsin.w))/3.0, 
                         (dot(resr.zw,phcosl.zw) + dot(res.xyz,phcos.xyz) + 0.5*(resr.y*phcosl.y+res.w*phcos.w))/3.0);
 
        vec3 yuvb = vec3((resr.w*one.w+dot(res.xyzw,one.xyzw) +0.5*(resr.z+resl.x))/6.0, 
                         (resr.w*phsinl.w+dot(res.xyzw,phsin.xyzw)+0.5*(resr.z*phsinl.z+resl.x*phsinr.x))/3.0, 
                         (resr.w*phcosl.w+dot(res.xyzw,phcos.xyzw)+0.5*(resr.z*phcosl.z+resl.x*phcosr.x))/3.0);

        vec3 yuvc = vec3((resl.x*one.x+dot(res.xyzw,one.xyzw) +0.5*(resr.w+resl.y))/6.0, 
                         (resl.x*phsinr.x+dot(res.xyzw,phsin.xyzw)+0.5*(resr.w*phsinl.w+resl.y*phsinr.y))/3.0, 
                         (resl.x*phcosr.x+dot(res.xyzw,phcos.xyzw)+0.5*(resr.w*phcosl.w+resl.y*phcosr.y))/3.0);

        vec3 yuvd = vec3((dot(resl.xy,one.xy)+dot(res.yzw,one.yzw) +0.5*(res.x+resl.z))/6.0, 
                         (dot(resl.xy,phsinr.xy)+dot(res.yzw,phsin.yzw)+0.5*(res.x*phsin.x+resl.z*phsinr.z))/3.0, 
                         (dot(resl.xy,phcosr.xy)+dot(res.yzw,phcos.yzw)+0.5*(res.x*phcos.x+resl.z*phcosr.z))/3.0);

        if (pos_f.x < 0.25)
          FragColor = vec4(yuv2rgb*yuva, 0.0);
        else if (pos_f.x < 0.5)
          FragColor = vec4(yuv2rgb*yuvb, 0.0);
        else if (pos_f.x < 0.75)
          FragColor = vec4(yuv2rgb*yuvc, 0.0);
        else
          FragColor = vec4(yuv2rgb*yuvd, 0.0);
      }
#endif
