// CRT-torridgristle - ScanlineSimple pass
// license: public domain

// Parameter lines go here:
#pragma parameter ScanlineSize "Scanline Size" 3.0 2.0 32.0 1.0
#pragma parameter YIQAmount "YIQ Amount" 1.0 0.0 1.0 0.05

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
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
uniform COMPAT_PRECISION float ScanlineSize, YIQAmount;
#else
#define ScanlineSize 3.0
#define YIQAmount 1.0
#endif

#define Pi 3.1415926536
const mat3 RGB_to_YIQ = mat3( 0.299 , 0.595716 , 0.211456 ,	0.587    , -0.274453 , -0.522591 ,		0.114    , -0.321263 , 0.311135 );
const mat3 YIQ_to_RGB =   mat3( 1.0   , 1.0      , 1.0      ,	0.9563   , -0.2721   , -1.1070   ,		0.6210   , -0.6474   , 1.7046   );

void main()
{
	vec3 Picture = COMPAT_TEXTURE(Source,vTexCoord).xyz;
    
    float HSBrightness = max(max(Picture.x,Picture.y),max(Picture.y,Picture.z));
    float YIQLuminance = ((0.299*Picture.x) + (0.587*Picture.y) + (0.114*Picture.z));
    
    float HSBYIQHybrid = mix(HSBrightness,YIQLuminance,HSBrightness);
    
	float Scanline = mod((vTexCoord.y * TextureSize.y / InputSize.y)*OutputSize.y,ScanlineSize)/ScanlineSize;
    Scanline = 1.-abs(Scanline-0.5)*2.;
    Scanline = 1.-pow(1.-Scanline,2.0);
    
    Scanline = clamp(sqrt(Scanline)-(1.0-HSBYIQHybrid),0.0,1.0);
    Scanline /= HSBYIQHybrid;



    vec3 YIQApplication = Picture * RGB_to_YIQ;
         YIQApplication.x *= Scanline;
         YIQApplication *= YIQ_to_RGB;

    FragColor = vec4(mix(Picture*Scanline,YIQApplication*mix(Scanline,1.0,0.75),YIQAmount),1.0);
    //FragColor = vec4(Picture,1.0);
    //FragColor = vec4(Scanline);
} 
#endif
