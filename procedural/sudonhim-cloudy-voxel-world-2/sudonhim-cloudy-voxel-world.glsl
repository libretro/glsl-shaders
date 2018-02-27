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

#define SUN_DIRECTION normalize(vec3(0.4, 0.6, 0.7))

struct VoxelHit
{
    ivec3 mapPos;    // world coords
    int terrainType; // terrain type
    vec2 volAccum;   // sum of (fog, water) along the ray path
    vec3 hitRel;     // position of intersect relative to center of voxel
    vec3 hitNormal;  // surface normal at intersect
    float weight;    // contribution to the ray (fractional values come from anti-aliasing)
};

struct VoxelMarchResult
{
    // we store the first two intersects for two purposes:
    // 1) it allows the first voxel hit to be non-cube shaped (e.g. rounded edges)
    // 2) it allows cheap anti-aliasing
    VoxelHit first;
    VoxelHit second;
};

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

void getVoxelAndOcclusionsAt(ivec3 ip, out int terrainType, out vec2 occlusions)
{ 
    terrainType = VOXEL_NONE;
    
    float cloudiness = noise(vec3(ip)/8.0);
    occlusions = vec2(smoothstep(0.6, 0.7, cloudiness)*0.3 + 0.1, 0.0);
    
    if (ip.y <= 1) {terrainType = VOXEL_WATER; occlusions = vec2(0.0, 1.0);}
    
    // so this is like, grabbing the texture as a heightmap and
    // then like twisting it in random directions as it goes up
    // umm...
    vec3 p = vec3(vec3(ip) + 0.5);
    float theta = noise(p / 16.0) * PI * 2.0;
    vec2 disp = vec2(cos(theta), sin(theta)) * p.y;
    vec3 terr = texture(iChannel1, (p.xz + disp) / 128.0).rgb;

    bvec3 contains = lessThanEqual(vec3(0.0), (terr - p.y/16.0));
    if (contains.x && contains.y && !contains.z) terrainType = VOXEL_SAND;
    else if (contains.x && contains.z) terrainType = VOXEL_GRASS;
    else if (contains.y && contains.z && !contains.x) terrainType = VOXEL_STONE;
    else if (contains.x || contains.y || contains.z) terrainType = VOXEL_EARTH;
}

float dfVoxel(vec3 p, int terrainType)
{
    float r = 0.1;
    if (terrainType == VOXEL_WATER) r = 0.0;
    return length(max(abs(p)-vec3(0.5-r),0.0))-r;
}

vec3 nrmVoxel(vec3 p, int terrainType) 
{
    vec2 dd = vec2(0.001,0.0);
    float base = dfVoxel(p, terrainType);
    return normalize(vec3(
        dfVoxel(p+dd.xyy, terrainType) - base,
        dfVoxel(p+dd.yxy, terrainType) - base,
        dfVoxel(p+dd.yyx, terrainType) - base
    ));
}

