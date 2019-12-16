/*
   CRT - Guest - SM (Scanline Mask) Shader
   
   Copyright (C) 2019 guest(r) - guest.r@gmail.com

   Big thanks to Nesguy from the Libretro forums for the masks and other ideas.
   
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

/*   README - MASKS GUIDE

To obtain the best results with masks 0, 1, 3, 4: 
must leave “mask size” at 1 and the display must be set to its native resolution to result in evenly spaced “active” LCD subpixels.

Mask 0: Uses a magenta and green pattern for even spacing of the LCD subpixels.

Mask 1: Intended for displays that have RBG subpixels (as opposed to the more common RGB). 
Uses a yellow/blue pattern for even spacing of the LCD subpixels.

Mask 2: Common red/green/blue pattern.

Mask 3: This is useful for 4K displays, where masks 0 and 1 can look too fine. 
Uses a red/yellow/cyan/blue pattern to result in even spacing of the LCD subpixels.

Mask 4: Intended for displays that have the less common RBG subpixel pattern. 
This is useful for 4K displays, where masks 0 and 1 can look too fine. 
Uses a red/magenta/cyan/green pattern for even spacing of the LCD subpixels.

*/


// Parameter lines go here:
#pragma parameter smart "Smart Y Integer Scaling" 0.0 0.0 1.0 1.0
#pragma parameter brightboost "Bright boost" 1.15 0.5 2.0 0.05
#pragma parameter scanline "Scanline adjust" 8.0 1.0 12.0 1.0
#pragma parameter beam_min "Scanline dark" 1.35 0.5 2.0 0.05
#pragma parameter beam_max "Scanline bright" 1.05 0.5 2.0 0.05
#pragma parameter s_gamma "Scanline gamma" 2.4 1.5 3.0 0.05
#pragma parameter h_sharp "Horizontal sharpness" 2.0 1.0 5.0 0.05
#pragma parameter mask "CRT Mask (3&4 are 4k masks)" 0.0 0.0 4.0 1.0
#pragma parameter maskstr "Raw CRT Mask Strength" 0.15 0.0 1.0 0.05
#pragma parameter masksize "CRT Mask Size" 1.0 1.0 2.0 1.0
#pragma parameter gamma_out "Gamma Out" 2.40 1.0 3.0 0.05

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
uniform COMPAT_PRECISION float smart;
uniform COMPAT_PRECISION float brightboost;
uniform COMPAT_PRECISION float scanline;
uniform COMPAT_PRECISION float beam_min;
uniform COMPAT_PRECISION float beam_max;
uniform COMPAT_PRECISION float s_gamma;
uniform COMPAT_PRECISION float h_sharp;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float maskstr;
uniform COMPAT_PRECISION float masksize;
uniform COMPAT_PRECISION float gamma_out;
#else
#define brightboost  0.00     // smart Y integer scaling
#define brightboost  1.15     // adjust brightness
#define scanline     8.00     // scanline param, vertical sharpness
#define beam_min     1.35     // dark area beam min - narrow
#define beam_max     1.05     // bright area beam max - wide
#define s_gamma      2.40     // scanline gamma
#define h_sharp      1.25     // pixel sharpness
#define mask         0.00     // crt mask
#define maskstr      0.15     // raw crt mask strength
#define masksize     1.00     // crt mask size
#define gamma_out    2.40     // gamma out
#endif

float st(float x)
{
	return exp2(-scanline*x*x);
}  

vec3 sw(float x, vec3 color)
{
	vec3 tmp = mix(vec3(2.75*beam_min),vec3(beam_max), color);
	tmp = mix(vec3(beam_max), tmp, pow(vec3(x), color+0.3));
	vec3 ex = vec3(x)*tmp;
	return exp2(-scanline*ex*ex)/(0.65 + 0.35*color);
}

float Overscan(float pos, float dy){
  pos=pos*2.0-1.0;    
  pos*=dy;
  return pos*0.5+0.5;
}

