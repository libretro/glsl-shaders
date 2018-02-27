// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter RETRO_PIXEL_SIZE "Retro Pixel Size" 0.84 0.0 1.0 0.01
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float RETRO_PIXEL_SIZE;
#else
#define RETRO_PIXEL_SIZE 0.84
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
// out variables go here as COMPAT_VARYING whatever

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
    TEX0.xy = VertexCoord.xy;
// Paste vertex contents here:
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
// in variables go here as COMPAT_VARYING whatever

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// delete all 'params.' or 'registers.' or whatever in the fragment
float iGlobalTime = float(FrameCount)*0.025;
vec2 iResolution = OutputSize.xy;

// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// A set of 38 points gets interpolated by computing the DFT (Discrete Fourier Transform)
// and then its inverse, and evaluating the it at more than 38 points. This results in
// an interpolation sort of made of cosine/sine waves. Would be nice to do a regular
// Hermite spline interpolation as well to compare.
//
// More info: http://www.iquilezles.org/www/articles/fourier/fourier.htm
//
// Original drawing (kind of), here:
// https://mir-s3-cdn-cf.behance.net/project_modules/disp/831a237863325.560b2e6f92480.png

float sdSegmentSq( in vec2 p, in vec2 a, in vec2 b )
{
	vec2 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    vec2  d = pa - ba*h;
	return dot(d,d);
}

float sdPointSq( in vec2 p, in vec2 a )
{
    vec2 d = p - a;
	return dot(d,d);
}

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float e = 1.0/iResolution.x;
	vec2 p = fragCoord / iResolution.x;
    
    vec3 col = vec3(1.0);

    #define NUM 38
    
    vec2 path[NUM];
    
    //------------------------------------------------------
    // path
    //------------------------------------------------------
    {
        path[ 0] = vec2( 0.098, 0.062 );
        path[ 1] = vec2( 0.352, 0.073 );
        path[ 2] = vec2( 0.422, 0.136 );
        path[ 3] = vec2( 0.371, 0.085 );
        path[ 4] = vec2( 0.449, 0.140 );
        path[ 5] = vec2( 0.352, 0.187 );
        path[ 6] = vec2( 0.379, 0.202 );
        path[ 7] = vec2( 0.398, 0.202 );
        path[ 8] = vec2( 0.266, 0.198 );
        path[ 9] = vec2( 0.318, 0.345 );
        path[10] = vec2( 0.402, 0.359 );
        path[11] = vec2( 0.361, 0.425 );
        path[12] = vec2( 0.371, 0.521 );
        path[13] = vec2( 0.410, 0.491 );
        path[14] = vec2( 0.410, 0.357 );
        path[15] = vec2( 0.502, 0.482 );
        path[16] = vec2( 0.529, 0.435 );
        path[17] = vec2( 0.426, 0.343 );
        path[18] = vec2( 0.449, 0.343 );
        path[19] = vec2( 0.504, 0.335 );
        path[20] = vec2( 0.664, 0.355 );
        path[21] = vec2( 0.748, 0.208 );
        path[22] = vec2( 0.738, 0.277 );
        path[23] = vec2( 0.787, 0.308 );
        path[24] = vec2( 0.748, 0.183 );
        path[25] = vec2( 0.623, 0.081 );
        path[26] = vec2( 0.557, 0.099 );
        path[27] = vec2( 0.648, 0.116 );
        path[28] = vec2( 0.598, 0.116 );
        path[29] = vec2( 0.566, 0.195 );
        path[30] = vec2( 0.584, 0.228 );
        path[31] = vec2( 0.508, 0.083 );
        path[32] = vec2( 0.457, 0.140 );
        path[33] = vec2( 0.508, 0.130 );
        path[34] = vec2( 0.625, 0.071 );
        path[35] = vec2( 0.818, 0.093 );
        path[36] = vec2( 0.951, 0.066 );
        path[37] = vec2( 0.547, 0.081 );
    }

    //------------------------------------------------------
    // draw path
    //------------------------------------------------------
    {
        vec2 d = vec2(1000.0);
        for( int i=0; i<(NUM-1); i++ )
        {
            vec2 a = path[i+0];
            vec2 b = path[i+1];
            d = min( d, vec2(sdSegmentSq( p,a,b ), sdPointSq(p,a) ) );
        }
        d.x = sqrt( d.x );
        d.y = sqrt( min( d.y, sdPointSq(p,path[NUM-1]) ) );
        //col = mix( col, vec3(0.8,0.8,0.8), 1.0-smoothstep(0.0,e,d.x) );
        col = mix( col, vec3(0.9,0.2,0.0), 1.0-smoothstep(5.0*e,6.0*e,d.y) );
    }

    //------------------------------------------------------
    // compute fourier transform of the path
    //------------------------------------------------------
    vec2 fcsX[20];
    vec2 fcsY[20];
    for( int k=0; k<20; k++ )
    {
        vec2 fcx = vec2(0.0);
        vec2 fcy = vec2(0.0);
        for( int i=0; i<NUM; i++ )
        {
            float an = -6.283185*float(k)*float(i)/float(NUM);
            vec2  ex = vec2( cos(an), sin(an) );
            fcx += path[i].x*ex;
            fcy += path[i].y*ex;
        }
        fcsX[k] = fcx;
        fcsY[k] = fcy;
    }

    //------------------------------------------------------
    // inverse transform with 6x evaluation points
    //------------------------------------------------------
    {
    float ani = min( mod((12.0+iGlobalTime)/10.1,1.3), 1.0 );
    float d = 1000.0;
    vec2 oq, fq;
    for( int i=0; i<256; i++ )
    {
        float h = ani*float(i)/256.0;
        vec2 q = vec2(0.0);
        for( int k=0; k<20; k++ )
        {
            float w = (k==0||k==19)?1.0:2.0;
            float an = -6.283185*float(k)*h;
            vec2  ex = vec2( cos(an), sin(an) );
            q.x += w*dot(fcsX[k],ex)/float(NUM);
            q.y += w*dot(fcsY[k],ex)/float(NUM);
        }
        if( i==0 ) fq=q; else d = min( d, sdSegmentSq( p, q, oq ) );
        oq = q;
    }
    d = sqrt(d);
    col = mix( col, vec3(0.1,0.1,0.2), 1.0-smoothstep(0.0*e,2.0*e,d) );
    col *= 0.75 + 0.25*smoothstep( 0.0, 0.13, sqrt(d) );
    }

    //------------------------------------------------------

    col *= 1.0 - 0.3*length(fragCoord/iResolution.xy-0.5);
    
	fragColor = vec4(col,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
