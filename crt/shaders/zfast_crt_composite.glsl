/*
    zfast_crt - A very simple CRT shader.

    Copyright (C) 2017 Greg Hogan (SoltanGris42)
    edited by metallic 77.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
	
*/


// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter Curvature "Curvature" 1.0 0.0 1.0 1.0
#pragma parameter blurx "Convergence X-Axis" 0.85 -2.0 2.0 0.05
#pragma parameter blury "Convergence Y-Axis" -0.10 -2.0 2.0 0.05
#pragma parameter HIGHSCANAMOUNT1 "Scanline Amount (Dark)" 0.40 0.0 1.0 0.05
#pragma parameter HIGHSCANAMOUNT2 "Scanline Amount (Bright)" 0.25 0.0 1.0 0.05
#pragma parameter TYPE "Mask Type" 0.0 0.0 1.0 1.0
#pragma parameter MASK_DARK "Mask Effect Amount" 0.3 0.0 1.0 0.05
#pragma parameter MASK_FADE "Mask/Scanline Fade" 0.7 0.0 1.0 0.05
#pragma parameter sat "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter ntsc "NTSC Colors" 0.0 0.0 1.0 1.0

#define pi 3.14159
#define scale vec4(TextureSize/InputSize,InputSize/TextureSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT1;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT2;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float MASK_FADE;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float ntsc;
uniform COMPAT_PRECISION float Curvature;
uniform COMPAT_PRECISION float TYPE;

#else

#define blurx 0.45
#define blury -0.15
#define HIGHSCANAMOUNT1  0.30
#define HIGHSCANAMOUNT2  0.20
#define MASK_DARK 0.3
#define MASK_FADE 0.8
#define sat 1.0
#define ntsc 0.0
#define Curvature 1.0
#define TYPE 0.0
#endif

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
// out variables go here as COMPAT_VARYING whatever
COMPAT_VARYING float maskFade;

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
    TEX0.xy = TexCoord.xy*1.0001;
    maskFade = 0.3333*MASK_FADE;
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

// in variables go here as COMPAT_VARYING whatever
COMPAT_VARYING float maskFade;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#define blur_y blury/(TextureSize.y*2.0)
#define blur_x blurx/(TextureSize.x*2.0)


// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*0.03, 1.0 + (pos.x*pos.x)*0.05);
    
    return pos*0.5 + 0.5;
}

// NTSC to sRGB matrix, used in linear space
const mat3 NTSC = mat3(1.5073,  -0.3725, -0.0832, 
                    -0.0275, 0.9350,  0.0670,
                     -0.0272, -0.0401, 1.1677);


void main()
{
    vec2 pos,corn;
    if (Curvature == 1.0) 
{
    pos = Warp(TEX0.xy*(scale.xy));
    corn = min(pos,vec2(1.0)-pos); // This is used to mask the rounded
    corn.x = 0.00001/corn.x;           // corners later on
    pos *= scale.zw;
}

    else pos = vTexCoord;
	
     float OGL2Pos = pos.y*TextureSize.y;
     float cent = floor(OGL2Pos)+0.5;
     float ycoord = cent*SourceSize.w; 
     ycoord = mix(pos.y,ycoord,0.6);
     pos = vec2(pos.x,ycoord);
	 
	

	 vec3 sample1 =  COMPAT_TEXTURE(Source,vec2(pos.x + blur_x, pos.y - blur_y)).rgb;
	 vec3 sample2 =  0.5*COMPAT_TEXTURE(Source,pos).rgb;
	 vec3 sample3 =  COMPAT_TEXTURE(Source,vec2(pos.x - blur_x, pos.y + blur_y)).rgb;
	
	 vec3 colour = vec3 (sample1.r*0.5  + sample2.r, 
		                 sample1.g*0.25 + sample2.g + sample3.g*0.25, 
		                                  sample2.b + sample3.b*0.5);
     vec3 lumweight=vec3(0.22,0.71,0.07);
     float lumsat = dot(colour,lumweight);
   
     vec3 graycolour = vec3(lumsat);
     colour = vec3(mix(graycolour,colour.rgb,sat));

     float SCANAMOUNT = mix(HIGHSCANAMOUNT1,HIGHSCANAMOUNT2,max(max(colour.r,colour.g),colour.b));
	    
    colour.rgb *= colour.rgb;
	 
	if (InputSize.y > 400.0) {
    colour ;
	} 
else {
	colour *= SCANAMOUNT * sin(fract(OGL2Pos)*3.14159)+1.0-SCANAMOUNT;
	colour *= SCANAMOUNT * sin(fract(1.0-OGL2Pos)*3.14159)+1.0-SCANAMOUNT;
	}

	 float steps; if (TYPE == 0.0) steps = 0.5; else steps = 0.3333;
	 float whichmask = fract(gl_FragCoord.x*steps);
	 float mask = 1.0 + float(whichmask < steps) * -MASK_DARK;


	colour.rgb = mix(mask*colour, colour, dot(colour.rgb,vec3(maskFade)));
    
    if (ntsc == 1.0) {colour.rgb *= NTSC; colour.rgb = clamp(colour.rgb,0.0,1.0);}
    
    colour.rgb = sqrt(colour.rgb);

    if (Curvature == 1.0 && corn.y < corn.x || Curvature == 1.0 && corn.x < 0.00001 )
    colour = vec3(0.0); 
    
	FragColor.rgb = colour.rgb;
} 
#endif
