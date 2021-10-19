

/*

- crt-blurPi slang shader -

Looks good on low res screens (640 x 480 or less), providing screen space scanlines.
Works great for anbernic handheld devices.

Made by Oriol Ferrer Mesià (armadillu)
http://uri.cat

MIT license
*/


/////////////////////////////////////////////////////////////////////////////////////////
#pragma stage vertex
/////////////////////////////////////////////////////////////////////////////////////////

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


#pragma name crt-blurPi
#pragma parameter rgbExtraGain "rgbExtraGain" 	0.0 	0.0 	1.0 	0.02
#pragma parameter blurGain "blurGain" 			0.11 	0.0 	0.25 	0.01
#pragma parameter blurRadius "blurRadius" 		0.51 	0.47 	0.7 	0.01


#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float rgbExtraGain;
uniform COMPAT_PRECISION float blurGain;
uniform COMPAT_PRECISION float blurRadius;
#else
#define rgbExtraGain 0.1
#define blurGain 0.15
#define blurRadius 1.5
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 dotSize;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize; //size of screen
uniform COMPAT_PRECISION vec2 TextureSize; //size of our working texture
uniform COMPAT_PRECISION vec2 InputSize; //size of GAME output

void main(){
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    TEX0.xy = TexCoord.xy;
    dotSize = blurRadius * 1.0 / TextureSize;
}
	
/////////////////////////////////////////////////////////////////////////////////////////
#pragma stage fragment
/////////////////////////////////////////////////////////////////////////////////////////


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
uniform COMPAT_PRECISION vec2 OutputSize; //size of screen
uniform COMPAT_PRECISION vec2 TextureSize; //size of our working texture
uniform COMPAT_PRECISION vec2 InputSize; //size of GAME output
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 dotSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float rgbExtraGain;
uniform COMPAT_PRECISION float blurGain;
uniform COMPAT_PRECISION float blurRadius;
#else
#define rgbExtraGain 0.1
#define blurGain 0.15
#define blurRadius 1.5
#endif

void main(){

	vec3 colN = COMPAT_TEXTURE(Texture, TEX0.xy + vec2(0.0, dotSize.y)).rgb;
	vec3 colS = COMPAT_TEXTURE(Texture, TEX0.xy + vec2(0.0, -dotSize.y)).rgb;
	vec3 colE = COMPAT_TEXTURE(Texture, TEX0.xy + vec2(dotSize.x, 0.0)).rgb;
	vec3 colW = COMPAT_TEXTURE(Texture, TEX0.xy + vec2(-dotSize.x, 0.0)).rgb;

	vec3 color = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
	
	float centerG = min(max(1.0 - 4.0 * blurGain, 0.0), 1.0);
    vec3 blur = centerG * color + blurGain * (colN + colS + colE + colW); 
    
    FragColor = vec4( (1.0 + rgbExtraGain) * blur, 1);
} 
#endif
