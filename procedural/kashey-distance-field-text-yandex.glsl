#version 120
// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter RETRO_PIXEL_SIZE "Retro Pixel Size" 0.84 0.0 1.0 0.01
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float RETRO_PIXEL_SIZE;
#else
#define RETRO_PIXEL_SIZE 0.84
#endif

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
// out variables go here as COMPAT_VARYING whatever

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
    TEX0.xy = VertexCoord.xy;
// Paste vertex contents here:
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
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// delete all 'params.' or 'registers.' or whatever in the fragment
float iGlobalTime = float(FrameCount)*0.025;
vec2 iResolution = OutputSize.xy;

//#define SHOW_DISTANCE

#define BACK_COL_TOP vec3(1,0,1)
#define BACK_COL_BOTTOM vec3(0,0,1)

#define TEXT_COL1_TOP vec3(0.05, 0.05, 0.40)
#define TEXT_COL1_BOTTOM vec3(0.60, 0.90, 1.00)
#define TEXT_COL2_TOP vec3(0.10, 0.10, 0.00)
#define TEXT_COL2_BOTTOM vec3(1.90, 1.30, 1.00)

//--- Primiives ---
float dfSemiArc(float rma, float rmi, vec2 uv)
{
	return max(abs(length(uv) - rma) - rmi, uv.x-0.0);
}

//p0 = bottom left, clockwise winding
float dfQuad(vec2 p0, vec2 p1, vec2 p2, vec2 p3, vec2 uv)
{
	vec2 s0n = normalize((p1 - p0).yx * vec2(-1,1));
	vec2 s1n = normalize((p2 - p1).yx * vec2(-1,1));
	vec2 s2n = normalize((p3 - p2).yx * vec2(-1,1));
	vec2 s3n = normalize((p0 - p3).yx * vec2(-1,1));
	
	return max(max(dot(uv-p0,s0n),dot(uv-p1,s1n)), max(dot(uv-p2,s2n),dot(uv-p3,s3n)));
}

float dfRect(vec2 size, vec2 uv)
{
	return max(max(-uv.x,uv.x - size.x),max(-uv.y,uv.y - size.y));
}
//-----------------

//--- Letters ---
void S(inout float df, vec2 uv)
{
	df = min(df, dfSemiArc(0.25, 0.125, uv - vec2(-0.250,0.250)));
	df = min(df, dfSemiArc(0.25, 0.125, (uv - vec2(-0.125,-0.25)) * vec2(-1)));
	df = min(df, dfRect(vec2(0.125, 0.250), uv - vec2(-0.250,-0.125)));
	df = min(df, dfQuad(vec2(-0.625,-0.625), vec2(-0.500,-0.375), vec2(-0.125,-0.375), vec2(-0.125,-0.625), uv));	
	df = min(df, dfQuad(vec2(-0.250,0.375), vec2(-0.250,0.625), vec2(0.250,0.625), vec2(0.125,0.375), uv));
}

void N(inout float df, vec2 uv)
{
	df = min(df, dfRect(vec2(0.250, 1.250), uv - vec2(-0.625,-0.625)));
    df = min(df, dfRect(vec2(0.250, 1.250), uv - vec2(-0.000,-0.625)));
	df = min(df, dfQuad(vec2(-0.375,-0.125), vec2(-0.375,0.125), vec2(0.000, 0.125), vec2(-0.125,-0.125), uv));	
}

void A(inout float df, vec2 uv)
{
	df = min(df, dfRect(vec2(0.250, 0.825), uv - vec2(-0.625,-0.625)));
    df = min(df, dfRect(vec2(0.250, 0.825), uv - vec2(-0.000,-0.625)));
	df = min(df, dfQuad(vec2(-0.375,-0.125), vec2(-0.375,0.125), vec2(0.000, 0.125), vec2(-0.125,-0.125), uv));	
    df = min(df, dfSemiArc(0.3125, 0.125, (uv.yx - vec2(0.1875,-0.1875)) * -1.0));
}

void D(inout float df, vec2 uv)
{
	df = min(df, dfRect(vec2(0.250, 1.25), uv - vec2(-0.625,-0.625)));
    df = min(df, dfSemiArc(0.5, 0.125, (uv.xy * vec2(-1,1) - vec2(0.375,-0.00))));
}

void E(inout float df, vec2 uv)
{
	df = min(df, dfRect(vec2(0.250, 1.250), uv - vec2(-0.625,-0.625)));    
    df = min(df, dfQuad(vec2(-0.375,-0.625), vec2(-0.375,-0.375), vec2(0.250, -0.375), vec2( 0.125,-0.625), uv));	
    df = min(df, dfQuad(vec2(-0.375,0.375), vec2(-0.375,0.625), vec2(0.250, 0.625), vec2(0.125, 0.375), uv));	   
    df = min(df, dfQuad(vec2(-0.375,-0.125), vec2(-0.375,0.125), vec2(0.000, 0.125), vec2(-0.125,-0.125), uv));	
}

void R(inout float df, vec2 uv)
{
	df = min(df, dfRect(vec2(0.250, 1.250), uv - vec2(-0.625,-0.625)));
    df = min(df, dfSemiArc(0.25, 0.125, (uv.xy * vec2(-1,1) - vec2(0.125,0.25))));    
    df = min(df, dfRect(vec2(0.25, 0.250), uv - vec2(-0.375,0.375)));
    df = min(df, dfQuad(vec2(-0.375,-0.125), vec2(-0.250,0.125), vec2(0.000, 0.125), vec2(-0.125,-0.125), uv));	
    df = min(df, dfQuad(vec2(-0.375,-0.125), vec2(-0.1,-0.125), vec2(0.250,-0.625), vec2(-0.025,-0.625), uv));	

}

