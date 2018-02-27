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

// ============================================================================================
// Base-10 digit extraction of Pi using a lovely formula I discovered which
// has a nice base-10 feel to it!
//
// pi/4 = 7/10 + 22/200 - 52/3000 - 312/40000 + 2/5000000 + 2852/6000000 + ...
//
// The nth term is given by ImaginaryPart[3(3i+1)^n - (2i-1)^n] / n10^n

// The code represents each part of the imaginary number in the spiral terms
// using a BIGNUM encoded in a vec4 - i.e. each float uses numbers less than
// 2^24. This works in C++ with IEEE! But it depends on the vagaries of your
// GPU and WebGL translation if you see the correct digits of pi. Sorry!

// Thanks to Fabrice for spotting that the 56th digit was wrong. Fixed now!

// Derivation of the formula:
//
// Using the logarithmic form of ArcTan(x), find the Taylor series of ArcTan(x) about 1/a
//
// ArcTan(x) = ArcTan(1/a) + SumOverN of [Q(n) * a^n * (x-1/a)^n / n(1+a^2)]
//
// The 1+a^2 on the bottom is interesting! It suggests values of a of 2, 3 or 7.
//
// Q(n) = i * ((-ia - 1)^n - (ia-1)^n)/2
//
// Which, for our purposes, we can simplify to just ImaginaryPart[ (ia - 1)^n ]
//
// This gives us the final formula.
//
// ArcTan(x) - ArcTan(1/a) = 1/n(1+a^2) * (x-1/a)^n * a^n * ImaginaryPart[ (ia - 1)^n ]
//
// For judicious choices of x and a we can get useful formulae. For instance:
//
// ArcTan(3/4) - ArcTan(1/2) = SumOverN of 1/n10^n * ImaginaryPart[( 2i-1)^n]
// ArcTan(2/3) - ArcTan(1/3) = SumOverN of 1/n10^n * ImaginaryPart[( 3i-1)^n]
// ArcTan(0/3) - ArcTan(1/3) = SumOverN of 1/n10^n * ImaginaryPart[(-3i+1)^n]
//
// Using the well known ArcTan addition formula
//
// ArcTan(3/4) - ArcTan(1/2) =  ArcTan(2/11)
// ArcTan(2/3) - ArcTan(1/3) =  ArcTan(3/11)
// ArcTan(0/3) - ArcTan(1/3) = -ArcTan(1/3)	... this is easy :)
//
// Then all we need to get pi is the Machin type formula, pi/4 = 3 ArcTan[1/3] - ArcTan[2/11]
//
// QED
//
// https://www.wolframalpha.com/input/?i=Sum+for+n+%3D+1+to+100+of+4+Im%5B3(3i%2B1)%5En-(2i-1)%5En%5D%2F(n+10%5En)
//

// Feeling brave? Try using ivecs for an extra 20 digits. Only works if you
// have full 32-precision ints... and your WebGL implementation may crash!
#define USE_INTEGERS 1

#if USE_INTEGERS

const int POW10_PER_COMPONENT	= 7;
const int BASE_FOR_NUMBER		= 10000000;
const int MAX_DIGIT				= 60;
const int MAX_1OVER3_TERMS		= 122;
const int MAX_2OVER11_TERMS		= 93;

bool IsZero(ivec4 lo)
{
	return lo.x == 0 && lo.y == 0 && lo.z == 0 && lo.w == 0;
}

// Returns +1(a>b), 0, -1(a<b)
int CompareAbsValues(ivec4 a, ivec4 b)
{
	if (a.w > b.w) {return +1;}
	if (a.w < b.w) {return -1;}
		
	if (a.z > b.z) {return +1;}
	if (a.z < b.z) {return -1;}

	if (a.y > b.y) {return +1;}
	if (a.y < b.y) {return -1;}

	if (a.x > b.x) {return +1;}
	if (a.x < b.x) {return -1;}

	return 0;
}

void DivMod(int a, int b, out int out_div, out int out_mod)
{
	if (a == 0)
	{
		out_div = 0;
		out_mod = 0;

		return;
	}

	out_div = a / b;
	out_mod = a - out_div * b;
}

int Mod(int a, int b)
{
	int div = a / b;
	int mod = a - b * div;

	return mod;
}

ivec4 Div(ivec4 a, int divisor, out int out_mod)
{
	ivec4 ans = a;

	if (ans.w != 0)
	{
		int div_w;
		int mod_w;

		DivMod(ans.w, divisor, div_w, mod_w);

		ans.w  = div_w;
		ans.z += mod_w * BASE_FOR_NUMBER;
	}

	if (ans.z != 0)
	{
		int div_z;
		int mod_z;

		DivMod(ans.z, divisor, div_z, mod_z);

		ans.z  = div_z;
		ans.y += mod_z * BASE_FOR_NUMBER;
	}

	if (ans.y != 0)
	{
		int div_y;
		int mod_y;

		DivMod(ans.y, divisor, div_y, mod_y);

		ans.y  = div_y;
		ans.x += mod_y * BASE_FOR_NUMBER;
	}

	if (ans.x != 0)
	{
		int div_x;
		int mod_x;

		DivMod(ans.x, divisor, div_x, mod_x);

		ans.x = div_x;

		out_mod =  mod_x;
	}
	else
	{
		out_mod = 0;
	}

	return ans;
}

ivec4 Double(ivec4 a)
{
	ivec4 ans = a + a;

	if (ans.x >= BASE_FOR_NUMBER)
	{
		ans.x -= BASE_FOR_NUMBER;
		ans.y += 1;
	}

	if (ans.y >= BASE_FOR_NUMBER)
	{
		ans.y -= BASE_FOR_NUMBER;
		ans.z += 1;
	}

	if (ans.z >= BASE_FOR_NUMBER)
	{
		ans.z -= BASE_FOR_NUMBER;
		ans.w += 1;
	}

	return ans;
}

ivec4 Treble(ivec4 a)
{
	ivec4 ans = a + a + a;

	if (ans.x >= BASE_FOR_NUMBER)
	{
		ans.x -= BASE_FOR_NUMBER;
		ans.y += 1;

		if (ans.x >= BASE_FOR_NUMBER)
		{
			ans.x -= BASE_FOR_NUMBER;
			ans.y += 1;
		}
	}

	if (ans.y >= BASE_FOR_NUMBER)
	{
		ans.y -= BASE_FOR_NUMBER;
		ans.z += 1;

		if (ans.y >= BASE_FOR_NUMBER)
		{
			ans.y -= BASE_FOR_NUMBER;
			ans.z += 1;
		}
	}

	if (ans.z >= BASE_FOR_NUMBER)
	{
		ans.z -= BASE_FOR_NUMBER;
		ans.w += 1;

		if (ans.z >= BASE_FOR_NUMBER)
		{
			ans.z -= BASE_FOR_NUMBER;
			ans.w += 1;
		}
	}

	return ans;
}

ivec4 Add(ivec4 a, ivec4 b)
{
	ivec4 ans = a + b;

	if (ans.x >= BASE_FOR_NUMBER)
	{
		ans.x -= BASE_FOR_NUMBER;
		ans.y += 1;
	}

	if (ans.y >= BASE_FOR_NUMBER)
	{
		ans.y -= BASE_FOR_NUMBER;
		ans.z += 1;
	}

	if (ans.z >= BASE_FOR_NUMBER)
	{
		ans.z -= BASE_FOR_NUMBER;
		ans.w += 1;
	}

	return ans;
}

// a must be > b
ivec4 Sub(ivec4 a, ivec4 b)
{
	ivec4 ans = a - b;

	if (ans.x < 0)
	{
		ans.x += BASE_FOR_NUMBER;
		ans.y -= 1;
	}

	if (ans.y < 0)
	{
		ans.y += BASE_FOR_NUMBER;
		ans.z -= 1;
	}

	if (ans.z < 0)
	{
		ans.z += BASE_FOR_NUMBER;
		ans.w -= 1;
	}

	return ans;
}

ivec4 Add(ivec4 a, bool aneg, ivec4 b, bool bneg, out bool out_a_plus_b_neg)
{
	if (aneg == bneg)
	{
		out_a_plus_b_neg = aneg;

		return Add(a,b);
	}

	// Signs are different.
	int sign = CompareAbsValues(a,b);

	if (sign == 0)
	{
		out_a_plus_b_neg = false;

		return ivec4(0,0,0,0);
	}

	if (sign < 0)
	{
		out_a_plus_b_neg = bneg;
			
		return Sub(b,a);
	}

	out_a_plus_b_neg = aneg;

	return Sub(a,b);
}

