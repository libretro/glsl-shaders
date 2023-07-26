#version 110

/*
   Simple S-video like shader by DariusG 2023
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/
#pragma parameter curv "Curvature amount" 0.2 0.0 1.0 0.01
#pragma parameter bleeding "Color Bleeding" 1.0 0.0 2.0 0.1
#pragma parameter blur "Blur Size" 3.0 0.0 10.0 1.0
#pragma parameter scanlineL "Scanline Low" 0.2 0.0 0.5 0.05
#pragma parameter scanlineH "Scanline High" 0.1 0.0 0.5 0.05
#pragma parameter mask "Mask" 0.5 0.0 1.0 0.05
#pragma parameter saturation "Saturation" 1.0 0.0 2.0 0.01
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
uniform COMPAT_PRECISION float bleeding;
uniform COMPAT_PRECISION float scanlineL;
uniform COMPAT_PRECISION float scanlineH;
uniform COMPAT_PRECISION float curv;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float saturation;
uniform COMPAT_PRECISION float blur;

#else
#define bleeding 0.5
#define scanlineL 0.2
#define scanlineH 0.1
#define curv 0.3
#define saturation 1.0
#define mask 0.5
#define blur 1.0
#endif

#define PI 3.14159265
#define _Framecount float (FrameCount)


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

vec2 curve(vec2 coord, float bend) {
    // put in symmetrical coords
    coord = (coord - 0.5) * 2.0;

    coord *= 1.0;   

    // deform coords
    coord.x *= 1.0 + pow((abs(coord.y) * bend), 2.0);
    coord.y *= 1.0 + pow((abs(coord.x) * bend), 2.0);

    // transform back to 0.0 - 1.0 space
    coord  = (coord / 2.0) + 0.5;

    return coord;
}



void main() {
    float a_kernel[5];
    a_kernel[0] = 2.0; 
    a_kernel[1] = 4.0; 
    a_kernel[2] = 1.0; 
    a_kernel[3] = 4.0; 
    a_kernel[4] = 2.0; 
    
    vec2 pos = curve(vTexCoord*SourceSize.xy/InputSize.xy,curv)*InputSize.xy/SourceSize.xy;
    float y = pos.y*SourceSize.y;
    float cent=floor(y)+0.5;
    y = cent*SourceSize.w;
    vec2 coords = vec2(pos.x,mix(pos.y,y,0.3));
    vec4 res;
    
//sawtooth effect
    if( mod( floor(coords.y*OutputSize.y), 2.0 ) == 0.0 ) {
        res = texture2D( Source, coords + vec2(OutSize.z*0.5, 0.0) );
    } else {
        res = texture2D( Source, coords - vec2(OutSize.z*0.5, 0.0) );
    }
//end of sawtooth
    
    int blurs = int(blur);
// blur image 
    vec2 fragCoord = coords*OutputSize.xy;
    float counter = 1.0;
    for (int i = -blurs; i <= blurs; i++) {
            vec2 uv = vec2(fragCoord.x + float(i)*0.33, fragCoord.y ) / OutputSize.xy;
            res.rgb += texture2D(Source, uv).xyz;
            counter += 1.0;
    }
    res.rgb /= counter;
//blur end


    vec3 yuv = vec3(0.0);

//color bleed   
    float px = 0.0;
    for( int x = -2; x <= 2; x++ ) {
        px = float(x) * SourceSize.z - SourceSize.w * 0.5;
        yuv.g += RGB2U( texture2D( Source, coords + vec2(px, 0.0)).rgb ) * a_kernel[x + 2];
        yuv.b += RGB2V( texture2D( Source, coords + vec2(px, 0.0)).rgb ) * a_kernel[x + 2];
    }
    
    yuv.r = RGB2Y(res.rgb);
    yuv.g /= 10.0;
    yuv.b /= 10.0;

    res.rgb = (res.rgb * (1.0 - bleeding*0.5)) + (YUV2RGB(yuv) * bleeding*0.5);
//color bleed end    
    res = res*res;
    float lum = 0.0, Scanline;

    if (InputSize.y <400.0)
    {
    lum = dot(vec3(0.2,0.7,0.1),res.rgb);  
    Scanline = mix(scanlineL,scanlineH,lum);

    res *= Scanline*sin(fract(pos.y*SourceSize.y)*2.0*PI)+1.0-Scanline;
    res *= Scanline*sin(fract(1.0+pos.y*SourceSize.y)*2.0*PI)+1.0-Scanline;}
    
    res *= mask*sin(fract(gl_FragCoord.x*0.333)*PI)+1.0-mask;
    res = sqrt(res);
    res.rgb = mix( vec3(dot(vec3(0.2126, 0.7152, 0.0722), res.rgb)),res.rgb, saturation);

   #if defined GL_ES
    // hacky clamp fix for GLES
    vec2 bordertest = coords;
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec4(0.,0.,0.,0.);
    #endif
    FragColor = res;
}
#endif
