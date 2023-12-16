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

  #define TEX2D(c) COMPAT_TEXTURE(Source,(c))
  #define PI 3.14159265

      void main()
      {
        vec2 xy = vTexCoord;

        vec2 xyp = xy * SourceSize.xy * 4.0 * PI / 3.0;
        xyp.y = xyp.y / 2.0 + 2.0 * PI / 3.0 * mod(float(FrameCount),crawl);

        vec4 rgb = TEX2D(xy);

        mat3 rgb2yuv = mat3(0.299,-0.14713, 0.615,
                 0.587,-0.28886,-0.51499,
                 0.114, 0.436  ,-0.10001);

        vec3 yuv;
        yuv = rgb2yuv * rgb.rgb;

        float dx = PI/3.0;
        xyp.x = xyp.x ;
        float c0 = yuv.x + yuv.y * sin(xyp.x+xyp.y) + yuv.z*cos(xyp.x+xyp.y);
        float c1 = yuv.x + yuv.y * sin(xyp.x+xyp.y+dx) + yuv.z * cos(xyp.x+xyp.y+dx);
        rgb = TEX2D(xy + vec2(1.0/SourceSize.x *0.5, 0.0));
        yuv = rgb2yuv * rgb.rgb;
        float c2 = yuv.x + yuv.y * sin(xyp.x+xyp.y+2.0*dx) + yuv.z * cos(xyp.x+xyp.y+2.0*dx);
        float c3 = yuv.x + yuv.y * sin(xyp.x+xyp.y+3.0*dx) + yuv.z * cos(xyp.x+xyp.y+3.0*dx);

        FragColor = (vec4(c0,c1,c2,c3)+0.65)/2.3;
}
#endif