void T(inout float df, vec2 uv)
{
    df = min(df, dfRect(vec2(0.250, 1.0), uv - vec2(-0.3125,-0.625))); 
	df = min(df, dfQuad(vec2(-0.625, 0.375), vec2(-0.625,0.625), vec2(0.250, 0.625), vec2(0.125, 0.375), uv));	
}

void O(inout float df, vec2 uv)
{
    df = min(df, dfRect(vec2(0.25, 0.375), uv - vec2( 0.000,-0.1875)));  
    df = min(df, dfRect(vec2(0.25, 0.375), uv - vec2(-0.625,-0.1875)));  
    df = min(df, dfSemiArc(0.3125, 0.125, (uv.yx - vec2(0.1875,-0.1875)) * -1.0));
    df = min(df, dfSemiArc(0.3125, 0.125, (uv.yx - vec2(-0.1875,-0.1875)) ));
}

void Y(inout float df, vec2 uv)
{
    df = min(df, dfRect(vec2(0.25, 0.25), uv - vec2( 0.000,0.375)));  
    df = min(df, dfRect(vec2(0.25, 0.25), uv - vec2(-0.625,0.375)));  
    df = min(df, dfSemiArc(0.3125, 0.125, (uv.yx - vec2(0.375,-0.1875)) ));
    df = min(df, dfRect(vec2(0.250, 0.75), uv - vec2(-0.3125,-0.625))); 
}

void X(inout float df, vec2 uv)
{
    df = min(df, dfRect(vec2(0.25, 0.25), uv - vec2( 0.000,0.375)));   
    df = min(df, dfRect(vec2(0.25, 0.25), uv - vec2(-0.625,0.375)));  
    df = min(df, dfSemiArc(0.3125, 0.125, (uv.yx - vec2(0.375,-0.1875)) ));
    df = min(df, dfSemiArc(0.3125, 0.125, (-uv.yx + vec2(-0.375,-0.1855)) ));
    //df = min(df, dfRect(vec2(0.250, 0.75), uv - vec2(-0.3125,-0.625)));
    
    df = min(df, dfRect(vec2(0.25, 0.25), uv - vec2( 0.000,-0.575)));   
    df = min(df, dfRect(vec2(0.25, 0.25), uv - vec2(-0.625,-0.575)));
}

//---------------

//--- Gradient Stuff ---
//returns 0-1 when xn is between x0-x1
float linstep(float x0, float x1, float xn)
{
	return (xn - x0) / (x1 - x0);
}

vec3 retrograd(float x0, float x1, float m, vec2 uv)
{
	float mid = x0+(x1 - x0) * m;

	vec3 grad1 = mix(TEXT_COL1_BOTTOM, TEXT_COL1_TOP, linstep(mid, x1, uv.y));
    vec3 grad2 = mix(TEXT_COL2_BOTTOM, TEXT_COL2_TOP, linstep(x0, mid, uv.y));

	return mix(grad2, grad1, smoothstep(mid, mid + 0.04, uv.y));
}
//----------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 aspect = iResolution.xy/iResolution.y;
	vec2 uv = ( fragCoord.xy / iResolution.y );
	
	uv = (uv - aspect/2.0)*8.0;
	
    //Text distance field
	float dist = 1e6;
	
	vec2 chSpace = vec2(1.125,1.500);
	
	vec2 chuv = uv;
	chuv.x += (chSpace.x * 7.0) / 2.0 - 0.75;
		
	Y(dist, chuv); chuv.x -= chSpace.x;
	A(dist, chuv); chuv.x -= chSpace.x;
	N(dist, chuv); chuv.x -= chSpace.x;
	D(dist, chuv); chuv.x -= chSpace.x;
    E(dist, chuv); chuv.x -= chSpace.x;
    X(dist, chuv); chuv.x -= chSpace.x;
    
    dist /= 2.0;
    
    //Colors and mixing mask
	float mask = smoothstep(4.0 / iResolution.y, 0.00, dist);
    
	vec3 textcol = retrograd(-0.75, 0.50, 0.40 + pow(abs(dist), 0.25) * 0.08, uv);
	
	vec3 backcol = mix(BACK_COL_BOTTOM, BACK_COL_TOP, (uv.y/4.0)+0.5) * smoothstep(0.02, 0.025, dist);
	
    //Grid Stuff
	vec2 gdef = vec2(uv.x / abs(uv.y), 1.0 / (uv.y));
	gdef.y = clamp(gdef.y,-1e2, 1e2);
	
	vec2 gpos = vec2(0.0,-iGlobalTime);
	
	gdef += gpos;
	
	vec2 grep = mod(gdef*vec2(1.0,2.0), vec2(1.0));
	
	float grid = max(abs(grep.x - 0.5),abs(grep.y - 0.5));
	
	float gs = length(gdef-gpos)*0.01;
	
	backcol *= mix(smoothstep(0.46-gs,0.48+gs,grid), 1.0, step(0.0,uv.y))*0.75+0.25;
	
    //Mixing text with background
	vec3 color = mix(backcol,textcol,mask);
	
    #ifdef SHOW_DISTANCE
    color = vec3(sin(dist*48.0));
    #endif
    
	fragColor = vec4( vec3( color ), 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