// Divides by BASE_FOR_NUMBER.
void ApplyShift(out ivec4 a)
{
	a.x = a.y;
	a.y = a.z;
	a.z = a.w;
	a.w = 0;
}
	
// Return Frac(10^power * Abs(num)/denom)
float GetFractionalPart(ivec4 numerator, int denominator, int power_of_ten)
{
	if (power_of_ten >= 0)
	{
		int m;
		Div(numerator, denominator, m);

		const int MAX_ITERS = MAX_DIGIT / POW10_PER_COMPONENT;

		for (int iter = 0; iter < MAX_ITERS; iter++)
		{
			if (power_of_ten < POW10_PER_COMPONENT)
			{
				break;
			}

			m *= BASE_FOR_NUMBER;
			m  = Mod(m, denominator);

			power_of_ten -= POW10_PER_COMPONENT;

			if (m == 0)
			{
				return 0.0;
			}
		}

		if (power_of_ten >= 4) {m = Mod(10000 * m, denominator); power_of_ten -= 4;}
		if (power_of_ten >= 2) {m = Mod(100   * m, denominator); power_of_ten -= 2;}
		if (power_of_ten >= 1) {m = Mod(10    * m, denominator); power_of_ten -= 1;}
			
		return float(m) / float(denominator);
	}

	const int NUM_POWERS_OF_10_TO_KEEP = 4;

	// Throw away terms we don't need.
	const int MAX_ITERS = MAX_DIGIT / POW10_PER_COMPONENT;

	for (int iter = 0; iter < MAX_ITERS; iter++)
	{
		if (power_of_ten + POW10_PER_COMPONENT > -NUM_POWERS_OF_10_TO_KEEP)
		{
			break;
		}

		ApplyShift(numerator);

		if (IsZero(numerator))
		{
			return 0.0;
		}

		power_of_ten += POW10_PER_COMPONENT;
	}

	// Divide by the denominator to get the fractional part in the wrong place...
	int the_mod;

	numerator = Div(numerator, denominator, the_mod);
		
	float ans = float(the_mod) / float(denominator);

	// We can't divide by more than 100 at a time.
	const int MAX_DIV100_ITERS = (NUM_POWERS_OF_10_TO_KEEP + POW10_PER_COMPONENT) / 2;

	for (int iter = 0; iter < MAX_DIV100_ITERS; iter++)
	{
		if (power_of_ten > -2)
		{
			break;
		}

		numerator = Div(numerator, 100, the_mod);

		ans += float(the_mod);
		ans *= 0.01;

		power_of_ten += 2;
	}

	// And one more if required.
	if (power_of_ten == -1)
	{
		numerator = Div(numerator, 100, the_mod);

		ans += float(the_mod);
		ans *= 0.1;
	}

	return ans - floor(ans);
}

// Im((2i - 1)^n) / (10^n n)
float GetNthDigitOfSpiral2(int nth_digit)
{
	int		num_terms	= 8 + (MAX_2OVER11_TERMS-8) * nth_digit / (MAX_DIGIT-1);
	int		shift		= 0;
	float	sum			= 0.0;

	ivec4 re = ivec4(1,0,0,0); bool re_neg = true;
	ivec4 im = ivec4(2,0,0,0); bool im_neg = false;

	for (int term = 1; term < MAX_2OVER11_TERMS; term++)
	{
		int shifted_digit = nth_digit - term + shift;

		float f = GetFractionalPart(im, term, shifted_digit);
        
		if (im_neg)
		{
			sum -= f;
		}
		else
		{
			sum += f;
		}

		if (im.w*3 < 0 ||
			re.w*3 < 0)
		{
			int mod;

			im = Div(im,10,mod);
			re = Div(re,10,mod);

			shift += 1;
		}

		bool new_re_neg;
		bool new_im_neg;

		ivec4 new_re = Add(Double(im), !im_neg, re, !re_neg, new_re_neg);
		ivec4 new_im = Add(Double(re),  re_neg, im, !im_neg, new_im_neg);

		re = new_re; re_neg = new_re_neg;
		im = new_im; im_neg = new_im_neg;

		if (term == num_terms)
		{
			break;
		}
	}

	sum = sum - floor(sum);

	return sum;
}

// Im((3i + 1)^n) / (10^n n)
float GetNthDigitOfSpiral3(int nth_digit)
{
	int		num_terms	= 8 + (MAX_1OVER3_TERMS-8) * nth_digit / (MAX_DIGIT-1);
	int		shift		= 0;
	float	sum			= 0.0;

	ivec4 re = ivec4(1,0,0,0); bool re_neg = false;
	ivec4 im = ivec4(3,0,0,0); bool im_neg = false;

	for (int term = 1; term < MAX_1OVER3_TERMS; term++)
	{
		int shifted_digit = nth_digit - term + shift;

		float f = GetFractionalPart(im, term, shifted_digit);

		if (im_neg)
		{
			sum -= f;
		}
		else
		{
			sum += f;
		}

		if (im.w*3 < 0 ||
			re.w*3 < 0)
		{
			int mod;

			im = Div(im,10,mod);
			re = Div(re,10,mod);

			shift += 1;
		}

		bool new_re_neg;
		bool new_im_neg;

		ivec4 new_re = Add(Treble(im), !im_neg, re, re_neg, new_re_neg);
		ivec4 new_im = Add(Treble(re),  re_neg, im, im_neg, new_im_neg);

		re = new_re; re_neg = new_re_neg;
		im = new_im; im_neg = new_im_neg;

		if (term == num_terms)
		{
			break;
		}
	}

	sum = sum - floor(sum);

	return sum;
}

int GetNthDigitOfPi(int nth_digit)
{
	float a = GetNthDigitOfSpiral3(nth_digit);
	float b = GetNthDigitOfSpiral2(nth_digit);

	float s = 4.0 * (a*3.0-b);

	s -= floor(s);

	int digit = int(floor(10.0 * s));

	return digit;
}

#else

const float	POW10_PER_COMPONENT	= 5.0;
const float	BASE_FOR_NUMBER		= 100000.0;
const float	MAX_DIGIT			= 40.0;
const float	MAX_1OVER3_TERMS	= 80.0;
const float	MAX_2OVER11_TERMS	= 60.0;

bool IsZero(vec4 a)
{
	return a.x == 0.0 && a.y == 0.0 && a.z == 0.0 && a.w == 0.0;
}

// Returns +1(a>b), 0, -1(a<b)
float CompareAbsValues(vec4 a, vec4 b)
{
	if (a.w > b.w) {return +1.0;}
	if (a.w < b.w) {return -1.0;}
		
	if (a.z > b.z) {return +1.0;}
	if (a.z < b.z) {return -1.0;}

	if (a.y > b.y) {return +1.0;}
	if (a.y < b.y) {return -1.0;}

	if (a.x > b.x) {return +1.0;}
	if (a.x < b.x) {return -1.0;}

	return 0.0;
}

void DivMod(float a, float b, out float out_div, out float out_mod)
{
	if (a == 0.0)
	{
		out_div = 0.0;
		out_mod = 0.0;

		return;
	}
	
	float d = floor(a / b);

	out_div = d;
	out_mod = a - d * b;
}

float Mod(float a, float b)
{
	float d		= floor(a / b);
	float mod	= a - d * b;

	return mod;
}

vec4 Div(vec4 a, float divisor, out float out_mod)
{
	vec4 ans = a;

	if (ans.w != 0.0)
	{
		float div_w;
		float mod_w;

		DivMod(ans.w, divisor, div_w, mod_w);

		ans.w  = div_w;
		ans.z += mod_w * BASE_FOR_NUMBER;
	}

	if (ans.z != 0.0)
	{
		float div_z;
		float mod_z;

		DivMod(ans.z, divisor, div_z, mod_z);

		ans.z  = div_z;
		ans.y += mod_z * BASE_FOR_NUMBER;
	}

	if (ans.y != 0.0)
	{
		float div_y;
		float mod_y;

		DivMod(ans.y, divisor, div_y, mod_y);

		ans.y  = div_y;
		ans.x += mod_y * BASE_FOR_NUMBER;
	}

	if (ans.x != 0.0)
	{
		float div_x;
		float mod_x;

		DivMod(ans.x, divisor, div_x, mod_x);

		ans.x = div_x;

		out_mod =  mod_x;
	}
	else
	{
		out_mod = 0.0;
	}

	return ans;
}

