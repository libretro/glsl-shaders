/**
 * GBC Color Palette Mixer
 * "Pastel Mix" Edition
 *
 * By Doctor Amaton - Jun/2020
 */

#pragma parameter mixness "Mixness" 0.0 0.0 1.0 0.1

/* Compatibility stuff */
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

/* Global coordinates */
COMPAT_VARYING vec2 tex_coord;

#if defined(VERTEX)
COMPAT_ATTRIBUTE vec2 TexCoord;
COMPAT_ATTRIBUTE vec2 VertexCoord;
uniform mat4 MVPMatrix;

void main()
{
    gl_Position = MVPMatrix * vec4(VertexCoord, 0.0, 1.0);
    tex_coord = TexCoord;
}

#elif defined(FRAGMENT)
uniform sampler2D Texture;

/* Access to the parameter uniforms, or take the default */
#ifdef PARAMETER_UNIFORM
	uniform COMPAT_PRECISION float mixness;
#else
	#define mixness 1.0
#endif

vec4 pastelMixColor(float red) {
	COMPAT_PRECISION int index = int(floor(red * 255.0 / 64.0));

	if (index == 0) {
	    return vec4(0.000, 0.000, 0.000, 1.0);

	} else if (index == 1) {
	    return vec4(0.647, 0.729, 0.937, 1.0);

	} else if (index == 2) {
	    return vec4(0.968, 0.698, 0.709, 1.0);

	} else if (index == 3) {
	    return vec4(1.000, 0.921, 0.776, 1.0);

	} else {
	    return vec4(0.000, 0.000, 0.000, 1.0);
	}
}

void main()
{
	vec4 source = COMPAT_TEXTURE(Texture, tex_coord);
	vec4 swap   = pastelMixColor(source.r);

    gl_FragColor = mix(swap, source, mixness);
}
#endif
