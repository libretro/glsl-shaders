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

// Where the River Goes
// @P_Malin

// What started as a hacked flow and advection experiment turned into something nice.

// Placeholder audio https://www.youtube.com/watch?v=gmar4gh5nIw suggested by @qthund on twitter

#define ENABLE_WATER
#define ENABLE_FOAM
#define ENABLE_WATER_RECEIVE_SHADOW
#define ENABLE_CONE_STEPPING


// Textureless version
#define ENABLE_NIMITZ_TRIANGLE_NOISE

//#define ENABLE_LANDSCAPE_RECEIVE_SHADOW

const float k_screenshotTime = 13.0;

#define ENABLE_SUPERSAMPLE_MODE

const int k_raymarchSteps = 96;
const int k_fmbSteps = 6;
const int k_superSampleCount = 6;

const int k_fmbWaterSteps = 4;

#define OBJ_ID_SKY 0.0
#define OBJ_ID_GROUND 1.0

float g_fTime;

const vec3 g_vSunDir = vec3( -1.0, 0.7, 0.25 );
vec3 GetSunDir() { return normalize( g_vSunDir ); }

const vec3 g_sunColour = vec3( 1.0, 0.85, 0.5 ) * 5.0;
const vec3 g_skyColour = vec3( 0.1, 0.5, 1.0 ) * 1.0;

const vec3 k_bgSkyColourUp = g_skyColour * 4.0;
const vec3 k_bgSkyColourDown = g_skyColour * 6.0;

const vec3 k_envFloorColor = vec3(0.3, 0.2, 0.2);

const vec3 k_vFogExt = vec3(0.01, 0.015, 0.015) * 3.0;
const vec3 k_vFogIn = vec3(1.0, 0.9, 0.8) * 0.015;


const float k_fFarClip = 20.0;

#define MOD2 vec2(4.438975,3.972973)

float Hash( float p ) 
{
    // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);    
	//return fract(sin(n)*43758.5453);
}

float SmoothNoise(in vec2 o) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	float a = Hash(n+  0.0);
	float b = Hash(n+  1.0);
	float c = Hash(n+ 57.0);
	float d = Hash(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	
	float u = t.x;
	float v = t.y;

	float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
    return res;
}

float FBM( vec2 p, float ps ) {
	float f = 0.0;
    float tot = 0.0;
    float a = 1.0;
    for( int i=0; i<k_fmbSteps; i++)
    {
        f += SmoothNoise( p ) * a;
        p *= 2.0;
        tot += a;
        a *= ps;
    }
    return f / tot;
}

float FBM_Simple( vec2 p, float ps ) {
	float f = 0.0;
    float tot = 0.0;
    float a = 1.0;
    for( int i=0; i<3; i++)
    {
        f += SmoothNoise( p ) * a;
        p *= 2.0;
        tot += a;
        a *= ps;
    }
    return f / tot;
}

vec3 SmoothNoise_DXY(in vec2 o) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	float a = Hash(n+  0.0);
	float b = Hash(n+  1.0);
	float c = Hash(n+ 57.0);
	float d = Hash(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	vec2 dt = 6.0 * f - 6.0 * f2;
	
	float u = t.x;
	float v = t.y;
	float du = dt.x;	
	float dv = dt.y;	

	float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
	float dx = (b-a)*du + (a-b+d-c)*du*v;
	float dy = (c-a)*dv + (a-b+d-c)*u*dv;    
    
    return vec3(dx, dy, res);
}

vec3 FBM_DXY( vec2 p, vec2 flow, float ps, float df ) {
	vec3 f = vec3(0.0);
    float tot = 0.0;
    float a = 1.0;
    //flow *= 0.6;
    for( int i=0; i<k_fmbWaterSteps; i++)
    {
        p += flow;
        flow *= -0.75; // modify flow for each octave - negating this is fun
        vec3 v = SmoothNoise_DXY( p );
        f += v * a;
        p += v.xy * df;
        p *= 2.0;
        tot += a;
        a *= ps;
    }
    return f / tot;
}

float GetRiverMeander( const float x )
{
    return sin(x * 0.3) * 1.5;
}

float GetRiverMeanderDx( const float x )
{
    return cos(x * 0.3) * 1.5 * 0.3;
}

