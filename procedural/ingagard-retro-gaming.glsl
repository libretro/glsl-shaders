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

//////////////////////////////////////////////////////////////////////////////////////
///////////////////// CREATED BY KIM BERKEBY, SEP 2017 ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////// BIG THANKS TO Inigo Quilez FOR PROVIDING THE SHAPE DISTANCE FUNCTIONS /////////
//////////////////////////////////////////////////////////////////////////////////////

struct RayHit
{
  bool hit;  
  vec3 hitPos;
  vec3 normal;
  float dist;
  float depth;
  float steps;
  int hitID;
};


RayHit marchResult;


float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdTriPrism( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.z-h.y, max(q.x*0.866025+p.y*0.5, -p.y)-h.x*0.5);
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa, ba)/dot(ba, ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

#define rotate(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float Cable( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a;
  b.xz = mix(b.xz, b.xz*rotate(1.1), smoothstep(1.0, 6.0, pa.z));
  b.xz = mix(b.xz, b.xz*rotate(-1.20), smoothstep(1.0, 14.0, pa.z));
  b.y = mix(b.y, -1.55, smoothstep(.0, 1.0, pa.z));

  vec3 ba = b - a;
  float h = clamp( dot(pa, ba)/dot(ba, ba), 0.0, 1.0 );

  return length( pa - ba*h ) - r;
}


float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
  return (length( p/r ) - 1.0) * min(min(r.x, r.y), r.z);
}


vec3 opRotXY( vec3 pos, vec3 rayPos, float rad )
{
  vec3 sPos = rayPos-pos;
  sPos.xy *= rotate(rad);
  return sPos+rayPos;
}
vec3 opRotXZ( vec3 pos, vec3 rayPos, float rad )
{
  vec3 sPos = rayPos-pos;
  sPos.xz *= rotate(rad);
  return sPos+rayPos;
}
vec3 opRotYZ( vec3 pos, vec3 rayPos, float rad )
{
  vec3 sPos = rayPos-pos;
  sPos.yz *= rotate(rad);
  return sPos+rayPos;
}



float ControllerBase(in vec3 p, vec3 oPos, float oScale)
{

  float d = sdCappedCylinder(p-oPos-vec3(1.40, -0.04, 0.0), vec2(1.0, 0.12)*oScale);
  d = min(d, sdCappedCylinder(p-oPos-vec3(-1.40, -0.04, 0.0), vec2(1.0, 0.12)*oScale));
  d = min(d, sdCappedCylinder(p-oPos-vec3(-.35, 0.0, -.40), vec2(0.5, 0.08)*oScale));
  d = min(d, sdCappedCylinder(p-oPos-vec3(.35, 0.0, -.40), vec2(0.5, 0.08)*oScale));


  d=min(d, sdBox(p-oPos-vec3(.0, 0.0, 0.2), vec3(1.0, .08, 0.7)*oScale));
  d = min(d, sdBox(p-oPos-vec3(.0, 0.0, 0.2), vec3(0.50, .07, 0.79)*oScale));
  d=max(d, -sdBox(p-oPos-vec3(.0, 0.0, 1.1), vec3(0.20, 1.08, 0.15)*oScale));   

  return d;
}

float ShoulderButtons(in vec3 p, float controllBase, vec3 oPos, float oScale)
{
  float d = sdCappedCylinder(p-oPos-vec3(1.45, -0.1, 0.10), vec2(1.0, 0.12)*oScale);
  d = min(d, sdCappedCylinder(p-oPos-vec3(-1.45, -0.1, 0.10), vec2(1.0, 0.12)*oScale));
  d =  min(d, sdBox(p-oPos-vec3(.0, -0.1, 0.2), vec3(1.60, .08, 0.8)*oScale));

  d=  max(d, -sdBox(p-oPos-vec3(.0, 0.0, 0.42), vec3(1.2, 1.08, 2.9)*oScale));
  d=  max(d, -sdBox(p-oPos-vec3(2.50, 0.0, 0.42), vec3(0.4, 1.08, 2.9)*oScale));
  d=  max(d, -sdBox(p-oPos-vec3(-2.50, 0.0, 0.42), vec3(0.4, 1.08, 2.9)*oScale));

  d=  max(d, -sdBox(p-oPos-vec3(0, 0.0, -0.42), vec3(3.0, 0.68, 1.)*oScale));

  return d;
}


float d,d1,d2,d3,d4,d5,d6,d7,d8,d9;

