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

float zigzag( float x )
{ 
   /* float y = mod(x,3.142 ) / 3.142;
    if ( y > 0.5 )
    {
        return 1.0-(y -0.5)/0.5;
    }
    return (y*2.0); */
    
    return cos(x);
}

float box( vec3 position, vec3 lengths, vec3 raypos )
{
    vec3 p = raypos - position;
    
    float d0 = max( p.x - lengths.x, -p.x - lengths.x );
    float d1 = max( p.y - lengths.y, -p.y - lengths.y );
    float d2 = max( p.z - lengths.z, -p.z - lengths.z );
    return vec4( max( d0, max(d1,d2 )), 1.0,0, 0.8).x;
}

float cylinder( vec3 position, vec2 dim, vec3 raypos )
{
    vec3 p = raypos - position;
    return max( length( p.zy ) - dim.x,
                 max( p.x - dim.y, -p.x - dim.y));
}



float feature( vec3 position, vec2 dim, vec3 raypos )
{
 
   // float zoff = float(int(raypos.z / 10.0));
    float y = (iGlobalTime*100.0);
    float x = -zigzag( (y+raypos.z)/100.0 )*40.0;
    
    position.y -= floor( mod( (raypos.z + y) / 1000.0 , 2.0 )) * 10.0;
    
    //roadpos.y += iGlobalTime*100.0;
    //position.x += x; //zigzag( raypos.z/100.0 )*40.0 ;
    
    //position.x = x;
    float c0, c1, c2;
    {
    vec3 r = vec3( raypos.x, raypos.y, mod( raypos.z + y + 1000.0, 10.0 ) );
  //  vec3 r = mod( raypos,10.0 );
    vec3 p = r - vec3( position.x + x, position.y, position.z  );
    c0 =  max( length( p.zx ) - dim.x,
                 max( p.y - dim.y, -p.y - dim.y));
    }
    
     {
    vec3 r = vec3( raypos.x, raypos.y, mod( raypos.z + 1000.0 + y, 10.0 ) );
    vec3 p = r - vec3( -position.x + x, position.y, position.z );
    c1 =  max( length( p.zx ) - dim.x,
                 max( p.y - dim.y, -p.y - dim.y));
    }
    
    {
    vec3 r = vec3( raypos.x, raypos.y, mod( raypos.z + 1000.0 + y, 10.0 ) );
    vec3 p = r - vec3(  x, position.y + dim.y, position.z );
    c2 =  max( length( p.zy ) - dim.x * 0.5,
                 max( p.x - 15.0, -p.x - 15.0));
    }
    
    return min( min(c0,c1 ), c2 );
}



vec4 road( vec2 roadpos )
{
    vec4 surface = vec4( 0.5,0.5,0.5,1.0);

    
    roadpos.y += iGlobalTime*100.0;
    roadpos.x += zigzag( roadpos.y/100.0 )*40.0 ;
    vec2 roadabs = abs(roadpos );
    
    if ( roadabs.x > 10.0 )
    {
    
        if ( roadabs.x > 12.0)
        {
        	surface = vec4(0.0,1.0,0.0,1.0 );
        }
        else
        {
            float fy =  floor( (roadabs.y) / 0.8 );
            if ( mod( fy, 2.0 ) == 0.0 )
            {
            	surface = vec4( 1,1,1,1.0);
            }
            else
            {
                surface = vec4( 1.0,0.0,0.0,1.0);
            }
        }
    }
    else
    {
        if ( roadabs.x < 0.1 )
        {
            float fy =  floor( (roadabs.y + 2.0 ) / 4.0 );
            if ( mod( fy, 2.0 ) == 0.0 )
            {
            	surface = vec4( 1,1,1,1.0);
            }
            else
            {
                surface = vec4( 0.5,0.5,0.5,1.0);
            }
        }
        else 
        {
        	surface = vec4( 0.5,0.5,0.5,1.0);
        }
    }
    
    float fy = floor( roadabs.y / 20.0 );
    
    
    
    
    if ( mod( fy, 2.0 ) == 0.0 ) 
    {
        surface *= 0.8;
    }
    
    return surface;
     
}

float sphere( vec3 spherepos, float r, vec3 raypos )
{
    return distance( spherepos, raypos ) - r;
}

vec4 getlight( vec3 normal, vec3 position, vec3 lightpos, vec4 lightcolour  )
{
    vec4 amb = vec4(0.3,0.3,0.3,1.0);
    float d = distance( position, lightpos );
    vec3 n = normalize( position - lightpos );
    if ( dot( normal, n ) > 0.5 )
    {
        return lightcolour + amb;;
    }
    else if ( dot( normal, n ) > 0.1 )
    {
        return lightcolour * 0.5 + amb;;
    }
        
    return amb;
    
}


float smin( float a,  float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    float blend = -log( res )/k;
    return blend;
}