float GetRiverBedOffset( const vec3 vPos )
{
    float fRiverBedDepth = 0.3 + (0.5 + 0.5 * sin( vPos.x * 0.001 + 3.0)) * 0.4;
    float fRiverBedWidth = 2.0 + cos( vPos.x * 0.1 ) * 1.0;;
    
    float fRiverBedAmount = smoothstep( fRiverBedWidth, fRiverBedWidth * 0.5, abs(vPos.z - GetRiverMeander(vPos.x)) );
        
    return fRiverBedAmount * fRiverBedDepth;    
}

float GetTerrainHeight( const vec3 vPos )
{    
    float fbm = FBM( vPos.xz * vec2(0.5, 1.0), 0.5 );
    float fTerrainHeight = fbm * fbm;
    
    fTerrainHeight -= GetRiverBedOffset(vPos);
        
    return fTerrainHeight;
}

float GetTerrainHeightSimple( const vec3 vPos )
{    
    float fbm = FBM_Simple( vPos.xz * vec2(0.5, 1.0), 0.5 );
    float fTerrainHeight = fbm * fbm;
    
    fTerrainHeight -= GetRiverBedOffset(vPos);
        
    return fTerrainHeight;
}


float GetSceneDistance( const vec3 vPos )
{
    return vPos.y - GetTerrainHeight( vPos );
}

float GetFlowDistance( const vec2 vPos )
{
    return -GetTerrainHeightSimple( vec3( vPos.x, 0.0, vPos.y ) );
}

vec2 GetBaseFlow( const vec2 vPos )
{
    return vec2( 1.0, GetRiverMeanderDx(vPos.x) );
}

vec2 GetGradient( const vec2 vPos )
{
    vec2 vDelta = vec2(0.01, 0.00);
    float dx = GetFlowDistance( vPos + vDelta.xy ) - GetFlowDistance( vPos - vDelta.xy );
    float dy = GetFlowDistance( vPos + vDelta.yx ) - GetFlowDistance( vPos - vDelta.yx );
    return vec2( dx, dy );
}

vec3 GetFlowRate( const vec2 vPos )
{
    vec2 vBaseFlow = GetBaseFlow( vPos );

    vec2 vFlow = vBaseFlow;
    
    float fFoam = 0.0;

	float fDepth = -GetTerrainHeightSimple( vec3(vPos.x, 0.0, vPos.y) );
    float fDist = GetFlowDistance( vPos );
    vec2 vGradient = GetGradient( vPos );
    
    vFlow += -vGradient * 40.0 / (1.0 + fDist * 1.5);
    vFlow *= 1.0 / (1.0 + fDist * 0.5);

#if 1
    float fBehindObstacle = 0.5 - dot( normalize(vGradient), -normalize(vFlow)) * 0.5;
    float fSlowDist = clamp( fDepth * 5.0, 0.0, 1.0);
    fSlowDist = mix(fSlowDist * 0.9 + 0.1, 1.0, fBehindObstacle * 0.9);
    //vFlow += vGradient * 10.0 * (1.0 - fSlowDist);
    fSlowDist = 0.5 + fSlowDist * 0.5;
    vFlow *= fSlowDist;
#endif    
    
    float fFoamScale1 =0.5;
    float fFoamCutoff = 0.4;
    float fFoamScale2 = 0.35;
    
    fFoam = abs(length( vFlow )) * fFoamScale1;// - length( vBaseFlow ));
	fFoam += clamp( fFoam - fFoamCutoff, 0.0, 1.0 );
    //fFoam = fFoam* fFoam;
    fFoam = 1.0 - pow( fDist, fFoam * fFoamScale2 );
    //fFoam = fFoam / fDist;
    return vec3( vFlow * 0.6, fFoam  );
}

vec4 SampleWaterNormal( vec2 vUV, vec2 vFlowOffset, float fMag, float fFoam )
{    
    vec2 vFilterWidth = max(abs(dFdx(vUV)), abs(dFdy(vUV)));
  	float fFilterWidth= max(vFilterWidth.x, vFilterWidth.y);
    
    float fScale = (1.0 / (1.0 + fFilterWidth * fFilterWidth * 2000.0));
    float fGradientAscent = 0.25 + (fFoam * -1.5);
    vec3 dxy = FBM_DXY(vUV * 20.0, vFlowOffset * 20.0, 0.75 + fFoam * 0.25, fGradientAscent);
    fScale *= max(0.25, 1.0 - fFoam * 5.0); // flatten normal in foam
    vec3 vBlended = mix( vec3(0.0, 1.0, 0.0), normalize( vec3(dxy.x, fMag, dxy.y) ), fScale );
    return vec4( normalize( vBlended ), dxy.z * fScale );
}

