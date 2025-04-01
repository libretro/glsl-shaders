// Hack together of fakelottes (shadowmask and curvature)
// and fake-CRT-geom (smooth border and corners)
// by Rogalian aka cools
// Scanline effect stripped from fakelottes, causes moire on low
// resolution devices and we gain a performance with it
// removed.

////////////////////////////////////////////////////////////////////
////////////////////////////  SETTINGS  ////////////////////////////
/////  comment these lines to disable effects and gain speed  //////
////////////////////////////////////////////////////////////////////

#define MASK // fancy, expensive phosphor mask effect
#define CURVATURE // applies barrel distortion to the screen
#define BORDER // border + rounded corners

////////////////////////////////////////////////////////////////////
//////////////////////////  END SETTINGS  //////////////////////////
////////////////////////////////////////////////////////////////////

///////////////////////  Runtime Parameters  ///////////////////////
#pragma parameter shadowMask "shadowMask" 1.0 0.0 4.0 1.0
#pragma parameter warpX "warpX" 0.031 0.0 0.125 0.01
#pragma parameter warpY "warpY" 0.041 0.0 0.125 0.01
#pragma parameter maskDark "maskDark" 0.5 0.0 2.0 0.1
#pragma parameter maskLight "maskLight" 1.5 0.0 2.0 0.1
#pragma parameter crt_gamma "CRT Gamma" 2.5 1.0 4.0 0.05
#pragma parameter monitor_gamma "Monitor Gamma" 2.2 1.0 4.0 0.05
#pragma parameter bsmooth "Border Smoothness" 600.0 40.0 600.0 10.0
#pragma parameter a_corner "Corner Roundness" 0.02 0.0 0.2 0.01

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
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
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define scale vec2(SourceSize.xy/InputSize.xy)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
uniform COMPAT_PRECISION float maskDark;
uniform COMPAT_PRECISION float maskLight;
uniform COMPAT_PRECISION float shadowMask;
uniform COMPAT_PRECISION float crt_gamma;
uniform COMPAT_PRECISION float monitor_gamma;
uniform COMPAT_PRECISION float bsmooth;
uniform COMPAT_PRECISION float a_corner;
#else
#define warpX 0.031
#define warpY 0.041
#define maskDark 0.5
#define maskLight 1.5
#define shadowMask 1.0
#define crt_gamma 2.5
#define monitor_gamma 2.2
#define bsmooth 600.0
#define a_corner 0.03
#endif

#ifdef CURVATURE
// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
    
    return pos*0.5 + 0.5;
}
#endif

#if defined MASK
	// Shadow mask.
	vec4 Mask(vec2 pos)
	{
		vec3 mask = vec3(maskDark, maskDark, maskDark);
	  
		// Very compressed TV style shadow mask.
		if (shadowMask == 1.0) 
		{
			float line = maskLight;
			float odd = 0.0;
			
			if (fract(pos.x*0.166666666) < 0.5) odd = 1.0;
			if (fract((pos.y + odd) * 0.5) < 0.5) line = maskDark;  
			
			pos.x = fract(pos.x*0.333333333);

			if      (pos.x < 0.333) mask.r = maskLight;
			else if (pos.x < 0.666) mask.g = maskLight;
			else                    mask.b = maskLight;
			mask*=line;  
		} 

		// Aperture-grille.
		else if (shadowMask == 2.0) 
		{
			pos.x = fract(pos.x*0.333333333);

			if      (pos.x < 0.333) mask.r = maskLight;
			else if (pos.x < 0.666) mask.g = maskLight;
			else                    mask.b = maskLight;
		} 
		
		else mask = vec3(1.,1.,1.);

		return vec4(mask, 1.0);
	}
#endif

#ifdef BORDER
float corner(vec2 coord)
{
                coord = min(coord, vec2(1.0)-coord);
                vec2 cdist = vec2(a_corner);
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*bsmooth,0.0, 1.0);
}
#endif

void main()
{
#ifdef CURVATURE
	vec2 pos = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
#else
	vec2 pos = TEX0.xy;
#endif

#if defined MASK
	// mask effects look bad unless applied in linear gamma space
	vec4 in_gamma = vec4(crt_gamma, crt_gamma, crt_gamma, 1.0);
	vec4 out_gamma = vec4(1.0 / monitor_gamma, 1.0 / monitor_gamma, 1.0 / monitor_gamma, 1.0);
	vec4 res = pow(COMPAT_TEXTURE(Source, pos), in_gamma);
#else
	vec4 res = COMPAT_TEXTURE(Source, pos);
#endif

#if defined MASK
	// apply the mask; looks bad with vert scanlines so make them mutually exclusive
	res *= Mask(gl_FragCoord.xy * 1.0001);
#endif

#if defined CURVATURE && defined GL_ES
	// hacky clamp fix for GLES
    vec2 bordertest = (pos);
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec4(0.,0.,0.,0.);
#endif

#ifdef BORDER
	if (a_corner >0.0) res *= corner(pos*scale);
#endif

#if defined MASK
	// re-apply the gamma curve for the mask path
    FragColor = pow((pos, res), out_gamma);
#else
	FragColor = (pos, res);
#endif
} 
#endif
