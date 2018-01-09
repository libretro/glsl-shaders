///////////////////////////////////////////////////////////////////////////
//                                                                       //
// Copyright (C) 2017 - Brad Parker                                      //
//                                                                       //
// This program is free software: you can redistribute it and/or modify  //
// it under the terms of the GNU General Public License as published by  //
// the Free Software Foundation, either version 3 of the License, or     //
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

#if defined(VERTEX)
////////////////////////////////////////////////////////////////////////////////
// Vertex shader                                                              //
////////////////////////////////////////////////////////////////////////////////

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

////////////////////////////////////////////////////////////////////////////////
// Vertex definitions                                                         //
////////////////////////////////////////////////////////////////////////////////

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

// Largest integer scale of input video that will fit in the current output (y axis would typically be limiting on widescreens)
#define video_scale         floor(outsize.y * SourceSize.w)

// Size of the scaled video
//#define scaled_video_out    (SourceSize.xy * vec2(video_scale))

//it's... half a pixel
#define half_pixel          (vec2(0.5) * outsize.zw)   

void main()
{
	vec2 scaled_video_out = (InputSize.xy * vec2(video_scale));
    // Remaps position to integer scaled output
    gl_Position = MVPMatrix * VertexCoord;// / vec4( vec2(outsize.xy / scaled_video_out), 1.0, 1.0 );
    TEX0.xy = TexCoord.xy;// + vec2(0.0, half_pixel);
    dot_size = SourceSize.zw;
    one_texel = 1.0 / (SourceSize.xy * video_scale);
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
uniform sampler2D MASK;

COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 dot_size;
COMPAT_VARYING vec2 one_texel;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#define maskSize vec2(2., floor(outsize.y / InputSize.y + 0.000001))

////////////////////////////////////////////////////////////////////////////////
//fragment definitions                                                        //
////////////////////////////////////////////////////////////////////////////////

#define curr_rgb  COMPAT_TEXTURE(Source, vTexCoord)
#define mask_rgb  COMPAT_TEXTURE(MASK, fract(gl_FragCoord.xy / maskSize))

void main()
{
    FragColor = mask_rgb * curr_rgb;
} 
#endif