float SampleWaterFoam( vec2 vUV, vec2 vFlowOffset, float fFoam )
{
    float f =  FBM_DXY(vUV * 30.0, vFlowOffset * 50.0, 0.8, -0.5 ).z;
    float fAmount = 0.2;
    f = max( 0.0, (f - fAmount) / fAmount );
    return pow( 0.5, f );
}
    

vec4 SampleFlowingNormal( const vec2 vUV, const vec2 vFlowRate, const float fFoam, const float time, out float fOutFoamTex )
{
    float fMag = 2.5 / (1.0 + dot( vFlowRate, vFlowRate ) * 5.0);
    float t0 = fract( time );
    float t1 = fract( time + 0.5 );
    
    float o0 = t0 - 0.5;
    float o1 = t1 - 0.5;
    
    vec4 sample0 = SampleWaterNormal( vUV, vFlowRate * o0, fMag, fFoam );
    vec4 sample1 = SampleWaterNormal( vUV, vFlowRate * o1, fMag, fFoam );

    float weight = abs( t0 - 0.5 ) * 2.0;
    //weight = smoothstep( 0.0, 1.0, weight );

    float foam0 = SampleWaterFoam( vUV, vFlowRate * o0 * 0.25, fFoam );
    float foam1 = SampleWaterFoam( vUV, vFlowRate * o1 * 0.25, fFoam );
    
    vec4 result=  mix( sample0, sample1, weight );
    result.xyz = normalize(result.xyz);

    fOutFoamTex = mix( foam0, foam1, weight );

    return result;
}

vec2 GetWindowCoord( const in vec2 vUV )
{
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= iResolution.x / iResolution.y;

	return vWindow;	
}

vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget )
{
	vec3 vForward = normalize(vCameraTarget - vCameraPos);
	vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
	vec3 vUp = normalize(cross(vForward, vRight));
							  
	vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * 2.0);

	return vDir;
}

vec3 ApplyVignetting( const in vec2 vUV, const in vec3 vInput )
{
	vec2 vOffset = (vUV - 0.5) * sqrt(2.0);
	
	float fDist = dot(vOffset, vOffset);
	
	const float kStrength = 0.8;
	
	float fShade = mix( 1.0, 1.0 - kStrength, fDist );	

	return vInput * fShade;
}

vec3 Tonemap( vec3 x )
{
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}

struct Intersection
{
    float m_dist;
    float m_objId;
    vec3 m_pos;
};
    
void RaymarchScene( vec3 vRayOrigin, vec3 vRayDir, out Intersection intersection )
{
    float stepScale = 1.0;
#ifdef ENABLE_CONE_STEPPING
    vec2 vRayProfile = vec2( sqrt(dot(vRayDir.xz, vRayDir.xz) ), vRayDir.y );
    vec2 vGradVec = normalize( vec2( 1.0, 2.0 ) ); // represents the biggest gradient in our heightfield
    vec2 vGradPerp = vec2( vGradVec.y, -vGradVec.x );

    float fRdotG = dot( vRayProfile, vGradPerp );
    float fOdotG = dot( vec2(0.0, 1.0), vGradPerp );

    stepScale = -fOdotG / fRdotG;

    if ( stepScale < 0.0 )
    {
        intersection.m_objId = OBJ_ID_SKY;
        intersection.m_dist = k_fFarClip;
        return;
    }
#endif
    
    intersection.m_dist = 0.01;
    intersection.m_objId = OBJ_ID_SKY;
    
    float fSceneDist = 0.0;
    
    float oldT = 0.01;
    for( int iter = 0; iter < k_raymarchSteps; iter++ )
    {
        vec3 vPos = vRayOrigin + vRayDir * intersection.m_dist;
      
        // into sky - early out
        if ( vRayDir.y > 0.0 )
        {
            if( vPos.y > 1.0 )
            {
                intersection.m_objId = OBJ_ID_SKY;
                intersection.m_dist = k_fFarClip;
                break;
            }
        }

      
        fSceneDist = GetSceneDistance( vPos );

        oldT = intersection.m_dist;
        intersection.m_dist += fSceneDist * stepScale;
                
        intersection.m_objId = OBJ_ID_GROUND;
        if ( fSceneDist <= 0.01 )
        {
            break;
        }

        if ( intersection.m_dist > k_fFarClip )
        {
            intersection.m_objId = OBJ_ID_SKY;
            intersection.m_dist = k_fFarClip;
            break;
        }        

        
    }    
    
    intersection.m_pos = vRayOrigin + vRayDir * intersection.m_dist;
}

