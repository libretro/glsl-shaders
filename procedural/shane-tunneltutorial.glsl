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



// 2D rotation. Always handy.
mat2 rot(float th){ float cs = cos(th), si = sin(th); return mat2(cs, -si, si, cs); }

// 3D Voronoi-like function. Cheap, low quality, 1st and 2nd order 3D Voronoi imitation.
//
// I wrote this a while back because I wanted a stand-alone algorithm fast enough to produce regular, or 2nd order, 
// Voronoi-looking patterns in a raymarching setting. Anyway, this is what I came up with. Obviously, it wouldn't 
// pass as genuine 3D Voronoi, but there's only so much you can do with a few lines. Even so, it has a Voronoi feel
// to it. Hence, Voronesque.
//
// Here's a rough explanation of how it works: Instead of partitioning space into cubes, partition it into its 
// simplex form, namely tetrahedrons. Use the four tetrahedral vertices to create some random falloff values, then 
// pick off the two highest, or lowest, depending on perspective. That's it. If you'd like to know more, the 
// function is roughly commented, plus there's a simplex noise related link below that should make it more clear.
//
// Credits: Ken Perlin, the creator of simplex noise, of course. Stefan Gustavson's paper - "Simplex Noise Demystified."
// IQ, other "ShaderToy.com" people, Brian Sharpe (does interesting work), etc.
//
// My favorite simplex-related write up: "Simplex Noise, keeping it simple." - Jasper Flick?
// http://catlikecoding.com/unity/tutorials/simplex-noise/
//
float Voronesque( in vec3 p ){
    
    // Skewing the cubic grid, then determining the first vertice.
    vec3 i  = floor(p + dot(p, vec3(0.333333)) );  p -= i - dot(i, vec3(0.166666)) ;
    
    // Breaking the skewed cube into tetrahedra with partitioning planes, then determining which side of the 
    // intersecting planes the skewed point is on. Ie: Determining which tetrahedron the point is in.
    vec3 i1 = step(0., p-p.yzx), i2 = max(i1, 1.0-i1.zxy); i1 = min(i1, 1.0-i1.zxy);    
    
    // Using the above to calculate the other three vertices. Now we have all four tetrahedral vertices.
    vec3 p1 = p - i1 + 0.166666, p2 = p - i2 + 0.333333, p3 = p - 0.5;
    
    vec3 rnd = vec3(7, 157, 113); // I use this combination to pay homage to Shadertoy.com. :)
    
    // Falloff values from the skewed point to each of the tetrahedral points.
    vec4 v = max(0.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.);
    
    // Assigning four random values to each of the points above. 
    vec4 d = vec4( dot(i, rnd), dot(i + i1, rnd), dot(i + i2, rnd), dot(i + 1., rnd) ); 
    
    // Further randomizing "d," then combining it with "v" to produce the final random falloff values. Range [0, 1]
    d = fract(sin(d)*262144.)*v*2.; 
 
    // Reusing "v" to determine the largest, and second largest falloff values. Analogous to distance.
    v.x = max(d.x, d.y), v.y = max(d.z, d.w), v.z = max(min(d.x, d.y), min(d.z, d.w)), v.w = min(v.x, v.y); 
   
    return  max(v.x, v.y)- max(v.z, v.w); // Maximum minus second order, for that beveled Voronoi look. Range [0, 1].
    //return max(v.x, v.y); // Maximum, or regular value for the regular Voronoi aesthetic.  Range [0, 1].
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    // Screen coordinates, plus some movement about the center.
    vec2 uv = (fragCoord.xy - iResolution.xy*0.5)/iResolution.y + vec2(0.5*cos(iGlobalTime*0.5), 0.25*sin(iGlobalTime*0.5));
    
    // Unit direction ray.
    vec3 rd = normalize(vec3(uv, 1.));
    rd.xy *= rot(sin(iGlobalTime*0.25)*0.5); // Very subtle look around, just to show it's a 3D effect.
    rd.xz *= rot(sin(iGlobalTime*0.25)*0.5);
 
    // Screen color. Initialized to black.
    vec3 col = vec3(0);
    
    // Ray intersection of a cylinder (radius one) - centered at the origin - from a ray-origin that has XY coordinates 
    // also centered at the origin.
    //float sDist = max(dot(rd.xy, rd.xy), 1e-16); // Analogous to the surface function.
    //sDist = 1./sqrt(sDist); // Ray origin to surface distance.
    
    // Same as above, but using a Minkowski distance and scaling factor. I tried it on a whim, and it seemed to work.
    // I know, not scientific at all, but it kind of makes sense. They'll let anyone get behind a computer these days. :)
    vec2 scale = vec2(0.75, 1.);
    float power = 6.;
    float sDist = max(dot( pow(abs(rd.xy)*scale, vec2(power)), vec2(1.) ), 1e-16); // Analogous to the surface function.
    sDist = 1./pow( sDist, 1./power ); // Ray origin to surface distance.
    
    //if(sDist>1e-8){
        
        // Using the the distance "sDist" above to calculate the surface position. Ie: sp = ro + rd*t;
        // I've hardcoded "ro" to reduce line count. Note that "ro.xy" is centered on zero. The cheap
        // ray-intersection formula above relies on that.
        vec3 sp = vec3(0.0, 0.0, iGlobalTime*2.) + rd*sDist;
 
        // The surface normal. Based on the derivative of the surface description function. See above.
        //vec3 sn = normalize(vec3(-sp.xy, 0.)); // Cylinder normal.
        vec3 sn = normalize(-sign(sp)*vec3(pow(abs(sp.xy)*scale, vec2(power-1.)), 0.)); // Minkowski normal.
        
        // Bump mapping.
        //
        // I wanted to make this example as simple as possible, but it's only a few extra lines. Note the larger 
        // "eps" number. Increasing the value spreads the samples out, which effectively blurs the result, thus 
        // reducing the jaggies. The downside is loss of bump precision, which isn't noticeable in this particular 
        // example. Decrease the value to "0.001" to see what I'm talking about.
        const vec2 eps = vec2(0.025, 0.);
        float c = Voronesque(sp*2.5); // Base value. Used below to color the surface.
        // 3D gradient vector... of sorts. Based on the bump function. In this case, Voronoi.                
        vec3 gr = (vec3(Voronesque((sp-eps.xyy)*2.5), Voronesque((sp-eps.yxy)*2.5), Voronesque((sp-eps.yyx)*2.5))-c)/eps.x;
        gr -= sn*dot(sn, gr); // There's a reason for this... but I need more room. :)
        sn = normalize(sn + gr*0.1); // Combining the bump gradient vector with the object surface normal.

        // Lighting.
        //
        // The light is hovering just in front of the viewer.
        vec3 lp = vec3(0.0, 0.0, iGlobalTime*2. + 3.);
        vec3 ld = lp - sp; // Light direction.
        float dist = max(length(ld), 0.001); // Distance from light to the surface.
        ld /= dist; // Use the distance to normalize "ld."

        // Light attenuation, based on the distance above.
        float atten = min(1.0/max(0.75 + dist*0.25 + dist*dist*0.05, 0.001), 1.0);
        
       
        float diff = max(dot(sn, ld), 0.); // Diffuse light value.
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.), 16.); // Specular highlighting.
        // Adding some fake, reflective environment information.
        float ref = Voronesque((sp + reflect(rd, sn)*0.5)*2.5);
        
        // Coloring the surface with the Voronesque function that is used to bump the surface. See "bump mapping" above.
        vec3 objCol = vec3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)); // Cheap, but effective, red palette.
        //vec3 objCol = vec3(c*c*0.9, c, c*c*0.4); // Cheap green palette.
        //vec3 objCol = vec3(pow(c, 1.6), pow(c, 1.7), c); // Purpley blue.
        //vec3 objCol = vec3(c); // Grey scale.

        // Using the values above to produce the final color.
        //col = (objCol*(diff + ref*0.25 + 0.25) + vec3(1., 0.8, 0.9)*ref*0.25 + spec*vec3(0.75, 0.9, 1.))*atten;
        col = (objCol*(vec3(1.0, 0.97, 0.92)*diff + ref*0.5 + 0.25) + vec3(1., 0.8, 0.9)*ref*0.3 + vec3(1., 0.9, 0.7)*spec)*atten;
        //col = ((vec3(1.0, 0.97, 0.92)*diff + ref*0.5 + 0.25)*c + vec3(1., 0.8, 0.9)*ref*0.3 + vec3(0.75, 0.9, 1.)*spec)*atten;
         
        
    //}
    
    fragColor = vec4(min(col, 1.), 1.);
}

void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif