// Based on Iterations - shiny Shadertoy - https://www.shadertoy.com/view/MslXz8
// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#pragma parameter aspect_x "Aspect Ratio Numerator" 64.0 1.0 256. 1.0
#pragma parameter aspect_y "Aspect Ratio Denominator" 49.0 1.0 256. 1.0
#pragma parameter SPEED "Border Animation Speed" 0.5 0.5 10 0.5
#pragma parameter integer_scale "Force Integer Scaling" 1.0 0.0 1.0 1.0
#pragma parameter overscale "Integer Overscale" 0.0 0.0 1.0 1.0
#pragma parameter scanline_toggle "Scanline Toggle" 0.0 0.0 1.0 1.0
#pragma parameter interp_toggle "Sharpen Linear Scaling" 0.0 0.0 1.0 1.0
#pragma parameter THICKNESS "Scanline Thickness" 2.0 1.0 12.0 1.0
#pragma parameter DARKNESS "Scanline Darkness" 0.35 0.0 1.0 0.05
#pragma parameter COL_SHFT "Color Shift" 0.5 0.0 5.0 0.25
#pragma parameter OS_MASK_TOP "OS Mask Top" 0.0 0.0 1.0 0.005
#pragma parameter OS_MASK_BOTTOM "OS Mask Bottom" 0.0 0.0 1.0 0.005
#pragma parameter OS_MASK_LEFT "OS Mask Left" 0.0 0.0 1.0 0.005
#pragma parameter OS_MASK_RIGHT "OS Mask Right" 0.0 0.0 1.0 0.005
#ifndef PARAMETER_UNIFORM
#define aspect_x 64.0
#define aspect_y 49.0
#define SPEED 0.5
#define integer_scale 1.0
#define overscale 0.0
#define scanline_toggle 0.0
#define THICKNESS 2.0
#define DARKNESS 0.35
#define interp_toggle 0.0
#define COL_SHFT 0.5
#define OS_MASK_TOP 0.0
#define OS_MASK_BOTTOM 0.0
#define OS_MASK_LEFT 0.0
#define OS_MASK_RIGHT 0.0
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
COMPAT_VARYING vec2 tex_border;

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
uniform COMPAT_PRECISION float aspect_x;
uniform COMPAT_PRECISION float aspect_y;
uniform COMPAT_PRECISION float SPEED;
uniform COMPAT_PRECISION float integer_scale;
uniform COMPAT_PRECISION float overscale;
uniform COMPAT_PRECISION float scanline_toggle;
uniform COMPAT_PRECISION float THICKNESS;
uniform COMPAT_PRECISION float DARKNESS;
uniform COMPAT_PRECISION float interp_toggle;
uniform COMPAT_PRECISION float COL_SHFT;
uniform COMPAT_PRECISION float OS_MASK_TOP;
uniform COMPAT_PRECISION float OS_MASK_BOTTOM;
uniform COMPAT_PRECISION float OS_MASK_LEFT;
uniform COMPAT_PRECISION float OS_MASK_RIGHT;
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
	vec2 out_res = OutputSize;
	vec2 corrected_size = InputSize * vec2(aspect_x / aspect_y, 1.0)
		 * vec2(InputSize.y / InputSize.x, 1.0);
	float full_scale = (integer_scale > 0.5) ? floor(OutputSize.y /
		InputSize.y) + overscale : OutputSize.y / InputSize.y;
	vec2 scale = (OutputSize / corrected_size) / full_scale;
	vec2 middle = vec2(0.49999, 0.49999) * InputSize / TextureSize;
	vec2 diff = TexCoord.xy - middle;
	TEX0.xy = middle + diff * scale;
	tex_border = TexCoord.xy;
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
precision mediump int;
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
COMPAT_VARYING vec2 tex_border;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float aspect_x;
uniform COMPAT_PRECISION float aspect_y;
uniform COMPAT_PRECISION float SPEED;
uniform COMPAT_PRECISION float integer_scale;
uniform COMPAT_PRECISION float overscale;
uniform COMPAT_PRECISION float scanline_toggle;
uniform COMPAT_PRECISION float THICKNESS;
uniform COMPAT_PRECISION float DARKNESS;
uniform COMPAT_PRECISION float interp_toggle;
uniform COMPAT_PRECISION float COL_SHFT;
uniform COMPAT_PRECISION float OS_MASK_TOP;
uniform COMPAT_PRECISION float OS_MASK_BOTTOM;
uniform COMPAT_PRECISION float OS_MASK_LEFT;
uniform COMPAT_PRECISION float OS_MASK_RIGHT;
#endif

