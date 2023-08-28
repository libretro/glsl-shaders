// Simple scanlines with curvature and mask effects lifted from crt-geom
// original by hunterk, edit by DariusG

///////////////////////  Runtime Parameters  ///////////////////////
#pragma parameter sharpx "Horizontal Sharpness" 2.5 1.0 5.0 0.05
#pragma parameter sharpy "Vertical Sharpness" 3.0 1.0 5.0 0.05
#pragma parameter SCANLINE_SINE_COMP_B "Scanline Intensity" 0.3 0.0 1.0 0.05
#pragma parameter SIZE "Scanline size" 1.0 0.5 2.0 0.5
#pragma parameter warpX "warpX" 0.03 0.0 0.125 0.01
#pragma parameter warpY "warpY" 0.05 0.0 0.125 0.01
#pragma parameter corner_round "Corner Roundness" 0.030 0.005 0.100 0.005
#pragma parameter MSIZE "Mask Type" 1.0 0.666 1.0 0.3333
#pragma parameter cgwg "CGWG mask brightness" 0.7 0.0 1.0 0.1
#pragma parameter crt_gamma "CRT Gamma" 2.4 1.0 4.0 0.05
#pragma parameter monitor_gamma "Monitor Gamma" 2.25 1.0 4.0 0.05
#pragma parameter boost "Bright boost " 0.20 0.00 1.00 0.02
#pragma parameter GLOW_LINE "Glowing line" 0.006 0.00 0.20 0.001

#define pi 3.141592
#define in_gamma  vec4(crt_gamma, crt_gamma, crt_gamma, 1.0)
#define out_gamma  vec4(1.0 / monitor_gamma, 1.0 / monitor_gamma, 1.0 / monitor_gamma, 1.0)
#define scale vec4(TextureSize/InputSize,InputSize/TextureSize)

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
COMPAT_VARYING float omega;
COMPAT_VARYING float fragpos;

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
    omega =  2.0 * pi * TextureSize.y;
    fragpos = TEX0.x*OutputSize.x*scale.x*pi;

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
COMPAT_VARYING float omega;
COMPAT_VARYING float fragpos;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define iTimer (float(FrameCount)*60.0)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float sharpx;
uniform COMPAT_PRECISION float sharpy;
uniform COMPAT_PRECISION float SCANLINE_SINE_COMP_B;
uniform COMPAT_PRECISION float SIZE;
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
uniform COMPAT_PRECISION float corner_round;
uniform COMPAT_PRECISION float cgwg;
uniform COMPAT_PRECISION float MSIZE;
uniform COMPAT_PRECISION float crt_gamma;
uniform COMPAT_PRECISION float monitor_gamma;
uniform COMPAT_PRECISION float boost;
uniform COMPAT_PRECISION float GLOW_LINE;
#else
#define sharpx     1.0 
#define sharpy     1.0
#define SCANLINE_SINE_COMP_B 0.40
#define SIZE 1.0
#define warpX 0.031
#define warpY 0.041
#define corner_round 0.030
#define cgwg 0.4
#define MSIZE 1.0
#define crt_gamma 2.2
#define monitor_gamma 2.4
#define boost 0.00
#define GLOW_LINE 0.00
#endif

vec4 scanline(vec2 coord, vec4 frame, float l)
{
    float SCANLINE_SINE_COMP = mix(SCANLINE_SINE_COMP_B*1.5,SCANLINE_SINE_COMP_B,l);
    vec3 res = frame.xyz;
    vec3 scanline = res * (SCANLINE_SINE_COMP*sin(fract(coord.y*SIZE*TextureSize.y)*pi)+1.0- SCANLINE_SINE_COMP);

    return vec4(scanline, 1.0);
}


// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
    
    return pos*0.5 + 0.5;
}

float corner(vec2 coord)
{
                coord *= scale.xy;
                coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
                coord = min(coord, vec2(1.0)-coord) * vec2(1.0, InputSize.y/InputSize.x);
                vec2 cdist = vec2(corner_round);
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*300.0,0.0, 1.0);
}  


 float randomPass(vec2 coords)
 {
    return fract(smoothstep(-120.0, 0.0, coords.y - (TextureSize.y + 120.0) * fract(iTimer * 0.00015)));
}

#define tex SourceSize.zw

vec3 BilinearSharp (vec2 pos)
{
    vec2 uv = pos * SourceSize.x + 0.5;
    
    vec2 frac = fract(uv);
    uv = (floor(uv) / SourceSize.x) - vec2(tex*0.5);

    vec3 C11 = COMPAT_TEXTURE(Source, uv + vec2( 0.0          , 0.0)).rgb;
    vec3 C21 = COMPAT_TEXTURE(Source, uv + vec2( tex.x , 0.0)).rgb;
    vec3 C12 = COMPAT_TEXTURE(Source, uv + vec2( 0.0          , tex.y)).rgb;
    vec3 C22 = COMPAT_TEXTURE(Source, uv + vec2( tex.x , tex.y)).rgb;

    float x = frac.x;
    float y = frac.y;
    vec3 up = mix(C11, C21, pow(x, sharpx));
    vec3 dw = mix(C12, C22, pow(x, sharpx));
    return mix(up, dw, pow(y, sharpy));
}

void main()
{
    vec2 pos = Warp(TEX0.xy*(scale.xy))*scale.zw;
    vec4 res = vec4(BilinearSharp(pos),1.0);

    float l = max(max(res.r,res.g),res.b);
    res = scanline(pos,res,l);
    res = scanline(1.0-pos,res,l);
    res = pow(res,in_gamma);

    // apply the mask; looks bad with vert scanlines so make them mutually exclusive
    float dotMaskWeights = mix(cgwg, 1.0, 0.5*sin(fragpos*MSIZE)+0.5);
    res *= dotMaskWeights;
#if defined GL_ES
    // hacky clamp fix for GLES
    vec2 bordertest = (pos);
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec4(0.,0.,0.,0.);
#endif
    vec4 color = res;

    // re-apply the gamma curve for the mask path
    color = pow(color, out_gamma);
    color += boost*color;
    color += randomPass(pos * TextureSize) * GLOW_LINE;
    FragColor = color*corner(pos);

} 
#endif
