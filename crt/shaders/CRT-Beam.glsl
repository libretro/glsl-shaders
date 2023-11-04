/*
	crt-beam
	for best results use integer scale 5x or more
*/

#pragma parameter blur "Horizontal Blur/Beam shape" 0.6 0.0 1.0 0.1
#pragma parameter Scanline "Scanline thickness" 0.2 0.0 1.0 0.05
#pragma parameter weightr "Scanline Red brightness" 0.8 0.0 1.0 0.05
#pragma parameter weightg "Scanline Green brightness" 0.8 0.0 1.0 0.05
#pragma parameter weightb "Scanline Blue brightness" 0.8 0.0 1.0 0.05
#pragma parameter bogus_msk " [ MASKS ] " 0.0 0.0 0.0 0.0
#pragma parameter mask "Mask 0:CGWG,1-2:Lottes,3-4 Gray,5-6:CGWG slot,7 VGA" 3.0 -1.0 7.0 1.0
#pragma parameter msk_size "Mask size" 1.0 1.0 2.0 1.0
#pragma parameter scale "VGA Mask Vertical Scale" 2.0 2.00 10.00 1.0
#pragma parameter MaskDark "Lottes Mask Dark" 0.7 0.00 2.00 0.10
#pragma parameter MaskLight "Lottes Mask Light" 1.0 0.00 2.00 0.10
#pragma parameter bogus_col " [ COLOR ] " 0.0 0.0 0.0 0.0
#pragma parameter sat "Saturation" 1.0 0.00 2.00 0.05
#pragma parameter bright "Boost bright" 1.0 1.00 2.00 0.05
#pragma parameter dark "Boost dark" 1.45 1.00 2.00 0.05
#pragma parameter glow "Glow Strength" 0.08 0.0 0.5 0.01


#define pi 3.14159

#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif


uniform vec2 TextureSize;
varying vec2 TEX0;
varying vec2 fragpos;

#if defined(VERTEX)
uniform mat4 MVPMatrix;
attribute vec4 VertexCoord;
attribute vec2 TexCoord;
uniform vec2 InputSize;
uniform vec2 OutputSize;

void main()
{
	TEX0 = TexCoord*1.0001;                    
	gl_Position = MVPMatrix * VertexCoord;  
	fragpos = TEX0.xy*OutputSize.xy*TextureSize.xy/InputSize.xy;   
}

#elif defined(FRAGMENT)

uniform sampler2D Texture;
uniform vec2 OutputSize;
uniform vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outSize vec4(OutputSize.xy, 1.0/OutputSize.xy/4.0)
#define FragColor gl_FragColor
#define Source Texture


#ifdef PARAMETER_UNIFORM

uniform COMPAT_PRECISION float blur;
uniform COMPAT_PRECISION float Scanline;
uniform COMPAT_PRECISION float weightr;
uniform COMPAT_PRECISION float weightg;
uniform COMPAT_PRECISION float weightb;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float scale;
uniform COMPAT_PRECISION float msk_size;
uniform COMPAT_PRECISION float MaskDark;
uniform COMPAT_PRECISION float MaskLight;
uniform COMPAT_PRECISION float bright;
uniform COMPAT_PRECISION float dark;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float glow;

#else

#define blur 0.6
#define Scanline 0.2
#define weightr  0.2
#define weightg  0.6
#define weightb  0.1
#define mask      7.0   
#define msk_size  1.0
#define scale   2.0
#define MaskDark  0.5
#define MaskLight  1.5
#define bright  1.5
#define dark  1.25
#define glow      0.05   
#define sat       1.0

#endif

