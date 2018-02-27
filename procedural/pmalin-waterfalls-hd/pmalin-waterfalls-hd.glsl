#version 130
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
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
vec2 iChannelResolution = vec2(64.0, 64.0);
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

// Waterfalls - @P_Malin
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Some waterfalls and a rainbow.
// Made with so many hacks I don't know what is real any more.
// I still need to work on the camera.

// If you are lucky you can try to enable high quality...
// If you are unlucky you may get "Unkown error"
#define HIGH_QUALITY

#ifdef HIGH_QUALITY
	#define ENABLE_SCENERY_REFLECTION
#endif


#define MORE_WATERFALLS
#define ENABLE_WATERFALL
#define ENABLE_WATER_REFLECTIONS

#define ENABLE_WATERFALL_REFLECTION

//#define PREVIEW_MODE

#ifndef PREVIEW_MODE

	#define ENABLE_ATMOSPHERE
	#define ENABLE_WATER_PLANE
	#define ENABLE_DROPLETS

#endif

const float kFarClip = 1000.0;

struct S_Waterfall
{
	mat3 mRot;
	vec3 vTrans;
	float fWidth;
	float fHeight;
	float fRadius;
	float fZMax;
	float fQuadraticA;
	float fQuadraticB;
	float fNoiseOffset;
};

vec3 vSunColour = vec3(1.0, 0.9, 0.8) * 5.0;

const vec3 vSkyBase = vec3(0.05, 0.2, 1.0);

vec3 vSkyColourA = vSkyBase * 1.5;
vec3 vSkyColourB = vSkyBase * 0.5;

const vec3 vAmbientLight = (vSkyBase + vec3(0.5));

//const vec3 vWaterExtinction = (vec3(1.0) - vec3(0.1, 0.6, 0.8)) * 1.0; // clear water
const vec3 vWaterExtinction = (vec3(1.0) - vec3(0.7, 0.6, 0.2)) * 1.5; // murky water

vec3 vSunDir = normalize(vec3(-0.5, -1.5, 1.0));

#ifdef MORE_WATERFALLS
const int kWaterfallCount=2;
#else
const int kWaterfallCount=1;
#endif 
	
S_Waterfall g_Waterfall[kWaterfallCount];

float gPixelRand;

float Checker(const in vec2 vUV)
{
	return step(fract((floor(vUV.x) + floor(vUV.y)) * 0.5), 0.25);
}

float hash( const in float n ) {
	return fract(sin(n)*4378.5453);
}

vec2 GetWindowCoord( const in vec2 vUV )
{
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= iResolution.x / iResolution.y;

	return vWindow;	
}

vec3 GetCameraRayDir( const in vec2 vWindow, inout vec3 vCameraPos, const in vec3 vCameraTarget, const in float fFov )
{
	vec3 vForward = normalize(vCameraTarget - vCameraPos);
	vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
	vec3 vUp = normalize(cross(vForward, vRight));	
	
	vec3 vDir = normalize(vWindow.x * vRight * fFov + vWindow.y * vUp * fFov + vForward);

#ifdef ENABLE_DROPLETS	
	//vCameraPos = vCameraPos + vDir * dot(vDir, vForward) * 0.5; // Why does this break the sky?!
	
	const vec3 vSplashPos = vec3(0.0, 1.0, -1.0);
	vec3 vSplashOffset = vCameraPos - vSplashPos;
	float fSplashAmount = 1.0 - (clamp(dot(vSplashOffset, vSplashOffset) * 0.005, 0.0, 1.0));
	
	const float fRepeat = 25.0;
	float t = floor(vWindow.x * fRepeat);
	float r = hash(t);
	float fRadiusSeed = fract(r * 100.0);
	float radius = fRadiusSeed * fRadiusSeed * 0.02 + 0.001;
	float fYpos = r * r - clamp(mod(iGlobalTime * radius * 2.0, 1.2) - 0.2, 0.0, 1.0);
	radius *= fSplashAmount;
	vec2 vPos = vec2((t + 0.5) * (1.0 / fRepeat), fYpos * 2.0 - 1.0);
	vec2 vDelta = vWindow - vPos;
	const float fInvMaxRadius = 1.0 / (0.02 + 0.001);
	vDelta.x /= (vDelta.y * fInvMaxRadius) * -0.15 + 0.85; // big droplets tear shaped
	vec2 vDeltaNorm = normalize(vDelta);
	float l = length(vDelta);
	if(l < radius)
	{		
		l = l / radius;
		
		float lz = sqrt(1.0 - l * l);		
				
		vec3 vNormal = l * vDeltaNorm.x * vRight + l* vDeltaNorm.y * vUp - lz * vForward;
		//vNormal = mix(vNormal, -vDir, (l * l * l * 0.9 + 0.1)); // flatten normal and fade out at edge
		vNormal = normalize(vNormal);
		vDir = refract(vDir, vNormal, 0.7);
	}
	/*else
	{
		vDir.x += (fract(sin(gPixelRand * 123.456) * 789.0) - 0.5) * fSplashAmount * 0.025;
		vDir.y += (fract(sin(gPixelRand * 234.567) * 890.1) - 0.5) * fSplashAmount * 0.025;
	}*/
#endif // ENABLE_DROPLETS	
	
	return vDir;
}

