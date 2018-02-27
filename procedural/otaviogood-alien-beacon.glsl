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
-Otavio Good
*/

// The noise function in this was inspired by IQ's "Terrain Tubes" shader. I never really figured out
// his function completely, so I'm not sure of the exact similarities. It's nice though because it
// works the same on all computers (I think). It's not based on a hash that changes from computer to 
// computer. That means I can finally rely on the terrain being the same and make a camera path. :)
// It's also a much faster noise function, although it can look a bit repetitive.

#define MOTION_BLUR
#define MOVING_SUN

float Hash2d(vec2 uv)
{
    float f = uv.x + uv.y * 47.0;
    return fract(cos(f*3.333)*100003.9);
}
float Hash3d(vec3 uv)
{
    float f = uv.x + uv.y * 37.0 + uv.z * 521.0;
    return fract(cos(f*3.333)*100003.9);
}

float PI=3.14159265;

vec3 saturate(vec3 a) { return clamp(a, 0.0, 1.0); }
vec2 saturate(vec2 a) { return clamp(a, 0.0, 1.0); }
float saturate(float a) { return clamp(a, 0.0, 1.0); }

vec3 RotateX(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  //if (RIGHT_HANDED_COORD)
  return vec3(v.x, cos * v.y + sin * v.z, -sin * v.y + cos * v.z);
  //else return new float3(x, cos * y - sin * z, sin * y + cos * z);
}
vec3 RotateY(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  //if (RIGHT_HANDED_COORD)
  return vec3(cos * v.x - sin * v.z, v.y, sin * v.x + cos * v.z);
  //else return new float3(cos * x + sin * z, y, -sin * x + cos * z);
}
vec3 RotateZ(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  //if (RIGHT_HANDED_COORD)
  return vec3(cos * v.x + sin * v.y, -sin * v.x + cos * v.y, v.z);
}


// This function basically is a procedural environment map that makes the sun
vec3 sunCol = vec3(258.0, 208.0, 100.0) / 4255.0;//unfortunately, i seem to have 2 different sun colors. :(
vec3 GetSunColorReflection(vec3 rayDir, vec3 sunDir)
{
	vec3 localRay = normalize(rayDir);
	float dist = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5);
	float sunIntensity = 0.015 / dist;
	sunIntensity = pow(sunIntensity, 0.3)*100.0;

    sunIntensity += exp(-dist*12.0)*300.0;
	sunIntensity = min(sunIntensity, 40000.0);
	return sunCol * sunIntensity*0.0425;
}
vec3 GetSunColorSmall(vec3 rayDir, vec3 sunDir)
{
	vec3 localRay = normalize(rayDir);
	float dist = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5);
	float sunIntensity = 0.05 / dist;
    sunIntensity += exp(-dist*12.0)*300.0;
	sunIntensity = min(sunIntensity, 40000.0);
	return sunCol * sunIntensity*0.025;
}

