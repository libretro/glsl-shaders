/*
  PT SkyWalker541  v2.0.0
  by SkyWalker541  |  RetroArch GLSL

  Pixel transparency shader inspired by mattakins' pixel transparency work.
  Restores GB/GBC/GBA backing material appearance on white/bright pixels.

  Pixel Effect LCD Dot mode inspired by Themaister's dot shader
  (public domain).

  v1.7.0 - replaced PT_PIXEL_BORDER with unified Pixel Effect system:
            Grid, LCD Dot (Gaussian falloff), CRT Phosphor (9-sample
            neighbourhood, RGB subpixels, scanlines, bloom). All effect
            parameters strictly gated to their own mode for minimum cost
            when not selected.

  v1.7.1 - added Black Level Threshold parameter shared by LCD Dot and
            CRT Phosphor modes. Black detection uses the raw input frame
            before color correction so unlit pixels remain clean regardless
            of emulator color settings. Hard gate on truly black pixels
            ensures clean blacks at zero cost regardless of threshold value.

  v1.8.0 - added PT_GAP_GRID_COLOR and PT_GAP_GRID_COLOR_INTENSITY parameters.
            Gap / Grid color applies to Grid, LCD Dot, and CRT Phosphor modes.
            Backing Texture option uses the already-computed bg value at zero
            extra cost. Black and White options use PT_GAP_GRID_COLOR_INTENSITY
            for opacity control. Removed Dot brightness compensation and
            Phosphor brightness comp parameters - these were designed to recover
            brightness lost to pure black gaps. PT_GAP_GRID_COLOR now solves
            this at the source making compensation redundant. Also renamed all
            parameter code names to closely match their menu label names.
            Added PT_SHADOW_DIRECTION parameter - lets the user choose from
            four drop shadow directions (Down Right, Down Left, Up Right,
            Up Left). Default is Down Right. Corrected shadow offset direction
            to cast down and to the right by default.

  v2.0.0 - major release (supersedes the unreleased 1.8.1 work). Parameter
            code names changed, so saved presets from 1.x fall back to the
            default values and should be re-saved. Removed CRT Phosphor mode
            (it does not apply to the reflective LCD systems this shader
            targets) and made the shader safer on low-end / strict GLSL ES
            drivers.
            * Pixel Effect now has three modes: Off, Grid, LCD Dot.
            * Removed all PT_PHOSPHOR_* parameters.
            * Menu labels renamed to say plainly what each setting does.
            * Menu reorganised: each group has a "== Name ==" main row with its
              dependent settings indented beneath it, and effect-specific rows
              tagged [Grid], [LCD Dot] or [Grid+Dot].
            * Code names now match the menu labels (old -> new):
                PT_SYSTEM                        -> PT_GAME_SYSTEM
                PT_MANUAL_SENSITIVITY_THRESHOLD  -> PT_MANUAL_WHITE_DETECTION_LEVEL
                PT_PIXEL_MODE                    -> PT_TRANSPARENT_PIXELS
                PT_BASE_TRANSPARENCY_AMOUNT      -> PT_TRANSPARENCY_AMOUNT
                PT_WHITE_PIXEL_MIN_TRANSPARENCY  -> PT_MINIMUM_WHITE_TRANSPARENCY
                PT_BACKGROUND_TINT               -> PT_BACKING_COLOR
                PT_TINT_INTENSITY                -> PT_BACKING_COLOR_STRENGTH
                PT_DARK_COLOR_FILTER             -> PT_DARKEN_PICTURE
                PT_GRID_WIDTH                    -> PT_GRID_LINE_WIDTH (now a real line width)
                PT_DOT_SHARPNESS                 -> PT_DOT_EDGE_SOFTNESS (new range and meaning)
                PT_BLACK_LEVEL_THRESHOLD         -> PT_MIN_BRIGHTNESS_FOR_DOTS
                PT_GAP_GRID_COLOR                -> PT_GAP_COLOR
                PT_GAP_GRID_COLOR_INTENSITY      -> split into PT_GRID_LINE_OPACITY and
                                                    PT_DOT_GAP_OPACITY
                PT_SHADOW_OPACITY                -> PT_DROP_SHADOW_OPACITY
                PT_SHADOW_OFFSET                 -> PT_SHADOW_DISTANCE
                PT_BEZEL_SHADOW_STRENGTH         -> PT_BEZEL_EDGE_SHADOW
              Presets that saved an old name fall back to the default value.
            * Backing gap fix: with Gap color = Backing, gaps around non-white
              pixels in White mode used to come out black. They now use the
              real backing color, built by a shared computeBacking() function
              that white pixels use too (their result is unchanged).
            * Grid reworked: Grid line width is now a real line thickness, and
              Grid has its own opacity (PT_GRID_LINE_OPACITY).
              Width is a fraction of one game pixel. With integer scaling at
              N times, one screen pixel is 1/N of a game pixel, so very thin
              widths (roughly below 1/N) fade out or do not show.
            * LCD Dot reworked: Dot edge softness (formerly Dot sharpness) sets
              how soft the dot's edge is (0 = hard edge, 1 = soft, which
              matches the old default look), and LCD Dot has its own opacity
              (PT_DOT_GAP_OPACITY).
              The shared gap strength setting no longer exists.
            * New defaults: Game system GBC, Transparent pixels All, Transparency
              amount 0.10, Backing color strength 2.0, Grid line width 0.25,
              Grid line opacity 0.50, Dot size 0.90, Dot gap opacity 0.50.
            * Vertex shader now passes only TEX0, texel and orig_coord
              (3 varyings instead of 8).
            * Source is now pure ASCII (box-drawing characters, em dashes and
              arrows removed from comments) - some mobile GLSL compilers
              reject non-ASCII bytes even inside comments.
            * Guarded smoothstep() against a zero Black Level Threshold
              (undefined behaviour when both edges are equal).
            * Fallback #define defaults now match the #pragma defaults.
*/