vec4 shiny_iterations(vec2 texture_size, float frame_count, vec2 uv)
{
	vec2 pc = uv * 5.0;

	vec2 pa = pc + vec2(0.04,0.0);
	vec2 pb = pc + vec2(0.0,0.04);
	
    // shape (3 times for diferentials)
	vec2 zc = pc;
	vec3 fc = vec3( 0.0, 0.0, 0.0 );
	for( int i=0; i<8; i++ ) 
	{
        // transform		
		zc += cos(zc.yx + cos(zc.yx + cos(zc.yx+frame_count * 0.01 * SPEED) ) );

        // orbit traps		
		float d = dot( zc-pc, zc-pc ); 
		fc.x += 1.0/(1.0+d);
		fc.y += d;
		fc.z += sin(atan(zc.x-pc.x, zc.y-pc.y));
	}
	fc /= 8.0;
	vec3 sc = fc;
	
	vec2 za = pa;
	vec3 fa = vec3( 0.0, 0.0, 0.0 );
		for( int j=0; j<8; j++ ) 
	{
        // transform		
		za += cos(za.yx + cos(za.yx + cos(za.yx+frame_count * 0.01 * SPEED) ) );

        // orbit traps		
		float d = dot( za-pa, za-pa ); 
		fa.x += 1.0/(1.0+d);
		fa.y += d;
		fa.z += sin(atan(zc.x-pc.x, zc.y-pc.y));
	}
	fa /= 8.0;
	vec3 sa = fa;
	
	vec2 zb = pb;
	vec3 fb = vec3( 0.0, 0.0, 0.0 );
		for( int k=0; k<8; k++ ) 
	{
        // transform		
		zb += cos(zb.yx + cos(zb.yx + cos(zb.yx+frame_count * 0.01 * SPEED) ) );

        // orbit traps		
		float d = dot( zb-pb, zb-pb ); 
		fb.x += 1.0/(1.0+d);
		fb.y += d;
		fb.z += sin(atan(zc.x-pc.x, zc.y-pc.y));
	}
	fb /= 8.0;
	vec3 sb = fb;

    // color	
	vec3 col = mix( vec3(0.08,0.02,0.15), vec3(0.6,1.1,1.6), sc.x );
	col = mix( col, col.zxy, smoothstep(-0.5,0.5,cos(0.01*frame_count * COL_SHFT)) );
	col *= 0.15*sc.y;
	col += 0.4*abs(sc.z) - 0.1;

    // light	
	vec3 nor = normalize( vec3( sa.x-sc.x, 0.01, sb.x-sc.x ) );
	float dif = clamp(0.5 + 0.5*dot( nor,vec3(0.5773, 0.5773, 0.5773) ),0.0,1.0);
	col *= 1.0 + 0.7*dif*col;
	col += 0.3 * pow(nor.y,128.0);

    // vignetting	
	col *= 1.0 - 0.1*length(pc);
	return vec4(col, 1.0);
}

vec4 scanlines(vec4 frame, vec2 coord, vec2 texture_size, vec2
	video_size, vec2 output_size)
{
	float lines = fract(coord.y * texture_size.y);
	float scale_factor = floor((output_size.y / video_size.y) + 0.4999);
    float lightness = 1.0 - DARKNESS;
	return (scanline_toggle > 0.5 && (lines < (1.0 / scale_factor * THICKNESS)))
		? frame * vec4(lightness, lightness, lightness, lightness) : frame;
}

vec2 interp_coord(vec2 coord, vec2 texture_size)
{
	vec2 p = coord.xy;
	p = p * texture_size.xy + vec2(0.5, 0.5);
	vec2 i = floor(p);
	vec2 f = p - i;
	// Smoothstep - amazingly, smoothstep() is slower than calculating directly the expression!
	f = f * f * f * f * (f * (f * (-20.0 * f + vec2(70.0, 70.0)) - vec2(84.0, 84.0)) + vec2(35.0, 35.0));
	p = i + f;
	p = (p - vec2(0.5, 0.5)) * 1.0 / texture_size;
	return p;
}

vec4 border(sampler2D decal, vec2 texture_size, vec2 video_size, vec2 output_size, float frame_count, vec2 tex, vec2 tex_border)
{
	vec4 effect = shiny_iterations(texture_size, frame_count, tex_border * (texture_size / video_size)
	 * vec2(output_size.x / output_size.y, 1.0));
	
	vec2 coord = (interp_toggle < 0.5) ? tex : interp_coord(tex, texture_size);
	vec4 frame = COMPAT_TEXTURE(decal, coord);
	frame = scanlines(frame, tex, texture_size, video_size, output_size);
	vec2 fragcoord = (tex.xy * (TextureSize.xy/InputSize.xy));
	if (fragcoord.x < 1.0 && fragcoord.x > 0.0 && fragcoord.y < 1.0 && fragcoord.y > 0.0)
		return frame;
	
	else return effect;
}

void main()
{
	FragColor = border(Source, TextureSize, InputSize, OutputSize, float(FrameCount), vTexCoord, tex_border);
} 
#endif
