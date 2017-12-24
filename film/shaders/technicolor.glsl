#version 130
// Technicolor
// by hunterk
// license: public domain

// There's a lot of unnecessary crap in this shader because I wanted to follow
// the technicolor process laid out in the Wikipedia article:
// https://en.wikipedia.org/wiki/Technicolor
// The color stuff could be collapsed into a single LUT, if preferred.

// Parameter lines go here:
#pragma parameter k_record "K Record Process" 0.0 0.0 1.0 1.0
#pragma parameter bright_boost "Bright Boost" 3.0 0.0 10.0 0.1
#pragma parameter blue_boost "Blue Boost" 1.0 1.0 1.333333 0.333333
#pragma parameter x_off_r "X Offset Red/Blue" 0.05 -1.0 1.0 0.01
#pragma parameter y_off_r "Y Offset Red/Blue" 0.05 -1.0 1.0 0.01
#pragma parameter x_off_g "X Offset Green" -0.05 -1.0 1.0 0.01
#pragma parameter y_off_g "Y Offset Green" -0.05 -1.0 1.0 0.01
#pragma parameter grain_str "Grain Strength" 6.0 0.0 16.0 1.0
#pragma parameter hotspot "Hotspot Toggle" 1.0 0.0 1.0 1.0
#pragma parameter vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter noise_toggle "Film Scratches" 1.0 0.0 1.0 1.0

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
uniform sampler2D noise1;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float k_record;
uniform COMPAT_PRECISION float bright_boost;
uniform COMPAT_PRECISION float blue_boost;
uniform COMPAT_PRECISION float x_off_r;
uniform COMPAT_PRECISION float y_off_r;
uniform COMPAT_PRECISION float x_off_g;
uniform COMPAT_PRECISION float y_off_g;
uniform COMPAT_PRECISION float grain_str;
uniform COMPAT_PRECISION float hotspot;
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float noise_toggle;
#else
#define k_record 0.0
#define bright_boost 0.0
#define blue_boost 0.0
#define x_off_r 0.05
#define y_off_r 0.05
#define x_off_g -0.05
#define y_off_g -0.05
#define grain_str 0.0
#define hotspot 1.0
#define vignette 1.0
#define noise_toggle 1.0
#endif