vec3 ApplyVignetting( const in vec2 vUV, const in vec3 vInput )
{
	vec2 vOffset = (vUV - 0.5) * sqrt(2.0);
	
	float fDist = dot(vOffset, vOffset);
	
	const float kStrength = 0.95;
	const float kPower = 1.5;

	return vInput * ((1.0 - kStrength) +  kStrength * pow(1.0 - fDist, kPower));
}

vec3 ApplyTonemap( vec3 x )
{
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}


float SunShadow(const in vec3 p)
{
	float f = -p.x * 1.1 + p.y - 1.5 - p.z;
	float fSpread = 4.0 / (abs(p.y -10.0)* 0.5);
	return f * fSpread;
}

float SunShadowClamped(const in vec3 p)
{
	return clamp(SunShadow(p), 0.0, 1.0);
}

float RainbowShadow(const in vec3 p)
{
	float f = -p.x * 1.1 + p.y - 1.5 - p.z;
	float fSpread = 0.05;
	return clamp(f * fSpread + 0.1, 0.0, 1.0);
}


float SmoothNoise( vec3 p );
float SmoothNoise( float p );

float GetRoundedBoxDistance( const in vec3 vPos, const in vec3 vMin, const in vec3 vMax, const in float fRadius )
{
	vec3 vCentre = (vMin + vMax) * 0.5;
	vec3 vSize = abs(vMax - vMin) * 0.5;
	return length(max(abs(vPos-vCentre)-vSize,0.0))-fRadius;
	
	// signed version
	//vec3 d = abs(vPos - (vMin + vMax) * 0.5) - (vMax - vMin) * 0.5;
	//return min(max(d.x,max(d.y,d.z)),0.0) +
	//	length(max(d,0.0)) - fRadius;	
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k)
{
	return -smin(-a, -b, k);
}

float GetSceneDistance( const in vec3 vPos )
{
	float fFloorHeight = -2.0;
	
	float fFloorDist = vPos.y - fFloorHeight;
	
	float fRiverDist = GetRoundedBoxDistance( vPos, vec3(-8.0, 1.5, -kFarClip), vec3(4.0, 1.5, -0.5), 6.0);
	
	float fCliffDist = -GetRoundedBoxDistance( vPos, vec3(0.0, -kFarClip, -1000.0), vec3(0.0, kFarClip, -20.0 + 7.5), 20.0);	
	fCliffDist = max(fCliffDist, -11.0 + vPos.y - vPos.z * 0.05);
	
	float fTopRiverDist = GetRoundedBoxDistance( vPos, vec3(-4.0, 12.0, -100.0), vec3(4.0, 12.0, kFarClip), 3.0);

	// match floor of top river to waterfall intensity
	float n = SmoothNoise(vPos.x + g_Waterfall[0].fNoiseOffset);
	fTopRiverDist += n * n * n + 1.0;
	
	float fResult = smax(fFloorDist, -fRiverDist, 0.75);
	fResult = smin(fCliffDist, fResult, 0.9);
#ifdef MORE_WATERFALLS
	float fTopRiver2Dist = GetRoundedBoxDistance( vPos, vec3(-kFarClip, 11.0, -5.0), vec3(0.0, 100.0, -5.0), 2.0);
	fResult = max(fResult, -fTopRiver2Dist);
#endif
	fResult -= SmoothNoise(vPos * vec3(0.5, 1.25, 0.5) + vec3(0.0, -vPos.z * 0.25, 0.0));
 	fResult = smax(fResult, -fTopRiverDist, 0.05);
	
	return fResult;
}

vec2 RaymarchScene( const in vec3 vRayOrigin, const in vec3 vRayDir )
{
	float fTClosest = kFarClip;	
	float fClosest = kFarClip;

	float d = 0.0;
	float fScaledD = 0.0;
	float t = 0.01;
	
	for(int i=0; i<64; i++)
	{
		d = GetSceneDistance(vRayOrigin + vRayDir * t);
		fScaledD = d / t;
		if(fScaledD < fClosest)
		{
			fTClosest = t;
			fClosest = fScaledD;
		}
		if( d < 0.01 )
		{
			break;
		}
		t = t + d * 0.95;
		if( t > kFarClip)
		{
			break;
		}
	}
	
	if( t > kFarClip )
		return vec2(fTClosest, fClosest);
		
	return vec2(t, 0.0);
}

