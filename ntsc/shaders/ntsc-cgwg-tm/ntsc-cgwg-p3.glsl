#version 110

/*
    NTSC encoding artifact shader

    This shader renders the input image with added NTSC artifacts, by
    transforming the input into an NTSC signal, then decoding it again.
    It was originally developed in this forum thread:

    http://board.byuu.org/viewtopic.php?f=10&t=1494

    Copyright (C) 2010-2012 cgwg and Themaister

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
*/

#pragma parameter crawl "Chroma Crawl Frequency" 2.0 1.0 4.0 1.0
// begin params
#define PI 3.14159265

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
    TEX0.xy = TexCoord.xy*1.0001;
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
uniform COMPAT_PRECISION float crawl;

#else

#define crawl

#endif

#define TEX2D(v) COMPAT_TEXTURE(Source, (v))

      void main()
      {
        mat3 rgb2yuv = mat3(0.299,-0.14713, 0.615,
                 0.587,-0.28886,-0.51499,
                 0.114, 0.436  ,-0.10001);
        mat3 yuv2rgb = mat3(1.0, 1.0, 1.0,
                 0.0,-0.39465,2.03211,
                 1.13983,-0.58060,0.0);


        vec4 sum   = vec4(0.0);

        float wid = 3.0;
        vec4 c1 = vec4(exp(-1.0/wid/wid));
        vec4 c2 = vec4(exp(-4.0/wid/wid));
        vec4 c3 = vec4(exp(-9.0/wid/wid));
        vec4 c4 = vec4(exp(-16.0/wid/wid));
        vec4 norm = 1.0 / (vec4(1.0) + vec4(2.0)*(c1+c2+c3+c4));

        vec2 xy = vTexCoord;
        float onex = 1.0 / SourceSize.x;

        sum += TEX2D(xy + vec2(-4.0 * onex,  0.0)) * c4;
        sum += TEX2D(xy + vec2(-3.0 * onex,  0.0)) * c3;
        sum += TEX2D(xy + vec2(-2.0 * onex,  0.0)) * c2;
        sum += TEX2D(xy + vec2(-1.0 * onex,  0.0)) * c1;
        sum += TEX2D(xy);
        sum += TEX2D(xy + vec2(+1.0 * onex,  0.0)) * c1;
        sum += TEX2D(xy + vec2(+2.0 * onex,  0.0)) * c2;
        sum += TEX2D(xy + vec2(+3.0 * onex,  0.0)) * c3;
        sum += TEX2D(xy + vec2(+4.0 * onex,  0.0)) * c4;

        float y = (rgb2yuv * TEX2D(xy).rgb).x;
        vec2 uv = (rgb2yuv * (sum.rgb * norm.rgb)).yz;

        FragColor = vec4(yuv2rgb * vec3(y, uv), 0.0);
      }
#endif
