// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

//const   vec4 Size = vec4( 1024.0, 512.0, 0.0009765625, 0.001953125 );
const   vec4 Size = vec4( 2048.0, 1024.0, 0.00048828125, 0.0009765625 );

const   mat3 RGBtoYIQ = mat3(0.299, 0.596, 0.212, 
                             0.587,-0.275,-0.523, 
                             0.114,-0.321, 0.311);

const   mat3 YIQtoRGB = mat3(1.0, 1.0, 1.0,
                             0.95568806036115671171,-0.27158179694405859326,-1.1081773266826619523,
                             0.61985809445637075388,-0.64687381613840131330, 1.7050645599191817149);

const   vec3 val00 = vec3( 1.2, 1.2, 1.2);

const	vec4 exp = vec4(30.0);

float Cdistance(vec3 c1, vec3 c2){
	float rmean = (c1.r+c2.r)*0.5;
	c1 = pow(c1-c2,vec3(2.0));
	return sqrt((2.0+rmean)*c1.r+4.0*c1.g+(3.0-rmean)*c1.b);
}

vec3 Interpolate( vec3 a, vec3 b ) {
	return ( a + b ) * 0.5;
}

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE COMPAT_TEXTURE
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
uniform int SourceDirection;
uniform int SourceCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
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

uniform int SourceDirection;
uniform int SourceCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	vec2 frac = fract(vTexCoord*SourceSize.xy);
	vec2 TexCoord = (floor(vTexCoord*SourceSize.xy)+0.5)*SourceSize.zw;
	vec4 shift  = vec4( SourceSize.zw,-SourceSize.zw);
	vec4 shift2 = 2.0*shift;

	vec3 C00 = COMPAT_TEXTURE(Source, TexCoord + shift2.zw                ).rgb;
	vec3 C01 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift2.w)).rgb;
	vec3 C02 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift2.w)).rgb;
	vec3 C03 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , shift2.w)).rgb;
	vec3 C04 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, shift2.w)).rgb;

	vec3 C05 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift.w )).rgb;
	vec3 C06 = COMPAT_TEXTURE(Source, TexCoord + shift.zw                 ).rgb;
	vec3 C07 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift.w )).rgb;
	vec3 C08 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , shift.w )).rgb;
	vec3 C09 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, shift.w )).rgb;

	vec3 C10 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, 0.0     )).rgb;
	vec3 C11 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , 0.0     )).rgb;
	vec3 C12 = COMPAT_TEXTURE(Source, TexCoord                            ).rgb;
	vec3 C13 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , 0.0     )).rgb;
	vec3 C14 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, 0.0     )).rgb;

	vec3 C15 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift.y )).rgb;
	vec3 C16 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift.y )).rgb;
	vec3 C17 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift.y )).rgb;
	vec3 C18 = COMPAT_TEXTURE(Source, TexCoord + shift.xy                 ).rgb;
	vec3 C19 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.x, shift.y )).rgb;

	vec3 C20 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift2.z, shift2.y)).rgb;
	vec3 C21 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.z , shift2.y)).rgb;
	vec3 C22 = COMPAT_TEXTURE(Source, TexCoord + vec2( 0.0     , shift2.y)).rgb;
	vec3 C23 = COMPAT_TEXTURE(Source, TexCoord + vec2( shift.x , shift2.y)).rgb;
	vec3 C24 = COMPAT_TEXTURE(Source, TexCoord + shift2.xy                ).rgb;

	float C03C09 = Cdistance(C03,C09);
	float C02C08 = Cdistance(C02,C08);
	float C08C14 = Cdistance(C08,C14);
	float C01C07 = Cdistance(C01,C07);
	float C07C13 = Cdistance(C07,C13);
	float C13C19 = Cdistance(C13,C19);
	float C00C06 = Cdistance(C00,C06);
	float C06C12 = Cdistance(C06,C12);
	float C12C18 = Cdistance(C12,C18);
	float C18C24 = Cdistance(C18,C24);
	float C05C11 = Cdistance(C05,C11);
	float C11C17 = Cdistance(C11,C17);
	float C17C23 = Cdistance(C17,C23);
	float C10C16 = Cdistance(C10,C16);
	float C16C22 = Cdistance(C16,C22);
	float C15C21 = Cdistance(C15,C21);

	vec4 d01 = vec4(
	C02C08 + C01C07 + C07C13 + C00C06 + C06C12 + C12C18 + C05C11 + C11C17 + C10C16,
	C03C09 + C02C08 + C08C14 + C01C07 + C07C13 + C13C19 + C06C12 + C12C18 + C11C17,
	C07C13 + C06C12 + C12C18 + C05C11 + C11C17 + C17C23 + C10C16 + C16C22 + C15C21,
	C08C14 + C07C13 + C13C19 + C06C12 + C12C18 + C18C24 + C11C17 + C17C23 + C16C22);

	d01 = pow(d01,exp)+1.0;

	float C01C05 = Cdistance(C01,C05);
	float C02C06 = Cdistance(C02,C06);
	float C06C10 = Cdistance(C06,C10);
	float C03C07 = Cdistance(C03,C07);
	float C07C11 = Cdistance(C07,C11);
	float C11C15 = Cdistance(C11,C15);
	float C04C08 = Cdistance(C04,C08);
	float C08C12 = Cdistance(C08,C12);
	float C12C16 = Cdistance(C12,C16);
	float C16C20 = Cdistance(C16,C20);
	float C09C13 = Cdistance(C09,C13);
	float C13C17 = Cdistance(C13,C17);
	float C17C21 = Cdistance(C17,C21);
	float C14C18 = Cdistance(C14,C18);
	float C18C22 = Cdistance(C18,C22);
	float C19C23 = Cdistance(C19,C23);

	vec4 d02 = vec4(
	C01C05 + C02C06 + C06C10 + C03C07 + C07C11 + C11C15 + C08C12 + C12C16 + C13C17,
	C02C06 + C03C07 + C07C11 + C04C08 + C08C12 + C12C16 + C09C13 + C13C17 + C14C18,
	C06C10 + C07C11 + C11C15 + C08C12 + C12C16 + C16C20 + C13C17 + C17C21 + C18C22,
	C07C11 + C08C12 + C12C16 + C09C13 + C13C17 + C17C21 + C14C18 + C18C22 + C19C23);

	d02 = pow(d02,exp)+1.0;

	vec4 w01 = 1.0 / d01;
	vec4 w02 = 1.0 / d02;
	vec4 w03 = w01 + w02;
	     w03 = 1.0 / w03;

	vec4 weight01 = w01 * w03;
	vec4 weight02 = w02 * w03;

	vec3 DR0 = Interpolate( C06, C12 ); 
	vec3 UR0 = Interpolate( C07, C11 ); 

	vec3 DR1 = Interpolate( C07, C13 ); 
	vec3 UR1 = Interpolate( C08, C12 ); 

	vec3 DR2 = Interpolate( C11, C17 ); 
	vec3 UR2 = Interpolate( C12, C16 ); 

	vec3 DR3 = Interpolate( C12, C18 ); 
	vec3 UR3 = Interpolate( C13, C17 ); 

	vec3 sum0 = DR0 * weight01.x + UR0 * weight02.x; 
	vec3 sum1 = DR1 * weight01.y + UR1 * weight02.y;
	vec3 sum2 = DR2 * weight01.z + UR2 * weight02.z;
	vec3 sum3 = DR3 * weight01.w + UR3 * weight02.w;

	FragColor = vec4(mix(mix(sum0,sum1,frac.x),mix(sum2,sum3,frac.x),frac.y), 1.0);
} 
#endif