VoxelMarchResult voxelMarch(vec3 ro, vec3 rd) 
{
    ivec3 mapPos = ivec3(floor(ro));
    vec3 deltaDist = abs(vec3(length(rd)) / rd);
    ivec3 rayStep = ivec3(sign(rd));
    vec3 sideDist = (sign(rd) * (vec3(mapPos) - ro) + (sign(rd) * 0.5) + 0.5) * deltaDist; 
    vec2 volAccum = vec2(0.0);
    float prevDist = 0.0;
    
    VoxelMarchResult result;
	
    for (int i = 0; i < 96; i++) {

        // check current position for voxel
        vec2 occlusions;  int terrainType;
        getVoxelAndOcclusionsAt(mapPos, terrainType, occlusions);
        
        // if intersected, save
        if (terrainType != VOXEL_NONE) {
            VoxelHit newVoxelHit = VoxelHit(mapPos, terrainType, volAccum, vec3(0.0), vec3(0.0), 0.0);
            if (result.first.terrainType == VOXEL_NONE) {
                result.first = newVoxelHit;
            } else if (result.first.terrainType != VOXEL_WATER || terrainType != VOXEL_WATER) {
                result.second = newVoxelHit;
                break; // two intersections, stop stepping!
            }
        }

        // march forward to next position
        float newDist = min( sideDist.x, min(sideDist.y, sideDist.z ));
        vec3 mi = step( sideDist.xyz, sideDist.yzx ); 
        vec3 mm = mi*(1.0-mi.zxy);
        sideDist += mm * vec3(rayStep) / rd;
        mapPos += ivec3(mm)*rayStep;
        
        // accumulate occlusions
        volAccum += occlusions * (newDist - prevDist);
        prevDist = newDist;
    }
    
    // last result should always have max fog
    result.second.volAccum = volAccum;
    
    // if there was no intersection, set accumulated fog on first hit and return
    if (result.first.terrainType == VOXEL_NONE) {
        result.first.volAccum = volAccum;
        result.first.weight = 1.0;
        return result;
    }
    
    // distance march to intersect first voxel
    vec3 hitVoxelCenter = vec3(result.first.mapPos) + 0.5;
    vec3 cubeIntersect = (hitVoxelCenter - ro - 0.5*sign(rd))/rd;
    float dist = max(cubeIntersect.x, max(cubeIntersect.y, cubeIntersect.z));
    float diff; float mindiff = 1.0; float finaldist = 0.0;
    for (int i=0; i<8; i++) {
        vec3 p = ro + rd * dist;
        diff = dfVoxel(p - hitVoxelCenter, result.first.terrainType);
        if (diff < mindiff) {
            mindiff = diff;
            finaldist = dist;
        }
        dist += diff; 
    }
    
    float pixSizeApprox = 2.0/iResolution.x * finaldist; // the FOV is actually about 1 radian :)
    result.first.weight = smoothstep(pixSizeApprox, 0.0, mindiff - 0.01); // anti-alias blend
    result.first.hitRel = ro + rd * finaldist - hitVoxelCenter;
    result.first.hitNormal = nrmVoxel(result.first.hitRel, result.first.terrainType);
    
    // if it was water, adjust weight for surface reflection
    if (result.first.terrainType == VOXEL_WATER) result.first.weight = 0.5;
    
    // do a cube intersection for the second voxel
    hitVoxelCenter = vec3(result.second.mapPos) + 0.5;
    cubeIntersect = (hitVoxelCenter - ro - 0.5*sign(rd))/rd;
    dist = max(cubeIntersect.x, max(cubeIntersect.y, cubeIntersect.z));
    result.second.hitRel = ro + rd * dist - hitVoxelCenter;
    
    // attempt to improve a little with distance marching
    for (int i=0; i<4; i++) {
        vec3 p = ro + rd * dist;
        diff = dfVoxel(p - hitVoxelCenter, result.first.terrainType);
        dist += diff; 
    }
    if (diff < 0.05) result.second.hitRel = ro + rd * dist - hitVoxelCenter;
    
    result.second.weight = 1.0 - result.first.weight;
    result.second.hitNormal = nrmVoxel(result.second.hitRel, result.second.terrainType);
    
    return result;
}

float marchShadowCheck(VoxelHit hit)
{
    vec3 ro = hit.hitRel + vec3(hit.mapPos) + 0.5;
    vec3 rd = SUN_DIRECTION;
    ro += rd*0.11;
    
    ivec3 mapPos = ivec3(floor(ro));
    vec3 deltaDist = abs(vec3(length(rd)) / rd);
    ivec3 rayStep = ivec3(sign(rd));
    vec3 sideDist = (sign(rd) * (vec3(mapPos) - ro) + (sign(rd) * 0.5) + 0.5) * deltaDist; 
	float fogAccum = 0.0;
    float prevDist = 0.0;
    
    for (int i = 0; i < 16; i++) {

        // check current position for voxel
        vec2 occlusions;  int terrainType;
        getVoxelAndOcclusionsAt(mapPos, terrainType, occlusions);
        
        // if intersected, finish
        if (terrainType != VOXEL_NONE) {
            return 1.0;
        }

        // march forward to next position
        float newDist = min( sideDist.x, min(sideDist.y, sideDist.z ));
        vec3 mi = step( sideDist.xyz, sideDist.yzx ); 
        vec3 mm = mi*(1.0-mi.zxy);
        sideDist += mm * vec3(rayStep) / rd;
        mapPos += ivec3(mm)*rayStep;
        
        // accumulate fog
        fogAccum += occlusions.x * (newDist - prevDist);
        prevDist = newDist;
    }
    
    // no intersection
    return fogAccum / 5.0;
}

float calcAmbientOcclusion(VoxelHit hit)
{
    float ambientOcc = 0.0;
    
    // for each of the 28 voxels surrounding the hit voxel
    for (int i=-1; i<=1; i++) for (int j=-1; j<=1; j++) for (int k=-1; k<=1; k++) {
        if (i == 0 && j == 0 && k == 0) continue; // skip the hit voxel
        ivec3 offset = ivec3(i, j, k);
        // TODO: find some way to skip these voxels
        // if (dot(hit.hitRel, vec3(offset)) < 0.0) continue; 
        
        int terrainType; vec2 occlusions;
        getVoxelAndOcclusionsAt(hit.mapPos + offset, terrainType, occlusions);
        if (terrainType != VOXEL_NONE && terrainType != VOXEL_WATER) {
            
            // use the distance from just above the intersection to estimate occlusion
            float dist = dfVoxel(hit.hitRel + hit.hitNormal*0.5 - vec3(offset), terrainType);
            ambientOcc += smoothstep(1.0, 0.0, dist);
        }
    }
    
    return ambientOcc / 8.0;
}

