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

// Doom 2. Reinder Nijhoff 2013
// @reindernijhoff
//
// https://www.shadertoy.com/view/lsB3zD
//

#define COL(r,g,b) vec3(r/255.,g/255.,b/255.)

#define time iGlobalTime

//----------------------------------------------------------------------
// Math functions

float hash( const float n ) {
    return fract(sin(n*14.1234512)*51231.545341231);
}
float hash( const vec2 x ) {
	float n = dot( x, vec2(14.1432,1131.15532) );
    return fract(sin(n)*51231.545341231);
}
float crossp( const vec2 a, const vec2 b ) { return a.x*b.y - a.y*b.x; }
vec3 rotate(vec3 r, float v){ return vec3(r.x*cos(v)+r.z*sin(v),r.y,r.z*cos(v)-r.x*sin(v));}

//----------------------------------------------------------------------
// Intersection functions

bool intersectWall(const vec3 ro, const vec3 rd, const vec2 a, const vec2 b, const float height, 
					  inout float dist, inout vec2 uv ) {
	vec2 p = ro.xz;	vec2 r = rd.xz;
	vec2 q = a-p;	vec2 s = b-a;
	float rCrossS = crossp(r, s);
	
	if( rCrossS == 0.) {
		return false;
	}
	float d = crossp(q, s) / rCrossS;
	float u = crossp(q, r) / rCrossS;
	float he = ro.y+rd.y*d;
	
	if(0. <= d && d < dist && 0. <= u && u <= 1. && he*sign(height) < height ) {
		dist = d;
		uv = vec2( -u*length(s), height-he );
		return true;
	}
	return false;
}
bool intersectFloor(const vec3 ro, const vec3 rd, const float height, 
					inout float dist, inout vec2 uv ) {	
	if (rd.y==0.0) {
		return false;
	}
		
	float d = -(ro.y - height)/rd.y;
	d = min(100000.0, d);
	if( d > 0. && d < dist) {
		dist = d;
		uv = ro.xz+dist*rd.xz;
		return true;
	}
	return false;
}

//----------------------------------------------------------------------
// Material helper functions

float sat( const float a ) { return clamp(a,0.,1.); }
float onCircleAA( const vec2 c, const vec2 centre, const float radius, const float aa ) {
	return sat( aa*(radius - distance(c,centre)) );
}
float onLineX( const vec2 c, const float x ) {
	return step(x,c.x)*step(c.x,x);
}
float onLineY( const vec2 c, const float y ) {
	return step(y,c.y)*step(c.y,y);
}
float onBand( const float c, const float mi, const float ma ) {
	return step(mi,c)*step(c,ma);
}
float onRect( const vec2 c, const vec2 lt, const vec2 rb ) {
	return onBand( c.x, lt.x, rb.x )*onBand( c.y, lt.y, rb.y );
}
vec3 addKnobAA( const vec2 c, const vec2 centre, const float radius, const float strength, const vec3 col ) {
	vec2 lv = normalize( centre-c );
	return mix( col, col*(1.0+strength*dot(lv,vec2(-0.7071,0.7071))), onCircleAA(c, centre, radius, 4. ) );
}
float onBandAA( const float c, const float mi, const float ma ) {
	return sat( (ma-c+1.) )*sat( (c-mi+1.) );
}
float onRectAA( const vec2 c, const vec2 lt, const vec2 rb ) {
	return onBandAA( c.x, lt.x, rb.x )*onBandAA( c.y, lt.y, rb.y );
}
vec3 addBevel( const vec2 c, const vec2 lt, const vec2 rb, const float size, const float strength, const float lil, const float lit, const vec3 col ) {
	float xl = sat( (c.x-lt.x)/size); 
	float xr = sat( (rb.x-c.x)/size);	
	float yt = sat( (c.y-lt.y)/size); 
	float yb = sat( (rb.y-c.y)/size);
	return mix( col, col*clamp(1.0+strength*(lil*(xl-xr)+lit*(yb-yt)), 0., 2.), onRectAA( c, lt, rb ) );
}

//----------------------------------------------------------------------
// Generate materials!