vec3 GetSceneNormal(const in vec3 vPos)
{
    const float fDelta = 0.001;

    vec3 vDir1 = vec3( 1.0, 0.0, -1.0);
    vec3 vDir2 = vec3(-1.0, 0.0,  1.0);
    vec3 vDir3 = vec3(-1.0, 0.0, -1.0);
	
    vec3 vOffset1 = vDir1 * fDelta;
    vec3 vOffset2 = vDir2 * fDelta;
    vec3 vOffset3 = vDir3 * fDelta;

    vec3 vPos1 = vPos + vOffset1;
    vec3 vPos2 = vPos + vOffset2;
    vec3 vPos3 = vPos + vOffset3;
 
    float f1 = GetSceneDistance( vPos1 );
    float f2 = GetSceneDistance( vPos2 );
    float f3 = GetSceneDistance( vPos3 );
    
    vPos1.y -= f1;
    vPos2.y -= f2;
    vPos3.y -= f3;
    
    vec3 vNormal = cross( vPos1 - vPos2, vPos3 - vPos2 );
    
    return normalize( vNormal );
}


void TraceWater( vec3 vRayOrigin, vec3 vRayDir, out Intersection intersection )
{
 	intersection.m_dist = k_fFarClip;
    
    float t = -vRayOrigin.y / vRayDir.y;
    if ( t > 0.0 )
    {
        intersection.m_dist = t;
    }
    
    intersection.m_pos = vRayOrigin + vRayDir * intersection.m_dist;
}

struct Surface
{
    vec3 m_pos;
    vec3 m_normal;
    vec3 m_albedo;
    vec3 m_specR0;
    float m_gloss;
    float m_specScale;
};
    
#ifdef ENABLE_NIMITZ_TRIANGLE_NOISE
// https://www.shadertoy.com/view/4ts3z2

float tri(in float x){return abs(fract(x)-.5);}
vec3 tri3(in vec3 p){return vec3( tri(p.z+tri(p.y)), tri(p.z+tri(p.x)), tri(p.y+tri(p.x)));}

float triNoise(in vec3 p)
{
    float z=1.4;
	float rz = 0.;
    vec3 bp = p;
	for (float i=0.; i<=4.; i++ )
	{
        vec3 dg = tri3(bp*2.);
        p += dg;

        bp *= 1.8;
		z *= 1.5;
		p *= 1.2;
           
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
	}
	return rz;
}    
#endif
    
void GetSurfaceInfo( Intersection intersection, out Surface surface )
{
    surface.m_pos = intersection.m_pos;
    surface.m_normal = GetSceneNormal(intersection.m_pos);

#ifdef ENABLE_NIMITZ_TRIANGLE_NOISE
    vec3 vNoisePos = surface.m_pos * vec3(0.4, 0.3, 1.0);
	surface.m_normal = normalize(surface.m_normal +triNoise(vNoisePos));
    float fNoise = triNoise(vNoisePos);
    fNoise = pow( fNoise, 0.15);
    surface.m_albedo = mix(vec3(.7,.8,.95), vec3(.1, .1,.05), fNoise );    
#else
    #if 0
    surface.m_albedo = texture( iChannel0, intersection.m_pos.xz ).rgb;
    surface.m_albedo = surface.m_albedo * surface.m_albedo;
    #else
    vec3 vWeights = surface.m_normal * surface.m_normal;
    vec3 col = vec3(0.0);
    vec3 _sample;
    _sample = texture( iChannel0, intersection.m_pos.xz ).rgb;
    col += _sample * _sample * vWeights.y;
    _sample = texture( iChannel0, intersection.m_pos.xy ).rgb;
    col += _sample * _sample * vWeights.z;
    _sample = texture( iChannel0, intersection.m_pos.yz ).rgb;
    col += _sample * _sample * vWeights.x;
    col /= vWeights.x + vWeights.y + vWeights.z;
    surface.m_albedo = col;
    #endif
#endif    
    
    surface.m_specR0 = vec3(0.001);
    surface.m_gloss = 0.0;
    surface.m_specScale = 1.0;
}
   
