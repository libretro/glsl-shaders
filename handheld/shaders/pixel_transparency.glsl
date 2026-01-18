/*
  ____  _          _
 |  _ \(_)_  _____| |
 | |_) | \ \/ / _ \ |
 |  __/| |>  <  __/ |
 |_|___|_/_/\_\___|_|
 |_   _| __ __ _ _ __  ___ _ __   __ _ _ __ ___ _ __   ___ _   _
   | || '__/ _` | '_ \/ __| '_ \ / _` | '__/ _ \ '_ \ / __| | | |
   | || | | (_| | | | \__ \ |_) | (_| | | |  __/ | | | (__| |_| |
   |_||_|  \__,_|_| |_|___/ .__/ \__,_|_|  \___|_| |_|\___|\__, |
                          |_|                              |___/
    v1.1 by mattakins
    Copyright (C) 2025 Matt Akins.

    Grid shaders look great on Game Boy Color games - except for one glaring issue.

    With no backlight, the original devices didn't render white pixels. These light pixels
    appeared as transparent areas where the backing material of the screen showed through.
    Many games relied on this effect for transparent backgrounds that now render on modern
    displays as eye-searing white pixels. No more! Pixel Transparency simulates this unique effect.

    Just append to your favorite LCD shader as the last pass to reduce eye strain and maximize nostalgia.

*/

#pragma parameter PT_ENABLE "=== Pixel Transparency v1.1 === (OFF/ON)" 1.0 0.0 1.0 1.0
#pragma parameter NOTE1 " *  Append to any LCD shader as last pass. Try with GBC & GBA." 0.0 0.0 1.0 1.0
#pragma parameter NOTE2 " *  Turn ON Core > Color Correction & Interframe Blending" 0.0 0.0 1.0 1.0

// Background tint
#pragma parameter PT_PALETTE "== Background tint == (0=OFF, 1=Pocket, 2=Gray, 3=White)" 1.0 0.0 3.0 1.0
#pragma parameter PT_PALETTE_INTENSITY "     ↳ Tint intensity" 1.0 0.0 2.0 0.05

// Transparency
#pragma parameter PT_PIXEL_MODE "== 1. Transparent pixels == (0=White only, 1=Bright, 2=All)" 1.0 0.0 2.0 1.0
#pragma parameter PT_BASE_ALPHA "     ↳ Transparency amount" 0.20 0.0 1.0 0.01
#pragma parameter PT_THRESHOLD "== 2. White pixel detection threshold ==" 0.90 0.0 1.0 0.01
#pragma parameter PT_WHITE_BOOST "== 3. Boost white transparency == (OFF/ON)" 0.0 0.0 1.0 1.0
#pragma parameter PT_WHITE_TRANSPARENCY "     ↳ Boost amount" 0.50 0.0 1.0 0.01

#pragma parameter PT_BRIGHTNESS_GRID "== Grid reduces pixel transparency == (OFF/ON)" 1.0 0.0 1.0 1.0
#pragma parameter PT_BRIGHTNESS_MODE "== Brightness mode == (0=Simple, 1=Perceptual)" 1.0 0.0 1.0 1.0

#pragma parameter PT_DARK_FILTER_ENABLE "== Color harshness filter == (OFF/ON)" 0.0 0.0 1.0 1.0
#pragma parameter PT_DARK_FILTER_LEVEL "     ↳ Filter amount" 10.0 0.0 100.0 1.0

// Shadows
#pragma parameter PT_SHADOW_ENABLE "== Drop shadows == (OFF/ON)" 1.0 0.0 1.0 1.0
#pragma parameter PT_SHADOW_OFFSET_X "     ↳ Shadow X offset" 3.0 -30.0 30.0 0.5
#pragma parameter PT_SHADOW_OFFSET_Y "     ↳ Shadow Y offset" 3.0 -30.0 30.0 0.5
#pragma parameter PT_SHADOW_OPACITY "     ↳ Shadow opacity" 0.5 0.0 1.0 0.01