void getMaterialColor( const int material, in vec2 uv, out vec3 col ) {	
	uv = floor( uv );
	float huv = hash(uv), huvx = hash(uv.x);
	
	if( material == 0 ) { // ceiling GRNLITE1
		uv = mod(uv, vec2(64.)); vec2 centre = mod(uv,vec2(32.,16.));
		col = mix( COL(90.,98.,69.),COL(152.,149.,125.),(0.75*huv+0.25*mod(uv.x,2.)) );
		col = mix( col, mix(vec3(243./255.),vec3(169./255.), distance(centre,vec2(16.,8.))/6.5), onCircleAA(centre, vec2(16.,8.), 6.25, 0.75) );
	} 
	else if( material == 1 ) { // ceiling FLOOR_1
		uv = mod(uv, vec2(64.)); vec2 uv8 = mod(uv, vec2(32.,7.7));
		float h = huv*huvx;
		col = mix( COL(136.,114.,95.), COL(143.,122.,92.), sat(4.*h) );	
		col = mix( col, COL(175.,126.,89.), sat( 2.*(hash(floor(uv*0.125))+huv-1.35) ) );
		col = mix( col, COL(121.,103.,83.), sat( onLineX(uv,0.)+onLineY(uv,63.)) );
		col = mix( col, COL(121.,103.,83.), onLineX(uv,31.)*huv );
		uv8.x = abs(16.-uv8.x);
		float d = min( max( uv8.x-8.,abs(uv8.y-4.) ), abs(distance(uv8,vec2(11.,4.))) )+huv;
		vec3 fgcol = mix( col, col*sat(((16.-uv8.y)/12.)), step(d,3.) );
		col = mix( mix( fgcol, COL(114.,94.,78.), sat(d*(3.5-d)/4.)*step(2.,d) ), col, onRect(uv, vec2(32.,23),vec2(63.,39.) ) );
	}
	else if( material == 2 ) { // wall TEKGREN2 & TEKGREN5
		uv = mod(uv, vec2(128.,128)); vec2 uv64 = mod(uv, vec2(64.,65.) ); vec2 uv24 = mod(uv64, vec2(64.,24.) );
		float h = huv*huvx;
		col = mix( vec3(114./255.), vec3(98./255.), sat(2.*h) );
		col = mix( col, mix( COL(111.,114.,87.), COL(90.,98.,69.), sat(2.*h) ), sat( 100.*(hash(uv+vec2(523.,53.))*hash(150.-uv.x)-0.15)) );	
		col = addKnobAA( mod( uv24, vec2(3.,32.) ), vec2(0.,4.5), 1.1, 0.4, col );
		col = mix( col, COL(137.,141.,115.), 0.7*sat( onLineX(uv64,1.)+onLineY(uv,1.)+onLineY(uv24,0.)+onLineY(uv24,19.)+onLineY(uv64,59.) ) ); 
		col = mix( col, COL(73.,81.,55.), sat( onLineX(uv64,0.)+onLineX(uv64,62.) ) ); 
		col = mix( col, mix(COL(73.,81.,55.),vec3(38./255.),uv24.y-22.), onBand(uv24.y,22.,23.) ); 
		col = mix( col, mix(COL(73.,81.,55.),vec3(38./255.),uv64.y-63.), onBand(uv64.y,63.,64.) ); 
		col = mix( col, vec3(38./255.), sat( onLineY(uv,0.)+onLineX(uv64,63.) ) ); 
		col = mix( col, COL(137.,141.,115.), onRect(uv,vec2(3.),vec2(60.,12.)) ); 
		col = mix( col, mix( vec3(1.), COL(255.,253.,110.), sat( abs(uv.x-32.)/20.)-0.25*mod(uv.x,2.)), onRect(uv,vec2(4.),vec2(59.,11.)) ); 
	}	
	else if( material == 3 ) { // wall BRONZE2
		uv = mod(uv, vec2(64.,128)); float s = sin(31.15926*uv.x/64.);
		col = mix( vec3(75./255.), vec3(64./255.), huv );
		col = mix( col, COL(106.,86.,51.),  sat( 5.*(huv+(s+1.2)*(1.-(uv.y+44.)/64.))) * onBand(uv.y, 0., 30. ) );
		col = mix( col, COL(123.,105.,85.), sat( 2.*(0.5*huvx+huv+(s+1.7)*(1.-(uv.y+44.)/64.)-0.5) ) * onBand(uv.y, 0., 30. ) );
		col = mix( col, COL(106.,86.,51.),  sat( 5.*(huv+(s+0.7)*(1.-(uv.y+14.)/64.))) * onBand(uv.y, 30., 98. ) );
		col = mix( col, COL(123.,105.,85.), sat( 2.*(1.1*huvx+(s+1.7)*(1.-(uv.y+14.)/64.)-0.5) ) * onBand(uv.y, 30., 98. ) );
		col = mix( col, COL(7.,59.,20.), sat( huv*uv.y/96.-0.5) );
		col = mix( col, COL(106.,86.,51.),  sat( 5.*(huv+(s+1.2)*(1.-(uv.y-40.)/64.))) * onBand(uv.y, 98., 128. ) );
		col = mix( col, COL(123.,105.,85.), sat( 2.*(huvx+(s+1.7)*(1.-(uv.y-40.)/64.)-0.5) ) * onBand(uv.y, 98., 128. ) );	
		col = mix( col, mix(COL(110.,89.,70.),COL(130.,112.,92.),sat((uv.y-3.)/18.)), onRectAA(mod(uv,vec2(16.,128.)),vec2(6.5,1.5),vec2(12.5,21.5)) );
		col = addBevel( mod(uv,vec2(16.,128.)),vec2(5.5,-2.5),vec2(12.5,21.5), 2.3, 1., 0.1, 0.7, col );
		col = mix( col, addBevel( abs(mod(uv+vec2(0.,-85.),vec2(64.))-vec2(32.,0.)), vec2(15.5,0.5), vec2(34.5,52.5), 1.2, 1., 0.5, -0.7, col ), onBand(uv.y, 30.,97.));
		col = mix( col, 0.7*col, sat( onLineY(uv,127.)+onLineX(uv,0.)+onBand(uv.y, 97.,98.)+onBand(uv.y, 29.,30.)) );
		col = mix( col, 1.2*col, sat( onBand(uv.y, 98.,99.)+onBand(uv.y, 0.,1.)+onLineX(uv, 63.)) );
		col = mix( col, 0.75*col*uv.x, onBand(uv.x, 0., 1.)*onBand(uv.y, 30.,97.) );
		col *= 1.0-0.1*huv;
	}	
	else if( material == 4 ) { // wall STEP2
		uv = mod(uv, vec2(64.,16.));
		col = mix( COL(182.,133.,93.), COL(132.,98.,66.), sat(huv-0.5) );
		col = mix( col, COL(129.,111.,79.), sat(1.-(uv.y-4.)/8.) );
		col = mix( col, COL(102.,82.,50.), sat((huv+1.)*onRectAA(mod(uv,vec2(32.,16.)), vec2(1.5,9.7), vec2(29.5,13.5))) );
		col = mix( col, COL(102.,82.,50.), 0.6*sat((huv+1.)*onRectAA(mod(uv,vec2(8.,16.)), vec2(2.5,3.5), vec2(5.5,6.2))) );
		col = mix( col, COL(143.,122.,92.), onLineY(uv,0.) );
		col = mix( col, COL(106.,86.,61.), onLineY(uv,2.) );
		col *= 1.-0.2*onLineY(uv,3.);
	}
	else if( material == 5 ) { // wall PIPE4
		uv = mod(uv, vec2(128.,64.)); float huv2 = hash( uv*5312. );
		col = mix( mix(COL(184.,165.,144.),COL(136.,102.,67.),uv.x/128.), 
				   mix(COL(142.,122.,104.),COL(93.,77.,50.),uv.x/128.), sat(huv+huvx) );
		col *= 1.+0.5*sat(hash(uv.y)-0.7);
		col *= 1.-0.2*sat(hash(uv.y-1.)-0.7);
		col = mix( col, COL(102.,82.,50.), sat(0.2*huv2+3.*(huvx-0.7)) );
		col = mix( col, COL(165.,122.,85.), (0.75+0.5*huv2)*sat( onBandAA(uv.x,122.5,123.5)+onBandAA(uv.x,117.5,118.5)+onBandAA(uv.x,108.5,109.5) ) );
		col = mix( col, mix(  (1.-sat(0.2*abs(2.8-mod(uv.x,6.))))*mix(COL(175.,126.,89.),COL(143.,107.,71.),0.4*distance( mod(uv,vec2(6.)), vec2 (1.5))), COL(77.,68.,40.), onBandAA(mod(uv.x+1.,6.),0.,1.5)),
								   (0.75+0.5*huv2)*sat( onBandAA(uv.x,6.5,11.5)+onBandAA(uv.x,54.5,59.5)+onBandAA(uv.x,66.5,70.5)+onBandAA(uv.x,72.5,78.5) ) );
		col = mix( col, mix( COL(82.,90.,64.), 1.2*COL(118.,125.,99.), huv*(sat(abs(uv.x-14.)-huv)+sat(abs(uv.x-62.)-huv)) ), onBandAA(uv.x,12.8,13.8) + onBandAA(uv.x,60.8,61.8));
		col = mix( col, vec3(0.), 0.3*(onBandAA(uv.y,18.8,21.8)*onBandAA(uv.x,40.8,52.8) + onBandAA(uv.x,0.1,3.7) + onBandAA(uv.x,41.3,44.2) + onBandAA(uv.x,48.9,51.8)+0.6*onBandAA(uv.x,80.1,81.6)));
		col = mix( col, mix( 1.2*COL(205.,186.,167.), COL(143.,122.,92.), 0.3*(sat(abs(uv.x-2.)+huv)+sat(abs(uv.x-43.)+huv)+sat(abs(uv.x-51.)+huv)) ), onBandAA(uv.x,0.8,2.8) + onBandAA(uv.x,42.1,43.3) + onBandAA(uv.x,49.8,51.2)+0.6*onBandAA(uv.x,80.8,81.5));
		col = mix( col, mix( 1.2*COL(205.,186.,167.), COL(154.,133.,105.), (sat(abs(uv.y-20.5)+huv)) ), onBandAA(uv.y,19.3,21.2)*onBandAA(uv.x,40.8,52.1));
		float d = min( min( min( min( min( min( distance(uv,vec2(6.,39.)), 0.8*distance(uv,vec2(23.,45.)) ), 1.2*distance(uv,vec2(39.,30.)) )
					  , 1.5*distance(uv,vec2(48.,42.)) ), distance(uv,vec2(90.,32.)) ), 0.8*distance(uv,vec2(98.,50.)) ), 1.15*distance(uv,vec2(120.,44.)) );;
		d *= (1.-0.8*(sat(hash(uv.x+uv.y)-0.6)+sat(huvx-0.6)));
		col = mix( col,COL(93.,77.,50.), sat((7.-d)/8.) );
		col = mix( col, vec3(0.), pow(sat((5.-d)/6.),1.5) );
	}
	else if( material == 6 ) { // floor FLOOR_3_3
		uv = mod(uv, vec2(64.));
		col = mix( COL(147.,126.,108.), COL(175.,152.,134.), sat( 1.5*(huv+hash(uv.x-uv.y)-0.95-uv.y/128.)) );
		col = mix( col, COL(175.,152.,134.), sat( 1.5*(huv+hash(uv.x-uv.y*1.1+5.)-1.8+uv.y/64.)) );
		col = mix( col, COL(130.,133.,108.), sat( 10.*(huv+hash(uv.x*1.1-uv.y+3.)-1.25)) );
		col = mix( col, mix( COL(118.,125.,99.), COL(130.,133.,108.), 1.-huv), sat(5.*(huv-1.5+uv.y/64.)) );
		col = mix( col, COL(129.,111.,91.), sat( onLineX(uv,0.)+onLineY(uv,63.) ) );
		col *= sat(0.92+huv);		
	} 
	else if( material == 7 ) { // floor FLOOR_0_1
		uv = mod(uv, vec2(64.)); 
		float h = hash(3.*uv.x+uv.y);
		col = mix( COL(136.,114.,95.), COL(143.,122.,104.), sat(4.*h*huv) );
		col = mix( col, COL(129.,111.,91.), sat(h-0.5) );	
		col *= 1.+0.05*sat( 0.3+mod(uv.x,2.)*cos(uv.y*0.2)*huv );
		col = mix( col, COL(175.,126.,89.), sat( 2.*(hash(floor(uv*0.125))+huv-1.5) ) );
		vec3 ncol = mix( col, COL(114.,94.,78.), sat( 
			(0.4*huv+0.4)*onRectAA( mod(uv+vec2(0.,33.),vec2(64.)), vec2(6.5,0.5), vec2(36.5,58.5) )
						 -onRectAA( mod(uv+vec2(0.,33.),vec2(64.)), vec2(9.5,3.5), vec2(33.5,55.5) ) ));
		ncol = mix( ncol, COL(114.,94.,78.), sat( (0.6*huv+0.3)*onRectAA( mod(uv+vec2(0.,5.),vec2(64.)), vec2(33.5,0.5), vec2(59.5,60.5) ) ));
		ncol = mix( ncol, col, sat(               0.8*onRectAA( mod(uv+vec2(0.,5.),vec2(64.)), vec2(35.5,2.5), vec2(57.5,58.5) ) ));
		ncol = mix( ncol, COL(121.,103.,81.), sat( (0.8*huv+0.9)*onRectAA( mod(uv+vec2(0.,53.),vec2(64.)), vec2(18.5,0.5), vec2(41.5,22.5) ) ));
		ncol = mix( ncol, col, sat(               onRectAA( mod(uv+vec2(0.,53.),vec2(64.)), vec2(19.5,1.5), vec2(40.5,21.5) ) ));
		ncol = mix( ncol, COL(114.,94.,78. ), sat( (0.8*huv+0.6)*onRectAA( mod(uv+vec2(8.,46.),vec2(64.)), vec2(0.5,0.5), vec2(20.5,36.5) ) ));
		col  = mix( ncol, col, sat(               onRectAA( mod(uv+vec2(8.,46.),vec2(64.)), vec2(1.5,1.5), vec2(19.5,35.5) ) ));
	} else  {
		col = vec3(0.5);
	}
}

