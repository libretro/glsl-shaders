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

//#define CARS
#define I_MAX 70

float rand(vec2 n) {
  return fract(sin((n.x*1e2+n.y*1e4+1475.4526)*1e-4)*1e6);
}

float noise(vec2 p)
{
    p = floor(p*200.0);
	return rand(p);
}
vec3 polygonXY(float z,vec2 vert1, vec2 vert2, vec3 camPos,vec3 rayDir){
    float t = -(camPos.z-z)/rayDir.z;
    vec2 cross = camPos.xy + rayDir.xy*t;
    if (cross.x>min(vert1.x,vert2.x) && 
        cross.x<max(vert1.x,vert2.x) &&
       	cross.y>min(vert1.y,vert2.y) &&
       	cross.y<max(vert1.y,vert2.y) &&
       dot(rayDir,vec3(cross,z)-camPos)>0.0){
        	float dist = length(camPos-vec3(cross,z));
            return vec3(dist, cross.x-min(vert1.x,vert2.x),cross.y-min(vert1.y,vert2.y));
        }
    
    return vec3(101.0,0.0,0.0);
}
vec3 polygonYZ(float x,vec2 vert1, vec2 vert2, vec3 camPos,vec3 rayDir){
    float t = -(camPos.x-x)/rayDir.x;
    vec2 cross1 = camPos.yz + rayDir.yz*t;
    if (cross1.x>min(vert1.x,vert2.x) && 
        cross1.x<max(vert1.x,vert2.x) &&
       	cross1.y>min(vert1.y,vert2.y) &&
       	cross1.y<max(vert1.y,vert2.y)&&
       dot(rayDir,vec3(x,cross1)-camPos)>0.0){
        	float dist = length(camPos-vec3(x,cross1));
            return vec3(dist, cross1.x-min(vert1.x,vert2.x),cross1.y-min(vert1.y,vert2.y));
        }
    
    return vec3(101.0,0.0,0.0);
}
vec3 polygonXZ(float y,vec2 vert1, vec2 vert2, vec3 camPos,vec3 rayDir){
    float t = -(camPos.y-y)/rayDir.y;
    vec2 cross1 = camPos.xz + rayDir.xz*t;
    if (cross1.x>min(vert1.x,vert2.x) && 
        cross1.x<max(vert1.x,vert2.x) &&
       	cross1.y>min(vert1.y,vert2.y) &&
       	cross1.y<max(vert1.y,vert2.y)&&
       dot(rayDir,vec3(cross1.x,y,cross1.y)-camPos)>0.0){
        	float dist = length(camPos-vec3(cross1.x,y,cross1.y));
            return vec3(dist, cross1.x-min(vert1.x,vert2.x),cross1.y-min(vert1.y,vert2.y));
        }
    
    return vec3(101.0,0.0,0.0);
}

