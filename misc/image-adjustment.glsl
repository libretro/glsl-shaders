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
COMPAT_VARYING     float _frame_rotation;
struct input_dummy {
    vec2 _video_size;
    vec2 _texture_size;
    vec2 _output_dummy_size;
    float _frame_count;
    float _frame_direction;
    float _frame_rotation;
float _placeholder26;
};
vec4 _oPosition1;
vec4 _r0006;
COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_VARYING vec4 COL0;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;
 
uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
void main()
{
    vec4 _oColor;
    vec2 _oTexCoord;
    _r0006 = VertexCoord.x*MVPMatrix[0];
    _r0006 = _r0006 + VertexCoord.y*MVPMatrix[1];
    _r0006 = _r0006 + VertexCoord.z*MVPMatrix[2];
    _r0006 = _r0006 + VertexCoord.w*MVPMatrix[3];
    _oPosition1 = _r0006;
    _oColor = COLOR;
    _oTexCoord = TexCoord.xy;
    gl_Position = _r0006;
    COL0 = COLOR;
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
COMPAT_VARYING     float _frame_rotation;
struct input_dummy {
    vec2 _video_size;
    vec2 _texture_size;
    vec2 _output_dummy_size;
    float _frame_count;
    float _frame_direction;
    float _frame_rotation;
float _placeholder27;
};
vec4 _ret_0;
float _TMP4;
float _TMP3;
float _TMP2;
float _TMP1;
input_dummy _IN1;
float mod_y;
float _a0011;
COMPAT_VARYING vec4 TEX0;
 
uniform sampler2D Texture;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// --USER SETTINGS-- //
#define saturation 1.0 		// color saturation; default 1.0
#define monitor_gamma 2.2 	// gamma setting of your current display; LCD monitors typically have a gamma of 2.2
#define target_gamma 2.4 	// the gamma you want the image to have; CRT TVs typically have a gamma of 2.4
#define contrast 1.0 		// image contrast; default 1.0
#define luminance 1.0 		// image luminance; default 1.0
#define bright_boost 0.0	// adds to the total brightness. Negative values decrease it; Use values between 1.0 (totally white) and -1.0 (totally black); default is 0.0
#define R 1.0			// Red channel saturation
#define G 1.0			// Green channel saturation
#define B 1.0			// Blue channel saturation
// --END USER SETTINGS-- //

vec3 grayscale(vec3 col)
{
   // ATSC grayscale standard
   return vec3(dot(col, vec3(0.2126, 0.7152, 0.0722)));
}

void main()
{
    vec3 _res;
	vec3 gamma;
	vec3 AvgLumin;
	vec3 intensity;
	vec3 satColor;
	vec3 conColor;
	vec3 intermed;
	
    _res = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
	gamma = vec3(monitor_gamma / target_gamma); // setup ratio of display's gamma vs desired gamma
	AvgLumin = vec3(0.5, 0.5, 0.5);
	intensity = grayscale(_res); // find luminance
	satColor = mix(intensity, _res, saturation); // apply saturation
	conColor = mix(AvgLumin, satColor, contrast);	// apply contrast
	conColor = pow(conColor, 1.0 / vec3(gamma)); // Apply gamma correction
	conColor = clamp(conColor * luminance, 0.0, 1.0); // apply luminance
	conColor += vec3(bright_boost); // apply brightboost
	conColor *= vec3(R, G, B); // apply color channel adjustment
	vec4 _ret_0 = vec4(conColor, 1.0);

    FragColor = _ret_0;
} 
#endif
