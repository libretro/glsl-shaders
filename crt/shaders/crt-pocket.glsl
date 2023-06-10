
#pragma parameter SHARPNESSX "   Horizontal Sharpness"  0.25 0.0 1.0 0.05
#pragma parameter SHARPNESSY "   Vertical Sharpness"  0.7 0.0 1.0 0.05
#pragma parameter WARPX "Curvature Horizontal" 0.03 0.0 0.2 0.01
#pragma parameter WARPY "Curvature Vertical" 0.05 0.0 0.2 0.01
#pragma parameter CORNER_ROUND "Corner Roundness" 0.02 0.005 0.2 0.01
#pragma parameter BORDER "Border Smoothness" 400.0 100.0 1000.0 25.0
#pragma parameter INTERLACE "Interlace On/Off" 1.0 0.0 1.0 1.0
#pragma parameter SCANLOW "   Scanline Low Brightness" 0.15 0.01 1.0 0.05
#pragma parameter SCANHIGH "   Scanline High Brightness" 0.20 0.01 1.0 0.05
#pragma parameter MINSCAN "   Scanline Min Brightness" 0.04 0.01 1.0 0.01
#pragma parameter SHADOWMASK "Mask Type, CGWG, Lottes 1-4" 5.0 -1.0 5.0 1.0
#pragma parameter BGR "RGB/BGR subpixels" 1.0 0.0 1.0 1.0 
#pragma parameter MASKLOW "Mask Strength Low" 1.0 0.0 1.0 0.05
#pragma parameter MASKHIGH "Mask Strength High" 0.75 0.0 1.0 0.05
#pragma parameter DOTMASK_STRENGTH "CGWG Dot Mask Strength" 0.3 0.0 1.0 0.05
#pragma parameter MASKDARK "Lottes Mask Dark" 0.5 0.0 2.0 0.1
#pragma parameter MASKLIGHT "Lottes Mask Light" 1.5 0.0 2.0 0.1
#pragma parameter GAMMAIN "   Gamma In" 2.4 1.0 4.0 0.05
#pragma parameter GAMMAOUT "   Gamma Out" 2.25 1.0 4.0 0.05
#pragma parameter BLACK "   Black Level" 0.0 -0.20 0.20 0.01 
#pragma parameter TEMP "   Color Temperature in Kelvins"  9311.0 1031.0 12047.0 72.0
#pragma parameter SAT "   Saturation" 1.0 0.0 2.0 0.01
#pragma parameter SEGA "   SEGA Lum Fix" 0.0 0.0 1.0 1.0
#pragma parameter GLOW "   Glow Strength" 0.12 0.0 1.0 0.01
#pragma parameter quality "   Glow Size" 1.0 0.0 1.5 0.05
#pragma parameter VIGNETTE "Vignette On/Off" 1.0 0.0 1.0 1.0
#pragma parameter VPOWER "Vignette Power" 0.1 0.0 1.0 0.01
#pragma parameter VSTR "Vignette Strength" 45.0 0.0 50.0 1.0
#pragma parameter nois "Noise strength" 0.4 0.0 1.0 0.01

#define PI  3.14159265 
#define FIX(c) max(abs(c), 1e-5);
#define mod_factor vTexCoord.x * OutputSize.x/InputSize.x* SourceSize.x 


#define scale vec4(TextureSize/InputSize,InputSize/TextureSize)
#define filterWidth (InputSize.y / OutputSize.y) / 3.0


#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif


uniform vec2 TextureSize;
varying vec2 TEX0;

#if defined(VERTEX)
uniform mat4 MVPMatrix;
attribute vec4 VertexCoord;
attribute vec2 TexCoord;
uniform int FrameCount;
uniform vec2 InputSize;
uniform vec2 OutputSize;

void main()
{
	TEX0 = TexCoord;                    
	gl_Position = MVPMatrix * VertexCoord;     
}

#elif defined(FRAGMENT)