vec4 Double(vec4 a)
{
	vec4 ans = a + a;

	if (ans.x >= BASE_FOR_NUMBER)
	{
		ans.x -= BASE_FOR_NUMBER;
		ans.y += 1.0;
	}

	if (ans.y >= BASE_FOR_NUMBER)
	{
		ans.y -= BASE_FOR_NUMBER;
		ans.z += 1.0;
	}

	if (ans.z >= BASE_FOR_NUMBER)
	{
		ans.z -= BASE_FOR_NUMBER;
		ans.w += 1.0;
	}

	return ans;
}

vec4 Treble(vec4 a)
{
	vec4 ans = a + a + a;

	if (ans.x >= BASE_FOR_NUMBER)
	{
		ans.x -= BASE_FOR_NUMBER;
		ans.y += 1.0;

		if (ans.x >= BASE_FOR_NUMBER)
		{
			ans.x -= BASE_FOR_NUMBER;
			ans.y += 1.0;
		}
	}

	if (ans.y >= BASE_FOR_NUMBER)
	{
		ans.y -= BASE_FOR_NUMBER;
		ans.z += 1.0;

		if (ans.y >= BASE_FOR_NUMBER)
		{
			ans.y -= BASE_FOR_NUMBER;
			ans.z += 1.0;
		}
	}

	if (ans.z >= BASE_FOR_NUMBER)
	{
		ans.z -= BASE_FOR_NUMBER;
		ans.w += 1.0;

		if (ans.z >= BASE_FOR_NUMBER)
		{
			ans.z -= BASE_FOR_NUMBER;
			ans.w += 1.0;
		}
	}

	return ans;
}

vec4 Add(vec4 a, vec4 b)
{
	vec4 ans = a + b;

	if (ans.x >= BASE_FOR_NUMBER)
	{
		ans.x -= BASE_FOR_NUMBER;
		ans.y += 1.0;
	}

	if (ans.y >= BASE_FOR_NUMBER)
	{
		ans.y -= BASE_FOR_NUMBER;
		ans.z += 1.0;
	}

	if (ans.z >= BASE_FOR_NUMBER)
	{
		ans.z -= BASE_FOR_NUMBER;
		ans.w += 1.0;
	}

	return ans;
}

// a must be > b
vec4 Sub(vec4 a, vec4 b)
{
	vec4 ans = a - b;

	if (ans.x < 0.0)
	{
		ans.x += BASE_FOR_NUMBER;
		ans.y -= 1.0;
	}

	if (ans.y < 0.0)
	{
		ans.y += BASE_FOR_NUMBER;
		ans.z -= 1.0;
	}

	if (ans.z < 0.0)
	{
		ans.z += BASE_FOR_NUMBER;
		ans.w -= 1.0;
	}

	return ans;
}

vec4 Add(vec4 a, bool aneg, vec4 b, bool bneg, out bool out_a_plus_b_neg)
{
	if (aneg == bneg)
	{
		out_a_plus_b_neg = aneg;

		return Add(a,b);
	}

	// Signs are different.
	float sign = CompareAbsValues(a,b);

	if (sign == 0.0)
	{
		out_a_plus_b_neg = false;

		return vec4(0.0,0.0,0.0,0.0);
	}

	if (sign < 0.0)
	{
		out_a_plus_b_neg = bneg;
			
		return Sub(b,a);
	}

	out_a_plus_b_neg = aneg;

	return Sub(a,b);
}

// Divides by BASE_FOR_NUMBER.
void ApplyShift(out vec4 a)
{
	a.x = a.y;
	a.y = a.z;
	a.z = a.w;
	a.w = 0.0;
}
	
// Return Frac(10^power * Abs(num)/denom)
float GetFractionalPart(vec4 numerator, float denominator, float power_of_ten)
{
	if (power_of_ten >= 0.0)
	{
		float m;
		Div(numerator, denominator, m);

		const int MAX_ITERS = int(MAX_DIGIT / POW10_PER_COMPONENT);

		for (int iter = 0; iter < MAX_ITERS; iter++)
		{
			if (power_of_ten < POW10_PER_COMPONENT)
			{
				break;
			}

			m *= BASE_FOR_NUMBER;
			m  = Mod(m, denominator);

			power_of_ten -= POW10_PER_COMPONENT;

			if (m == 0.0)
			{
				return 0.0;
			}
		}

		if (power_of_ten >= 4.0) {m = Mod(10000.0 * m, denominator); power_of_ten -= 4.0;}
		if (power_of_ten >= 2.0) {m = Mod(100.0   * m, denominator); power_of_ten -= 2.0;}
		if (power_of_ten >= 1.0) {m = Mod(10.0    * m, denominator); power_of_ten -= 1.0;}
			
		return float(m) / float(denominator);
	}

	const float NUM_POWERS_OF_10_TO_KEEP = 4.0;

	// Throw away terms we don't need.
	const int MAX_ITERS = int(MAX_DIGIT / POW10_PER_COMPONENT);

	for (int iter = 0; iter < MAX_ITERS; iter++)
	{
		if (power_of_ten + POW10_PER_COMPONENT > -NUM_POWERS_OF_10_TO_KEEP)
		{
			break;
		}

		ApplyShift(numerator);

		if (IsZero(numerator))
		{
			return 0.0;
		}

		power_of_ten += POW10_PER_COMPONENT;
	}

	// Divide by the denominator to get the fractional part in the wrong place...
	float the_mod;

	numerator = Div(numerator, denominator, the_mod);
		
	float ans = float(the_mod) / float(denominator);

	// We can't divide by more than 100 at a time.
	const int MAX_DIV100_ITERS = int(NUM_POWERS_OF_10_TO_KEEP + POW10_PER_COMPONENT) / 2;

	for (int iter = 0; iter < MAX_DIV100_ITERS; iter++)
	{
		if (power_of_ten > -2.0)
		{
			break;
		}

		numerator = Div(numerator, 100.0, the_mod);

		ans += float(the_mod);
		ans *= 0.01;

		power_of_ten += 2.0;
	}

	// And one more if required.
	if (power_of_ten == -1.0)
	{
		numerator = Div(numerator, 10.0, the_mod);

		ans += float(the_mod);
		ans *= 0.1;
	}

	return ans - floor(ans);
}

// Im((2i - 1)^n) / (10^n n)
float GetNthDigitOfSpiral2(float nth_digit)
{
    int		num_terms	= int(8.0 + (MAX_2OVER11_TERMS - 8.0) * nth_digit / (MAX_DIGIT-1.0));
	float	shift		= 0.0;
	float	sum			= 0.0;

	vec4 re = vec4(1.0, 0.0, 0.0, 0.0); bool re_neg = true;
	vec4 im = vec4(2.0, 0.0, 0.0, 0.0); bool im_neg = false;

	for (int term = 1; term < int(MAX_2OVER11_TERMS); term++)
	{
		float shifted_digit = nth_digit - float(term) + shift;

		float f = GetFractionalPart(im, float(term), shifted_digit);
        
		if (im_neg)
		{
			sum -= f;
		}
		else
		{
			sum += f;
		}

		if (im.w * 2.0 > BASE_FOR_NUMBER ||
			re.w * 2.0 > BASE_FOR_NUMBER)
		{
			float mod;

			im = Div(im,10.0,mod);
			re = Div(re,10.0,mod);

			shift += 1.0;
		}

		bool new_re_neg;
		bool new_im_neg;

		vec4 new_re = Add(Double(im), !im_neg, re, !re_neg, new_re_neg);
		vec4 new_im = Add(Double(re),  re_neg, im, !im_neg, new_im_neg);

		re = new_re; re_neg = new_re_neg;
		im = new_im; im_neg = new_im_neg;

		if (term == num_terms)
		{
			break;
		}
	}

	sum = sum - floor(sum);

	return sum;
}

// Im((3i + 1)^n) / (10^n n)
float GetNthDigitOfSpiral3(float nth_digit)
{
	int		num_terms	= int(8.0 + (MAX_1OVER3_TERMS - 8.0) * nth_digit / (MAX_DIGIT-1.0));
	float	shift		= 0.0;
	float	sum			= 0.0;

	vec4 re = vec4(1.0, 0.0, 0.0, 0.0); bool re_neg = false;
	vec4 im = vec4(3.0, 0.0, 0.0, 0.0); bool im_neg = false;

	for (int term = 1; term < int(MAX_1OVER3_TERMS); term++)
	{
		float shifted_digit = nth_digit - float(term) + shift;

		float f = GetFractionalPart(im, float(term), shifted_digit);

		if (im_neg)
		{
			sum -= f;
		}
		else
		{
			sum += f;
		}

		if (im.w * 3.0 > BASE_FOR_NUMBER ||
			re.w * 3.0 > BASE_FOR_NUMBER)
		{
			float mod;

			im = Div(im,10.0,mod);
			re = Div(re,10.0,mod);

			shift += 1.0;
		}

		bool new_re_neg;
		bool new_im_neg;

		vec4 new_re = Add(Treble(im), !im_neg, re, re_neg, new_re_neg);
		vec4 new_im = Add(Treble(re),  re_neg, im, im_neg, new_im_neg);

		re = new_re; re_neg = new_re_neg;
		im = new_im; im_neg = new_im_neg;

		if (term == num_terms)
		{
			break;
		}
	}

	sum = sum - floor(sum);

	return sum;
}

int GetNthDigitOfPi(float nth_digit)
{
	float a = GetNthDigitOfSpiral3(nth_digit);
	float b = GetNthDigitOfSpiral2(nth_digit);

	float s = 4.0 * (a*3.0-b);

	s -= floor(s);

	int digit = int(floor(10.0 * s));

	return digit;
}


#endif




// ============================================================================================

bool Is0To1(float x)
{
	return x >= 0.0 && x < 1.0;
}

bool Is0To1(vec2 uv)
{
	return
		uv.x >= 0.0 && uv.x < 1.0 &&
		uv.y >= 0.0 && uv.y < 1.0;
}

// ============================================================================================

float GetPositionAlongLineSegmentNearestToPoint(vec2 line_segment_a, vec2 line_segment_b, vec2 point)
{
	vec2 p = point			- line_segment_a;
	vec2 l = line_segment_b	- line_segment_a;

	float dprod = dot(p,l);
	float len2  = dot(l,l);

	return clamp(dprod / len2, 0.0, 1.0);
}

float GetPositionAlongLineNearestToPoint(vec2 line_segment_a, vec2 line_segment_b, vec2 point)
{
	vec2 p = point			- line_segment_a;
	vec2 l = line_segment_b	- line_segment_a;

	float dprod = dot(p,l);
	float len2  = dot(l,l);

	return dprod / len2;
}

float GetDistSqFromLineSegmentToPoint(vec2 line_segment_a, vec2 line_segment_b, vec2 point)
{
	float t = GetPositionAlongLineSegmentNearestToPoint(line_segment_a, line_segment_b, point);

	vec2 to_nearest = point - mix(line_segment_a, line_segment_b, t);

	return dot(to_nearest, to_nearest);
}

vec3 GetPointOnCubicSpline(vec3 cp0, vec3 cp1, vec3 cp2, vec3 cp3, float t)
{
	float p = t;
	float n = 1.0 - t;
        
	vec3 ans;
       
	ans  = cp0 * (n*n*n);
	ans += cp1 * (n*n*p*3.0);
	ans += cp2 * (n*p*p*3.0);
	ans += cp3 * (p*p*p);
    
    return ans;
}

vec2 GetPointOnCubicSpline(vec2 cp0, vec2 cp1, vec2 cp2, vec2 cp3, float t)
{
	float p = t;
	float n = 1.0 - t;
        
	vec2 ans;
       
	ans  = cp0 * (n*n*n);
	ans += cp1 * (n*n*p*3.0);
	ans += cp2 * (n*p*p*3.0);
	ans += cp3 * (p*p*p);
    
    return ans;
}

float GetNearestPointAlongCubicSpline(vec2 cp0, vec2 cp1, vec2 cp2, vec2 cp3, vec2 uv)
{
	float t = GetPositionAlongLineSegmentNearestToPoint(cp0,cp3, uv);

	// Now refine once.
	{
		float t0 = max(0.0, t - 0.1);
		float t1 = min(1.0, t + 0.1);

		vec2 p0 = GetPointOnCubicSpline(cp0,cp1,cp2,cp3, t0);
		vec2 p1 = GetPointOnCubicSpline(cp0,cp1,cp2,cp3, t1);

		t = clamp(mix(t0,t1,GetPositionAlongLineNearestToPoint(p0,p1, uv)), 0.0, 1.0);
	}

	return t;
}

// ============================================================================================

float GetColourForLineSegment(vec3 cp0, vec3 cp1, vec2 uv, float pixel_uv_size)
{
	float t = GetPositionAlongLineSegmentNearestToPoint(cp0.xy,cp1.xy, uv);

	vec2	best_point		= mix(cp0.xy,cp1.xy,t);
	float	best_thickness	= mix(cp0.z, cp1.z, t*t);	// Non-linear for thickness...
    float	best_dist 		= length(uv - best_point.xy);
    float	best_surface	= best_thickness - best_dist;
    
    float aa = smoothstep(0.0, pixel_uv_size, best_surface);
    
    return aa;
}

float GetColourForCubicSpline(vec3 cp0, vec3 cp1, vec3 cp2, vec3 cp3, vec2 uv, float pixel_uv_size)
{
	float	t				= GetNearestPointAlongCubicSpline(cp0.xy,cp1.xy,cp2.xy,cp3.xy, uv);
    vec3	best_point		= GetPointOnCubicSpline(cp0,cp1,cp2,cp3, t);
    float	best_dist 		= length(uv - best_point.xy);
    float	best_surface	= best_point.z - best_dist;
    
    float aa = smoothstep(0.0, pixel_uv_size, best_surface);
    
    return aa;
}

float GetColourForEllispse(vec2 origin, vec2 scale, float thickness, vec2 uv, float pixel_uv_size)
{
    vec2 r = (uv - origin) / scale;
    vec2 n = normalize(r) * scale + origin;
    
    // Stylish!
    thickness *= 1.0+r.x*r.y*0.5;
    
    float d = distance(n, uv);
    float s = thickness - d;

    float aa = smoothstep(0.0, pixel_uv_size, s);
    
    return aa;
}

// ============================================================================================
// THE FONT

// Control over the aspect ratio.
#define CHAR_ASPECT 0.75
#define CHAR_HEIGHT 0.95
#define AR(x) (((x)-0.5)*CHAR_ASPECT+0.5)
#define H(y) ((y)*CHAR_HEIGHT)

bool IsDigitUV(vec2 uv)
{
	return uv.x > AR(0.0) && uv.x < AR(1.0) && uv.y > 0.01 * CHAR_HEIGHT && uv.y < 0.99 * CHAR_HEIGHT;
}

float Char0(vec2 uv, float pixel_uv_size)
{
    return GetColourForEllispse(vec2(0.5,0.5*CHAR_HEIGHT),vec2(0.35 * CHAR_ASPECT,0.35),0.09,uv,pixel_uv_size);
}

float Char1(vec2 uv, float pixel_uv_size)
{
	float s0 = GetColourForLineSegment(vec3(0.52,0.9*CHAR_HEIGHT,0.09),vec3(0.50,0.15*CHAR_HEIGHT,0.13), uv, pixel_uv_size);
    float s1 = GetColourForLineSegment(vec3(0.52,0.9*CHAR_HEIGHT,0.09),vec3(0.30,0.75*CHAR_HEIGHT,0.06), uv, pixel_uv_size);
    
    return max(s0,s1);   
}

float Char2(vec2 uv, float pixel_uv_size)
{
    float s0 = GetColourForCubicSpline(vec3(AR(0.4),H(0.80),0.16), vec3(AR(0.8),H(0.6),0.06), vec3(AR(0.6),H(0.4),0.03), vec3(AR(0.2),H(0.15),0.13), uv, pixel_uv_size);
    float s1 = GetColourForCubicSpline(vec3(AR(0.2),H(0.15),0.13), vec3(AR(0.4),H(0.3),0.08), vec3(AR(0.6),H(0.2),0.08), vec3(AR(0.8),H(0.20),0.16), uv, pixel_uv_size);
    
    return max(s0,s1);
}