float GIV( float dotNV, float k)
{
	return 1.0 / ((dotNV + 0.0001) * (1.0 - k)+k);
}

float GetSunShadow( const vec3 vPos )
{
    vec3 vSunDir = GetSunDir();

    Intersection shadowInt;
    float k_fShadowDist = 2.0;
    RaymarchScene( vPos + vSunDir * k_fShadowDist, -vSunDir, shadowInt );
    
    float fShadowFactor = 1.0;
    if( shadowInt.m_dist < (k_fShadowDist - 0.1) )
    {
        fShadowFactor = 0.0;
    }

    return fShadowFactor;
}

void AddSunLight( Surface surf, const vec3 vViewDir, const float fShadowFactor, inout vec3 vDiffuse, inout vec3 vSpecular )
{
    vec3 vSunDir = GetSunDir();

	vec3 vH = normalize( vViewDir + vSunDir );
	float fNdotL = clamp(dot(GetSunDir(), surf.m_normal), 0.0, 1.0);
	float fNdotV = clamp(dot(vViewDir, surf.m_normal), 0.0, 1.0);
	float fNdotH = clamp(dot(surf.m_normal, vH), 0.0, 1.0);
    
    float diffuseIntensity = fNdotL;
    
    vDiffuse += g_sunColour * diffuseIntensity * fShadowFactor;
	//vDiffuse = fShadowFactor * vec3(100.0);
	
	float alpha = 1.0 - surf.m_gloss;
	// D

	float alphaSqr = alpha * alpha;
	float pi = 3.14159;
	float denom = fNdotH * fNdotH * (alphaSqr - 1.0) + 1.0;
	float d = alphaSqr / (pi * denom * denom);

	float k = alpha / 2.0;
	float vis = GIV(fNdotL, k) * GIV(fNdotV, k);

	float fSpecularIntensity = d * vis * fNdotL;
	vSpecular += g_sunColour * fSpecularIntensity * fShadowFactor;
}
    
void AddSkyLight( Surface surf, inout vec3 vDiffuse, inout vec3 vSpecular )
{
    float skyIntensity = max( 0.0, surf.m_normal.y * 0.3 + 0.7 );
    vDiffuse += g_skyColour * skyIntensity;       
}

vec3 GetFresnel( vec3 vView, vec3 vNormal, vec3 vR0, float fGloss )
{
    float NdotV = max( 0.0, dot( vView, vNormal ) );

    return vR0 + (vec3(1.0) - vR0) * pow( 1.0 - NdotV, 5.0 ) * pow( fGloss, 20.0 );
}

vec3 GetWaterExtinction( float dist )
{
    float fOpticalDepth = dist * 6.0;

    vec3 vExtinctCol = 1.0 - vec3(0.5, 0.4, 0.1);           
    vec3 vExtinction = exp2( -fOpticalDepth * vExtinctCol );
    
    return vExtinction;
}

vec3 GetSkyColour( vec3 vRayDir )
{    
	vec3 vSkyColour = mix( k_bgSkyColourDown, k_bgSkyColourUp, clamp( vRayDir.y, 0.0, 1.0 ) );
    float fSunDotV = dot(GetSunDir(), vRayDir);    
    float fDirDot = clamp(fSunDotV * 0.5 + 0.5, 0.0, 1.0);
    vSkyColour += g_sunColour * (1.0 - exp2(fDirDot * -0.5)) * 2.0;
    
    return vSkyColour;
}

vec3 GetEnvColour( vec3 vRayDir, float fGloss )
{
	return mix( k_envFloorColor, k_bgSkyColourUp, clamp( vRayDir.y * (1.0 - fGloss * 0.5) * 0.5 + 0.5, 0.0, 1.0 ) );
}


