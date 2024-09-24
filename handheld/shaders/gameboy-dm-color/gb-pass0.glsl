///////////////////////////////////////////////////////////////////////////
//                                                                       //
// Gameboy Color Dot Matrix v0.9                                         //
//                                                                       //
// Copyright (C) 2024 LuigiRa : ra.luigi@gmail.com                       //
//                                                                       //
// This program is free software: you can redistribute it and/or modify  //
// it under the terms of the GNU General Public License as published by  //
// the Free Software Foundation, either version 3 of the License, o`r     //
// (at your option) any later version.                                   //
//                                                                       //
// This program is distributed in the hope that it will be useful,       //
// but WITHOUT ANY WARRANTY; without even the implied warranty of        //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         //
// GNU General Public License for more details.                          //
//                                                                       //
// You should have received a copy of the GNU General Public License     //
// along with this program.  If not, see <http://www.gnu.org/licenses/>. //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

#pragma parameter baseline_alpha "Baseline Alpha" 1.0 0.0 1.0 0.01
#pragma parameter console_border_enable "Console-Border Enable" 0.0 0.0 1.0 1.0
#pragma parameter video_scale "Video Scale" 3.0 2.0 9.0 1.0
#pragma parameter response_time "LCD Response Time" 0.222 0.0 0.777 0.111
#pragma parameter color_toggle "Color Toggle" 0.0 0.0 1.0 1.0
#pragma parameter negative_toggle "Negative Toggle" 0.0 0.0 1.0 1.0
#pragma parameter desaturate_toggle "Desaturate Toggle" 0.4 0.0 1.0 0.1

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
COMPAT_VARYING vec2 dot_size;
COMPAT_VARYING vec2 one_texel;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float baseline_alpha;
uniform COMPAT_PRECISION float grey_balance;
uniform COMPAT_PRECISION float response_time;
uniform COMPAT_PRECISION float video_scale;
uniform COMPAT_PRECISION float console_border_enable;
#else
#define baseline_alpha 0.10
#define response_time 0.333
#define video_scale 3.0
#endif

////////////////////////////////////////////////////////////////////////////////
// Vertex definitions                                                         //
////////////////////////////////////////////////////////////////////////////////

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)
#define half_pixel (vec2(0.5) * outsize.zw) 
//#define video_scale floor(outsize.y * SourceSize.w)

void main()
{
	float video_scale_factor = floor(outsize.y / InputSize.y);
	if (console_border_enable > 0.5) video_scale_factor = video_scale;
	vec2 scaled_video_out = (InputSize.xy * vec2(video_scale_factor));
    // Remaps position to integer scaled output
    gl_Position = MVPMatrix * VertexCoord / vec4( vec2(outsize.xy / scaled_video_out), 1.0, 1.0 );
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy + half_pixel;
    dot_size = SourceSize.zw;
    one_texel = 1.0 / (SourceSize.xy * video_scale_factor);
}

#elif defined(FRAGMENT)
////////////////////////////////////////////////////////////////////////////////
// Fragment shader                                                            //
////////////////////////////////////////////////////////////////////////////////

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
uniform sampler2D COLOR_PALETTE;
uniform sampler2D PrevTexture;
uniform sampler2D Prev1Texture;
uniform sampler2D Prev2Texture;
uniform sampler2D Prev3Texture;
uniform sampler2D Prev4Texture;
uniform sampler2D Prev5Texture;
uniform sampler2D Prev6Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 dot_size;
COMPAT_VARYING vec2 one_texel;

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float baseline_alpha;
uniform COMPAT_PRECISION float grey_balance;
uniform COMPAT_PRECISION float response_time;
uniform COMPAT_PRECISION float color_toggle;
uniform COMPAT_PRECISION float negative_toggle;
uniform COMPAT_PRECISION float desaturate_toggle;
#endif

void main()
{
    vec3 foreground_color = texture2D(COLOR_PALETTE, vec2(0.75, 0.5)).rgb;

    vec3 curr_rgb_original = texture2D(Texture, TEX0.xy).rgb;
    vec3 curr_rgb_negative = vec3(1.0) - curr_rgb_original;
    vec3 curr_rgb = mix(curr_rgb_original, curr_rgb_negative, step(0.5, negative_toggle));

    float is_on_dot = 0.0;
    if (mod(TEX0.x, dot_size.x) > one_texel.x && mod(TEX0.y, dot_size.y * 1.0001) > one_texel.y)
        is_on_dot = 1.0;

    vec3 input_rgb = curr_rgb;
    input_rgb += (texture2D(PrevTexture, TEX0.xy).rgb - input_rgb) * response_time;
    input_rgb += (texture2D(Prev1Texture, TEX0.xy).rgb - input_rgb) * pow(response_time, 2.0);
    input_rgb += (texture2D(Prev2Texture, TEX0.xy).rgb - input_rgb) * pow(response_time, 3.0);
    input_rgb += (texture2D(Prev3Texture, TEX0.xy).rgb - input_rgb) * pow(response_time, 4.0);
    input_rgb += (texture2D(Prev4Texture, TEX0.xy).rgb - input_rgb) * pow(response_time, 5.0);
    input_rgb += (texture2D(Prev5Texture, TEX0.xy).rgb - input_rgb) * pow(response_time, 6.0);
    input_rgb += (texture2D(Prev6Texture, TEX0.xy).rgb - input_rgb) * pow(response_time, 7.0);

    float rgb_to_alpha = (input_rgb.r + input_rgb.g + input_rgb.b) / 3.0 + (is_on_dot * baseline_alpha);
    
    vec3 final_color = mix(input_rgb, foreground_color, color_toggle);

    // Cálculo de luminancia
    float luminance = dot(final_color, vec3(0.299, 0.587, 0.114));
    final_color = mix(final_color, vec3(luminance), desaturate_toggle); // Mezcla con blanco y negro

    vec4 out_color = vec4(final_color, rgb_to_alpha);  

    if (dot(input_rgb, vec3(0.299, 0.587, 0.114)) > 0.85) {
        out_color.a = 1.0;
    } else {
        out_color.a *= is_on_dot;
    }

    gl_FragColor = out_color;
}
#endif