vec3 textureWall(vec2 pos, vec2 maxPos, vec2 squarer,float s,float height,float dist,vec3 rayDir,vec3 norm){
    float randB = rand(squarer*2.0);
    vec3 windowColor =(-0.4+randB*0.8)*vec3(0.3,0.3,0.0)+(-0.4+fract(randB*10.0)*0.8)*vec3(0.0,0.0,0.3)+(-0.4+fract(randB*10000.0)*0.8)*vec3(0.3,0.0,0.0);
    float floorFactor = 1.0;
    vec2 windowSize = vec2(0.65,0.35);
    vec3 wallColor = s*(0.3+1.4*fract(randB*100.0))*vec3(0.1,0.1,0.1)+(-0.7+1.4*fract(randB*1000.0))*vec3(0.02,0.,0.);
	wallColor*=1.3;
    
    vec3 color = vec3(0.0);
    vec3 conturColor = wallColor/1.5;
    if (height<0.51){
    	windowColor += vec3(0.3,0.3,0.0);
        windowSize = vec2(0.4,0.4);
        floorFactor = 0.0;

    }
    if (height<0.6){floorFactor = 0.0;}
    if (height>0.75){
    	windowColor += vec3(0.0,0.0,0.3);
    }
    windowColor*=1.5;
    float wsize = 0.02;
    wsize+=-0.007+0.014*fract(randB*75389.9365);
    windowSize+= vec2(0.34*fract(randB*45696.9365),0.50*fract(randB*853993.5783));
    
    vec2 contur=vec2(0.0)+(fract(maxPos/2.0/wsize))*wsize;
    if (contur.x<wsize){contur.x+=wsize;}
    if (contur.y<wsize){contur.y+=wsize;}
    
	vec2 winPos = (pos-contur)/wsize/2.0-floor((pos-contur)/wsize/2.0);
    
    float numWin = floor((maxPos-contur)/wsize/2.0).x;
    
    if ( (maxPos.x>0.5&&maxPos.x<0.6) && ( ((pos-contur).x>wsize*2.0*floor(numWin/2.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin/2.0)) )){
     	   return (0.9+0.2*noise(pos))*conturColor;
    }
    
    if ( (maxPos.x>0.6&&maxPos.x<0.7) &&( ( ((pos-contur).x>wsize*2.0*floor(numWin/3.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin/3.0)) )||
                                          ( ((pos-contur).x>wsize*2.0*floor(numWin*2.0/3.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin*2.0/3.0)) )) ){
     	   return (0.9+0.2*noise(pos))*conturColor;
    }
    
    if ( (maxPos.x>0.7) &&( ( ((pos-contur).x>wsize*2.0*floor(numWin/4.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin/4.0)) )||
                                          ( ((pos-contur).x>wsize*2.0*floor(numWin*2.0/4.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin*2.0/4.0)) )||
                                          ( ((pos-contur).x>wsize*2.0*floor(numWin*3.0/4.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin*3.0/4.0)) )) ){
     	   return (0.9+0.2*noise(pos))*conturColor;
    }
    if ((maxPos.x-pos.x<contur.x)||(maxPos.y-pos.y<contur.y+2.0*wsize)||(pos.x<contur.x)||(pos.y<contur.y)){
            return (0.9+0.2*noise(pos))*conturColor;
        
    }
    if (maxPos.x<0.14) {
     	   return (0.9+0.2*noise(pos))*wallColor;
    }
    vec2 window = floor((pos-contur)/wsize/2.0);
    float random = rand(squarer*s*maxPos.y+window);
    float randomZ = rand(squarer*s*maxPos.y+floor(vec2((pos-contur).y,(pos-contur).y)/wsize/2.0));
    float windows = floorFactor*sin(randomZ*5342.475379+(fract(975.568*randomZ)*0.15+0.05)*window.x);
    
	float blH = 0.06*dist*600.0/iResolution.x/abs(dot(normalize(rayDir.xy),normalize(norm.xy)));
    float blV = 0.06*dist*600.0/iResolution.x/sqrt(abs(1.0-pow(abs(rayDir.z),2.0)));
    
	windowColor +=vec3(1.0,1.0,1.0);
    windowColor *= smoothstep(0.5-windowSize.x/2.0-blH,0.5-windowSize.x/2.0+blH,winPos.x);
   	windowColor *= smoothstep(0.5+windowSize.x/2.0+blH,0.5+windowSize.x/2.0-blH,winPos.x);
   	windowColor *= smoothstep(0.5-windowSize.y/2.0-blV,0.5-windowSize.y/2.0+blV,winPos.y);
   	windowColor *= smoothstep(0.5+windowSize.y/2.0+blV,0.5+windowSize.y/2.0-blV,winPos.y);
    
    if ((random <0.05*(3.5-2.5*floorFactor))||(windows>0.65)){
        	if (winPos.y<0.5) {windowColor*=(1.0-0.4*fract(random*100.0));}
        	if ((winPos.y>0.5)&&(winPos.x<0.5)) {windowColor*=(1.0-0.4*fract(random*10.0));}
            return (0.9+0.2*noise(pos))*wallColor+(0.9+0.2*noise(pos))*windowColor;


    } 
    else{
        windowColor*=0.08*fract(10.0*random);
    }
    
    return (0.9+0.2*noise(pos))*wallColor+windowColor;

}