vec3 doColoring(VoxelHit hit, vec3 rd)
{   
    // global position for non-repeating noise
    vec3 hitGlobal = vec3(hit.mapPos) + hit.hitRel + 0.5;
    float f1 = noise(hitGlobal*19.0);
    float f2 = noise(hitGlobal*33.0);
    float f3 = noise(hitGlobal*71.0);
    
    vec3 color = vec3(0.0);
    if (hit.terrainType == VOXEL_WATER) {
        color = vec3(0.4, 0.4, 0.8) * (0.8 + f1*0.1 + f2*0.05 + f3*0.05);
    } else if (hit.terrainType == VOXEL_EARTH) {
        color = vec3(1.0, 0.7, 0.3) * (f1*0.13 + f2*0.13 + f3*0.1 + 0.3);
    } else if (hit.terrainType == VOXEL_SAND) {
        color = vec3(1.0, 1.0, 0.6) * (f1*0.07 + f2*0.07 + f3*0.2 + 0.5);
    } else if (hit.terrainType == VOXEL_STONE) {
        color = vec3(0.5) * (f1*0.3 + f2*0.1 + 0.6);
    } else if (hit.terrainType == VOXEL_GRASS) {
        color = vec3(0.3, 0.7, 0.4) * (f1*0.1 + f3*0.1 + 0.6);
    }  else if (hit.terrainType == VOXEL_NONE) {
        color = vec3(0.0, 1.0, 1.0);
        color += vec3(5.0, 3.0, 0.0)*pow(max(dot(rd, SUN_DIRECTION), 0.0), 128.0);
    }
    
    float shadow = min(marchShadowCheck(hit), 1.0);
    float ambient = 1.0 - calcAmbientOcclusion(hit);
    float diffuse = max(dot(SUN_DIRECTION, hit.hitNormal), 0.0);
    diffuse = diffuse*(1.0-shadow);
    
    color *= diffuse * 0.6 + ambient * 0.4;
    
    vec2 occlusions = smoothstep(vec2(0.0), vec2(10.0, 3.0), hit.volAccum);
    color = mix(color, vec3(0.3, 0.3, 0.5), occlusions.y); // water
    color = mix(color, vec3(0.6), occlusions.x);           // cloud
    
    // blend with other intersection. will be fractional when anti-aliasing or underwater
    color *= hit.weight;
    
    return color;
}


VoxelHit marchReflection(VoxelHit hit, vec3 prevrd)
{
    vec3 ro = hit.hitRel + vec3(hit.mapPos) + 0.5;
    vec3 rd = reflect(prevrd, hit.hitNormal);
    ro += 0.01*rd;
    
    ivec3 mapPos = ivec3(floor(ro));
    vec3 deltaDist = abs(vec3(length(rd)) / rd);
    ivec3 rayStep = ivec3(sign(rd));
    vec3 sideDist = (sign(rd) * (vec3(mapPos) - ro) + (sign(rd) * 0.5) + 0.5) * deltaDist; 
    vec2 volAccum = hit.volAccum;
    float prevDist = 0.0;
	
    for (int i = 0; i < 16; i++) {

        // check current position for voxel
        vec2 occlusions;  int terrainType;
        getVoxelAndOcclusionsAt(mapPos, terrainType, occlusions);
        
        // if intersected, finish
        if (terrainType != VOXEL_NONE) {
            vec3 hitVoxelCenter = vec3(mapPos) + 0.5;
    		vec3 cubeIntersect = (hitVoxelCenter - ro - 0.5*sign(rd))/rd;
    		float dist = max(cubeIntersect.x, max(cubeIntersect.y, cubeIntersect.z));
            vec3 hitRel = ro + rd * dist - hitVoxelCenter;
            return VoxelHit(mapPos, terrainType, volAccum, hitRel, nrmVoxel(hitRel, terrainType), 1.0);
        }

        // march forward to next position
        float newDist = min( sideDist.x, min(sideDist.y, sideDist.z ));
        vec3 mi = step( sideDist.xyz, sideDist.yzx ); 
        vec3 mm = mi*(1.0-mi.zxy);
        sideDist += mm * vec3(rayStep) / rd;
        mapPos += ivec3(mm)*rayStep;
        
        // accumulate occlusions
        volAccum += occlusions * (newDist - prevDist);
        prevDist = newDist;
    }
    
    // no intersection
    return VoxelHit(mapPos, VOXEL_NONE, volAccum, vec3(0.0), vec3(0.0), 1.0);
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
    VoxelMarchResult result = voxelMarch(ro, rd);
    
    // if first intersection is with water surface, march reflection
    if (result.first.terrainType == VOXEL_WATER) {
        result.first = marchReflection(result.first, rd);
        result.first.weight = 0.5;
        result.second.weight = 0.5;
    }
    
    // color
    vec3 color1 = doColoring(result.first, rd);
    vec3 color2 = doColoring(result.second, rd);
    vec3 color = color1 + color2;
    
	fragColor = vec4(color,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
