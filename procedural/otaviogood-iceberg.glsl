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

/*--------------------------------------------------------------------------------------
License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
----------------------------------------------------------------------------------------
^ This means do ANYTHING YOU WANT with this code. Because we are programmers, not lawyers.
-Otavio Good
*/

// ---------------- Config ----------------
// This is an option that lets you render high quality frames for screenshots. It enables
// stochastic antialiasing and motion blur automatically for any shader.
//#define NON_REALTIME_HQ_RENDER
const float frameToRenderHQ = 15.1; // Time in seconds of frame to render
const float antialiasingSamples = 16.0; // 16x antialiasing - too much might make the shader compiler angry.

//#define MANUAL_CAMERA
// Some computers were crashing, so I scaled this down by default.
//#define HQ_NOISE

// --------------------------------------------------------
// These variables are for the non-realtime block renderer.
float localTime = 0.0;
float seed = 1.0;

// Animation variables
float fade = 1.0;
float exposure = 1.0;

// lighting vars
vec3 sunDir = normalize(vec3(0.93, 1.0, 1.0));
const vec3 sunCol = vec3(250.0, 220.0, 200.0) / 3555.0;
const vec3 horizonCol = vec3(0.95, 0.95, 0.95)*1.3;
const vec3 skyCol = vec3(0.03,0.45,0.95);
const vec3 groundCol = vec3(0.003,0.7,0.75);

// ---- noise functions ----
float v31(vec3 a)
{
    return a.x + a.y * 37.0 + a.z * 521.0;
}
float v21(vec2 a)
{
    return a.x + a.y * 37.0;
}
float Hash11(float a)
{
    return fract(sin(a)*10403.9);
}
float Hash21(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}
vec2 Hash22(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(cos(f)*vec2(10003.579, 37049.7));
}
vec2 Hash12(float f)
{
    return fract(cos(f)*vec2(10003.579, 37049.7));
}
// noise functions
float Hash2d(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}
float Hash3d(vec3 uv)
{
    float f = uv.x + uv.y * 37.0 + uv.z * 521.0;
    return fract(sin(f)*110003.9);
}
float mixP(float f0, float f1, float a)
{
    return mix(f0, f1, a*a*(3.0-2.0*a));
}
const vec2 zeroOne = vec2(0.0, 1.0);
float noise1d(float uv)
{
    float fr = fract(uv);
    float fl = floor(uv);
    float h0 = Hash11(fl);
    float h1 = Hash11(fl + 1.0);
    return mixP(h0, h1, fr);
}
float noise2d(vec2 uv)
{
    vec2 fr = fract(uv.xy);
    vec2 fl = floor(uv.xy);
    float h00 = Hash2d(fl);
    float h10 = Hash2d(fl + zeroOne.yx);
    float h01 = Hash2d(fl + zeroOne);
    float h11 = Hash2d(fl + zeroOne.yy);
    return mixP(mixP(h00, h10, fr.x), mixP(h01, h11, fr.x), fr.y);
}
float noiseValue(vec3 uv)
{
    vec3 fr = fract(uv.xyz);
    vec3 fl = floor(uv.xyz);
    float h000 = Hash3d(fl);
    float h100 = Hash3d(fl + zeroOne.yxx);
    float h010 = Hash3d(fl + zeroOne.xyx);
    float h110 = Hash3d(fl + zeroOne.yyx);
    float h001 = Hash3d(fl + zeroOne.xxy);
    float h101 = Hash3d(fl + zeroOne.yxy);
    float h011 = Hash3d(fl + zeroOne.xyy);
    float h111 = Hash3d(fl + zeroOne.yyy);
    return mixP(
        mixP(mixP(h000, h100, fr.x),
             mixP(h010, h110, fr.x), fr.y),
        mixP(mixP(h001, h101, fr.x),
             mixP(h011, h111, fr.x), fr.y)
        , fr.z);
}


const float PI=3.14159265;