float Map( in vec3 p)
{
    d,d1,d2,d3,d4,d5,d6,d7,d8,d9 = 100000.0;
    
  d8 = ControllerBase(p, vec3(0, -0.51, 1.0), 1.05);
  d = ControllerBase(p, vec3(0, -0.3, 1.0), 1.0);

  // button ring
  d=  max(d, -sdCappedCylinder(p-vec3(-1.45, -0.22, 1.0), vec2(0.8, 0.02)));
  d8=  min(d8, sdCappedCylinder(p-vec3(-1.45, -0.25, 1.0), vec2(0.765, 0.03)));
  d8=  min(d8, sdEllipsoid(p-vec3(-1.45, -0.25, 1.0), vec3(0.7, 0.1, 0.7)));

  // button holes
  d8=  max(d8, -sdEllipsoid(p-vec3(-1.45, -0.18, 1.40), vec3(0.32, 0.06, 0.32)));
  d8=  max(d8, -sdEllipsoid(p-vec3(-1.45, -0.18, .60), vec3(0.32, 0.06, 0.32)));
  d8=  max(d8, -sdEllipsoid(p-vec3(-1.90, -0.18, 1.0), vec3(0.32, 0.06, 0.32)));
  d8=  max(d8, -sdEllipsoid(p-vec3(-1.00, -0.18, 1.0), vec3(0.32, 0.06, 0.32)));

  // buttons
  d2= sdCappedCylinder(p-vec3(-1.45, -0.3, 1.40), vec2(0.18, 0.12));
  d9= sdCappedCylinder(p-vec3(-1.45, -0.3, 0.60), vec2(0.18, 0.12));
  d2= min(d2, sdCappedCylinder(p-vec3(-1.90, -0.3, 1.0), vec2(0.18, 0.12)));
  d9= min(d9, sdCappedCylinder(p-vec3(-1.0, -0.3, 1.0), vec2(0.18, 0.12)));

  // button details       
  d2=  max(d2, -sdEllipsoid(p-vec3(-1.45, -0.16, 1.40), vec3(0.25, 0.04, 0.25)));
  d9=  max(d9, -sdEllipsoid(p-vec3(-1.45, -0.16, .60), vec3(0.25, 0.04, 0.25)));
  d2=  max(d2, -sdEllipsoid(p-vec3(-1.90, -0.16, 1.0), vec3(0.25, 0.04, 0.25)));
  d9=  max(d9, -sdEllipsoid(p-vec3(-1.0, -0.16, 1.0), vec3(0.25, 0.04, 0.25)));

  // cross cutout
  d=  max(d, -sdEllipsoid(p-vec3(1.55, -0.22, 1.0), vec3(0.7, 0.1, 0.7)));
  d=  max(d, -sdEllipsoid(p-vec3(1.55, -0.22, 1.0), vec3(1.0, 0.03, 1.0)));
  d3 = sdEllipsoid(p-vec3(1.55, -0.265, 1.0), vec3(.46, 0.06, .46));

  // cross
  d3 = min(d3, sdBox(p-vec3(1.55, -0.22, 1.0), vec3(0.4, 0.06, 0.13)));
  d3 = min(d3, sdBox(p-vec3(1.55, -0.22, 1.0), vec3(0.13, 0.06, 0.4)));

  // cross details
  d3=  max(d3, -sdEllipsoid(p-vec3(1.55, -0.2, 1.0), vec3(0.16, 0.04, 0.16)));

  // calculate button arrows and perform boolean
  vec3 pPos = p-vec3(1.55, -0.13, 1.25);
  pPos.xz *=rotate(radians(120.0));
  pPos.zy *=rotate(radians(90.0));
  d3 = max(d3, -sdTriPrism(pPos, vec2(.15, 0.05)));

  pPos = p-vec3(1.55, -0.13, 0.75);
  pPos.xz *=rotate(radians(300.0));
  pPos.zy *=rotate(radians(90.0));
  d3 = max(d3, -sdTriPrism(pPos, vec2(.15, 0.05)));

  pPos = p-vec3(1.8, -0.13, 1.0);
  pPos.xz *=rotate(radians(210.0));
  pPos.zy *=rotate(radians(90.0));
  d3 = max(d3, -sdTriPrism(pPos, vec2(.15, 0.05)));

  pPos = p-vec3(1.3, -0.13, 1.0);
  pPos.xz *=rotate(radians(30.0));
  pPos.zy *=rotate(radians(90.0));
  d3 = max(d3, -sdTriPrism(pPos, vec2(.15, 0.05)));

  // cable input
  d=max(d, -sdCapsule(p-vec3(.0, -0.4, 2.1), vec3(0.0, 0.0, -0.5), vec3(0.0, 0.0, 3.0), 0.13));   
  d=min(d, sdCapsule(p-vec3(.0, -0.39, 2.07), vec3(0.0, 0.0, -0.1), vec3(0.0, 0.0, -0.1), 0.11));   

  // cable
  d4 = sdCapsule(p-vec3(.0, -0.39, 2.07), vec3(0.0, 0.0, 0), vec3(0.0, 0.0, 0), 0.11);       
  d4=min(d4, Cable(p-vec3(.0, -0.4, 2.1), vec3(0., 0., -1.0), vec3(0., 0., 70.0), 0.072));   

  // analog buttons
  d= max(d, -sdEllipsoid(p-vec3(0.35, -0.15, .50), vec3(0.4, 0.2, 0.4)));
  d= max(d, -sdEllipsoid(p-vec3(-0.35, -0.15, .50), vec3(0.4, 0.2, 0.4)));

  d5=  sdEllipsoid(p-vec3(0.35, -0.35, .50), vec3(0.3, 0.18, 0.3));
  d5= min(d5, sdCappedCylinder(p-vec3(0.35, -0.35, .50), vec2(0.15, 0.3)));
  d5=  min(d5, sdEllipsoid(p-vec3(0.35, -0.05, .50), vec3(0.22, 0.03, 0.22)));

  d5=  min(d5, sdEllipsoid(p-vec3(-0.35, -0.35, .50), vec3(0.3, 0.18, 0.3)));
  d5= min(d5, sdCappedCylinder(p-vec3(-0.35, -0.35, .50), vec2(0.15, 0.3)));
  d5=  min(d5, sdEllipsoid(p-vec3(-0.35, -0.05, .50), vec3(0.22, 0.03, 0.22)));

  // start select cutouts
  d=max(d, -sdCapsule(p-vec3(-.1, -.06, 1.4), vec3(0., 0., -0.15), vec3(-0.22, 0., 0.05), 0.2));   
  d=max(d, -sdCapsule(p-vec3(.45, -.06, 1.4), vec3(0., 0., -0.15), vec3(-0.22, 0., 0.05), 0.2));   

  // start select buttons
  d7=sdCapsule(p-vec3(-.1, -.25, 1.4), vec3(0., 0., -0.15), vec3(-0.22, 0., 0.05), 0.095);   
  d7=min(d7, sdCapsule(p-vec3(.45, -.25, 1.4), vec3(0., 0., -0.15), vec3(-0.22, 0., 0.05), 0.095));   

  d6 = ShoulderButtons(p, d, vec3(0, -0.3, 1.0), 1.0);

    
  return  min(d,min(d2,min(d3,min(d4,min(d5,min(d6,min(d7,min(d8,min(d9,p.y+0.75)))))))));
}