//----------------------------------------------------------------------
// Render MAP functions

struct lineDef { vec2 a, b; float h; float l; int m; };

vec3 castRay( const vec3 ro, const vec3 rd ) {
	lineDef ldfs[14];
	ldfs[0]  = lineDef(vec2(192.,-448.), vec2(320.,-320.), 264., 128., 5 );
	ldfs[1]  = lineDef(vec2(320.,-320.), vec2(256.,0.),    264., 128., 5 );
	ldfs[2]  = lineDef(vec2(256.,0.),    vec2(64.,0.),     264., 128., 5 );
	ldfs[4]  = lineDef(vec2(64.,0.),     vec2(0.,0.),       56., 208., 4 );
	ldfs[3]  = lineDef(vec2(0.,448.),    vec2(320.,448.),  128., 224., 2 );
	ldfs[5]  = lineDef(vec2(64.,0.),     vec2(-64.,0.),   -128., 208., 5 );
	ldfs[6]  = lineDef(vec2(192.,-320.), vec2(128.,-320.), 264., 128., 3 );
	ldfs[7]  = lineDef(vec2(128.,-320.), vec2(128.,-256.), 264., 128., 3 );
	ldfs[8]  = lineDef(vec2(192.,0.),    vec2(0.,-320.),    16., 144., 4 );
	ldfs[9]  = lineDef(vec2(160.,0.),    vec2(0.,-256.),    24., 160., 4 );
	ldfs[10] = lineDef(vec2(128.,0.),    vec2(0.,-192.),    32., 176., 4 );
	ldfs[11] = lineDef(vec2(96.,0.),     vec2(0.,-128.),    40., 192., 4 );
	ldfs[12] = lineDef(vec2(64.,0.),     vec2(0.,-64.),     48., 208., 4 );
	ldfs[13] = lineDef(vec2(64.,0.),     vec2(64.,320.),   128., 224., 2 );
	
	float dist = 999999., curdist; vec2 uv, curuv;
	vec3 col = vec3( 0. ); float lightning = 128.; int mat = 0;

	// check walls
	for( int i=0; i<14; i++ ) {
		vec2 a = ldfs[i].a, b = ldfs[i].b; float h=ldfs[i].h; 		
		if( intersectWall(ro, rd, a, b, h, dist, uv) || 
			intersectWall(ro, rd, b*vec2(-1.,1.), a*vec2(-1.,1.), h, dist, uv) ) {
			mat = ldfs[i].m;
			lightning = ldfs[i].l * (1.-0.2*abs( normalize( (a-b).yx ).y ));
		}
	}
	if( mat == 5 ) { // fix large texture on wall above portal
		vec3 intersection = ro + rd*dist;
		if( intersection.z > -0.1 ) {
			uv = -intersection.xy+vec2(64.,0.);
			lightning = 0.8*max(128., min(208., 248.-20.*floor(abs(intersection.x)/32.)));
		}
		uv *= 0.5;
	}
	
	// check floor and ceiling
	if( intersectFloor(ro, rd, 264., dist, uv ) ) {
		mat = 1;
		lightning =128.;
		float c1=320., c2=196.;
		for( int i=4; i>=0; i-- ) {
			if( abs(uv.x)*(c1/c2)-uv.y < c1 ) {
				lightning = float(208-i*16);
			}
			c1-=64.; c2-=32.;
		}
	}
	if( intersectFloor(ro, rd, 8., dist, uv ) ) {
		mat = 7;
		lightning =128.;
	}		
	float c1=64., c2=64., c3=48.;
	for( int i=0; i<5; i++ ) {
		curdist = dist;
		if( intersectFloor(ro, rd, c3, curdist, curuv ) && abs(curuv.x)*(c1/c2)-curuv.y < c1 ) {
			uv = curuv;
			mat = 7;
			dist = curdist;
			lightning = float(208-i*16);
		}
		c3-=8.; c1+=64.; c2+=32.;
	}
	// and hall	
	curdist = dist;
	if( (intersectFloor(ro, rd, 56., curdist, curuv ) || intersectFloor(ro, rd, 128., curdist, curuv ) ) && curuv.y > 0. ) {
		dist = curdist;
		uv = curuv;
		mat = rd.y>0.?0:6;
		lightning = 224.;
	}
	
	getMaterialColor( mat, uv, col );
		
	col *= 0.3*pow(2.*lightning/255., 2.5)*sat( 1.-curdist/2000. );	
	// fake 8-bit pallete
	col = floor((col)*64.+vec3(0.5))/64.;
	return col;
}