vec3 GetTerrainTexture( const in vec3 vPos, const float fNormalY )
{
	vec3 vSample0 = texture(iChannel0, vPos.xz * 0.25).rgb;
	vSample0 = vSample0 * vSample0;
	vSample0 *= vec3(0.2, 0.22, 0.05);
	
	vec2 vUV1 = vec2(atan(vPos.x, vPos.z) * 15.0, vPos.y - vPos.z * 0.25) * 0.1;
	vec3 vSample1 = texture(iChannel0, vUV1).rgb;
	vSample1 = vSample1 * vSample1;
	vSample1 *= vec3(0.6, 0.4, 0.1);
	
	float fBlend = clamp((fNormalY), 0.0, 1.0);
	vec3 vResult = mix(vSample1, vSample0, fBlend * fBlend);
	
	return vResult;
}

vec3 GetSkyColour( const in vec3 vRayOrigin, const in vec3 vRayDir )
{
	vec3 vSkyColour = mix(vSkyColourA, vSkyColourB, vRayDir.y);
	vec2 vCloudUV = 0.01 * vRayDir.xz / -vRayDir.y;
	vCloudUV += iGlobalTime * 0.0001;
	vec3 vCloud = texture(iChannel1, vCloudUV).rgb;
	
	float fBlend = vCloud.r * vCloud.r * 3.0;
	vSkyColour = vSkyColour * clamp(1.0 - fBlend, 0.0, 1.0) + fBlend;

	return vSkyColour;	
}

// return (rgb, distance)
vec4 TraceScene( const in vec3 vRayOrigin, const in vec3 vRayDir )
{
	vec2 vRaymarch = RaymarchScene( vRayOrigin, vRayDir );
	float t = vRaymarch.x;

	float blurRadius = 0.01;

	vec3 vPos = vRayOrigin + vRayDir * t;

	const float fEpsilon = 0.1;
	float fSceneDist = GetSceneDistance(vPos);
	float fSceneDistSun = GetSceneDistance(vPos - vSunDir * fEpsilon);
	float fSunIntensity = clamp( (fSceneDistSun - fSceneDist) * (1.0 / fEpsilon), 0.0, 1.0);

	float fSceneDistAmbient = GetSceneDistance(vPos + vec3(0.0, 1.0, 0.0) * fEpsilon);
	float fNormalY = (fSceneDistAmbient - fSceneDist) / fEpsilon;
	float fAmbientIntensity = clamp( (fNormalY * 0.5 + 0.5) * (vPos.y + 3.0) * 0.15, 0.0, 1.0);
	
	vec3 vResult = GetTerrainTexture(vPos, fNormalY);
	
	vResult *= vSunColour * SunShadowClamped(vPos) * fSunIntensity + vAmbientLight * fAmbientIntensity;
	
	vec4 vReturnValue = vec4(vResult, t);
		
	// blur terrain over sky
	{
		vec3 vSkyColour = GetSkyColour( vRayOrigin, vRayDir );
		
		float fBlend = 1.0 - clamp(vRaymarch.y / blurRadius, 0.0, 1.0);
		fBlend = fBlend * fBlend;
		fBlend = 1.0 - fBlend * fBlend;
		vReturnValue = mix(vReturnValue, vec4(vSkyColour, kFarClip), fBlend);
	}
	
	return vReturnValue;
}

float TraceWater( const in vec3 vRayOrigin, const in vec3 vRayDir )
{
	if( vRayDir.y >= 0.0 )
	{
		return kFarClip;
	}
	
	float fHeight = -2.5;
	return -(vRayOrigin.y - fHeight) / vRayDir.y;
}


float Quadratic( const in float x, const in float a, const in float b )
{
	return a * x * x + b * x;
}

float SolveQuadratic( const in float a, const in float b, const in float c )
{
	return (-b - sqrt( b * b - 4.0 * a * c )) / (2.0 * a);
}


float QuadraticDiff( const in float x, const in float a, const in float b )
{
	return 2.0 * a * x + b;
}

vec2 StepQuadratic( const in vec2 vCurr, const in vec2 vPos, const in float a, const in float b )
{
	float x = vCurr.x;
	float y = Quadratic(x, a, b);
	float dy_dx = QuadraticDiff(x, a, b);
	
	vec2 vNormal = normalize(vec2(dy_dx, -1.0));
	float d = dot(vNormal, vec2(x, y) - vCurr);
	
	vec2 newp = vCurr + vNormal * d;
	
	return newp;
}


vec2 ClosestPointOnQuadratic( vec2 vPos, float a, float b)
{
	vec2 vPos2 = StepQuadratic( vPos, vPos, a, b);
	
	vPos2.y = Quadratic( vPos2.x, a, b );
	
	return vPos2;
}

vec4 GetWaterfallSprayDistance( const in S_Waterfall waterfall, vec3 vPos )
{	
	vec3 vLocalPos = (vPos - waterfall.vTrans) * waterfall.mRot;
	
	vec2 vQuadraticPos = vLocalPos.zy;
	vQuadraticPos.x = clamp(vQuadraticPos.x, 0.0, 1000.0);

	vec2 quadraticResult = ClosestPointOnQuadratic( vQuadraticPos, waterfall.fQuadraticA, waterfall.fQuadraticB);
	
	vec3 vClosestPos = vLocalPos;
	vClosestPos.y = quadraticResult.y;
	vClosestPos.z = quadraticResult.x;
	
	vClosestPos.x = clamp(vClosestPos.x, -waterfall.fWidth, waterfall.fWidth);
	
	vec3 vUVW = vec3(vLocalPos.x, -length(vClosestPos.yz), vLocalPos.y - vClosestPos.y);
	
	if(	vClosestPos.y < -waterfall.fHeight)
	{
		vClosestPos.y = -waterfall.fHeight;
		vClosestPos.z = waterfall.fZMax;
	}

	float fDist = length(vLocalPos - vClosestPos) - waterfall.fRadius;

	return vec4(fDist, vUVW);
}

vec4 GetSprayDistance( out S_Waterfall waterfall, const in vec3 vPos )
{
	vec4 vResult = vec4(10000.0);
	
	waterfall = g_Waterfall[0];
	
	for(int i=0; i<kWaterfallCount; i++)
	{
		vec4 vInt = GetWaterfallSprayDistance(g_Waterfall[i], vPos);
		
		if(vInt.x < vResult.x)
		{
			vResult = vInt;
			waterfall = g_Waterfall[i];
		}		
	}
	
	return vResult;
}

vec2 TraceWaterfall( out S_Waterfall waterfall, out vec3 vUVW1, out vec3 vUVW2, const in vec3 vRayOrigin, const in vec3 vRayDir )
{
	waterfall = g_Waterfall[0];

	float t1 = 0.0;
	vec4 i1 = vec4(0.0);

	for(int i=0; i<16; i++)
	{
		vec3 vPos = vRayOrigin + vRayDir * t1;
		i1 = GetSprayDistance(waterfall, vPos);
		if( i1.x < 0.01 )
		{
			break;
		}
		t1 = t1 + min(i1.x, 5.0); // min is a hacky fix for my bad quadratic distance function
		if( t1 > 1000.0)
		{
			return vec2(1.0, -1.0);
		}
	}

	
	float kMaxWaterfallDepth = 4.0;
	
	float t2 = t1 + kMaxWaterfallDepth;
	vec4 i2;
	
	for(int i=0; i<16; i++)
	{
		vec3 vPos = vRayOrigin + vRayDir * t2;
		i2 = GetWaterfallSprayDistance(waterfall, vPos);
		if( i2.x < 0.01 )
		{
			break;
		}
		t2 = t2 - i2.x;
		if( t2 < 0.0)
		{
			break;
		}
	}
	
	vUVW1 = i1.yzw;
	vUVW2 = i2.yzw;
	
	return vec2(t1, t2);
}

float noise(in float o) 
{
	float p = floor(o);
	float fr = fract(o);
		
	float n = p;

	float a = hash(n);
	float b = hash(n+  1.0);

	float fr2 = fr * fr;
	float fr3 = fr2 * fr;
	
	float t = 3.0 * fr2 - 2.0 * fr3;	

	return a * (1.0 - t) + b * t;
}

float noise(in vec3 o) 
{
	vec3 p = floor(o);
	vec3 fr = fract(o);
		
	float n = p.x + p.y*57.0 + p.z * 1009.0;

	float a = hash(n+  0.0);
	float b = hash(n+  1.0);
	float c = hash(n+ 57.0);
	float d = hash(n+ 58.0);
	
	float e = hash(n+  0.0 + 1009.0);
	float f = hash(n+  1.0 + 1009.0);
	float g = hash(n+ 57.0 + 1009.0);
	float h = hash(n+ 58.0 + 1009.0);
	
	
	vec3 fr2 = fr * fr;
	vec3 fr3 = fr2 * fr;
	
	vec3 t = 3.0 * fr2 - 2.0 * fr3;
	
	float u = t.x;
	float v = t.y;
	float w = t.z;

	// this last bit should be refactored to the same form as the rest :)
	float res1 = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
	float res2 = e + (f-e)*u +(g-e)*v + (e-f+h-g)*u*v;
	
	float res = res1 * (1.0- w) + res2 * (w);
	
	return res;
}