// This is a spline used for the camera path
vec4 CatmullRom(vec4 p0, vec4 p1, vec4 p2, vec4 p3, float t)
{
    float t2 = t*t;
    float t3 = t*t*t;
    return 0.5 *((2.0 * p1) +
                 (-p0 + p2) * t +
    			 (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
    			 (-p0 + 3.0 * p1- 3.0 * p2 + p3) * t3);
}

// This spiral noise works by successively adding and rotating sin waves while increasing frequency.
// It should work the same on all computers since it's not based on a hash function like some other noises.
// It can be much faster than other noise functions if you're ok with some repetition.
const float nudge = 0.739513;	// size of perpendicular vector
float normalizer = 1.0 / sqrt(1.0 + nudge*nudge);	// pythagorean theorem on that perpendicular to maintain scale
float SpiralNoiseC(vec3 p)
{
    float n = 0.0;	// noise amount
    float iter = 1.0;
    for (int i = 0; i < 8; i++)
    {
        // add sin and cos scaled inverse with the frequency
        n += -abs(sin(p.y*iter) + cos(p.x*iter)) / iter;	// abs for a ridged look
        // rotate by adding perpendicular and scaling down
        p.xy += vec2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        // rotate on other axis
        p.xz += vec2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        // increase the frequency
        iter *= 1.733733;
    }
    return n;
}
float SpiralNoiseD(vec3 p)
{
    float n = 0.0;
    float iter = 1.0;
    for (int i = 0; i < 6; i++)
    {
        n += abs(sin(p.y*iter) + cos(p.x*iter)) / iter;	// abs for a ridged look
        p.xy += vec2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        p.xz += vec2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        iter *= 1.733733;
    }
    return n;
}
float SpiralNoise3D(vec3 p)
{
    float n = 0.0;
    float iter = 1.0;
    for (int i = 0; i < 5; i++)
    {
        n += (sin(p.y*iter) + cos(p.x*iter)) / iter;
        //p.xy += vec2(p.y, -p.x) * nudge;
        //p.xy *= normalizer;
        p.xz += vec2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        iter *= 1.33733;
    }
    return n;
}

// These are the xyz camera positions and a left/right facing angle relative to the path line
// I think webgl glsl can only access arrays using a constant, so I'm writing all these out.
// Someone please tell me if I'm wrong.
vec4 c00 = vec4(3.5, 2.0, 13.1, 0.0);	// start point
vec4 c01 = vec4(12.5, 2.2, 17.0, 0.0);	// run up to canyon 2 before hole in large rock face
vec4 c02 = vec4(21.5, 4.0, 8.1, 0.0);	// canyon 2 before hole in large rock face
vec4 c03 = vec4(21.0, 5.0, 1.1, -0.5);	// before hole in large rock face
vec4 c04 = vec4(17.8, 5.4, -0.2, 0.0);	// hole in large rock face
vec4 c05 = vec4(14.7, 2.5, 1.4, 0.0);	// after hole in large rock face
vec4 c06 = vec4(7.9, 2.3, -2.1, 0.0);
vec4 c07 = vec4(0.5, -0.7, -3.5, 1.0);
vec4 c08 = vec4(-3.0, -1.0, -3.5, 1.3);
vec4 c09 = vec4(-3.5, -1.0, 4.0, 1.3);
vec4 c10 = vec4(3.0, -0.7, 3.3, 0.8);
vec4 c11 = vec4(3.5, -1.0, -4.75, 0.0);
vec4 c12 = vec4(-6.0, -0.2, 1.0, 3.14);
vec4 c13 = vec4(-6.0, -1.0, 5.5, 0.0);

vec4 cXX = vec4(0.0, 3.0, 0.0, 0.0);

float camPathOffset = 0.0;	// where to start on the camera path - parametric t var for catmull-rom spline
vec3 camPos = vec3(0.0), camFacing;
vec3 camLookat=vec3(0,0.0,0);
float waterLevel = 1.5;
// from a time t, this finds where in the camera path you are.
// It uses Catmull-Rom splines
vec4 CamPos(float t)
{
    t = mod(t, 14.0);	// repeat after 14 time units
    float bigTime = floor(t);
    float smallTime = fract(t);
    // Can't do arrays right, so write this all out.
    if (bigTime == 0.0) return CatmullRom(c00, c01, c02, c03, smallTime);
    if (bigTime == 1.0) return CatmullRom(c01, c02, c03, c04, smallTime);
    if (bigTime == 2.0) return CatmullRom(c02, c03, c04, c05, smallTime);
    if (bigTime == 3.0) return CatmullRom(c03, c04, c05, c06, smallTime);
    if (bigTime == 4.0) return CatmullRom(c04, c05, c06, c07, smallTime);
    if (bigTime == 5.0) return CatmullRom(c05, c06, c07, c08, smallTime);
    if (bigTime == 6.0) return CatmullRom(c06, c07, c08, c09, smallTime);

    if (bigTime == 7.0) return CatmullRom(c07, c08, c09, c10, smallTime);
    if (bigTime == 8.0) return CatmullRom(c08, c09, c10, c11, smallTime);
    if (bigTime == 9.0) return CatmullRom(c09, c10, c11, c12, smallTime);
    if (bigTime == 10.0) return CatmullRom(c10, c11, c12, c13, smallTime);
    if (bigTime == 11.0) return CatmullRom(c11, c12, c13, c00, smallTime);
    if (bigTime == 12.0) return CatmullRom(c12, c13, c00, c01, smallTime);
    if (bigTime == 13.0) return CatmullRom(c13, c00, c01, c02, smallTime);
    return vec4(0.0);
}

float DistanceToObject(vec3 p)
{
	float final = p.y + 4.5;
    final -= SpiralNoiseC(p.xyz);	// mid-range noise
    final += SpiralNoiseC(p.zxy*0.123+100.0)*3.0;	// large scale terrain features
    final -= SpiralNoise3D(p);	// more large scale features, but 3d, so not just a height map.
    final -= SpiralNoise3D(p*49.0)*0.0625*0.125;	// small scale noise for variation
	final = min(final, length(p) - 1.99);	// sphere in center
    final = min(final, p.y + waterLevel);	// water
	//final = min(final, length(p-camLookat) - 0.3);
    return final;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// ---------------- First, set up the camera rays for ray marching ----------------
	vec2 uv = fragCoord.xy/iResolution.xy * 2.0 - 1.0;

	// Camera up vector.
	vec3 camUp=vec3(0,1,0); // vuv

	// Camera lookat.
	camLookat=vec3(0,0.0,0);	// vrp

/*    if (iGlobalTime == 0.0)	// for debugging with manual camera
    {
        camPos = cXX.xyz;
        camLookat = vec3(0.0)*cXX.xyz;
    }*/

    // debugging camera
#ifdef MOUSE
    float mx=iMouse.x/iResolution.x*PI*2.0;// + iGlobalTime * 0.1;
	float my=-iMouse.y/iResolution.y*10.0;// + sin(iGlobalTime * 0.3)*0.2+0.2;//*PI/2.01;
#else
    float mx=0.0/iResolution.x*PI*2.0;// + iGlobalTime * 0.1;
	float my=-0.0/iResolution.y*10.0;// + sin(iGlobalTime * 0.3)*0.2+0.2;//*PI/2.01;
#endif
	camPos += vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*(5.2); 	// prp

    // set time for moving camera along path
    float timeLine = iGlobalTime*0.2 + camPathOffset;
    camFacing = camLookat + camPos;
    // without this if condition, the mac doesn't work. mysterious. :(
    if (iGlobalTime != -1.0)
    {
        vec4 catmullA = CamPos(timeLine);
        // get a smoother derivative even though the spline is not C2 continuous.
        // Also look ahead a bit so the camera leads the motion
        vec4 catmullB = CamPos(timeLine + 0.3);
#ifdef MOTION_BLUR
        vec4 catmullC = CamPos(timeLine + 0.004);	// adjust for camera motion blur
        vec4 catmullBlur = mix(catmullA, catmullC, Hash2d(uv));	// motion blur along camera path
        camPos = catmullBlur.xyz;
        // face camera along derivate of motion path
        camFacing = normalize(catmullB.xyz - catmullA.xyz);
        // rotate camera based on w component of camera path vectors
        camFacing = RotateY(camFacing, -catmullBlur.w);
#else
        camPos = catmullA.xyz;
        // face camera along derivate of motion path
        camFacing = normalize(catmullB.xyz - catmullA.xyz);
        // rotate camera based on w component of camera path vectors
        camFacing = RotateY(camFacing, -catmullA.w);
#endif
        camFacing = RotateY(camFacing, -mx);
    	camLookat = camPos + camFacing;
    }


    // add randomness to camera for depth-of-field look close up.
    //camPos += vec3(Hash2d(uv)*0.91, Hash2d(uv+37.0), Hash2d(uv+47.0))*0.01;

	// Camera setup.
	vec3 camVec=normalize(camLookat - camPos);//vpn
	vec3 sideNorm=normalize(cross(camUp, camVec));	// u
	vec3 upNorm=cross(camVec, sideNorm);//v
	vec3 worldFacing=(camPos + camVec);//vcv
	vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;//scrCoord
	vec3 relVec = normalize(worldPix - camPos);//scp

	// --------------------------------------------------------------------------------
	float dist = 0.05;
	float t = 0.0;
	float inc = 0.02;
	float maxDepth = 110.0;
	vec3 pos = vec3(0,0,0);
	// ray marching time
    for (int i = 0; i < 200; i++)	// This is the count of the max times the ray actually marches.
    {
        if ((t > maxDepth) || (abs(dist) < 0.0075)) break;
        pos = camPos + relVec * t;
        // *******************************************************
        // This is _the_ function that defines the "distance field".
        // It's really what makes the scene geometry.
        // *******************************************************
        dist = DistanceToObject(pos);
        t += dist * 0.25;	// because deformations mess up distance function.
    }

	// --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this geometry.

#ifdef MOVING_SUN
	vec3 sunDir = normalize(vec3(sin(iGlobalTime*0.047-1.5), cos(iGlobalTime*0.047-1.5), -0.5));
#else
	vec3 sunDir = normalize(vec3(0.93, 1.0, -1.5));
#endif
    // This makes the sky fade at sunset
    float skyMultiplier = saturate(sunDir.y+0.7);
	vec3 finalColor = vec3(0.0);

	// If a ray actually hit the object, let's light it.
	if (abs(dist) < 0.75)
    //if (t <= maxDepth)
	{
        // calculate the normal from the distance field. The distance field is a volume, so if you
        // sample the current point and neighboring points, you can use the difference to get
        // the normal.
        vec3 smallVec = vec3(0.005, 0, 0);
        vec3 normal = vec3(dist - DistanceToObject(pos - smallVec.xyy),
                           dist - DistanceToObject(pos - smallVec.yxy),
                           dist - DistanceToObject(pos - smallVec.yyx));

        /*if (pos.y <= waterLevel-2.995)	// water waves?
        {
            normal += SpiralNoise3D(pos*32.0+vec3(iGlobalTime*8.0,0.0,0.0))*0.0001;
            normal += SpiralNoise3D(pos*27.0+vec3(0.0,0.0, iGlobalTime* 10.333))*0.0001;
            normal += SpiralNoiseD(pos*37.0+vec3(0.0,iGlobalTime* 14.333,0.0))*0.0002;
        }*/
        normal = normalize(normal);

        // calculate 2 ambient occlusion values. One for global stuff and one
        // for local stuff - so the green sphere light source can also have ambient.
        float ambientS = 1.0;
        //ambient *= saturate(DistanceToObject(pos + normal * 0.1)*10.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.2)*5.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.4)*2.5);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.8)*1.25);
        float ambient = ambientS * saturate(DistanceToObject(pos + normal * 1.6)*1.25*0.5);
        ambient *= saturate(DistanceToObject(pos + normal * 3.2)*1.25*0.25);
        ambient *= saturate(DistanceToObject(pos + normal * 6.4)*1.25*0.125);
        //ambient = max(0.05, pow(ambient, 0.3));	// tone down ambient with a pow and min clamp it.
        ambient = saturate(ambient);

        // Trace a ray toward the sun for sun shadows
        float sunShadow = 1.0;
        float iter = 0.2;
		for (int i = 0; i < 10; i++)
        {
            float tempDist = DistanceToObject(pos + sunDir * iter);
	        sunShadow *= saturate(tempDist*10.0);
            if (tempDist <= 0.0) break;
            iter *= 1.5;	// constant is more reliable than distance-based
            //iter += max(0.2, tempDist)*1.2;
        }
        float sunSet = saturate(sunDir.y*4.0); // sunset dims the sun
        sunShadow = saturate(sunShadow) * sunSet;

        // calculate the reflection vector for highlights
        vec3 ref = reflect(relVec, normal);

        // pulse the ball light source
        vec3 ballGlow = vec3(0.1, 0.97, 0.1) * abs(SpiralNoise3D(vec3(iGlobalTime*1.3)));

        // ------ Calculate texture color of the rock ------
        // basic orange and white blended together with noise
        vec3 texColor = mix(vec3(0.95, 1.0, 1.0),  vec3(0.9, 0.7, 0.5), pow(abs(SpiralNoise3D(pos*1.0)-1.0), 0.6) );
        // make the undersides darker greenish
        texColor = mix(vec3(0.2, 0.2, 0.1), texColor, saturate(normal.y));
        // fade to reddish/orange closer to the water level
        texColor = mix(texColor, vec3(0.64, 0.2, 0.1) , saturate(-0.4-pos.y));
        // some more variation to the color vertically
        texColor = mix(texColor, vec3(0.2, 0.13, 0.02) , pow(saturate(pos.y*0.125+0.5), 2.0));
        // give the rock a stratified, layered look
        float rockLayers = abs(cos(pos.y*1.5+ SpiralNoiseD(pos*vec3(1.0, 2.0, 1.0)*4.0)*0.2 ));
        texColor += vec3(0.7, 0.4, 0.3)*(1.0-pow(rockLayers, 0.3));

        // make the water orange. I'm trying for that "nickel tailings" look.
        texColor = mix(texColor, vec3(1.4, 0.15, 0.05) + SpiralNoise3D(pos)*0.025, saturate((-pos.y-1.45)*17.0));
        // make the sphere white
        if (length(pos) <= 2.01) texColor = vec3(1.0);
        // don't let it get too saturated or dark
        texColor = max(texColor, 0.05);

        // ------ Calculate lighting color ------
        // Start with sun color, standard lighting equation, and shadow
        vec3 lightColor = vec3(1.0, 0.75, 0.75) * saturate(dot(sunDir, normal)) * sunShadow*1.5;
        // sky color, hemisphere light equation approximation, anbient occlusion, sunset multiplier
        lightColor += vec3(1.0,0.3,0.6) * ( dot(sunDir, normal) * 0.5 + 0.5 ) * ambient * 0.25 * skyMultiplier;
        // Make the ball cast light. Distance to the 4th light falloff looked best. Use local ambient occlusion.
        float lp = length(pos) - 1.0;
        lightColor += ambientS*(ballGlow*1.2 * saturate(dot(normal, -pos)*0.5+0.5) / (lp*lp*lp*lp));

        // finally, apply the light to the texture.
        finalColor = texColor * lightColor;

        // Make the water reflect the sun (leaving out sky reflection for no good reason)
        vec3 refColor = GetSunColorReflection(ref, sunDir)*0.68;
        finalColor += refColor * sunShadow * saturate(normal.y*normal.y) * saturate(-(pos.y+1.35)*16.0);

        // make the ball itself glow
        finalColor += pow(saturate(1.0 - length(pos)*0.4925), 0.65) * ballGlow*6.1;
        // fog that fades to reddish plus the sun color so that fog is brightest towards sun
        finalColor = mix(vec3(1.0, 0.41, 0.41)*skyMultiplier + min(vec3(0.25),GetSunColorSmall(relVec, sunDir))*2.0*sunSet, finalColor, exp(-t*0.03));
	}
    else
    {
        // Our ray trace hit nothing, so draw sky.
        // fade the sky color, multiply sunset dimming
        finalColor = mix(vec3(1.0, 0.5, 0.5), vec3(0.40, 0.25, 0.91), saturate(relVec.y))*skyMultiplier;
        // add the sun
        finalColor += GetSunColorSmall(relVec, sunDir);// + vec3(0.1, 0.1, 0.1);
    }

    //finalColor = vec3(Hash2d(uv)*0.91,  Hash2d(uv+47.0)*0.91, 0.0);
    // vignette?
    finalColor *= vec3(1.0) * saturate(1.0 - length(uv/2.5));
    finalColor *= 1.3;

	// output the final color with sqrt for "gamma correction"
	fragColor = vec4(sqrt(clamp(finalColor, 0.0, 1.0)),1.0);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
