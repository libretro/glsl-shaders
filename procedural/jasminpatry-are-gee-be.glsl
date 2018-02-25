#version 120
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


// Configuration

// Number of (primary) rays per pixel

#define RAY_COUNT (1)

// Enable specular importance sampling?

#define ENABLE_IS 0

// Larger values reduces fireflies

const float g_gISNoiseReduction = 0.005;

// Enable depth of field?

#define ENABLE_DOF 0

// Controls size of DOF ray cone

const float g_rDOFScale = 0.015;

// Enable motion blur?

#define ENABLE_MOTION_BLUR 0

// Motion blur exposure time in seconds.

const float g_dTExposure = 1.0 / 48.0;

// Number of reflection bounces

const int g_cBounce = 3;

// Angle (radians) to tilt camera down

const float g_radTiltCamera = 0.06;

// Full-strength (mirror-like, no fog) sun reflections. Fake, but combined with long-exposure
//	motion blur gives cool specular light painting effects. Has no effect unless ENABLE_IS is on.

#define FULL_STRENGTH_SUN 0

// Scaling factor for sun reflections & specular highlights. Alternative or complement to
//	FULL_STRENGTH_SUN to achieve light painting effects.

const float g_rSunSpecScale = 1.0;

// If true, uses same low-discrepancy sequence to generate DOF and IS samples. Generally not good
//	practice, but can generate rather beautiful results when combined with long exposure times.

#define CORRELATED_DOF 0

// If true, uses same low-discrepancy sequence to generate motion blur and IS samples. Generally
//	not good practice, but can generate rather beautiful results when combine with long exposure
//	times. For example see https://twitter.com/jasminpatry/status/652570309204115456

#define CORRELATED_MB 0

// For doing high-res offline tiled renders

#define TILED_RENDER 0

// If true, use soft-min from @mmalex's SIGGRAPH 2015 presentation. (This is what started me on
//	this in the first place.) If false, uses "classic" soft-min (see
//	http://www.johndcook.com/blog/2010/01/20/how-to-compute-the-soft-maximum/ ), which has the
//	advantage that its derivatives are continuous everywhere.

#define MM_SOFT_MIN 0

// My son's color scheme :)

#define BERNIE_COLORS 0

// Halloween colors

#define HALLOWEEN_COLORS 0

// Disable AO? Doesn't contribute very much since diffuse albedo is dark, and it's pretty
//	expensive...

#define DISABLE_AO 0

// Disable shadows?

#define DISABLE_SHADOWS 0

// Debug displays

#define DEBUG_STEPS		0
#define DEBUG_DIFFUSE	0
#define DEBUG_NORMALS	0
#define DEBUG_AO		0
#define DEBUG_SHADOWS	0

// End configuration



const float g_gPi = 3.14159265359;

// Maximum ray length

const float g_sRayMax = 1.0e5;

// Maximum geometry height

const float g_zMax = 400.0;

// Specular reflectance at normal incidence

const float g_rSpecular = 0.04;

// Global time (jittered if motion blur is enabled)

float g_t = 0.0;

// [0-1] uniform random values for importance sampling

vec2 g_vecURandomIS = vec2(0);

// Light direction

vec3 g_normalLight = vec3(0);

float saturate(float g)
{
	return clamp(g, 0.0, 1.0);
}

vec2 saturate(vec2 vec)
{
	return clamp(vec, 0.0, 1.0);
}

vec3 saturate(vec3 vec)
{
	return clamp(vec, 0.0, 1.0);
}

vec4 saturate(vec4 vec)
{
	return clamp(vec, 0.0, 1.0);
}

float GLuminance(vec3 rgbLinear)
{
	return dot(rgbLinear, vec3(0.2126, 0.7152, 0.0722));
}

float GSign(float g)
{
	return (g < 0.0) ? -1.0 : 1.0;
}

float GSqr(float g)
{
	return g * g;
}

float GLengthSqr(vec3 vec)
{
	return dot(vec, vec);
}

