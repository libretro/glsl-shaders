#version 110

/*
   Simple S-video like shader by DariusG 2023
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/
#pragma parameter distortion "Overall Distortion" 0.25 0.0 1.0 0.01 
#pragma parameter artifacts "Artifacts Strength" 0.01 0.0 1.0 0.01
#pragma parameter fringing "Fringing Strength" 0.06 0.0 1.0 0.01
#pragma parameter bleed "Color Bleed Strength" 0.25 0.0 1.0 0.01
#pragma parameter rad "Color Bleed Radius" 1.0 0.0 3.0 0.05
#pragma parameter brightness "NTSC Brightness" 1.0 0.0 2.0 0.05
#pragma parameter contrast "NTSC Contrast" 1.0 0.0 2.0 0.05
#pragma parameter sat "NTSC Saturation" 1.0 0.0 2.0 0.05
#pragma parameter NTSC "NTSC Colors" 1.0 0.0 2.0 0.05

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
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float distortion;
uniform COMPAT_PRECISION float artifacts;
uniform COMPAT_PRECISION float fringing;
uniform COMPAT_PRECISION float bleed;
uniform COMPAT_PRECISION float rad;
uniform COMPAT_PRECISION float contrast;
uniform COMPAT_PRECISION float brightness;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float NTSC;

#else
#define distortion  0.25
#define artifacts 0.01
#define fringing 0.06 
#define bleed   0.5  
#define rad 2.0
#define contrast 1.0
#define brightness 1.0
#define sat 1.0
#define NTSC 1.0

#endif

#define PI 3.14159265
#define time float (FrameCount)


float RGB2Y(vec3 _rgb) {
    return dot(_rgb, vec3(0.29900, 0.58700, 0.11400));
}

float RGB2U(vec3 _rgb) {
   return dot(_rgb, vec3(-0.14713, -0.28886, 0.43600));
}

float RGB2V(vec3 _rgb) {
   return dot(_rgb, vec3(0.61500, -0.51499, -0.10001));
}

float YUV2R(vec3 _yuv) {
   return dot(_yuv, vec3(1, 0.00000, 1.13983));
}

float YUV2G(vec3 _yuv) {
   return dot(_yuv, vec3(1.0, -0.39465, -0.58060));
}

float YUV2B(vec3 _yuv) {
    return dot(_yuv, vec3(1.0, 2.03211, 0.00000));
}

vec3 YUV2RGB(vec3 _yuv) {
    vec3 _rgb;
    _rgb.r = YUV2R(_yuv);
    _rgb.g = YUV2G(_yuv);
    _rgb.b = YUV2B(_yuv);

   return _rgb;
}

vec3 RGB2YUV(vec3 _rgb) {
    vec3 _yuv;
    _yuv.r = RGB2Y(_rgb);
    _yuv.g = RGB2U(_rgb);
    _yuv.b = RGB2V(_rgb);

   return _yuv;
}


float Overlay(float col, float M) {
    col += 0.5;
    M += 0.5;
    return (col * (col + (2.0 * M)*(1.0 - col))) -0.5;
}


//non linear approximate (but not exact)
const mat3 ntsc  = mat3 (
1.5164, -0.4945,    -0.02,
-0.0372,    0.9571, 0.0802,
-0.0192,    -0.0309,    1.0500
);


void main() {

    float kernel[3];
    kernel[0] = 0.2; 
    kernel[1] = 0.5; 
    kernel[2] = 0.3; 

    float kernelb[5];
    kernelb[0] = 2.0*bleed; 
    kernelb[1] = 4.0*bleed; 
    kernelb[2] = 1.0; 
    kernelb[3] = 4.0*bleed; 
    kernelb[4] = 2.0*bleed; 
        
    float odd = mod(abs(vTexCoord.x*SourceSize.x + vTexCoord.y*SourceSize.y) + 0.5, 2.0);
    float distort = SourceSize.z* odd * distortion;

// UV distortion
    vec4 color_out = COMPAT_TEXTURE( Source, vTexCoord );
    color_out += COMPAT_TEXTURE( Source, vTexCoord + vec2( distort, 0.0 ) );
    color_out += COMPAT_TEXTURE( Source, vTexCoord - vec2( distort, 0.0 ) );
    
    vec3 YUV = RGB2YUV(color_out.rgb*0.3333);

// Y distortion for fringing/artifacts   
    vec3 Ycol = vec3(0.0);
    Ycol += COMPAT_TEXTURE( Source, vTexCoord  - vec2( SourceSize.x * distort, 0.0) ).rgb * kernel[0];
    Ycol += COMPAT_TEXTURE( Source, vTexCoord  + vec2( distort, 0.0 )               ).rgb * kernel[1];
    Ycol += COMPAT_TEXTURE( Source, vTexCoord  + vec2( SourceSize.x * distort, 0.0) ).rgb * kernel[2];
    
    float Y = RGB2Y(Ycol);
    if( floor(odd) == 0.0 ) Y = -Y;
    
// Color Bleeding    
        float px;
 for(int x = -2; x <= 2; x++ ) {
        px = float(x) * SourceSize.z - SourceSize.w * 0.5;
        float T = floor(mod(time,2.0));
        YUV.g += RGB2U (COMPAT_TEXTURE( Source, vTexCoord + vec2(px*rad, 0.0) ).rgb) * kernelb[x+2]; 
        YUV.g += RGB2U (COMPAT_TEXTURE( Source, vTexCoord - vec2(px*rad, 0.0) ).rgb) * kernelb[x+2]; 
        YUV.b += RGB2V (COMPAT_TEXTURE( Source, vTexCoord + vec2(px*rad, 0.0) ).rgb) * kernelb[x+2];
        YUV.b += RGB2V (COMPAT_TEXTURE( Source, vTexCoord - vec2(px*rad, 0.0) ).rgb) * kernelb[x+2];
    }
    YUV.g /= 3.0+24.0*bleed;
    YUV.b /= 3.0+24.0*bleed;

// fringing-artifacts

    float artifact =  Y * artifacts;
    float fringing =  Y * fringing;
    YUV.r = Overlay(YUV.r, artifact);
    YUV.g = Overlay(YUV.g, fringing);  
    YUV.b = Overlay(YUV.b, fringing); 

/////////    
    YUV.r *= brightness;
    color_out.rgb = contrast * (YUV2RGB( YUV )-vec3(0.5)) + vec3(0.5);
    color_out.rgb = mix(vec3(dot(vec3(0.3,0.6,0.1),color_out.rgb)),color_out.rgb,sat);
    if (NTSC == 1.0) color_out.rgb = color_out.rgb*ntsc;
    color_out - clamp(color_out,0.0,1.0);

    FragColor = color_out;
}

#endif
