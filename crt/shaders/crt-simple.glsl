/*
 *  CRT-simple shader
 *
 *  Copyright (C) 2011 DOLLS. Based on cgwg's CRT shader.
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the Free
 *  Software Foundation; either version 2 of the License, or (at your option)
 *  any later version.
 *
 *
 */

#pragma parameter DISTORTION "Distortion" 0.12 0.0 0.30 0.01
#pragma parameter SCANLINE "Scanline Weight" 0.3 0.2 0.6 0.05
#pragma parameter INPUTGAMMA "Input Gamma" 2.4 0.0 4.0 0.05
#pragma parameter OUTPUTGAMMA "Output Gamma" 2.2 0.0 4.0 0.05
#pragma parameter MASK "Mask Brightness" 0.7 0.0 1.0 0.05
#pragma parameter SIZE "Mask Size" 1.0 1.0 2.0 1.0

// Uncomment to enable curvature (ugly)
#define CURVATURE        
#define PI 3.141592653589
#define outgamma 1.0 / OUTPUTGAMMA
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


uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{  
    gl_Position = MVPMatrix * VertexCoord;    
    TEX0.xy = TexCoord.xy*1.00001;
    scale = TextureSize.xy/InputSize.xy;
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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define Source Texture


uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 scale;

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float DISTORTION;
uniform COMPAT_PRECISION float INPUTGAMMA;
uniform COMPAT_PRECISION float OUTPUTGAMMA;
uniform COMPAT_PRECISION float SIZE;
uniform COMPAT_PRECISION float CURVATURE;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float MASK;

#else
#define DISTORTION 0.05
#define INPUTGAMMA 2.4
#define OUTPUTGAMMA 2.2
#define SIZE 1.0
#define CURVATURE 0.0
#define SCANLINE 0.3
#define MASK 0.3
#endif


     

        // Calculate the influence of a scanline on the current pixel.
        //
        // 'distance' is the distance in texture coordinates from the current
        // pixel to the scanline in question.
        // 'color' is the colour of the scanline at the horizontal location of
        // the current pixel.
        vec4 scanlineWeights(float distance, vec4 color)
        {
                // The "width" of the scanline beam is set as 2*(1 + x^4) for
                // each RGB channel.
                vec4 wid = 2.0 + 2.0 * pow(color, vec4(4.0));

                // The "weights" lines basically specify the formula that gives
                // you the profile of the beam, i.e. the intensity as
                // a function of distance from the vertical center of the
                // scanline. In this case, it is gaussian if width=2, and
                // becomes nongaussian for larger widths. Ideally this should
                // be normalized so that the integral across the beam is
                // independent of its width. That is, for a narrower beam
                // "weights" should have a higher peak at the center of the
                // scanline than for a wider beam.
                vec4 weights = vec4(distance / SCANLINE);
                return 1.4 * exp(-pow(weights * inversesqrt(0.5 * wid), wid)) / (0.6 + 0.2 * wid);
        }


vec2 Distort(vec2 coord)
{
        vec2 CURVATURE_DISTORTION = vec2(DISTORTION, DISTORTION*1.5);
        // Barrel distortion shrinks the display area a bit, this will allow us to counteract that.
        vec2 barrelScale = 1.0 - (0.23 * CURVATURE_DISTORTION);
        coord *= TextureSize/InputSize;
        coord -= vec2(0.5);
        float rsq = coord.x * coord.x + coord.y * coord.y;
        coord += coord * (CURVATURE_DISTORTION * rsq);
        coord *= barrelScale;
        if (abs(coord.x) >= 0.5 || abs(coord.y) >= 0.5)
                coord = vec2(-1.0);             // If out of bounds, return an invalid value.
        else
        {
                coord += vec2(0.5);
                coord /= TextureSize/InputSize;
        }

        return coord;
}
void main()
{
        // Texture coordinates of the texel containing the active pixel.
              vec2 abspos = TEX0.xy*SourceSize.xy*scale;
        vec2 xy;

        #ifdef CURVATURE
                xy = Distort(TEX0.xy); float xblur = xy.x;
        #else
                xy = TEX0.xy;
        #endif
                // Of all the pixels that are mapped onto the texel we are
                // currently rendering, which pixel are we currently rendering?
                vec2 ratio_scale = xy * SourceSize.xy - 0.5;
                vec2 uv_ratio = fract(ratio_scale);

                // Snap to the center of the underlying texel.
                xy = (floor(ratio_scale) + 0.5) / SourceSize.xy;
                xy.x = xblur;
                // Calculate the effective colour of the current and next
                // scanlines at the horizontal location of the current pixel.
                vec4 col  = COMPAT_TEXTURE(Source,xy); 
                col=pow(col,vec4(INPUTGAMMA));
                vec4 col2 = COMPAT_TEXTURE(Source,xy + vec2(0.0, SourceSize.w)); 
                col2=pow(col2,vec4(INPUTGAMMA));

                // Calculate the influence of the current and next scanlines on
                // the current pixel.
                vec4 weights  = scanlineWeights(uv_ratio.y, col);
                vec4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

                vec3 mul_res  = (col * weights + col2 * weights2).rgb;
                
                // dot-mask emulation:
                vec3 dotMaskWeights = mix(vec3(MASK), vec3(1.0),fract(gl_FragCoord.x*0.5/SIZE));

                mul_res *= dotMaskWeights;

                FragColor = vec4(vec3(pow(mul_res, vec3(outgamma))), 1.0);
        }

#endif