const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float SmoothNoise( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); //p = m*p*2.02;
    //f += 0.1250*noise( p );
	
    return f * (1.0 / (0.5000 + 0.2500));
}

float SmoothNoise( float p )
{
    float f;
    f  = 0.5000*noise( p ); p = p*2.02;
    f += 0.2500*noise( p ); p = p*2.03;
    f += 0.1250*noise( p ); 
	
    return f * (1.0 / (0.5000 + 0.2500 + 0.1250));
}


float GetWaterfallNoise( const vec3 vPos )
{
	float f = SmoothNoise( vPos * vec3(16.0, 2.0, 16.0) + vec3(0.0, mod(iGlobalTime * 20.0, 1000.0), 0.0) );
	return f * f;
}

vec4 ApplyWaterfall( const in vec3 vRayOrigin, const in vec3 vRayDir, const in vec4 vPrev )
{
	vec4 vResult = vPrev;
	// intersect entry + exit, get uvw in waterfall space and pos in world space, trace through noise
	
	vec3 vParam = vec3(0.0, 0.0, 10.0);
	vec3 vUVW0, vUVW1;
	
	S_Waterfall waterfall;	
	
	vec2 vIntT = TraceWaterfall( waterfall, vUVW0, vUVW1, vRayOrigin, vRayDir );
	
	if( vIntT.x >= vIntT.y )
	{
		return vPrev;
	}

	vec3 vPos0 = vRayOrigin + vRayDir * vIntT.x;
	vec3 vPos1 = vRayOrigin + vRayDir * vIntT.y;

	// trace noise	
	float fFraction = 0.0;
	const int kTraceIter = 12;	
	float fFractionDelta = 1.0 / float(kTraceIter);
	
	float fBlend = 0.5 * abs(vIntT.y - vIntT.x) / waterfall.fRadius;
	
	fFraction += fFractionDelta * gPixelRand; // randomize to hide shells
	for(int i=0; i<kTraceIter; i++)
	{
		float tCurr = mix( vIntT.y, vIntT.x, fFraction);
		if(tCurr < vPrev.w)
		{
			vec3 vPosCurr = mix(vPos1, vPos0, fFraction);
			vec3 vUVWCurr = mix( vUVW1, vUVW0, fFraction);
			float fNoise = GetWaterfallNoise(vUVWCurr);
			
			vec2 vClosest;
			vClosest.x = clamp(vUVWCurr.x, -waterfall.fWidth, waterfall.fWidth);
			vClosest.y = 0.0;

			float fFade = 0.0;
			
			const float fHack = 0.5; // a hacky fix for my bad quadratic distance function
			fFade += (length(vClosest - vUVWCurr.xz) / (waterfall.fRadius * fHack));
			fFade = fFade * fFade * fFade;
			fFade = fFade;
						
			// amount of spray based on x position along waterfall
			float n = SmoothNoise(vUVWCurr.x + waterfall.fNoiseOffset);
			fFade += n * n * n;			
			
			//fFade = 0.0;			
			fNoise = clamp(fNoise - fFade, 0.0, 1.0);

			float fShadeFactor = clamp(vUVWCurr.z / waterfall.fRadius, 0.0, 1.0);
			float fShade = 0.3 + sqrt(fShadeFactor) * 0.5;
			
			fShade *= fNoise * 0.5 + 0.5;
			
			const float kEpsilon = 0.01;
			float d1 = GetSprayDistance( waterfall, vPosCurr ).x;
			float d2 = GetSprayDistance( waterfall, vPosCurr + vSunDir * kEpsilon ).x;
			float fSunIntensity = clamp((d1 - d2) * (1.0 / kEpsilon) * 0.5 + 0.5, 0.0, 1.0);

			vec3 vCol =  (fSunIntensity * vSunColour * SunShadowClamped(vPosCurr) + fShade * vAmbientLight);

			vResult.xyz = mix(vResult.xyz, vCol, clamp(fNoise * fBlend, 0.0, 1.0));
			vResult.w = min(vResult.w, tCurr / (fNoise)); // hack depth to make fog work later?!
		}
		
		fFraction += fFractionDelta;
	}
	
	return vResult;
}

