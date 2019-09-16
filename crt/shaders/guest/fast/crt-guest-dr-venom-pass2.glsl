/*
   CRT - Guest - Dr. Venom - Pass2
   
   Copyright (C) 2018-2019 guest(r) - guest.r@gmail.com

   Incorporates many good ideas and suggestions from Dr. Venom.
   
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

#pragma parameter brightboost "Bright boost" 1.30 0.50 2.00 0.01
#pragma parameter IOS "Smart Y Integer Scaling" 0.0 0.0 1.0 1.0
#pragma parameter gsl "Scanline Type" 1.0 0.0 2.0 1.0
#pragma parameter scanline1 "Scanline beam shape low" 8.0 1.0 15.0 1.0
#pragma parameter scanline2 "Scanline beam shape high" 8.0 5.0 23.0 1.0
#pragma parameter beam_min "Scanline dark" 1.25 0.5 2.0 0.05
#pragma parameter beam_max "Scanline bright" 1.05 0.5 2.0 0.05
#pragma parameter s_power  "Scanline intensity" 1.0 0.5 2.5 0.05
#pragma parameter beam_size "Increased bright scanline beam" 0.65 0.0 1.0 0.05
#pragma parameter shadowMask "CRT Mask: 0:CGWG, 1-4:Lottes, 5-6:'Trinitron'" 5.0 -1.0 6.0 1.0
#pragma parameter masksize "CRT Mask Size (2.0 is nice in 4k)" 1.0 1.0 2.0 1.0
#pragma parameter vertmask "PVM Like Colors" 0.05 0.0 0.25 0.01
#pragma parameter slotmask "Slot Mask Strength" 0.0 0.0 1.0 0.05
#pragma parameter slotwidth "Slot Mask Width" 2.0 2.0 6.0 0.5
#pragma parameter double_slot "Slot Mask Height: 2x1 or 4x1" 1.0 1.0 2.0 1.0
#pragma parameter mcut "Mask 5&6 cutoff" 0.2 0.0 0.5 0.05
#pragma parameter maskDark "Mask Dark" 0.5 0.0 2.0 0.05
#pragma parameter maskLight "Mask Light" 1.5 0.0 2.0 0.05
#pragma parameter CGWG "CGWG Mask Str." 0.3 0.0 1.0 0.05
#pragma parameter gamma_out "Gamma out" 2.4 1.0 3.5 0.05

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
#define round(c) floor(c+0.5)
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
uniform sampler2D PassPrev3Texture;
uniform sampler2D PassPrev4Texture;
uniform sampler2D PassPrev6Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them

uniform COMPAT_PRECISION float brightboost;
uniform COMPAT_PRECISION float IOS;
uniform COMPAT_PRECISION float gsl;
uniform COMPAT_PRECISION float scanline1;
uniform COMPAT_PRECISION float scanline2;
uniform COMPAT_PRECISION float beam_min;
uniform COMPAT_PRECISION float beam_max;
uniform COMPAT_PRECISION float s_power;
uniform COMPAT_PRECISION float beam_size;
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float masksize;
uniform COMPAT_PRECISION float vertmask;
uniform COMPAT_PRECISION float slotmask;
uniform COMPAT_PRECISION float slotwidth;
uniform COMPAT_PRECISION float double_slot;
uniform COMPAT_PRECISION float mcut;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
uniform COMPAT_PRECISION float CGWG;
uniform COMPAT_PRECISION float gamma_out;
#else

#define brightboost  1.40     // adjust brightness
#define IOS          0.00     // smart integer scaling
#define gsl          1.00     // Alternate scanlines
#define scanline1    5.00     // scanline param, vertical sharpness
#define scanline2   12.00     // scanline param, vertical sharpness
#define beam_min     1.30     // dark area beam min - narrow
#define beam_max     1.10     // bright area beam max - wide
#define s_power      1.00     // scanline intensity
#define beam_size    0.65     // increased max. beam size
#define shadowMask   5.00     // Mask Style
#define masksize     1.00     // Mask Size
#define vertmask     0.00     // Vertical mask
#define slotmask     0.00     // Slot Mask ON/OFF
#define slotwidth    2.00     // Slot Mask Width
#define double_slot  1.00     // Slot Mask Height
#define mcut         0.20     // Mask 5&6 cutoff
#define maskDark     0.50     // Dark "Phosphor"
#define maskLight    1.50     // Light "Phosphor"
#define CGWG         0.30     // CGWG Mask Strength
#define gamma_out    2.40     // output gamma
#endif

#define eps 1e-10

float st(float x, float scanline)
{
	return exp2(-scanline*x*x);
} 
   
vec3 sw0(vec3 x, vec3 color, float scanline)
{
	vec3 tmp = mix(vec3(beam_min),vec3(beam_max), color);
	vec3 ex = x*tmp;
	return exp2(-scanline*ex*ex);
} 

vec3 sw1(vec3 x, vec3 color, float scanline)
{	
	float mx = max(max(color.r, color.g),color.b);
	x = mix (x, beam_min*x, max(x-0.4*mx,0.0));
	vec3 tmp = mix(vec3(1.2*beam_min),vec3(beam_max), color);
	vec3 ex = x*tmp;
	float br = clamp(0.8*beam_min - 1.0, 0.2, 0.45);
	return exp2(-scanline*ex*ex)/(1.0-br+br*color);
}    

vec3 sw2(vec3 x, vec3 color, float scanline)
{
	vec3 tmp = mix(vec3(2.75*beam_min),vec3(beam_max), color);
	tmp = mix(vec3(beam_max), tmp, pow(x, vec3(max(max(color.r, color.g),color.b)+0.3)));
	vec3 ex = x*tmp;
	return exp2(-scanline*ex*ex)/(0.6 + 0.4*color);
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
    
		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
		
		mask*=line;  
	} 

	// Aperture-grille.
	else if (shadowMask == 2.0)
	{
		pos.x = fract(pos.x/3.0); 

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3.0)
	{
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4.0)
	{
		pos.xy = floor(pos.xy*vec2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
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
		vec3 maskTmp = vec3( min( 1.5*max(mx-mcut,0.0)/(1.0-mcut) ,maskDark + 0.225*(1.0-maskDark)*mx));
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);
		mask = maskTmp;
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.333) mask.r = adj;
		else if (pos.x < 0.666) mask.g = adj;
		else                    mask.b = adj; 
	}      
	
	return mask;
} 

float SlotMask(vec2 pos, vec3 c)
{
	if (slotmask == 0.0) return 1.0;
	
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

float Overscan2(float pos, float dy){
	pos=pos*2.0-1.0;    
	pos*=dy;
	return pos*0.5+0.5;
}  

void main()
{
	vec2 texcoord = vTexCoord;
	
	if (IOS == 1.0){
		float ofactor = OutputSize.y/InputSize.y;
		float intfactor = round(ofactor);
		float diff = ofactor/intfactor;
		texcoord.y = Overscan2(texcoord.y*(SourceSize.y/InputSize.y), diff)*(InputSize.y/SourceSize.y);
	} 	

	vec2 ps = SourceSize.zw;
	vec2 OGL2Pos = texcoord * SourceSize.xy - vec2(0.0,0.5);
	vec2 fp = fract(OGL2Pos);
	vec2 dx = vec2(ps.x,0.0);
	vec2 dy = vec2(0.0, ps.y);

	vec2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;  
	
	vec3 color1 = COMPAT_TEXTURE(Source, pC4    ).xyz;
	vec3 color2 = COMPAT_TEXTURE(Source, pC4 +dy).xyz;
   
	// calculating scanlines
   
	float f = fp.y;
	float shape1 = mix(scanline1, scanline2, f);
	float shape2 = mix(scanline1, scanline2, 1.0-f);	
	
	float wt1 = st(f, shape1);
	float wt2 = st(1.0-f, shape2);
	vec3 color0 = color1*wt1 + color2*wt2;
	vec3 ctmp = color0/(wt1+wt2);
	vec3 tmp = pow(ctmp, vec3(1.0/gamma_out));
	
	vec3 w1,w2 = vec3(0.0);
	
	vec3 cref1 = mix(ctmp, color1, beam_size);
	vec3 cref2 = mix(ctmp, color2, beam_size);
	
	vec3 shift = vec3(-vertmask, vertmask, -vertmask);
	
	vec3 f1 = clamp(vec3(f) + shift*0.5*(1.0+f), 0.0, 1.0); 
	vec3 f2 = clamp(vec3(1.0-f) - shift*0.5*(2.0-f), 0.0, 1.0);
	
	if (gsl == 0.0) { w1 = sw0(f1,cref1,shape1); w2 = sw0(f2,cref2,shape2);} else
	if (gsl == 1.0) { w1 = sw1(f1,cref1,shape1); w2 = sw1(f2,cref2,shape2);} else
	if (gsl == 2.0) { w1 = sw2(f1,cref1,shape1); w2 = sw2(f2,cref2,shape2);}
	
	vec3 color = color1*pow(w1, vec3(s_power)) + color2*pow(w2, vec3(s_power));
	
	color*=brightboost;
	color = min(color, 1.0); 
	
	// Apply Mask
	
	color *= Mask(gl_FragCoord.xy * 1.000001,tmp);
	
	color = min(color,1.0);
	
	color *= SlotMask(gl_FragCoord.xy * 1.000001,tmp);		
   
	color = pow(color, vec3(1.0/gamma_out));
	FragColor = vec4(color, 1.0);
} 
#endif

