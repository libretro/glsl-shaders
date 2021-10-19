
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
#pragma parameter scanlineGain 		"scanlineGain" 		0.15 	0.0 	1.0 	0.05
#pragma parameter scanlineVertical 	"scanlineVertical" 	0.0 	0.0 	1.0 	1.0


COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize; //size of screen
uniform COMPAT_PRECISION vec2 TextureSize; //size of our working texture
uniform COMPAT_PRECISION vec2 InputSize; //size of GAME output

void main(){
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    TEX0.xy = TexCoord.xy;
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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float scanlineGain;
uniform COMPAT_PRECISION float scanlineVertical;
#else
#define scanlineGain 0.3
#define scanlineVertical 0.0
#endif

void main(){

	float texCN;
	float scanLine;	
	if(scanlineVertical > 0.5){
	 	//y tex coods so that screen maps exactly to [0..1]
 		texCN = TEX0.x * TextureSize.x / InputSize.x;
 		scanLine = mod(texCN * OutputSize.x * 0.5, 1.0);
 	}else{
 		//y tex coods so that screen maps exactly to [0..1]
 		texCN = TEX0.y * TextureSize.y / InputSize.y;
 		scanLine = mod(texCN * OutputSize.y * 0.5, 1.0);
 	}
	scanLine = (scanLine > 0.5) ? 1.0 + scanlineGain * 0.5 : 1.0 - scanlineGain * 0.5;
	vec3 color = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
    FragColor = vec4( color * scanLine, 1.0 );
    
} 
#endif
