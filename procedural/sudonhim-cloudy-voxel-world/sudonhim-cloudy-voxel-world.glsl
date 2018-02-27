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

#define PI 3.14159

#define VOXEL_NONE  0
#define VOXEL_WATER 1
#define VOXEL_SAND  2
#define VOXEL_EARTH 3
#define VOXEL_STONE 4
#define VOXEL_GRASS 5

// from https://www.shadertoy.com/view/4sfGzS
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
    vec2 uv = p.xy + f.xy;
	vec2 rg = vec2(texture( iChannel0, (uv+vec2(37.0,17.0)*p.z+0.5)/256.0, -100.0 ).x,
                   texture( iChannel0, (uv+vec2(37.0,17.0)*(p.z+1.0)+0.5)/256.0, -100.0 ).x );
	return mix( rg.x, rg.y, f.z );
}

int getVoxelAndFogAt(ivec3 ip, out float fogStrength)
{ 
    float cloudiness = noise(vec3(ip)/8.0);
    fogStrength = smoothstep(0.6, 0.7, cloudiness)*0.3 + 0.1;
    
    if (ip.y <= 0) return VOXEL_WATER;
    
    // so this is like, grabbing the texture as a heightmap and
    // then like twisting it in random directions as it goes up
    // umm...
    vec3 p = vec3(vec3(ip) + 0.5);
    float theta = noise(p / 16.0) * PI * 2.0;
    vec2 disp = vec2(cos(theta), sin(theta)) * p.y;
    vec3 terr = texture(iChannel1, (p.xz + disp) / 128.0).rgb;

    bvec3 contains = lessThanEqual(vec3(0.0), (terr - p.y/16.0));
    if (contains.x && contains.y && !contains.z) return VOXEL_SAND;
    if (contains.x && contains.z) return VOXEL_GRASS;
    if (contains.y && contains.z && !contains.x) return VOXEL_STONE;
    if (contains.x || contains.y || contains.z) return VOXEL_EARTH;

    return VOXEL_NONE;
}

float dfVoxel(vec3 p, int voxelType)
{
    float r = 0.1;
    if (voxelType == VOXEL_WATER) r = 0.0;
    return length(max(abs(p)-vec3(0.5-r),0.0))-r;
}

vec3 nrmVoxel(vec3 p, int voxelType) 
{
    vec2 dd = vec2(0.001,0.0);
    float base = dfVoxel(p, voxelType);
    return normalize(vec3(
        dfVoxel(p+dd.xyy, voxelType) - base,
        dfVoxel(p+dd.yxy, voxelType) - base,
        dfVoxel(p+dd.yyx, voxelType) - base
    ));
}

void voxelMarch(vec3 ro, vec3 rd, out ivec3 hitVoxels[4], out float fogAccums[5], out int hitCount) 
{
    hitCount = 0;

    ivec3 mapPos = ivec3(floor(ro));
    vec3 deltaDist = abs(vec3(length(rd)) / rd);
    ivec3 rayStep = ivec3(sign(rd));
    vec3 sideDist = (sign(rd) * (vec3(mapPos) - ro) + (sign(rd) * 0.5) + 0.5) * deltaDist; 
    bvec3 mask;
    float fogAccum = 0.0;
    float prevDist = 0.0;
	
    for (int i = 0; i < 96; i++) {

        // check current position for voxel
        float fogStrength;
        if (getVoxelAndFogAt(mapPos, fogStrength) != VOXEL_NONE) {
            // no non-const indexing? :<
            if (hitCount == 0)      { hitVoxels[0] = mapPos; fogAccums[0] = fogAccum; }
            else if (hitCount == 1) { hitVoxels[1] = mapPos; fogAccums[1] = fogAccum; }
            else if (hitCount == 2) { hitVoxels[2] = mapPos; fogAccums[2] = fogAccum; }
            else if (hitCount == 3) { hitVoxels[3] = mapPos; fogAccums[3] = fogAccum; }
            hitCount++;
            if (hitCount == 4) return;
        }

        // march forward to next position by discrete digital analyzer
        float newDist = min( sideDist.x, min(sideDist.y, sideDist.z ));
        vec3 mi = step( sideDist.xyz, sideDist.yzx ); 
        vec3 mm = mi*(1.0-mi.zxy);
        sideDist += mm * vec3(rayStep) / rd;
        mapPos += ivec3(mm)*rayStep;
        
        fogAccum += fogStrength * (newDist - prevDist);
        prevDist = newDist;
    }
    
    // did not intersect.
    fogAccums[4] = fogAccum;
}

