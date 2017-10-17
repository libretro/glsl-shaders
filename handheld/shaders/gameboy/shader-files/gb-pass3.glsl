#version 120

///////////////////////////////////////////////////////////////////////////
//                                                                       //
// Gameboy Classic Shader v0.2.2                                         //
//                                                                       //
// Copyright (C) 2013 Harlequin : unknown92835@gmail.com                 //
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
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 lower_bound;
COMPAT_VARYING vec2 upper_bound;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;

    texel = SourceSize.zw;
    lower_bound = vec2(0.0);
    upper_bound = vec2(texel * (outsize.xy - 1.0));
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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 lower_bound;
COMPAT_VARYING vec2 upper_bound;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

/*
sigma = 4.0, normalized for 5 pixel offset       sigma = 4.0, normalized for 4 pixel offset
Raw Gaussian weights:                            Raw Gaussian weights:   
0.09973561222190091607086808117254 @position0    0.09973561222190091607086808117254 @position0
0.09666707205829167156101677393475 @position1    0.09666707205829167156101677393475 @position1
0.08801637626376240452162358324964 @position2    0.08801637626376240452162358324964 @position2
0.07528440407628116669052257071979 @position3    0.07528440407628116669052257071979 @position3
0.06049272702308815188099267447364 @position4    0.06049272702308815188099267447364 @position4
0.04566231462789672460813692086928 @position5            

sum [p0 + 2(p1 + p2 + p3 + p4 + p5)]:            sum [p0 + 2(p1 + p2 + p3 + p4)]:
0.83198140032054115459545312766674               0.74065677106474770537917928592818

Normalizing factor [1 / sum]:                    Normalizing factor [1 / sum]:
1.2019499469756482251051310195171                1.350153052084338115052273748029

Normalized Gaussian weights:                     Normalized Gaussian weights:
0.11987721382169761913280166382392 @position0    0.13465834124289953661305802732548 @position0
0.11618898213475484076479592086597 @position1    0.13051534237555914090930704141833 @position1
0.10579127878321792515352079488329 @position2    0.11883557904592230273554609080014 @position2
0.09048808548757942339961181362524 @position3    0.10164546793794160274995705611009 @position3
0.07270923003781316665844409497651 @position4    0.08167444001912718529866079800870 @position4
0.05488381664578583445722654373702
*/

void main()
{
// unroll the loop for GLES, which can't handle C-style array initialization
// I kept the old path when available for readability and speed(?)
#ifdef GL_ES
	float offsets1 = 0.0;
	float offsets2 = 1.0;
	float offsets3 = 2.0;
	float offsets4 = 3.0;
	float offsets5 = 4.0;

    /*
    Precalculated using the Gaussian function:
    G(x) = (1 / sqrt(2 * pi * sigma^2)) * e^(-x^2 / (2 * sigma^2))
    
    Where sigma = 4.0 and x = offset in range [0, 5]
    Normalized to 1 to prevent image darkening by multiplying each weight by:
    1 / sum(all weights)
    */	
	float weights1 = 0.13465834124289953661305802732548;   
    float weights2 = 0.13051534237555914090930704141833;
    float weights3 = 0.11883557904592230273554609080014;
    float weights4 = 0.10164546793794160274995705611009;
    float weights5 = 0.08167444001912718529866079800870;
	
	// Sample the current fragment and apply its weight
    vec4 out_color = COMPAT_TEXTURE(Source, clamp(vTexCoord, lower_bound, upper_bound)) * weights1;

    // Iterate across the offsets in both directions sampling texels
    // and adding their weighted alpha values to the total	
	out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord + vec2(0.0, offsets1 * texel.y), lower_bound, upper_bound)).a * weights1;
    out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord - vec2(0.0, offsets1 * texel.y), lower_bound, upper_bound)).a * weights1;
	out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord + vec2(0.0, offsets2 * texel.y), lower_bound, upper_bound)).a * weights2;
    out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord - vec2(0.0, offsets2 * texel.y), lower_bound, upper_bound)).a * weights2;
	out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord + vec2(0.0, offsets3 * texel.y), lower_bound, upper_bound)).a * weights3;
    out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord - vec2(0.0, offsets3 * texel.y), lower_bound, upper_bound)).a * weights3;
	out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord + vec2(0.0, offsets4 * texel.y), lower_bound, upper_bound)).a * weights4;
    out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord - vec2(0.0, offsets4 * texel.y), lower_bound, upper_bound)).a * weights4;
	out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord + vec2(0.0, offsets5 * texel.y), lower_bound, upper_bound)).a * weights5;
    out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord - vec2(0.0, offsets5 * texel.y), lower_bound, upper_bound)).a * weights5;
#else
    // Define offsets and weights - change this for both the X and Y passes if you change the sigma value or number of texels sampled
    float offsets[5] = float[](0.0, 1.0, 2.0, 3.0, 4.0);
    
    /*
    Precalculated using the Gaussian function:
    G(x) = (1 / sqrt(2 * pi * sigma^2)) * e^(-x^2 / (2 * sigma^2))
    
    Where sigma = 4.0 and x = offset in range [0, 5]
    Normalized to 1 to prevent image darkening by multiplying each weight by:
    1 / sum(all weights)
    */
    float weights[5] = float[]( 0.13465834124289953661305802732548,       
                                0.13051534237555914090930704141833,        
                                0.11883557904592230273554609080014,         
                                0.10164546793794160274995705611009,      
                                0.08167444001912718529866079800870 );

    // Sample the current fragment and apply its weight
    vec4 out_color = COMPAT_TEXTURE(Source, clamp(vTexCoord, lower_bound, upper_bound)) * weights[0];

    // Iterate across the offsets in both directions sampling texels
    // and adding their weighted alpha values to the total
    for (int i = 1; i < 5; i++)
    {
        out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord + vec2(0.0, offsets[i] * texel.y), lower_bound, upper_bound)).a * weights[i];
        out_color.a += COMPAT_TEXTURE(Source, clamp(vTexCoord - vec2(0.0, offsets[i] * texel.y), lower_bound, upper_bound)).a * weights[i];
    }
#endif
    FragColor = out_color;
} 
#endif
