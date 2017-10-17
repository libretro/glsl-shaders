#version 130

//////////////////////////////////////////////////////////////////////////
//
// CC0 1.0 Universal (CC0 1.0)
// Public Domain Dedication 
//
// To the extent possible under law, J. Kyle Pittman has waived all
// copyright and related or neighboring rights to this implementation
// of CRT simulation. This work is published from the United States.
//
// For more information, please visit
// https://creativecommons.org/publicdomain/zero/1.0/
//
//////////////////////////////////////////////////////////////////////////

// This is the second step of the CRT simulation process,
// after the ntsc.fx shader has transformed the RGB values with a lookup table.
// This is where we apply effects "inside the screen," including spatial and temporal bleeding,
// an unsharp mask to simulate overshoot/undershoot, NTSC artifacts, and so on.

// Parameter lines go here:
#pragma parameter Tuning_Sharp "Composite Sharp" 0.2 0.0 1.0 0.05
// typically [0,1], defines the weighting of the sharpness taps
#pragma parameter Tuning_Persistence_R "Red Persistence" 0.075 0.0 1.0 0.01
// typically [0,1] per channel, defines the total blending of previous frame values
#pragma parameter Tuning_Persistence_G "Green Persistence" 0.05 0.0 1.0 0.01
#pragma parameter Tuning_Persistence_B "Blue Persistence" 0.05 0.0 1.0 0.01
#pragma parameter Tuning_Bleed "Composite Bleed" 0.5 0.0 1.0 0.05
// typically [0,1], defines the blending of L/R values with center value from prevous frame
#pragma parameter Tuning_Artifacts "Composite Artifacts" 0.5 0.0 1.0 0.05
// typically [0,1], defines the weighting of NTSC scanline artifacts (not physically accurate by any means)
#pragma parameter NTSCLerp "NTSC Artifacts" 1.0 0.0 1.0 1.0
// Defines an interpolation between the two NTSC filter states. Typically would be 0 or 1 for vsynced 60 fps gameplay or 0.5 for unsynced, but can be whatever.
#pragma parameter NTSCArtifactScale "NTSC Artifact Scale" 255.0 0.0 1000.0 5.0
#pragma parameter animate_artifacts "Animate NTSC Artifacts" 1.0 0.0 1.0 1.0

#define lerp(a, b, c) mix(a, b, c)
#define tex2D(a, b) COMPAT_TEXTURE(a, b)
#define half4 vec4
#define half2 vec2
#define half float
#define saturate(c) clamp(c, 0.0, 1.0)

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

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D NTSCArtifactSampler;
uniform sampler2D PrevTexture;
uniform sampler2D Prev1Texture;
uniform sampler2D Prev2Texture;
uniform sampler2D Prev3Texture;
uniform sampler2D Prev4Texture;
uniform sampler2D Prev5Texture;
uniform sampler2D Prev6Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float Tuning_Sharp;
uniform COMPAT_PRECISION float Tuning_Persistence_R;
uniform COMPAT_PRECISION float Tuning_Persistence_G;
uniform COMPAT_PRECISION float Tuning_Persistence_B;
uniform COMPAT_PRECISION float Tuning_Bleed;
uniform COMPAT_PRECISION float Tuning_Artifacts;
uniform COMPAT_PRECISION float NTSCLerp;
uniform COMPAT_PRECISION float NTSCArtifactScale;
uniform COMPAT_PRECISION float animate_artifacts;
#else
#define Tuning_Sharp 0.2
#define Tuning_Persistence_R 0.075
#define Tuning_Persistence_G 0.05
#define Tuning_Persistence_B 0.05
#define Tuning_Bleed 0.5
#define Tuning_Artifacts 0.5
#define NTSCLerp 1.0
#define NTSCArtifactScale 255.0
#define animate_artifacts 1.0
#endif

// Weight for applying an unsharp mask at a distance of 1, 2, or 3 pixels from changes in luma.
// The sign of each weight changes in order to alternately simulate overshooting and undershooting.
float SharpWeight[3] =
float[](
	1.0, -0.3162277, 0.1
);

// Calculate luma for an RGB value.
float Brightness(vec4 InVal)
{
	return dot(InVal, vec4(0.299, 0.587, 0.114, 0.0));
}

#define curFrameSampler Source