float Char3(vec2 uv, float pixel_uv_size)
{
	float s0 = GetColourForCubicSpline(vec3(AR(0.5),H(0.6),0.09), vec3(AR(0.7),H(0.7),0.08), vec3(AR(0.6),H(0.9),0.07), vec3(AR(0.4),H(0.87),0.11), uv, pixel_uv_size);
    float s1 = GetColourForCubicSpline(vec3(AR(0.5),H(0.6),0.09), vec3(AR(1.0),H(0.4),0.05), vec3(AR(0.5),H(0.1),0.06), vec3(AR(0.2),H(0.20),0.16), uv, pixel_uv_size);
    
    return max(s0,s1);
}

float Char4(vec2 uv, float pixel_uv_size)
{
	float s0 = GetColourForCubicSpline(vec3(AR(0.15),H(0.4),0.11), vec3(AR(0.3),H(0.5),0.06), vec3(AR(0.3),H(0.7),0.06), vec3(AR(0.2),H(0.80),0.11), uv, pixel_uv_size);
    float s1 = GetColourForCubicSpline(vec3(AR(0.18),H(0.4),0.10), vec3(AR(0.4),H(0.5),0.06), vec3(AR(0.6),H(0.3),0.06), vec3(AR(0.8),H(0.40),0.13), uv, pixel_uv_size);
    float s2 = GetColourForCubicSpline(vec3(AR(0.60),H(0.6),0.09), vec3(AR(0.5),H(0.4),0.06), vec3(AR(0.6),H(0.3),0.06), vec3(AR(0.5),H(0.15),0.09), uv, pixel_uv_size);
    
    return max(s0,max(s1,s2));
}

float Char5(vec2 uv, float pixel_uv_size)
{
    float s0 = GetColourForCubicSpline(vec3(AR(0.3),H(0.80),0.10), vec3(AR(0.5),H(0.70),0.07), vec3(AR(0.6),H(0.80),0.07), vec3(AR(0.8),H(0.80),0.11), uv, pixel_uv_size);
    float s2 = GetColourForCubicSpline(vec3(AR(0.3),H(0.55),0.09), vec3(AR(0.8),H(0.55),0.03), vec3(AR(0.9),H(0.25),0.09), vec3(AR(0.5),H(0.15),0.11), uv, pixel_uv_size);
    
    float s1 = GetColourForLineSegment(vec3(AR(0.3),H(0.55),0.09), vec3(AR(0.3),H(0.8),0.10), uv, pixel_uv_size);
    
	return max(s0,max(s1,s2));
}

float Char6(vec2 uv, float pixel_uv_size)
{
	float s0 = GetColourForEllispse(vec2(0.5,0.35*CHAR_HEIGHT),vec2(0.3*CHAR_ASPECT,0.25*CHAR_HEIGHT),0.08,uv,pixel_uv_size);
    float s1 = GetColourForCubicSpline(vec3(AR(0.2),H(0.23),0.08), vec3(AR(0.1),H(0.6),0.09), vec3(AR(0.2),H(0.9),0.02), vec3(AR(0.6),H(0.85),0.13), uv, pixel_uv_size);

    return max(s0,s1);
}

float Char7(vec2 uv, float pixel_uv_size)
{
    float s0 = GetColourForCubicSpline(vec3(AR(0.2),H(0.8),0.11), vec3(AR(0.4),H(0.7),0.06), vec3(AR(0.6),H(0.8),0.06), vec3(AR(0.8),H(0.8),0.13), uv, pixel_uv_size);
    float s1 = GetColourForCubicSpline(vec3(AR(0.8),H(0.8),0.13), vec3(AR(0.5),H(0.6),0.02), vec3(AR(0.4),H(0.4),0.06), vec3(AR(0.5),H(0.2),0.16), uv, pixel_uv_size);
    
    return max(s0,s1);
}

float Char8(vec2 uv, float pixel_uv_size)
{
	float s0 = GetColourForEllispse(vec2(0.5,0.35*CHAR_HEIGHT),vec2(0.3 * CHAR_ASPECT,0.25*CHAR_HEIGHT),0.08,uv,pixel_uv_size);
	float s1 = GetColourForEllispse(vec2(0.5,0.76*CHAR_HEIGHT),vec2(0.2 * CHAR_ASPECT,0.14*CHAR_HEIGHT),0.07,uv,pixel_uv_size);
    
    return max(s0,s1);
}

float Char9(vec2 uv, float pixel_uv_size)
{
	return Char6(vec2(1.0-uv.x, CHAR_HEIGHT-uv.y),pixel_uv_size);
}

#undef AR
#undef H


float CharDot(vec2 uv, float pixel_uv_size)
{
    float thickness = 0.1;
    
    float d = distance(uv, vec2(0.8,0.2));
    float s = thickness - d;

    float aa = smoothstep(0.0, pixel_uv_size, s);
    
    return aa;
}

float CharPi(vec2 uv, float pixel_uv_size)
{
    float s0 = GetColourForCubicSpline(vec3(0.20,0.85,0.13), vec3(0.4,0.8,0.10), vec3(0.70,0.8,0.075), vec3(0.8,0.9,0.09), uv, pixel_uv_size);
    float s1 = GetColourForCubicSpline(vec3(0.35,0.80,0.10), vec3(0.4,0.6,0.08), vec3(0.40,0.3,0.010), vec3(0.2,0.2,0.08), uv, pixel_uv_size);
    float s2 = GetColourForCubicSpline(vec3(0.70,0.80,0.08), vec3(0.7,0.7,0.08), vec3(0.73,0.4,0.050), vec3(0.9,0.2,0.04), uv, pixel_uv_size);
    
    return (min(s0+s1+s2,1.0) + max(s0,max(s1,s2))) * 0.5;
}

float CharDigit(int digit, vec2 uv, float pixel_uv_size)
{
	if (digit < 5)
	{
		if (digit == 0) {return Char0(uv,pixel_uv_size);}
		if (digit == 1) {return Char1(uv,pixel_uv_size);}
		if (digit == 2) {return Char2(uv,pixel_uv_size);}
		if (digit == 3) {return Char3(uv,pixel_uv_size);}
		
		return Char4(uv,pixel_uv_size);
	}
	else
	{
		if (digit == 5) {return Char5(uv,pixel_uv_size);}
		if (digit == 6) {return Char6(uv,pixel_uv_size);}
		if (digit == 7) {return Char7(uv,pixel_uv_size);}
		if (digit == 8) {return Char8(uv,pixel_uv_size);}
		
		return Char9(uv,pixel_uv_size);
	}
}

// ============================================================================================
// GRAPHICS PRIMS

vec2 ApplyWarp(vec2 uv, float seed)
{
	uv += cos(4.0 * uv.x - seed*67.0) * vec2(0.007, 0.009);
	uv += sin(5.0 * uv.y - seed*89.0) * vec2(0.009,-0.008);

	return uv;
}

vec2 ApplyBulge(vec2 uv)
{
    //return uv - normalize(uv - vec2(0,5)) * smoothstep(3.0, 12.0, distance(uv, vec2(0,7))) + sin( cos(uv.x * uv.x * 0.05) + iGlobalTime) * 0.04;
    return uv + normalize(uv - vec2(0,20.0)) * 2.0 + sin( cos(uv.x * uv.x * 0.06) + iGlobalTime) * 0.05;
}

