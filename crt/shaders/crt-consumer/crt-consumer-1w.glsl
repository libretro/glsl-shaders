#version 110

#pragma parameter u_sharp "Reverse Sharpness" 0.25 0.0 0.5 0.01
#pragma parameter u_warp "Curvature" 0.04 0.0 0.15 0.01
#pragma parameter u_overscanx "Overscan Horiz." 0.3 0.3 2.0 0.05
#pragma parameter u_overscany "Overscan Vertic." 0.3 0.3 2.0 0.05
#pragma parameter u_vignette "Vignette" 0.15 0.0 0.5 0.01

#pragma parameter SCAN_LOW "Scanline Intensity (Dark Scenes)" 0.8 0.0 1.0 0.05
#pragma parameter SCAN_HIGH "Scanline Intensity (Bright Scenes)" 0.3 0.0 1.0 0.05
#pragma parameter MSK_SIZE "Mask Fine/Coarse" 1.0 0.6666 1.0 0.3333
#pragma parameter MASK_LOW "Mask Intensity (Dark Scenes)" 0.5 0.0 1.0 0.05
#pragma parameter MASK_HIGH "Mask Intensity (Bright Scenes)" 0.2 0.0 1.0 0.05

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
COMPAT_VARYING vec2 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 barrel;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float u_warp;
uniform COMPAT_PRECISION float u_overscanx;
uniform COMPAT_PRECISION float u_overscany;
uniform COMPAT_PRECISION float MSK_SIZE;
#else
#define u_warp 0.05
#define u_overscanx 0.3
#define u_overscany 0.3
#define MSK_SIZE 1.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0 = TexCoord.xy*1.0001;
    ogl2pos = TEX0.xy*TextureSize;
    invdims = 1.0/TextureSize;
    scale = TextureSize/InputSize;
    maskpos = TEX0.xy*scale*OutputSize.xy*MSK_SIZE;
    barrel = vec2(1.0-u_warp*u_overscanx, 1.0-u_warp*u_overscany);
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
COMPAT_VARYING vec2 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 barrel;

#define Source Texture
#define vTexCoord TEX0.xy

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float u_vignette;
uniform COMPAT_PRECISION float u_warp;
uniform COMPAT_PRECISION float u_sharp;
uniform COMPAT_PRECISION float SCAN_LOW;
uniform COMPAT_PRECISION float SCAN_HIGH;
uniform COMPAT_PRECISION float MASK_LOW;
uniform COMPAT_PRECISION float MASK_HIGH;
#else
#define u_vignette 0.1
#define u_warp 0.1
#define u_sharp 0.15
#define SCAN_LOW 0.8
#define SCAN_HIGH 0.3
#define MASK_LOW 0.5
#define MASK_HIGH 0.2
#endif

#define PI 3.14159265358979323846 
#define TAU 6.2831852
#define pixel 1.0/TextureSize

void main() {
    vec2 uv = TEX0*scale;
    vec2 pos = uv;
    vec2 n = uv * 2.0 - 1.0;
    float rsq = dot(n, n);
    n *= 1.0 + u_warp*rsq*1.5;
    n -= n*(barrel*u_warp);
    n *= barrel;
    uv = (n + 1.0) * 0.5;
    vec2 corn   = min(pos, 1.0-pos);
         corn.x = 0.0012/corn.x;   

    uv /= scale;
    
    vec2 dx = vec2(pixel.x, 0.0);

    vec3 col = COMPAT_TEXTURE(Texture, uv).rgb;
    vec3 sharpl  = COMPAT_TEXTURE(Texture, uv      -dx).rgb*(-u_sharp);
    vec3 sharpl2 = COMPAT_TEXTURE(Texture, uv - 2.0*dx).rgb*(u_sharp*0.1);
    vec3 sharpr  = COMPAT_TEXTURE(Texture, uv     + dx).rgb*(-u_sharp);
    vec3 sharpr2 = COMPAT_TEXTURE(Texture, uv + 2.0*dx).rgb*(u_sharp*0.1);
    
    col = col*(1.0 + u_sharp*1.8) + sharpl+sharpr+sharpl2+sharpr2;

    float l = max(max(col.r, col.g), col.b);
    float infl = mix(SCAN_LOW, SCAN_HIGH, l);
    float infl2 = mix(MASK_LOW, MASK_HIGH, l);

    float scan = infl * sin((uv.y * TextureSize.y) * TAU);
    float msk = infl2 * sin(maskpos.x * PI);
    
    col += col * scan;
    col += col * msk;

    float vig = 1.0 - u_vignette * pow(length(n), 1.5);
    col *= vig;

    if (u_warp > 0.0){  
        if (corn.y <= corn.x || corn.x < 0.0001)
            col = vec3(0.0);
    }
    FragColor = vec4(col, 1.0);
}
#endif