float sdf( vec3 raypos )
{
#ifdef MOUSE
    float xpos = iMouse.x / iResolution.x - 0.5 ;
#else
    float xpos = 0.0 / iResolution.x - 0.5 ;
#endif
    float y = (iGlobalTime-3.0)*100.0;
    float x = (xpos * 0.0 + zigzag( y/100.0 ))*40.0;
    //float e = 1.0; //abs( 0.5 + abs( cos( iGlobalTime )) * 3.0 ) ;
    float sdf0 = cylinder( vec3( x, 0.5, 0.0 ), vec2( 0.49,1.3 ), raypos  );
    float sdf1 = cylinder( vec3( x, 0.5, 2.0 ), vec2( 0.49,1.2 ), raypos  );
    float sdf2 =  box( vec3( x, 0.7, 1.0 ), vec3( 1.0, 0.5, 1.0), raypos);
    float sdf3 =  feature( vec3(15.0,0,5.0), vec2(1.0,4.0), raypos );

    return 
        	 min( sdf3, 
                min( sdf2, 
                    min( sdf1, 
                        min( sdf0, min(raypos.y, 20.0-raypos.y )) 
                    )
                )
              );
                    //sphere( vec3( 0,10, 0.0), 2.0, raypos ), e );
}

vec4 contact( vec3 position, vec3 normal, float scale )
{
    float s = sdf( position + normal * scale );
    
    if ( s < scale )
    {
        return vec4(0.8,0.8,0.8,1.0);
    }
    
    return   vec4(1.0,1.0,1.0,1.0);
    
    
}

vec3 grad( vec3 raypos, float delta )
{
    float dx =  sdf( raypos + vec3( delta, 0,0 ) ) - sdf( raypos - vec3( delta,0,0 ) );
    float dy =  sdf( raypos + vec3( 0, delta,0 ) ) - sdf( raypos - vec3( 0,delta,0 ) );
    float dz =  sdf( raypos + vec3( 0,0, delta ) ) - sdf( raypos - vec3( 0,0,delta ) );
    return vec3( dx,dy,dz );
    //return vec3(0,-1.0,0);
}

vec4 march( vec3 ray, vec3 origin, float ep, vec2 uv)
{
    vec3 p = origin;
    //int pscale = int(  float(iFrameRate) / 60.0 * 1024.0);
    for ( int i = 0; i < 256; i++ )
    {
       /* if ( i == pscale )
        {
            break;
        } */ 
        float step = sdf(p);
        if ( step  <  ep )
        {
            if ( p.y  > 19.0 )
            {
    			return vec4( 0.3,0.3,1.0,1.0) *  ( (uv.y - 0.5) / 0.5  ) + 
                       vec4( 1.0,1.0,1.0,1.0) *  (1.0 - ( (uv.y-0.5) / 0.5  )) ;
            }
            else if ( p.y  > ep )
            {
            	vec3 normal = normalize( grad( p, 0.1 ) );
            	return getlight( normal, p,  vec3( 500 ,0,1000 ), vec4(1.0, 1.0, 1.0, 0 ));
                	   //getlight( normal, p,  vec3( -100,-100,-100 ), vec4(0.0,1.0,1.0,1.0 )) ;
            }
        	
            else 
        	{
            	return road( vec2( p.x, p.z ) ) * contact( p, vec3(0.0,1.0,0.0), 0.25 );
        	}
        }
        
        p += ray * step;
    }
    
    if ( ray.y < 0.0 )
    {
    	vec3 h = ray * -origin.y / ray.y + origin;
 		return road( vec2( h.x, h.z ) ) * contact( p, vec3(0.0,1.0,0.0), 0.25 );
    }
    else
    {
   
    return vec4( 0.3,0.3,1.0,1.0) *  ( (uv.y - 0.5) / 0.5  ) + 
           vec4( 1.0,1.0,1.0,1.0) *  (1.0 - ( (uv.y-0.5) / 0.5  )) ; 
    }
}

vec3 rotatevecY( vec3 vec, float angle )
{
    vec3 m0 = vec3( -cos( angle ), 0, sin( angle ));
    vec3 m1 = vec3( 0            , 1.0,   0      );
    vec3 m2 = vec3( sin( angle ), 0, cos( angle ) );
    
    return vec3(  dot( m0, vec ), dot( m1, vec ), dot( m2, vec )) ;
} 


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    /*if ( uv.y > 0.8 )
    {
        fragColor = vec4( 0.3,0.3,1.0,1.0) *  ( (uv.y - 0.5) / 0.5  ) + 
                    vec4( 1.0,1.0,1.0,1.0) *  (1.0 - ( (uv.y-0.5) / 0.5  )) ;
    }
    else */ 
    {
         float aspect = iResolution.y / iResolution.x;
    
    	 vec3 origin = vec3(0.0, 2.0,-5.0 );
    	 vec3 ray = vec3( uv.x - 0.5, (uv.y - 0.5) * aspect, 0.5 );
    
        
        float y = (iGlobalTime-0.0)*100.0;
        float x = zigzag( y/100.0 )*40.0;
   
    	ray = rotatevecY( ray, x/80.0 );
        origin.x += x;
    	origin = rotatevecY( origin, 0.0 );
    
		fragColor = march( ray, origin, 0.01, uv );
        
        //float y = (iGlobalTime-0.0)*100.0;
        //float x = zigzag( y/100.0 )*40.0;
        
        //vec2 vp = uv - vec2(0.5,0.5 );
  		//vec2 rp = vec2( -x + vp.x / -vp.y * 5.0,  5.0 / -vp.y 	);
        
		//fragColor = road( rp);
    }
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