// box_dx/dy normalised please. Returns colour/alpha.
vec2 Box(vec2 box_origin, vec2 box_dx, vec2 box_dy, vec2 box_dims, float thickness, float roundness, vec2 uv, float pixel_uv_size)
{
	vec2 r = uv - box_origin;

	{
		float x = dot(r, box_dx);
		float y = dot(r, box_dy);

		r = ApplyWarp(vec2(x,y), 1.2);
	}

	vec2 r_in_box = clamp(r, vec2(0.0,0.0), box_dims);

	float dist_from_box = distance(r, r_in_box);
	float surface		= dist_from_box - thickness;

	float	colour	= smoothstep(pixel_uv_size, 0.0, surface);
	float	alpha	= colour;
    
    if (r == r_in_box)
    {
		vec2 box_half_size	= box_dims * 0.5;
		vec2 from_mid		= r - box_half_size;
		vec2 to_corner		= sign(from_mid);
		vec2 nearest_corner = box_half_size + to_corner * box_half_size;
		vec2 corner_sphere	= nearest_corner - to_corner * roundness;
		vec2 to_edge		= abs(box_half_size) - abs(from_mid);

		float dist_from_edge = min(to_edge.x, to_edge.y);

		colour = smoothstep(pixel_uv_size, 0.0, dist_from_edge);

		if (sign(r - corner_sphere) == to_corner)
		{
			float dist_from_corner = roundness - distance(corner_sphere, r);

			colour = max(colour, smoothstep(pixel_uv_size, 0.0, dist_from_corner));
		}
    }

	return vec2(colour, alpha);
}

vec2 Circle(vec2 circle_origin, float circle_radius, float thickness, vec2 uv, float pixel_uv_size)
{
	float d = distance(uv, circle_origin);

	float surface	= abs(d - circle_radius) - thickness * 0.5;
	float colour	= smoothstep(pixel_uv_size, 0.0, surface);
	float alpha		= (d < circle_radius) ? 1.0 : colour;

	return vec2(colour, alpha);
}

// Circle with a sprial in the middle!
vec2 Wheel(vec2 wheel_origin, float wheel_radius, float wheel_angle, float thickness, vec2 uv, float pixel_uv_size)
{
	vec2 r = uv - wheel_origin;

	// We need wheel space, w.
	float sa = sin(wheel_angle);
	float ca = cos(wheel_angle);

	vec2 w = vec2(
				dot(r, vec2( sa,ca)),
				dot(r, vec2(-ca,sa)));

	// Wonky please!
	w = ApplyWarp(w, 0.11);

	float d = length(w);

	float surface	= abs(d - wheel_radius) - thickness * 0.5;
	float colour	= smoothstep(pixel_uv_size, 0.0, surface);
	float alpha		= (d < wheel_radius) ? 1.0 : colour;

	if (d < wheel_radius)
	{
        if (d < thickness * 2.0)
        {
            colour = smoothstep(pixel_uv_size, 0.0, d - thickness * 1.0);
        }
	
		// So the point on the spiral, s.
		float a = atan(w.y,w.x);
		float d = a + 3.1;
		d *= d;
		d *= 0.027;
		d *= wheel_radius;

		vec2 s = normalize(w) * d;

		float spiral_surface	= distance(s, w) - thickness * 0.5;
		float spiral_colour		= smoothstep(pixel_uv_size, 0.0, spiral_surface);

		colour = max(colour, spiral_colour);
	}

	return vec2(colour, alpha);
}

// chimney_dims = width bot, height, width top.
vec2 Chimney(vec2 chimney_origin, vec2 chimney_dx, vec2 chimney_dy, vec3 chimney_dims, float anim, float thickness, vec2 uv, float pixel_uv_size)
{
	vec2 r = vec2(
				dot(uv - chimney_origin, chimney_dx),
				dot(uv - chimney_origin, chimney_dy));

	if (r.y < 0.0 || r.y > chimney_dims.y + thickness)
	{
		return vec2(0.0, 0.0);
	}

	r.x = abs(r.x);

	if (r.x > chimney_dims.x + thickness + chimney_dims.y * 0.4)
	{
		return vec2(0.0, 0.0);
	}

    float b = 1.0 - anim;
	float q = 1.0-b*b*b*b;
	float a = 2.0*(1.0-q)*q;

    float down	= 1.0 - a * 0.5;
    float push	= a;
    
    chimney_dims.z *= 1.0 + a * 0.2;
    
	vec2 cp0 = vec2(chimney_dims.x, 0.0);
	vec2 cp1 = vec2(chimney_dims.x - chimney_dims.y * 0.33 * push, chimney_dims.y * 0.33);
	vec2 cp2 = vec2(chimney_dims.z, chimney_dims.y * 0.66 * down);
	vec2 cp3 = vec2(chimney_dims.z, chimney_dims.y * down);

	float t = GetNearestPointAlongCubicSpline(cp0,cp1,cp2,cp3, r);

	vec2 pt = GetPointOnCubicSpline(cp0,cp1,cp2,cp3, t);

	float dist_from_edge	= distance(pt, r);
	float surface			= dist_from_edge  - thickness * 0.5;
	float colour			= smoothstep(pixel_uv_size, 0.0, surface);
	float alpha				= (r.x < pt.x) ? 1.0 : colour;

	// Top?
    float bend = 1.0 - a * 0.3;
    
	//if (alpha > 0.0 && r.y > chimney_dims.y * bend - thickness)
	{
		cp0 = vec2(chimney_dims.z * -1.0, chimney_dims.y * down);
		cp1 = vec2(chimney_dims.z * -0.3, chimney_dims.y * down * bend);
		cp2 = vec2(chimney_dims.z * +0.3, chimney_dims.y * down * bend);
		cp3 = vec2(chimney_dims.z * +1.0, chimney_dims.y * down);

		t = GetNearestPointAlongCubicSpline(cp0,cp1,cp2,cp3, r);

		pt = GetPointOnCubicSpline(cp0,cp1,cp2,cp3, t);

		dist_from_edge	= distance(pt, r);
		surface			= dist_from_edge  - thickness * 0.5;
		colour			= max(colour, smoothstep(pixel_uv_size, 0.0, surface));
		alpha			= (r.y > pt.y) ? colour : alpha;
	}

	return vec2(colour, alpha);
}

float Puff(float puff, float seed, vec2 uv, float pixel_uv_size)
{
	if (!Is0To1(uv))
    {
        return 0.0;
    }
    
    const float GRID_SIZE = 4.0;

	vec2 grid		= uv * vec2(GRID_SIZE, GRID_SIZE);
	vec2 gsquare	= floor(grid);

	seed *= gsquare.x + 7.8;
	seed *= gsquare.y + 9.8;
	seed  = sin(seed);

	float	random_colour	= mix( 1.0, 2.0, fract(seed * 15.67));
	float	random_time		= mix(-0.3, 0.3, fract(seed * 27.89));
	vec2	random_middle	= vec2(
								mix(0.35, 0.65, fract(seed * 37.22)),
								mix(0.35, 0.65, fract(seed * 47.89)));

	float dist_from_middle_of_puff		= distance(gsquare + vec2(0.5,0.5), vec2(GRID_SIZE,GRID_SIZE) * 0.5);
	float dist_from_middle_of_square	= distance(grid, gsquare + random_middle);

	float shape			= max(0.0, 1.25 - dist_from_middle_of_puff / (GRID_SIZE*0.5-0.5));
	float start_time	= mix(0.5, 0.0, dist_from_middle_of_puff / (GRID_SIZE * 0.5));
	float s				= clamp(puff + start_time + random_time, 0.0, 1.0);
	float fade			= random_colour * shape * smoothstep(1.0,0.9,s);
	float size			= (1.0-s)*s * 1.2;

	float colour = smoothstep(pixel_uv_size * GRID_SIZE, 0.0, abs(dist_from_middle_of_square - size)-0.01);

	return colour * fade;
}

float PrintNumber(float n, vec2 digit_uv, vec2 uv, float pixel_uv_size)
{
	vec2 rel_uv = uv - digit_uv;

	if (rel_uv.y < 0.0 || rel_uv.y > 1.0)
	{
		return 0.0;
	}

	float digit_place = floor(rel_uv.x - 3.0);

	if (digit_place >= 1.0 || digit_place <= -3.0)
	{
		return 0.0;
	}

	int digit = int(10.0 * fract(n * pow(10.0, digit_place)));
	
	return CharDigit(digit, fract(rel_uv), pixel_uv_size);
}


// ============================================================================================

#define SPEED_SCALE 3.0

float GetTrainXAtTime(float time)
{
    if (time < 2.0)
    {
        return SPEED_SCALE * (time*time / 4.0 - 3.5);
    }
    
	return SPEED_SCALE * (time - 4.5);
}

