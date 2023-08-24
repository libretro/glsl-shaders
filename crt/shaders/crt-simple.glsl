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

#pragma parameter DISTORTION "CRT-Geom Distortion" 0.12 0.0 0.30 0.01
#pragma parameter SCANLINE "CRT-Geom Scanline Weight" 0.25 0.2 0.6 0.05
#pragma parameter MASK "CRT-Geom Mask Brightness" 0.6 0.0 1.0 0.05
#pragma parameter SIZE "CRT-Geom Mask Size" 1.0 0.666 1.0 0.333

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
COMPAT_VARYING float fragpos;


uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{  
    gl_Position = MVPMatrix * VertexCoord;    
    TEX0.xy = TexCoord.xy*1.0001;
    scale = TextureSize.xy/InputSize.xy;
    fragpos = TEX0.x*OutputSize.x*scale.x*PI;
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
COMPAT_VARYING float fragpos;

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float DISTORTION;
uniform COMPAT_PRECISION float SIZE;
uniform COMPAT_PRECISION float CURVATURE;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float MASK;

#else
#define DISTORTION 0.05
#define SIZE 1.0
#define CURVATURE 0.0
#define SCANLINE 0.3
#define MASK 0.3
#endif


        // Calculate the influence of a scanline on the current pixel.
        //
        // 'pos_y' is the distance in texture coordinates from the current
        // pixel to the scanline in question.
        // 'color' is the colour of the scanline at the horizontal location of
        // the current pixel.
        vec4 scanlineWeights(float pos_y, vec4 color)
        {
                // The "width" of the scanline beam is set as 2*(1 + x^4) for
                // each RGB channel.
                float widt = dot(sqrt(color.rgb),vec3(0.6666));
                vec4 wid = vec4 (widt); // 2.0 to 4.0
                //wid.r is min 0.0, max 4.0   
                float sqc = mix(1.0,1.41, widt);
                // The "weights" lines basically specify the formula that gives
                // you the profile of the beam, i.e. the intensity as
                // a function of pos_y from the vertical center of the
                // scanline. In this case, it is gaussian if width=2, and
                // becomes nongaussian for larger widths. Ideally this should
                // be normalized so that the integral across the beam is
                // independent of its width. That is, for a narrower beam
                // "weights" should have a higher peak at the center of the
                // scanline than for a wider beam.
                vec4 weights = vec4(pos_y / SCANLINE);
                vec4 wsc = weights/sqc;
                wsc = wsc*wsc*wsc; 
                return 1.2 * exp(-wsc) / (1.2 + 0.2 * wid);
        }

vec2 Distort(vec2 coord)
{
        //crt-pi
        vec2 CURVATURE_DISTORTION = vec2(DISTORTION, DISTORTION*1.5);
        // Barrel distortion shrinks the display area a bit, this will allow us to counteract that.
        vec2 barrelScale = 1.0 - (0.23 * CURVATURE_DISTORTION);
        coord *= scale;
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
        vec2 xy;

        #ifdef CURVATURE
                xy = Distort(TEX0.xy); 
                float xblur = xy.x; 
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
                col *= col;
                vec4 col2 = COMPAT_TEXTURE(Source,xy + vec2(0.0, SourceSize.w)); 
                col2 *= col2;

                // Calculate the influence of the current and next scanlines on
                // the current pixel.
                vec4 weights  = scanlineWeights(uv_ratio.y, col);
                vec4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

                vec3 mul_res  = (col * weights + col2 * weights2).rgb;
                
// dot-mask emulation:
                float dotMaskWeights = mix(MASK, 1.0, 0.5*sin(fragpos*SIZE)+0.5);

                mul_res *= dotMaskWeights;


#if  defined GL_ES
	// hacky clamp fix for GLES
    vec2 bordertest = (xy);
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        mul_res = mul_res;
    else
        mul_res = vec3(0.,0.,0.);
#endif
        mul_res = sqrt(mul_res);
        mul_res.rgb *= mix(1.45,1.05, dot(mul_res.rgb, vec3(0.3,0.6,0.1)));

        FragColor = vec4(mul_res, 1.0);
        }

#endif
