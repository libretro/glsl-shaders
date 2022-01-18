
// Parameter lines go here:
#pragma parameter Scanline "Scanline overall Strength" 0.5 0.0 2.0 0.05
#pragma parameter weightr "Scanline Red Weight" 0.04 0.0 0.8 0.01
#pragma parameter weightg "Scanline Green Weight" 0.324 0.0 0.8 0.01
#pragma parameter weightb "Scanline Blue Weight" 0.04 0.0 0.8 0.01
#pragma parameter gap "Scanline gap Brightness" 0.06 0.0 1.0 0.01
#pragma parameter blur "Blur Horizontal" 0.70 0.00 1.20 0.10
#pragma parameter glow "Glow Strength" 0.08 0.0 0.3 0.01
#pragma parameter mask "Mask -1:Off,0:CGWG,1-2:Lottes,3-4 Gray,5-6:CGWG slot,7 VGA" 7.0 -1.0 7.0 1.0
#pragma parameter msk_size "Mask size" 1.0 1.0 2.0 1.0
#pragma parameter scale "VGA Mask Vertical Scale" 2.0 2.00 10.00 1.0
#pragma parameter MaskDark "Lottes Mask Dark" 0.50 0.00 2.00 0.10
#pragma parameter MaskLight "Lottes Mask Light" 1.50 0.00 2.00 0.10
#pragma parameter bright "Brightness" 1.06 0.00 2.00 0.02
#pragma parameter sat "Saturation, 1.0:Off" 1.30 0.00 2.00 0.05
#pragma parameter contrast "Contrast, 1.0:Off" 1.1 0.00 2.00 0.05
#pragma parameter WP "Color Temperature %, 0.0:Off" -10.0 -100.0 100.0 5.0 
#pragma parameter gamma "Gamma correct, 0.0:Off" 0.42 0.00 0.60 0.01

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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 invDims;


vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy * 1.0001;
    invDims = 1.0/TextureSize.xy;

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
uniform sampler2D PassPrev2Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 invDims;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy


#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float Scanline;
uniform COMPAT_PRECISION float weightr;
uniform COMPAT_PRECISION float weightg;
uniform COMPAT_PRECISION float weightb;
uniform COMPAT_PRECISION float gap;
uniform COMPAT_PRECISION float blur;
uniform COMPAT_PRECISION float glow;
uniform COMPAT_PRECISION float mask;
uniform COMPAT_PRECISION float msk_size;
uniform COMPAT_PRECISION float scale;
uniform COMPAT_PRECISION float MaskDark;
uniform COMPAT_PRECISION float MaskLight;
uniform COMPAT_PRECISION float bright;
uniform COMPAT_PRECISION float gamma;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float contrast;
uniform COMPAT_PRECISION float WP;


#else
#define Scanline  1.0
#define weightr  0.33
#define weightg  0.33
#define weightb  0.33
#define gap 	  0.12
#define mask      0.0
#define blur      0.5
#define glow      0.05   
#define msk_size  1.0
#define scale   2.0
#define MaskDark  0.5
#define MaskLight  1.5
#define bright    1.06
#define gamma     0.45
#define sat       1.1
#define contrast  1.0
#define WP  0.0

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
    
		if  (p.x < 0.5) {Mask.r = MaskLight; Mask.b = MaskLight;}
		else  Mask.g = MaskLight;	
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
				if  (p.x < 0.5) {Mask.r = MaskLight; Mask.b = MaskLight;}
				else  {Mask.g = MaskLight;}	
			}
		else
			{
				if  (p.x < 0.5) {Mask.g = MaskLight;}	
				else   {Mask.r = MaskLight; Mask.b = MaskLight;}
	}
		Mask*=line;
		return vec4 (Mask.r, Mask.g, Mask.b,1.0);   

	} 
else return vec4(1.0);
}
//CRT-Pi scanline code adjusted so that scanline takes in to account the actual emmited pixel light,
// e.g. blue emits less light on actual CRT.
float CalcScanLine(float dy, vec3 col)
{

	float lum = (col.r*weightr + col.g*weightg + col.b*weightb);
	lum=pow(1.5,lum)-1.0+(lum/2.0);

	lum=min(lum,0.95);
	float scan = 1.0;
	float scanl= dy*dy*20.0*(Scanline-lum); scanl = max(scanl,0.0);
	if (dy<=0.50 )
		scan = max(1.0-scanl, gap);

	return scan;
}

vec4 booster (float pos, vec3 col)
{

	float lum = (col.r*weightr + col.g*weightg + col.b*weightb);
	lum = min (lum,0.9);

	float bo=lum*glow;
	
	if (fract(pos*0.5)>0.5)
		return vec4(bo);
	else return vec4(0.0);	

}


// Code from https://www.shadertoy.com/view/XdcXzn
mat4 saturationMatrix( float saturation )
{
    vec3 luminance = vec3( 0.3086, 0.6094, 0.1520 );
    
    float oneMinusSat = 1.0 - saturation;
    
    vec3 red = vec3( luminance.x * oneMinusSat ); red+= vec3( saturation, 0, 0 );
    
    vec3 green = vec3( luminance.y * oneMinusSat ); green += vec3( 0, saturation, 0 );
    
    vec3 blue = vec3( luminance.z * oneMinusSat ); blue += vec3( 0, 0, saturation );
    
    return mat4( red,     0,
                 green,   0,
                 blue,    0,
                 0, 0, 0, 1 );
}

mat4 contrastMatrix( float contrast )
{
	float t = ( 1.0 - contrast ) / 2.0;
    
    return mat4( contrast, 0, 0, 0,
                 0, contrast, 0, 0,
                 0, 0, contrast, 0,
                 t, t, t, 1 );

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
//Zfast-CRT filter
	vec2 pos = TEX0.xy;
	vec2 p = pos * TextureSize; 
	vec2 i = floor(p)*1.0001 + 0.5;
	vec2 f = p - i;
	p = (i + 4.0*f*f*f)*invDims;
	p.x = mix(p.x, pos.x, blur);

	vec4 screen = COMPAT_TEXTURE(Source, p);
//BRIGHTNESS
	screen*=vec4(bright);

	vec3 mcolor = vec3 (screen.r,screen.g ,screen.b);
	float scanLineWeight = CalcScanLine(f.y, mcolor);

//COLOR TEMPERATURE FROM GUEST.R-DR.VENOM
if (WP !=0.0){
	vec3 warmer = D50_to_XYZ*mcolor;
	warmer = XYZ_to_D65*warmer;	
	vec3 cooler = D65_to_XYZ*mcolor;
	cooler = XYZ_to_D50*cooler;
	float m = abs(WP)/100.0;
	vec3 comp = (WP < 0.0) ? cooler : warmer;	
	screen = vec4(mix(mcolor, comp, m),1.0);
}

//FAKE GAMMA IN
if (gamma !=0.0) {screen = screen * screen;}

//APPLY MASK
if (mask !=-1.0){screen *= Mask(gl_FragCoord.xy*1.0001);}

//GAMMA OUT
if (gamma !=0.0){screen = pow(screen,vec4(gamma,gamma,gamma,1.0));}
//BOOST COLORS	
if (glow !=0.0)	{screen+= booster(f.y, mcolor);}
//APPLY SCANLINES
	screen *= scanLineWeight;
if (contrast !=1.0) {screen = contrastMatrix(contrast)*screen;}
    
if (sat !=1.0) FragColor = saturationMatrix(sat)*screen;
		else FragColor = screen;
} 
#endif