vec3 textureRoof(vec2 pos, vec2 maxPos,vec2 squarer){
    float wsize = 0.025;
    float randB = rand(squarer*2.0);
    vec3 wallColor = (0.3+1.4*fract(randB*100.0))*vec3(0.1,0.1,0.1)+(-0.7+1.4*fract(randB*1000.0))*vec3(0.02,0.,0.);
	vec3 conturColor = wallColor*1.5/2.5;
    vec2 contur = vec2(0.02);
    if ((maxPos.x-pos.x<contur.x)||(maxPos.y-pos.y<contur.y)||(pos.x<contur.x)||(pos.y<contur.y)){
            return (0.9+0.2*noise(pos))*conturColor;
        
    }
    float step1 = 0.06+0.12*fract(randB*562526.2865);
    pos -=step1;
    maxPos -=step1*2.0;
    if ((pos.x>0.0&&pos.y>0.0&&pos.x<maxPos.x&&pos.y<maxPos.y)&&((abs(maxPos.x-pos.x)<contur.x)||(abs(maxPos.y-pos.y)<contur.y)||(abs(pos.x)<contur.x)||(abs(pos.y)<contur.y))){
            return (0.9+0.2*noise(pos))*conturColor;
        
    }
    pos -=step1;
    maxPos -=step1*2.0;
    if ((pos.x>0.0&&pos.y>0.0&&pos.x<maxPos.x&&pos.y<maxPos.y)&&((abs(maxPos.x-pos.x)<contur.x)||(abs(maxPos.y-pos.y)<contur.y)||(abs(pos.x)<contur.x)||(abs(pos.y)<contur.y))){
            return (0.9+0.2*noise(pos))*conturColor;
        
    }
    pos -=step1;
    maxPos -=step1*2.0;
    if ((pos.x>0.0&&pos.y>0.0&&pos.x<maxPos.x&&pos.y<maxPos.y)&&((abs(maxPos.x-pos.x)<contur.x)||(abs(maxPos.y-pos.y)<contur.y)||(abs(pos.x)<contur.x)||(abs(pos.y)<contur.y))){
            return (0.9+0.2*noise(pos))*conturColor;
        
    }
    
    return (0.9+0.2*noise(pos))*wallColor;
    
}
vec3 cars(vec2 squarer, vec2 pos, float dist,float level){
    vec3 color = vec3(0.0);
    float carInten = 3.5/sqrt(dist);
    float carRadis = 0.01; 
    if (dist>2.0) {carRadis *= sqrt(dist/2.0);}
    vec3 car1 = vec3(0.5,0.5,1.0);
    vec3 car2 = vec3(1.0,0.1,0.1);
    float carNumber = 0.5;
    
    float random = noise((level+1.0)*squarer*1.24435824);
    for (int j=0;j<10; j++){
        float i = 0.03+float(j)*0.094;
        if(fract(random*5.0/i)>carNumber){color += car1*carInten*smoothstep(carRadis,0.0,length(pos - vec2(fract(i+iGlobalTime/4.0),0.025)));}
        
        if(fract(random*10.0/i)>carNumber){color += car2*carInten*smoothstep(carRadis,0.0,length(pos - vec2(fract(i-iGlobalTime/4.0),0.975)));}
    	if(color.x>0.0) break;
    }
    for (int j=0;j<10; j++){
        float i= 0.03+float(j)*0.094;
        if(fract(random*5.0/i)>carNumber){color += car2*carInten*smoothstep(carRadis,0.0,length(pos - vec2(0.025,fract(i+iGlobalTime/4.0))));}
        if(fract(random*10.0/i)>carNumber){color += car1*carInten*smoothstep(carRadis,0.0,length(pos - vec2(0.975,fract(i-iGlobalTime/4.0))));}
        	if(color.x>0.0) break;

    }
    for (int j=0;j<10; j++){
        float i = 0.03+0.047+float(j)*0.094;
        if(fract(random*100.0/i)>carNumber){color += car1*carInten*smoothstep(carRadis,0.0,length(pos - vec2(fract(i+iGlobalTime/4.0),0.045)));}
        if(fract(random*1000.0/i)>carNumber){color += car2*carInten*smoothstep(carRadis,0.0,length(pos - vec2(fract(i-iGlobalTime/4.0),0.955)));}
        	if(color.x>0.0) break;

    }
    for (int j=0;j<10; j++){
        float i = 0.03+0.047+float(j)*0.094;
        if(fract(random*100.0/i)>carNumber){color += car2*carInten*smoothstep(carRadis,0.0,length(pos - vec2(0.045,fract(i+iGlobalTime/4.0))));}
        if(fract(random*1000.0/i)>carNumber){color += car1*carInten*smoothstep(carRadis,0.0,length(pos - vec2(0.955,fract(i-iGlobalTime/4.0))));}
        	if(color.x>0.0) break;

    }
    return color;
}
vec3 textureGround(vec2 squarer, vec2 pos,vec2 vert1,vec2 vert2,float dist){
    vec3 color = (0.9+0.2*noise(pos))*vec3(0.1,0.15,0.1);
    float randB = rand(squarer*2.0);

    vec3 wallColor = (0.3+1.4*fract(randB*100.0))*vec3(0.1,0.1,0.1)+(-0.7+1.4*fract(randB*1000.0))*vec3(0.02,0.,0.);
	float fund = 0.03;
    float bl = 0.01;
    float f = smoothstep(vert1.x-fund-bl,vert1.x-fund,pos.x);
    f *= smoothstep(vert1.y-fund-bl,vert1.y-fund,pos.y);
    f *= smoothstep(vert2.y+fund+bl,vert2.y+fund,pos.y);
    f *= smoothstep(vert2.x+fund+bl,vert2.x+fund,pos.x);

    pos -= 0.0;
    vec2 maxPos = vec2(1.,1.);
    vec2 contur = vec2(0.06,0.06);
    if ((pos.x>0.0&&pos.y>0.0&&pos.x<maxPos.x&&pos.y<maxPos.y)&&((abs(maxPos.x-pos.x)<contur.x)||(abs(maxPos.y-pos.y)<contur.y)||(abs(pos.x)<contur.x)||(abs(pos.y)<contur.y))){
            color =  vec3(0.1,0.1,0.1)*(0.9+0.2*noise(pos));
        
    }
    pos -= 0.06;
    maxPos = vec2(.88,0.88);
    contur = vec2(0.01,0.01);
    if ((pos.x>0.0&&pos.y>0.0&&pos.x<maxPos.x&&pos.y<maxPos.y)&&((abs(maxPos.x-pos.x)<contur.x)||(abs(maxPos.y-pos.y)<contur.y)||(abs(pos.x)<contur.x)||(abs(pos.y)<contur.y))){
            color =  vec3(0.,0.,0.);
        
    }
    color = mix(color,(0.9+0.2*noise(pos))*wallColor*1.5/2.5,f);

    pos+=0.06;
    
#ifdef CARS
    if (pos.x<0.07||pos.x>0.93||pos.y<0.07||pos.y>0.93){
        color+=cars(squarer,pos,dist,0.0);
    }
#endif
    
    return color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 pos = (fragCoord.xy*2.0 - iResolution.xy) / iResolution.y;
    float t = -iGlobalTime;
    float tt = -iGlobalTime-0.5;
    
    
    vec3 camPos = vec3(5.0+12.0*sin(t*0.05),5.0+ 7.0*cos(t*0.05), 1.9);
    
    vec3 camTarget = vec3(5.0+0.0,5.0+7.0*sin(t*0.05), 0.0);
    if (fract(t/12.0)<0.25){
    	camPos = vec3(5.*t,3.1*t,2.1);
		camTarget = vec3(5.*tt,3.1*tt,1.7);
    }
    if (fract(t/12.0)>0.75){
    	camPos = vec3(35.,3.1,1.);
		camTarget = vec3(35.+sin(t/10.0),3.1+cos(t/10.0),0.7);
    }
    vec3 camDir = normalize(camTarget-camPos);
    vec3 camUp  = normalize(vec3(0.0, 0.0, -1.0));
    vec3 camSide = cross(camDir, camUp);
    camUp  = cross(camDir, camSide);
    vec3 rayDir = normalize(camSide*pos.x + camUp*pos.y + camDir*1.6);
    float angle = 0.03*pow(abs(acos(rayDir.x)),4.0);
    //angle = min(0.0,angle);
    vec3 color = vec3(0.0);
    vec2 square = floor(camPos.xy);
    square.x += 0.5-0.5*sign(rayDir.x);
    square.y += 0.5-0.5*sign(rayDir.y);
    float mind = 100.0;
    int k = 0;
    vec3 pol;
    vec2 maxPos;
    vec2 crossG;
    float tSky = -(camPos.z-3.9)/rayDir.z;
    vec2 crossSky = floor(camPos.xy + rayDir.xy*tSky);
    for (int i=1; i<I_MAX; i++){
                
        vec2 squarer = square-vec2(0.5,0.5)+0.5*sign(rayDir.xy);
        if (crossSky == squarer&&crossSky!=floor(camPos.xy))
        {
        	color += vec3(vec2(0.5,0.15)*abs(angle)*exp(-rayDir.z*rayDir.z*30.0),0.2);
            break;

        }
        float t;
        float random = rand(squarer);
        float height = 0.0;
        float quartalR = rand(floor(squarer/10.0));
        if (floor(squarer/10.0) == vec2(0.0,0.0)) quartalR = 0.399;
        if (quartalR<0.4) {
            height = -0.15+0.4*random+smoothstep(12.0,7.0,length(fract(squarer/10.0)*10.0-vec2(5.0,5.0)))*0.8*random+0.9*smoothstep(10.0,0.0,length(fract(squarer/10.0)*10.0-vec2(5.0,5.0)));
        	height*=quartalR/0.4;
        }
        float maxJ=2.0;
        float roof = 1.0;
        if (height<0.3){
            height = 0.3*(0.7+1.8*fract(random*100.543264));maxJ = 2.0;
            if (fract(height*1000.0)<0.04) height*=1.3;
        }
        if (height>0.5) {maxJ=3.0;}
        if (height>0.85){maxJ = 4.0;}
        if (fract(height*100.0)<0.15){height = pow(maxJ-1.0,0.3)*height; maxJ = 2.0; roof = 0.0;}

        
        float maxheight = 1.5*pow((maxJ-1.0),0.3)*height+roof*0.07;
        if (camPos.z+rayDir.z*(length(camPos.xy - square) +0.71 - sign(rayDir.z)*0.71)/length(rayDir.xy)<maxheight){
			vec2 vert1r;
        	vec2 vert2r;
            float zz = 0.0;
            float prevZZ = 0.0;
            for(int nf=1;nf<8;nf++){
                float j = float(nf);
   	        	if(j>maxJ){break;}
                prevZZ = zz;
   	    	    zz = 1.5*pow(j,0.3)*height;
                //prevZZ = zz-0.8;

   		     	float dia = 1.0/pow(j,0.3);
            	if(j==maxJ){
                    if (roof == 0.0) {break;}
      		      	zz = 1.5*pow((j-1.0),0.3)*height+0.03+0.04*fract(random*1535.347);
     	           	dia = 1.0/pow((j-1.0),0.3)-0.2-0.2*fract(random*10000.0);
       		    }
            
            	vec2 v1 = vec2(0.0);//vec2(random*10.0,random*1.0);
            	vec2 v2 = vec2(0.0);//vec2(random*1000.0,random*100.0);
                float randomF = fract(random*10.0);
                if (randomF<0.25){ v1 = vec2(fract(random*1000.0),fract(random*100.0));}
                if (randomF>0.25&&randomF<0.5){ v1 = vec2(fract(random*100.0),0.0);v2 = vec2(0.0,fract(random*1000.0));}
                if (randomF>0.5&&randomF<0.75){ v2 = vec2(fract(random*1000.0),fract(random*100.0));}
                if (randomF>0.75){ v1 = vec2(0.0,fract(random*1000.0)); v2 = vec2(fract(random*100.0),0.0);}
            	if (rayDir.y<0.0){
            	    float y = v1.y;
            	    v1.y = v2.y;
            	    v2.y = y;
            	}
            	if (rayDir.x<0.0){
            	    float x = v1.x;
            	    v1.x = v2.x;
            	    v2.x = x;
            	}
            
        		vec2 vert1 = square+sign(rayDir.xy)*(0.5-0.37*(dia*1.0-1.0*v1));
        		vec2 vert2 = square+sign(rayDir.xy)*(0.5+0.37*(dia*1.0-1.0*v2));
                if (j==1.0){ 
                    vert1r = vec2(min(vert1.x, vert2.x),min(vert1.y,vert2.y));
                    vert2r = vec2(max(vert1.x, vert2.x),max(vert1.y,vert2.y));
                }
            
        		vec3 pxy = polygonXY(zz,vert1,vert2,camPos,rayDir);
            	if (pxy.x<mind){mind = pxy.x; pol = pxy; k=1;maxPos = vec2(abs(vert1.x-vert2.x),abs(vert1.y-vert2.y));}
            
        		vec3 pyz = polygonYZ(vert1.x,vec2(vert1.y,prevZZ),vec2(vert2.y,zz),camPos,rayDir);
            	if (pyz.x<mind){mind = pyz.x; pol = pyz; k=2;maxPos = vec2(abs(vert1.y-vert2.y),zz-prevZZ);}

        		vec3 pxz = polygonXZ(vert1.y,vec2(vert1.x,prevZZ),vec2(vert2.x,zz),camPos,rayDir);
            	if (pxz.x<mind){mind = pxz.x; pol = pxz; k=3;maxPos = vec2(abs(vert1.x-vert2.x),zz-prevZZ);}
               	

        	}
            
        	if ((mind<100.0)&&(k==1)){
            	color += textureRoof(vec2(pol.y,pol.z),maxPos,squarer);
                if (mind>3.0){color*=sqrt(3.0/mind);}

            	break;
        	} 
        	if ((mind<100.0)&&(k==2)){
            	color += textureWall(vec2(pol.y,pol.z),maxPos,squarer,1.2075624928,height,mind,rayDir,vec3(1.0,0.0,0.0));
            	if (mind>3.0){color*=sqrt(3.0/mind);}
            	break;
        	} 
        
        	if ((mind<100.0)&&(k==3)){
            	color += textureWall(vec2(pol.y,pol.z),maxPos,squarer,0.8093856205,height,mind,rayDir,vec3(0.0,1.0,0.0));
            	if (mind>3.0){color*=sqrt(3.0/mind);}

            	break;
        	}
        	t = -camPos.z/rayDir.z;
    		crossG = camPos.xy + rayDir.xy*t;
        	if (floor(crossG) == squarer)
        	{
            	mind = length(vec3(crossG,0.0)-camPos);
            	color += textureGround(squarer,fract(crossG),fract(vert1r),fract(vert2r),mind);
            	if (mind>3.0){color*=sqrt(3.0/mind);}

            	break;
        	}
        
        } 
        
            
        if ((square.x+sign(rayDir.x)-camPos.x)/rayDir.x<(square.y+sign(rayDir.y)-camPos.y)/rayDir.y) {
            square.x += sign(rayDir.x)*1.0;
        } else {
            square.y += sign(rayDir.y)*1.0;
        }
        
        if(i==I_MAX-1&&rayDir.z>-0.1) {color += vec3(vec2(0.5,0.15)*abs(angle)*exp(-rayDir.z*rayDir.z*30.0),0.2);}

    }
    fragColor = vec4( color, 1.0);;
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