vec3 GetRayColour( const in vec3 vRayOrigin, const in vec3 vRayDir, out Intersection intersection )
{
    RaymarchScene( vRayOrigin, vRayDir, intersection );        

    if ( intersection.m_objId == OBJ_ID_SKY )
    {
        return GetSkyColour( vRayDir );
    }
    
    Surface surface;
    GetSurfaceInfo( intersection, surface );

    vec3 vIgnore = vec3(0.0);
    vec3 vResult = vec3(0.0);
    float fSunShadow = 1.0;
    AddSunLight( surface, -vRayDir, fSunShadow, vResult, vIgnore );
    AddSkyLight( surface, vResult, vIgnore);
    return vResult * surface.m_albedo;
}

vec3 GetRayColour( const in vec3 vRayOrigin, const in vec3 vRayDir )
{
	Intersection intersection;
    return GetRayColour( vRayOrigin, vRayDir, intersection );
}

vec3 GetSceneColour( const in vec3 vRayOrigin,  const in vec3 vRayDir )
{
	Intersection primaryInt;
    RaymarchScene( vRayOrigin, vRayDir, primaryInt );

     float fFogDistance = 0.0;
    vec3 vResult = vec3( 0.0 );
    
    float fSunDotV = dot(GetSunDir(), vRayDir);    

    if ( primaryInt.m_objId == OBJ_ID_SKY )
    {
        vResult = GetSkyColour( vRayDir );
        fFogDistance = k_fFarClip;
    }
    else
    {
        Intersection waterInt;
        TraceWater( vRayOrigin, vRayDir, waterInt );

        vec3 vReflectRayOrigin;
        vec3 vSpecNormal;
        vec3 vTransmitLight;

        Surface specSurface;
        vec3 vSpecularLight = vec3(0.0);

    #ifdef ENABLE_WATER
        vec3 vFlowRateAndFoam = GetFlowRate( waterInt.m_pos.xz );
        vec2 vFlowRate = vFlowRateAndFoam.xy;
        #ifdef ENABLE_FOAM
        float fFoam = vFlowRateAndFoam.z;
        float fFoamScale = 1.5;
        float fFoamOffset = 0.2;
        fFoam = clamp( (fFoam - fFoamOffset) * fFoamScale, 0.0, 1.0 );
        fFoam = fFoam * fFoam * 0.5;
        #else
        float fFoam = 0.0;
        #endif            

        float fWaterFoamTex = 1.0;
        vec4 vWaterNormalAndHeight = SampleFlowingNormal( waterInt.m_pos.xz, vFlowRate, fFoam, g_fTime, fWaterFoamTex );
        
        if( vRayDir.y < -0.01 )
        {
            // lie about the water intersection depth
            waterInt.m_dist -= (0.04 * (1.0 - vWaterNormalAndHeight.w) / vRayDir.y);
        }
        
        if( waterInt.m_dist < primaryInt.m_dist )
        {
            fFogDistance = waterInt.m_dist;
            vec3 vWaterNormal = vWaterNormalAndHeight.xyz;

            vReflectRayOrigin = waterInt.m_pos;
            vSpecNormal = vWaterNormal;

            vec3 vRefractRayOrigin = waterInt.m_pos;
            vec3 vRefractRayDir = refract( vRayDir, vWaterNormal, 1.0 / 1.3333 );

            Intersection refractInt;
            vec3 vRefractLight = GetRayColour( vRefractRayOrigin, vRefractRayDir, refractInt ); // note : dont need sky

            float fEdgeAlpha = clamp( (1.0 + vWaterNormalAndHeight.w * 0.25) - refractInt.m_dist * 10.0, 0.0, 1.0 );
            fFoam *= 1.0 - fEdgeAlpha;
            
            // add extra extinction for the light travelling to the point underwater
            vec3 vExtinction = GetWaterExtinction( refractInt.m_dist + abs( refractInt.m_pos.y ) );

            specSurface.m_pos = waterInt.m_pos;
            specSurface.m_normal = normalize( vWaterNormal + GetSunDir() * fFoam ); // would rather have SSS for foam
            specSurface.m_albedo = vec3(1.0);
            specSurface.m_specR0 = vec3( 0.01, 0.01, 0.01 );

            vec2 vFilterWidth = max(abs(dFdx(waterInt.m_pos.xz)), abs(dFdy(waterInt.m_pos.xz)));
  			float fFilterWidth= max(vFilterWidth.x, vFilterWidth.y);
            float fGlossFactor = exp2( -fFilterWidth * 0.3 );
            specSurface.m_gloss = 0.99 * fGlossFactor;            
            specSurface.m_specScale = 1.0;
            
            vec3 vSurfaceDiffuse = vec3(0.0);

            float fSunShadow = 1.0;
        #ifdef ENABLE_WATER_RECEIVE_SHADOW
            fSunShadow = GetSunShadow( waterInt.m_pos );
        #endif
            AddSunLight( specSurface, -vRayDir, fSunShadow, vSurfaceDiffuse, vSpecularLight);
            AddSkyLight( specSurface, vSurfaceDiffuse, vSpecularLight);

            vec3 vInscatter = vSurfaceDiffuse * (1.0 - exp( -refractInt.m_dist * 0.1 )) * (1.0 + fSunDotV);
            vTransmitLight = vRefractLight.rgb;
            vTransmitLight += vInscatter;
            vTransmitLight *= vExtinction;   


    #ifdef ENABLE_FOAM
            float fFoamBlend = 1.0 - pow( fWaterFoamTex, fFoam * 5.0);// * (1.0 - fWaterFoamTex));
            vTransmitLight = mix(vTransmitLight, vSurfaceDiffuse * 0.8, fFoamBlend );
            specSurface.m_specScale = clamp(1.0 - fFoamBlend * 4.0, 0.0, 1.0);
    #endif
        }
        else
    #endif // #ifdef ENABLE_WATER
        {
            fFogDistance = primaryInt.m_dist;

            Surface primarySurface;
            GetSurfaceInfo( primaryInt, primarySurface );

            vSpecNormal = primarySurface.m_normal;
            vReflectRayOrigin = primaryInt.m_pos;
            
            float fWetness = 1.0 - clamp( (vReflectRayOrigin.y + 0.025) * 5.0, 0.0, 1.0);
            primarySurface.m_gloss = mix( primarySurface.m_albedo.r, 1.0, fWetness );
            primarySurface.m_albedo = mix( primarySurface.m_albedo, primarySurface.m_albedo * 0.8, fWetness );

            vTransmitLight = vec3(0.0);
            float fSunShadow = 1.0;
       #ifdef ENABLE_LANDSCAPE_RECEIVE_SHADOW
            fSunShadow = GetSunShadow( primaryInt.m_pos );
       #endif
            AddSunLight( primarySurface, -vRayDir, fSunShadow, vTransmitLight, vSpecularLight);
            AddSkyLight( primarySurface, vTransmitLight, vSpecularLight);
            vTransmitLight *= primarySurface.m_albedo;
            specSurface = primarySurface;
        }

        vec3 vReflectRayDir = reflect( vRayDir, vSpecNormal );
        vec3 vReflectLight = GetRayColour( vReflectRayOrigin, vReflectRayDir );

        vReflectLight = mix( GetEnvColour(vReflectRayDir, specSurface.m_gloss), vReflectLight, pow( specSurface.m_gloss, 40.0) );
        
        vec3 vFresnel = GetFresnel( -vRayDir, vSpecNormal, specSurface.m_specR0, specSurface.m_gloss );

        vSpecularLight += vReflectLight;
        vResult = mix(vTransmitLight, vSpecularLight, vFresnel * specSurface.m_specScale );
    }
    
    
    if ( fFogDistance >= k_fFarClip )
    {
        fFogDistance = 100.0;
        vResult = smoothstep( 0.9995, 0.9999, fSunDotV ) * g_sunColour * 200.0;
    }    
    
    vec3 vFogColour = GetSkyColour(vRayDir);
    
    vec3 vFogExtCol = exp2( k_vFogExt * -fFogDistance );
    vec3 vFogInCol = exp2( k_vFogIn * -fFogDistance );
    vResult = vResult*(vFogExtCol) + vFogColour*(1.0-vFogInCol);
    
    return vResult;
}