// -- PARAMETERS ---------------------------------------------------------------

// Menu layout: each "== Name ==" row is the main setting for a group. The
// "     > " rows beneath it only matter when that main setting is turned on.
// Tags in square brackets show which pixel effect a row applies to.
// RetroArch lists parameters in the order of the lines below.

// System
#pragma parameter PT_GAME_SYSTEM "== Game system == (0=Manual, 1=GB, 2=GBC, 3=GBA SP, 4=GBA Orig)" 2.0 0.0 4.0 1.0
#pragma parameter PT_MANUAL_WHITE_DETECTION_LEVEL "     > Manual white detection level (Manual only)" 0.85 0.0 1.0 0.01

// Pixel Transparency
#pragma parameter PT_TRANSPARENT_PIXELS "== Transparent pixels == (0=White, 1=Bright, 2=All)" 2.0 0.0 2.0 1.0
#pragma parameter PT_TRANSPARENCY_AMOUNT "     > Transparency amount" 0.10 0.0 1.0 0.01
#pragma parameter PT_MINIMUM_WHITE_TRANSPARENCY "     > Minimum white transparency" 0.20 0.0 1.0 0.01

// Background
#pragma parameter PT_BACKING_COLOR "== Backing color == (0=Off, 1=Pocket, 2=Grey, 3=White)" 1.0 0.0 3.0 1.0
#pragma parameter PT_BACKING_COLOR_STRENGTH "     > Backing color strength" 2.0 0.0 2.0 0.05
// Color Filter
#pragma parameter PT_DARKEN_PICTURE "== Darken picture == (0=Off)" 0.0 0.0 100.0 1.0

// Pixel Effect
#pragma parameter PT_PIXEL_EFFECT "== Pixel Effect == (0=Off, 1=Grid, 2=LCD Dot)" 1.0 0.0 2.0 1.0
#pragma parameter PT_GAP_COLOR "     > [Grid+Dot] Gap color (0=Backing, 1=Black, 2=White)" 0.0 0.0 2.0 1.0
#pragma parameter PT_GRID_LINE_WIDTH "     > [Grid] Grid line width" 0.25 0.0 0.5 0.01
#pragma parameter PT_GRID_LINE_OPACITY "     > [Grid] Grid line opacity" 0.50 0.0 1.0 0.01
#pragma parameter PT_DOT_SIZE "     > [LCD Dot] Dot size" 0.90 0.1 0.9 0.01
#pragma parameter PT_DOT_EDGE_SOFTNESS "     > [LCD Dot] Dot edge softness (0=hard, 1=soft)" 1.0 0.0 1.0 0.01
#pragma parameter PT_DOT_GAP_OPACITY "     > [LCD Dot] Dot gap opacity" 0.50 0.0 1.0 0.01
#pragma parameter PT_MIN_BRIGHTNESS_FOR_DOTS "     > [LCD Dot] Min brightness for dots" 0.15 0.0 1.0 0.01