void main()
{
	vec2 tex = TEX0.xy * 1.000001;

	if (smart == 1.0)
	{
		float factor = OutputSize.y/InputSize.y;
		float intfactor = round(factor);
		float diff = factor/intfactor;
		tex.y = Overscan(tex.y*(SourceSize.y/InputSize.y), diff)*(InputSize.y/SourceSize.y); 
	}
	
	vec2 OGL2Pos = tex * SourceSize.xy - vec2(0.5);
	vec2 fp = fract(OGL2Pos);

	vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * SourceSize.zw;	
	
	// Reading the texels
	vec3 ul = COMPAT_TEXTURE(Texture, pC4                         ).xyz; ul*=ul;
	vec3 ur = COMPAT_TEXTURE(Texture, pC4 + vec2(SourceSize.z,0.0)).xyz; ur*=ur;
	vec3 dl = COMPAT_TEXTURE(Texture, pC4 + vec2(0.0,SourceSize.w)).xyz; dl*=dl;
	vec3 dr = COMPAT_TEXTURE(Texture, pC4 + SourceSize.zw         ).xyz; dr*=dr;
	
	float lx = fp.x;        lx = pow(lx, h_sharp);
	float rx = 1.0 - fp.x;  rx = pow(rx, h_sharp);
	
	float w = 1.0/(lx+rx);
	
	vec3 color1 = w*(ur*lx + ul*rx);
	vec3 color2 = w*(dr*lx + dl*rx);


	ul*=ul*ul; ul*=ul;
	ur*=ur*ur; ur*=ur;
	dl*=dl*dl; dl*=dl;
	dr*=dr*dr; dr*=dr;	
	
	vec3 scolor1 = w*(ur*lx + ul*rx); scolor1 = pow(scolor1, vec3(s_gamma*(1.0/12.0)));
	vec3 scolor2 = w*(dr*lx + dl*rx); scolor2 = pow(scolor2, vec3(s_gamma*(1.0/12.0)));	
	
// calculating scanlines
	
	float f = fp.y;

	float t1 = st(f);
	float t2 = st(1.0-f);
	
	vec3 color = color1*t1 + color2*t2;
	vec3 scolor = scolor1*t1 + scolor2*t2;
	
	vec3 ctemp = color / (t1 + t2);
	vec3 sctemp = scolor / (t1 + t2);
	
	vec3 cref1 = mix(scolor1, sctemp, 0.35);
	vec3 cref2 = mix(scolor2, sctemp, 0.35);
	
	vec3 w1 = sw(f,cref1);
	vec3 w2 = sw(1.0-f,cref2);
	
	color = color1*w1 + color2*w2;
	color = min(color, 1.0);
	
	vec3 scan3 = vec3(0.0);
	float spos = floor((gl_FragCoord.x * 1.000001)/masksize); float spos1 = 0.0;
	vec3 tmp1 = 0.5*(ctemp+sqrt(ctemp));

	if (mask == 0.0)
	{
		spos1 = fract(spos*0.5);
		if      (spos1 < 0.5)  scan3.rb = color.rb;
		else                   scan3.g  = color.g;	
	}
	else
	if (mask == 1.0)
	{
		spos1 = fract(spos*0.5);
		if      (spos1 < 0.5)  scan3.rg = color.rg;
		else                   scan3.b  = color.b;
	}
	else
	if (mask == 2.0)
	{
		spos1 = fract(spos/3.0);
		if      (spos1 < 0.333)  scan3.r = color.r;
		else if (spos1 < 0.666)  scan3.g = color.g;
		else                     scan3.b = color.b;
	}
	else
	if (mask == 3.0)
	{
		spos1 = fract(spos*0.25);
		if      (spos1 < 0.25)  scan3.r = color.r;
		else if (spos1 < 0.50)  scan3.rg = color.rg;
		else if (spos1 < 0.75)  scan3.gb = color.gb;	
		else                    scan3.b  = color.b;	
	}
	else	
	{
		spos1 = fract(spos*0.25);
		if      (spos1 < 0.25)  scan3.r = color.r;
		else if (spos1 < 0.50)  scan3.rb = color.rb;
		else if (spos1 < 0.75)  scan3.gb = color.gb;
		else                    scan3.g =  color.g;
	}
	
	color = mix(1.15*scan3, color, (1.0-maskstr)*tmp1)*(1.0 + 0.15*maskstr);
	
	color*=brightboost;
	float corr = (max(max(color.r,color.g),color.b) + 0.0001);
	if (corr < 1.0) corr = 1.0;
	color = color/corr;

	color = pow(color, vec3(1.0/gamma_out));
    FragColor = vec4(color, 1.0);
} 
#endif