// Shadow blur
#pragma parameter PT_SHADOW_BLUR_MODE "== Shadow blur (impacts performance) == (0=OFF,1=Lite,2=Full)" 1.0 0.0 2.0 1.0
#pragma parameter PT_SHADOW_BLUR "     ↳ Shadow blur amount" 1.0 0.0 5.0 0.1

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
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 orig_texel;
COMPAT_VARYING float shadow_scale_factor;
COMPAT_VARYING vec2 orig_coord;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    texel = 1.0 / TextureSize;
    orig_texel = 1.0 / OrigTextureSize;

    // Calculate coordinates for sampling OrigTexture
    // First normalize TEX0 to [0,1] using current pass dimensions,
    // then scale to original texture coordinate space
    orig_coord = TEX0.xy * (TextureSize / InputSize) * (OrigInputSize / OrigTextureSize);

    // Calculate resolution scale for shadow compensation
    // Reference resolution: 640x480 (shadow offsets tuned for this resolution)
    float scale_x = OutputSize.x / 640.0;
    float scale_y = OutputSize.y / 480.0;
    shadow_scale_factor = sqrt(scale_x * scale_y);
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
uniform COMPAT_PRECISION vec2 OrigTextureSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;
uniform sampler2D Texture;
uniform sampler2D OrigTexture;

COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 texel;
COMPAT_VARYING vec2 orig_texel;
COMPAT_VARYING float shadow_scale_factor;
COMPAT_VARYING vec2 orig_coord;

// Compatibility defines
#define Source Texture
#define Original OrigTexture

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PT_ENABLE;
uniform COMPAT_PRECISION float PT_BRIGHTNESS_GRID;
uniform COMPAT_PRECISION float PT_PIXEL_MODE;
uniform COMPAT_PRECISION float PT_BRIGHTNESS_MODE;
uniform COMPAT_PRECISION float PT_WHITE_BOOST;
uniform COMPAT_PRECISION float PT_WHITE_TRANSPARENCY;
uniform COMPAT_PRECISION float PT_THRESHOLD;
uniform COMPAT_PRECISION float PT_PALETTE;
uniform COMPAT_PRECISION float PT_PALETTE_INTENSITY;
uniform COMPAT_PRECISION float PT_BASE_ALPHA;
uniform COMPAT_PRECISION float PT_DARK_FILTER_ENABLE;
uniform COMPAT_PRECISION float PT_DARK_FILTER_LEVEL;
uniform COMPAT_PRECISION float PT_SHADOW_ENABLE;
uniform COMPAT_PRECISION float PT_SHADOW_OFFSET_X;
uniform COMPAT_PRECISION float PT_SHADOW_OFFSET_Y;
uniform COMPAT_PRECISION float PT_SHADOW_OPACITY;
uniform COMPAT_PRECISION float PT_SHADOW_BLUR;
uniform COMPAT_PRECISION float PT_SHADOW_BLUR_MODE;
#else
#define PT_ENABLE 1.0
#define PT_BRIGHTNESS_GRID 1.0
#define PT_PIXEL_MODE 1.0
#define PT_BRIGHTNESS_MODE 1.0
#define PT_WHITE_BOOST 0.0
#define PT_WHITE_TRANSPARENCY 0.50
#define PT_THRESHOLD 0.90
#define PT_PALETTE 1.0
#define PT_PALETTE_INTENSITY 1.0
#define PT_BASE_ALPHA 0.20
#define PT_DARK_FILTER_ENABLE 0.0
#define PT_DARK_FILTER_LEVEL 10.0
#define PT_SHADOW_ENABLE 1.0
#define PT_SHADOW_OFFSET_X 3.0
#define PT_SHADOW_OFFSET_Y 3.0
#define PT_SHADOW_OPACITY 0.5
#define PT_SHADOW_BLUR 1.0
#define PT_SHADOW_BLUR_MODE 2.0
#endif

// Gambatte luminance constants (ITU-R BT.709 standard)
#define LUMA_R 0.2126
#define LUMA_G 0.7152
#define LUMA_B 0.0722

// Perceptual brightness calculation using Gambatte luminance formula
float getPerceptualBrightness(vec3 color) {
    return LUMA_R * color.r + LUMA_G * color.g + LUMA_B * color.b;
}

// Game Boy style RGB calculation (normalized to 0-1 range)
float getGameBoyRGBSum(vec3 color) {
    return (color.r + color.g + color.b) / 3.0;
}

// Unified brightness calculation based on mode parameter
float getBrightness(vec3 color) {
    if (PT_BRIGHTNESS_MODE < 0.5) {
        return getGameBoyRGBSum(color);
    }
    return getPerceptualBrightness(color);
}