vec3 noise_dxy(in vec2 o) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	float a = hash(n+  0.0);
	float b = hash(n+  1.0);
	float c = hash(n+ 57.0);
	float d = hash(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	vec2 dt = 6.0 * f - 6.0 * f2;
	
	float u = t.x;
	float du = dt.x;	
	float v = t.y;
	float dv = dt.y;	

	float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
	
	float dx = (b-a)*du + (a-b+d-c)*du*v;
	float dy = (c-a)*dv + (a-b+d-c)*u*dv;
	
	return vec3(dx, dy, res);
}

vec3 fbm_dxy( vec2 p, vec2 d ) {
	vec3 f;
	p += d * 1.0;
	f  =      0.5000*noise_dxy( p );
	p = p * 2.0;
	p += d * 1.0;
	p += f.xy * 0.75;
	f +=      0.2500*noise_dxy( p);
	p = p * 2.0;
	p += d * 1.0;
	p += f.xy * 0.75;
	f +=      0.1250*noise_dxy( p );	
	return f * (1.0/(0.5000 + 0.2500 + 0.1250));
}

vec3 GetSpectrum( float x, const in vec3 vBrightness, const in vec3 vPeak, const in vec3 vRange )
{
	vec3 vTemp = 1.0 - abs((vPeak - x) * vRange);
	vTemp = clamp(vTemp, 0.0, 1.0);
	vec3 vTemp2 = vTemp  * vTemp;	
	return (3.0 * vTemp2 - 2.0 * vTemp * vTemp2) * vBrightness;	
}

vec4 GetRainbowRGBA( float theta )
{
	vec4 vResult = vec4(0.0);

	// red0 = 137.7 deg
	// violet0 = 139.6 deg
	// red1 = 129.5 deg
	// violet1 = 126.1 deg
	
	const vec3 vPeak0 = vec3(180.0 - 137.7, 180.0 - (137.7 + 139.6)*0.5, 180.0 - 139.6);
	const vec3 vRange0 = 1.0 / vec3(vPeak0.b - vPeak0.r);
	const vec3 vBrightness0 = vec3(1.0);

	vResult.xyz += GetSpectrum(theta, vBrightness0, vPeak0, vRange0);	

	const vec3 vPeak1 = vec3(180.0 - 129.5, 180.0 - (129.5 + 126.1) * 0.5, 180.0 - 126.1);
	const vec3 vRange1 = 1.0 / vec3(vPeak1.b - vPeak1.r);
	const vec3 vBrightness1 = vec3(0.25);
	
	vResult.xyz += GetSpectrum(theta, vBrightness1, vPeak1, vRange1);	
	
	float aFactor = max(smoothstep(vPeak0.r + 1.0, vPeak0.b - 1.0, theta), smoothstep(vPeak1.r - 1.0, vPeak1.b + 1.0, theta) * 0.2);
	vResult.a = 1.0 - aFactor;	
	
	return vResult;
}

vec4 ApplyAtmosphere( const in vec3 vRayOrigin, const in vec3 vRayDir, in vec4 vResult )
{
	vec3 vCentre = vec3(0.0, -5.0, 1.0);
	
	vec3 vOffset = vCentre - vRayOrigin;
	float d = dot(vRayDir, vOffset);
	vec3 vClosest = vRayOrigin + vRayDir * d;
	float l = length(vClosest - vCentre);
	
	// fog
	vec3 cFogColour = vAmbientLight;
	vResult.xyz = mix(vResult.xyz, cFogColour, 1.0 - exp2(vResult.w * -0.001));
	
	// mist and rainbows
	float r = 12.0;
	if( l < r )
	{
		
		float hcl = sqrt(r * r - l * l);
		
		float t0 = d - hcl;
		
		float dt = vResult.w - t0;
		float fAmount = 0.0;
		if(dt > 0.0)
		{
			float f = (r - l)/r;
			f = f * f * f;
			float fOpticalDepth = dt * f * 0.1;
			float fAmount = 1.0 - exp2(-fOpticalDepth);
			
			vec3 cMistColour = vAmbientLight * 0.7 + length(vAmbientLight) * vec3(0.3);
			float fYPos = vRayOrigin.y + vRayDir.y * vResult.w;
			//cMistColour *= clamp((fYPos + 2.5) * 0.25, 0.0, 1.0) * 0.5 + 0.5;
			vResult.xyz = mix(vResult.xyz, cMistColour, fAmount);
			
			float fCameraShadow = RainbowShadow(vRayOrigin) * 0.75 + 0.25;
			
			float fRainbowAmount = clamp(fAmount * fCameraShadow * 1.0, 0.0, 1.0);
			float fRainbowDarkenAmount = clamp(fAmount * fCameraShadow * 1.5, 0.0, 1.0);
			
			float fDp = dot(vSunDir, vRayDir);
			vec4 vRainbow = GetRainbowRGBA(degrees(acos(fDp)) + 0.5);
			vResult.xyz *= 1.0 - vRainbow.a * fRainbowDarkenAmount;
			vResult.xyz += vRainbow.xyz * fRainbowAmount;
			
		}
	}			

	return vResult;	
}