// Code from https://www.shadertoy.com/view/ltlSWf 
void BlockRender(in vec2 fragCoord)
{
    const float blockRate = 15.0;
    const float blockSize = 64.0;
    float frame = floor(iGlobalTime * blockRate);
    vec2 blockRes = floor(iResolution.xy / blockSize) + vec2(1.0);
    float blockX = fract(frame / blockRes.x) * blockRes.x;
    float blockY = fract(floor(frame / blockRes.x) / blockRes.y) * blockRes.y;
    // Don't draw anything outside the current block.
    if ((fragCoord.x - blockX * blockSize >= blockSize) ||
    	(fragCoord.x - (blockX - 1.0) * blockSize < blockSize) ||
    	(fragCoord.y - blockY * blockSize >= blockSize) ||
    	(fragCoord.y - (blockY - 1.0) * blockSize < blockSize))
    {
        discard;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    g_fTime = iGlobalTime;

    float fBaseTime = iGlobalTime;
    g_fTime = fBaseTime;
    
    float fCameraTime = g_fTime;
    
	// Static camera locations
    //fCameraTime = 146.0; // some rocks
    
    vec2 vUV = fragCoord.xy / iResolution.xy;

	vec3 vCameraTarget = vec3(0.0, -0.5, 0.0);

    vCameraTarget.x -= fCameraTime * 0.5;
    
    vec3 vCameraPos = vCameraTarget + vec3(0.0, 0.0, 0.0);
    
    float fHeading = fCameraTime * 0.1;
    float fDist = 1.5 - cos(fCameraTime * 0.1 + 2.0) * 0.8;
    
#ifdef MOUSE
    if( iMouse.z > 0.0 )
    {
        fHeading = iMouse.x * 10.0 / iResolution.x;
        fDist = 5.0 - iMouse.y * 5.0 / iResolution.y;
    }
#endif
    
    vCameraPos.y += 1.0 + fDist * fDist * 0.01;
        
    vCameraPos.x += sin( fHeading ) * fDist;
    vCameraPos.z += cos( fHeading ) * fDist;
    
    vCameraTarget.z += GetRiverMeander( vCameraTarget.x );
    vCameraPos.z += GetRiverMeander( vCameraPos.x );

    vCameraPos.y = max( vCameraPos.y, GetTerrainHeightSimple( vCameraPos ) + 0.2 );
    
    vec3 vRayOrigin = vCameraPos;
	vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV), vCameraPos, vCameraTarget );
	