//https://www.shadertoy.com/view/4sXSWs strength= 16.0
float filmGrain(vec2 uv, float strength, float timer ){       
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * ((mod(timer, 800.0) + 10.0) * 10.0);
	return  (mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
}

float hash( float n ){
    return fract(sin(n)*43758.5453123);
}

void main()
{
// a simple calculation for the vignette/hotspot effects
	vec2 middle = TEX0.xy - 0.25;
	float len = length(middle);
	float vig = smoothstep(0.0, 0.5, len);

// create the noise effects from a LUT of actual film noise
	vec4 film_noise1 = COMPAT_TEXTURE(noise1, vTexCoord.xx * 2.0 * sin(hash(mod(FrameCount, 47.0))));
	vec4 film_noise2 = COMPAT_TEXTURE(noise1, vTexCoord.xy * 2.0 * cos(hash(mod(FrameCount, 92.0))));

// Begin Technicolor simulation
/*
The Technicolor Process 4 camera, manufactured to Technicolor's detailed
specifications by Mitchell Camera Corporation, contained color filters, a beam
splitter consisting of a partially reflecting surface inside a split-cube prism,
and three separate rolls of black-and-white film (hence the "three-strip"
designation).
*/
// this represents the light entering the camera lens; blue and red share offset
	vec2 red_coord = vTexCoord + 0.01 * vec2(x_off_r, y_off_r);
	vec3 red_light = COMPAT_TEXTURE(Source, red_coord).rgb;
	vec2 green_coord = vTexCoord + 0.01 * vec2(x_off_g, y_off_g);
	vec3 green_light = COMPAT_TEXTURE(Source, green_coord).rgb;
	vec2 blue_coord = vTexCoord + 0.01 * vec2(x_off_r, y_off_r);
	vec3 blue_light = COMPAT_TEXTURE(Source, blue_coord).rgb;

/*The beam splitter allowed ⅓ of the light coming through the camera lens to
pass through the reflector and a green filter and form an image on one of the
strips, which therefore recorded only the green-dominated third of the spectrum.
*/
	vec3 green = green_light * vec3(0.0,1.0,0.0) * 0.333333;

/*The other ⅔ was reflected sideways by the mirror and passed through a magenta
filter, which absorbed green light and allowed only the red and blue thirds of
the spectrum to pass.
*/
	vec3 magenta_light = ((blue_light + red_light));
	magenta_light *= vec3(1.0,0.0,1.0);
/*
Behind this filter were the other two strips of film, their emulsions pressed
into contact face to face. The front film was a red-blind orthochromatic type
that recorded only the blue light. On the surface of its emulsion was a red-
orange coating that prevented blue light from continuing on to the red-sensitive
panchromatic emulsion of the film behind it, which therefore recorded only the
red-dominated third of the spectrum.
*/
	vec3 blue = magenta_light * vec3(0.0,1.0,1.0);
	vec3 red = magenta_light * vec3(1.0,1.0,0.0) * 0.5;
/*
Each of the three resulting negatives was printed onto a special matrix film.
After processing, each matrix was a nearly invisible representation of the
series of film frames as gelatin reliefs, thickest (and most absorbent) where
each image was darkest and thinnest where it was lightest.
*/
	vec3 negative_red = 1.0 - red;
	negative_red += filmGrain(red_coord, grain_str, float(FrameCount));
	vec3 negative_green = 1.0 - green;
	negative_green += filmGrain(green_coord, grain_str, float(FrameCount));
	vec3 negative_blue = 1.0 - blue;
	negative_blue += filmGrain(blue_coord, grain_str, float(FrameCount));
/*
Each matrix was soaked in a dye complementary to the color of light recorded by
the negative printed on it: cyan for red, magenta for green, and yellow for blue
*/
	vec3 r_dyed = 1.0 - negative_red;
	r_dyed += filmGrain(red_coord, grain_str, float(FrameCount));
	vec3 g_dyed = 1.0 - negative_green;
	g_dyed += filmGrain(green_coord, grain_str, float(FrameCount));
	vec3 b_dyed = 1.0 - negative_blue;
	b_dyed += filmGrain(blue_coord, grain_str, float(FrameCount));
/*
A single clear strip of black-and-white film with the soundtrack and frame lines
printed in advance was first treated with a mordant solution and then brought
into contact with each of the three dye-loaded matrix films in turn, building up
the complete color image. 
*/
// NTSC grayscale weights for nonlinear gamma to represent the b&w film
	vec3 technicolor;
	vec3 black_and_white = (COMPAT_TEXTURE(Source, vTexCoord).rgb *
		vec3(0.299, 0.587, 0.114));
	technicolor.r = black_and_white.r * r_dyed.r;
	technicolor.r += filmGrain(red_coord, grain_str, float(FrameCount));
	technicolor.g = black_and_white.g * g_dyed.g;
	technicolor.g += filmGrain(green_coord, grain_str, float(FrameCount));
	technicolor.b = black_and_white.b * b_dyed.b;
	technicolor.b += filmGrain(blue_coord, grain_str, float(FrameCount));

/*
In the early days of the process, the receiver film was pre-printed with a 50%
black-and-white image derived from the green strip, the so-called Key, or K,
record. This procedure was used largely to cover up fine edges in the picture
where colors would mix unrealistically (also known as fringing). This additional
black increased the contrast of the final print and concealed any fringing.
However, overall colorfulness was compromised as a result. In 1944, Technicolor
had improved the process to make up for these shortcomings and the K record was,
therefore, eliminated.
*/
	float K;
	K = green.g * 0.5;
	technicolor += vec3(K,K,K);

    technicolor = technicolor * bright_boost * vec3(1.0,1.0,blue_boost);
// End Technicolor simulation

	technicolor *= (vignette > 0.5) ? (1.0 - vig) : 1.0; // Vignette
	technicolor += ((1.0 - vig) * 0.2) * hotspot; // Hotspot

// Apply noise effects (or not)
	if (hash(FrameCount) > 0.99 && noise_toggle > 0.5)
		FragColor = vec4(mix(technicolor, film_noise1.rgb, film_noise1.a), 1.0);
	else if (hash(FrameCount) < 0.01 && noise_toggle > 0.5)
		FragColor = vec4(mix(technicolor, film_noise2.rgb, film_noise2.a), 1.0);
	else
		FragColor = vec4(technicolor, 1.0);
} 
#endif