void main()
{
	vec2 fragcoord = (vTexCoord * (SourceSize.xy / InputSize.xy)) * (InputSize.xy / SourceSize.xy);
	half2 scanuv = vec2(fract(fragcoord * 1.0001 * SourceSize.xy / NTSCArtifactScale));
	half4 NTSCArtifact1 = tex2D(NTSCArtifactSampler, scanuv);
	half4 NTSCArtifact2 = tex2D(NTSCArtifactSampler, scanuv + vec2(0.0, 1.0 / SourceSize.y));
	float lerpfactor = (animate_artifacts > 0.5) ? mod(float(FrameCount), 2.0) : NTSCLerp;
	half4 NTSCArtifact = lerp(NTSCArtifact1, NTSCArtifact2, 1.0 - lerpfactor);
	
	half2 LeftUV = vTexCoord - vec2(1.0 / SourceSize.x, 0.0);
	half2 RightUV = vTexCoord + vec2(1.0 / SourceSize.x, 0.0);
	
	half4 Cur_Left = tex2D(curFrameSampler, LeftUV);
	half4 Cur_Local = tex2D(curFrameSampler, vTexCoord);
	half4 Cur_Right = tex2D(curFrameSampler, RightUV);
	
	half4 TunedNTSC = NTSCArtifact * Tuning_Artifacts;
		
	// Note: The "persistence" and "bleed" parameters have some overlap, but they are not redundant.
	// "Persistence" affects bleeding AND trails. (Scales the sum of the previous value and its scaled neighbors.)
	// "Bleed" only affects bleeding. (Scaling of neighboring previous values.)
	
	vec4 Prev = COMPAT_TEXTURE(Prev4Texture, TEX0.xy);
	Prev = (Prev + COMPAT_TEXTURE(Prev2Texture, TEX0.xy)) / 2.0;
	Prev = (Prev + COMPAT_TEXTURE(PrevTexture, TEX0.xy)) / 2.0;
	
	vec4 Prev_L = COMPAT_TEXTURE(Prev4Texture, LeftUV);
	Prev_L = (Prev_L + COMPAT_TEXTURE(Prev2Texture, LeftUV)) / 2.0;
	Prev_L = (Prev_L + COMPAT_TEXTURE(PrevTexture, LeftUV)) / 2.0;
	
	vec4 Prev_R = COMPAT_TEXTURE(Prev4Texture, RightUV);
	Prev_R = (Prev_R + COMPAT_TEXTURE(Prev2Texture, RightUV)) / 2.0;
	Prev_R = (Prev_R + COMPAT_TEXTURE(PrevTexture, RightUV)) / 2.0;
	
	half4 Prev_Left = Prev_L;//tex2D(prevFrameSampler, LeftUV);
	half4 Prev_Local = Prev;//tex2D(prevFrameSampler, vTexCoord);
	half4 Prev_Right = Prev_R;//tex2D(prevFrameSampler, RightUV);
	
	// Apply NTSC artifacts based on differences in luma between local pixel and neighbors..
	Cur_Local =
		saturate(Cur_Local +
		(((Cur_Left - Cur_Local) + (Cur_Right - Cur_Local)) * TunedNTSC));
	
	half curBrt = Brightness(Cur_Local);
	half offset = 0.;
	
	// Step left and right looking for changes in luma that would produce a ring or halo on this pixel due to undershooting/overshooting.
	// (Note: It would probably be more accurate to look at changes in luma between pixels at a distance of N and N+1,
	// as opposed to 0 and N as done here, but this works pretty well and is a little cheaper.)
	for (int i = 0; i < 3; ++i)
	{
		half2 StepSize = (half2(1.0/TextureSize.x,0.0) * (float(i + 1)));
		half4 neighborleft = tex2D(curFrameSampler, vTexCoord - StepSize);
		half4 neighborright = tex2D(curFrameSampler, vTexCoord + StepSize);
		
		half NBrtL = Brightness(neighborleft);
		half NBrtR = Brightness(neighborright);
		offset += ((((curBrt - NBrtL) + (curBrt - NBrtR))) * SharpWeight[i]);
	}
	
	// Apply the NTSC artifacts to the unsharp offset as well.
	Cur_Local = saturate(Cur_Local + (offset * Tuning_Sharp * lerp(vec4(1.,1.,1.,1.), NTSCArtifact, Tuning_Artifacts)));
	
	vec4 Tuning_Persistence = vec4(Tuning_Persistence_R, Tuning_Persistence_G, Tuning_Persistence_B, 1.0);
	// Take the max here because adding is overkill; bleeding should only brighten up dark areas, not blow out the whole screen.
	Cur_Local = saturate(max(Cur_Local, Tuning_Persistence * (10.0 / (1.0 + (2.0 * Tuning_Bleed))) * (Prev_Local + ((Prev_Left + Prev_Right) * Tuning_Bleed))));
	
   FragColor = vec4(Cur_Local);
} 
#endif