vec3 saturate(vec3 a) { return clamp(a, 0.0, 1.0); }
vec2 saturate(vec2 a) { return clamp(a, 0.0, 1.0); }
float saturate(float a) { return clamp(a, 0.0, 1.0); }

vec3 RotateX(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(v.x, cos * v.y + sin * v.z, -sin * v.y + cos * v.z);
}
vec3 RotateY(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(cos * v.x - sin * v.z, v.y, sin * v.x + cos * v.z);
}
vec3 RotateZ(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(cos * v.x + sin * v.y, -sin * v.x + cos * v.y, v.z);
}

// This function basically is a procedural environment map that makes the sun
vec3 GetSunColorSmall(vec3 rayDir, vec3 sunDir)
{
	vec3 localRay = normalize(rayDir);
	float dist = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5);
	float sunIntensity = 0.05 / dist;
    sunIntensity += exp(-dist*150.0)*7000.0;
	sunIntensity = min(sunIntensity, 40000.0);
	return sunCol * sunIntensity*0.2;
}

vec3 GetEnvMap(vec3 rayDir, vec3 sunDir)
{
    // fade the sky color, multiply sunset dimming
    vec3 finalColor = mix(horizonCol, skyCol, pow(saturate(rayDir.y), 0.47))*0.95;
    // make clouds - just a horizontal plane with noise
    float n = noise2d(rayDir.xz/rayDir.y*1.0);
    n += noise2d(rayDir.xz/rayDir.y*2.0)*0.5;
    n += noise2d(rayDir.xz/rayDir.y*4.0)*0.25;
    n += noise2d(rayDir.xz/rayDir.y*8.0)*0.125;
    n = pow(abs(n), 3.0);
    n = mix(n * 0.2, n, saturate(abs(rayDir.y * 8.0)));  // fade clouds in distance
    finalColor = mix(finalColor, (vec3(1.0)+sunCol*10.0)*0.75*saturate((rayDir.y+0.2)*5.0), saturate(n*0.125));

    // add the sun
    finalColor += GetSunColorSmall(rayDir, sunDir);
    return finalColor;
}

// min function that supports materials in the y component
vec2 matmin(vec2 a, vec2 b)
{
    if (a.x < b.x) return a;
    else return b;
}

// ---- shapes defined by distance fields ----
// See this site for a reference to more distance functions...
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

// signed box distance field
float sdBox(vec3 p, vec3 radius)
{
  vec3 dist = abs(p) - radius;
  return min(max(dist.x, max(dist.y, dist.z)), 0.0) + length(max(dist, 0.0));
}

float cyl(vec3 p, float rad)
{
    return length(p.xy) - rad;
}

float sSphere(vec3 p, float rad)
{
    return length(p) - rad;
}

// k should be negative. -4.0 works nicely.
// smooth blending function
float smin(float a, float b, float k)
{
	return log2(exp2(k*a)+exp2(k*b))/k;
}

const float sway = 0.015;

