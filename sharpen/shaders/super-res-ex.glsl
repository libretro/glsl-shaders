/*
   Super-res shader - Shiandow

   Ported from Shiandow's code by Hyllian, 2016.

   This file is a part of MPDN Extensions.
   https://github.com/zachsaw/MPDN_Extensions
  
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3.0 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library.
*/   

#define round(c) floor(c + 0.5)

// -- Edge detection options -- 
#define strength 0.8
#define softness 0.3
#define acuity   100.0
#define radius   1.0
#define power    2.0

#define originalSize refTexSize

#define dxdy (1.0 / SourceSize.xy)
#define ddxddy (1.0 / originalSize)

#define sqr(x) dot(x,x)


// -- Input processing --
//Current high res value
#define Get(x,y)    (COMPAT_TEXTURE(refTex,ddxddy*(pos+vec2(x,y)+0.5)).xyz)
#define GetY(x,y)    (COMPAT_TEXTURE(Source,ddxddy*(pos+vec2(x,y)+0.5)).a)
//Downsampled result
#define Diff(x,y)     (COMPAT_TEXTURE(Source,ddxddy*(pos+vec2(x,y)+0.5)).xyz)

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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
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
uniform COMPAT_PRECISION vec2 REFTextureSize;
#define refTexSize REFTextureSize
uniform sampler2D Texture;
uniform sampler2D REFTexture;
#define refTex REFTexture
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

const vec3 Y = vec3(.2126, .7152, .0722);


float RGBtoYUV(vec3 color)
{
  return dot(color, Y);
}

void main()
{
    vec2 tex = vTexCoord;

    vec4 c0 = COMPAT_TEXTURE(refTex, tex);

    // Calculate position
    vec2 pos = tex * refTexSize.xy - 0.5;
    vec2 offset = pos - round(pos);
    pos -= offset;

    // Calculate faithfulness force
    float W = 0.;
    vec3 diff = vec3(0.0);
    vec3 stab = vec3(0.0);
    float var = 0.;

    float c0y = RGBtoYUV(c0.rgb);

	// Loop unrolled for better compatibility.

	float dI2 = sqr(acuity*(c0y - GetY(-1.,-1.)));
        float dXY2 = sqr(vec2(-1,-1) - offset);
        float w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff(-1,-1);
        stab += w*(c0.rgb - Get(-1,-1));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY(-1, 0)));
        dXY2 = sqr(vec2(-1, 0) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff(-1, 0);
        stab += w*(c0.rgb - Get(-1, 0));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY(-1, 1)));
        dXY2 = sqr(vec2(-1, 1) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff(-1, 1);
        stab += w*(c0.rgb - Get(-1, 1));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY( 0,-1)));
        dXY2 = sqr(vec2( 0,-1) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff( 0,-1);
        stab += w*(c0.rgb - Get( 0,-1));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY( 0, 0)));
        dXY2 = sqr(vec2( 0, 0) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff( 0, 0);
        stab += w*(c0.rgb - Get( 0, 0));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY( 0, 1)));
        dXY2 = sqr(vec2( 0, 1) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff( 0, 1);
        stab += w*(c0.rgb - Get( 0, 1));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY( 1,-1)));
        dXY2 = sqr(vec2( 1,-1) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff( 1,-1);
        stab += w*(c0.rgb - Get( 1,-1));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY( 1, 0)));
        dXY2 = sqr(vec2( 1, 0) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff( 1, 0);
        stab += w*(c0.rgb - Get( 1, 0));
        var += w*dI2;
        W += w;

	dI2 = sqr(acuity*(c0y - GetY( 1, 1)));
        dXY2 = sqr(vec2( 1, 1) - offset);
        w = exp(-dXY2/(2.*radius*radius))*pow(1. + dI2/power, - power);
        diff += w*Diff( 1, 1);
        stab += w*(c0.rgb - Get( 1, 1));
        var += w*dI2;
        W += w;

    diff /= W;
    stab /= W;
    var = (var / W) - sqr(acuity*stab);

    // Calculate edge statistics
    float varD = softness * sqr(acuity*stab);
    float varS = (1. - softness) * var;

    // Apply force
    c0.xyz -= strength*mix(diff, stab, softness);

   FragColor = vec4(c0);
} 
#endif
