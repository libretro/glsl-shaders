
#pragma parameter R "Red Channel" 1.1 0.0 2.0 0.01
#pragma parameter G "Green Channel" 1.05 0.0 2.0 0.01
#pragma parameter B "Blue Channel" 1.2 0.0 2.0 0.01
#pragma parameter gamma "Gamma" 0.9 0.0 2.0 0.01
#pragma parameter sat "Saturation" 0.83 0.0 2.0 0.01
#pragma parameter bright "Brightness" 1.06 0.0 2.0 0.01
#pragma parameter BLACK  "Black Level" 0.06 -0.20 0.20 0.01 


#define pi 3.14159

#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float something;
#else

#define something 1.0

#endif

/* COMPATIBILITY
   - GLSL compilers
*/

uniform vec2 TextureSize;
varying vec2 TEX0;

#if defined(VERTEX)
uniform mat4 MVPMatrix;
attribute vec4 VertexCoord;
attribute vec2 TexCoord;
uniform vec2 InputSize;
uniform vec2 OutputSize;

void main()
{
	TEX0 = TexCoord;                    
	gl_Position = MVPMatrix * VertexCoord;     
}

#elif defined(FRAGMENT)

uniform sampler2D Texture;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define FragColor gl_FragColor
#define Source Texture

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float R;
uniform COMPAT_PRECISION float G;
uniform COMPAT_PRECISION float B;
uniform COMPAT_PRECISION float gamma;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float bright;
uniform COMPAT_PRECISION float BLACK; 

#else
#define R 1.0
#define G 1.0
#define B 1.0
#define gamma 1.1
#define res 1.0
#define BLACK 0.0
#define bright 1.0
#define sat 1.0

#endif

void main()
{
	vec3 res = texture2D(Source, vTexCoord).rgb;
	res *= bright;
	res = pow(res,vec3(gamma));
	res *= vec3(R,G,B);
		vec3 lumweight = vec3(0.29,0.6,0.11);
		float l = dot(lumweight, res);
		vec3 grays = vec3(l);
		res = mix(grays,res,sat);
  	res -= vec3(BLACK);
        res *= vec3(1.0)/vec3(1.0-BLACK);
	FragColor = vec4(res, 1.0);
}
#endif
