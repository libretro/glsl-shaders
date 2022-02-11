// Simple scanlines with curvature and mask effects lifted from crt-geom
// original by hunterk

////////////////////////////////////////////////////////////////////
////////////////////////////  SETTINGS  ////////////////////////////
/////  comment these lines to disable effects and gain speed  //////
////////////////////////////////////////////////////////////////////

#define CURVATURE // applies barrel distortion to the screen
#define SCANLINES  // applies horizontal scanline effect



////////////////////////////////////////////////////////////////////
//////////////////////////  END SETTINGS  //////////////////////////
////////////////////////////////////////////////////////////////////

///////////////////////  Runtime Parameters  ///////////////////////

#pragma parameter SCANLINE_SINE_COMP_B "Scanline Intensity" 0.60 0.0 1.0 0.05
#pragma parameter warpX "warpX" 0.03 0.0 0.125 0.01
#pragma parameter warpY "warpY" 0.05 0.0 0.125 0.01
#pragma parameter cgwg "CGWG mask str. " 0.5 0.0 1.0 0.1
#pragma parameter crt_gamma "CRT Gamma" 2.5 1.0 4.0 0.05
#pragma parameter monitor_gamma "Monitor Gamma" 2.2 1.0 4.0 0.05
#pragma parameter boost "Bright boost " 0.00 0.00 1.00 0.02
#pragma parameter SCANLINE_SINE_COMP_A "Scanline Sine Comp A" 0.0 0.0 0.10 0.01
#pragma parameter SCANLINE_BASE_BRIGHTNESS "Scanline Base Brightness" 0.95 0.0 1.0 0.01



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

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SCANLINE_BASE_BRIGHTNESS;
uniform COMPAT_PRECISION float SCANLINE_SINE_COMP_A;
uniform COMPAT_PRECISION float SCANLINE_SINE_COMP_B;
uniform COMPAT_PRECISION float warpX;
uniform COMPAT_PRECISION float warpY;
uniform COMPAT_PRECISION float cgwg;
uniform COMPAT_PRECISION float crt_gamma;
uniform COMPAT_PRECISION float monitor_gamma;
uniform COMPAT_PRECISION float boost;
#else
#define SCANLINE_BASE_BRIGHTNESS 0.95
#define SCANLINE_SINE_COMP_A 0.0
#define SCANLINE_SINE_COMP_B 0.40
#define warpX 0.031
#define warpY 0.041
#define cgwg 0.4
#define crt_gamma 2.2
#define monitor_gamma 2.4
#define boost 0.00
#endif

vec4 scanline(vec2 coord, vec4 frame)
{

	vec2 omega = vec2(3.1415 * OutputSize.x, 2.0 * 3.1415 * TextureSize.y);
	vec2 sine_comp = vec2(SCANLINE_SINE_COMP_A, SCANLINE_SINE_COMP_B);
	vec3 res = frame.xyz;
	
	vec3 scanline = res * (SCANLINE_BASE_BRIGHTNESS + dot(sine_comp * sin(coord * omega), vec2(1.0, 1.0)));

	return vec4(scanline.x, scanline.y, scanline.z, 1.0);


}

#ifdef CURVATURE
// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos)
{
    pos  = pos*2.0-1.0;    
    pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
    
    return pos*0.5 + 0.5;
}

float corner(vec2 coord)
{
                coord *= TextureSize / InputSize;
                coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
                coord = min(coord, vec2(1.0)-coord) * vec2(1.0, InputSize.y/InputSize.x);
                vec2 cdist = vec2(0.03); // alter value to change corner size
                coord = (cdist - min(coord,cdist));
                float dist = sqrt(dot(coord,coord));
                return clamp((cdist.x-dist)*300.0,0.0, 1.0);
}  
#endif

// mask calculation
	// cgwg mask.
	vec4 Mask(vec2 pos)
	{
	  vec3 mask = vec3(1.0);
	{
      float mf = floor(mod(pos.x,2.0));
      float mc = 1.0 - cgwg;	
      if (mf == 0.0) { mask.g = mc; }
      else { mask.r = mc; mask.b = mc; };
   }  
		return vec4(mask, 1.0);
	}


void main()
{
#ifdef CURVATURE
	vec2 pos = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
#else
	vec2 pos = TEX0.xy;
#endif

//borrowed from CRT-Pi
		vec2 OGL2Pos = pos * TextureSize;
		vec2 pC4 = floor(OGL2Pos) + 0.5;
		vec2 coord = pC4 / TextureSize;
		vec2 deltas = OGL2Pos - pC4;
		vec2 signs = sign(deltas);
		deltas.x *= 2.0;
		deltas = deltas * deltas;
		deltas.y = deltas.y * deltas.y;
		deltas.x *= 0.5;
		deltas.y *= 8.0;
		deltas /= TextureSize;
		deltas *= signs;
		vec2 tc = coord + deltas;


// mask effects look bad unless applied in linear gamma space
	vec4 in_gamma = vec4(crt_gamma, crt_gamma, crt_gamma, 1.0);
	vec4 out_gamma = vec4(1.0 / monitor_gamma, 1.0 / monitor_gamma, 1.0 / monitor_gamma, 1.0);
	
	vec4 res = COMPAT_TEXTURE(Texture, tc);
	
	res=pow(res,in_gamma);

	// apply the mask; looks bad with vert scanlines so make them mutually exclusive
	res *= Mask(gl_FragCoord.xy * 1.0001);


#if defined CURVATURE && defined GL_ES
    // hacky clamp fix for GLES
    vec2 bordertest = (tc);
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec4(0.,0.,0.,0.);
#endif

    // re-apply the gamma curve for the mask path
    vec4 color = pow(scanline(pos, res), out_gamma);
    color+=boost*color;
    FragColor = color*corner(tc);

} 
#endif