// This is the distance function that defines all the scene's geometry.
// The input is a position in space.
// The output is the distance to the nearest surface, a material index,
// and the difference between the iceberg distance and the water distance.
vec3 DistanceToObject(vec3 p)
{
    float dist = p.y;

    if (abs(dist) < 0.07)  // Only calculate noise if we are close.
    {
        // Sum up different frequencies of noise to make water waves.
        float waterNoise = noise2d(p.xz*4.0+localTime)*0.1 +
            noise2d(p.xz*8.0+localTime)*0.03 +
            noise2d(p.xz*16.0-localTime)*0.015 +
            noise2d(p.xz*32.0-localTime)*0.005 +
            noise2d(p.xz*64.0-localTime)*0.002;
        // Fade the waves a bit in the distance.
    	dist += waterNoise * 0.2 * saturate(8.0/length(p.xz));
    }
    vec2 water = vec2(dist, 1.0);

    p = RotateZ(p, sin(localTime)*sway);
    // Sculpt the iceberg.
    float slant = (p.y + p.x*0.25) / 1.0307;
    slant -= cos(p.z*2.0)*0.0625;
    dist = sSphere(p, 2.0) + sin(p.z*4.0)*0.125;
    dist = smin(dist, sSphere(p + vec3(1.0, 11.85, 0.0), 12.0), -5.0);
    float chop = cyl(p.xzy + vec3(1.5), 1.5);
    float chop2 = cyl(p.xyz + vec3(0.0, -0.5, 0.0), 0.6) + sin(p.z*2.0)*0.125;
    chop2 = min(chop2, -slant + 1.6);
    chop2 = min(chop2, sdBox(p + vec3(-1.75, -0.74, -2.0), vec3(0.7)));
    chop = smin(chop, chop2, -10.0);
    chop = min(chop, chop2);
    dist = -smin(-dist, chop, -30.0);
    if (abs(dist) < 0.5)  // Only calculate noise if we are close.
    {
    	//dist += noise1d(slant*4.0+1.333)*0.1 + noise1d(slant*8.0+1.333)*0.05;
    	dist += noiseValue(vec3(slant)*4.0)*0.1 + noiseValue(vec3(slant)*8.0)*0.05;
        float snowNoise=0.0;
   		snowNoise = noiseValue(p*4.0)*0.5*0.5;
   		snowNoise += noiseValue(p*8.0)*0.125*0.25;
        // prevent crashing on mac/chrome/nvidia
#ifdef HQ_NOISE
   		snowNoise += noiseValue(p*16.0)*0.125*0.0625;
   		snowNoise += noiseValue(p*32.0)*0.0625*0.0625;
#endif
        //snowNoise -= abs(fract(p.z*0.5-p.y*0.05)-0.5)*2.0;
        //snowNoise -= 0.95;
        dist += snowNoise*0.25;
    }
    vec2 iceberg = vec2(dist, 0.0);
    vec2 distAndMat = matmin(water, iceberg);
    return vec3(distAndMat, water.x - iceberg.x);
}