float UHash(vec2 xy)
{
	return fract(sin(dot(xy.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 VecHash2(vec2 xy)
{
	// BB Values for y component pulled out of the air, more or less.

	return fract(sin(vec2(
						dot(xy, vec2(12.9898, 78.233)),
						dot(xy, vec2(-67.233, 10.9898)))) * vec2(43758.5453, 73756.5453));
}

vec2 VecSubRandom(vec2 vecPrev)
{
	// From http://mollwollfumble.blogspot.com/2011/03/subrandom-numbers.html
	//	Interactive graph: https://www.desmos.com/calculator/rvtbalxuhq

	vecPrev += vec2(0.5545497, 0.308517);
	return vecPrev - floor(vecPrev);
}

vec2 VecDisc(vec2 vecURandom)
{
	// For vecURandom uniformly distributed in [0, 1], returns uniform samples on unit disc.

	float rad = vecURandom.x * 2.0 * g_gPi;
	float s = sqrt(vecURandom.y);
	return s * vec2(cos(rad), sin(rad));
}

vec3 VecRotateY(vec3 vec, float rad)
{
	float gSin = sin(rad);
	float gCos = cos(rad);
	vec3 vecRot = vec;
	vecRot.x = vec.x * gCos + vec.z * gSin;
	vecRot.z = - vec.x * gSin + vec.z * gCos;
	return vecRot;
}

void UpdateLightDirection()
{
	vec3 normalLight = normalize(vec3(0.2, 0.9, 0.2));
	float radTheta = 2.0 * g_gPi * g_t / 60.0;
	float gSin = sin(radTheta);
	float gCos = cos(radTheta);
	mat2 matRot = mat2(gCos, -gSin, gSin, gCos);
	normalLight.xy = matRot * normalLight.xy;
	g_normalLight = normalLight;
}

vec3 RgbLight()
{
#if BERNIE_COLORS
	return vec3(1.7, 0.3, 0.1);
#elif HALLOWEEN_COLORS
	return vec3(1.7, 0.15, 0.0);
#else
	return vec3(2.0, 0.1, 0.1);
#endif
}

float RLightCone()
{
	// tan of one half of subtended angle of sun disc in sky

	return 0.02;
}

float GDotLightCone()
{
	return cos(atan(RLightCone()));
}

vec3 RgbSunDisc()
{
	return RgbLight() / (GSqr(RLightCone()));
}

vec3 RgbSky()
{
#if BERNIE_COLORS
	return vec3(0.6, 0.4, 0.05);
#elif HALLOWEEN_COLORS
	return vec3(0.01, 0.001, 0.0);
#else
	return vec3(1.0, 1.0, 1.0) * 0.1;
#endif
}

vec3 RgbAmbient()
{
	return RgbSky() / g_gPi;
}

vec3 RgbFog(vec3 normalRay)
{
#if BERNIE_COLORS
	vec3 rgbFog = RgbSky() * 3.0;
#elif HALLOWEEN_COLORS
	vec3 rgbFog = vec3(1.0, 0.0, 0.0) * 0.03;
#else
	vec3 rgbFog = vec3(0.6, 0.2, 1.0);
#endif
	return mix(rgbFog, RgbLight() * 3.5, GSqr(saturate(dot(normalRay, g_normalLight))));
}

vec4 VecOsc(vec4 vecFreq, vec4 vecAmp, float dT)
{
	return vecAmp * sin(vec4((g_t + dT) * 2.0 * g_gPi) * vecFreq);
}

vec4 Sphere0(vec4 sphereBase, float uRandom)
{
	return sphereBase + VecOsc(
							vec4(1.02389382 / 2.0, 1.0320809 / 3.0, 1.07381 / 4.0, 0.0),
							vec4(20, 100, 100, 0) +
							VecOsc(
								vec4(1.10382 / 6.0, 1.092385 / 10.0, 1.03389 / 14.0, 0),
								vec4(10, 50, 50, 0), 100.0 * uRandom), 100.0 * uRandom);
}

vec4 Sphere1(vec4 sphereBase, float uRandom)
{
	return sphereBase + VecOsc(
							vec4(1.032038 / 4.0, 1.13328 / 2.0, 1.09183 / 3.0, 0),
							vec4(20, 100, 100, 0) +
							VecOsc(
								vec4(1.0328 / 14.0, 1.1381 / 6.0, 1.0238 / 10.0, 0),
								vec4(10, 50, 50, 0), 100.0 * uRandom), 100.0 * uRandom);
}

vec4 Sphere2(vec4 sphereBase, float uRandom)
{
	return sphereBase + VecOsc(
							vec4(1.123283 / 3.0, 1.13323 / 4.0, 1.2238 / 2.0, 0),
							vec4(20, 100, 100, 0) +
							VecOsc(
								vec4(1.0 / 10.0, 1.0 / 14.0, 1.0 / 6.0, 0),
								vec4(10, 50, 50, 0), 100.0 * uRandom), 100.0 * uRandom);
}

float SSoftMinRadius01(float uRandom)
{
	return 100.0 + 50.0 * sin(g_t * 1.14 + uRandom * 100.0);
}

float SSoftMinRadius12(float uRandom)
{
	return 100.0 + 50.0 * sin(g_t * 1.16323823 + uRandom * 100.0);
}

vec3 RgbTonemap(vec3 rgbLinear)
{
	// Desaturate with luminance

	float gLuminance = GLuminance(rgbLinear);
	rgbLinear = mix(rgbLinear, vec3(gLuminance), GSqr(saturate((gLuminance - 1.0) / 1.0)));

	// Hejl/Burgess-Dawson approx to Hable operator; includes sRGB conversion

	vec3 rgbT = max(vec3(0.0), rgbLinear - 0.004);
	vec3 rgbSrgb = (rgbT * (6.2 * rgbT + 0.5)) / (rgbT * (6.2 * rgbT + 1.7) + 0.06);

	return rgbSrgb;
}

struct SMaterial	// tag = mtl
{
	vec3 m_rgbDiffuse;
	float m_gGgxAlpha;
};

SMaterial MtlCreate(vec3 rgbDiffuse, float gGgxAlpha)
{
	SMaterial mtl;
	mtl.m_rgbDiffuse = rgbDiffuse;
	mtl.m_gGgxAlpha = gGgxAlpha;
	return mtl;
}

SMaterial MtlLerp(SMaterial mtl0, SMaterial mtl1, float u)
{
	SMaterial mtl;
	mtl.m_rgbDiffuse = mix(mtl0.m_rgbDiffuse, mtl1.m_rgbDiffuse, u);
	mtl.m_gGgxAlpha = mix(mtl0.m_gGgxAlpha, mtl1.m_gGgxAlpha, u);
	return mtl;
}

struct SHit	// tag = hit
{
	float m_s;
	vec3 m_normal;
	SMaterial m_mtl;
};

SHit HitMin(SHit hit0, SHit hit1)
{
	if (hit0.m_s < hit1.m_s)
	{
		return hit0;
	}
	else
	{
		return hit1;
	}
}

SHit HitPlane(vec4 plane, SMaterial mtl, vec3 posRay, vec3 normalRay)
{
	float gDotNormal = dot(plane.xyz, normalRay);

	float s = -dot(plane, vec4(posRay, 1.0)) / gDotNormal;

	SHit hit;

	hit.m_normal = plane.xyz;
	vec3 posHit = (posRay + s * normalRay);
	hit.m_normal.xy += saturate(-normalRay.z) * 0.1 * sin(posHit.xy / (100.0));
	hit.m_normal = normalize(hit.m_normal);
	hit.m_s = (abs(gDotNormal) > 1e-6 && s > 0.0) ? s : g_sRayMax;
	hit.m_mtl = mtl;

	return hit;
}

struct SSdfSample	// tag = sdf
{
	float m_s;
	SMaterial m_mtl;
};

SSdfSample SdfSoftMin(SSdfSample sdf0, SSdfSample sdf1, float sRadiusBlend)
{
#if MM_SOFT_MIN
	float gT = max(sRadiusBlend - abs(sdf0.m_s - sdf1.m_s), 0.0);
	float s = min(sdf0.m_s, sdf1.m_s) - gT * gT * 0.25 / sRadiusBlend;
#else
	float gK = 0.25 * sRadiusBlend;
	float sMin = min(sdf0.m_s, sdf1.m_s);
	float sMax = max(sdf0.m_s, sdf1.m_s);
	float s = sMin - gK * log2(exp2((sMin - sMax) / gK) + 1.0);
#endif
	float dS0 = sdf0.m_s - s;
	float dS1 = sdf1.m_s - s;
	float u = dS0 / (dS1 + dS0);
	SSdfSample sdf;
	sdf.m_s = s;
	sdf.m_mtl = MtlLerp(sdf0.m_mtl, sdf1.m_mtl, u);
	return sdf;
}

SSdfSample SdfSphere(vec4 sphere, SMaterial mtl, vec3 pos)
{
	vec3 posSphere = sphere.xyz;
	float sRadius = sphere.w;

	SSdfSample sdf;
	sdf.m_s = length(pos - posSphere) - sRadius;
	sdf.m_mtl = mtl;
	return sdf;
}

SSdfSample SdfBlobby(vec3 pos, float uRandom)
{
	const float gGgxAlpha = 1.0 / 64.0;
	const vec4 sphereBase = vec4(0.0, 0.0, 200.0, 50.0);

	SSdfSample sdf = SdfSphere(
						Sphere0(sphereBase, uRandom),
						MtlCreate(vec3(0.1, 0.8, 0.1) / 4.0, gGgxAlpha),
						pos);

	sdf = SdfSoftMin(
			sdf,
			SdfSphere(
				Sphere1(sphereBase, uRandom),
				MtlCreate(vec3(0.1, 0.3, 0.8) / 4.0, gGgxAlpha),
				pos),
			SSoftMinRadius01(uRandom));

	sdf = SdfSoftMin(
			sdf,
			SdfSphere(
				Sphere2(sphereBase, uRandom),
				MtlCreate(vec3(0.7, 0.05, 0.2) / 4.0, gGgxAlpha),
				pos),
			SSoftMinRadius12(uRandom));

	return sdf;
}

const float g_sRepeat = 800.0;

vec2 PosIndex(vec3 pos)
{
	vec2 posIndex;
	posIndex.x = floor((pos.x + 0.5 * g_sRepeat) / g_sRepeat);
	posIndex.y = floor((pos.y + 0.5 * g_sRepeat) / g_sRepeat);
	return posIndex;
}

vec3 PosWrap(vec3 pos)
{
	vec2 posIndex = PosIndex(pos);
	pos.xy = fract(pos.xy / g_sRepeat + 0.5) * g_sRepeat - 0.5 * g_sRepeat;
	if (dot(posIndex, posIndex) != 0.0)
	{
		pos.xy += (VecHash2(posIndex) - vec2(0.5, 0.5)) * g_sRepeat * 0.5;
	}
	return pos;
}

float UHashFromPos(vec3 pos)
{
	pos.xy = PosIndex(pos);
	return UHash(pos.xy);
}

vec3 PosRound(vec3 pos)
{
	pos.xy = floor((pos.xy + 0.5 * g_sRepeat) / g_sRepeat + 0.5) * g_sRepeat - 0.5 * g_sRepeat;
	return pos;
}

float DSCellEdge(vec3 pos)
{
	vec2 dPos = abs(PosRound(pos).xy - pos.xy);
	const float sZSlop = 10.0;
	return (pos.z > g_zMax) ? (pos.z - g_zMax - sZSlop) : min(dPos.x, dPos.y);
}

SSdfSample SdfScene(vec3 pos, float uRandom)
{
	SSdfSample sdf = SdfBlobby(pos, uRandom);

	// Try to keep from penetrating the ground plane
	// BB Causes issues with shadows, better solution?

	sdf.m_s += max(0.0, max(20.0 - pos.z, 100.0 / max(pos.z, 1e-6)));

	// And g_zMax

	sdf.m_s += max(0.0, max(20.0 - (g_zMax - pos.z), 100.0 / max(g_zMax - pos.z, 1e-6)));

	return sdf;
}

bool FIntersectScene(
		vec3 posRay,
		vec3 normalRay,
		out SHit o_hit,
		out int o_cStep)
{
	SMaterial mtlPlane = MtlCreate(vec3(0.2, 0.2, 0.2), 1.0 / 20.0);
	SHit hitPlane = HitPlane(vec4(0, 0, 1, 0), mtlPlane, posRay, normalRay);

	float sRay = 0.0;
	const int cStepMax = 100;
	for (int cStep = 0; cStep < cStepMax; ++cStep)
	{
		o_cStep = cStep;

		vec3 pos = posRay + normalRay * sRay;

		float uRandom = UHashFromPos(pos);
		SSdfSample sdf = SdfScene(PosWrap(pos), uRandom);

		float dSEdge = DSCellEdge(pos);
		const float sEdgeSlop = 100.0;
		sRay += min(sdf.m_s, dSEdge + sEdgeSlop);

		if (sRay >= hitPlane.m_s ||
			pos.z < 0.0 ||
			(pos.z > g_zMax && normalRay.z >= 0.0))
		{
			o_hit = hitPlane;
			return hitPlane.m_s < g_sRayMax;
		}

		if (sdf.m_s < 1.0)
		{
			o_hit.m_s = sRay;
			vec3 posHit = posRay + normalRay * sRay;
			posHit = PosWrap(posHit);
			SSdfSample sdfHit = SdfScene(posHit, uRandom);

			// Construct normal

			SSdfSample sdfHitX = SdfScene(posHit + vec3(0.1, 0, 0), uRandom);
			SSdfSample sdfHitY = SdfScene(posHit + vec3(0, 0.1, 0), uRandom);
			SSdfSample sdfHitZ = SdfScene(posHit + vec3(0, 0, 0.1), uRandom);

			o_hit.m_normal = vec3(
								sdfHitX.m_s - sdfHit.m_s,
								sdfHitY.m_s - sdfHit.m_s,
								sdfHitZ.m_s - sdfHit.m_s);
			o_hit.m_normal = normalize(o_hit.m_normal);

			o_hit.m_mtl = sdfHit.m_mtl;
			return true;
		}
	}

	o_cStep = cStepMax;

	o_hit = hitPlane;
	return hitPlane.m_s < g_sRayMax;
}

float UConeTraceScene(vec3 posRay, vec3 normalRay, float rConeWidth, float dS, float dUOccMax, bool fCrossCells)
{
	float sRay = 3.0;

	float uOcclusion = 1.0;

	float uRandom = 0.0;

	// rConeNoOcc is the non-occluded portion of the cone (tan of the cone half-angle)

	float rConeNoOcc = rConeWidth;

	if (!fCrossCells)
	{
		uRandom = UHashFromPos(posRay);
		posRay = PosWrap(posRay);
	}

	for (int iStep = 0; iStep < 50; ++iStep)
	{
		vec3 pos = posRay + normalRay * sRay;

		float sConeWidth = sRay * rConeWidth;

		// Compute min step size. The second argument to max() is the step size yielding a maximum occlusion change of
		//	dUOccMax.

		float dSMin = max(dS, 2.0 * dUOccMax * sRay * rConeWidth);

		// Find sRay_new such that sRay_new - sRay_old == sdf.m_s - rConeNoOcc * sRay_new
		//	i.e., march until until new cone potentially touches surface
		//	Solution is: sRay_new := (sdf.m_s - sRay_old * rConeNoOcc) / (1.0 + rConeNoOcc)
        //  Then add dSMin to potentially get some occlusion.

		SSdfSample sdf;
		if (fCrossCells)
		{
			uRandom = UHashFromPos(pos);
			sdf = SdfScene(PosWrap(pos), uRandom);

			float dSCellEdge = DSCellEdge(pos);
			const float sEdgeSlop = 10.0;
			sRay += max(
						0.0,
						(min(dSCellEdge + sEdgeSlop, sdf.m_s) - sRay * rConeNoOcc) /
						(1.0 + rConeNoOcc));
            sRay += dSMin;
		}
		else
		{
			sdf = SdfScene(pos, uRandom);

			sRay += max(0.0, (sdf.m_s - sRay * rConeNoOcc) / (1.0 + rConeNoOcc));
            sRay += dSMin;
		}

		// Update occlusion and non-occluded cone width

		uOcclusion = min(uOcclusion, saturate(0.5 * (1.0 + sdf.m_s / sConeWidth)));
		rConeNoOcc = rConeWidth * saturate(2.0 * uOcclusion - 1.0);

		if (uOcclusion < 0.01 ||
			pos.z < 0.0 ||
			(pos.z > g_zMax && normalRay.z >= 0.0))
		{
			return uOcclusion;
		}
	}

	return uOcclusion;
}

// GGX specular lighting
// See e.g. http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf

float GGgxVisRcp(float gGgxAlphaSqr, float gDot)
{
	gDot = saturate(gDot);
	return gDot + sqrt(mix(GSqr(gDot), 1.0, gGgxAlphaSqr));
}

float UFresnel(float gDot)
{
	float uFresnel = 1.0 - gDot;
	float uFresnel2 = GSqr(uFresnel);
	uFresnel = GSqr(uFresnel2) * uFresnel;
	return uFresnel;
}

float RSpecularLight(vec3 normalRay, vec3 normal, float gGgxAlpha, out float o_rDiffuse)
{
	float gGgxAlphaSqr = GSqr(gGgxAlpha);

	vec3 normalHalf = normalize(g_normalLight - normalRay);
	float gDotHalf = saturate(dot(normalHalf, normal));

	float uFresnel = UFresnel(gDotHalf);

	float rSpecular = mix(g_rSpecular, 1.0, uFresnel);

	float gNdf = gGgxAlphaSqr / GSqr(GSqr(gDotHalf) * (gGgxAlphaSqr - 1.0) + 1.0);
	float gVis = 1.0 / (GGgxVisRcp(gGgxAlphaSqr, dot(-normalRay, normal)) *
						GGgxVisRcp(gGgxAlphaSqr, dot(g_normalLight, normal)));

	o_rDiffuse = 1.0 - rSpecular;

#if ENABLE_IS
	return 0.0;
#else
	return gNdf * gVis * rSpecular * g_rSunSpecScale;
#endif
}

vec3 RgbLightHit(vec3 posHit, vec3 normalRay, SHit hit)
{
	const float rScaleLightCone = 3.0;	// Enlarge light cone for softer shadows

	float uShadow = UConeTraceScene(
						posHit,
						g_normalLight,
						RLightCone() * rScaleLightCone,
						20.0,
						0.15,
						true);

#if DISABLE_SHADOWS
	uShadow = 1.0;
#endif

#if DEBUG_SHADOWS
	return vec3(uShadow);
#endif

	float uAmbient = UConeTraceScene(posHit, hit.m_normal, 1.0, 20.0, 0.05, false);

	// BB Hacky AO based on normal Z with height falloff

	uAmbient = min(uAmbient, mix(
								saturate(0.5 + 0.5 * hit.m_normal.z),
								1.0,
								saturate(posHit.z / 300.0)));

	float dSCellEdge = DSCellEdge(posHit);
	uAmbient = mix(uAmbient, 1.0, smoothstep(0.0, 1.0, 1.0 - dSCellEdge / 100.0));

#if DISABLE_AO
	uAmbient = 1.0;
#endif

#if DEBUG_AO
	return vec3(uAmbient);
#endif

	vec3 rgbLight = uAmbient * RgbAmbient() * hit.m_mtl.m_rgbDiffuse;
	float gDotLight = dot(g_normalLight, hit.m_normal);
	vec3 rgbDiffuse = hit.m_mtl.m_rgbDiffuse;
	float rDiffuse;
	float rSpecularLight = RSpecularLight(
							normalRay,
							hit.m_normal,
							hit.m_mtl.m_gGgxAlpha,
							rDiffuse);
	rgbDiffuse *= rDiffuse;
	rgbLight += uShadow * saturate(gDotLight) * (rgbDiffuse + rSpecularLight) * RgbLight();

	return rgbLight;
}

float RFog(float s, vec3 posRay, vec3 normalRay)
{
	// Height-based exponential fog

	const float gDensityAtGround = 1.0 / 40000.0;
	const float gHeightFalloff = 1.0 / 10000.0;

	float gT = -gDensityAtGround * exp(-gHeightFalloff * posRay.z);

	if (abs(normalRay.z) > 1e-6)
	{
		gT *= (1.0 - exp(-gHeightFalloff * normalRay.z * s)) / (gHeightFalloff * normalRay.z);
	}
	else
	{
		gT *= s;
	}

	return exp(gT);
}

vec3 RgbIntersectScene(vec3 posRay, vec3 normalRay)
{
	SHit hit;
	vec3 rgbLight = vec3(0);
	float r = 1.0;
	int cStepTotal = 0;

	for (int iBounce = 0; iBounce <= g_cBounce; ++iBounce)
	{
		int cStep = 0;
		bool fIntersect = FIntersectScene(posRay, normalRay, hit, cStep);

		cStepTotal += cStep;

#if DEBUG_DIFFUSE
		// BB Should use exact sRGB conversion

		return (fIntersect) ? pow(hit.m_mtl.m_rgbDiffuse, vec3(1.0 / 2.2)) : vec3(0);
#endif

#if DEBUG_NORMALS
		return (fIntersect) ? hit.m_normal * 0.5 + 0.5 : vec3(0);
#endif

		if (fIntersect)
		{
			vec3 posHit = posRay + normalRay * hit.m_s;

			float rFog = RFog(hit.m_s, posRay, normalRay);
			rgbLight += (1.0 - rFog) * r * RgbFog(normalRay);
			r *= rFog;

			vec3 rgbLightHit = RgbLightHit(posHit, normalRay, hit);

#if DEBUG_AO || DEBUG_SHADOWS
			return rgbLightHit;
#endif

			rgbLight += r * rgbLightHit;

			// Prepare for next bounce

			vec3 normalReflect;

#if ENABLE_IS
			{
				// GGX importance sampling (see Karis notes linked above)

				float gGgxAlphaSqr = GSqr(hit.m_mtl.m_gGgxAlpha);
				float radPhi = 2.0 * g_gPi * g_vecURandomIS.x;
				float gCosTheta = sqrt((1.0 - g_vecURandomIS.y) /
									   (1.0 + (gGgxAlphaSqr - 1.0) * g_vecURandomIS.y));
				float gSinTheta = sqrt(1.0 - GSqr(gCosTheta));

				vec3 normalHalfTangentSpace = vec3(
												gSinTheta * cos(radPhi),
												gSinTheta * sin(radPhi),
												gCosTheta);

				// Construct orthonormal basis (Frisvad method)

				float gA = (hit.m_normal.z > -0.99999) ? 1.0 / (1.0 + hit.m_normal.z) : 0.0;
				float gB = -hit.m_normal.x * hit.m_normal.y * gA;
				vec3 tangent = vec3(1.0 - GSqr(hit.m_normal.x) * gA, gB, -hit.m_normal.x);
				vec3 binormal = vec3(gB, 1.0 - GSqr(hit.m_normal.y) * gA, -hit.m_normal.y);
				vec3 normalHalf = normalHalfTangentSpace.x * tangent +
					normalHalfTangentSpace.y * binormal +
					normalHalfTangentSpace.z * hit.m_normal;

				normalReflect = normalRay - 2.0 * dot(normalRay, normalHalf) * normalHalf;

				float gDotRay = saturate(dot(hit.m_normal, -normalRay));
				float gDotReflect = saturate(dot(hit.m_normal, normalReflect));
				float gDotHalf = saturate(dot(hit.m_normal, normalHalf));
				float gRayDotHalf = saturate(dot(-normalRay, normalHalf));
				if (gDotReflect > 0.0)
				{
					float gVisRcp = GGgxVisRcp(gGgxAlphaSqr, gDotRay) *
									GGgxVisRcp(gGgxAlphaSqr, gDotReflect);
					float uFresnel = UFresnel(gRayDotHalf);
					float rSpecular = mix(g_rSpecular, 1.0, uFresnel);
					r *= 4.0 * rSpecular * gRayDotHalf * gDotReflect / (gVisRcp * gDotHalf);
				}
				else
				{
					// NOTE a break here makes the AMD compiler on Windows unhappy

					r = 0.0;
					posRay = vec3(0.0, 0.0, g_zMax * 10.0);
					normalRay = vec3(0.0, 0.0, 1.0);
				}
			}

#else // !ENABLE_IS
			// BB This works ok for our low roughness values, but for rougher materials would want
			//	something better, e.g. an analytic approximation to the pre-integrated ambient
			//	specular BRDF LUT in Karis's notes.

			normalReflect = reflect(normalRay, hit.m_normal);
			r *= mix(g_rSpecular, 1.0, UFresnel(saturate(dot(normalReflect, hit.m_normal))));
#endif // !ENABLE_IS

			posRay = posHit + normalReflect * 10.0;
			normalRay = normalReflect;
		}
		else
		{
			float rFog = RFog(1e10, posRay, normalRay);
			rgbLight += (1.0 - rFog) * r * RgbFog(normalRay);
			r *= rFog;

			// Sun + sky
			// BB Just hacking here, can probably be simplified a bunch.

			float gDotLight = dot(normalRay, g_normalLight);

			vec3 vecPerp = normalRay - gDotLight * g_normalLight;

			float gPerpDistSqr = dot(vecPerp, vecPerp);
			float rGlow = 20.0;

			bool fDrawSun = true;
#if !ENABLE_IS
			fDrawSun = (iBounce == 0);
#endif

			if (fDrawSun &&
				gDotLight > 0.0 &&
				gPerpDistSqr < GSqr(RLightCone() * rGlow * gDotLight))
			{
				float gSunLum = GLuminance(RgbSunDisc());
				float gK = 0.1;
				gSunLum /= gK + gSunLum;
				float gNewLum = gSunLum * GSqr(smoothstep(
											(RLightCone() * rGlow),
											RLightCone() * 1.0,
											length(vecPerp)));
				gNewLum *= gK / (1.0 - gNewLum);

				float rSun = r;

#if FULL_STRENGTH_SUN
				rSun = 1.0;
#endif

				if (iBounce > 0)
				{
					rSun *= g_rSunSpecScale;
				}

				rgbLight += rSun * gNewLum / GLuminance(RgbSunDisc()) * RgbSunDisc();
			}

			rgbLight += r * RgbSky();

			float u = saturate(
						-gDotLight / (GDotLightCone() + 1.0) + 1.0 / (1.0 / GDotLightCone() + 1.0));
			float g = u / max(1.0 - u, 1e-8);
			float rHaze = exp(-g * 10.0);
			rHaze += rHaze * (1.0 + rHaze * (1.0 + rHaze * (1.0 + rHaze)));
			rgbLight += r * 0.4 * RgbLight() * rHaze;

			// NOTE a break here makes the AMD compiler on Windows unhappy

			r = 0.0;
			posRay = vec3(0.0, 0.0, g_zMax * 10.0);
			normalRay = vec3(0.0, 0.0, 1.0);
		}
	}

#if DEBUG_STEPS
	return vec3(float(cStepTotal) / 100.0);
#endif

	return rgbLight;
}

void mainImage(out vec4 o_rgbaColor, in vec2 xyPixel)
{
#if TILED_RENDER
	xyPixel += iOffset;
#endif

	g_t = iGlobalTime;
	vec3 rgbColor = vec3(0);
	float gWeightSum = 0.0;

	g_vecURandomIS = VecHash2(vec2(xyPixel + g_t));
	vec2 vecURandomDOF = VecHash2(vec2(xyPixel * g_gPi + g_t * exp(1.0)));
	vec2 vecURandomAA = VecHash2(vec2(xyPixel * exp(1.0) + g_t * g_gPi));
	float uRandomMB = UHash(vec2(xyPixel * sqrt(2.0) + g_t * 0.5 * (1.0 + sqrt(5.0))));

	for (int iRay = 0; iRay < RAY_COUNT; ++iRay)
	{
#if CORRELATED_DOF
		vecURandomDOF = g_vecURandomIS;
#endif

#if CORRELATED_MB
		uRandomMB = g_vecURandomIS.x;
#endif

#if ENABLE_MOTION_BLUR
		g_t = iGlobalTime - uRandomMB * g_dTExposure;
#endif

		UpdateLightDirection();

		vec3 posView = vec3(-500.0, 0.0, 200.0);
		vec2 dXyOffset = vec2(0);
#if RAY_COUNT > 1
		dXyOffset = vecURandomAA - 0.5;
#endif
		vec2 xyPixelOffset = (xyPixel.xy + dXyOffset);
		vec2 uvScreen = xyPixelOffset / iResolution.xy;
		vec3 normalCm = vec3(1.0, 0.0, 0.0);
		vec2 vecAspect = vec2(-1.0, iResolution.y / iResolution.x);
		float gFov = 0.9;
		normalCm.yz = (uvScreen * 2.0 - 1.0) * vecAspect * gFov;

#if ENABLE_DOF
		vec2 vecDisc = VecDisc(vecURandomDOF);
		normalCm.yz += vecDisc * g_rDOFScale;
		posView.yz += vecDisc * g_rDOFScale * posView.x;
#endif

		normalCm = VecRotateY(normalCm, g_radTiltCamera);

		// Lens distortion

		normalCm.yz *= 5.0 / (5.0 + dot(normalCm.yz, normalCm.yz));

		normalCm = normalize(normalCm);

		vec3 rgbHit = RgbIntersectScene(posView, normalCm);
		float gLum = GLuminance(rgbHit);
		float gWeight = 1.0 / (1.0 / (g_gISNoiseReduction + 1e-10) + gLum);
		rgbColor += rgbHit * gWeight;
		gWeightSum += gWeight;

		g_vecURandomIS = VecSubRandom(g_vecURandomIS);
		vecURandomDOF = VecSubRandom(vecURandomDOF);
		vecURandomAA = VecSubRandom(vecURandomAA);
		uRandomMB = VecSubRandom(vec2(uRandomMB)).x;
	}

	rgbColor = rgbColor / gWeightSum;

#if DEBUG_STEPS || DEBUG_DIFFUSE || DEBUG_NORMALS || DEBUG_AO || DEBUG_SHADOWS
	o_rgbaColor.rgb = rgbColor;
#else
	o_rgbaColor.rgb = RgbTonemap(rgbColor);
#endif

	// Vignette

	o_rgbaColor.rgb *= 1.0 - smoothstep(0.8, 2.6, length((xyPixel.xy / iResolution.xy) * 2.0 - 1.0));

	// Noise to reduce banding

	o_rgbaColor.rgb += (g_vecURandomIS.x - 0.5) / 255.0;

	o_rgbaColor.a = 1.0;
}


 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
