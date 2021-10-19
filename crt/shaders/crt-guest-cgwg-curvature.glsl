/*
   CRT - Guest - Nomask w. Curvature
   
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
#pragma parameter brightboost "Bright boost" 1.1 0.5 2.0 0.05
#pragma parameter saturation "Saturation adjustment" 1.1 0.1 2.0 0.05
#pragma parameter scanline "Scanline adjust" 8.0 1.0 12.0 1.0
#pragma parameter beam_min "Scanline dark" 1.70 0.5 3.0 0.05
#pragma parameter beam_max "Scanline bright" 2.1 0.5 3.0 0.05
#pragma parameter h_sharp "Horizontal sharpness" 2.00 1.0 5.0 0.05
#pragma parameter gamma_out "Gamma out" 0.5 0.2 0.6 0.01
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.1
#pragma parameter CGWG "CGWG Mask Str." 0.4 0.0 1.0 0.1
#pragma parameter warpX "warpX" 0.0 0.0 0.125 0.01
#pragma parameter warpY "warpY" 0.0 0.0 0.125 0.01

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
uniform COMPAT_PRECISION float saturation;
uniform COMPAT_PRECISION float scanline;
uniform COMPAT_PRECISION float beam_min;
uniform COMPAT_PRECISION float beam_max;
uniform COMPAT_PRECISION float h_sharp;
uniform COMPAT_PRECISION float gamma_out;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float CGWG;
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
#else
#define brightboost  1.20     // adjust brightness
#define saturation   1.10     // 1.0 is normal saturation
#define scanline     8.0      // scanline param, vertical sharpness
#define beam_min     1.70	  // dark area beam min - wide
#define beam_max     2.10 	  // bright area beam max - narrow
#define h_sharp      1.25     // pixel sharpness
#define gamma_out    0.50     // output gamma
#define maskDark     0.50     // Dark "Phosphor"
#define CGWG         0.40     // CGWG Mask Strength
#define warpX        0.0    // Curvature X
#define warpY        0.0    // Curvature Y
#endif

float sw(float x, float l)
{
	float d = x;
	float bm = scanline;
	float b = mix(beam_min,beam_max,l);
	d = exp2(-bm*pow(d,b));
	return d;
}

vec3 Mask(vec2 pos)
{
   vec3 mask = vec3(maskDark, maskDark, maskDark);

   // Phosphor.
  
   {
      float mf = floor(mod(pos.x,2.0));
      float mc = 1.0 - CGWG;	
      if (mf == 0.0) { mask.r = 1.0; mask.g = mc; mask.b = 1.0; }
      else { mask.r = mc; mask.g = 1.0; mask.b = mc; };
   }    
   
      return mask;
} 

// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
    return pos*0.5 + 0.5;
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
	
	float f = fp.y;
	float luma1 = length(color1)*0.57735;
	float luma2 = length(color2)*0.57735;
	
	vec3 color = color1*sw(f,luma1) + color2*sw(1.0-f,luma2);
	
	color*=brightboost;
	color = min(color, 1.0);

	color = pow(color, vec3(gamma_out, gamma_out, gamma_out));
	
	float l = length(color);
	color = normalize(pow(color, vec3(saturation,saturation,saturation)))*l;
	color = color*Mask(gl_FragCoord.xy);	

    FragColor = vec4(color, 1.0);
} 
#endif