vec3 TraceOneRay(vec3 camPos, vec3 rayVec, out vec3 normal, out vec3 distAndMat, out float t) {
    normal = vec3(0.0);
    distAndMat = vec3(0.0, -1.0, 1000.0);  // Distance and material
    vec3 finalColor = vec3(0.0);
	// ----------------------------- Ray march the scene ------------------------------
	t = 0.0;
	const float maxDepth = 32.0; // farthest distance rays will travel
	vec3 pos = vec3(0.0);
    const float smallVal = 0.00625;
	// ray marching time
    for (int i = 210; i >= 0; i--)	// This is the count of the max times the ray actually marches.
    {
        // Step along the ray.
        pos = (camPos + rayVec * t);
        // This is _the_ function that defines the "distance field".
        // It's really what makes the scene geometry. The idea is that the
        // distance field returns the distance to the closest object, and then
        // we know we are safe to "march" along the ray by that much distance
        // without hitting anything. We repeat this until we get really close
        // and then break because we have effectively hit the object.
        distAndMat = DistanceToObject(pos);

        // move down the ray a safe amount
        t += distAndMat.x;
        if (i == 0) t = maxDepth+0.01;
        // If we are very close to the object, let's call it a hit and exit this loop.
        if ((t > maxDepth) || (abs(distAndMat.x) < smallVal)) break;
    }

	// --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this geometry.
	// If a ray actually hit the object, let's light it.
    if (t <= maxDepth)
	{
        float dist = distAndMat.x;
        // calculate the normal from the distance field. The distance field is a volume, so if you
        // sample the current point and neighboring points, you can use the difference to get
        // the normal.
        vec3 smallVec = vec3(smallVal, 0, 0);
        vec3 normalU = vec3(dist - DistanceToObject(pos - smallVec.xyy).x,
                           dist - DistanceToObject(pos - smallVec.yxy).x,
                           dist - DistanceToObject(pos - smallVec.yyx).x);
        normal = normalize(normalU);

        // Giant hack for border between water and snow to look nice.
        if (abs(distAndMat.z) < smallVal*0.25) normal = vec3(0.0, 0.2, 0.0);

        // calculate 2 ambient occlusion values. One for global stuff and one
        // for local stuff
        float ambientS = 1.0;
        vec3 distAndMatA = DistanceToObject(pos + normal * 0.4);
        ambientS *= saturate(distAndMatA.x*2.5);
        distAndMatA = DistanceToObject(pos + normal * 0.8);
        ambientS *= saturate(distAndMatA.x*1.25);
        float ambient = ambientS;
        ambient *= saturate(DistanceToObject(pos + normal * 1.6).x*1.25*0.5);
        ambient *= saturate(DistanceToObject(pos + normal * 3.2).x*1.25*0.25);
        //ambient = max(0.05, pow(ambient, 0.5));	// tone down ambient with a pow and min clamp it.
        ambient = max(0.15, ambient);
        ambient = saturate(ambient);

        // Trace a ray toward the sun for sun shadows
        float sunShadow = 1.0;
        float iter = 0.2;
		for (int i = 0; i < 10; i++)
        {
            float tempDist = DistanceToObject(pos + sunDir * iter).x;
	        sunShadow *= saturate(tempDist*10.0);
            if (tempDist <= 0.0) break;
            //iter *= 1.5;	// constant is more reliable than distance-based
            iter += max(0.1, tempDist)*1.2;
        }
        sunShadow = saturate(sunShadow);

        // Trace a ray through the solid for sub-surface scattering
        float scattering = 1.0;
        iter = 0.05;
		for (int i = 0; i < 8; i++)
        {
            float tempDist = -DistanceToObject(pos - normal * iter).x;
	        scattering *= saturate(tempDist*10.0);
            if (tempDist <= 0.0) break;
            //iter *= 1.5;	// constant is more reliable than distance-based
            iter += max(0.001, tempDist);//*0.6;
        }
        scattering = saturate(scattering);
        //scattering = (1.0-sunShadow)*(1.0-length(sunDir * iter));
        scattering = saturate(1.0-iter);

        // calculate the reflection vector for highlights
        vec3 ref = reflect(rayVec, normal);

        // ------ Calculate texture color  ------
        vec3 texColor = vec3(0.0);
        // Underwater green glow
        float fade = 1.0-saturate(abs(distAndMat.z)*3.5);
        vec3 greenFade = mix(vec3(0.1, 0.995, 0.65)*0.95, vec3(0.75, 1.0, 1.0), fade*fade);
        texColor += greenFade * fade;
        texColor *= 0.75;
        // iceberg
        if (distAndMat.y == 0.0) {
            texColor = vec3(1.0);
        }
        texColor = saturate(texColor);

        // ------ Calculate lighting color ------
        // Start with sun color, standard lighting equation, and shadow
        vec3 lightColor = vec3(14.0)*sunCol * saturate(dot(sunDir, normal)) * (sunShadow*0.7+0.3);
        // weighted average the near ambient occlusion with the far for just the right look

        // apply the light to the texture.
        finalColor = texColor * lightColor;
        vec3 underwaterGlow = vec3(0.002, 0.6, 0.51);
        // water
        if (distAndMat.y == 1.0) {
	        finalColor += underwaterGlow*0.25 * length(normalU)*80.0;
	        finalColor += vec3(0.02, 0.5, 0.71)*0.35 * saturate(1.0-ambient);
            finalColor += skyCol*0.02 * ambientS;
        }
        // iceberg
        if (distAndMat.y == 0.0) {
            float fade = saturate(1.0-pos.y);
	        // Add sky color
            finalColor += (skyCol*0.6 + horizonCol*0.4)*1.5 * saturate(normal.y *0.5+0.5);
			vec3 rotPos = RotateZ(pos, sin(localTime)*sway);
            float noiseScatter = noiseValue(rotPos*32.0)*0.25 +
                noiseValue(rotPos*16.0)*0.5 +
                noiseValue(rotPos*8.0)*1.0;
	        finalColor += groundCol * 0.5 * max(-normal.y*0.5+0.5, 0.0) * (noiseScatter*0.3+0.6);
            finalColor += underwaterGlow * 0.35 * saturate(0.5-saturate(abs(pos.y*3.0)));
            finalColor += vec3(0.01, 0.55, 0.7) * saturate(scattering-sunShadow*0.3)*0.25;
            finalColor = mix((underwaterGlow + vec3(0.5, 0.9, 0.8))*0.5, finalColor, saturate(distAndMat.z*64.0)*0.75+0.25);
            finalColor *= 0.7;
        }

        // visualize length of gradient of distance field to check distance field correctness
        //finalColor = vec3(0.5) * (length(normalU) / smallVec.x);
	}
    else
    {
        // Our ray trace hit nothing, so draw background.
        finalColor = GetEnvMap(rayVec, sunDir);
        distAndMat.y = -1.0;
    }
    return finalColor;
}