vec2 GetCameraPosAtTime(float time)
{
    if (time < 12.0)
    {
        return vec2(time*time / 24.0, 0.0) * SPEED_SCALE;
    }
 
	float t = time - 12.0;

	if (t > 60.0)
	{
		return vec2(61.0, 0.0) * SPEED_SCALE;
	}

	if (t > 50.0)
	{
		float x = (t - 50.0) / 20.0;

		return vec2(56.0 + 20.0*x - 20.0*x*x, 0.0) * SPEED_SCALE;
	}

	return vec2(6.0+t, 0.0) * SPEED_SCALE;
}

float GetTrackHeight(float world_x)
{
	return 2.5 + sin(world_x * 0.29) + sin(world_x * 0.47) * 0.43;
}

void GetTrainWheelPositions(float time, out vec2 out_wheel_0, out vec2 out_wheel_1)
{
	const float TRAIN_WHEELBASE = 3.0;

	float train_x0 = GetTrainXAtTime(time);
	float train_x1 = train_x0 + TRAIN_WHEELBASE;

	vec2 train_wheel_0 = vec2(train_x0, GetTrackHeight(train_x0));
	vec2 train_wheel_1 = vec2(train_x1, GetTrackHeight(train_x1));

	train_wheel_1	= train_wheel_0 + normalize(train_wheel_1 - train_wheel_0) * TRAIN_WHEELBASE;
	train_wheel_1.y	= GetTrackHeight(train_wheel_1.x);
	train_wheel_1	= train_wheel_0 + normalize(train_wheel_1 - train_wheel_0) * TRAIN_WHEELBASE;
	train_wheel_1.y	= GetTrackHeight(train_wheel_1.x);
	
	out_wheel_0 = train_wheel_0;
	out_wheel_1 = train_wheel_1;
}

void GetTrainChimneyPosition(float time, out vec2 out_chimney_top, out vec2 out_chimney_dir)
{
	vec2 wheel_0;
	vec2 wheel_1;

	GetTrainWheelPositions(time, wheel_0, wheel_1);

	vec2 dx = normalize(wheel_1 - wheel_0);
	vec2 dy = vec2(-dx.y,dx.x);

	out_chimney_top = wheel_0 + dx * 2.25 + dy * 3.8;
	out_chimney_dir = dy;
}

// ============================================================================================