uniform sampler2D Texture;
uniform vec2 OutputSize;
uniform int FrameCount;
uniform vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define FragColor gl_FragColor
#define Source Texture
#define iTime FrameCount/60


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SHARPNESSX;
uniform COMPAT_PRECISION float SHARPNESSY;
uniform COMPAT_PRECISION float WARPX;
uniform COMPAT_PRECISION float WARPY;
uniform COMPAT_PRECISION float CORNER_ROUND;
uniform COMPAT_PRECISION float BORDER;
uniform COMPAT_PRECISION float SHADOWMASK;
uniform COMPAT_PRECISION float MASKLOW;
uniform COMPAT_PRECISION float MASKHIGH;
uniform COMPAT_PRECISION float DOTMASK_STRENGTH;
uniform COMPAT_PRECISION float MASKDARK;
uniform COMPAT_PRECISION float MASKLIGHT;
uniform COMPAT_PRECISION float GAMMAIN;
uniform COMPAT_PRECISION float GAMMAOUT;
uniform COMPAT_PRECISION float SAT;
uniform COMPAT_PRECISION float SCANLOW;
uniform COMPAT_PRECISION float SCANHIGH;
uniform COMPAT_PRECISION float MINSCAN;
uniform COMPAT_PRECISION float VIGNETTE;
uniform COMPAT_PRECISION float VPOWER;
uniform COMPAT_PRECISION float VSTR;
uniform COMPAT_PRECISION float TEMP;
uniform COMPAT_PRECISION float SEGA;
uniform COMPAT_PRECISION float BLACK;
uniform COMPAT_PRECISION float GLOW;
uniform COMPAT_PRECISION float SIZE;
uniform COMPAT_PRECISION float quality;
uniform COMPAT_PRECISION float nois;
uniform COMPAT_PRECISION float BGR;
uniform COMPAT_PRECISION float INTERLACE;


#else

#define SHARPNESSX 0.3
#define SHARPNESSY 0.5
#define WARPX 0.03
#define WARPY 0.05
#define CORNER_ROUND 0.02
#define BORDER 400.0
#define SHADOWMASK 3.0
#define MASKLOW 0.5
#define MASKHIGH 0.3
#define DOTMASK_STRENGTH 0.3
#define MASKDARK 0.5
#define MASKLIGHT 1.5
#define GAMMAIN 2.5
#define GAMMAOUT 2.25
#define SAT 1.0
#define SCANLOW 0.15
#define SCANHIGH 0.35
#define MINSCAN 0.12
#define VIGNETTE 1.0
#define VPOWER 0.15
#define VSTR 45.0
#define TEMP 9300.0
#define SEGA 0.0
#define BLACK 0.0
#define GLOW 0.0 
#define SIZE 2.0
#define quality 1.0
#define BGR 1.0
#define nois 0.0
#define INTERLACE 1.0

#endif

#define iTimer (float(FrameCount) / 60.0)


vec2 curve(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*WARPX, 
        1.0 + (pos.x*pos.x)*WARPY);
    
    return pos*0.5 + 0.5;
}

float corner(vec2 coord)
{
                coord *= scale.xy;
                coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
                coord = min(coord, vec2(1.0)-coord) * vec2(1.0, InputSize.y/InputSize.x);
                vec2 cdist = vec2(CORNER_ROUND);
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*BORDER,0.0, 1.0);
}  



float CalcScanLineWeight(float dist, float scan)
{
    return max(1.0-dist*dist/scan, MINSCAN);
}

float ScanLine(float dy, float l)
{
    float scan = mix(SCANLOW, SCANHIGH, l);
    float scanLineWeight = CalcScanLineWeight(dy, scan);
    scanLineWeight += CalcScanLineWeight(dy-filterWidth, scan);
    scanLineWeight += CalcScanLineWeight(dy+filterWidth, scan);
    scanLineWeight *= 0.3333333;
    return scanLineWeight;
}