// Drop Shadow
#pragma parameter PT_DROP_SHADOW_OPACITY "== Drop shadow opacity == (0=Off)" 0.30 0.0 1.0 0.01
#pragma parameter PT_SHADOW_DISTANCE "     > Shadow distance" 1.0 -10.0 10.0 0.5
#pragma parameter PT_SHADOW_DIRECTION "     > Shadow direction (0=Down Right, 1=Down Left, 2=Up Right, 3=Up Left)" 0.0 0.0 3.0 1.0

// Bezel Shadow
#pragma parameter PT_BEZEL_EDGE_SHADOW "== Bezel edge shadow == (0=Off)" 0.40 0.0 1.0 0.01

// -- VERTEX SHADER ------------------------------------------------------------
#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING    out
#define COMPAT_ATTRIBUTE  in
#define COMPAT_TEXTURE    texture
#else
#define COMPAT_VARYING    varying
#define COMPAT_ATTRIBUTE  attribute
#define COMPAT_TEXTURE    texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING   vec2 TEX0;
COMPAT_VARYING   vec2 texel;
COMPAT_VARYING   vec2 orig_coord;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0        = TexCoord.xy;
    texel       = 1.0 / TextureSize;
    orig_coord  = TEX0.xy * (TextureSize / InputSize) * (OrigInputSize / OrigTextureSize);
}

// -- FRAGMENT SHADER ----------------------------------------------------------
#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING  in
#define COMPAT_TEXTURE  texture
out vec4 FragColor;
#else
#define COMPAT_VARYING  varying
#define FragColor       gl_FragColor
#define COMPAT_TEXTURE  texture2D
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

uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;
uniform sampler2D Texture;
uniform sampler2D OrigTexture;

COMPAT_VARYING vec2 TEX0;
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 orig_coord;

// -- PARAMETER UNIFORMS / FALLBACKS -------------------------------------------
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PT_GAME_SYSTEM;
uniform COMPAT_PRECISION float PT_MANUAL_WHITE_DETECTION_LEVEL;
uniform COMPAT_PRECISION float PT_TRANSPARENT_PIXELS;
uniform COMPAT_PRECISION float PT_TRANSPARENCY_AMOUNT;
uniform COMPAT_PRECISION float PT_MINIMUM_WHITE_TRANSPARENCY;
uniform COMPAT_PRECISION float PT_BACKING_COLOR;
uniform COMPAT_PRECISION float PT_BACKING_COLOR_STRENGTH;
uniform COMPAT_PRECISION float PT_DARKEN_PICTURE;
uniform COMPAT_PRECISION float PT_PIXEL_EFFECT;
uniform COMPAT_PRECISION float PT_GAP_COLOR;
uniform COMPAT_PRECISION float PT_GRID_LINE_WIDTH;
uniform COMPAT_PRECISION float PT_GRID_LINE_OPACITY;
uniform COMPAT_PRECISION float PT_DOT_SIZE;
uniform COMPAT_PRECISION float PT_DOT_EDGE_SOFTNESS;
uniform COMPAT_PRECISION float PT_DOT_GAP_OPACITY;
uniform COMPAT_PRECISION float PT_MIN_BRIGHTNESS_FOR_DOTS;
uniform COMPAT_PRECISION float PT_DROP_SHADOW_OPACITY;
uniform COMPAT_PRECISION float PT_SHADOW_DISTANCE;
uniform COMPAT_PRECISION float PT_SHADOW_DIRECTION;
uniform COMPAT_PRECISION float PT_BEZEL_EDGE_SHADOW;
#else
// Fallback defaults - generated from, and identical to, the #pragma parameter defaults above.
#define PT_GAME_SYSTEM                   2.0
#define PT_MANUAL_WHITE_DETECTION_LEVEL  0.85
#define PT_TRANSPARENT_PIXELS            2.0
#define PT_TRANSPARENCY_AMOUNT           0.10
#define PT_MINIMUM_WHITE_TRANSPARENCY    0.20
#define PT_BACKING_COLOR                 1.0
#define PT_BACKING_COLOR_STRENGTH        2.0
#define PT_DARKEN_PICTURE                0.0
#define PT_PIXEL_EFFECT                  1.0
#define PT_GAP_COLOR                     0.0
#define PT_GRID_LINE_WIDTH               0.25
#define PT_GRID_LINE_OPACITY             0.50
#define PT_DOT_SIZE                      0.90
#define PT_DOT_EDGE_SOFTNESS             1.0
#define PT_DOT_GAP_OPACITY               0.50
#define PT_MIN_BRIGHTNESS_FOR_DOTS       0.15
#define PT_DROP_SHADOW_OPACITY           0.30
#define PT_SHADOW_DISTANCE               1.0
#define PT_SHADOW_DIRECTION              0.0
#define PT_BEZEL_EDGE_SHADOW             0.40
#endif

