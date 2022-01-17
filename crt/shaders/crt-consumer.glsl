// Parameter lines go here:
#pragma parameter SCANLINE "SCANLINE THICKNESS" 0.5 0.0 1.0 0.01
#pragma parameter BRIGHTBOOST "SCANLINE LUMINANCE" 1.0 0.0 2.0 0.05
#pragma parameter MASK "MASK LUMINANCE" 0.4 0.0 2.0 0.02
#pragma parameter MASKSIZE "MASK SIZE" 1.0 1.0 2.0 0.5
#pragma parameter BLUR "BLUR" 5.0 0.0 60.0 1.0
#pragma parameter SATURATION "SATURATION" 1.0 0.0 3.0 0.05

#define SAMPLES 20  //increase for better quality - decrease for better performance

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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy * 1.00001;

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
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float BRIGHTBOOST;
uniform COMPAT_PRECISION float SATURATION;
uniform COMPAT_PRECISION float BLUR;
uniform COMPAT_PRECISION float SCANLINE;
uniform COMPAT_PRECISION float MASKSIZE;
uniform COMPAT_PRECISION float MASK;

#else
#define BRIGHTBOOST 1.0
#define SATURATION 1.0
#define BLUR 0.5
#define SCANLINE 0.5
#define MASKSIZE 1.0
#define MASK 1.0
#endif


vec3 color (vec2 pos)
{
    //calculate aspect ratio
    float invAspect = SourceSize.y / SourceSize.x;
    
    //init color variable
    vec3 col = vec3 (0.0);
    float blur1 = BLUR/10000.0;
    //iterate over blur samples
    for (float index = 0.0; index < SAMPLES; index++)
    {
        //get uv coordinate of sample
        vec2 uv = pos.xy + vec2((index/(SAMPLES - 1.0) - 0.5) * blur1 * invAspect, 0.0);
        
        //add color at position to color
        col += COMPAT_TEXTURE(Source, uv).rgb;
    }
    //divide the sum of values by the amount of samples
    col = col / SAMPLES;
    return col;
}

vec3 scanline (float p, vec3 pixel)

{
    float scale = OutputSize.y/InputSize.y;                     //scale
    float stepy = 1.0/scale;                                    //steps based on scale
    float lum = BRIGHTBOOST*(max(pixel.r,pixel.g) + max(pixel.r,pixel.b) + max(pixel.g,pixel.b))/3.0;      //pixel luminance
    vec3 pix = vec3 (pixel.r, pixel.g, pixel.b);    
    
    float pos = fract(p*stepy);                                   //even steps 

    if (pos >SCANLINE)
    while  (pos>SCANLINE && pos<=1.0) 
    {
        return pix*sqrt(lum)*(1.2-pos);
        pos = pos + stepy;
    }
    else if (pos <SCANLINE)
    while  (pos<=SCANLINE && pos>=0.0) 
    {
        return pix*lum*pos;
        pos = pos + stepy;
    }

}


vec3 mask (float p, vec3 pixel)

{
    float pos = fract(p*0.33333/MASKSIZE);                     

    if (pos > 0.666) return vec3(MASK,0.7,1.0);         //cyan
    else if (pos>0.333) return vec3(0.7,1.0,MASK);      //yellow
    else return vec3(1.0,MASK,0.7);                     //magenta
}


//SIMPLE AND FAST SATURATION
vec3 saturation (vec3 textureColor)

{
    vec3 luminanceWeighting = vec3(0.3, 0.6, 0.1);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);

    vec3 res = vec3(mix(greyScaleColor, textureColor.rgb, SATURATION));
    return res;
}


void main()
{
    vec2 pos =TEX0.xy;

    vec3 screen=color(pos);

    screen+=scanline(gl_FragCoord.y,screen);
    screen*= mask(gl_FragCoord.x,screen);

    screen = saturation(screen);

    FragColor = vec4(screen, 1.0);
} 
#endif
