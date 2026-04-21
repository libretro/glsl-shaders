#version 110

/*
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
*/

#pragma parameter SCAN_STR "SCANLINES STRENGTH" 0.4 0.0 0.5 0.05
#pragma parameter BEAM_LOW "SCANLINES BEAM LOW" 3.0 0.0 5.0 0.05  
#pragma parameter BEAM_HIGH "SCANLINES BEAM HIGH" 0.75 0.0 5.0 0.05  
#pragma parameter COLOR_BOOST "COLOR BOOST (BRIGHTNESS)" 1.5 1.0 5.0 0.05  

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
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float m_size;

#else
#define float m_size 1.0

#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    invdims = 1.0/TextureSize;
    scale = TextureSize/InputSize;
    maskpos = TEX0.xy*scale*OutputSize.xy;
    ogl2pos = TEX0.xy*TextureSize;    
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

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;

#define Source Texture
#define vTexCoord TEX0.xy

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BEAM_LOW;
uniform COMPAT_PRECISION float BEAM_HIGH;
uniform COMPAT_PRECISION float COLOR_BOOST;
uniform COMPAT_PRECISION float SCAN_STR;
#else
#define BEAM_LOW 4.0
#define BEAM_HIGH 1.0
#define COLOR_BOOST 1.0
#define SCAN_STR 0.5
#endif

#define GAMMA(color) color*color 
#define PI 3.14159265358979323846 
#define TAU 6.2831852

void main()
{   
    vec2 dx = vec2(invdims.x*0.5, 0.0);
    vec2 dy = vec2(0.0,invdims.y*0.5);

    vec2 near = floor(ogl2pos)+0.5;
    vec2 f = fract(ogl2pos);    
         f = f*f*(3.0-2.0*f);
         f.y = f.y*f.y;
         f.y = f.y*f.y;
    vec2 pos = (near + f)*invdims;     
    
    vec3 res1 = GAMMA(COMPAT_TEXTURE(Source,pos - dy - dx).rgb);
    vec3 res2 = GAMMA(COMPAT_TEXTURE(Source,pos - dy + dx).rgb);
    vec3 res3 = GAMMA(COMPAT_TEXTURE(Source,pos + dy - dx).rgb);
    vec3 res4 = GAMMA(COMPAT_TEXTURE(Source,pos + dy + dx).rgb);

    vec3 res01 = mix(res1, res2, f.x);
    vec3 res02 = mix(res3, res4, f.x);

    vec3 res = mix(res01, res02, f.y);
    float l = max(max(res.r, res.g), res.b);
    res *= COLOR_BOOST;
    // SCANLINES
    float s = SCAN_STR*sin(ogl2pos.y*TAU)+1.0-SCAN_STR;
    float beam = mix(BEAM_LOW, BEAM_HIGH, l);
    s = pow(s, beam);
    res *= s;

    FragColor.rgb = sqrt(res);
}
#endif