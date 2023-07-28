
#pragma parameter TEMP "Color Temperature in Kelvins"  9311.0 1031.0 12047.0 72.0
#pragma parameter SAT "Saturation" 1.0 0.0 2.0 0.01
#pragma parameter BRIGHTNESS "Brightness" 1.0 0.0 2.0 0.01
#pragma parameter contrast "Contrast" 1.0 0.00 2.00 0.01
#pragma parameter BLACK  "Black Level" 0.0 -0.20 0.20 0.01 
#pragma parameter SEGA "SEGA Lum Fix" 0.0 0.0 1.0 1.0
#pragma parameter postbr "Post Brightness" 1.0 0.0 2.5 0.01
#pragma parameter gamma_in "Gamma In" 2.4 1.0 4.0 0.05
#pragma parameter gamma_out_red "Gamma out Red" 2.2 1.0 4.0 0.05
#pragma parameter gamma_out_green "Gamma out Green" 2.2 1.0 4.0 0.05
#pragma parameter gamma_out_blue "Gamma out Blue" 2.2 1.0 4.0 0.05
#pragma parameter mono "Mono Display On/Off" 0.0 0.0 1.0 1.0
#pragma parameter R "Mono Red/Channel" 1.0 0.0 2.0 0.01
#pragma parameter G "Mono Green/Channel" 1.0 0.0 2.0 0.01
#pragma parameter B "Mono Blue/Channel" 1.0 0.0 2.0 0.01


#define PI 3.141592653589
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
uniform COMPAT_PRECISION float R; 
uniform COMPAT_PRECISION float G; 
uniform COMPAT_PRECISION float B; 
uniform COMPAT_PRECISION float TEMP; 
uniform COMPAT_PRECISION float SAT;
uniform COMPAT_PRECISION float BRIGHTNESS; 
uniform COMPAT_PRECISION float contrast; 
uniform COMPAT_PRECISION float SEGA; 
uniform COMPAT_PRECISION float postbr; 
uniform COMPAT_PRECISION float mono; 
uniform COMPAT_PRECISION float gamma_in;
uniform COMPAT_PRECISION float gamma_out_blue; 
uniform COMPAT_PRECISION float gamma_out_green; 
uniform COMPAT_PRECISION float gamma_out_red; 
uniform COMPAT_PRECISION float BLACK; 



#else
#define R 1.0
#define G 1.0
#define B 1.0
#define TEMP 9300.0
#define SAT 1.0
#define BRIGHTNESS 1.0
#define contrast 1.0
#define SEGA 0.0
#define postbr 1.0
#define mono 0.0
#define gamma_out_blue 2.2
#define gamma_out_green 2.2
#define gamma_out_red 2.2
#define gamma_in 2.4
#define BLACK 0.0

#endif

float saturate(float v) 
    { 
        return clamp(v, 0.0, 1.0);       
    }

vec3 ColorTemp(float temperatureInKelvins)
{
    vec3 retColor;
    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;
    
    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = saturate(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098);
    }
    else
    {
        float t = temperatureInKelvins - 60.0;
        retColor.r = saturate(1.29293618606274509804 * pow(t, -0.1332047592));
        retColor.g = saturate(1.12989086089529411765 * pow(t, -0.0755148492));
    }
    
    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914);

    return retColor;
}

mat4 contrastMatrix(float contr)
{   
    float t = (1.0 - contr) / 2.0;
    
    return mat4(contr, 0,               0,               0,
                0,               contr, 0,               0,
                0,               0,               contr, 0,
                t,               t,               t,               1);
}


vec3 toGrayscale(vec3 color)
{
  float average = dot(vec3(0.22,0.71,0.07),color);
  return vec3(average);
}

vec3 colorize(vec3 grayscale, vec3 color)
{
    return (grayscale * color);
}



void main()
{
   vec3 col = COMPAT_TEXTURE(Source,vTexCoord).rgb;
   col *= BRIGHTNESS;
   col = (contrastMatrix(contrast) * vec4(col,1.0)).rgb;  
//color temperature  
   col *= ColorTemp(TEMP);

//saturation
   float l = dot(col, vec3(0.3,0.6,0.1));
   col = mix(vec3(l), col, SAT); 
   col = pow(col, vec3(gamma_in));
//black level    
   
   if (SEGA == 1.0) col *= 1.0625;
    col *= mix(1.0,postbr,l);
    col = pow(col, vec3(1.0/gamma_out_red,1.0,1.0));
    col = pow(col, vec3(1.0,1.0/gamma_out_green,1.0));
    col = pow(col, vec3(1.0,1.0,1.0/gamma_out_blue));
    col -= vec3(BLACK);
    col*= vec3(1.0)/vec3(1.0-BLACK);
    
    if (mono == 1.0)
    {
    vec3 col1 = toGrayscale (col);
    vec3 c = vec3(R, G, B);
    col = colorize (col1, c);
    }

   FragColor = vec4(col,1.0);
}
#endif
