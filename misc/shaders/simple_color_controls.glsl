
#pragma parameter CS "Colors: sRGB, PAL, NTSC-U, NTSC-J" 0.0 0.0 3.0 1.0
#pragma parameter TEMP "Color Temperature in Kelvins (NTSC-J 9300)"  6863.0 1031.0 12047.0 72.0
#pragma parameter sc_gamma_in "Gamma In" 2.4 1.0 4.0 0.05
#pragma parameter sc_RG "Green <-to-> Red Hue" 0.0 -0.25 0.25 0.01
#pragma parameter sc_RB "Blue <-to-> Red Hue"  0.0 -0.25 0.25 0.01
#pragma parameter sc_GB "Blue <-to-> Green Hue" 0.0 -0.25 0.25 0.01
#pragma parameter r_out "CRT Red Vibrancy" 0.29 0.0 1.0 0.01
#pragma parameter g_out "CRT Green Vibrancy" 0.62 0.0 1.0 0.01
#pragma parameter b_out "CRT Blue Vibrancy" 0.09 0.0 1.0 0.01
#pragma parameter BRIGHTNESS "Brightness" 1.0 0.0 2.0 0.01
#pragma parameter contrast "Contrast" 1.0 0.00 2.00 0.01
#pragma parameter SAT "Saturation" 1.0 0.0 2.0 0.01
#pragma parameter BLACK  "Black Level" 0.0 -0.20 0.20 0.01 
#pragma parameter SEGA "Lum Fix: ST/GEN-CPC-AMIGA" 0.0 0.0 3.0 1.0
#pragma parameter postbr "Bright Boost" 1.0 1.0 2.0 0.05
#pragma parameter postdk "Dark Boost" 1.0 1.0 2.0 0.05
#pragma parameter sc_gamma_out "Gamma out" 2.2 1.0 4.0 0.05
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
uniform COMPAT_PRECISION float postdk; 
uniform COMPAT_PRECISION float mono; 
uniform COMPAT_PRECISION float sc_gamma_in;
uniform COMPAT_PRECISION float sc_gamma_out; 
uniform COMPAT_PRECISION float r_out;
uniform COMPAT_PRECISION float g_out;
uniform COMPAT_PRECISION float b_out;
uniform COMPAT_PRECISION float BLACK; 
uniform COMPAT_PRECISION float sc_RG;
uniform COMPAT_PRECISION float sc_RB;
uniform COMPAT_PRECISION float sc_GB;
uniform COMPAT_PRECISION float CS;

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
#define postdk 1.0
#define mono 0.0
#define sc_gamma_out 2.2
#define sc_gamma_in 2.4
#define BLACK 0.0
#define sc_RG 0.0   
#define sc_RB 0.0   
#define sc_GB 0.0  
#define CS 0.0 
#define r_out 0.0 
#define g_out 0.0 
#define b_out 0.0 
#endif

#if defined GL_ES

mat3 PAL = mat3(                    
0.7954  ,   0.1881  ,   0.0053  ,
-0.0310 ,   1.0343  ,   -0.0044 ,
-0.0236 ,   0.1383  ,   0.8927  );

mat3 NTSC = mat3(                   
0.6837  ,   0.2635  ,   0.0336  ,
-0.0499 ,   1.0323  ,   0.0139  ,
-0.0119 ,   0.1071  ,   0.9111  );

mat3 NTSC_J = mat3(                 
0.8642  ,   0.1253  ,   0.0030  ,
0.0545  ,   0.9513  ,   -0.0029 ,
-0.0214 ,   0.1554  ,   0.8750  );

#else
// standard 6500k
mat3 PAL = mat3(                    
1.0740  ,   -0.0574 ,   -0.0119 ,
0.0384  ,   0.9699  ,   -0.0059 ,
-0.0079 ,   0.0204  ,   0.9884  );

// standard 6500k
mat3 NTSC = mat3(                   
0.9318  ,   0.0412  ,   0.0217  ,
0.0135  ,   0.9711  ,   0.0148  ,
0.0055  ,   -0.0143 ,   1.0085  );

// standard 6500k
mat3 NTSC_J = mat3(                 
1.0185  ,   -0.0144 ,   -0.0029 ,
0.0732  ,   0.9369  ,   -0.0059 ,
-0.0318 ,   -0.0080 ,   1.0353  );
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

  float average = dot(vec3(0.3,0.59,0.11),color);
  if (CS == 0.0) average = dot(vec3(0.22,0.71,0.07),color);
  return vec3(average);
}

vec3 colorize(vec3 grayscale, vec3 color)
{
    return (grayscale * color);
}


vec3 huePreserveClipDesaturate(float r, float g, float b)
{
   float l = (.299 * r) + (0.587 * g) + (0.114 * b);
   bool ovr = false;
   float ratio = 1.0;

   if ((r > 1.0) || (g > 1.0) || (b > 1.0))
   {
      ovr = true;
      float max = r;
      if (g > max) max = g;
      if (b > max) max = b;
      ratio = 1.0 / max;
   }

   if (ovr)
   {
      r -= 1.0;
      g -= 1.0;
      b -= 1.0;
      r *= ratio;
      g *= ratio;
      b *= ratio;
      r += 1.0;
      g += 1.0;
      b += 1.0;
   }

   r = clamp(r, 0.0, 1.0);
   g = clamp(g, 0.0, 1.0);
   b = clamp(b, 0.0, 1.0);

   return vec3(r, g, b);
}


void main()
{
mat3 hue = mat3(
    1.0, -sc_RG, -sc_RB,
    sc_RG, 1.0, -sc_GB,
    sc_RB, sc_GB, 1.0
);

   vec3 col = COMPAT_TEXTURE(Source,vTexCoord).rgb;

  if (SEGA == 1.0) col = floor(col*7.0+0.5)/7.0;
  if (SEGA == 2.0) col = floor(col*2.0+0.5)/2.0;
  if (SEGA == 3.0) col = floor(col*15.0+0.5)/15.0;
   
   col *= BRIGHTNESS;
   
   col = pow((col+0.099)/1.099, vec3(sc_gamma_in));
//color temperature  
   col *= ColorTemp(TEMP);

   
if (CS != 0.0){
    if (CS == 1.0) col *= PAL;
    if (CS == 2.0) col *= NTSC;
    if (CS == 3.0) col *= NTSC_J;
    col /= vec3(0.24,0.69,0.07);
    col *= vec3(r_out,g_out,b_out); 
    col = clamp(col,0.0,2.0);
}

    col = pow(1.099*col, vec3(1.0/sc_gamma_out))-0.099;
   
    col -= vec3(BLACK);
    col*= vec3(1.0)/vec3(1.0-BLACK);
    
//saturation
vec3 lumw = vec3(0.3,0.59,0.11);
if (CS == 0.0) lumw = vec3(0.2124,0.7011, 0.0866);   
float l = dot(col, lumw);
    
   col = mix(vec3(l), col, SAT); 
    if (mono == 1.0)
    {
    vec3 col1 = toGrayscale (col);
    vec3 c = vec3(R, G, B);
    col = colorize (col1, c);
    }
   col *= hue;

col *= mix(postdk,postbr,l);
col = (contrastMatrix(contrast) * vec4(col,1.0)).rgb;  

   col = huePreserveClipDesaturate(col.r, col.g, col.b);

   FragColor = vec4(col,1.0);
}
#endif