#ifndef ENABLE_SUPERSAMPLE_MODE
	vec3 vResult = GetSceneColour(vRayOrigin, vRayDir);
#else
	vec3 vResult = vec3(0.0);
    float fTot = 0.0;
    for(int i=0; i<k_superSampleCount; i++)
    {
        g_fTime = fBaseTime + (fTot / 10.0) / 30.0;
        vec3 vCurrRayDir = vRayDir;
        vec3 vRandom = vec3( SmoothNoise( fragCoord.xy + fTot ), 
                        SmoothNoise( fragCoord.yx + fTot + 42.0 ),
                        SmoothNoise( fragCoord.xx + fragCoord.yy + fTot + 42.0 ) ) * 2.0 - 1.0;
        vRandom = normalize( vRandom );
        vCurrRayDir += vRandom * 0.001;
        vCurrRayDir = normalize(vCurrRayDir);
    	vResult += GetSceneColour(vRayOrigin, vCurrRayDir);
        fTot += 1.0;
    }
    vResult /= fTot;
#endif    
    
	vResult = ApplyVignetting( vUV, vResult );	
	
	vec3 vFinal = Tonemap(vResult * 3.0);
	
    vFinal = vFinal * 1.1 - 0.1;
    
	fragColor = vec4(vFinal, 1.0);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    g_fTime = iGlobalTime;
    
    fragRayOri = fragRayOri.zyx;
    fragRayDir = fragRayDir.zyx;
    
    fragRayOri.z *= -1.0;
    fragRayDir.z *= -1.0;
    
    fragRayOri *= 0.1;
    
    fragRayOri.y += 0.2;
    
    fragRayOri.x -= g_fTime * 0.1;
    fragRayOri.z += GetRiverMeander( fragRayOri.x );
    
    
    vec3 vResult = GetSceneColour(fragRayOri, fragRayDir);
    
	vec3 vFinal = Tonemap(vResult * 3.0);
	
    vFinal = vFinal * 1.1 - 0.1;
    
	fragColor = vec4(vFinal, 1.0);    
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