void resolveHitVoxels(
    vec3 ro, vec3 rd, ivec3 hitVoxels[4], float fogAccums[5], int hitCount, 
    out ivec3 hitVoxel, out vec3 hit, out int terrainType, out float fogAccum) 
{ 
  for (int i=0; i<4; i++) {
    if (i == hitCount) { 
      terrainType = VOXEL_NONE;
      fogAccum = fogAccums[4];
      return; // less than four hits, none intersected
    }
    
    hitVoxel = hitVoxels[i]; float tmp;
    terrainType = getVoxelAndFogAt(hitVoxel, tmp);
    fogAccum = fogAccums[i];
    vec3 hitVoxelCenter = vec3(hitVoxel) + 0.5;
    
    // intersect with voxel cube
    vec3 cubeIntersect = (hitVoxelCenter - ro - 0.5*sign(rd))/rd;
    float d = max(cubeIntersect.x, max(cubeIntersect.y, cubeIntersect.z));

    // fallback in case of four no distance intersection
    hit = ro + rd * (d - 0.01) - hitVoxelCenter;
      
    // attempt better intersect with distance marching
    float diff;
    vec3 p = ro + rd * d;
    for (int j=0; j<4; j++) {
      diff = dfVoxel(p - hitVoxelCenter, terrainType);
      d += diff;
      p = ro + rd * d;
    }
    if (diff < 0.05) { // good enough distance marched intersection
      hit = p - hitVoxelCenter;
      return;
    }
  }
  // four hits, none intersected. Use the intersection with the cube to pretend we hit the last one.
}

vec3 doColoring(vec3 hit, int terrainType, vec3 hitGlobal, vec3 ldir)
{
    vec3 n = nrmVoxel(hit, terrainType);
    float diffuse = max(dot(-ldir, n), 0.1);
    
    float f1 = noise(hitGlobal*19.0);
    float f2 = noise(hitGlobal*33.0);
    float f3 = noise(hitGlobal*71.0);
    
    // render
    vec3 color = vec3(0.0);
    if (terrainType == VOXEL_WATER) {
        color = vec3(0.4, 0.4, 0.8) * (0.8 + f1*0.1 + f2*0.05 + f3*0.05);
    } else if (terrainType == VOXEL_EARTH) {
        color = vec3(1.0, 0.7, 0.3) * (f1*0.33 + f2*0.33 + f3*0.33);
    } else if (terrainType == VOXEL_SAND) {
        color = vec3(1.0, 1.0, 0.6) * (f1*0.1 + f2*0.1 + f3*0.5 + 0.3);
    } else if (terrainType == VOXEL_STONE) {
        color = vec3(0.5) * (f1*0.3 + f2*0.1 + 0.6);
    } else if (terrainType == VOXEL_GRASS) {
        color = vec3(0.3, 0.7, 0.4) * (f1*0.2 + f3*0.5 + 0.3);
    }
    
    color *= diffuse;
    
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera stolen from Shane :) https://www.shadertoy.com/view/ll2SRy
	vec2 uv = (fragCoord - iResolution.xy*.5 )/iResolution.y;
    vec3 rd = normalize(vec3(uv, (1.-dot(uv, uv)*.5)*.5));
    vec3 ro = vec3(0., 10., iGlobalTime*10.0);
    float t = sin(iGlobalTime * 0.2) + noise(ro/32.0);
    ro.y += 4.0*t;
	float cs = cos( t ), si = sin( t );
    rd.yz = mat2(cs, si,-si, cs)*rd.yz;
    rd.xz = mat2(cs, si,-si, cs)*rd.xz;
    
    // voxel march into the scene storing up to four intersections
    int hitCount;
    ivec3 hitVoxels[4];
    float fogAccums[5];
    voxelMarch(ro, rd, hitVoxels, fogAccums, hitCount);

    // resolve to one accurate intersection by distance marching
    int terrainType = VOXEL_NONE;
    ivec3 hitVoxel;
    vec3 hit;
    float fogAccum;
    resolveHitVoxels(ro, rd, hitVoxels, fogAccums, hitCount, hitVoxel, hit, terrainType, fogAccum);

    vec3 hitGlobal = vec3(hitVoxel) + hit;
    float dist = length(hitGlobal - ro);
    
    // color
    vec3 color;
    if (terrainType == VOXEL_NONE) // sky
    {
        color = vec3 (0.5, 0.5, 0.6);
        dist = 1000.0;
    } else {
        vec3 ldir = normalize(hitGlobal - ro);
        color = doColoring(hit, terrainType, hitGlobal, ldir);
    }
    
    // fog
    float fog = smoothstep(0.0, 10.0, fogAccum);
    color = mix(color, vec3(0.6), fog);
    
	fragColor = vec4(color,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
