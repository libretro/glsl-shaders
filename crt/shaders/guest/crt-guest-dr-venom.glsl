/*
   CRT - Guest - Dr. Venom
   
   Copyright (C) 2018-2020 guest(r) - guest.r@gmail.com

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
#pragma parameter TATE "TATE Mode" 0.0 0.0 1.0 1.0
#pragma parameter IOS "Smart Integer Scaling: 1.0:Y, 2.0:'X'+Y" 0.0 0.0 2.0 1.0
#pragma parameter OS "R. Bloom Overscan Mode" 1.0 0.0 2.0 1.0
#pragma parameter BLOOM "Raster bloom %" 0.0 0.0 20.0 1.0
#pragma parameter brightboost "Bright Boost Dark Pixels" 1.40 0.50 4.00 0.05
#pragma parameter brightboost1 "Bright Boost Bright Pixels" 1.10 0.50 3.00 0.05
#pragma parameter gsl "Scanline Type" 0.0 0.0 2.0 1.0
#pragma parameter scanline1 "Scanline beam shape low" 6.0 1.0 15.0 1.0
#pragma parameter scanline2 "Scanline beam shape high" 8.0 5.0 23.0 1.0 
#pragma parameter beam_min "Scanline dark" 1.35 0.5 2.5 0.05
#pragma parameter beam_max "Scanline bright" 1.05 0.5 2.0 0.05
#pragma parameter beam_size "Increased bright scanline beam" 0.70 0.0 1.0 0.05
#pragma parameter spike "Scanline Spike Removal" 1.10 0.0 2.0 0.10 
#pragma parameter h_sharp "Horizontal sharpness" 5.25 1.0 15.0 0.25
#pragma parameter s_sharp "Substractive sharpness" 0.40 0.0 1.0 0.10
#pragma parameter csize "Corner size" 0.0 0.0 0.07 0.01
#pragma parameter bsize "Border smoothness" 600.0 100.0 600.0 25.0
#pragma parameter warpX "CurvatureX (default 0.03)" 0.0 0.0 0.125 0.01
#pragma parameter warpY "CurvatureY (default 0.04)" 0.0 0.0 0.125 0.01
#pragma parameter glow "Glow Strength" 0.02 0.0 0.5 0.01
#pragma parameter shadowMask "CRT Mask: 0:CGWG, 1-4:Lottes, 5-6:'Trinitron'" 0.0 -1.0 7.0 1.0
#pragma parameter masksize "CRT Mask Size (2.0 is nice in 4k)" 1.0 1.0 2.0 1.0
#pragma parameter vertmask "PVM Like Colors" 0.0 0.0 0.25 0.01
#pragma parameter slotmask "Slot Mask Strength" 0.0 0.0 1.0 0.05
#pragma parameter slotwidth "Slot Mask Width" 2.0 1.0 6.0 0.5
#pragma parameter double_slot "Slot Mask Height: 2x1 or 4x1" 1.0 1.0 2.0 1.0
#pragma parameter slotms "Slot Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter mcut "Mask 5-7 cutoff" 0.2 0.0 0.5 0.05
#pragma parameter maskDark "Lottes&Trinitron maskDark" 0.5 0.0 2.0 0.05
#pragma parameter maskLight "Lottes&Trinitron maskLight" 1.5 0.0 2.0 0.05
#pragma parameter CGWG "Mask 0&7 Mask Str." 0.3 0.0 1.0 0.05
#pragma parameter gamma_out "Gamma out" 2.4 1.0 3.5 0.05
#pragma parameter inter "Interlace Trigger Resolution :" 400.0 0.0 800.0 25.0
#pragma parameter interm "Interlace Mode (0.0 = OFF):" 1.0 0.0 3.0 1.0
#pragma parameter bloom "Bloom Strength" 0.0 0.0 2.0 0.10
#pragma parameter scans "Scanline 1&2 Saturation" 0.5 0.0 1.0 0.10

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
uniform sampler2D PassPrev2Texture;
uniform sampler2D PassPrev4Texture;
uniform sampler2D PassPrev5Texture;

COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float TATE;
uniform COMPAT_PRECISION float IOS;
uniform COMPAT_PRECISION float OS;
uniform COMPAT_PRECISION float BLOOM;
uniform COMPAT_PRECISION float brightboost;
uniform COMPAT_PRECISION float brightboost1;
uniform COMPAT_PRECISION float gsl;
uniform COMPAT_PRECISION float scanline1;
uniform COMPAT_PRECISION float scanline2;
uniform COMPAT_PRECISION float beam_min;
uniform COMPAT_PRECISION float beam_max;
uniform COMPAT_PRECISION float beam_size;
uniform COMPAT_PRECISION float spike;
uniform COMPAT_PRECISION float h_sharp;
uniform COMPAT_PRECISION float s_sharp;
uniform COMPAT_PRECISION float csize;
uniform COMPAT_PRECISION float bsize;
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
uniform COMPAT_PRECISION float glow;
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float masksize;
uniform COMPAT_PRECISION float vertmask;
uniform COMPAT_PRECISION float slotmask;
uniform COMPAT_PRECISION float slotwidth;
uniform COMPAT_PRECISION float double_slot;
uniform COMPAT_PRECISION float slotms;
uniform COMPAT_PRECISION float mcut;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
uniform COMPAT_PRECISION float CGWG;
uniform COMPAT_PRECISION float gamma_out;
uniform COMPAT_PRECISION float inter;
uniform COMPAT_PRECISION float interm;
uniform COMPAT_PRECISION float bloom;
uniform COMPAT_PRECISION float scans;
#else
#define TATE         0.00     // Screen orientation
#define IOS          0.00     // Smart Integer Scaling
#define OS           2.00     // Do overscan
#define BLOOM        0.00     // Bloom overscan percentage
#define brightboost  1.30     // adjust brightness
#define gsl          0.0      // Alternate scanlines
#define scanline1    8.0      // scanline param, vertical sharpness
#define scanline2    8.0      // scanline param, vertical sharpness
#define beam_min     1.35     // dark area beam min - narrow
#define beam_max     1.05     // bright area beam max - wide
#define beam_size    0.70     // increased max. beam size
#define spike        1.25     // scanline spike removal
#define h_sharp      5.25     // pixel sharpness
#define s_sharp      0.05     // substractive sharpness
#define csize        0.00     // corner size
#define bsize        0.00     // border smoothness
#define warpX        0.00     // Curvature X
#define warpY        0.00     // Curvature Y
#define glow         0.02     // Glow Strength
#define shadowMask   0.00     // Mask Style
#define masksize     1.00     // Mask Size
#define vertmask     0.00     // Vertical mask
#define slotmask     0.00     // Slot Mask ON/OFF
#define slotwidth    2.00     // Slot Mask Width
#define double_slot  1.00     // Slot Mask Height
#define slotms       1.00     // Slot Mask Size
#define mcut         0.20     // Mask 5&6 cutoff
#define maskDark     0.50     // Dark "Phosphor"
#define maskLight    1.50     // Light "Phosphor"
#define CGWG         0.30     // CGWG Mask Strength
#define gamma_out    2.40     // output gamma
#define inter      400.00     // interlace resolution 
#define interm       1.00     // interlace mode  
#define bloom        0.00     // bloom effect 
#define scans        0.50     // scanline saturation
#endif

#define eps 1e-10

float st(float x)
{
	return exp2(-10.0*x*x);
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
	vec3 res = exp2(-scanline*ex*ex)/(1.0-br+br*mx);
	mx = max(max(res.r,res.g),res.b);
	float scans1 = scans; if (vertmask > 0.0) scans1=1.0;
	return mix(vec3(mx), res, scans1);		
}    

vec3 sw2(vec3 x, vec3 color, float scanline)
{
	float mx = max(max(color.r, color.g),color.b);
	vec3 tmp = mix(vec3(2.5*beam_min),vec3(beam_max), color);
	tmp = mix(vec3(beam_max), tmp, pow(abs(x), color+0.3));
	vec3 ex = x*tmp;
	vec3 res = exp2(-scanline*ex*ex)/(0.6 + 0.4*mx);
	mx = max(max(res.r,res.g),res.b);
	float scans1 = scans; if (vertmask > 0.0) scans1=0.75;	
	return mix(vec3(mx), res, scans1);	
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
		vec3 maskTmp = vec3( min( 1.33*max(mx-mcut,0.0)/(1.0-mcut) ,maskDark + 0.225*(1.0-maskDark)*mx));
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);
		mask = maskTmp;
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.333) mask.r = adj;
		else if (pos.x < 0.666) mask.g = adj;
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
	
	return mask;
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
 
// Distortion of scanlines, and end of screen alpha (PD Lottes Curvature)
vec2 Warp(vec2 pos)
{
	pos  = pos*2.0-1.0;    
	pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
	return pos*0.5 + 0.5;
} 

vec2 Overscan(vec2 pos, float dx, float dy){
	pos=pos*2.0-1.0;    
	pos*=vec2(dx,dy);
	return pos*0.5+0.5;
} 

// Borrowed from cgwg's crt-geom, under GPL

float corner(vec2 coord)
{
	coord *= SourceSize.xy / InputSize.xy;
	coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
	coord = min(coord, vec2(1.0)-coord) * vec2(1.0, OutputSize.y/OutputSize.x);
	vec2 cdist = vec2(max(csize, max((1.0-smoothstep(100.0,600.0,bsize))*0.01,0.002)));
	coord = (cdist - min(coord,cdist));
	float dist = sqrt(dot(coord,coord));
	return clamp((cdist.x-dist)*bsize,0.0, 1.0);
}

vec3 declip(vec3 c, float b)
{
	float m = max(max(c.r,c.g),c.b);
	if (m > b) c = c*b/m;
	return c;
}

void main()
{
	float lum = COMPAT_TEXTURE(PassPrev5Texture, vec2(0.05,0.05)).a;

	// Calculating texel coordinates
   
	vec2 texcoord = TEX0.xy;
	if (IOS > 0.0){
		vec2 ofactor = OutputSize.xy/InputSize.xy;
		vec2 intfactor = round(ofactor);
		vec2 diff = ofactor/intfactor;
		float scan = mix(diff.y, diff.x, TATE);
		texcoord = Overscan(texcoord*(SourceSize.xy/InputSize.xy), scan, scan)*(InputSize.xy/SourceSize.xy);
		if (IOS == 1.0) texcoord = mix(vec2(TEX0.x, texcoord.y), vec2(texcoord.x, TEX0.y), TATE);
	}
   
	float factor  = 1.00 + (1.0-0.5*OS)*BLOOM/100.0 - lum*BLOOM/100.0;
	texcoord  = Overscan(texcoord*(SourceSize.xy/InputSize.xy), factor, factor)*(InputSize.xy/SourceSize.xy);
	vec2 pos  = Warp(texcoord*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
	vec2 pos0 = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);

	vec2 coffset = vec2(0.5, 0.5);
	if ((interm == 1.0 || interm == 2.0) && inter <= mix(InputSize.y, InputSize.x, TATE)) coffset = ((TATE < 0.5) ? vec2(0.5,0.0) : vec2(0.0, 0.5));
   
	vec2 ps = SourceSize.zw;
	vec2 OGL2Pos = pos * SourceSize.xy - coffset;
	vec2 fp = fract(OGL2Pos);
	vec2 dx = vec2(ps.x,0.0);
	vec2 dy = vec2(0.0, ps.y);

	// Reading the texels
	vec2 x2 = 2.0*dx;
	vec2 y2 = 2.0*dy;

	vec2 offx = dx;
	vec2 off2 = x2;
	vec2 offy = dy;
	float fpx = fp.x;
	if(TATE > 0.5)
	{
		offx = dy;
		off2 = y2;
		offy = dx;
		fpx = fp.y;
	}
	
	float  f = (TATE < 0.5) ? fp.y : fp.x;
	
	vec2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;
	
	float zero = exp2(-h_sharp);   
	float sharp1 = s_sharp * zero;
	
	float wl3 = 2.0 + fpx;
	float wl2 = 1.0 + fpx;
	float wl1 =       fpx;
	float wr1 = 1.0 - fpx;
	float wr2 = 2.0 - fpx;
	float wr3 = 3.0 - fpx;

	wl3*=wl3; wl3 = exp2(-h_sharp*wl3);	
	wl2*=wl2; wl2 = exp2(-h_sharp*wl2);
	wl1*=wl1; wl1 = exp2(-h_sharp*wl1);
	wr1*=wr1; wr1 = exp2(-h_sharp*wr1);
	wr2*=wr2; wr2 = exp2(-h_sharp*wr2);
	wr3*=wr3; wr3 = exp2(-h_sharp*wr3);
	
	float fp1 = 1.-fpx;

	float twl3 = max(wl3 - sharp1, 0.0);
	float twl2 = max(wl2 - sharp1, mix(0.0,mix(-0.17, -0.025, fp.x),float(s_sharp > 0.05)));
	float twl1 = max(wl1 - sharp1, 0.0);
	float twr1 = max(wr1 - sharp1, 0.0);	
	float twr2 = max(wr2 - sharp1, mix(0.0,mix(-0.17, -0.025, 1.-fp.x),float(s_sharp > 0.05)));
	float twr3 = max(wr3 - sharp1, 0.0);
	
	float wtt = 1.0/(twl3+twl2+twl1+twr1+twr2+twr3);
	float wt  = 1.0/(wl2+wl1+wr1+wr2);
	bool sharp = (s_sharp > 0.05);
	
	vec3 l3 = COMPAT_TEXTURE(PassPrev4Texture, pC4 -off2).xyz;
	vec3 l2 = COMPAT_TEXTURE(PassPrev4Texture, pC4 -offx).xyz;
	vec3 l1 = COMPAT_TEXTURE(PassPrev4Texture, pC4      ).xyz;
	vec3 r1 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +offx).xyz;
	vec3 r2 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +off2).xyz;
	vec3 r3 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +offx+off2).xyz;
	
	vec3 sl2 = COMPAT_TEXTURE(Texture, pC4 -offx).xyz;
	vec3 sl1 = COMPAT_TEXTURE(Texture, pC4      ).xyz;
	vec3 sr1 = COMPAT_TEXTURE(Texture, pC4 +offx).xyz;
	vec3 sr2 = COMPAT_TEXTURE(Texture, pC4 +off2).xyz;
	
	vec3 color1 = (l3*twl3 + l2*twl2 + l1*twl1 + r1*twr1 + r2*twr2 + r3*twr3)*wtt;
	
	vec3 colmin = min(min(l1,r1), min(l2,r2));
	vec3 colmax = max(max(l1,r1), max(l2,r2));
	
	if (sharp) color1 = clamp(color1, colmin, colmax);
	
	vec3 gtmp = vec3(gamma_out*0.1); 
	vec3 scolor1 = color1;
	
	scolor1 = (sl2*wl2 + sl1*wl1 + sr1*wr1 + sr2*wr2)*wt;
	scolor1 = pow(scolor1, gtmp);	vec3 mcolor1 = scolor1;
	scolor1 = mix(color1, scolor1, spike);
	
	pC4+=offy;
	
	l3 = COMPAT_TEXTURE(PassPrev4Texture, pC4 -off2).xyz;
	l2 = COMPAT_TEXTURE(PassPrev4Texture, pC4 -offx).xyz;
	l1 = COMPAT_TEXTURE(PassPrev4Texture, pC4      ).xyz;
	r1 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +offx).xyz;
	r2 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +off2).xyz;
	r3 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +offx+off2).xyz;
	
	sl2 = COMPAT_TEXTURE(Texture, pC4 -offx).xyz;
	sl1 = COMPAT_TEXTURE(Texture, pC4      ).xyz;
	sr1 = COMPAT_TEXTURE(Texture, pC4 +offx).xyz;
	sr2 = COMPAT_TEXTURE(Texture, pC4 +off2).xyz;
	
	vec3 color2 = (l3*twl3 + l2*twl2 + l1*twl1 + r1*twr1 + r2*twr2 + r3*twr3)*wtt;
	
	colmin = min(min(l1,r1), min(l2,r2));
	colmax = max(max(l1,r1), max(l2,r2));
	
	if (sharp) color2 = clamp(color2, colmin, colmax);

	vec3 scolor2 = color2;
	
	scolor2 = (sl2*wl2 + sl1*wl1 + sr1*wr1 + sr2*wr2)*wt;
	scolor2 = pow(scolor2, gtmp);	vec3 mcolor2 = scolor2;
	scolor2 = mix(color2, scolor2, spike);
	
	vec3 color0 = color1;

	if ((interm == 1.0 || interm == 2.0) && inter <= mix(InputSize.y, InputSize.x, TATE))
	{
		pC4-= 2.*offy;
	
		l3 = COMPAT_TEXTURE(PassPrev4Texture, pC4 -off2).xyz;
		l2 = COMPAT_TEXTURE(PassPrev4Texture, pC4 -offx).xyz;
		l1 = COMPAT_TEXTURE(PassPrev4Texture, pC4      ).xyz;
		r1 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +offx).xyz;
		r2 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +off2).xyz;
		r3 = COMPAT_TEXTURE(PassPrev4Texture, pC4 +offx+off2).xyz;
	
		color0 = (l3*twl3 + l2*twl2 + l1*twl1 + r1*twr1 + r2*twr2 + r3*twr3)*wtt;
	
		colmin = min(min(l1,r1), min(l2,r2));
		colmax = max(max(l1,r1), max(l2,r2));
	
		if (sharp) color0 = clamp(color0, colmin, colmax);
	}
	
	// calculating scanlines
	
	float shape1 = mix(scanline1, scanline2, f);
	float shape2 = mix(scanline1, scanline2, 1.0-f);	
	
	float wt1 = st(f);
	float wt2 = st(1.0-f);

	vec3 color00 = color1*wt1 + color2*wt2;
	vec3 scolor0 = scolor1*wt1 + scolor2*wt2;
	vec3 mcolor  = (mcolor1*wt1 + mcolor2*wt2)/(wt1+wt2);
	
	vec3 ctmp = color00/(wt1+wt2);
	vec3 sctmp = scolor0/(wt1+wt2);
	
	vec3 tmp = pow(ctmp, vec3(1.0/gamma_out));
	mcolor = clamp(mix(ctmp, mcolor, 1.5),0.0,1.0);
	mcolor = pow(mcolor, vec3(1.4/gamma_out));
	
	vec3 w1,w2 = vec3(0.0);
	
	vec3 cref1 = mix(sctmp, scolor1, beam_size);
	vec3 cref2 = mix(sctmp, scolor2, beam_size);
	
	vec3 shift = vec3(-vertmask, vertmask, -vertmask);
	
	vec3 f1 = clamp(vec3(f) + shift*0.5*(1.0+f), 0.0, 1.0); 
	vec3 f2 = clamp(vec3(1.0-f) - shift*0.5*(2.0-f), 0.0, 1.0);
	
	if (gsl == 0.0) { w1 = sw0(f1,cref1,shape1); w2 = sw0(f2,cref2,shape2);} else
	if (gsl == 1.0) { w1 = sw1(f1,cref1,shape1); w2 = sw1(f2,cref2,shape2);} else
	if (gsl == 2.0) { w1 = sw2(f1,cref1,shape1); w2 = sw2(f2,cref2,shape2);}
	
	vec3 color = color1*w1 + color2*w2;
	color = min(color, 1.0);
	
	if (interm > 0.5 && inter <= mix(InputSize.y, InputSize.x, TATE)) 
	{	
		if (interm < 3.0)
		{
			float line_no  = floor(mod(mix(  OGL2Pos.y,  OGL2Pos.x, TATE),2.0));		
			float frame_no = floor(mod(float(FrameCount),2.0));
			float ii = (interm > 1.5) ? 0.5 : abs(line_no-frame_no);
			
			vec3 icolor1 = mix(color1, color0, ii);
			vec3 icolor2 = mix(color1, color2, ii);
			
			color = mix(icolor1, icolor2, f);
		} 
		else color = mix(color1, color2, f);
		mcolor = sqrt(color);
	}
	
	ctmp = 0.5*(ctmp+tmp);
	color*=mix(brightboost, brightboost1, max(max(ctmp.r,ctmp.g),ctmp.b));
   
	// Apply Mask
	
	vec3 orig1 = color; float pixbr = max(max(ctmp.r,ctmp.g),ctmp.b); vec3 orig = ctmp; w1 = w1+w2; float w3 = max(max(w1.r,w1.g),w1.b); 
	vec3 cmask = vec3(1.0); vec3 cmask1 = cmask; vec3 one = vec3(1.0);
	
	cmask*= (TATE < 0.5) ? Mask(gl_FragCoord.xy * 1.000001,mcolor) :
		Mask(gl_FragCoord.yx * 1.000001,mcolor);
	
	color = color*cmask;
	
	color = min(color,1.0);
	
	cmask1 *= (TATE < 0.5) ? SlotMask(gl_FragCoord.xy * 1.000001,tmp) :
		SlotMask(gl_FragCoord.yx * 1.000001,tmp);		
	
	color = color*cmask1; cmask = cmask*cmask1; cmask = min(cmask, 1.0);
	
	vec3 Bloom = COMPAT_TEXTURE(PassPrev2Texture, pos).xyz;
   
	vec3 Bloom1 = 2.0*Bloom*Bloom;
	Bloom1 = min(Bloom1, 0.80);
	float bmax = max(max(Bloom1.r,Bloom1.g),Bloom1.b);
	float pmax = mix(0.825, 0.725, pixbr);
	Bloom1 = min(Bloom1, pmax*bmax)/pmax;
	
	Bloom1 = mix(min( Bloom1, color), Bloom1, 0.5*(orig1+color));
	
	Bloom1 = bloom*Bloom1;
	
	color = color + Bloom1;
	
	color = min(color, 1.0);
	if (interm < 0.5 || inter > mix(InputSize.y, InputSize.x, TATE)) color = declip(color, pow(w3,0.5));	
	color = min(color, mix(cmask,one,0.5));

	color = color + glow*Bloom;
		
	color = pow(color, vec3(1.0/gamma_out));
	FragColor = vec4(color*corner(pos0), 1.0);
} 
#endif