vec3 calcNormal( in vec3 pos )
{   
    const vec3 eps = vec3(0.02, 0.0, 0.0);
  return normalize( vec3(Map(pos+eps.xyy) - Map(pos-eps.xyy), 0.5*2.0*eps.x, Map(pos+eps.yyx) - Map(pos-eps.yyx) ) );
}

float SoftShadow( in vec3 origin, in vec3 direction )
{
  float res = 2.0;
  float t = 0.0;
  float hardness = 6.50;
  for ( int i=0; i<10; i++ )
  {
    float h = Map(origin+direction*t);
    res = min( res, hardness*h/t );
    t += clamp( h, 0.02, 0.075 );
    if ( h<0.002 ) break;
  }
  return clamp( res, 0.0, 1.0 );
}


RayHit March(in vec3 origin, in vec3 direction, float maxDist, float precis, int maxSteps)
{
  RayHit result;

  float t = 0.0, dist = 0.0, distStep = 1.0;
  vec3 rayPos =vec3(0);

  for ( int i=0; i<maxSteps; i++ )
  {
    rayPos =origin+direction*t;
    dist = Map( rayPos);

    if (abs(dist)<precis || t>maxDist )
    {    
        result.hitID =10;
        
        if(d == dist){  result.hitID =1;}
        else if(d2 == dist){  result.hitID =2;}
        else if(d3 == dist){  result.hitID =3;}
        else if(d4 == dist){  result.hitID =4;}
        else if(d5 == dist){  result.hitID =5;}
        else if(d6 == dist){  result.hitID =6;}
        else if(d7 == dist){  result.hitID =7;}
        else if(d8 == dist){  result.hitID =8;}
        else if(d9 == dist){  result.hitID =9;}
   
      result.depth = t; 
      result.dist = dist;                              
      result.hitPos = origin+((direction*t)*0.99);   
      result.steps = float(i);
      break;
    }
    t += dist*distStep;
  }


  return result;
}

// Thanks to Inigo Quilez
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}