// Input is UV coordinate of pixel to render.
// Output is RGB color.
vec3 RayTrace(in vec2 fragCoord )
{
    fade = 1.0;

	vec3 camPos, camUp, camLookat;
	// ------------------- Set up the camera rays for ray marching --------------------
    // Map uv to [-1.0..1.0]
	vec2 uv = fragCoord.xy/iResolution.xy * 2.0 - 1.0;
    uv /= 2.0;  // zoom in

#ifdef MANUAL_CAMERA
    // Camera up vector.
	camUp=vec3(0,1,0);

	// Camera lookat.
	camLookat=vec3(0,0,0);

    // debugging camera
    float mx=-iMouse.x/iResolution.x*PI*2.0;
	float my=iMouse.y/iResolution.y*3.14*0.95 + PI/2.0;
	camPos = vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*5.0;
#else
    // Do the camera fly-by animation and different scenes.
    // Time variables for start and end of each scene
    const float t0 = 0.0;
    const float t1 = 12.0;
    const float t2 = 20.0;
    const float t3 = 38.0;
    // Repeat the animation after time t3
    localTime = fract(localTime / t3) * t3;
    if (localTime < t1)
    {
        float time = localTime - t0;
        float alpha = time / (t1 - t0);
        fade = saturate(time);
        fade *= saturate(t1 - localTime);
        camPos = vec3(0.0, 0.4, -8.0);
        camPos.x -= smoothstep(0.0, 1.0, alpha) * 2.0;
        camPos.y += smoothstep(0.0, 1.0, alpha) * 2.0;
        camPos.z += smoothstep(0.0, 1.0, alpha) * 4.0;
        camUp=vec3(0,1,0);
        camLookat=vec3(0,-0.5,0.5);
        camLookat.y -= smoothstep(0.0, 1.0, alpha) * 0.5;
    } else if (localTime < t2)
    {
        float time = localTime - t1;
        float alpha = time / (t2 - t1);
        fade = saturate(time);
        fade *= saturate(t2 - localTime);
        camPos = vec3(2.0, 4.3, -0.5);
        camPos.y -= alpha * 3.5;
        camPos.x = sin(alpha*1.0) * 9.2;
        camPos.z = cos(alpha*1.0) * 6.2;
        camUp=normalize(vec3(0,1,-0.005 + alpha * 0.005));
        camLookat=vec3(0,-1.5,0.0);
        camLookat.y += smoothstep(0.0, 1.0, alpha) * 1.5;
    } else if (localTime < t3)
    {
        float time = localTime - t2;
        float alpha = time / (t3 - t2);
        fade = saturate(time);
        fade *= saturate(t3 - localTime);
        camPos = vec3(-9.0, 1.3, -10.0);
        //camPos.y -= alpha * 8.0;
        camPos.x += alpha * 14.0;
        camPos.z += alpha * 7.0;
        camUp=normalize(vec3(0,1,0.0));
        camLookat=vec3(0.0,0.0,0.0);
    }
#endif

	// Camera setup for ray tracing / marching
	vec3 camVec=normalize(camLookat - camPos);
	vec3 sideNorm=normalize(cross(camUp, camVec));
	vec3 upNorm=cross(camVec, sideNorm);
	vec3 worldFacing=(camPos + camVec);
	vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;
	vec3 rayVec = normalize(worldPix - camPos);

	vec3 finalColor = vec3(0.0);

    vec3 normal;
    vec3 distAndMat;
    float t;
    finalColor = TraceOneRay(camPos, rayVec, normal, distAndMat, t);
    float origDelta = distAndMat.z;
    if (distAndMat.y == 1.0) {
        vec3 ref = normalize(reflect(rayVec, normal));
        ref.y = abs(ref.y);
        vec3 newStartPos = (camPos + rayVec * t) + normal * 0.02; // nudge away.
        float fresnel = saturate(1.0 - dot(-rayVec, normal));
        fresnel = fresnel * fresnel * fresnel * fresnel * fresnel * fresnel;
        fresnel = mix(0.05, 0.9, fresnel);
        vec3 refColor = TraceOneRay(newStartPos, ref, normal, distAndMat, t);
	    finalColor += refColor * fresnel;
    }

    // vignette?
    finalColor *= vec3(1.0) * saturate(1.0 - length(uv/2.5));
    finalColor *= exposure;

	// output the final color without gamma correction - will do gamma later.
	return vec3(clamp(finalColor, 0.0, 1.0));//*saturate(fade));
}

#ifdef NON_REALTIME_HQ_RENDER
// This function breaks the image down into blocks and scans
// through them, rendering 1 block at a time. It's for non-
// realtime things that take a long time to render.

// This is the frame rate to render at. Too fast and you will
// miss some blocks.
const float blockRate = 20.0;
void BlockRender(in vec2 fragCoord)
{
    // blockSize is how much it will try to render in 1 frame.
    // adjust this smaller for more complex scenes, bigger for
    // faster render times.
    const float blockSize = 64.0;
    // Make the block repeatedly scan across the image based on time.
    float frame = floor(iGlobalTime * blockRate);
    vec2 blockRes = floor(iResolution.xy / blockSize) + vec2(1.0);
    // ugly bug with mod.
    //float blockX = mod(frame, blockRes.x);
    float blockX = fract(frame / blockRes.x) * blockRes.x;
    //float blockY = mod(floor(frame / blockRes.x), blockRes.y);
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
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
#ifdef NON_REALTIME_HQ_RENDER
    // Optionally render a non-realtime scene with high quality
    BlockRender(fragCoord);
#endif

    // Do a multi-pass render
    vec3 finalColor = vec3(0.0);
#ifdef NON_REALTIME_HQ_RENDER
    for (float i = 0.0; i < antialiasingSamples; i++)
    {
        const float motionBlurLengthInSeconds = 1.0 / 60.0;
        // Set this to the time in seconds of the frame to render.
	    localTime = frameToRenderHQ;
        // This line will motion-blur the renders
        localTime += Hash11(v21(fragCoord + seed)) * motionBlurLengthInSeconds;
        // Jitter the pixel position so we get antialiasing when we do multiple passes.
        vec2 jittered = fragCoord.xy + vec2(
            Hash21(fragCoord + seed),
            Hash21(fragCoord*7.234567 + seed)
            );
        // don't antialias if only 1 sample.
        if (antialiasingSamples == 1.0) jittered = fragCoord;
        // Accumulate one pass of raytracing into our pixel value
	    finalColor += RayTrace(jittered);
        // Change the random seed for each pass.
	    seed *= 1.01234567;
    }
    // Average all accumulated pixel intensities
    finalColor /= antialiasingSamples;
#else
    // Regular real-time rendering
    localTime = iGlobalTime;
    finalColor = RayTrace(fragCoord);
#endif

    fragColor = vec4(sqrt(clamp(finalColor, 0.0, 1.0)),1.0);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