vec3 GetSceneColour( const in vec3 vRayOrigin,  const in vec3 vRayDir )
{
	float fWaterT = TraceWater( vRayOrigin, vRayDir );
	
	vec4 vResult = TraceScene( vRayOrigin, vRayDir );
	float fOriginalT = vResult.w;

#ifdef ENABLE_WATER_PLANE	
	float fSplashMin = -3.0;
	float fSplashMax =  3.0;
	float fSplashZ = -0.5;
	
	if(fWaterT < vResult.w)	
	{
		vec3 vWaterPos = vRayOrigin + vRayDir * fWaterT;
		vec2 vWaterUV = vWaterPos.xz;		
		
		float fNormalStrength = 0.0;
		vec2 vDistortPos = vec2(clamp(vWaterPos.x, fSplashMin, fSplashMax), fSplashZ);
		vec2 vDelta = vWaterUV - vDistortPos;
		float fLen = length(vDelta);
		vec2 vNorm = normalize(vDelta);
		fLen = fLen / 4.0;
		if(fLen < 1.0)
		{
			fNormalStrength = 1.0 - fLen;
			float fBlend = fNormalStrength * fNormalStrength;
			fLen = mix(fLen, fLen * 3.0, fBlend);
		}
		fLen = fLen * 4.0;		
		vWaterUV = vDistortPos + vNorm * fLen;
		
		vWaterUV *= 3.0;
		vec2 vWaterSpeed = vec2(0.0, iGlobalTime) * 4.0;
		vec3 vWaterFBM = fbm_dxy(vWaterUV, vWaterSpeed);

		vec3 vWaterNormal = vec3(0.0, 0.25 + (1.0 - fNormalStrength) * 3.0, 0.0);
		vWaterNormal.xz += vWaterFBM.yz;		
		vWaterNormal = normalize(vWaterNormal);
				
		#ifdef ENABLE_WATER_REFLECTIONS
		vec3 vReflectDir = reflect(vRayDir, vWaterNormal);
		#ifdef ENABLE_SCENERY_REFLECTION
		vec4 vReflectResult = TraceScene( vWaterPos, vReflectDir );
		#else
		vec4 vReflectResult = vec4(0.1, 0.1, 0.05, kFarClip);
		#endif
		
		#ifdef ENABLE_WATERFALL_REFLECTION
		vReflectResult = ApplyWaterfall( vWaterPos, vReflectDir, vReflectResult );
		#endif // ENABLE_WATERFALL_REFLECTION
		
		// Apply water
		vec3 vHalfVec = normalize(vReflectDir + -vRayDir);
		float fFresnelDot = 1.0 - clamp(dot(vHalfVec, -vRayDir), 0.0, 1.0);	
		float fFresnel = pow(fFresnelDot, 5.0);
		fFresnel = mix(0.02, 1.0, fFresnel);
		#endif
		// Water extinction
		vResult.xyz *= exp( (fOriginalT - fWaterT) * -vWaterExtinction);
		
		#ifdef ENABLE_WATER_REFLECTIONS
		vResult.xyz = mix(vResult.xyz, vReflectResult.xyz, fFresnel);
		#endif
		
		float fFoam = sqrt(1.0 - vWaterFBM.z);
		vec2 vFoamSplashClosest = vec2(clamp(vWaterPos.x, fSplashMin, fSplashMax), fSplashZ);
		float fFoamSplashFade = clamp(length(vFoamSplashClosest - vWaterPos.xz) * 0.2, 0.0, 1.0);

		float fWaterToSceneryDist = GetSceneDistance(vWaterPos);
		fFoam -= min(clamp(fWaterToSceneryDist * .5, 0.0, 1.0), fFoamSplashFade);
		
		fFoam *= clamp(fWaterToSceneryDist * (1.0 / 0.4), 0.0, 1.0); // softer edges
		
		fFoam = clamp(fFoam, 0.0, 1.0);

		//fFoam = Checker(vWaterUV * 0.25);
		
		vec3 vFoamCol = vec3(0.5, 0.45, 0.4);
		float fSunIntensity = clamp( dot(vWaterNormal, -vSunDir), 0.0, 1.0);
		float fAmbientIntensity = clamp(fWaterToSceneryDist + 0.25, 0.0, 1.0);
		vFoamCol *= (vSunColour * SunShadowClamped(vWaterPos) * fSunIntensity + vAmbientLight * fAmbientIntensity);
		
		vResult.xyz = mix(vResult.xyz, vFoamCol, fFoam); // foam
		vResult.w = min(vResult.w, fWaterT);
	}
#endif // ENABLE_WATER_PLANE	
	
#ifdef ENABLE_WATERFALL
	vResult = ApplyWaterfall( vRayOrigin, vRayDir, vResult );
#endif // ENABLE_WATERFALL

#ifdef ENABLE_ATMOSPHERE	
	vResult = ApplyAtmosphere( vRayOrigin, vRayDir, vResult );
#endif // ENABLE_ATMOSPHERE
	
	return vResult.xyz;
}