// White pixel detection helper - returns 1.0 if white, 0.0 if not
float isWhitePixel(vec3 color, float threshold) {
    float brightness = getPerceptualBrightness(color);
    float min_channel = min(min(color.r, color.g), color.b);
    if (brightness > threshold && min_channel > threshold * 0.9) {
        return 1.0;
    }
    return 0.0;
}

// Gambatte darkenRgb function implementation
vec3 darkenRgb(vec3 color, float darkFilterLevel) {
    float darkStrength = darkFilterLevel * 0.01;
    float luma = LUMA_R * color.r + LUMA_G * color.g + LUMA_B * color.b;
    float darkFactor = max(1.0 - darkStrength * luma, 0.0);
    return color * darkFactor;
}

// Procedural paper grain noise generation
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 = p3 + vec3(dot(p3, p3.yzx + 33.33));
    return fract((p3.x + p3.y) * p3.z);
}

float paperNoise(vec2 uv, float scale) {
    vec2 p = uv * scale * 512.0;
    float n = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    // Unrolled loop for GLSL ES compatibility
    n = n + hash(p * frequency) * amplitude;
    amplitude = amplitude * 0.5;
    frequency = frequency * 2.0;

    n = n + hash(p * frequency) * amplitude;
    amplitude = amplitude * 0.5;
    frequency = frequency * 2.0;

    n = n + hash(p * frequency) * amplitude;

    return n;
}

vec3 generateProceduralBackground(vec2 uv) {
    vec3 baseColor = vec3(0.4773, 0.4773, 0.4773);
    float grainIntensity = 0.065;
    float scale = 0.25;

    float grain = paperNoise(uv, scale);
    float grainOffset = (grain - 0.4375) * grainIntensity;

    return baseColor + vec3(grainOffset, grainOffset, grainOffset);
}