// -- CONSTANTS ----------------------------------------------------------------
#define LUMA_R 0.2126
#define LUMA_G 0.7152
#define LUMA_B 0.0722

// -- HELPER FUNCTIONS ---------------------------------------------------------

float getBrightness(vec3 c)
{
    return LUMA_R * c.r + LUMA_G * c.g + LUMA_B * c.b;
}

float resolveThreshold()
{
    if (PT_GAME_SYSTEM < 0.5) return PT_MANUAL_WHITE_DETECTION_LEVEL;
    if (PT_GAME_SYSTEM < 1.5) return 0.90;
    if (PT_GAME_SYSTEM < 2.5) return 0.85;
    if (PT_GAME_SYSTEM < 3.5) return 0.80;
    return 0.75;
}

float isWhitePixel(vec3 pixel, float brightness, float threshold)
{
    float minCh = min(pixel.r, min(pixel.g, pixel.b));
    if (brightness > threshold && minCh > threshold * 0.9) return 1.0;
    return 0.0;
}

vec3 applyDarkFilter(vec3 c, float level)
{
    float strength = level * 0.01;
    float luma     = getBrightness(c);
    float factor   = max(1.0 - strength * luma, 0.0);
    return c * factor;
}

float noiseHash(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 = p3 + vec3(dot(p3, p3.yzx + 33.33));
    return fract((p3.x + p3.y) * p3.z);
}

vec3 proceduralBackground(vec2 uv)
{
    float grain  = noiseHash(uv * 128.0) * 0.875;
    float offset = (grain - 0.4375) * 0.065;
    return vec3(0.478 + offset);
}

// Smooth fade-in from black. The threshold is clamped away from zero because
// smoothstep() is undefined when both edges are equal.
float blackLevelFade(float rawLuma)
{
    return smoothstep(0.0, max(PT_MIN_BRIGHTNESS_FOR_DOTS, 0.001), rawLuma);
}

// -- PIXEL EFFECT - MODE 1 : GRID ---------------------------------------------
// Thin lines along the borders between source pixels. No texture samples.
// PT_GRID_LINE_WIDTH sets the line thickness (as a fraction of one source
// pixel); PT_GRID_LINE_OPACITY sets how strongly the gap color covers the
// pixel underneath the line.

vec3 applyGrid(vec3 color, vec2 coord, vec3 gapColor)
{
    vec2  cellUV = fract(coord * TextureSize);

    // Distance from this point to the nearest pixel border:
    // 0 on the border, 0.5 at the pixel centre.
    float edgeDist = min(min(cellUV.x, 1.0 - cellUV.x), min(cellUV.y, 1.0 - cellUV.y));

    // Each pixel holds half of the line on every side of it. A small fixed
    // soft edge keeps the line from looking jagged. Width 0 gives no line.
    float halfWidth = PT_GRID_LINE_WIDTH * 0.5;
    float lineMask  = 1.0 - smoothstep(halfWidth - 0.04, halfWidth, edgeDist);

    return mix(color, gapColor, lineMask * PT_GRID_LINE_OPACITY);
}

// -- PIXEL EFFECT - MODE 2 : LCD DOT ------------------------------------------
// Round dot with an adjustable edge and brightness-dependent dot sizing.
// Single sample. Only the dot parameters, the minimum brightness and the
// shared gap color are evaluated.