//----------------------------------------------------------------------
// Camera path

float getPathHeight( const float z, const float t ) {
	return max( 0.+step(0.,z)*56.+step(z,-448.)*56.+
		mix(56.,8.,(448.+z)/32.)*step(-448.,z)*step(z,-416.)+
		mix(8.,56.,(320.+z)/320.)*step(z,0.)*step(-320.,z), 8.) + 56.;
}
vec2 path( const float t ) {
	return vec2(32.*sin(t*0.21), -200.-249.*cos( max(0.,mod(t,30.)-10.)*(3.1415936/10.) ) );
}


//----------------------------------------------------------------------
// Main

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x/ iResolution.y;

	vec3 ro; ro.xz = path(time); 
	vec3 ta; ta.xz = path(time+0.1) + vec2(0.,20.);
	ta.y = ro.y = getPathHeight(ro.z, time);
	
    vec3 rdcenter =  rotate( normalize(ta - ro), 0.5*cos(time*0.5) );
    vec3 uu = normalize(cross( vec3(0.,1.,0.), rdcenter ));
    vec3 vv = normalize(cross(rdcenter,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + 1.25*rdcenter );
	
	vec3 col = castRay( ro, rd );
		
	fragColor = vec4( col, 1.0 );
}

 void main(void)
{
  //just some shit to wrap shadertoy's stuff
  vec2 FragCoord = vTexCoord.xy*OutputSize.xy;
  mainImage(FragColor,FragCoord);
}
#endif