// Shadow mask.
vec3 Mask(vec2 pos)
{
   vec3 mask = vec3(MASKDARK, MASKDARK, MASKDARK);
   
   // Very compressed TV style shadow mask.
   if (SHADOWMASK == 1.0)
   {
      float line = MASKLIGHT;
      float odd  = 0.0;

      if (fract(pos.x/6.0) < 0.5)
         odd = 1.0;
      if (fract((pos.y + odd)/2.0) < 0.5)
         line = MASKDARK;

      pos.x = fract(pos.x/3.0);
    
      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = MASKLIGHT : mask.r = MASKLIGHT;
      else if (pos.x < 0.666) mask.g = MASKLIGHT;
      else                    (BGR == 1.0) ? mask.r = MASKLIGHT : mask.b = MASKLIGHT;
      mask*=line;  
   } 

   // Aperture-grille.
   else if (SHADOWMASK == 2.0)
   {
      pos.x = fract(pos.x/3.0);

      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = MASKLIGHT : mask.r = MASKLIGHT;
      else if (pos.x < 0.666) mask.g = MASKLIGHT;
      else                   (BGR == 1.0) ? mask.r = MASKLIGHT : mask.b = MASKLIGHT;
   } 

   // Stretched VGA style shadow mask (same as prior shaders).
   else if (SHADOWMASK == 3.0)
   {
      pos.x += pos.y*3.0;
      pos.x  = fract(pos.x/6.0);

      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = MASKLIGHT : mask.r = MASKLIGHT;
      else if (pos.x < 0.666) mask.g = MASKLIGHT;
      else                    (BGR == 1.0) ? mask.r = MASKLIGHT : mask.b = MASKLIGHT;
   }

   // VGA style shadow mask.
   else if (SHADOWMASK == 4.0)
   {
      pos.xy = floor(pos.xy*vec2(1.0, 0.5));
      pos.x += pos.y*3.0;
      pos.x  = fract(pos.x/6.0);

      if      (pos.x < 0.333) (BGR == 1.0) ? mask.b = MASKLIGHT : mask.r = MASKLIGHT;
      else if (pos.x < 0.666) mask.g = MASKLIGHT;
      else                    (BGR == 1.0) ? mask.r = MASKLIGHT : mask.b = MASKLIGHT;
   }
   else if (SHADOWMASK == 5.0)
    {
        float line = MASKLIGHT;
        float odd  = 0.0;

        if (fract(pos.x/4.0) < 0.5)
            odd = 1.0;
        if (fract((pos.y + odd)/2.0) < 0.5)
            line = MASKDARK;

        pos.x = fract(pos.x/2.0);
    
        if  (pos.x < 0.5) {mask.r = MASKLIGHT; mask.b = MASKLIGHT;}
        else  mask.g = MASKLIGHT;   
        mask*=line;  
    } 



   else if (SHADOWMASK == -1.0) mask = vec3(1.0);
   return mask;
}

mat3 vign()
{
    vec2 vpos = vTexCoord * TextureSize/InputSize;
    vpos *= 1.0 - vpos;    

    float vig = vpos.x * vpos.y * VSTR;

    vig = min(pow(vig, VPOWER), 1.0); 
    
    if (VIGNETTE == 0.0) vig=1.0;
   
    return mat3(vig, 0, 0,
                 0,   vig, 0,
                 0,    0, vig);
}

float saturate(float v) 
    { 
        return clamp(v, 0.0, 1.0);       
    }

// https://www.shadertoy.com/view/lsSXW1
vec3 ColorTemperatureToRGB(float temperatureInKelvins)
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


