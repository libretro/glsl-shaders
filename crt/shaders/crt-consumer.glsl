
// Parameter lines go here:
#pragma parameter blurx "Convergence X" 0.25 -2.0 2.0 0.05
#pragma parameter blury "Convergence Y" -0.15 -2.0 2.0 0.05
#pragma parameter warpx "Curvature X" 0.03 0.0 0.12 0.01
#pragma parameter warpy "Curvature Y" 0.04 0.0 0.12 0.01
#pragma parameter corner "Corner size" 0.01 0.0 0.10 0.01
#pragma parameter smoothness "Border Smoothness" 400.0 25.0 600.0 5.0
#pragma parameter scanlow "Beam low" 6.0 1.0 15.0 1.0
#pragma parameter scanhigh "Beam high" 8.0 1.0 15.0 1.0
#pragma parameter beamlow "Scanlines dark" 1.35 0.5 2.5 0.05 
#pragma parameter beamhigh "Scanlines bright" 1.05 0.5 2.5 0.05 
#pragma parameter brightboost1 "Bright boost dark pixels" 1.1 0.0 3.0 0.05
#pragma parameter brightboost2 "Bright boost bright pixels" 1.05 0.0 3.0 0.05
#pragma parameter Shadowmask "Mask Type" 7.0 -1.0 8.0 1.0 
#pragma parameter masksize "Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter MaskDark "Mask dark" 0.5 0.0 2.0 0.1
#pragma parameter MaskLight "Mask light" 1.5 0.0 2.0 0.1
#pragma parameter slotmask "Slot Mask Strength" 0.0 0.0 1.0 0.05
#pragma parameter slotwidth "Slot Mask Width" 2.0 1.0 6.0 0.5
#pragma parameter double_slot "Slot Mask Height: 2x1 or 4x1" 1.0 1.0 2.0 1.0
#pragma parameter slotms "Slot Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter GAMMA_IN "Gamma In" 2.5 0.0 4.0 0.1
#pragma parameter GAMMA_OUT "Gamma Out" 2.2 0.0 4.0 0.1
#pragma parameter glow "Glow Strength" 0.05 0.0 0.5 0.01
#pragma parameter Size "Glow Size" 1.0 0.1 4.0 0.05
#pragma parameter sat "Saturation" 1.1 0.0 2.0 0.05
#pragma parameter contrast "Contrast, 1.0:Off" 1.0 0.00 2.00 0.05
#pragma parameter nois "Noise" 0.0 0.0 32.0 1.0
#pragma parameter WP "Color Temperature %" 0.0 -100.0 100.0 5.0 
#pragma parameter inter "Interlacing Toggle" 1.0 0.0 1.0 1.0 
#pragma parameter vignette "Vignette On/Off" 1.0 0.0 1.0 1.0
#pragma parameter vpower "Vignette Power" 0.2 0.0 1.0 0.01
#pragma parameter vstr "Vignette strength" 40.0 0.0 50.0 1.0
#pragma parameter alloff "Switch off shader" 0.0 0.0 1.0 1.0
#define pi 6.28318

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
COMPAT_VARYING vec2 TEX0;

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
    TEX0.xy = TexCoord.xy * 1.0001;
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
COMPAT_VARYING vec2 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define iChannel0 Texture
#define iTime (float(FrameCount) / 2.0)
#define iTimer (float(FrameCount) / 60.0)

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
uniform COMPAT_PRECISION float warpx;
uniform COMPAT_PRECISION float warpy;
uniform COMPAT_PRECISION float corner;
uniform COMPAT_PRECISION float smoothness;
uniform COMPAT_PRECISION float scanlow;
uniform COMPAT_PRECISION float scanhigh;
uniform COMPAT_PRECISION float beamlow;
uniform COMPAT_PRECISION float beamhigh;
uniform COMPAT_PRECISION float brightboost1;
uniform COMPAT_PRECISION float brightboost2;
uniform COMPAT_PRECISION float Shadowmask;
uniform COMPAT_PRECISION float masksize;
uniform COMPAT_PRECISION float MaskDark;
uniform COMPAT_PRECISION float MaskLight;
uniform COMPAT_PRECISION float slotmask;
uniform COMPAT_PRECISION float slotwidth;
uniform COMPAT_PRECISION float double_slot;
uniform COMPAT_PRECISION float slotms;
uniform COMPAT_PRECISION float GAMMA_IN;
uniform COMPAT_PRECISION float GAMMA_OUT;
uniform COMPAT_PRECISION float glow;
uniform COMPAT_PRECISION float Size;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float contrast;
uniform COMPAT_PRECISION float nois;
uniform COMPAT_PRECISION float WP;
uniform COMPAT_PRECISION float inter;
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float vpower;
uniform COMPAT_PRECISION float vstr;
uniform COMPAT_PRECISION float alloff;
#else
#define blurx  0.0    
#define blury  0.0    
#define warpx  0.0    
#define warpy  0.0    
#define corner 0.0    
#define smoothness 300.0    
#define scanlow  6.0    
#define scanhigh  8.0    
#define beamlow  1.35    
#define beamhigh  1.05    
#define brightboost1 1.45    
#define brightboost2 1.1    
#define Shadowmask 0.0    
#define masksize 1.0    
#define MaskDark 0.5  
#define MaskLight 1.5 
#define slotmask     0.00     // Slot Mask ON/OFF
#define slotwidth    2.00     // Slot Mask Width
#define double_slot  1.00     // Slot Mask Height
#define slotms       1.00     // Slot Mask Size 
#define GAMMA_IN 2.4
#define GAMMA_OUT 2.2
#define glow 0.0 
#define Size 0.4
#define sat 1.0 
#define contrast  1.0   
#define nois 0.0
#define WP  0.0
#define inter 1.0
#define vignette 1.0
#define vpower 0.2
#define vstr 40.0
#define alloff 0.0
#endif


vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpx, 1.0 + (pos.x*pos.x)*warpy);
    return pos*0.5 + 0.5;
} 


float sw (vec3 x,vec3 color)
{
    float scan = mix(scanlow,scanhigh,x.y);
    vec3 tmp = mix(vec3(beamlow),vec3(beamhigh), color);
    vec3 ex = x*tmp;
    return exp2(-scan*ex.y*ex.y);
}

vec3 mask(vec2 x,vec3 col,float l)
{
    x = floor(x/masksize);        
  

    if (Shadowmask == 0.0)
    {
    float m =fract(x.x*0.4999);

    if (m<0.4999) return vec3(1.0,MaskDark,1.0);
    else return vec3(MaskDark,1.0,MaskDark);
    }
   
    else if (Shadowmask == 1.0)
    {
        vec3 Mask = vec3(MaskDark);

        float line = MaskLight;
        float odd  = 0.0;

        if (fract(x.x/6.0) < 0.5)
            odd = 1.0;
        if (fract((x.y + odd)/2.0) < 0.5)
            line = MaskDark;

        float m = fract(x.x/3.0);
    
        if      (m< 0.333)  Mask.b = MaskLight;
        else if (m < 0.666) Mask.g = MaskLight;
        else                Mask.r = MaskLight;
        
        Mask*=line; 
        return Mask; 
    } 
    

    else if (Shadowmask == 2.0)
    {
    float m =fract(x.x*0.3333);

    if (m<0.3333) return vec3(MaskDark,MaskDark,MaskLight);
    if (m<0.6666) return vec3(MaskDark,MaskLight,MaskDark);
    else return vec3(MaskLight,MaskDark,MaskDark);
    }

    if (Shadowmask == 3.0)
    {
    float m =fract(x.x*0.5);

    if (m<0.5) return vec3(1.0);
    else return vec3(MaskDark);
    }
   

    else if (Shadowmask == 4.0)
    {   
        vec3 Mask = vec3(col.rgb);
        float line = MaskLight;
        float odd  = 0.0;

        if (fract(x.x/4.0) < 0.5)
            odd = 1.0;
        if (fract((x.y + odd)/2.0) < 0.5)
            line = MaskDark;

        float m = fract(x.x/2.0);
    
        if  (m < 0.5) {Mask.r = 1.0; Mask.b = 1.0;}
                else  Mask.g = 1.0;   

        Mask*=line;  
        return Mask;
    } 

	else if (Shadowmask == 5.0)

    {
        vec3 Mask = vec3(1.0);

        if (fract(x.x/4.0)<0.5)   
            {if (fract(x.y/3.0)<0.666)  {if (fract(x.x/2.0)<0.5) Mask=vec3(1.0,MaskDark,1.0); else Mask=vec3(MaskDark,1.0,MaskDark);}
            else Mask*=l;}
        else if (fract(x.x/4.0)>=0.5)   
            {if (fract(x.y/3.0)>0.333)  {if (fract(x.x/2.0)<0.5) Mask=vec3(1.0,MaskDark,1.0); else Mask=vec3(MaskDark,1.0,MaskDark);}
            else Mask*=l;}

    return Mask;
    }

    else if (Shadowmask == 6.0)

    {
        vec3 Mask = vec3(MaskDark);
        if (fract(x.x/6.0)<0.5)   
            {if (fract(x.y/4.0)<0.75)  {if (fract(x.x/3.0)<0.3333) Mask.r=MaskLight; else if (fract(x.x/3.0)<0.6666) Mask.g=MaskLight; else Mask.b=MaskLight;}
            else Mask*l*0.9;}
        else if (fract(x.x/6.0)>=0.5)   
            {if (fract(x.y/4.0)>=0.5 || fract(x.y/4.0)<0.25 )  {if (fract(x.x/3.0)<0.3333) Mask.r=MaskLight; else if (fract(x.x/3.0)<0.6666) Mask.g=MaskLight; else Mask.b=MaskLight;}
            else Mask*l*0.9;}

    return Mask;

    }


    else if (Shadowmask == 7.0)
    {
    float m =fract(x.x*0.3333);

    if (m<0.3333) return vec3(MaskDark,MaskLight,MaskLight*col.b);  //Cyan
    if (m<0.6666) return vec3(MaskLight*col.r,MaskDark,MaskLight);  //Magenta
    else return vec3(MaskLight,MaskLight*col.g,MaskDark);           //Yellow
    }

  
     else if (Shadowmask == 8.0)
    {
        vec3 Mask = vec3(MaskDark);

        float bright = MaskLight;
        float left  = 0.0;
      

        if (fract(x.x/6.0) < 0.5)
            left = 1.0;
             
        float m = fract(x.x/3.0);
    
        if      (m < 0.333) Mask.b = 0.9;
        else if (m < 0.666) Mask.g = 0.9;
        else                Mask.r = 0.9;
        
        if      (mod(x.y,2.0)==1.0 && left == 1.0 || mod(x.y,2.0)==0.0 && left == 0.0 ) Mask*=bright; 
      
        return Mask; 
    } 
    
    else return vec3(1.0);
}

