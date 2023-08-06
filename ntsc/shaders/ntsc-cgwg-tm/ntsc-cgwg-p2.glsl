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


// ------------

#define iTime float (FrameCount/2)
#define TEX2D(c) texture2D(Source,(c))


const mat3 rgb2yuv = mat3(0.299,-0.14713, 0.615,
                 0.587,-0.28886,-0.51499,
                 0.114, 0.436  ,-0.10001);
const mat3 yuv2rgb = mat3(1.0, 1.0, 1.0,
                 0.0,-0.39465,2.03211,
                 1.13983,-0.58060,0.0);


const mat3 NTSC = mat3(1.5073,  -0.3725, -0.0832, 
                    -0.0275, 0.9350,  0.0670,
                     -0.0272, -0.0401, 1.1677);


      void main()
      {
        vec2 xy = vTexCoord;

        vec2 xyf = fract(xy * SourceSize.xy);
        vec2 xyp = floor(xy * SourceSize.xy)+vec2(0.5);
        xy = xyp / SourceSize.xy;
        float f = float (FrameCount);
        float offs = mod(f,crawl)/2.0;
        vec4 phases  = (vec4(0.0,0.25,0.5,0.75) + vec4(     xyp.x+xyp.y/2.0+offs)) *4.0*PI/3.0;
        vec4 phasesl = (vec4(0.0,0.25,0.5,0.75) + vec4(-1.0+xyp.x+xyp.y/2.0+offs)) *4.0*PI/3.0;
        vec4 phasesr = (vec4(0.0,0.25,0.5,0.75) + vec4( 1.0+xyp.x+xyp.y/2.0+offs)) *4.0*PI/3.0;
        vec4 phsin = sin(phases);
        vec4 phcos = cos(phases);
        vec4 phsinl= sin(phasesl);
        vec4 phcosl= cos(phasesl);
        vec4 phsinr= sin(phasesr);
        vec4 phcosr= cos(phasesr);
        vec4 phone = vec4(1.0);

        vec2 one = 1.0/SourceSize.xy;

        vec4 c = TEX2D(xy)*2.3-0.65;
        vec4 cl= TEX2D(xy + vec2(-one.x,0.0))*2.3-0.65;
        vec4 cr= TEX2D(xy + vec2( one.x,0.0))*2.3-0.65;
        
        vec3 yuva = vec3((dot(cl.zw,phone.zw)+dot(c.xyz,phone.xyz)+0.5*(cl.y+c.w))/6.0, (dot(cl.zw,phsinl.zw)+dot(c.xyz,phsin.xyz)+0.5*(cl.y*phsinl.y+c.w*phsin.w))/3.0, (dot(cl.zw,phcosl.zw)+dot(c.xyz,phcos.xyz)+0.5*(cl.y*phcosl.y+c.w*phcos.w))/3.0);

        vec3 yuvb = vec3((cl.w*phone.w+dot(c.xyzw,phone.xyzw)+0.5*(cl.z+cr.x))/6.0, (cl.w*phsinl.w+dot(c.xyzw,phsin.xyzw)+0.5*(cl.z*phsinl.z+cr.x*phsinr.x))/3.0, (cl.w*phcosl.w+dot(c.xyzw,phcos.xyzw)+0.5*(cl.z*phcosl.z+cr.x*phcosr.x))/3.0);

        vec3 yuvc = vec3((cr.x*phone.x+dot(c.xyzw,phone.xyzw)+0.5*(cl.w+cr.y))/6.0, (cr.x*phsinr.x+dot(c.xyzw,phsin.xyzw)+0.5*(cl.w*phsinl.w+cr.y*phsinr.y))/3.0, (cr.x*phcosr.x+dot(c.xyzw,phcos.xyzw)+0.5*(cl.w*phcosl.w+cr.y*phcosr.y))/3.0);

        vec3 yuvd = vec3((dot(cr.xy,phone.xy)+dot(c.yzw,phone.yzw)+0.5*(c.x+cr.z))/6.0, (dot(cr.xy,phsinr.xy)+dot(c.yzw,phsin.yzw)+0.5*(c.x*phsin.x+cr.z*phsinr.z))/3.0, (dot(cr.xy,phcosr.xy)+dot(c.yzw,phcos.yzw)+0.5*(c.x*phcos.x+cr.z*phcosr.z))/3.0);
        
        
        if (xyf.x < 0.25)
          FragColor = vec4(yuv2rgb*yuva, 0.0);
        else if (xyf.x < 0.5)
          FragColor = vec4(yuv2rgb*yuvb, 0.0);
        else if (xyf.x < 0.75)
          FragColor = vec4(yuv2rgb*yuvc, 0.0);
        else
          FragColor = vec4(yuv2rgb*yuvd, 0.0);
      }
#endif