void main()
{
    // Cache texture samples
    vec4 lcd_color = COMPAT_TEXTURE(Source, TEX0.xy);
    vec3 original_pixel = COMPAT_TEXTURE(Original, orig_coord).rgb;

    // Apply gambatte luminance filter to LCD content if enabled
    if (PT_DARK_FILTER_ENABLE > 0.5) {
        lcd_color.rgb = darkenRgb(lcd_color.rgb, PT_DARK_FILTER_LEVEL);
    }

    // Default output is the LCD-processed color
    vec4 output_color = lcd_color;

    // Early exit if shader is disabled
    if (PT_ENABLE < 0.5) {
        FragColor = output_color;
        return;
    }

    // Pre-calculate white detection for current pixel (1.0 = white, 0.0 = not white)
    float current_is_white = isWhitePixel(original_pixel, PT_THRESHOLD);

    // Generate procedural background
    vec4 background = vec4(generateProceduralBackground(TEX0.xy), 1.0);

    // Apply drop shadow to background if enabled (BEFORE tinting)
    if (PT_SHADOW_ENABLE > 0.5) {
        vec2 base_offset = vec2(-PT_SHADOW_OFFSET_X, -PT_SHADOW_OFFSET_Y);
        // Convert screen-space pixel offset to original texture coordinates
        // base_offset * shadow_scale_factor = pixels at current output resolution
        // Divide by OutputSize to get normalized screen coords, then scale to orig texture space
        vec2 shadow_offset = base_offset * shadow_scale_factor * OrigInputSize / (OutputSize * OrigTextureSize);

        vec3 shadow_source = COMPAT_TEXTURE(Original, orig_coord + shadow_offset).rgb;
        float source_is_white = isWhitePixel(shadow_source, PT_THRESHOLD);

        if (source_is_white < 0.5) {
            float shadow_source_brightness = getBrightness(shadow_source);
            float shadow_strength = (1.0 - shadow_source_brightness) * PT_SHADOW_OPACITY;

            // Blur modes: 0=Off, 1=Lite (5-sample), 2=Full (9-sample)
            if (PT_SHADOW_BLUR_MODE > 0.5 && PT_SHADOW_BLUR > 0.1) {
                float blur_distance = PT_SHADOW_BLUR * shadow_scale_factor * OrigInputSize.x / (OutputSize.x * OrigTextureSize.x);
                float blurred_shadow = 0.0;
                vec2 base_pos = orig_coord + shadow_offset;
                vec3 blur_sample;

                // Center sample (used by both Lite and Full modes)
                blur_sample = COMPAT_TEXTURE(Original, base_pos).rgb;
                blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                // Cardinal samples (used by both Lite and Full modes)
                blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(-blur_distance, 0.0)).rgb;
                blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(blur_distance, 0.0)).rgb;
                blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(0.0, -blur_distance)).rgb;
                blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(0.0, blur_distance)).rgb;
                blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                // Diagonal samples (Full mode only - 9 samples total)
                if (PT_SHADOW_BLUR_MODE > 1.5) {
                    blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(-blur_distance, -blur_distance)).rgb;
                    blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                    blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(blur_distance, -blur_distance)).rgb;
                    blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                    blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(-blur_distance, blur_distance)).rgb;
                    blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                    blur_sample = COMPAT_TEXTURE(Original, base_pos + vec2(blur_distance, blur_distance)).rgb;
                    blurred_shadow = blurred_shadow + (1.0 - getBrightness(blur_sample));

                    shadow_strength = (blurred_shadow / 9.0) * PT_SHADOW_OPACITY;
                } else {
                    // Lite mode: 5 samples
                    shadow_strength = (blurred_shadow / 5.0) * PT_SHADOW_OPACITY;
                }
            }

            background.rgb = mix(background.rgb, background.rgb * 0.2, shadow_strength);
        }
    }

    // Apply background tint if enabled (AFTER shadows)
    if (PT_PALETTE > 0.5) {
        vec3 bg_palette_color;

        if (PT_PALETTE < 1.5) {
            bg_palette_color = vec3(0.651, 0.675, 0.518);
        } else if (PT_PALETTE < 2.5) {
            bg_palette_color = vec3(0.737, 0.737, 0.737);
        } else {
            bg_palette_color = vec3(1.0, 1.0, 1.0);
        }

        vec3 tinted_background = clamp(
            vec3(
                bg_palette_color.r + mix(-1.0, 1.0, background.r),
                bg_palette_color.g + mix(-1.0, 1.0, background.g),
                bg_palette_color.b + mix(-1.0, 1.0, background.b)
            ), 0.0, 1.0
        );

        background.rgb = mix(background.rgb, tinted_background, PT_PALETTE_INTENSITY);
    }

    // Choose brightness source based on grid influence setting
    vec3 brightness_source;
    if (PT_BRIGHTNESS_GRID > 0.5) {
        brightness_source = lcd_color.rgb;
    } else {
        brightness_source = original_pixel;
    }

    // Mode 1: Bright pixel transparency
    if (PT_PIXEL_MODE > 0.5 && PT_PIXEL_MODE < 1.5) {
        float pixel_intensity = getBrightness(brightness_source);
        float transparency = (PT_BASE_ALPHA * pixel_intensity) * 2.665;

        if (current_is_white > 0.5 && PT_WHITE_BOOST > 0.5) {
            transparency = max(transparency, PT_WHITE_TRANSPARENCY);
        }
        transparency = clamp(transparency, 0.0, 1.0);
        output_color.rgb = mix(lcd_color.rgb, background.rgb, transparency);
    }
    // Mode 0: White only
    else if (PT_PIXEL_MODE < 0.5) {
        if (current_is_white > 0.5) {
            float pixel_intensity = getBrightness(brightness_source);
            float pixel_alpha = (pixel_intensity / 3.0) + PT_BASE_ALPHA;

            if (PT_WHITE_BOOST > 0.5) {
                pixel_alpha = max(pixel_alpha, PT_WHITE_TRANSPARENCY);
            }
            pixel_alpha = clamp(pixel_alpha, 0.0, 1.0);
            output_color.rgb = mix(lcd_color.rgb, background.rgb, pixel_alpha);
        }
    }
    // Mode 2: All pixels
    else {
        float pixel_intensity = getBrightness(brightness_source);
        float pixel_alpha = (pixel_intensity / 3.0) + PT_BASE_ALPHA;

        if (current_is_white > 0.5 && PT_WHITE_BOOST > 0.5) {
            pixel_alpha = max(pixel_alpha, PT_WHITE_TRANSPARENCY);
        }
        pixel_alpha = clamp(pixel_alpha, 0.0, 1.0);
        output_color.rgb = mix(lcd_color.rgb, background.rgb, pixel_alpha);
    }

    FragColor = output_color;
}
#endif