float SlotMask(vec2 pos, vec3 c)
{
    if (slotmask == 0.0) return 1.0;
    
    pos = floor(pos/slotms);
    float mx = pow(max(max(c.r,c.g),c.b),1.33);
    float mlen = slotwidth*2.0;
    float px = fract(pos.x/mlen);
    float py = floor(fract(pos.y/(2.0*double_slot))*2.0*double_slot);
    float slot_dark = mix(1.0-slotmask, 1.0-0.80*slotmask, mx);
    float slot = 1.0 + 0.7*slotmask*(1.0-mx);
    if (py == 0.0 && px <  0.5) slot = slot_dark; else
    if (py == double_slot && px >= 0.5) slot = slot_dark;       
    
    return slot;
}


mat4 contrastMatrix( float contrast )
{
    
	float t = ( 1.0 - contrast ) / 2.0;
    
    return mat4( contrast, 0, 0, 0,
                 0, contrast, 0, 0,
                 0, 0, contrast, 0,
                 t, t, t, 1 );

}


mat3 vign( float l )
{
    vec2 vpos = vTexCoord * (TextureSize.xy / InputSize.xy);
    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * vstr;
    vig = min(pow(vig, vpower), 1.0); 
    if (vignette == 0.0) vig=1.0;
   
    return mat3(vig, 0, 0,
                 0,   vig, 0,
                 0,    0, vig);

}

vec3 saturation (vec3 textureColor)
{
    float lum=length(textureColor.rgb)*0.5775;

    vec3 luminanceWeighting = vec3(0.4,0.5,0.1);
    if (lum<0.5) luminanceWeighting.rgb=(luminanceWeighting.rgb*luminanceWeighting.rgb)+(luminanceWeighting.rgb*luminanceWeighting.rgb);

    float luminance = dot(textureColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);

    vec3 res = vec3(mix(greyScaleColor, textureColor.rgb, sat));
    return res;
}

vec3 glow0 (vec2 texcoord,vec3 col)

{
   vec3 sum = vec3(0.0);
    float blurSize = Size/1024.0;

   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - 2.0*blurSize, texcoord.y)).rgb * 0.1;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - blurSize,     texcoord.y)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x,                texcoord.y)).rgb * 0.16;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + blurSize,     texcoord.y)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + 2.0*blurSize, texcoord.y)).rgb * 0.1;

   //sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - 2.0*blurSize, texcoord.y - 2.0*blurSize)) * 0.1;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - 2.0*blurSize, texcoord.y - blurSize)).rgb * 0.1;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - blurSize,     texcoord.y - 2.0*blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - blurSize,     texcoord.y - blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + blurSize,     texcoord.y + blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + blurSize,     texcoord.y + 2.0*blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + 2.0*blurSize, texcoord.y + blurSize)).rgb * 0.1;
   
   //sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + 2.0*blurSize,  texcoord.y + 2.0*blurSize)) * 0.1;
   //sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - 2.0*blurSize, texcoord.y + 2.0*blurSize)) * 0.1;
   
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - 2.0*blurSize, texcoord.y + blurSize)).rgb * 0.1;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - blurSize,     texcoord.y + 2.0*blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x - blurSize,     texcoord.y + blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + blurSize,     texcoord.y - blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + blurSize,     texcoord.y - 2.0*blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + 2.0*blurSize, texcoord.y - blurSize)).rgb * 0.1;
   
   //sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x + 2.0*blurSize,  texcoord.y - 2.0*blurSize)) * 0.1;

   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x,               texcoord.y - 2.0*blurSize)).rgb * 0.1;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x,               texcoord.y - blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x,               texcoord.y + blurSize)).rgb * 0.13;
   sum += COMPAT_TEXTURE(iChannel0, vec2(texcoord.x,               texcoord.y + 2.0*blurSize)).rgb * 0.1;
  
   return sum*glow; 

}