#define SCREEN_HEIGHT 15.0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// Our sequence takes one minute.
    float time = min(max(0.0, iGlobalTime - 2.0) * (1.0 / 60.0),1.0) * 80.0;
 
	// Our screen_uv space has (0,0) at the middle, bottom of the screen and is SCREEN_HEIGHT high and +/- 12*aspect/2 wide.
	vec2	uv		= fragCoord.xy / iResolution.xy;
    float	aspect	= float(iResolution.x) / float(iResolution.y);

	uv.x -= 0.5;
    uv.x *= aspect;
	uv   *= SCREEN_HEIGHT;

	// Size of a pixel in uv space for antialiasing. Enlarge to get extra creamy AA!
	float pixel_uv_size = 2.0 * SCREEN_HEIGHT / iResolution.y;

    // Accumulate final colour into here.
	vec2 final_colour = vec2(0.0, 0.0);

    // Do this now so we can blur the screen edges.
    float vignette;
	{
        float fade_out = smoothstep(65.0, 79.0, time);
        
        uv *= 1.0 - fade_out * 0.15;
        uv.y += fade_out * 4.0;
        
        vec2 vignette_uv = abs(vec2(2.04,2.0) * (fragCoord.xy / iResolution.xy) - vec2(1.02,1.0));
        vignette_uv += fade_out * 0.5;
        vignette_uv *= vignette_uv;
        vignette_uv *= vignette_uv;
        vignette = mix(0.2 * (1.0 - fade_out), 1.0 - fade_out * fade_out * fade_out, 1.0 - vignette_uv.x - vignette_uv.y);

        pixel_uv_size /= vignette + 0.1;
	}

	// World space is in the same scale as uv space.
	vec2 camera_pos = GetCameraPosAtTime(time);

	// The track first.
	vec2 world_pos = camera_pos + uv;
	
	{
		float track_y		= GetTrackHeight(world_pos.x);
		float dist_to_track	= abs(track_y - world_pos.y - 0.1);
		float surface		= dist_to_track - 0.05;
		float colour		= smoothstep(pixel_uv_size, 0.0, surface);

		final_colour.xy += colour;
	}
    
	#if USE_INTEGERS
	const float	DIGITS_PER_LINE			= 15.0;
	const float	LINES_OF_PI				= (float(MAX_DIGIT) + DIGITS_PER_LINE - 1.0) / DIGITS_PER_LINE;
	#else
	const float	DIGITS_PER_LINE			= 10.0;
	const float	LINES_OF_PI				= ceil((MAX_DIGIT + DIGITS_PER_LINE - 1.0) / DIGITS_PER_LINE);
	#endif

	const int	NUM_DIGITS_IN_FLIGHT	= 4;
	const float	TIME_FOR_FLIGHT			= 4.0;
	const float TIME_PER_PUFF			= TIME_FOR_FLIGHT / float(NUM_DIGITS_IN_FLIGHT);
	const vec2	DEST_DIGIT_UV			= vec2(DIGITS_PER_LINE * -0.5, SCREEN_HEIGHT * 0.65);
	const float	KERNING					= 0.9;
	const float	TIME_TO_START_PUFFING	= 3.0;

    
    float train_x = GetTrainXAtTime(time);

    if (world_pos.x > train_x - 3.0 && world_pos.x < train_x + 5.0 && world_pos.y > SCREEN_HEIGHT * 0.05 && world_pos.y < SCREEN_HEIGHT * 0.6)
    {
        // Where is the train now?
        vec2 train_wheel_0;
        vec2 train_wheel_1;

        GetTrainWheelPositions(time, train_wheel_0, train_wheel_1);

        vec2 train_dx = normalize(train_wheel_1 - train_wheel_0);
        vec2 train_dy = vec2(-train_dx.y,train_dx.x);

        // Big wheel.
        {
            float	wheel_angle		= time * 3.0;
            float	wheel_wonky		= sin(wheel_angle) * 0.05;

            train_wheel_0 += train_dy * wheel_wonky;

            vec2	wheel_uv		= train_wheel_0 + train_dy * 1.0;
            float	wheel_radius	= 1.0;

            vec2 wheel_colour = Wheel(wheel_uv, wheel_radius, wheel_angle, 0.1, world_pos, pixel_uv_size);

            final_colour += wheel_colour * (1.0 - final_colour.y);
        }

        // Little wheel.
        {
            float	wheel_angle		= time * 5.1;
            float	wheel_wonky		= sin(wheel_angle) * 0.04;

            train_wheel_1 += train_dy * wheel_wonky;

            vec2	wheel_uv		= train_wheel_1 + train_dy * 0.6;
            float	wheel_radius	= 0.6;

            vec2 wheel_colour = Wheel(wheel_uv, wheel_radius, wheel_angle, 0.1, world_pos, pixel_uv_size);

            final_colour += wheel_colour * (1.0 - final_colour.y);
        }

        // Recalculate train basis due to wonky wheels!
        train_dx = normalize(train_wheel_1 - train_wheel_0);
        train_dy = vec2(-train_dx.y,train_dx.x);

        // ------------------------------------------------------------------------
        // Train

        {
            vec2 box_uv		= train_wheel_0 - train_dx * 0.2 + train_dy * 0.6;
            vec2 box_dims	= vec2(3.0, 2.0);
            vec2 box_colour	= Box(box_uv, train_dx, train_dy, box_dims, 0.1, 0.1, world_pos, pixel_uv_size);

            final_colour += box_colour * (1.0 - final_colour.y);

            {
                vec2 cab_uv		= box_uv + train_dx * 0.2 + train_dy * 2.1;
                vec2 cab_dx		= train_dx;
                vec2 cab_dy		= train_dy;
                vec2 cab_dims	= vec2(1.0, 1.6);

                vec2 cab_colour	= Box(cab_uv, cab_dx, cab_dy, cab_dims, 0.1, 0.1, world_pos, pixel_uv_size);

                if (dot(uv - cab_uv, cab_dx) < 1.0)
                {
                    vec2 window_uv = cab_uv + cab_dx * 0.9 + cab_dy * 0.9;
                    vec2 window_colour	= Circle(window_uv, 0.4, 0.1, world_pos, pixel_uv_size);

                    cab_colour.x += window_colour.x * cab_colour.y;
                }

                final_colour += cab_colour * (1.0 - final_colour.y);
            }

            {
                vec2	chimney_uv		= box_uv + train_dx * box_dims.x * 0.8 + train_dy * box_dims.y;
                vec2	chimney_dx		= train_dx;
                vec2	chimney_dy		= train_dy;
                vec3	chimney_dims	= vec3(0.3, 1.1, 0.4);
                float	chimney_anim	= fract(time * TIME_PER_PUFF);

                if (time < TIME_TO_START_PUFFING || time + TIME_PER_PUFF >= TIME_TO_START_PUFFING + float(MAX_DIGIT) * TIME_PER_PUFF)
                {
                    chimney_anim = 0.0;
                }

                vec2	chimney_colour	= Chimney(chimney_uv, chimney_dx, chimney_dy, chimney_dims, chimney_anim, 0.1, world_pos, pixel_uv_size);

                final_colour += chimney_colour * (1.0 - final_colour.y);
            }

            {
                vec2 circle_uv		= box_uv + train_dx * 3.0 + train_dy * 1.1;
                vec2 circle_colour	= Circle(circle_uv, 0.6, 0.1, world_pos, pixel_uv_size);

                final_colour += circle_colour * (1.0 - final_colour.y);
            }
        }
    }

	// ------------------------------------------------------------------------
	// The digits we've already found.

    if (time < 79.0)
	{
        
        vec2 found_uv 	= (ApplyBulge(uv) - DEST_DIGIT_UV) / vec2(KERNING,1.0);
		vec2 found_base	= floor(found_uv);

		// Which digit of pi?
		float line		= -floor(found_base.y);
		float column	=  floor(found_base.x);

		if (line >= 0.0 && column >= 0.0)
		{
			float nth_digit = float(MAX_DIGIT);	// MAX_DIGIT -> Invalid.

			if (column == 0.0)
			{
				// First column only has the first digit.
				if (line == 0.0)
				{
					nth_digit = -1.0;
				}
			}
			else
            if (column <= DIGITS_PER_LINE)
			{
				nth_digit = line * DIGITS_PER_LINE + (column - 1.0);
			}

			if (nth_digit < float(MAX_DIGIT))
			{
				// How many digits have arrived already?
				float num_arrived = floor(time - TIME_FOR_FLIGHT - TIME_TO_START_PUFFING);

				if (nth_digit < num_arrived)
				{
					vec2 digit_uv = (found_uv - found_base) * vec2(KERNING,1.0) + vec2((1.0 - KERNING)*0.5, 0.0);
                
					if (IsDigitUV(digit_uv))
					{
                        #if USE_INTEGERS
						int pi_digit = GetNthDigitOfPi(int(nth_digit));
                        #else
						int pi_digit = GetNthDigitOfPi(nth_digit);
                        #endif
						final_colour.x += CharDigit(pi_digit, digit_uv, pixel_uv_size);	
                    }
                        
                    if (nth_digit == -1.0)
                    {
                        final_colour.x += CharDot(digit_uv, pixel_uv_size);
					}
				}
			}
		}
	}

	// ------------------------------------------------------------------------
	// Digit puffs.

    if (uv.x > SCREEN_HEIGHT * -0.7 && uv.y > SCREEN_HEIGHT * 0.3 && uv.y < SCREEN_HEIGHT * 0.9)
    {
        for (int i = 0; i < NUM_DIGITS_IN_FLIGHT; i++)
        {
            float offset_i	= float(i) * (TIME_FOR_FLIGHT / float(NUM_DIGITS_IN_FLIGHT));
            float puff_time	= (time - offset_i - TIME_TO_START_PUFFING) / TIME_FOR_FLIGHT;

            if (puff_time < 0.0)
            {
                continue;
            }

            float puff_digit = floor(puff_time) * float(NUM_DIGITS_IN_FLIGHT) + float(i) - 1.0;

            if (puff_digit >= 60.0)	// Always puff even if no more digits... .to keep in sync with sound
            {
                continue;
            }

            float	puff_start_time				= floor(puff_time) * TIME_FOR_FLIGHT + offset_i + TIME_TO_START_PUFFING;
            float	puff_t						= pow(fract(puff_time), 0.75);
            float	puff_size					= 1.0 + puff_t * 3.0;
            float	digit_size					= min(0.3 + puff_t, 1.0);
            vec2	camera_pos_at_start_time	= GetCameraPosAtTime(puff_start_time);

            vec2 chimney_pos_at_start_time;
            vec2 chimney_dir_at_start_time;

            GetTrainChimneyPosition(puff_start_time, chimney_pos_at_start_time, chimney_dir_at_start_time);

            vec2 puff_cp0 = chimney_pos_at_start_time;
            vec2 puff_cp1 = chimney_pos_at_start_time + chimney_dir_at_start_time * 5.0;
            vec2 puff_cp2 = puff_cp1 + vec2(0.0, -1.0);
            vec2 puff_cp3 = puff_cp1 + vec2(0.0, -2.0);

            vec2 puff_pos	= GetPointOnCubicSpline(puff_cp0, puff_cp1, puff_cp2, puff_cp3, puff_t);
            vec2 puff_uv	= (world_pos - puff_pos)/puff_size+0.5;

            {
                final_colour.x += Puff(puff_t * 1.5, puff_start_time + 5.6, puff_uv - 0.05, pixel_uv_size / puff_size) * (1.0 - final_colour.y);
                final_colour.x += Puff(puff_t * 1.5, puff_start_time + 7.9, puff_uv + 0.05, pixel_uv_size / puff_size) * (1.0 - final_colour.y);
            }

            if (puff_digit >= float(MAX_DIGIT))
            {
                continue;
            }
            
            vec2 digit_dest_uv;

            if (puff_digit == -1.0)
            {
                // This is the first digit of pi.
                digit_dest_uv = DEST_DIGIT_UV - (1.0 - KERNING) * 0.5;
            }
            else
            {
				#if USE_INTEGERS
                int line;
                int column;
                DivMod(int(puff_digit), int(DIGITS_PER_LINE), line, column);
				#else
                float line;
                float column;
                DivMod(puff_digit, DIGITS_PER_LINE, line, column);
				#endif

                digit_dest_uv = DEST_DIGIT_UV + vec2((float(column) + 1.0) * KERNING - (1.0 - KERNING) * 0.5, -float(line));
            }

            // The digit of pi are we puffing out of the train.
            vec2 digit_cp0 = chimney_pos_at_start_time;
            vec2 digit_cp1 = chimney_pos_at_start_time + chimney_dir_at_start_time * 5.0;
            vec2 digit_cp3 = digit_dest_uv + camera_pos;
            vec2 digit_cp2 = digit_cp3 + vec2(2.0, -8.0);

            float	bulge_amount	= smoothstep(0.0, 0.9, puff_t);
            vec2	bulged_uv		= mix(uv, ApplyBulge(uv), bulge_amount);

            vec2 digit_pos	= GetPointOnCubicSpline(digit_cp0, digit_cp1, digit_cp2, digit_cp3, puff_t);
            vec2 digit_uv	= (bulged_uv + camera_pos - digit_pos)/digit_size;

            if (IsDigitUV(digit_uv))
            {
				#if USE_INTEGERS
                int pi_digit = GetNthDigitOfPi(int(puff_digit));
                #else
                int pi_digit = GetNthDigitOfPi(puff_digit);
                #endif

                final_colour += CharDigit(pi_digit, digit_uv, pixel_uv_size) * (1.0 - final_colour.y);
            }
        }
    }
    
	// Apply vignette
    final_colour.x = sqrt(clamp(final_colour.x,0.0,1.0)) * vignette;
   
    if (time >= 75.0)
    {
        vec2 original_uv = fragCoord.xy / iResolution.xy;
        original_uv.x -= 0.5;
        original_uv.x *= aspect;
        original_uv   *= SCREEN_HEIGHT;
        float original_pixel_uv_size = 2.0 * SCREEN_HEIGHT / iResolution.y;
        
        vec2 pi_uv = (original_uv - vec2(0.0, SCREEN_HEIGHT * 0.62)) * 0.4 + 0.5;
        float pi = CharPi(pi_uv, original_pixel_uv_size) * 4.0 * smoothstep(75.0,80.0,time);
        final_colour.x += sqrt(pi);
    }
    
    fragColor = vec4(final_colour.xxx,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