vec4 Mask (vec2 p)
{		
		p = floor(p/msk_size);
		float mf=fract(p.x*0.5);
		float m=MaskDark;
		vec3 Mask = vec3 (MaskDark);

// Phosphor.
	if (mask==0.0)
	{
		if (mf < 0.5) return vec4 (MaskLight,m,MaskLight,1.0); 
		else return vec4 (m,MaskLight,m,1.0);
	}

// Very compressed TV style shadow mask.
	else if (mask == 1.0)
	{
		float line = MaskLight;
		float odd  = 0.0;

		if (fract(p.x/6.0) < 0.5)
			odd = 1.0;
		if (fract((p.y + odd)/2.0) < 0.5)
			line = MaskDark;

		p.x = fract(p.x/3.0);
    
		if      (p.x < 0.333) Mask.r = MaskLight;
		else if (p.x < 0.666) Mask.g = MaskLight;
		else                  Mask.b = MaskLight;
		
		Mask*=line;
		return vec4 (Mask.r, Mask.g, Mask.b,1.0);  
	} 

// Aperture-grille.
	else if (mask == 2.0)
	{
		p.x = fract(p.x/3.0);

		if      (p.x < 0.333) Mask.r = MaskLight;
		else if (p.x < 0.666) Mask.g = MaskLight;
		else                  Mask.b = MaskLight;
		return vec4 (Mask.r, Mask.g, Mask.b,1.0);  

	} 
// gray
	else if (mask==3.0)
	{
		
		if (mf < 0.5) return vec4 (MaskLight,MaskLight,MaskLight,1.0); 
		else return vec4 (m,m,m,1.0);
	}
//gray 3px
	else if (mask==4.0)
	{
		float mf=fract(p.x*0.3333);
		if (mf < 0.6666) return vec4 (MaskLight,MaskLight,MaskLight,1.0); 
		else return vec4 (m,m,m,1.0);
	}
//cgwg slot
	else if (mask == 5.0)
	{
		float line = MaskLight;
		float odd  = 0.0;

		if (fract(p.x/4.0) < 0.5)
			odd = 1.0;
		if (fract((p.y + odd)/2.0) < 0.5)
			line = MaskDark;

		p.x = fract(p.x/2.0);
    
		if  (p.x < 0.5) {Mask.r = 1.0; Mask.b = 1.0;}
		else  Mask.g = 1.0;	
		Mask*=line;  
		return vec4 (Mask.r, Mask.g, Mask.b,1.0);  

	} 

//cgwg slot 1440p
	else if (mask == 6.0)
	{
		float line = MaskLight;
		float odd  = 0.0;

		if (fract(p.x/6.0) < 0.5)
			odd = 1.0;
		if (fract((p.y + odd)/3.0) < 0.5)
			line = MaskDark;

		p.x = fract(p.x/2.0);
    
		if  (p.x < 0.5) {Mask.r = MaskLight; Mask.b = MaskLight;}
			else  {Mask.g = MaskLight;}	
		
		Mask*=line; 
		return vec4 (Mask.r, Mask.g, Mask.b,1.0);   
	} 

//PC CRT VGA style mask
	else if (mask == 7.0)
	{
		float line = 1.0;
		p.x = fract(p.x/2.0);

		if (fract(p.y/scale) < 0.5)
			{
				if  (p.x < 0.5) {Mask.r = 1.0; Mask.b = 1.0;}
				else  {Mask.g = 1.0;}	
			}
		else
			{
				if  (p.x < 0.5) {Mask.g = 1.0;}	
				else   {Mask.r = 1.0; Mask.b = 1.0;}
	}
		Mask*=line;
		return vec4 (Mask.r, Mask.g, Mask.b,1.0);   

	} 
else return vec4(1.0);
}
vec3 booster (vec2 pos)
{
	vec2 dx = vec2(SourceSize.z,0.0);
	vec2 dy = vec2(0.0,SourceSize.w);

	vec4 c00 = texture2D(Source,pos);
	vec4 c01 = texture2D(Source,pos+dx);
	vec4 c02 = texture2D(Source,pos+dy);
	vec4 c03 = texture2D(Source,pos+dx+dy);

	vec4 gl = (c00+c01+c02+c03)/4.0; gl *=gl;
	vec3 gl0 = gl.rgb;
	return gl0*glow;
}

void main()
{	
	vec2 pos =vTexCoord;
	vec2 OGL2Pos = pos*TextureSize;
	vec2 cent = (floor(OGL2Pos)+0.5)/TextureSize;
	float xcoord = mix(cent.x,vTexCoord.x,blur);
	vec2 coords = vec2(xcoord, cent.y);

	vec3 res= texture2D(Source, coords).rgb;

	float lum = max(max(res.r*weightr,res.g*weightg),res.b*weightb);
	float f = fract(OGL2Pos.y);
	
	res *= 1.0-(f-0.5)*(f-0.5)*45.0*(Scanline*(1.0-lum));
	res = clamp(res,0.0,1.0);
	
	float l = dot(res,vec3(0.3,0.6,0.1));
	res = mix(vec3(l), res, sat);
	res += booster(coords);
	vec4 res0 = vec4(res,1.0); 
	res0 *= Mask(fragpos*1.0001);
	res0 *= mix(dark,bright,l);
	
	FragColor = res0;
}
#endif