vec3 applyLCDDot(vec3 color, vec2 coord, float rawLuma, vec3 gapColor)
{
    // Gate: uses raw input frame brightness so color correction cannot
    // cause unlit pixels to appear lit. Dot structure fades in smoothly
    // as raw pixel brightness rises above black.
    if (rawLuma < 0.01) return color;
    float lumaFade = blackLevelFade(rawLuma);
    float luma     = getBrightness(color);

    vec2  cellUV = fract(coord * TextureSize);
    vec2  delta  = cellUV - 0.5;
    float dist   = sqrt(dot(delta, delta));

    // Brightness-dependent radius: bright pixels get slightly larger dots,
    // dark pixels slightly smaller - consistent with physical LCD behaviour.
    float bloomBias = mix(0.0, 0.08, luma);
    float radius    = PT_DOT_SIZE * 0.5 + bloomBias;

    // Dot edge softness sets how wide the soft edge is, as a fraction of the dot
    // radius: 0 = hard-edged disk, 1 = the edge fades all the way in to the
    // centre. A tiny minimum keeps a hard edge from being jagged.
    float softEdge = max(PT_DOT_EDGE_SOFTNESS * radius, 0.02);
    float dotMask  = clamp((radius - dist) / softEdge, 0.0, 1.0);

    // Outside the dot, cover the pixel with the gap color at PT_DOT_GAP_OPACITY.
    // lumaFade ensures dark pixels blend back to original color.
    vec3 dotResult = mix(color, gapColor, (1.0 - dotMask) * PT_DOT_GAP_OPACITY);
    vec3 result    = mix(color, dotResult, lumaFade);

    return result;
}

// -- UNIFIED PIXEL EFFECT DISPATCHER ------------------------------------------
// Strictly gated - each branch only evaluates its own mode's parameters.

vec3 resolveGapColor(vec3 bg)
{
    if (PT_GAP_COLOR < 0.5) return bg;            // Backing Texture
    if (PT_GAP_COLOR < 1.5) return vec3(0.0);     // Black
    return vec3(1.0);                                  // White
}

vec3 applyPixelEffect(vec3 color, vec2 coord, float rawLuma, vec3 bg)
{
    if (PT_PIXEL_EFFECT < 0.5) return color;
    vec3 gapColor = resolveGapColor(bg);
    if (PT_PIXEL_EFFECT < 1.5) return applyGrid(color, coord, gapColor);
    return applyLCDDot(color, coord, rawLuma, gapColor);
}

// -- BEZEL SHADOW -------------------------------------------------------------

vec3 applyBezelShadow(vec3 color, vec2 coord)
{
    if (PT_BEZEL_EDGE_SHADOW < 0.001) return color;

    float scale = 35.0;
    if      (PT_GAME_SYSTEM < 1.5) scale = 22.0;
    else if (PT_GAME_SYSTEM < 2.5) scale = 35.0;
    else if (PT_GAME_SYSTEM < 3.5) scale = 70.0;
    else                      scale = 55.0;

    vec2  gameUV = coord / (InputSize / TextureSize);
    vec2  uv     = gameUV * 2.0 - 1.0;
    float shadow = clamp((1.0 - abs(uv.x)) * scale, 0.0, 1.0) *
                   clamp((1.0 - abs(uv.y)) * scale, 0.0, 1.0);

    return color * mix(1.0 - PT_BEZEL_EDGE_SHADOW, 1.0, shadow);
}

// -- BACKING MATERIAL ---------------------------------------------------------
// The color of the screen's backing at this pixel: procedural grain, a drop
// shadow cast by dark neighbouring pixels, then the backing color tint.
// It shows through transparent pixels and, when Gap color is Backing, it also
// fills the gaps of the pixel effects.