vec3 glow0 (vec2 uv)
{
   vec3 sum = vec3(0.0);
   float x = uv.x;
   float y = uv.y;
   float xx = SourceSize.z*quality;
   float yy = SourceSize.w*quality;

   sum += texture2D(Source, vec2(x-xx,y)).rgb*0.1;
   sum += texture2D(Source,vec2(x-xx,y-yy)).rgb*0.1;
   sum += texture2D(Source,vec2(x,y-yy)).rgb*0.1;
   sum += texture2D(Source,vec2(x+xx,y-yy)).rgb*0.1;
   sum += texture2D(Source,vec2(x+xx,y)).rgb*0.1;
   sum += texture2D(Source,vec2(x+xx,y+yy)).rgb*0.1;
   sum += texture2D(Source,vec2(x, y-yy)).rgb*0.1;
   sum += texture2D(Source,vec2(x+xx,y+yy)).rgb*0.1;

   sum += texture2D(Source,vec2(x-2.0*xx,y)).rgb*0.05;
   sum += texture2D(Source,vec2(x-2.0*xx,y-yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x-xx,y-2.0*yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x,y-2.0*yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x+xx,y-2.0*yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x+2.0*xx,y-yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x+2.0*xx,y)).rgb*0.05;
   sum += texture2D(Source,vec2(x+2.0*xx,y+yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x+xx,y+2.0*yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x,y+2.0*yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x-xx,y+2.0*yy)).rgb*0.05;
   sum += texture2D(Source,vec2(x-2.0*xx,y-yy)).rgb*0.05;

   return sum * GLOW; 
}

float noise(vec2 co)
{
return fract(sin(iTimer * dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{

// FILTER
	vec2 stepxy = SourceSize.zw;
     if (InputSize.y > 400.0 && INTERLACE == 0.0) stepxy.y *=2.0;

    vec2 texCoord = curve(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
    
    vec2 pos = texCoord.xy + stepxy * 0.5;
    vec2 OGL2Pos = texCoord * TextureSize;
    vec2 pC4 = floor(OGL2Pos) + 0.5;
    vec2 coord = pC4 / TextureSize;
    vec2 f = fract(pos / stepxy);
    if (InputSize.y > 400.0 && INTERLACE == 1.0) f = vec2(1.0);
    else if (InputSize.y > 400.0 && INTERLACE == 0.0) f;

    float x = mix(texCoord.x,coord.x,SHARPNESSX);
    float y = mix(texCoord.y,coord.y,SHARPNESSY);
    vec4 color = texture2D(Source,vec2(x,y)); 

    float lum2 = dot(color.rgb,vec3(0.29,0.60,0.11));

//gamma in    
    color = pow(color, vec4(GAMMAIN));
    
//Color temp    
    color.rgb *= ColorTemperatureToRGB(TEMP);
    
    float lum = max(max(color.r,color.g),color.b);
// noise    
    color.rgb *= mix(1.0 + noise(texCoord)*nois,1.0,lum);
//scanlines
float ss = ScanLine(f.y, lum)+ScanLine(1.0-f.y, lum);
    color *= ss;
//mask
    float mask = 1.0 - DOTMASK_STRENGTH;
    vec3 dotMaskWeights = mix(vec3(1.0, mask, 1.0),
                             vec3(mask, 1.0, mask),
                             floor(mod(mod_factor, 2.0)));
    float msk = mix(MASKLOW,MASKHIGH,lum2);

 if (SHADOWMASK == 0.0) 
   {
      color.rgb *= mix(vec3(1.0),dotMaskWeights, msk);
   }
   else 
   {
      color.rgb *= mix(vec3(1.0),Mask(floor(1.000001 * gl_FragCoord.xy + vec2(0.5,0.5))), msk);
   }

//gamma out
    color = pow(color, vec4(1.0/GAMMAOUT));  
//glow    
    color.rgb += glow0(pos);
//saturation
    color.rgb = mix(vec3(lum2)*ss,color.rgb, SAT);
//black level    
    color.rgb -= vec3(BLACK);
    color.rgb *= vec3(1.0)/vec3(1.0-BLACK);
//corner    
    color *= corner(texCoord);

    if (SEGA == 1.0) color.rgb *= 1.0625;

// vignette    
    color.rgb *= vign();
    FragColor = color;
}
#endif