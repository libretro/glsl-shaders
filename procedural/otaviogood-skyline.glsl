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
const float frameToRenderHQ = 50.0; // Time in seconds of frame to render
const float antialiasingSamples = 16.0; // 16x antialiasing - too much might make the shader compiler angry.

//#define MANUAL_CAMERA


// --------------------------------------------------------
// These variables are for the non-realtime block renderer.
float localTime = 0.0;
float seed = 1.0;

// Animation variables
float fade = 1.0;
vec3 sunDir;
vec3 sunCol;
float exposure = 1.0;
vec3 skyCol, horizonCol;

// other
float marchCount = 0.0;

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
float Hash1d(float u)
{
    return fract(sin(u)*143.9);	// scale this down to kill the jitters
}
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
float noise(vec3 uv)
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

// This function basically is a procedural environment map that makes the sun
vec3 GetSunColorSmall(vec3 rayDir, vec3 sunDir)
{
	vec3 localRay = normalize(rayDir);
	float dist = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5);
	float sunIntensity = 0.05 / dist;
    sunIntensity += exp(-dist*150.0)*7000.0;
	sunIntensity = min(sunIntensity, 40000.0);
	return sunCol * sunIntensity*0.025;
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

vec3 GetEnvMapSkyline(vec3 rayDir, vec3 sunDir, float height)
{
    vec3 finalColor = GetEnvMap(rayDir, sunDir);

    // Make a skyscraper skyline reflection.
    float radial = atan(rayDir.z, rayDir.x)*4.0;
    float skyline = floor((sin(5.3456*radial) + sin(1.234*radial)+ sin(2.177*radial))*0.6);
    radial *= 4.0;
    skyline += floor((sin(5.0*radial) + sin(1.234*radial)+ sin(2.177*radial))*0.6)*0.1;
    float mask = saturate((rayDir.y*8.0 - skyline-2.5+height)*24.0);
    float vert = sign(sin(radial*32.0))*0.5+0.5;
    float hor = sign(sin(rayDir.y*256.0))*0.5+0.5;
    mask = saturate(mask + (1.0-hor*vert)*0.05);
    finalColor = mix(finalColor * vec3(0.1,0.07,0.05), finalColor, mask);

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

// capped cylinder distance field
float cylCap(vec3 p, float r, float lenRad)
{
    float a = length(p.xy) - r;
    a = max(a, abs(p.z) - lenRad);
    return a;
}

// k should be negative. -4.0 works nicely.
// smooth blending function
float smin(float a, float b, float k)
{
	return log2(exp2(k*a)+exp2(k*b))/k;
}

float Repeat(float a, float len)
{
    return mod(a, len) - 0.5 * len;
}

// Distance function that defines the car.
// Basically it's 2 boxes smooth-blended together and a mirrored cylinder for the wheels.
vec2 Car(vec3 baseCenter, float unique)
{
    // bottom box
    float car = sdBox(baseCenter + vec3(0.0, -0.008, 0.001), vec3(0.01, 0.00225, 0.0275));
    // top box smooth blended
    car = smin(car, sdBox(baseCenter + vec3(0.0, -0.016, 0.008), vec3(0.005, 0.0005, 0.01)), -160.0);
    // mirror the z axis to duplicate the cylinders for wheels
    vec3 wMirror = baseCenter + vec3(0.0, -0.005, 0.0);
    wMirror.z = abs(wMirror.z)-0.02;
    float wheels = cylCap((wMirror).zyx, 0.004, 0.0135);
    // Set materials
    vec2 distAndMat = vec2(wheels, 3.0);	// car wheels
    // Car material is some big number that's unique to each car
    // so I can have each car be a different color
    distAndMat = matmin(distAndMat, vec2(car, 100000.0 + unique));	// car
    return distAndMat;
}

// How much space between voxel borders and geometry for voxel ray march optimization
float voxelPad = 0.2;
// p should be in [0..1] range on xz plane
// pint is an integer pair saying which city block you are on
vec2 CityBlock(vec3 p, vec2 pint)
{
    // Get random numbers for this block by hashing the city block variable
    vec4 rand;
    rand.xy = Hash22(pint);
    rand.zw = Hash22(rand.xy);
    vec2 rand2 = Hash22(rand.zw);

    // Radius of the building
    float baseRad = 0.2 + (rand.x) * 0.1;
    baseRad = floor(baseRad * 20.0+0.5)/20.0;	// try to snap this for window texture

    // make position relative to the middle of the block
    vec3 baseCenter = p - vec3(0.5, 0.0, 0.5);
    float height = rand.w*rand.z + 0.1; // height of first building block
    // Make the city skyline higher in the middle of the city.
    float downtown = saturate(4.0 / length(pint.xy));
    height *= downtown;
    height *= 1.5+(baseRad-0.15)*20.0;
    height += 0.1;	// minimum building height
    //height += sin(iGlobalTime + pint.x);	// animate the building heights if you're feeling silly
    height = floor(height*20.0)*0.05;	// height is in floor units - each floor is 0.05 high.
	float d = sdBox(baseCenter, vec3(baseRad, height, baseRad)); // large building piece

    // road
    d = min(d, p.y);

    //if (length(pint.xy) > 8.0) return vec2(d, mat);	// Hack to LOD in the distance

    // height of second building section
    float height2 = max(0.0, rand.y * 2.0 - 1.0) * downtown;
    height2 = floor(height2*20.0)*0.05;	// floor units
    rand2 = floor(rand2*20.0)*0.05;	// floor units
    // size pieces of building
	d = min(d, sdBox(baseCenter - vec3(0.0, height, 0.0), vec3(baseRad, height2 - rand2.y, baseRad*0.4)));
	d = min(d, sdBox(baseCenter - vec3(0.0, height, 0.0), vec3(baseRad*0.4, height2 - rand2.x, baseRad)));
    // second building section
    if (rand2.y > 0.25)
    {
		d = min(d, sdBox(baseCenter - vec3(0.0, height, 0.0), vec3(baseRad*0.8, height2, baseRad*0.8)));
        // subtract off piece from top so it looks like there's a wall around the roof.
        float topWidth = baseRad;
        if (height2 > 0.0) topWidth = baseRad * 0.8;
		d = max(d, -sdBox(baseCenter - vec3(0.0, height+height2, 0.0), vec3(topWidth-0.0125, 0.015, topWidth-0.0125)));
    }
    else
    {
        // Cylinder top section of building
		if (height2 > 0.0) d = min(d, cylCap((baseCenter - vec3(0.0, height, 0.0)).xzy, baseRad*0.8, height2));
    }
    // mini elevator shaft boxes on top of building
	d = min(d, sdBox(baseCenter - vec3((rand.x-0.5)*baseRad, height+height2, (rand.y-0.5)*baseRad),
                     vec3(baseRad*0.3*rand.z, 0.1*rand2.y, baseRad*0.3*rand2.x+0.025)));
    // mirror another box (and scale it) so we get 2 boxes for the price of 1.
    vec3 boxPos = baseCenter - vec3((rand2.x-0.5)*baseRad, height+height2, (rand2.y-0.5)*baseRad);
    float big = sign(boxPos.x);
    boxPos.x = abs(boxPos.x)-0.02 - baseRad*0.3*rand.w;
	d = min(d, sdBox(boxPos,
    vec3(baseRad*0.3*rand.w, 0.07*rand.y, baseRad*0.2*rand.x + big*0.025)));

    // Put domes on some building tops for variety
    if (rand.y < 0.04)
    {
        d = min(d, length(baseCenter - vec3(0.0, height, 0.0)) - baseRad*0.8);
    }

    //d = max(d, p.y);  // flatten the city for debugging cars

    // Need to make a material variable.
    vec2 distAndMat = vec2(d, 0.0);
    // sidewalk box with material
    distAndMat = matmin(distAndMat, vec2(sdBox(baseCenter, vec3(0.35, 0.005, 0.35)), 1.0));

    return distAndMat;
}

// This is the distance function that defines all the scene's geometry.
// The input is a position in space.
// The output is the distance to the nearest surface and a material index.
vec2 DistanceToObject(vec3 p)
{
    //p.y += noise2d((p.xz)*0.0625)*8.0; // Hills
    vec3 rep = p;
    rep.xz = fract(p.xz); // [0..1] for representing the position in the city block
    vec2 distAndMat = CityBlock(rep, floor(p.xz));

    // Set up the cars. This is doing a lot of mirroring and repeating because I
    // only want to do a single call to the car distance function for all the
    // cars in the scene. And there's a lot of traffic!
    vec3 p2 = p;
    rep.xyz = p2;
    float carTime = localTime*0.2;  // Speed of car driving
    float crossStreet = 1.0;  // whether we are north/south or east/west
    float repeatDist = 0.25;  // Car density bumper to bumper
    // If we are going north/south instead of east/west (?) make cars that are
    // stopped in the street so we don't have collisions.
    if (abs(fract(rep.x)-0.5) < 0.35)
    {
        p2.x += 0.05;
        p2.xz = p2.zx * vec2(-1.0,1.0);  // Rotate 90 degrees
        rep.xz = p2.xz;
        crossStreet = 0.0;
        repeatDist = 0.1;  // Denser traffic on cross streets
    }
    
    rep.z += floor(p2.x);	// shift so less repitition between parallel blocks
    rep.x = Repeat(p2.x - 0.5, 1.0);	// repeat every block
    rep.z = rep.z*sign(rep.x);	// mirror but keep cars facing the right way
    rep.x = (rep.x*sign(rep.x))-0.09;
    rep.z -= carTime * crossStreet;	// make cars move
    float uniqueID = floor(rep.z/repeatDist);	// each car gets a unique ID that we can use for colors
    rep.z = Repeat(rep.z, repeatDist);	// repeat the line of cars every quarter block
    rep.x += (Hash11(uniqueID)*0.075-0.01);	// nudge cars left and right to take both lanes
    float frontBack = Hash11(uniqueID*0.987)*0.18-0.09;
    frontBack *= sin(localTime*2.0 + uniqueID);
    rep.z += frontBack * crossStreet; // nudge cars forward back for variation
    vec2 carDist = Car(rep, uniqueID); // car distance function

    // Drop the cars in the scene with materials
    distAndMat = matmin(distAndMat, carDist);

    return distAndMat;
}

// This basically makes a procedural texture map for the sides of the buildings.
// It makes a texture, a normal for normal mapping, and a mask for window reflection.
void CalcWindows(vec2 block, vec3 pos, inout vec3 texColor, inout float windowRef, inout vec3 normal)
{
    vec3 hue = vec3(Hash21(block)*0.8, Hash21(block*7.89)*0.4, Hash21(block*37.89)*0.5);
    texColor += hue*0.4;
    texColor *= 0.75;
    float window = 0.0;
    window = max(window, mix(0.2, 1.0, floor(fract(pos.y*20.0-0.35)*2.0+0.1)));
    if (pos.y < 0.05) window = 1.0;
    float winWidth = Hash21(block*4.321)*2.0;
    if ((winWidth < 1.3) && (winWidth >= 1.0)) winWidth = 1.3;
    window = max(window, mix(0.2, 1.0, floor(fract(pos.x * 40.0+0.05)*winWidth)));
    window = max(window, mix(0.2, 1.0, floor(fract(pos.z * 40.0+0.05)*winWidth)));
    if (window < 0.5)
    {
        windowRef += 1.0;
    }
    window *= Hash21(block*1.123);
    texColor *= window;

    float wave = floor(sin((pos.y*40.0-0.1)*PI)*0.505-0.5)+1.0;
    normal.y -= max(-1.0, min(1.0, -wave*0.5));
    float pits = min(1.0, abs(sin((pos.z*80.0)*PI))*4.0)-1.0;
    normal.z += pits*0.25;
    pits = min(1.0, abs(sin((pos.x*80.0)*PI))*4.0)-1.0;
    normal.x += pits*0.25;
}

// Input is UV coordinate of pixel to render.
// Output is RGB color.
vec3 RayTrace(in vec2 fragCoord )
{
    marchCount = 0.0;
	// -------------------------------- animate ---------------------------------------
    sunCol = vec3(258.0, 248.0, 200.0) / 3555.0;
	sunDir = normalize(vec3(0.93, 1.0, 1.0));
    horizonCol = vec3(1.0, 0.95, 0.85)*0.9;
    skyCol = vec3(0.3,0.5,0.95);
    exposure = 1.0;
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
	camLookat=vec3(0,0.0,0);

    // debugging camera
    float mx=-iMouse.x/iResolution.x*PI*2.0;// + localTime * 0.05;
	float my=iMouse.y/iResolution.y*3.14*0.5 + PI/2.0;// + sin(localTime * 0.3)*0.8+0.1;//*PI/2.01;
	camPos = vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*7.35;//7.35
#else
    // Do the camera fly-by animation and different scenes.
    // Time variables for start and end of each scene
    const float t0 = 0.0;
    const float t1 = 8.0;
    const float t2 = 14.0;
    const float t3 = 24.0;
    const float t4 = 38.0;
    const float t5 = 56.0;
    const float t6 = 58.0;
    /*const float t0 = 0.0;
    const float t1 = 0.0;
    const float t2 = 0.0;
    const float t3 = 0.0;
    const float t4 = 0.0;
    const float t5 = 16.0;
    const float t6 = 18.0;*/
    // Repeat the animation after time t6
    localTime = fract(localTime / t6) * t6;
    if (localTime < t1)
    {
        float time = localTime - t0;
        float alpha = time / (t1 - t0);
        fade = saturate(time);
        fade *= saturate(t1 - localTime);
        camPos = vec3(13.0, 3.3, -3.5);
        camPos.x -= smoothstep(0.0, 1.0, alpha) * 4.8;
        camUp=vec3(0,1,0);
        camLookat=vec3(0,1.5,1.5);
    } else if (localTime < t2)
    {
        float time = localTime - t1;
        float alpha = time / (t2 - t1);
        fade = saturate(time);
        fade *= saturate(t2 - localTime);
        camPos = vec3(26.0, 0.05+smoothstep(0.0, 1.0, alpha)*0.4, 2.0);
        camPos.z -= alpha * 2.8;
        camUp=vec3(0,1,0);
        camLookat=vec3(camPos.x-0.3,-8.15,-40.0);
        
        sunDir = normalize(vec3(0.95, 0.6, 1.0));
        sunCol = vec3(258.0, 248.0, 160.0) / 3555.0;
        exposure *= 0.7;
        skyCol *= 1.5;
    } else if (localTime < t3)
    {
        float time = localTime - t2;
        float alpha = time / (t3 - t2);
        fade = saturate(time);
        fade *= saturate(t3 - localTime);
        camPos = vec3(12.0, 6.3, -0.5);
        camPos.y -= alpha * 5.5;
        camPos.x = cos(alpha*1.0) * 5.2;
        camPos.z = sin(alpha*1.0) * 5.2;
        camUp=normalize(vec3(0,1,-0.5 + alpha * 0.5));
        camLookat=vec3(0,1.0,-0.5);
    } else if (localTime < t4)
    {
        float time = localTime - t3;
        float alpha = time / (t4 - t3);
        fade = saturate(time);
        fade *= saturate(t4 - localTime);
        camPos = vec3(2.15-alpha*0.5, 0.02, -1.0-alpha*0.2);
        camPos.y += smoothstep(0.0,1.0,alpha*alpha) * 3.4;
        camUp=normalize(vec3(0,1,0.0));
        camLookat=vec3(0,0.5+alpha,alpha*5.0);
    } else if (localTime < t5)
    {
        float time = localTime - t4;
        float alpha = time / (t5 - t4);
        fade = saturate(time);
        fade *= saturate(t5 - localTime);
        camPos = vec3(-2.0, 1.3- alpha*1.2, -10.5-alpha*0.5);
        camUp=normalize(vec3(0,1,0.0));
        camLookat=vec3(-2.0,0.3+alpha,-0.0);
        sunDir = normalize(vec3(0.5-alpha*0.6, 0.3-alpha*0.3, 1.0));
        sunCol = vec3(258.0, 148.0, 60.0) / 3555.0;
        localTime *= 16.0;
        exposure *= 0.4;
        horizonCol = vec3(1.0, 0.5, 0.35)*2.0;
        skyCol = vec3(0.75,0.5,0.95);

    } else if (localTime < t6)
    {
        fade = 0.0;
        camPos = vec3(26.0, 100.0, 2.0);
        camUp=vec3(0,1,0);
        camLookat=vec3(0.3,0.15,0.0);
    }
#endif

	// Camera setup for ray tracing / marching
	vec3 camVec=normalize(camLookat - camPos);
	vec3 sideNorm=normalize(cross(camUp, camVec));
	vec3 upNorm=cross(camVec, sideNorm);
	vec3 worldFacing=(camPos + camVec);
	vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;
	vec3 rayVec = normalize(worldPix - camPos);

	// ----------------------------- Ray march the scene ------------------------------
	vec2 distAndMat;  // Distance and material
	float t = 0.05;// + Hash2d(uv)*0.1;	// random dither-fade things close to the camera
	const float maxDepth = 45.0; // farthest distance rays will travel
	vec3 pos = vec3(0.0);
    const float smallVal = 0.000625;
	// ray marching time
    for (int i = 0; i < 250; i++)	// This is the count of the max times the ray actually marches.
    {
        marchCount+=1.0;
        // Step along the ray.
        pos = (camPos + rayVec * t);
        // This is _the_ function that defines the "distance field".
        // It's really what makes the scene geometry. The idea is that the
        // distance field returns the distance to the closest object, and then
        // we know we are safe to "march" along the ray by that much distance
        // without hitting anything. We repeat this until we get really close
        // and then break because we have effectively hit the object.
        distAndMat = DistanceToObject(pos);

        // 2d voxel walk through the city blocks.
        // The distance function is not continuous at city block boundaries,
        // so we have to pause our ray march at each voxel boundary.
        float walk = distAndMat.x;
        float dx = -fract(pos.x);
        if (rayVec.x > 0.0) dx = fract(-pos.x);
        float dz = -fract(pos.z);
        if (rayVec.z > 0.0) dz = fract(-pos.z);
        float nearestVoxel = min(fract(dx/rayVec.x), fract(dz/rayVec.z))+voxelPad;
        nearestVoxel = max(voxelPad, nearestVoxel);// hack that assumes streets and sidewalks are this wide.
        //nearestVoxel = max(nearestVoxel, t * 0.02); // hack to stop voxel walking in the distance.
        walk = min(walk, nearestVoxel);

        // move down the ray a safe amount
        t += walk;
        // If we are very close to the object, let's call it a hit and exit this loop.
        if ((t > maxDepth) || (abs(distAndMat.x) < smallVal)) break;
    }

    // Ray trace a ground plane to infinity
    float alpha = -camPos.y / rayVec.y;
    if ((t > maxDepth) && (rayVec.y < -0.0))
    {
        pos.xz = camPos.xz + rayVec.xz * alpha;
        pos.y = -0.0;
        t = alpha;
        distAndMat.y = 0.0;
        distAndMat.x = 0.0;
    }
	// --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this geometry.
	vec3 finalColor = vec3(0.0);

	// If a ray actually hit the object, let's light it.
    if ((t <= maxDepth) || (t == alpha))
	{
        float dist = distAndMat.x;
        // calculate the normal from the distance field. The distance field is a volume, so if you
        // sample the current point and neighboring points, you can use the difference to get
        // the normal.
        vec3 smallVec = vec3(smallVal, 0, 0);
        vec3 normalU = vec3(dist - DistanceToObject(pos - smallVec.xyy).x,
                           dist - DistanceToObject(pos - smallVec.yxy).x,
                           dist - DistanceToObject(pos - smallVec.yyx).x);
        vec3 normal = normalize(normalU);

        // calculate 2 ambient occlusion values. One for global stuff and one
        // for local stuff
        float ambientS = 1.0;
        ambientS *= saturate(DistanceToObject(pos + normal * 0.0125).x*80.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.025).x*40.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.05).x*20.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.1).x*10.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.2).x*5.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.4).x*2.5);
        //ambientS *= saturate(DistanceToObject(pos + normal * 0.8).x*1.25);
        float ambient = ambientS;// * saturate(DistanceToObject(pos + normal * 1.6).x*1.25*0.5);
        //ambient *= saturate(DistanceToObject(pos + normal * 3.2)*1.25*0.25);
        //ambient *= saturate(DistanceToObject(pos + normal * 6.4)*1.25*0.125);
        ambient = max(0.025, pow(ambient, 0.5));	// tone down ambient with a pow and min clamp it.
        ambient = saturate(ambient);

        // calculate the reflection vector for highlights
        vec3 ref = reflect(rayVec, normal);

        // Trace a ray toward the sun for sun shadows
        float sunShadow = 1.0;
        float iter = 0.01;
        vec3 nudgePos = pos + normal*0.002;	// don't start tracing too close or inside the object
		for (int i = 0; i < 40; i++)
        {
            vec3 shadowPos = nudgePos + sunDir * iter;
            float tempDist = DistanceToObject(shadowPos).x;
	        sunShadow *= saturate(tempDist*150.0);	// Shadow hardness
            if (tempDist <= 0.0) break;

            float walk = tempDist;
            float dx = -fract(shadowPos.x);
            if (sunDir.x > 0.0) dx = fract(-shadowPos.x);
            float dz = -fract(shadowPos.z);
            if (sunDir.z > 0.0) dz = fract(-shadowPos.z);
            float nearestVoxel = min(fract(dx/sunDir.x), fract(dz/sunDir.z))+smallVal;
            nearestVoxel = max(0.2, nearestVoxel);// hack that assumes streets and sidewalks are this wide.
            walk = min(walk, nearestVoxel);

            iter += max(0.01, walk);
            if (iter > 4.5) break;
        }
        sunShadow = saturate(sunShadow);

        // make a few frequencies of noise to give it some texture
        float n =0.0;
        n += noise(pos*32.0);
        n += noise(pos*64.0);
        n += noise(pos*128.0);
        n += noise(pos*256.0);
        n += noise(pos*512.0);
        n = mix(0.7, 0.95, n);

        // ------ Calculate texture color  ------
        vec2 block = floor(pos.xz);
        vec3 texColor = vec3(0.95, 1.0, 1.0);
        texColor *= 0.8;
        float windowRef = 0.0;
        // texture map the sides of buildings
        if ((normal.y < 0.1) && (distAndMat.y == 0.0))
        {
            vec3 posdx = dFdx(pos);
            vec3 posdy = dFdy(pos);
            vec3 posGrad = posdx * Hash21(uv) + posdy * Hash21(uv*7.6543);

            // Quincunx antialias the building texture and normal map.
            // I guess procedural textures are hard to mipmap.
            vec3 colTotal = vec3(0.0);
            vec3 colTemp = texColor;
            vec3 nTemp = vec3(0.0);
            CalcWindows(block, pos, colTemp, windowRef, nTemp);
            colTotal = colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdx * 0.666, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdx * 0.666 + posdy * 0.666, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdy * 0.666, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdx * 0.333 + posdy * 0.333, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            texColor = colTotal * 0.2;
            windowRef *= 0.2;

            normal = normalize(normal + nTemp * 0.2);
        }
        else
        {
            // Draw the road
            float xroad = abs(fract(pos.x+0.5)-0.5);
            float zroad = abs(fract(pos.z+0.5)-0.5);
            float road = saturate((min(xroad, zroad)-0.143)*480.0);
            texColor *= 1.0-normal.y*0.95*Hash21(block*9.87)*road; // change rooftop color
            texColor *= mix(0.1, 1.0, road);

            // double yellow line in middle of road
            float yellowLine = saturate(1.0-(min(xroad, zroad)-0.002)*480.0);
            yellowLine *= saturate((min(xroad, zroad)-0.0005)*480.0);
            yellowLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0);
            texColor = mix(texColor, vec3(1.0, 0.8, 0.3), yellowLine);

            // white dashed lines on road
            float whiteLine = saturate(1.0-(min(xroad, zroad)-0.06)*480.0);
            whiteLine *= saturate((min(xroad, zroad)-0.056)*480.0);
            whiteLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0);
            whiteLine *= saturate(1.0-(fract(zroad*8.0)-0.5)*280.0);  // dotted line
            whiteLine *= saturate(1.0-(fract(xroad*8.0)-0.5)*280.0);
            texColor = mix(texColor, vec3(0.5), whiteLine);

            whiteLine = saturate(1.0-(min(xroad, zroad)-0.11)*480.0);
            whiteLine *= saturate((min(xroad, zroad)-0.106)*480.0);
            whiteLine *= saturate((xroad*xroad+zroad*zroad-0.06)*880.0);
            texColor = mix(texColor, vec3(0.5), whiteLine);

            // crosswalk
            float crossWalk = saturate(1.0-(fract(xroad*40.0)-0.5)*280.0);
            crossWalk *= saturate((zroad-0.15)*880.0);
            crossWalk *= saturate((-zroad+0.21)*880.0)*(1.0-road);
            crossWalk *= n*n;
            texColor = mix(texColor, vec3(0.25), crossWalk);
            crossWalk = saturate(1.0-(fract(zroad*40.0)-0.5)*280.0);
            crossWalk *= saturate((xroad-0.15)*880.0);
            crossWalk *= saturate((-xroad+0.21)*880.0)*(1.0-road);
            crossWalk *= n*n;
            texColor = mix(texColor, vec3(0.25), crossWalk);

            {
                // sidewalk cracks
                float sidewalk = 1.0;
                vec2 blockSize = vec2(100.0);
                if (pos.y > 0.1) blockSize = vec2(10.0, 50);
                //sidewalk *= pow(abs(sin(pos.x*blockSize)), 0.025);
                //sidewalk *= pow(abs(sin(pos.z*blockSize)), 0.025);
                sidewalk *= saturate(abs(sin(pos.z*blockSize.x)*800.0/blockSize.x));
                sidewalk *= saturate(abs(sin(pos.x*blockSize.y)*800.0/blockSize.y));
                sidewalk = saturate(mix(0.7, 1.0, sidewalk));
                sidewalk = saturate((1.0-road) + sidewalk);
                texColor *= sidewalk;
            }
        }
        // Car tires are almost black to not call attention to their ugly.
        if (distAndMat.y == 3.0)
        {
            texColor = vec3(0.05);
        }

        // apply noise
        texColor *= vec3(1.0)*n*0.05;
        texColor *= 0.7;
        texColor = saturate(texColor);

        float windowMask = 0.0;
        if (distAndMat.y >= 100.0)
        {
            // car texture and windows
            texColor = vec3(Hash11(distAndMat.y)*1.0, Hash11(distAndMat.y*8.765), Hash11(distAndMat.y*17.731))*0.1;
            texColor = pow(abs(texColor), vec3(0.2));  // bias toward white
            texColor = max(vec3(0.25), texColor);  // not too saturated color.
            texColor.z = min(texColor.y, texColor.z);  // no purple cars. just not realistic. :)
            texColor *= Hash11(distAndMat.y*0.789) * 0.15;
            windowMask = saturate( max(0.0, abs(pos.y - 0.0175)*3800.0)-10.0);
            vec2 dirNorm = abs(normalize(normal.xz));
            float pillars = saturate(1.0-max(dirNorm.x, dirNorm.y));
            pillars = pow(max(0.0, pillars-0.15), 0.125);
            windowMask = max(windowMask, pillars);
            texColor *= windowMask;
        }

        // ------ Calculate lighting color ------
        // Start with sun color, standard lighting equation, and shadow
        vec3 lightColor = vec3(100.0)*sunCol * saturate(dot(sunDir, normal)) * sunShadow;
        // weighted average the near ambient occlusion with the far for just the right look
        float ambientAvg = (ambient*3.0 + ambientS) * 0.25;
        // Add sky color with ambient acclusion
        lightColor += (skyCol * saturate(normal.y *0.5+0.5))*pow(ambientAvg, 0.35)*2.5;
        lightColor *= 4.0;

        // finally, apply the light to the texture.
        finalColor = texColor * lightColor;
        // Reflections for cars
        if (distAndMat.y >= 100.0)
        {
            float yfade = max(0.01, min(1.0, ref.y*100.0));
            // low-res way of making lines at the edges of car windows. Not sure I like it.
            yfade *= (saturate(1.0-abs(dFdx(windowMask)*dFdy(windowMask))*250.995));
            finalColor += GetEnvMapSkyline(ref, sunDir, pos.y-1.5)*0.3*yfade*max(0.4,sunShadow);
            //finalColor += saturate(texture(iChannel0, ref).xyz-0.35)*0.15*max(0.2,sunShadow);
        }
        // reflections for building windows
        if (windowRef != 0.0)
        {
            finalColor *= mix(1.0, 0.6, windowRef);
            float yfade = max(0.01, min(1.0, ref.y*100.0));
            finalColor += GetEnvMapSkyline(ref, sunDir, pos.y-0.5)*0.6*yfade*max(0.6,sunShadow)*windowRef;//*(windowMask*0.5+0.5);
            //finalColor += saturate(texture(iChannel0, ref).xyz-0.35)*0.15*max(0.25,sunShadow)*windowRef;
        }
        finalColor *= 0.9;
        // fog that fades to reddish plus the sun color so that fog is brightest towards sun
        vec3 rv2 = rayVec;
        rv2.y *= saturate(sign(rv2.y));
        vec3 fogColor = GetEnvMap(rv2, sunDir);
        fogColor = min(vec3(9.0), fogColor);
        finalColor = mix(fogColor, finalColor, exp(-t*0.02));

        // visualize length of gradient of distance field to check distance field correctness
        //finalColor = vec3(0.5) * (length(normalU) / smallVec.x);
        //finalColor = vec3(marchCount)/255.0;
	}
    else
    {
        // Our ray trace hit nothing, so draw sky.
        finalColor = GetEnvMap(rayVec, sunDir);
    }

    // vignette?
    finalColor *= vec3(1.0) * saturate(1.0 - length(uv/2.5));
    finalColor *= 1.3*exposure;

	// output the final color without gamma correction - will do gamma later.
	return vec3(clamp(finalColor, 0.0, 1.0)*saturate(fade+0.2));
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
