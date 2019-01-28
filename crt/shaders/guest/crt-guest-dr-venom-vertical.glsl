/*
   CRT - Guest - Dr. Venom
   
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
#pragma parameter IOS "Smart X Integer Scaling" 0.0 0.0 1.0 1.0
#pragma parameter OS "R. Bloom Overscan Mode" 2.0 0.0 2.0 1.0
#pragma parameter BLOOM "Raster bloom %" 0.0 0.0 20.0 1.0
#pragma parameter brightboost "Bright boost" 1.10 0.50 2.00 0.01
#pragma parameter saturation "Saturation adjustment" 1.0 0.1 2.0 0.05
#pragma parameter gsl "Alternate scanlines" 0.0 0.0 1.0 1.0
#pragma parameter scanline "Scanline adjust" 8.0 1.0 12.0 1.0
#pragma parameter beam_min "Scanline dark" 1.30 0.5 2.0 0.05
#pragma parameter beam_max "Scanline bright" 1.00 0.5 2.0 0.05
#pragma parameter h_sharp "Horizontal sharpness" 4.0 1.5 20.0 0.25
#pragma parameter s_sharp "Substractive sharpness" 0.10 0.0 0.20 0.01
#pragma parameter csize "Corner size" 0.0 0.0 0.05 0.01
#pragma parameter warpX "CurvatureX (default 0.03)" 0.0 0.0 0.125 0.01
#pragma parameter warpY "CurvatureY (default 0.04)" 0.0 0.0 0.125 0.01
#pragma parameter glow "Glow Strength" 0.04 0.0 0.5 0.01
#pragma parameter shadowMask "Mask Style (0 = CGWG)" -1.0 -1.0 5.0 1.0
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.1
#pragma parameter maskLight "Lottes maskLight" 1.5 0.0 2.0 0.1
#pragma parameter CGWG "CGWG Mask Str." 0.4 0.0 1.0 0.05
#pragma parameter GTW "Gamma Tweak" 1.10 0.5 1.5 0.01
#pragma parameter gamma_out "Gamma out" 2.4 1.0 3.0 0.05

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
uniform sampler2D PassPrev3Texture;
uniform sampler2D PassPrev4Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float IOS;
uniform COMPAT_PRECISION float OS;
uniform COMPAT_PRECISION float BLOOM;
uniform COMPAT_PRECISION float brightboost;
uniform COMPAT_PRECISION float saturation;
uniform COMPAT_PRECISION float gsl;
uniform COMPAT_PRECISION float scanline;
uniform COMPAT_PRECISION float beam_min;
uniform COMPAT_PRECISION float beam_max;
uniform COMPAT_PRECISION float h_sharp;
uniform COMPAT_PRECISION float s_sharp;
uniform COMPAT_PRECISION float csize;
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
uniform COMPAT_PRECISION float glow;
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
uniform COMPAT_PRECISION float CGWG;
uniform COMPAT_PRECISION float GTW;
uniform COMPAT_PRECISION float gamma_out;
#else
#define IOS          0.00     // Smart Integer Scaling
#define OS           2.00     // Do overscan
#define BLOOM        0.00     // Bloom overscan percentage
#define brightboost  1.10     // adjust brightness
#define saturation   1.00     // 1.0 is normal saturation
#define gsl          0.0      // Alternate scanlines
#define scanline     8.0      // scanline param, vertical sharpness
#define beam_min     1.30	  // dark area beam min - wide
#define beam_max     1.00 	  // bright area beam max - narrow
#define h_sharp      5.00     // pixel sharpness
#define s_sharp      0.00     // substractive sharpness
#define csize        0.00     // corner size
#define warpX        0.031    // Curvature X
#define warpY        0.041    // Curvature Y
#define glow         0.04     // Glow Strength
#define shadowMask   0.00     // Mask Style
#define maskDark     0.50     // Dark "Phosphor"
#define maskLight    1.50     // Light "Phosphor"
#define CGWG         0.40     // CGWG Mask Strength
#define GTW          1.10     // Gamma tweak
#define gamma_out    2.40     // output gamma
#endif


#define eps 1e-10

float b_min = 1.0 + 7.0*(beam_min - 0.5)*0.666666666;
float b_max = 1.0 + 7.0*(beam_max - 0.5)*0.666666666;
float scn_s = 0.3 + 0.7*(scanline - 1.0)*0.090909090;
	
vec3 sw(float x, vec3 color)
{
	vec3 tmp = mix(vec3(beam_min),vec3(beam_max), color);
	vec3 ex = vec3(x)*tmp;
	return exp2(-scanline*ex*ex);
} 

vec3 sw2(float x, vec3 c)
{
	vec3 s = mix(vec3(b_min), vec3(b_max), c);
	return clamp(smoothstep(vec3(0.0), vec3(scn_s), pow(vec3(x),s)), 0.0001, 1.0);
} 

// Shadow mask (mostly from PD Lottes shader).
vec3 Mask(vec2 pos)
{
   vec3 mask = vec3(maskDark, maskDark, maskDark);
   float mf = floor(mod(pos.x,2.0));
   float mf2 = floor(mod(pos.x + pos.y,2.0));   
   float mc = 1.0 - CGWG;   
   float mc2 = mc * 0.7;
   
  // No mask
   if (shadowMask == -1.0)
   {
      mask = vec3(1.0);
   }       

   // Light mask.
   else if (shadowMask == 5.0)
   {
      if (mf2 == 0.0) { mask = vec3(1.0); }
      else { mask = vec3(mc2); }
   }    
   
   // Phosphor.
   else if (shadowMask == 0.0)
   {
      if (mf == 0.0) { mask.r = 1.0; mask.g = mc; mask.b = 1.0; }
      else { mask.r = mc; mask.g = 1.0; mask.b = mc; }
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

   return mask;
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

float Overscan2(float pos, float dy){
  pos=pos*2.0-1.0;    
  pos*=dy;
  return pos*0.5+0.5;
} 

// Borrowed from cgwg's crt-geom, under GPL

float corner(vec2 coord)
{
                coord *= SourceSize.xy / InputSize.xy;
                coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
                coord = min(coord, vec2(1.0)-coord) * vec2(1.0, OutputSize.y/OutputSize.x);
                vec2 cdist = vec2(max(csize,0.002));
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*700.0,0.0, 1.0);
}  

const float sqrt3     = 1.732050807568877;

vec3 gamma_correct(vec3 color, vec3 tmp)
{
	return color*mix(GTW, 1.0, max(max(tmp.r,tmp.g),tmp.b));
}

void main()
{
	vec3 lum = COMPAT_TEXTURE(PassPrev4Texture, vec2(0.33,0.33)).xyz;

	// Calculating texel coordinates
	
	vec2 texcoord = TEX0.xy;
	if (IOS == 1.0){
		float ofactor = OutputSize.x/InputSize.x;
		float intfactor = round(ofactor);
		float diff = ofactor/intfactor;
		texcoord.x = Overscan2(TEX0.x*(SourceSize.x/InputSize.x), diff)*(InputSize.x/SourceSize.x); 
	}
	
	float factor  = 1.00 + (1.0-0.5*OS)*BLOOM/100.0 - lum.x*BLOOM/100.0;
	texcoord  = Overscan(texcoord*(SourceSize.xy/InputSize.xy), factor, factor)*(InputSize.xy/SourceSize.xy);
	vec2 pos  = Warp(texcoord*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
	vec2 pos0 = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
	
	vec2 ps = SourceSize.zw;
	vec2 OGL2Pos = pos * SourceSize.xy - vec2(0.5,0.0);
	vec2 fp = fract(OGL2Pos);
	vec2 dx = vec2(ps.x,0.0);
	vec2 dy = vec2(0.0, ps.y);

	vec2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;	
	
	// Reading the texels
	vec2 y2 = 2.0*dy;
	
	bool sharp = (s_sharp > 0.0);
	
	float wl2 = 1.5 + fp.y; wl2*=wl2; wl2 = exp2(-h_sharp*wl2); wl2 = max(wl2 - s_sharp, -wl2);
	float wl1 = 0.5 + fp.y; wl1*=wl1; wl1 = exp2(-h_sharp*wl1); wl1 = max(wl1 - s_sharp, -0.4*s_sharp);
	float wct = 0.5 - fp.y; wct*=wct; wct = exp2(-h_sharp*wct); wct = max(wct - s_sharp,  s_sharp);
	float wr1 = 1.5 - fp.y; wr1*=wr1; wr1 = exp2(-h_sharp*wr1); wr1 = max(wr1 - s_sharp, -0.4*s_sharp);
	float wr2 = 2.5 - fp.y; wr2*=wr2; wr2 = exp2(-h_sharp*wr2); wr2 = max(wr2 - s_sharp, -wr2);

	float wt = 1.0/(wl2+wl1+wct+wr1+wr2);
	
	vec3 l2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -y2).xyz;
	vec3 l1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -dy).xyz;
	vec3 ct = COMPAT_TEXTURE(PassPrev3Texture, pC4    ).xyz;
	vec3 r1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +dy).xyz;
	vec3 r2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +y2).xyz;

	vec3 color1 = (l2*wl2 + l1*wl1 + ct*wct + r1*wr1 + r2*wr2)*wt;
	if (sharp) color1 = clamp(color1, min(min(l1,r1),ct), max(max(l1,r1),ct)); 
	
	l2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -y2 +dx).xyz;
	l1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -dy +dx).xyz;
	ct = COMPAT_TEXTURE(PassPrev3Texture, pC4     +dx).xyz;	
	r1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +dy +dx).xyz;
	r2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +y2 +dx).xyz;

	vec3 color2 = (l2*wl2 + l1*wl1 + ct*wct + r1*wr1 + r2*wr2)*wt;
	if (sharp) color2 = clamp(color2, min(min(l1,r1),ct), max(max(l1,r1),ct)); 
	
// calculating scanlines
	
	float f = fp.x;
	
	vec3 w1 = sw(f,color1);
	vec3 w2 = sw(1.0-f,color2); 
	
	if (gsl == 1.0) { w1 = sw2(1.0-f,color1); w2 = sw2(f,color2);}
	
	vec3 color = color1*w1 + color2*w2;
	vec3 ctmp  = color/(w1+w2);
	
	color = pow(color, vec3(1.0/gamma_out));
	float l = length(color);
	color = normalize(pow(color + vec3(eps), vec3(saturation,saturation,saturation)))*l;	
	color*=brightboost;	
	color = gamma_correct(color,ctmp);
	color = pow(color, vec3(gamma_out));
	color = min(color, 1.0);	
	
// Apply Mask

	color = color*Mask(gl_FragCoord.yx * 1.000001);
	
	vec3 Bloom = COMPAT_TEXTURE(Texture, pos).xyz;
	
	color+=glow*Bloom;
	color = min(color, 1.0);
	
	color = pow(color, vec3(1.0/gamma_out));
    FragColor = vec4(color*corner(pos0), 1.0);
} 
#endif