vec3 GetSceneLight(float specLevel, vec3 normal, vec3 pos, vec3 rayDir)
{      
  vec3 light1 = normalize(vec3(-1.0, 2.8, 1.0));
    
  vec3 reflectDir = reflect( rayDir, normal );
  specLevel *= pow(clamp( dot( reflectDir, light1 ), 0.0, 1.0 ), 16.0);

  float amb = clamp( 0.5+0.5*normal.y, 0.0, 1.0 );
  float diffuse = clamp( dot( normal, light1 ), 0.0, 1.0 );
  float skyLight = smoothstep( -0.1, 0.1, reflectDir.y );
  float fill = pow( clamp(1.0+dot(normal, rayDir), 0.0, 1.0), 1.0 )*1.0;
  float backLight = clamp( dot( normal, normalize(vec3(-light1.x, 0.0, -light1.z))), 0.0, 1.0 )*5.0;

  diffuse *= SoftShadow( pos, light1);
  skyLight *= SoftShadow( pos, reflectDir);

  vec3 lightTot = 1.30*diffuse*vec3(1.00, 0.80, 0.55);
  lightTot += specLevel*vec3(1.00, 0.90, 0.70)*diffuse;
  lightTot += 0.40*amb*vec3(0.40, 0.60, 1.00);
  lightTot += 0.50*skyLight*vec3(0.40, 0.60, 1.00);
  lightTot += 0.50*backLight*vec3(0.25, 0.25, 0.25);

  return lightTot+(0.25*fill*vec3(1.00, 1.00, 1.00));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{  
#ifdef MOUSE
  vec2 mo = iMouse.xy/iResolution.xy;
#else
  vec2 mo = 0.0/iResolution.xy;
#endif
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;

  float camrot = 0.5*iGlobalTime;
#ifdef MOUSE
  if (iMouse.w>0.1) camrot=0.0; 
#endif

  vec3 rayOrigin = vec3( -0.5+3.5*cos(camrot + 6.0*mo.x), 1.0 + 2.0, 0.5 + 4.0*sin(camrot + 6.0*mo.x) );
  mat3 ca = setCamera( rayOrigin, vec3( 0.0, -0.9, 0.5 ), 0.0 );
  vec3 rayDir = ca * normalize( vec3(screenSpace.xy, 2.0) );
  vec4 color =vec4(0);

   marchResult = March(rayOrigin, rayDir, 110.0, 0.001, 128);
   marchResult.normal = calcNormal(marchResult.hitPos); 
    
      // pad top, buttons, cross, cable, sticks, shoulder buttons
  const vec4[10] partColor = vec4[] (vec4(.65, 0.14, 0.14, 0.6), // pad top
  vec4(0.5, 0.14, .14, 0.6), //buttons
  vec4(.3, 0.3, 0.3, 0.5), //cross
  vec4(0.2, 0.2, 0.2, 0.35), //cable
  vec4(.3, 0.3, 0.3, 0.4), //sticks
  vec4(0.5, 0.5, .5, 0.6), // shoulder buttons
  vec4(.3, 0.3, 0.3, 0.5), // start/select
  vec4(.3, 0.3, 0.3, 0.4), // pad bottom
  vec4(0.5, 0.5, .5, 0.6), //buttons left
  vec4(.35, .35, .34, 0.3)); // ground
   vec4 col =partColor[marchResult.hitID-1];
   vec3 light = GetSceneLight(col.a, marchResult.normal, marchResult.hitPos, rayDir);   
    
    // reflections in floor
    if (marchResult.hitID==10)
    {
      vec3 refDir = normalize(reflect(rayDir, marchResult.normal));
      RayHit reflectResult = March(marchResult.hitPos + (refDir*0.001), refDir, 30.0, 0.03, 64); 

      if (reflectResult.hit==true)
      {
        col = mix(col, col+(col* partColor[reflectResult.hitID-1]), .65);
      }
    }

    float rim = clamp(1.0+dot(marchResult.normal, rayDir), 0.0, 1.0);
#ifdef TEXTURE
    vec4 ref = vec4(texture( iChannel0, marchResult.normal+rayDir).rgb, 1.0); 
    ref += rim*pow(0.5, 2.0);
    ref /= pow(2.0, col.a);
#endif

    // apply lightning
    color = col*vec4(light, 1.0);
#ifdef TEXTURE
    color.rgb= mix((color.rgb+(color.rgb*ref.rgb))*col.a, (color.rgb+vec3(1.4))*col.a, pow(marchResult.normal.r, 2.0));
#else
    color.rgb= mix((color.rgb+(color.rgb))*col.a, (color.rgb+vec3(1.4))*col.a, pow(marchResult.normal.r, 2.0));
#endif
  

  fragColor = vec4(pow(color.rgb, vec3(1.0/0.9)), 1.0 ) * (0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.2 ));
  //  fragColor = vec4(marchResult.normal,1.0);
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
