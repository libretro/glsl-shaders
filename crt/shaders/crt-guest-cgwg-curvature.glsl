/*
   CRT - Guest 
   edited by metallic77
   
   Copyright (C) 2017-2018 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
   
*/

// Parameter lines go here:
#pragma parameter brightboost "Bright boost" 1.0 0.5 2.0 0.05
#pragma parameter sat "Saturation adjustment" 1.0 0.0 2.0 0.05
#pragma parameter scanline "Scanline adjust" 8.0 1.0 12.0 1.0
#pragma parameter beam_min "Scanline dark" 1.35 0.5 3.0 0.05
#pragma parameter beam_max "Scanline bright" 1.05 0.5 3.0 0.05
#pragma parameter h_sharp "Horizontal sharpness" 2.00 1.0 5.0 0.05
#pragma parameter gamma_out "Gamma out" 0.5 0.2 0.6 0.01
#pragma parameter shadowMask "CRT Mask: 0:CGWG, 1-4:Lottes, 5-6:'Trinitron'" 0.0 -1.0 10.0 1.0
#pragma parameter masksize "CRT Mask Size (2.0 is nice in 4k)" 1.0 1.0 2.0 1.0
#pragma parameter mcut "Mask 5-7-10 cutoff" 0.2 0.0 0.5 0.05
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.1
#pragma parameter maskLight "Lottes maskLight" 1.5 0.0 2.0 0.1
#pragma parameter CGWG "CGWG Mask Str." 0.4 0.0 1.0 0.1
#pragma parameter warpX "warpX" 0.0 0.0 0.125 0.01
#pragma parameter warpY "warpY" 0.0 0.0 0.125 0.01
#pragma parameter vignette "Vignette On/Off" 0.0 0.0 1.0 1.0
#pragma parameter vpower "Vignette Power" 0.2 0.0 1.0 0.01
#pragma parameter vstr "Vignette strength" 40.0 0.0 50.0 1.0

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
uniform COMPAT_PRECISION float brightboost;
uniform COMPAT_PRECISION float scanline;
uniform COMPAT_PRECISION float beam_min;
uniform COMPAT_PRECISION float beam_max;
uniform COMPAT_PRECISION float h_sharp;
uniform COMPAT_PRECISION float gamma_out;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float masksize;
uniform COMPAT_PRECISION float mcut;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
uniform COMPAT_PRECISION float CGWG;
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float vpower;
uniform COMPAT_PRECISION float vstr;
#else
#define brightboost  1.20     // adjust brightness
#define scanline     8.0      // scanline param, vertical sharpness
#define beam_min     1.35     // dark area beam min - wide
#define beam_max     1.05     // bright area beam max - narrow
#define h_sharp      1.25     // pixel sharpness
#define gamma_out    0.50     // output gamma
#define sat          1.0     // saturation
#define shadowMask   0.0      // Shadow mask type 
#define masksize     1.0      // Shadow mask size
#define mcut         0.20     // Mask 5&6 cutoff
#define maskDark     0.50     // Dark "Phosphor"
#define maskLight    1.50     // Light "Phosphor"
#define CGWG         0.40     // CGWG Mask Strength
#define warpX        0.0    // Curvature X
#define warpY        0.0    // Curvature Y
#define vignette 1.0
#define vpower 0.2
#define vstr 40.0
#endif

float sw (vec3 x,vec3 color)
{
    float scan = mix(scanline-2.0,scanline,x.y);
    vec3 tmp = mix(vec3(beam_min),vec3(beam_max), color);
    vec3 ex = x*tmp;
    return exp2(-scan*ex.y*ex.y);
}

// Shadow mask (1-4 from PD CRT Lottes shader).
vec3 Mask(vec2 pos, vec3 c)
{
	pos = floor(pos/masksize);
	vec3 mask = vec3(maskDark, maskDark, maskDark);
	
	// No mask
	if (shadowMask == -1.0)
	{
		mask = vec3(1.0);
	}       
	
	// Phosphor.
	else if (shadowMask == 0.0)
	{
		pos.x = fract(pos.x*0.5);
		float mc = 1.0 - CGWG;
		if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
		else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
	}    
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 1.0)
	{
		float line = maskLight;
		float odd  = 0.0;

		if (fract(pos.x/6.0) < 0.5)
			odd = 1.0;
		if (fract((pos.y + odd)/2.0) < 0.5)
			line = maskDark;

		pos.x = fract(pos.x/3.0);
    
		if      (pos.x < 0.3333) mask.b = maskLight;
		else if (pos.x < 0.6666) mask.g = maskLight;
		else                    mask.r = maskLight;
		
		mask*=line;  
	} 

	// Aperture-grille.
	else if (shadowMask == 2.0)
	{
		pos.x = fract(pos.x/3.0);

		if      (pos.x < 0.3333) mask.b = maskLight;
		else if (pos.x < 0.6666) mask.g = maskLight;
		else                    mask.r = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3.0)
	{
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.3333) mask.r = maskLight;
		else if (pos.x < 0.6666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4.0)
	{
		pos.xy = floor(pos.xy*vec2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.3333) mask.r = maskLight;
		else if (pos.x < 0.6666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}
	
	// Alternate mask 5
	else if (shadowMask == 5.0)
	{
		float mx = max(max(c.r,c.g),c.b);
		vec3 maskTmp = vec3( min( 1.25*max(mx-mcut,0.0)/(1.0-mcut) ,maskDark + 0.2*(1.0-maskDark)*mx));
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);	
		mask = maskTmp;
		pos.x = fract(pos.x/2.0);
		if  (pos.x < 0.5)
		{	mask.r  = adj;
			mask.b  = adj;
		}
		else     mask.g = adj;
	}    

	// Alternate mask 6
	else if (shadowMask == 6.0)
	{
		float mx = max(max(c.r,c.g),c.b);
		vec3 maskTmp = vec3( min( 1.33*max(mx-mcut,0.0)/(1.0-mcut) ,maskDark + 0.225*(1.0-maskDark)*mx));
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);
		mask = maskTmp;
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.3333) mask.r = adj;
		else if (pos.x < 0.6666) mask.g = adj;
		else                    mask.b = adj; 
	}
	
	// Alternate mask 7
	else if (shadowMask == 7.0)
	{
		float mc = 1.0 - CGWG;
		float mx = max(max(c.r,c.g),c.b);
		float maskTmp = min(1.6*max(mx-mcut,0.0)/(1.0-mcut) , mc);
		mask = vec3(maskTmp);
		pos.x = fract(pos.x/2.0);
		if  (pos.x < 0.5) mask = vec3(1.0 + 0.6*(1.0-mx));
	}    
	else if (shadowMask == 8.0)
	{
		float line = maskLight;
		float odd  = 0.0;

		if (fract(pos.x/4.0) < 0.5)
			odd = 1.0;
		if (fract((pos.y + odd)/2.0) < 0.5)
			line = maskDark;

		pos.x = fract(pos.x/2.0);
    
		if  (pos.x < 0.5) {mask.r = maskLight; mask.b = maskLight;}
		else  mask.g = maskLight;	
		mask*=line;  
	} 

	 else if (shadowMask == 9.0)
    {
        vec3 Mask = vec3(maskDark);

        float bright = maskLight;
        float left  = 0.0;
      

        if (fract(pos.x/6.0) < 0.5)
            left = 1.0;
          
            
        float m = fract(pos.x/3.0);
    
        if      (m < 0.3333) Mask.b = 0.9;
        else if (m < 0.6666) Mask.g = 0.9;
        else                Mask.r = 0.9;
        
        if      (mod(pos.y,2.0)==1.0 && left == 1.0 || mod(pos.y,2.0)==0.0 && left == 0.0 ) Mask*=bright; 
        
        return Mask; 
    } 
    
	 else if (shadowMask == 10.0)
    {
        vec3 Mask = vec3(maskDark);
        float line = maskLight;
		float odd  = 0.0;

		if (fract(pos.x/6.0) < 0.5)
			odd = 1.0;
		if (fract((pos.y + odd)/2.0) < 0.5)
			line = 1.0;    
    
        float m = fract(pos.x/3.0);
        float y = fract(pos.y/2.0);
        
        if      (m > 0.3333)  {Mask.r = 1.0; Mask.b = 1.0;}
        else if (m > 0.6666) Mask.g = 1.0;
        else                 Mask = vec3(mcut);
        if (m>0.333) Mask*=line; 
        return Mask; 
    } 

	return mask;
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

// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
    return pos*0.5 + 0.5;
} 

vec3 saturation (vec3 textureColor)
{
    float lum=length(textureColor.rgb)*0.5775;

    vec3 luminanceWeighting = vec3(0.3,0.6,0.1);
    if (lum<0.5) luminanceWeighting.rgb=(luminanceWeighting.rgb*luminanceWeighting.rgb)+(luminanceWeighting.rgb*luminanceWeighting.rgb);

    float luminance = dot(textureColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);

    vec3 res = vec3(mix(greyScaleColor, textureColor.rgb, sat));
    return res;
}

void main()
{
	vec2 pos = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);	

	vec2 ps = SourceSize.zw;
	vec2 OGL2Pos = pos * SourceSize.xy;
	vec2 fp = fract(OGL2Pos);
	vec2 dx = vec2(ps.x,0.0);
	vec2 dy = vec2(0.0, ps.y);

	vec2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;	
	float f = fp.y; if (InputSize.y > 400.0) f=1.0;
    vec3 f1 = vec3(f); 
	vec3 color = vec3 (0.0);

	// Reading the texels
	vec3 ul = COMPAT_TEXTURE(Texture, pC4     ).xyz; ul*=ul;
	vec3 ur = COMPAT_TEXTURE(Texture, pC4 + dx).xyz; ur*=ur;
	vec3 dl = COMPAT_TEXTURE(Texture, pC4 + dy).xyz; dl*=dl;
	vec3 dr = COMPAT_TEXTURE(Texture, pC4 + ps).xyz; dr*=dr;
	
	float lx = fp.x;        lx = pow(lx, h_sharp);
	float rx = 1.0 - fp.x;  rx = pow(rx, h_sharp);
	
	vec3 color1 = (ur*lx + ul*rx)/(lx+rx);
	vec3 color2 = (dr*lx + dl*rx)/(lx+rx);

// calculating scanlines
	
    color = color1*sw(f1,color1) + color2*sw(1.0-f1,color2);
		
	color = color*Mask(gl_FragCoord.xy*1.0001, color);
	float lum = color.r*0.3+color.g*0.6+color.b*0.1;
	color = pow(color, vec3(gamma_out, gamma_out, gamma_out));
	color*= mix(1.0,brightboost,lum);
	color = saturation(color);
	color*= vign(lum);
	
	#if defined GL_ES
	// hacky clamp fix for GLES
    	vec2 bordertest = (pos);
    		if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        	color = color;
        else
        	color = vec3(0.0);
	#endif

    FragColor = vec4(color, 1.0);
} 
#endif
