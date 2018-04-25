#pragma name MMJ_ColorPass

/*
----------------------------------------------------------------
MMJ's Cel Shader v2.01 - Multi-Pass 
----------------------------------------------------------------
Parameters:
-----------
Color Saturation = Increase or decrease color saturation. 

Color Levels = Determines number of color "bands".

Color Weight = Changes the strength of the color adjustments.
----------------------------------------------------------------
*/

#pragma parameter ColorLevels "Color Levels" 12.0 1.0 32.0 1.0
#pragma parameter ColorSaturation "Color Saturation" 1.15 0.00 2.00 0.05
#pragma parameter ColorWeight "Color Weight" 0.50 0.00 1.00 0.05


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
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	gl_Position = MVPMatrix * VertexCoord;
	TEX0 = TexCoord;
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

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform sampler2D OrigTexture;
uniform sampler2D PassPrev1Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float ColorLevels;
uniform COMPAT_PRECISION float ColorSaturation;
uniform COMPAT_PRECISION float ColorWeight;
#else
#define ColorLevels 12.0
#define ColorSaturation 1.15
#define ColorWeight 0.50
#endif


vec3 RGB2HSL(vec3 cRGB) 
{
  float cR = cRGB[0], cG = cRGB[1], cB = cRGB[2];
  float vMin = min(min(cR, cG), cB), vMax = max(max(cR, cG), cB);
  float dMax = vMax - vMin, vS = 0.0, vH = 0.0, vL = (vMax + vMin) / 2.0;

  // gray, no chroma
  if(dMax == 0.0) { 
    vH = 0.0; vS = vH; 

  // chromatic data
  } else {
    if(vL < 0.5) { vS = dMax / (vMax + vMin); }
    else         { vS = dMax / (2.0 - vMax - vMin); }

    float dR = (((vMax - cR) * 0.1667) + (dMax * 0.5)) / dMax;
    float dG = (((vMax - cG) * 0.1667) + (dMax * 0.5)) / dMax;
    float dB = (((vMax - cB) * 0.1667) + (dMax * 0.5)) / dMax;

    if     (cR >= vMax) { vH = dB - dG; }
    else if(cG >= vMax) { vH = 0.3333 + dR - dB; }
    else if(cB >= vMax) { vH = 0.6667 + dG - dR; }

    if     (vH < 0.0) { vH += 1.0; }
    else if(vH > 1.0) { vH -= 1.0; }
  }
  return vec3(vH, vS, vL);
}

float Hue2RGB(float v1, float v2, float vH) 
{
  float v3 = 0.0;

  if     (vH < 0.0) { vH += 1.0; }
  else if(vH > 1.0) { vH -= 1.0; }

  if     ((6.0 * vH) < 1.0) { v3 = v1 + (v2 - v1) * 6.0 * vH; }
  else if((2.0 * vH) < 1.0) { v3 = v2; }
  else if((3.0 * vH) < 2.0) { v3 = v1 + (v2 - v1) * (0.6667 - vH) * 6.0; }
  else                      { v3 = v1; }

  return v3;
}

vec3 HSL2RGB(vec3 vHSL) 
{
    float cR = 0.0, cG = cR, cB = cR;

  if(vHSL[1] == 0.0) { 
    cR = vHSL[2], cG = cR, cB = cR; 
    
  } else {
    float v1 = 0.0, v2 = v1;

    if(vHSL[2] < 0.5) { v2 = vHSL[2] * (1.0 + vHSL[1] ); }
    else              { v2 = (vHSL[2] + vHSL[1] ) - (vHSL[1] * vHSL[2] ); }

    v1 = 2.0 * vHSL[2] - v2;

    cR = Hue2RGB(v1, v2, vHSL[0] + 0.3333);
    cG = Hue2RGB(v1, v2, vHSL[0] );
    cB = Hue2RGB(v1, v2, vHSL[0] - 0.3333);
  }
  return vec3(cR, cG, cB);
}

vec3 colorAdjust(vec3 cRGB) 
{
  vec3 cHSL = RGB2HSL(cRGB);

  float cr = 1.0 / ColorLevels;

  // brightness modifier
  float BrtModify = mod(cHSL[2], cr); 

  cHSL[1] *= ColorSaturation; 
  cHSL[2] += (cHSL[2] * cr - BrtModify);
  cRGB = 1.2 * HSL2RGB(cHSL);

  return cRGB;
}

void main()
{
  vec3 cOriginal = COMPAT_TEXTURE(OrigTexture, vTexCoord).rgb;
  vec3 cOutline = COMPAT_TEXTURE(PassPrev1Texture, vTexCoord).rgb;
	
	vec3 cNew = cOriginal;
	cNew = min(vec3(1.0), min(cNew, cNew + dot(vec3(1.0), cNew)));
	FragColor.rgb = mix(cOriginal * cOutline, colorAdjust(cNew * cOutline), ColorWeight);
}
#endif