void CommonInit( in vec2 fragCoord )
{
	gPixelRand = hash(fract(iGlobalTime) + fragCoord.x + fragCoord.y * 1009.0);
	
	// setup positions
	vec3 vDir = normalize(vec3(0.0, 0.0, -1.0));
	const vec3 vUp = vec3(0.0, 1.0, 0.0);	
	vec3 vPerp = cross(vDir, vUp);
	
	g_Waterfall[0].mRot = mat3( vPerp, vUp, vDir );	
	g_Waterfall[0].vTrans = vec3(0.0, 10.5, 8.0);	
	g_Waterfall[0].fWidth = 4.0;
	g_Waterfall[0].fHeight = 14.0;
	g_Waterfall[0].fRadius = 1.0;
	g_Waterfall[0].fQuadraticA = -0.2;
	g_Waterfall[0].fQuadraticB = -0.1;
	g_Waterfall[0].fZMax = SolveQuadratic(g_Waterfall[0].fQuadraticA, g_Waterfall[0].fQuadraticB, g_Waterfall[0].fHeight);
	g_Waterfall[0].fNoiseOffset = 37.6;
	
#ifdef MORE_WATERFALLS
	float fAngle2 = 2.0;
	vec3 vDir2 = normalize(vec3(sin(fAngle2), 0.0, cos(fAngle2)));	
	vec3 vPerp2 = cross(vDir2, vUp);

	g_Waterfall[1].mRot = mat3( vPerp2, vUp, vDir2 );	
	g_Waterfall[1].vTrans = vec3(-18.0, 10.0, -5.0);	
	g_Waterfall[1].fWidth = 0.5;
	g_Waterfall[1].fHeight = 15.0;
	g_Waterfall[1].fRadius = 0.75;
	g_Waterfall[1].fQuadraticA = -0.2;
	g_Waterfall[1].fQuadraticB = -0.1;
	g_Waterfall[1].fZMax = SolveQuadratic(g_Waterfall[1].fQuadraticA, g_Waterfall[1].fQuadraticB, g_Waterfall[1].fHeight);
	g_Waterfall[1].fNoiseOffset = 1.0;

#endif		    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
    
    CommonInit( fragCoord );
	
#ifdef MOUSE
	vec2 vMouse = iMouse.xy / iResolution.xy;

	if(iMouse.x <= 0.0)
	{
		vMouse = vec2(0.85, 0.3); 
	}
#else
   vec2 vMouse = 0.0 / iResolution.xy;
   vMouse = vec2(0.85, 0.3); 
#endif
	
	//float fExposure = 3.0;
	float fFov = 0.5;
	float fExposure = clamp(iGlobalTime * 0.5, 0.0, 5.0);
	vec3 vCameraPos = vec3(vMouse.x * 30.0 - 15.0, 5.0 * (1.0 - vMouse.y), -27.0 + vMouse.y * 30.0);
	vec3 vCameraTarget = vec3(-2.0, 1.5, -1.0);
	
	vec3 vRayOrigin = vCameraPos;
	vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV), vRayOrigin, vCameraTarget, fFov );
	vec3 vResult = GetSceneColour(vRayOrigin, vRayDir);
	vResult = ApplyVignetting( vUV, vResult );	
	vResult = ApplyTonemap(vResult * fExposure);
	
	fragColor = vec4(vResult, 1.0);
}


void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    CommonInit( fragCoord );
    
    fragRayOri *= 2.0;
    
    fragRayOri.z *= -1.0;
    fragRayDir.z *= -1.0;
    
    fragRayOri.z -= 11.0;
    fragRayOri.x -= 0.5;
    fragRayOri.y += 0.5;
    
	vec3 vResult = GetSceneColour(fragRayOri, fragRayDir);

	float fExposure = clamp(iGlobalTime * 0.5, 0.0, 5.0);
    vResult = ApplyTonemap(vResult * fExposure);
	
	fragColor = vec4(vResult, 1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