float noise(vec2 co)
{
return fract(sin(iTimer * dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float corner0(vec2 coord)
{
                coord *= TextureSize / InputSize;
                coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
                coord = min(coord, vec2(1.0)-coord) * vec2(1.0, InputSize.y/InputSize.x);
                vec2 cdist = vec2(corner);
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*smoothness,0.0, 1.0);
}  

const mat3 D65_to_XYZ = mat3 (
           0.4306190,  0.2220379,  0.0201853,
           0.3415419,  0.7066384,  0.1295504,
           0.1783091,  0.0713236,  0.9390944);

const mat3 XYZ_to_D65 = mat3 (
           3.0628971, -0.9692660,  0.0678775,
          -1.3931791,  1.8760108, -0.2288548,
          -0.4757517,  0.0415560,  1.0693490);
           
const mat3 D50_to_XYZ = mat3 (
           0.4552773,  0.2323025,  0.0145457,
           0.3675500,  0.7077956,  0.1049154,
           0.1413926,  0.0599019,  0.7057489);
           
const mat3 XYZ_to_D50 = mat3 (
           2.9603944, -0.9787684,  0.0844874,
          -1.4678519,  1.9161415, -0.2545973,
          -0.4685105,  0.0334540,  1.4216174);         


void main()
{
	vec2 pos = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
    vec2 tex_size = SourceSize.xy;	
    if (inter < 0.5 && InputSize.y >400.0) tex_size*=0.5;

	vec2 pC4 = (pos + 0.5/tex_size.xy);
	vec2 fp = fract(pos*tex_size.xy);
    if (inter >0.5 && InputSize.y >400.0) fp.y=1.0; 
    vec4 res = vec4(1.0);
    if (alloff == 1.0) res= COMPAT_TEXTURE(Source,pC4); else
    {
	vec3 sample1 = COMPAT_TEXTURE(Source,vec2(pC4.x + blurx/1000.0, pC4.y - blury/1000.0)).rgb;
	vec3 sample2 = COMPAT_TEXTURE(Source,pC4).rgb;
	vec3 sample3 = COMPAT_TEXTURE(Source,vec2(pC4.x - blurx/1000.0, pC4.y + blury/1000.0)).rgb;
	
	vec3 color = vec3 (sample1.r*0.5+sample2.r*0.5, sample1.g*0.25 + sample2.g*0.5 + sample3.g*0.25, sample2.b*0.5 + sample3.b*0.5);
   
    //COLOR TEMPERATURE FROM GUEST.R-DR.VENOM
    if (WP !=0.0){
    vec3 warmer = D50_to_XYZ*color;
    warmer = XYZ_to_D65*warmer; 
    vec3 cooler = D65_to_XYZ*color;
    cooler = XYZ_to_D50*cooler;
    float m = abs(WP)/100.0;
    vec3 comp = (WP < 0.0) ? cooler : warmer;
    comp=clamp(comp,0.0,1.0);   
    color = vec3(mix(color, comp, m));
    }

    color=pow(color,vec3(GAMMA_IN));
    
	float lum=color.r*0.4+color.g*0.5+color.b*0.1;
	
    float f = fp.y;
    vec3 f1 = vec3(f); 

    color = color*sw(f1,color) + color*sw(1.0-f1,color);
    
    color*=mask(gl_FragCoord.xy*1.0001,color,lum);
    if (slotmask !=0.0) color*=SlotMask(gl_FragCoord.xy*1.0001,color);
    
    color*=mix(brightboost1,brightboost2, max(max(color.r,color.g),color.b));    

    color=pow(color,vec3(1.0/GAMMA_OUT));

    if (glow !=0.0) color+=glow0(pC4,color);
    if (sat != 1.0) color = saturation(color);
    
    if (corner!=0.0) color*= corner0(pC4);
    if (nois != 0.0) color*=1.0+noise(pC4*2.0)/nois;
	
	res = vec4(color,1.0);
	if (contrast !=1.0) res = contrastMatrix(contrast)*res;
    if (inter >0.5 && InputSize.y >400.0 && fract(iTime)<0.5) res=res*0.95; else res;
    res.rgb*= vign(lum);
}
#if defined GL_ES
    // hacky clamp fix for GLES
    vec2 bordertest = (pC4);
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec4(0.0);
#endif

    FragColor = res;
} 
#endif