vec3 computeBacking(float threshold)
{
    // Procedural backing texture.
    vec3 bg = proceduralBackground(TEX0.xy);

    // Drop shadow - single tap on raw frame, before palette tint.
    if (PT_DROP_SHADOW_OPACITY > 0.001) {
        vec2 shadowDir;
        if      (PT_SHADOW_DIRECTION < 0.5) shadowDir = vec2(-1.0,  1.0);  // Down Right
        else if (PT_SHADOW_DIRECTION < 1.5) shadowDir = vec2( 1.0,  1.0);  // Down Left
        else if (PT_SHADOW_DIRECTION < 2.5) shadowDir = vec2(-1.0, -1.0);  // Up Right
        else                                shadowDir = vec2( 1.0, -1.0);  // Up Left
        vec2  shadowPos      = orig_coord + shadowDir * PT_SHADOW_DISTANCE * texel;
        vec3  shadowSrc      = COMPAT_TEXTURE(OrigTexture, shadowPos).rgb;
        float shadowBright   = getBrightness(shadowSrc);
        float shadowSrcWhite = isWhitePixel(shadowSrc, shadowBright, threshold);
        if (shadowSrcWhite < 0.5) {
            float shadowStrength = (1.0 - shadowBright) * PT_DROP_SHADOW_OPACITY;
            bg = mix(bg, bg * 0.2, shadowStrength);
        }
    }

    // Palette tint - after shadow.
    if (PT_BACKING_COLOR > 0.5) {
        vec3 tint;
        if      (PT_BACKING_COLOR < 1.5) tint = vec3(0.651, 0.675, 0.518);
        else if (PT_BACKING_COLOR < 2.5) tint = vec3(0.737, 0.737, 0.737);
        else                             tint = vec3(1.0,   1.0,   1.0  );
        vec3 tinted = clamp(tint + (bg * 2.0 - vec3(1.0)), 0.0, 1.0);
        bg = mix(bg, tinted, PT_BACKING_COLOR_STRENGTH);
    }

    return bg;
}

// -- MAIN ---------------------------------------------------------------------
void main()
{
    // Sample corrected frame and raw input frame.
    vec4 lcd      = COMPAT_TEXTURE(Texture,     TEX0.xy);
    vec3 pixel    = lcd.rgb;
    vec3 rawPixel = COMPAT_TEXTURE(OrigTexture, orig_coord).rgb;

    // Cache brightness.
    float pixBrightness = getBrightness(pixel);
    float rawBrightness = getBrightness(rawPixel);

    // Dark color filter - on corrected frame.
    if (PT_DARKEN_PICTURE > 0.5) {
        pixel         = applyDarkFilter(pixel, PT_DARKEN_PICTURE);
        pixBrightness = getBrightness(pixel);
    }

    // White detection - on raw frame.
    float threshold = resolveThreshold();
    float isWhite   = isWhitePixel(rawPixel, rawBrightness, threshold);

    // White mode - non-white pixels exit early, post effects still applied.
    float alpha = 0.0;
    if (PT_TRANSPARENT_PIXELS < 0.5 && isWhite < 0.5) {
        // These pixels get no transparency, but the pixel effect still runs on
        // them. Build the backing only when the gaps actually use it (Gap color
        // = Backing), and not for pure black pixels that LCD Dot skips anyway.
        vec3 gapBacking = vec3(0.0);
        if (PT_PIXEL_EFFECT > 0.5 && PT_GAP_COLOR < 0.5 &&
            !(PT_PIXEL_EFFECT > 1.5 && rawBrightness < 0.01)) {
            gapBacking = computeBacking(threshold);
        }
        vec3 result = applyPixelEffect(pixel, TEX0.xy, rawBrightness, gapBacking);
        result = applyBezelShadow(result, TEX0.xy);
        FragColor = vec4(result, lcd.a);
        return;
    }

    // Backing material (grain, shadow, tint).
    vec3 bg = computeBacking(threshold);

    // Transparency alpha.
    if (PT_TRANSPARENT_PIXELS < 0.5) {
        alpha = clamp((pixBrightness / 3.0) + PT_TRANSPARENCY_AMOUNT, 0.0, 1.0);
    } else if (PT_TRANSPARENT_PIXELS < 1.5) {
        alpha = clamp(PT_TRANSPARENCY_AMOUNT * pixBrightness * 2.665, 0.0, 1.0);
    } else {
        alpha = clamp((pixBrightness / 3.0) + PT_TRANSPARENCY_AMOUNT, 0.0, 1.0);
    }

    if (isWhite > 0.5) alpha = max(alpha, PT_MINIMUM_WHITE_TRANSPARENCY);

    vec3 result = mix(pixel, bg, alpha);

    // Post-blend pixel effect and bezel - applied last.
    result = applyPixelEffect(result, TEX0.xy, rawBrightness, bg);
    result = applyBezelShadow(result, TEX0.xy);

    FragColor = vec4(result, lcd.a);
}
#endif
